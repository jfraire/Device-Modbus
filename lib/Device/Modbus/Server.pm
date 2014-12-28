package Device::Modbus::Server;

use Device::Modbus;
use Device::Modbus::Exception;
use Device::Modbus::Unit;
use Carp;
use Moo::Role;

has units => (is => 'rwp', default => sub { +{} });
requires 'start';

sub add_server_unit {
    my ($self, $unit, $id) = @_;

    if (ref $unit) {
        $unit->init_unit;
        $self->units->{$unit->id} = $unit;
        return $unit;
    }
    else {
        # $unit is a class name
        eval "require $unit";
        croak "Unable to load module '$unit': $@" if $@;
        my $new_unit = $unit->new(id => $id);
        $new_unit->init_unit;
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
    my ($server, $unit_id, $req) = @_;

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
            $zone = 'discrete_coils';
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
        elsif ($func eq 'Write Multiple Coils') {
            $zone = 'discrete_coils';
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
            $match->routine->($unit, $server, $req, $addr, $qty, $val);
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
            $resp = Device::Modbus::Response::WriteMultiple->new(
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

        if ($func eq 'Read/Write Multiple Registers') {
            $addr = $req->read_address;
            $qty  = $req->read_quantity;
            $zone = 'holding_registers'; 
            $type = 'Device::Modbus::Response::ReadWrite';
        }
        else {

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
            else {
                return Device::Modbus::Exception->new(
                    function       => $func,
                    exception_code => 1,
                    unit           => $unit_id
                );
            }
        }


        my $match = $unit->route($zone, 'read', $addr, $qty);
        
        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match; 

        my @vals;
        eval {
            @vals = $match->routine->($unit, $server, $req, $addr, $qty);
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

__END__

=head1 NAME

Device::Modbus - Perl distribution to implement Modbus communications

=head1 SYNOPSIS

This is a Modbus TCP client:


A Modbus RTU client would be:


=head1 DESCRIPTION


=head2 Servers

Device::Modbus provides two classes to implement servers: Device::Modbus::Server::RTU and Device::Modbus::Server::TCP. Your server must inherit from any of these two. Your server class should establish valid address limits for each Modbus data model zone (coils, discrete inputs, input registers and holding registers) and it must provide a method responsible for the generation of the actual responses. Then, your class must be instantiated by a script that will simply call its constructor and start the server.

Servers can implement several units. This is useful, for example, for writing Modbus TCP to RTU gateways, where a multitude of RTU servers are mapped onto a TCP network using the same IP address. You need to create the units that will be available through Device::Modbus servers:

 $server->add_server_unit($unit_id);

where the unit id is a number. This will simply add a bank of default address limits that the unit will accept. By default, these are set to the maximum of the Modbus specification. You must add at least one server unit.

Given these limits, servers must read requests and then check that:

=over

=item The requested function is implemented (exception 1 if it is not)

=item The requested addresses are within limits (exception 2)

=item The quantity of data requested is within limits (exception 3)

=item The values to write are valid (exception 3 for writing functions)

=back

The following methods allow you to declare validity limits:

=over

=item limits_discrete_inputs($unit, $min, $max)

=item limits_discrete_outputs($unit, $min, $max)

=item limits_input_registers($unit, $min, $max)

=item limits_holding_registers($unit, $min, $max)

=back

Adding units and adjusting their limits is usually performed in a method called C<init_server>. The default implementation simply creates a default unit with id 1. This code is available in the example servers:

 sub init_server {
    my $server = shift;

    $server->add_server_unit(1);
    
    $server->limits_discrete_inputs(1,1,16);
    $server->limits_discrete_outputs(1,1,16);
    $server->limits_input_registers(1,1,10);
    $server->limits_holding_registers(1,1,10);
 }

The server will start an infinite loop which will parse the request, validate it, and then call a user defined routine called C<process_request>. This routine will receive the server object, the unit number and the request itself. This routine is responsible for returning an appropriate response. It is called like this:

 ### Real work is perfomed here
 eval { $resp = $server->process_request($unit, $req) };

Finally, the C<start> method is used to start the infinite loop. It takes no arguments:

 $server->start;

Visit the C<examples> directory to see a couple of functional servers.

=head3 Constructor for Modbus RTU server

The RTU server shares the same constructor as the client and adds one argument, the unit number to listen for:

my $server = Test::Modbus::Server->new(
    port => '/dev/ttyUSB0',
    unit => 3
);
 
=head3 Constructor for Modbus TCP server

The TCP server inherits from L<Net::Daemon>. This is very nice, as Net::Daemon takes care of the management of sockets and it provides different execution modes, like forking, threading or single process servers. It can read its configuration arguments from a file and can take arguments from the command line. Please see its documentation.

The constructor has the following arguments:

=over

=item pidfile  (default: none)

=item localport (default: 502)

=item logfile (default: STDERR)

=back

as well as all the arguments received directly by Net::Daemon.



=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus>.

=head1 SEE ALSO

The documentation of the distribution is split among these different documents:

=over

=item L<Device::Modbus> - For basic request and response objects

=item L<Device::Modbus::Client>

=item L<Device::Modbus::Server>

=item L<Device::Modbus::Unit> - Server routing of requests

=item L<Device::Modbus::Spy>

=back

These are other implementations of Modbus in Perl:

L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
