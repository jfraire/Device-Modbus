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

 use Device::Modbus;
 use Device::Modbus::Client::TCP;
 use Modern::Perl;

 my $client = Device::Modbus::Client::TCP->new();

 my $req    = Device::Modbus->read_holding_registers(
    unit     => 1,
    address  => 6,
    quantity => 5
 );

 foreach (1..5) {
    my $trn = $client->request_transaction($req);
    say "-> $req";
    $client->send_request($trn) || die "Send error";
    $client->receive_response   || die "Receive error";
    my $response = $trn->response;
    say "<- $response";
 }

 $client->close;

A Modbus RTU client would be:

 #! /usr/bin/env perl

 use Device::Modbus;
 use Device::Modbus::Client::RTU;
 use Modern::Perl;

 my $client = Device::Modbus::Client::RTU->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
 );

 my $req = Device::Modbus->read_holding_registers(
    address  => 1,
    quantity => 1,
    unit     => 1
 );

 while (1) {
    $client->send_request($req);
    say "-> $req";
    my $resp = $client->receive_response;
    say "<- $resp";
    sleep 1;
 }

=head1 DESCRIPTION

Modbus is a simple client/server communication protocol developed by Modicon in 1979. It is implemented by thousands of devices to transfer data in an industrial environment. Its roots in the early automation world are clearly visible through its model, where writable single bits are called I<coils> after relay contacts, for example.

The protocol follows a model that distiguishes between four types of data:

=over

=item * Discrete Inputs

Read-only, bit addressable data. 

=item * Coils

Writable, bit addressable data.

=item * Input Registers

Read/Write, word addressable data.

=item * Holding Registers

Read/Write, word addressable data.

=back

Modbus offers functions to access each of these types. The application is free to map this model onto its particular needs.

As it would be expected from such an old and pervasive protocol, it exists in three frame formats. The first one is Modbus RTU, which is a binary representation of the protocol suitable for transmision over a serial port using RS485 as the physical and data link layers. In this model, only one master should exist in the bus. Many instruments and controllers exist today that provide this mode of communication.

The second variant is Modbus ASCII. This is also a serial protocol which is a less efficient cousin of RTU, which should be implemented over a serial line. This variant is not implemented in this distribution.

The third frame format is Modbus TCP, which implements the protocol over Ethernet using TCP sockets. Using this model, any device can send requests to any other element in the network. This variant is implemented in this distribution.

To learn more about Modbus, please visit L<http://www.modbus.org>.

=head1 MOTIVATION AND GOALS

I was working with an HMI (human-machine interface) that communicates via Modbus TCP and it was required to bring information from a database. I thought this should be possible to do with Perl, but it was not. I found a couple of Modbus clients but no servers. As I learned more about Modbus, then just a fancy word, it was clear that it could be done. It should be done.

The goal for this distribution is then to provide easy ways to write clients and servers both for the RTU and TCP variants. In RTU, it is possible to make a spy that allows you to see the messages between a server and a client, or to read the messages sent by a controller, and this is very useful as a debugging tool. It is easy to implement a spy once you have servers available.

The servers must be able to execute arbitrary code to react to Modbus requests. This should allow to write database front ends that are reachable by Modbus, or to write protocol converters. There are many interesting possibilities.

=head1 USAGE

The usage of Device::Modbus depends on what you want to do. Servers, clients and the spy are quite different from each other. While clients issue requests and read responses, servers do the opposite.

Therefore, the protocol itself is broken into requests, responses and exception objects. These objects appear in every application and thus, we shall begin with their description.

=head2 Modbus functions

This distribution implements only the basic read and write functions of the Modbus specification. Moreover, while the specification calls for one-based addressing, the current implementation in Modicon controllers is zero-based. Device::Modbus addressing is zero-based.

When writing Modbus clients, once the communication channel is open (a socket or a serial port) you want to create requests. The client will then send these requests to the server, and wait for its responses.

=head3 Read functions

The following reading functions have been implemented, both as requests and as responses:

=over

=item * Read Discrete Inputs

=item * Read Coils

=item * Read Input Registers

=item * Read Holding Registers

=back

All of the requests share the same parameters with the significant difference that the first two functions work over discrete, bit values, and the last two, over word registers which are returned as numbers. The same is valid for response objects:

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

 # And the following methods create responses:
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

=head3 Write functions

Just like for reading, there are functions to write into bit and word-addressable zones. More over, you can write either one or multiple contiguous values using Modbus functions. Requests and responses for the following functions are implemented in Device::Modbus:

=over

=item * Write Single Coil

=item * Write Multiple Coils

=item * Write Single Register

=item * Write Multiple Registers

=back

Register-based functions work over the holding register area. Input registers are read-only.

The method to produce write requests are:

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

 # The following methods build requests:
 $res = Device::Modbus->single_coil_write(
    address => 26,
    value   =>  0
 );

 $res = Device::Modbus->multiple_coils_write(
    address => 256,
    values  => [1,0,0,1,1]
 );

 $res = Device::Modbus->single_register_write(
    address =>  26,
    value   => 820
 );

 $res = Device::Modbus->multiple_registers_write(
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

 $res = Device::Modbus->registers_read_write(
    values => [1,0,0,24,12,56]
 );

=head2 Request and response stringification

As a useful debugging tool, requests and responses are stringified to produce human-readable messages. You can, for example:

 say "$req";

to have a nice message telling you the function represented and its parameters.

=head2 Clients

Being able to issue requests and parsing responses is only half of the problem. The other half is getting down to the details of the transmission, and in Modbus there are two ways to do it: RTU and TCP.

Anyway, both RTU and TCP clients share some functionality. Both need to establish a connection channel (a serial port or a socket) and they both need to send requests and receive responses.

=head3 Methods common to both clients

=over

=item send_request($obj)

To send a request via the serial line (Modbus RTU), this method receives a request object. However, in the case of Modbus TCP it requires a transaction (more on this later):

 $client_rtu->send_request($req);
 $client_tcp->send_request($trn);

=item receive_response()

This method must be called to receive a response. In the case of Modbus RTU, it will look at input through the serial port; Modbus TCP clients will read from the client's socket.

 my $res = $client->receive_response()

=back

=head3 RTU client

The constructor can take the following arguments:

=over

=item * port (required)

=item * databits (default: 8)

=item * stopbits (default: 1)

=item * parity (default: even. Other valid values are 'none' and 'odd')

=item * baudrate (default: 9600)

=item * timeout (default: 2, in seconds)

=back

It uses L<Device::SerialPort> and so it is not Windows friendly (but this should be easy to change).

=head3 TCP client

The TCP client is more complex because it is not restricted to wait for each response. However, because communication is established via the client, each client can talk to a single server.

The constructor will take the following arguments:

=over

=item * host (default: 127.0.0.1)

=item * port (default: 502)

=item * blocking (default: 1)

=item * timeout (default: 0.2, in seconds)

=back

=head4 Transactions

Because sockets can be established in non-blocking mode, the client uses transactions. A transaction is an envelope that serves to relate a response to its request, as responses might arrive in a different order. Each transaction is uniquely identified. The identification number is sent along with the request and is returned by the server, thus permitting to find the request that originated a fresh response.

 # First create a request object
 my $req = Device::Modbus->read_coils(
    address  => 23,
    quantity =>  2
 );

 # and then use it to request a new transaction. You can reuse the same
 # request for many transactions, as the example server in the
 # synopsis
 my $trn = $client->request_transaction($req);

 # send_request will extract the request from the transaction and it
 # will use the transaction id number to build the Modbus message
 $client->send_request($trn);

 # In a separate piece of code:
 my $trn = $client->receive_response;

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

=head2 Modbus RTU Spy

=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus>.

=head1 SEE ALSO

These are other implementations of Modbus in Perl:

L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
