package Device::Modbus::Server;

use Device::Modbus;
use Device::Modbus::Exception;
use Device::Modbus::Unit;
use Carp;
use Moo;

has units => (is => 'rwp', default => sub { +{} });

sub add_server_unit {
    my ($self, $unit, $id) = @_;

    if (ref $unit) {
        $self->units->{$unit->id} = $unit;
        return $unit;
    }
    else {
        # $unit is a class name
        eval "require $unit";
        croak "Unable to load module '$unit': $@" if $@;
        my $new_unit = $unit->new(id => $id);
        $self->units->{$id} = $new_unit;
        return $new_unit;
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

    my ($zone, $mode, $addr, $qty, $val, $type);

    ### Process write requests first
    if (ref($req) =~ /Write(?:Single|Multiple)?$/) {
        if ($func eq 'Write Single Coil') {
            $zone = 'discrete_outputs';
            $mode = 'write';
            $addr = $req->address;
            $qty  = 1;
            $val  = $req->value;
            $type = 'Device::Modbus::Response::WriteSingle';
        }
        elsif ($func eq 'Write Single Register') {
            $zone = 'holding_registers';
            $mode = 'write';
            $addr = $req->address;
            $qty  = 1;
            $val  = $req->value;
            $type = 'Device::Modbus::Response::WriteSingle';

            unless ($val >= 0x0000 && $val <= 0xffff) {
                return Device::Modbus::Exception->new(
                    function       => $func,
                    exception_code => 3,
                    unit           => $unit
                );
            }
        }
        elsif (ref $req eq 'Write Multiple Coils') {
            $zone = 'discrete_outputs';
            $mode = 'write';
            $addr = $req->address;
            $qty  = $req->quantity;
            $val  = $req->values;
            $type = 'Device::Modbus::Response::WriteMultiple';
        }
        elsif ($func eq 'Write Multiple Registers') {
            $zone = 'holding_registers';
            $mode = 'write';
            $addr = $req->address;
            $qty  = $req->quantity;
            $val  = $req->values;
            $type = 'Device::Modbus::Response::WriteMultiple';
        }
        elsif ($func eq 'Read/Write Multiple Registers') {
            $zone = 'holding_registers',
            $mode = 'write';
            $addr = $req->write_address;
            $qty  = $req->write_quantity;
            $val  = $req->values;
        }
        else {
            return Device::Modbus::Exception->new(
                function       => $func,
                exception_code => 1,
                unit           => $unit_id
            );
        }

        my $match = $unit->route($zone, $mode, $addr, $qty);
            
        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match; 

        eval {
            $match->routine->($unit, $server, $val);
        };

        if ($@) {
            print STDERR $@;
            return Device::Modbus::Exception->new(
                function       => $func,
                exception_code => 4,
                unit           => $unit_id
            );
        }

        my $resp;
        if (ref $req eq 'Device::Modbus::Request::WriteSingle') {
            $resp = Device::Modbus::Response::WriteSingle->new(
                function => $func,
                address  => $addr,
                value    => $val,
                unit     => $unit_id
            );
        }
        elsif (ref $req eq 'Device::Modbus::Request::WriteMultiple') {
            $resp = Device::Modbus::Response::WriteSingle->new(
                function => $func,
                address  => $addr,
                quantity => $qty,
                unit     => $unit_id
            );
        }

        return $resp if defined $resp;
    }

    # Process read requests
    if (ref($req) =~ /Read(?:Write)?$/) {
        $addr = $req->address;
        $qty  = $req->quantity;

        if ($func eq 'Read Coils') {
            $zone = 'discrete_coils';
            $type = 'Device::Modbus::Response::ReadDiscrete';
        }
        elsif($func eq 'Read Discrete Inputs') {
            $zone = 'discrete_inputs'; 
            $type = 'Device::Modbus::Response::ReadDiscrete';
        }
        elsif($func eq 'Read Input Registers') {
            $zone = 'input_registers'; 
            $type = 'Device::Modbus::Response::ReadRegisters';
        }
        elsif($func eq 'Read Holding Registers') {
            $zone = 'holding_registers'; 
            $type = 'Device::Modbus::Response::ReadRegisters';
        }
        elsif($func eq 'Read/Write Multiple Registers') {
            $zone = 'holding_registers'; 
            $type = 'Device::Modbus::Response::ReadWrite';
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
        
        return $type->new(
            function => $func,
            values   => \@vals
        );
    }

    return Device::Modbus::Exception->new(
        function       => $func,
        exception_code => 1,
        unit           => $unit_id
    );
}

1;
