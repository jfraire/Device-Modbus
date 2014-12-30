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
            $val  = [ $req->value ];
            $type = 'Device::Modbus::Response::WriteSingle';
        }
        elsif ($func eq 'Write Single Register') {
            $zone = 'holding_registers';
            $mode = 'write';
            $addr = $req->address;
            $qty  = 1;
            $val  = [ $req->value ];
            $type = 'Device::Modbus::Response::WriteSingle';
            unless ($val->[0] >= 0x0000 && $val->[0] <= 0xffff) {
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

        $server->log(4, "Routing 'write' zone: <$zone> addr: <$addr> qty: <$qty>");

        my $match = $unit->route($zone, $mode, $addr, $qty);
            
        $server->log(4, sub {
            'Match was' . (ref $match ? ' ' : ' not ') . 'successful'
            . " for 'write' zone: <$zone> addr: <$addr> qty: <$qty>"
        });

        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match;

        eval {
            $match->routine->($unit, $server, $req, $addr, $qty, $val);
        };

        if ($@) {
            $server->log(4, sub {
                "Action died for 'write' zone: <$zone> addr: <$addr> qty: <$qty> -- $@"
            });
            
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
                value    => $val->[0],
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

        $server->log(4, "Routing 'read' zone: <$zone> addr: <$addr> qty: <$qty>");

        my $match = $unit->route($zone, 'read', $addr, $qty);

        $server->log(4,
            sub {'Match was' . (ref $match ? ' ' : ' not ') . 'successful'});
        
        return Device::Modbus::Exception->new(
            function       => $func,
            exception_code => $match,
            unit           => $unit_id
        ) unless ref $match; 

        my @vals;
        eval {
            @vals = $match->routine->($unit, $server, $req, $addr, $qty);
            die 'Quantity of returned values differs from request'
                unless scalar @vals == $qty;
        };

        if ($@) {
            $server->log(4, sub {
                "Action died for 'read' zone: <$zone> addr: <$addr> qty: <$qty> -- $@"
            });
            
            return Device::Modbus::Exception->new(
                function       => $func,
                exception_code => 4,
                unit           => $unit_id
            );
        }
        
        return $type->new(
            function => $func,
            values   => \@vals,
            unit     => $unit_id
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

Device::Modbus::Server - Server side of Device::Modbus

=head1 SYNOPSIS

    package My::Unit;

    use parent 'Device::Modbus::Unit';
    use strict;
    use warnings;

    my %mem = (
        discrete_inputs   => [0,1,0,1,0,1],
        input_registers   => [200,201,202],
        holding_registers => [100,101,102],
    );

    sub init_unit {
        my $unit = shift;

        $unit->get('discrete_inputs',    0, 6,
            sub { return @{$mem{discrete_inputs}}[0..5] }
        );
        $unit->get('holding_registers',  0, 3,
            sub { return @{$mem{holding_registers}}[0..2] }
        );
        $unit->put('holding_registers',  0, 3, 'store_hr');
    }

    sub store_hr {
        my ($unit, $server, $req, $addr, $qty, $val) = @_;
        splice @{$mem{holding_registers}}, $addr, $qty, @$val;
        return scalar @$val;
    }

And somewhere else:

    use My::Unit;
    use Modbus::Server::RTU;
    use strict;
    use warnings;

    my $server = Modbus::Server::RTU->new(
        port => '/dev/ttyUSB0',
    );

    my $unit   = My::Unit->new(id => 1);
    $server->add_server_unit($unit);
    $server->start;


=head1 DESCRIPTION

One of the goals for L<Device::Modbus> is to have the ability to write Modbus servers that execute arbitrary code. Given the Modbus data model, the interface requires I<units> which in turn must have I<zones>. Zones may be one of:

=over

=item * Discrete Inputs

Read-only, bit addressable data. 

=item * Coils

Writable, bit addressable data.

=item * Input Registers

Read-only, word addressable data.

=item * Holding Registers

Read/Write, word addressable data.

=back

Then, as implied above, each zone must have addresses.

The addressing model is quite simple. Modbus requests indicate the operation to perform, an address, and a quantity of values either to read or write. Requests allow only for reading and/or writing, and the zone is implied by the request function.

                     +---------------------------------+
                     |            Unit 3               |
                     |                                 |
                     |  Zone: Holding Registers        |
                     |  +---------------------------+  |
                     |  | Address:  1               |  |
                     |  | Quantity: 3               |  |
                     |  | Read/Write:  Read-only    |  |
 Modbus request -->  |  +---------------------------+  |
 Read 3 registers    |  +---------------------------+  |
 from address 1      |  | Address:  1-5             |  |
                     |  | Quantity: *               |  |
                     |  | Read/Write:  Write-only   |  |
                     |  +---------------------------+  |
                     +---------------------------------+
 
Therefore, it is necessary to define units, which inherit from Device::Modbus::Unit. These units will have a set of zones and valid addresses (Device::Modbus::Unit::Address). When a request is received, it will be routed to the first address object that matches both in address and quantity. This Address object will contain the arbitrary code to execute to serve the request.

All of that happens in the Device::Modbus::Unit subclass. In a separate program, a server object must be instantiated, whose class will be either L<Device::Modbus::Server::TCP> or L<Device::Modbus::Server::RTU>, and finally, the different unit objects must be added to the server.

To gain flexibility, units "route" requests through their addresses. Addresses define the address range they will respond to, and the quantity of data they can receive or return. The first address to match a given request is then executed to handle the request. In fact, your code does not even need to work with the Modbus protocol at all!

This document will discuss only the generic Modbus server methods. For details of the two different variants, please see L<Device::Modbus::Server::TCP> and L<Device::Modbus::Server::RTU>.

=head1 UNITS

There are only three Unit methods for your use: init_unit, get and put.

=head2 init_unit

This method will be executed when the unit is added to the server. It receives only the unit object. It is called as:

 $unit->init_unit;

In this method you are expected to list the set of addresses that this unit will be able to handle.

=head2 Defining Unit addresses with C<get> and C<put>

Device::Modbus::Unit provides two methods to define addresses: get and put. Read-only addresses are created by using the unit method C<get>, while C<put> allows for the creation of write-only addresses. They both take as input the following positional parameters:

=over

=item 1. Zone

Zone must be one of C<discrete_coils>, C<discrete_inputs>, C<input_registers>, C<holding_registers> (and of course, you cannot define a write-only address in a read-only zone)

=item 2. Address

This defines the address or address range that this route will accept. It must be a single scalar (a number or a string):

=over

=item A single number

=item A string with comma-separated addresses (like '2,4,77')

=item A string defining a range of addresses (like '22-45')

=item A string combining the last two options

=item Simply '*', which matches all addresses.

=back

=item 3. Quantity

Takes the same format as the address parameter. 

=item 4. Code to execute

Takes either a code reference or the name of a method of the unit object.

=back

=head2 Address and quantity routing examples

As you noticed, both the address and quantity are quite flexible and allow for routing requests. To actually execute a piece of code, both quantity and address must match. The first matching address unit will be executed.

The following examples are valid definitions for the address and quantity fields. They come from the test suite (see routing.t):

    6
    '3, 8,5'
    '1-5'
    '1,3, 5 - 7,9'
    '*'
    '33-36'
    '101, 145, 23-28, 56-60'

=head2 Execution of the address code

When a request is routed to an address, its code will be executed as follows:

 # Serving a read request (address added with 'get')
 @vals = $code->($unit, $server, $req, $addr, $qty);

 # Serving a write request (address added with 'put')
 $code->($unit, $server, $req, $addr, $qty, $val);

The parameters are, in order: the unit object, the server object, the received Modbus request, the requested address, the requested quantity of values to read or write, and in the case of write requests, an array reference of the values received.

Note that, for read-only addresses, your code must return a list of values of length $qty. Otherwise an exception type 4 will be sent to the client (server failed). All values must be defined and in the appropriate range.

If the routine dies, a Modbus exception with code 4 will be sent to the client. The other exception codes are returned automatically by the server.

=head2 Example unit class

This example is from the test suite.

    package My::Unit;

    use parent 'Device::Modbus::Unit';
    use strict;
    use warnings;

    my %mem = (
        discrete_inputs   => [0,1,0,1,0,1],
        input_registers   => [200,201,202],
        holding_registers => [100,101,102],
    );

    sub init_unit {
        my $unit = shift;

        $unit->get(
            'discrete_inputs',    0, 6,
            sub { die 'Look for an exception code 4' }
        );
        $unit->get('holding_registers',  0, 3,
            sub { return @{$mem{holding_registers}}[0..2] }
        );
        $unit->put('holding_registers',  0, 3, 'store_hr');
    }

    sub store_hr {
        my ($unit, $server, $req, $addr, $qty, $val) = @_;
        splice @{$mem{holding_registers}}, $addr, $qty, @$val;
        return scalar @$val;
    }

    1;

=head1 SERVER METHODS

The two types of servers implement the same interface. The only difference is in the communication-related attributes. They both inherit from Device::Modbus::Server and this interface is very simple.

=head2 add_server_unit

This is the method which, once the server object has been instantiated, allows you to add one server unit to it. It can be called multiple times to add more than one unit. A server needs at least one unit to be useful, so you must call this method at least once:

 my $unit = My::Unit->new(id => 3);
 $server->add_server_unit($unit);

 # Or you can call it like this:
 $server->add_server_unit('My::Unit', 3);

This method is responsible of composing the unit into the server object and also of calling init_unit on it.

Note that units need to have an identification number. It is the second parameter in the second invocation form as shown in the above example.

=head2 get_server_unit

Simply returns a server unit:

 my $unit = $server->get_server_unit(3);

=head2 start

Starts the server, which finally enters the infinite loop waiting to serve clients. Servers respond to HUP signals.

=head2 Device::Modbus::Server::TCP and Device::Modbus::Server::RTU

See L<Device::Modbus::Server::TCP> and L<Device::Modbus::Server::RTU> for information about their particularities.

=head1 SEE ALSO

The documentation of the distribution is split among these different documents:

=over

=item L<Device::Modbus>

=item L<Device::Modbus::Client>

=item L<Device::Modbus::Server>

=item L<Device::Modbus::Server::TCP>

=item L<Device::Modbus::Server::RTU>

=item L<Device::Modbus::Spy>

=back

=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
