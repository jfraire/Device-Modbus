package Device::Modbus::Server;

use Device::Modbus;
use Device::Modbus::Exception;
use Device::Modbus::Unit;
use Carp;
use Moo;

has units => (is => 'rwp', default => sub { +{} });

sub add_server_unit {
    my ($self, $unit_id) = @_;
    my $unit = Device::Modbus::Unit->new(id => $unit_id);
    $self->units->{$unit_id} = $unit;
    return $unit;
}

sub get_server_unit {
    my ($self, $unit_id) = @_;
    return $self->units->{$unit_id};
}

# To be overrided in subclasses
sub init_server {
    croak "Server must be initialized\n";
}

sub modbus_server {
    my ($server, $unit_id, $pdu) = @_;

    ### Parse message
    my $req = Device::Modbus->parse_request($pdu);    

    # Treat unimplemented functions -- return exception 1
    if (!ref $req) {
        return Device::Modbus::Exception->new(
            function       => $req,
            exception_code => 1,
            unit           => $unit_id
        );
    }

    my $unit = $server->get_server_unit($unit_id);
    my $func = $req->function;

    # Process write requests first
    if (ref $req eq 'Device::Modbus::Request::WriteSingle') {
        my $zone;
        my $addr  = $req->address;
        my $qty   = 1;
        my $value = $req->value;
        
        if ($func eq 'Write Single Coil') {
            $zone = 'discrete_outputs';
        }
        elsif ($func eq 'Write Single Register') {
            $zone = 'holding_registers';
            unless ($value >= 0x0000 && $value <= 0xffff) {
                return Device::Modbus::Exception->new(
                    function       => $func,
                    exception_code => 3,
                    unit           => $unit
                );
            }
        }
        else {
            return Device::Modbus::Exception->new(
                function       => $func,
                exception_code => 1,
                unit           => $unit_id
            );
        }

        my $match = $unit->route($zone, 'write', $addr, $qty);
        
        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match; 

        eval {
            $match->routine->($unit, $server, $value);
        };

        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => 4,
            unit           => $unit_id
        ) if $@;

        return Device::Modbus::Response::WriteSingle->new(
            function => $func,
            address  => $addr,
            value    => $value,
            unit     => $unit_id
        );
    }

    if (ref $req eq 'Device::Modbus::Request::WriteMultiple') {
        my $zone;
        my $addr   = $req->address;
        my $qty    = $req->quantity;
        my $values = $req->values;

        if ($func eq 'Write Multiple Coils') {
            $zone = 'discrete_outputs';
        }
        elsif ($func eq 'Write Multiple Registers') {
            $zone = 'holding_registers';
        }
        else {
            return Device::Modbus::Exception->new(
                function       => $func,
                exception_code => 1,
                unit           => $unit_id
            );
        }

        my $match = $unit->route($zone, 'write', $addr, $qty);
        
        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match; 

        eval {
            $match->routine->($unit, $server, $values);
        };

        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => 4,
            unit           => $unit_id
        ) if $@;

        return Device::Modbus::Response::WriteMultiple->new(
            function => $func,
            address  => $addr,
            quantity => $qty,
            unit     => $unit_id
        );
    }

    if (ref $req eq 'Device::Modbus::Request::ReadWrite') {
        my $zone   = 'holding_registers',
        my $addr   = $req->write_address;
        my $values = $req->values;
        my $qty    = $req->write_quantity;

        my $match = $unit->route($zone, 'write', $addr, $qty);
        
        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match; 

        eval {
            $match->routine->($unit, $server, $values);
        };

        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => 4,
            unit           => $unit_id
        ) if $@;
    }

    # Process read requests
    if (ref $req eq 'Device::Modbus::Request::Read') {
        my $zone;
        my $addr = $req->address;
        my $qty  = $req->quantity;
        my $class;

        if ($func eq 'Read Coils') {
            $zone  = 'discrete_coils';
            $class = 'Device::Modbus::Response::ReadDiscrete';
        }
        elsif($func eq  'Read Discrete Inputs') {
            $zone  = 'discrete_inputs'; 
            $class = 'Device::Modbus::Response::ReadDiscrete';
        }
        elsif($func eq  'Read Input Registers') {
            $zone  = 'input_registers'; 
            $class = 'Device::Modbus::Response::ReadRegisters';
        }
        elsif($func eq  'Read Holding Registers') {
            $zone  = 'holding_registers'; 
            $class = 'Device::Modbus::Response::ReadRegisters';
        }
        else {
            return Device::Modbus::Exception->new(
                function       => $func,
                exception_code => 1,
                unit           => $unit_id
            );
        }

        my $match = $unit->route($zone, 'read', $addr, $qty);
        
        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match; 

        my @vals;
        eval {
            @vals = $match->routine->($unit, $server);
        };

        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => 4,
            unit           => $unit_id
        ) if $@;
        
        return $class->new(
            function => $func,
            values   => \@vals
        );
    }
}

1;
