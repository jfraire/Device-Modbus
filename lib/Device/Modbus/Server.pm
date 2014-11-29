package Device::Modbus::Server;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use strict;
use warnings;

# Memory limits and memory areas per function

my %dispatch = (
    'Read Coils'                     => 'discrete_outputs',
    'Read Discrete Inputs'           => 'discrete_inputs', 
    'Read Input Registers'           => 'input_registers', 
    'Read Holding Registers'         => 'holding_registers',
    'Write Single Coil'              => 'discrete_outputs',
    'Write Single Register'          => 'holding_registers',
    'Write Multiple Coils'           => 'discrete_outputs',
    'Write Multiple Registers'       => 'holding_registers',
    'Read/Write Multiple Registers'  => 'holding_registers',
);

# Keeps minimum and maximum address values to validate requests against
my %server_units = ();

my %default_unit = (
    discrete_inputs   => [ 1, 0x07d0 ],
    discrete_outputs  => [ 1, 0x07d0 ],
    input_registers   => [ 1, 0x07d  ],
    holding_registers => [ 1, 0x07d  ],
);

sub add_server_unit {
    my ($self, $unit_id) = @_;
    $server_units{$unit_id} = { %default_unit };
}

sub limits_discrete_inputs {
    return shift->limits('discrete_inputs',   @_);
}

sub limits_discrete_outputs {
    return shift->limits('discrete_outputs',  @_);
}

sub limits_input_registers {
    return shift->limits('input_registers',   @_);
}

sub limits_holding_registers {
    return shift->limits('holding_registers', @_);
}

sub limits {
    my ($proto, $func, $unit, $min, $max) = @_;
    croak "Server unit <$unit> does not exist"
        unless exists $server_units{$unit};
    if (defined $min) {
        $server_units{$unit}->{$func}[0] = $min;
    }
    if (defined $max) {
        $server_units{$unit}->{$func}[1] = $max;
    }
    return @{ $server_units{$unit}->{$func} };
}

# To be overrided in subclasses
sub init_server {
    my $server = shift;
    $server->add_server_unit(1);
}



# Parses message, checks request for errors and calls external
# process to manage the request
sub modbus_server {
    my ($server, $unit, $pdu) = @_;

    ### Parse message
    my $req = Device::Modbus->parse_request($pdu);

    # Treat unimplemented functions -- return exception 1
    if (!ref $req) {
        return Device::Modbus::Exception->new(
            function       => $req,    # Function requested
            exception_code => 1        # Unimplemented function
        );
    }

    ### Validations that throw Modbus::Exceptions
    my $fcn = $req->function;    
    my ($min, $max) = $server->addr_limits($unit, $mem_for{$fcn});

    # All of read and multiple write functions
    if (   ref $req eq 'Device::Modbus::Request::Read'
        || ref $req eq 'Device::Modbus::Request::WriteMultiple'
    ) {
        my $addr = $req->address;
        my $qty  = $req->quantity;

        unless ($addr >= $min  && $addr+$qty <= $max) {
            return Device::Modbus::Exception->new(
                function       => $fcn,
                exception_code => 2 );
        }
        unless ($qty >= 1 && $qty <= $max - $min -1) {
            return Device::Modbus::Exception->new(
                function       => $fcn,
                exception_code => 3 );
        }
    }

    # Write single coil and single register
    if (ref $req eq 'Device::Modbus::Request::WriteSingle') {
        my $addr = $req->address;
        my $val  = $req->value;

        unless ($addr >= $min  && $addr <= $max) {
            return Device::Modbus::Exception->new(
                function       => $fcn,
                exception_code => 2 );
        }

        if (  $fcn eq 'Write Single Register' &&
            !($val >= 0x0000 && $val <= 0xffff)
        ) {
            return Device::Modbus::Exception->new(
                function       => $fcn,
                exception_code => 3 );
        }
            
    }

    # Read/Write
    if (ref $req eq 'Device::Modbus::Request::ReadWrite') {
        my $raddr  => $req->read_address;
        my $waddr  => $req->waddr;
        my $rqty   => $req->read_quantity;
        my $wqty   => $req->write_quantity;
        my $wbytes => $req->write_bytes;
        
        unless ($raddr >= $min  && $raddr+$rqty <= $max
            &&  $waddr >= $min  && $waddr+$wqty <= $max
        ) {
            return Device::Modbus::Exception->new(
                function       => $fcn,
                exception_code => 2 );
        }

        unless (
               $rqty >= 1 && $rqty <= 0x007d
            && $wqty >= 1 && $wqty <= 0x0079
            && $wbytes == 2*$wqty 
        ) {
            return Device::Modbus::Exception->new(
                function       => $fcn,
                exception_code => 3,
            );
        }
    }

    ### Real work is perfomed here
    my $response;
    eval { $response = $self->process_request($unit, $request) };


    # Return if the request was processed correctly
    if (defined $response && !$@) {
        return $response;
    }
    
    my $err_msg =
          "Client:      " . $sock->peerhost
        . "Unit:        " . $trn->unit
        . "Transaction: " . $trn->id
        . "Function:    " . $trn->request->function
        ;
    if ($@) {
        $self->Error("Application crashed: $@\n" . $err_msg);
    }
    elsif (!defined $response) {
        $self->Error("Application did not return a response:\n"
            . $err_msg);
    }

    return Device::Modbus::Exception->new(
        function       => $req->function,
        exception_code => 0x04
    );
}
    
1;
