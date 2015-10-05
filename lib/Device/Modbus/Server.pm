package Device::Modbus::Server;

use Device::Modbus;
use Device::Modbus::Request;
use Device::Modbus::Response;
use Device::Modbus::Exception;
use Device::Modbus::Unit;

use Try::Tiny;
use Carp;
use strict;
use warnings;
use v5.10;

sub proto {
    return {
        units     => {},
        log_level => 2,
        timeout   => 5,
    };
}

### Unit management

sub units {
    my $self = shift;
    return $self->{units};
}

sub add_server_unit {
    my ($self, $unit, $id) = @_;

    if (ref $unit && $unit->isa('Device::Modbus::Unit')) {
        $unit->init_unit;
        $self->units->{$unit->id} = $unit;
        return $unit;
    }
    else {
        croak "Units must be subclasses of Device::Modbus::Unit";
    }
}

sub get_server_unit {
    my ($self, $unit_id) = @_;
    return $self->units->{$unit_id};
}

# To be overrided in subclasses
sub init_server {
    croak "Server must be initialized\n";
}


### Request parsing

sub receive_request {
    my $self = shift;
    my $adu = $self->new_adu();
    $self->parse_header($adu);
    $self->parse_pdu($adu);
    $self->parse_footer($adu);
    return $adu;
}

sub parse_pdu {
    my ($self, $adu) = @_;
    my $request;
    
    my $code = $self->parse_buffer(1,'C');

    foreach ($code) {
        when ([0x01, 0x02, 0x03, 0x04]) {
            # Read coils, discrete inputs, holding registers, input registers
            my ($address, $quantity) = $self->parse_buffer(4,'nn');

            $request = Device::Modbus::Request->new(
                code       => $code,
                address    => $address,
                quantity   => $quantity
            );
        }
        when ([0x05, 0x06]) {
            # Write single coil and single register
            my ($address, $value) = $self->parse_buffer(4, 'nn');
            if ($code == 0x05 && $value != 0xFF00 && $value != 0) {
                $request = Device::Modbus::Exception->new(
                    code           => $code + 0x80,
                    exception_code => 3
                );
            }
            else {               
                $request = Device::Modbus::Request->new(
                    code       => $code,
                    address    => $address,
                    value      => $value
                );
            }
        }
        when (0x0F) {
            # Write multiple coils
            my ($address, $qty, $bytes) = $self->parse_buffer(5, 'nnC');
            my $bytes_qty = $qty % 8 ? int($qty/8) + 1 : $qty/8;

            if ($bytes == $bytes_qty) {
                my (@values) = $self->parse_buffer($bytes, 'C*');
                @values      = Device::Modbus->explode_bit_values(@values);

                $request = Device::Modbus::Request->new(
                    code       => $code,
                    address    => $address,
                    quantity   => $qty,
                    bytes      => $bytes,
                    values     => \@values
                );
            }
            else {
                $request = Device::Modbus::Exception->new(
                    code           => $code + 0x80,
                    exception_code => 3
                );
            }
        }
        when (0x10) {
            # Write multiple registers
            my ($address, $qty, $bytes) = $self->parse_buffer(5, 'nnC');

            if ($bytes == 2 * $qty) {
                my (@values) = $self->parse_buffer($bytes, 'n*');

                $request = Device::Modbus::Request->new(
                    code       => $code,
                    address    => $address,
                    quantity   => $qty,
                    bytes      => $bytes,
                    values     => \@values
                );
            }
            else {
                $request = Device::Modbus::Exception->new(
                    code           => $code + 0x80,
                    exception_code => 3
                );
            }
        }
        when (0x17) {
            # Read/Write multiple registers
            my ($read_addr, $read_qty, $write_addr, $write_qty, $bytes)
                = $self->parse_buffer(9, 'nnnnC');

            if ($bytes == 2 * $write_qty) {
                my (@values) = $self->parse_buffer($bytes, 'n*');

                $request = Device::Modbus::Request->new(
                    code           => $code,
                    read_address   => $read_addr,
                    read_quantity  => $read_qty,
                    write_address  => $write_addr,
                    write_quantity => $write_qty,
                    bytes          => $bytes,
                    values         => \@values
                );
            }
            else {
                $request = Device::Modbus::Exception->new(
                    code           => $code + 0x80,
                    exception_code => 3
                );
            }
        }
        default {
            # Unimplemented function
            $request = Device::Modbus::Exception->new(
                code           => $code + 0x80,
                exception_code => 1,
            );
        }
    }

    $adu->message($request);
    return $request;        
}

### Server code

#    'Read Coils'                    => 0x01,
#    'Read Discrete Inputs'          => 0x02,
#    'Read Holding Registers'        => 0x03,
#    'Read Input Registers'          => 0x04,
#    'Write Single Coil'             => 0x05,
#    'Write Single Register'         => 0x06,
#    'Write Multiple Coils'          => 0x0F,
#    'Write Multiple Registers'      => 0x10,
#    'Read/Write Multiple Registers' => 0x17,

#my %area_and_mode_for = (
my %can_read_zone = (
    0x01 => ['discrete_coils',    'read' ],
    0x02 => ['discrete_inputs',   'read' ],
    0x03 => ['holding_registers', 'read' ],
    0x04 => ['input_registers',   'read' ],
    0x17 => ['holding_registers', 'read' ],
);

my %can_write_zone = (
    0x05 => ['discrete_coils',    'write' ],
    0x06 => ['holding_registers', 'write' ],
    0x0F => ['discrete_coils',    'write' ],
    0x10 => ['holding_registers', 'write' ],
    0x17 => ['holding_registers', 'write' ],
);

sub modbus_server {
    my ($server, $adu) = @_;

    ### Make sure the requested unit exists in this server
    unless (exists $server->units->{$adu->unit}) {
        return $server->request_for_others($adu);
    }
    
    ### Process write requests first
    if (exists $can_write_zone{ $adu->code }) {
        my ($zone, $mode) = @{$can_write_zone{$adu->code}};
        my $resp = $server->process_write_requests($adu, $zone, $mode);
        return $resp if $resp;
    }
    
    ### Process read requests last
    my ($zone, $mode) = @{$can_read_zone{$adu->code}};
    my $resp = $server->process_read_requests($adu, $zone, $mode);
    return $resp;
}

sub process_write_requests {
    my ($server, $adu, $zone, $mode) = @_;

    my $unit = $server->get_server_unit($adu->unit);
    my $code = $adu->code;

    my $address = $adu->message->{address} // $adu->message->{write_address};
    my $values  = $adu->message->{values} // [ $adu->message->{value} ];
    my $quantity = @$values;

    # Find the requested address within unit's addresses
    $server->log(4, "Routing 'write' zone: <$zone> address: <$address> qty: <$quantity>");
    my $match = $unit->route($zone, $mode, $address, $quantity);
    $server->log(4, 'Match was' . (ref $match ? ' ' : ' not ') . 'successful');

    return Device::Modbus::Exception->new(
        function       => $Device::Modbus::function_for{$code},
        exception_code => $match,
        unit           => $adu->unit
    ) unless ref $match;


    # Execute the requested route with the given parameters
    my $response;
    try {
        $match->routine->($unit, $server, $adu->message, $address, $quantity, $values);
    }
    catch {
        $server->log(4,
            "Action failed for 'write' zone: <$zone> address: <$address> quantity: <$quantity> error: $_ ");
        
        $response = Device::Modbus::Exception->new(
            function       => $Device::Modbus::function_for{$code},
            exception_code => 4,
            unit           => $adu->unit
        );
    };
    return $response if defined $response;

    # Build the response
    foreach ($code) {
        # Write single values
        when ([0x05, 0x06]) {
            $response = Device::Modbus::Response->new(
                code    => $code,
                address => $address,
                value   => $values->[0]
            );
        }
        # Write multiple values
        when ([0x0F, 0x10]) {
            $response = Device::Modbus::Response->new(
                code     => $code,
                address  => $address,
                quantity => $quantity
            );
        }
        when (0x17) {
            # 0x17 must perform a read operation afterwards
            $response = '';
        }
    }
    return $response;
}

sub process_read_requests {
    my ($server, $adu, $zone, $mode) = @_;

    my $unit = $server->get_server_unit($adu->unit);
    my $code = $adu->code;

    my $address  = $adu->message->{address} // $adu->message->{write_address};
    my $quantity = $adu->message->{quantity} // $adu->message->{read_quantity};

    $server->log(4, "Routing 'read' zone: <$zone> address: <$address> quantity: <$quantity>");
    my $match = $unit->route($zone, 'read', $address, $quantity);
    $server->log(4,
        'Match was' . (ref $match ? ' ' : ' not ') . 'successful');

    return Device::Modbus::Exception->new(
        function       => $Device::Modbus::function_for{$code},
        exception_code => $match,
        unit           => $adu->unit
    ) unless ref $match;
    
    my @vals;
    my $response;
    try {
        @vals = $match->routine->($unit, $server, $adu->message, $address, $quantity);
        croak 'Quantity of returned values differs from request'
            unless scalar @vals == $quantity;
    }
    catch {
        $server->log(4,
            "Action failed for 'read' zone: <$zone> address: <$address> quantity: <$quantity> -- $_");
        
        $response = Device::Modbus::Exception->new(
            function       => $Device::Modbus::function_for{$code},
            exception_code => 4,
            unit           => $adu->unit
        );
    };

    unless (defined $response) {
        $response = Device::Modbus::Response->new(
            code   => $code,
            values => \@vals
        );
    }
    
    return $response;
}

1;
