package Device::Modbus;

use strict;
use warnings;

our $VERSION = '0.01';

use Device::Modbus::Message;
use Device::Modbus::Request::Read;
use Device::Modbus::Request::WriteSingle;
use Device::Modbus::Request::WriteMultiple;
use Device::Modbus::Request::ReadWrite;
use Device::Modbus::Response::ReadDiscrete;
use Device::Modbus::Response::ReadRegisters;
use Device::Modbus::Response::WriteSingle;
use Device::Modbus::Response::WriteMultiple;
use Device::Modbus::Response::ReadWrite;

#############################################################
# Message building
#############################################################

### Request builders

sub read_coils {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Coils',
        @_
    );
    return $req;
}

sub read_discrete_inputs {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Discrete Inputs',
        @_
    );
    return $req;
}

sub read_input_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Input Registers',
        @_
    );
    return $req;
}

sub read_holding_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Holding Registers',
        @_
    );
    return $req;
}

sub write_single_coil {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteSingle->new(
        function => 'Write Single Coil',
        @_
    );
    return $req;
}

sub write_single_register {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteSingle->new(
        function => 'Write Single Register',
        @_
    );
    return $req;
}

sub write_multiple_coils {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteMultiple->new(
        function => 'Write Multiple Coils',
        @_
    );
    return $req;
}

sub write_multiple_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteMultiple->new(
        function => 'Write Multiple Registers',
        @_
    );
    return $req;
}

sub read_write_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::ReadWrite->new(
        function => 'Read/Write Multiple Registers',
        @_
    );
    return $req;
}

### Response builders

sub coils_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadDiscrete->new(
        function => 'Read Coils',
        @_
    );
    return $res;
}

sub discrete_inputs_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadDiscrete->new(
        function => 'Read Discrete Inputs',
        @_
    );
    return $res;
}

sub holding_registers_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadRegisters->new(
        function => 'Read Holding Registers',
        @_
    );
    return $res;
}

sub input_registers_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadRegisters->new(
        function => 'Read Input Registers',
        @_
    );
    return $res;
}

sub single_coil_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteSingle->new(
        function => 'Write Single Coil',
        @_
    );
    return $res;
}

sub single_register_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteSingle->new(
        function => 'Write Single Register',
        @_
    );
    return $res;
}

sub multiple_coils_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteMultiple->new(
        function => 'Write Multiple Coils',
        @_
    );
    return $res;
}

sub multiple_registers_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteMultiple->new(
        function => 'Write Multiple Registers',
        @_
    );
    return $res;
}

sub registers_read_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadWrite->new(
        function => 'Read/Write Multiple Registers',
        @_
    );
    return $res;
}

#############################################################
# Message parsing
#############################################################

### Request parsing

sub parse_request {
    my ($class, $binary_req) = @_;

    my $request;
    my $function_code = unpack 'C', $binary_req;
    my $function = Device::Modbus::Message->function_for($function_code);

    if ($function_code > 0 && $function_code <= 4) {
        $request = Device::Modbus::Request::Read->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 5 || $function_code == 6) {
        $request = Device::Modbus::Request::WriteSingle->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x0f || $function_code == 0x10) {
        $request = Device::Modbus::Request::WriteMultiple->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x17) {
        $request = Device::Modbus::Request::ReadWrite->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    else {
        return $function_code;
    }

    return $request;
}

### Response parsing

sub parse_response {
    my ($class, $binary_req) = @_;

    my $response;
    my $function_code = unpack 'C', $binary_req;
    my $function = Device::Modbus::Message->function_for($function_code);

    if ($function_code == 0x01 || $function_code == 0x02) {
        $response = Device::Modbus::Response::ReadDiscrete->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x03 || $function_code == 0x04) {
        $response = Device::Modbus::Response::ReadRegisters->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x05 || $function_code == 0x06) {
        $response = Device::Modbus::Response::WriteSingle->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x0f || $function_code == 0x10) {
        $response = Device::Modbus::Response::WriteMultiple->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x17) {
        $response = Device::Modbus::Response::ReadWrite->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code > 0x80) {
        $response = $class->parse_exception($binary_req);
    }
    else {
        return $function_code;
    }

    return $response;
}

sub parse_exception {
    my ($class, $binary_req) = @_;

    my ($fcn_code, $exc_code) = unpack 'Cn', $binary_req;

    return $fcn_code unless $fcn_code > 0x80;
    
    my $fcn = Device::Modbus::Message->function_for($fcn_code-0x80);

    return Device::Modbus::Exception->new(
        function       => $fcn,
        exception_code => $exc_code
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

Device::Modbus is a distribution that allows writing simple Modbus clients and (not so simple) servers in Perl. Modbus RTU and Modbus TCP are both supported, but Modbus ASCII is not. 

For Modbus RTU, it is desirable to have a spy that allows you to see the messages between a server and a client, or to read the messages sent by a controller, as this is a very useful debugging tool. It is easy to implement a spy once you have the ability to parse requests and responses and you shall find one in the examples directory.

Servers are able to execute arbitrary code to react to Modbus requests. This should allow to write database front ends that are reachable by Modbus and protocol converters among other interesting possibilities.

=head1 BACKGROUND

Modbus is a simple client/server communication protocol developed by Modicon in 1979. It is implemented by thousands of devices to transfer data in an industrial environment. Its roots in the early automation world are clearly visible through its data model, where writable single bits are called I<coils> after relay contacts.

As it would be expected from such an old and pervasive protocol, it exists in three frame formats. The first one is Modbus RTU, which is a binary representation of the protocol suitable for transmision over a serial port using RS485 as the physical and data link layers. In this model, only one master should exist in the bus. Many instruments and controllers exist today that provide this mode of communication.

The second variant is Modbus ASCII. This is also a serial protocol which is a less efficient cousin of RTU, which should be implemented over a serial line. This variant is not implemented in this distribution.

The third frame format is Modbus TCP, which implements the protocol over Ethernet using TCP sockets. Using this model, any device can send requests to any other element in the network. This variant is implemented in this distribution.

To learn more about Modbus, please visit L<http://www.modbus.org>.

=head2 Basic Modbus concepts

There are a few concepts that you need to know about Modbus to use this distribution effectively. First of all, Modbus is based on a model that distiguishes between four types of data:

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

The protocol offers functions to access each of these types, and it leaves the application free to map this model onto its particular needs.

In this distribution, a I<unit> is an object or device which can be addressed using any of the above types.

Modbus defines a simple protocol data unit which is independent of the communication layers. This protocol data unit (PDU from here on) contains only function-related information (for example, to read input registers) but does not care if it is being sent via the serial port or over the internet.

The PDU is then wrapped into an Application Data Unit (ADU), which is devised to benefit from the communication layer particularities. Therefore, Modbus RTU ADUs are different from those used for Modbus TCP, but the underlying PDUs are the same.

This all means that the protocol is divided in two parts. The first deals with PDUs, which are always the same, and the other part deals with ADUs. ADUs depend on the variant of the protocol that is being used (that is, Modbus RTU or TCP).

Device::Modbus, the main module of this distribution, deals exclusively with reading and writing PDUs in an object-oriented way. The variants RTU or TCP are applied as roles to client and server objects.

=head1 BASIC MODBUS TASKS

To discuss about the structure of the distribution, let's first discuss what you can do with it. For example, the following tasks are performed by clients:

=over

=item 1. Open a connection to a server

=item 2. Build a request and obtain its PDU

=item 3. Wrap the PDU into an ADU

=item 4. Send the request (ADU) and read the response message

=item 5. Break the returned message (an ADU)

=item 6. Parse the obtained PDU into a response object

=item 7. Close the connection

=back


=head2 Structure of the distribution

The module Device::Modbus provides the basic tools to deal with Modbus requests and responses to the point of parsing and writing PDUs. It implements the communication-independent layer of the protocol. With Device::Modbus, you can do steps 2 and 6 of the above client.

The wrapping of PDUs into ADUs as well as communication handling details are done using roles. These roles are composed into client or server classes and thus you do not need to interact with them directly. These roles are responsible of steps 3, 4 and 5 for the example client.

In addition to the above, there are classes that help you write clients, servers and a Modbus RTU spy. To write a client, you should use Device::Modbus::Client::RTU or Device::Modbus::Client::TCP. See L<Device::Modbus::Client> for their documenation.

Servers are documented in L<Device::Modbus::Server>. Device::Modbus::Server includes a generic method that parses requests, calls user-defined routines accordingly, and builds a response with their results. This generic method is wrapped by Device::Modbus::Server::RTU and Device::Modbus::Server::TCP to take care of the actual communication.

Finally, a simple Modbus RTU spy module is included, L<Device::Modbus::Spy>. It will simple listen the serial port for any incoming message, parse the message and show the request, response or exception received.

Be sure to take a look into the examples directory, where you shall find programs that implement all of the major functionalities of the distribution.

=head1 REQUESTS AND RESPONSES

The protocol itself is broken into requests, responses and exception objects. These objects appear in every application and thus, we shall begin with their description.

=head2 Zero-based addressing

This distribution implements only the basic read and write functions of the Modbus specification. Moreover, while the specification calls for one-based addressing (see section 4.4 of the Modbus Application Protocol V1.1b3), the current implementation in Modicon controllers is zero-based. Device::Modbus addressing is zero-based which means that it will send addresses as you type them.

=head2 Modbus request functions

When writing Modbus clients, once the communication channel is open (a socket or a serial port) you want to create requests. The client will then send these requests to the server, and wait for its responses. Clients are also capable of parsing responses.

=head3 Read functions

The following reading functions have been implemented:

=over

=item * Read Discrete Inputs

=item * Read Coils

=item * Read Input Registers

=item * Read Holding Registers

=back

All of the requests share the same parameters with the significant difference that the first two functions work over bit-addressable data, and the last two, over word registers which are returned as numbers:

 # These are all Modbus requests:
 $req = Device::Modbus->read_discrete_inputs(
    address  => 0x32,
    quantity => 5
 );

 $req = Device::Modbus->read_coils(
    address  => 0x032,
    quantity => 5
 );

 $req = Device::Modbus->read_input_registers(
    address  => 23,
    quantity => 6
 );

 $req = Device::Modbus->read_holding_registers(
    address  => 22,
    quantity => 1
 );

=head3 Write functions

Just like for reading, there are functions to write into bit and word-addressable zones. More over, you can write either one or multiple contiguous values using Modbus functions. Requests and responses for the following functions are implemented in Device::Modbus:

=over

=item * Write Single Coil

=item * Write Multiple Coils

=item * Write Single Register

=item * Write Multiple Registers

=back

Register-based functions work over the holding register area since input registers are read-only.

The methods to produce write requests are:

 # Methods that return write requests:
 $req = Device::Modbus->write_single_coil(
    address => 26,
    value   =>  0
 );

 $req = Device::Modbus->write_multiple_coils(
    address => 256,
    values  => [1,0,0,1,1]
 );

 $req = Device::Modbus->write_single_register(
    address =>  26,
    value   => 820
 );

 $req = Device::Modbus->write_multiple_registers(
    address => 256,
    values  => [1,2,0,0,12,23]
 );

=head3 Read/Write Registers

The final funtion that is implemented in Device::Modbus is to read and write registers in a single request:

 # Read/Write Registers request:
 $req = Device::Modbus->read_write_registers(
    read_address    => 127,
    read_quantities =>   6,
    write_address   =>  32,
    values          => [122,132,154,26]
 );

=head2 Modbus response functions

Servers need the ability to parse requests and produce responses. These are the functions that create such responses:

=head3 Read responses

For each request function, there is an appropriate response.

 # The following methods create responses:
 $res = Device::Modbus->discrete_inputs_read(
    values => [1, 1, 0, 0, 1]
 );

 $res = Device::Modbus->coils_read(
    values => [1, 1, 0, 0, 1]
 );

 $res = Device::Modbus->input_registers_read(
    values => [12, 234, 24, 2, 224, 65368]
 );

 $res = Device::Modbus->holding_registers_read(
    values => [12]
 );

=head3 Write response functions

In the case of single-value write functions, the response is actually equal to the request. Multiple valued functions send back the quantity of coils or registers that were written:

 # The following methods build responses:
 $res = Device::Modbus->single_coil_write(
    address   => 26,
    value     =>  0
 );

 $res = Device::Modbus->multiple_coils_write(
    address   => 256,
    quantity  => 5
 );

 $res = Device::Modbus->single_register_write(
    address   =>  26,
    value     => 820
 );

 $res = Device::Modbus->multiple_registers_write(
    address   => 256,
    quantity  => 6
 );

=head3 Read/Write multiple registers

The response for a read/write multiple registers request, includes simply an array with the read values:

 $res = Device::Modbus->registers_read_write(
    values => [1,0,0,24,12,56]
 );

=head2 Writing a PDU

The PDU (I<Protocol Data Unit>) is the binary representation of a Modbus message. Given a request, response or exception:

 # Obtain a pdu string
 my $pdu = $obj->pdu;

The PDU cannot be sent over to another device just yet. It must be turned into an ADU by the client or server.

=head2 Parsing a PDU

When a Modbus message is received, it is really an ADU. It needs to be broken down to find the actual PDU among other information. The PDU is then parsed to produce an actual request or response object (or an exception object). The two following methods are provided:

 my $req = Device::Modbus->parse_request($pdu);
 my $res = Device::Modbus->parse_response($pdu);

In the case of responses, C<$res> can be an exception object, so be careful to test for this:

 # Is the response an exception object?
 if (ref $res eq 'Device::Modbus::Exception') {
     ...
 }

If the PDU could not be parsed, these methods return C<undef>.

=head2 Request and response stringification

As a useful debugging tool, requests and responses are stringified to produce human-readable messages. You can, for example:

 say "$req";

to have a nice message telling you the function represented and its parameters.


=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus>.

=head1 SEE ALSO

The documentation of the distribution is split among these different documents:

=over

=item L<Device::Modbus>

=item L<Device::Modbus::Client>

=item L<Device::Modbus::Server>

=item L<Device::Modbus::Unit>

=item L<Device::Modbus::Spy>

=back

=head2 Other distributions

These are other implementations of Modbus in Perl which may be well suited for your application:

L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
