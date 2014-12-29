package Device::Modbus::Spy;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use Moo;

with 'Device::Modbus::RTU';

has unit        => (is => 'rwp');
has pdu         => (is => 'rwp');
has cdc         => (is => 'rwp');
has function    => (is => 'rwp');
has message     => (is => 'rwp');
has raw_object  => (is => 'rwp');
has old_msg     => (is => 'rw', default => sub { return { unit => 0, fcn => 0 } });
has is_request  => (is => 'rw', default => sub { 1 });

sub watch_port {
    my $self = shift;

    my $message;
    while (1) {
        $message = $self->read_port;
        last if $message;
    }

    return $self->parse_message($message);
}

sub parse_message {
    my ($self, $message) = @_;
    
    ### Break message
    my ($unit, $pdu, $footer) = $self->break_message($message);

    ### Parse message
    my $function_code = unpack 'C', $pdu;

    my %this_msg = ( unit => $unit, fcn => $function_code );
    my $msg;
    my $raw;

    # What if it is an exception?
    if ($function_code > 0x80) {
        my $exc = Device::Modbus->parse_exception($pdu);
        $msg = "*** (!) $exc";
        $raw = $exc;
    }
    else {
        # Parse the message twice anyway. It is difficult to find the difference
        # between requests and responses some times.
        my $req  = Device::Modbus->parse_request($pdu);
        my $resp = Device::Modbus->parse_response($pdu);

        # It could be a request if unit and function are different than the last message
        if ($this_msg{unit} != $self->old_msg->{unit} || $this_msg{fcn} != $self->old_msg->{fcn}) {
            $self->is_request(1);
        }


        # Write multiple coils or register responses are always 5 bytes
        if (($function_code == 15 || $function_code == 16) && length($pdu) != 5) { 
            $self->is_request(1);
        }

        # Reading functions
        if ($function_code <= 4) {
            my $values = defined $resp ? scalar @{$resp->values} : 1;
            my $bytes  = defined $resp ? $resp->bytes : 0;
            
            if (length($pdu) != 5) { # Requests are always 5 bytes
                $self->is_request(0);
            }
            elsif ($function_code >= 3 && $bytes > 0 && $values == 2*$bytes) {
                $self->is_request(0);
            }
            elsif ($function_code <= 2 && $bytes > 0 && $values == 8*$bytes) {
                $self->is_request(0);
            }
            else {
                $self->is_request(1);
            }
                
        }

        if ($function_code == 0x0F || $function_code == 0x10 && defined $req) {
             $self->is_request(0) if scalar @{$req->values} == 0;
             $self->is_request(1) if scalar @{$req->values} > 0;
        }
            

        # Read/Write responses have the length of the PDU in its 2nd byte
        if ($function_code == 23) {
            my $bytes = unpack 'C', substr $pdu, 1, 1;
            $self->is_request(0) if length($pdu) == 2 + $bytes;
        }

        if (defined $req && $self->is_request) {
            $msg = "--> $req";
            $raw = $req;
        }
        elsif (defined $resp && !$self->is_request) {
            $msg = "<-- $resp";
            $raw = $resp;
        }
        elsif (defined $req) {
            # Response was not parsed correctly even though we expected
            # a response
            $self->is_request(1);
            $msg = "--> (!) $req";
            $raw = $req;
        }
        elsif (defined $resp) {
            # Request was not parsed correctly even though we expected
            # a request
            $self->is_request(0);
            $msg = "<-- (!) $resp";
            $raw = $resp;
        }
        else {
            $msg = "*** (!) Unable to parse PDU";
        }
    }

    $raw->unit($unit);
    $self->_set_message($msg);
    $self->_set_raw_object($raw);
    $self->_set_function($function_code);
    $self->_set_unit("Unit: [$unit]");
    $self->_set_pdu("PDU:  [".join('-', map { unpack 'H*' } split //, $pdu)."]");
    $self->_set_cdc("CDC:  [".join('-', map { unpack 'H*' } split //, $footer)."]");

    # Toggle $is_request
    $self->is_request($self->is_request ? 0 : 1);
    $self->old_msg({%this_msg});

    return $self;
}

1;

__END__

=head1 NAME

Device::Modbus::Spy - Modbus RTU message sniffer

=head1 SYNOPSIS

From the examples directory:

 #! /usr/bin/env perl

 use Device::Modbus;
 use Device::Modbus::Spy;
 use Modern::Perl;

 say "Starting Modbus Spy";

 my $spy = Device::Modbus::Spy->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
 );

 while (1) {
    $spy->watch_port;

    say $spy->message;
    say $spy->unit;
    say $spy->pdu;
    say $spy->cdc;
    say '---';
 }

Sample output:

 --> Request: Function: [Write Multiple Registers] Address: [0x14e] Quantity: [12] Values: [1, 0, 2, 0, 0, 500, 50, 100, 50, 50, 100, 0]
 Unit: [3]
 PDU:  [10-01-4e-00-0c-18-00-01-00-00-00-02-00-00-00-00-01-f4-00-32-00-64-00-32-00-32-00-64-00-00]
 CDC:  [2a-2d]
 ---
 --> Request: Function: [Write Single Register] Address: [0x1100] Value: [47872]
 Unit: [3]
 PDU:  [06-11-00-bb-00]
 CDC:  [ff-e4]
 ---

=head1 DESCRIPTION

While developing machines, a Modbus message sniffer is a very useful tool to have. This module has already found connection problems (inverted wires), programming problems, and PLC debugging. The program in the examples directory was written with this kind of application in mind.

From the synopsis, you can see that the $spy object includes methods that directly stringify the different elements of the Modbus message. The Modbus message object can be retrieve with the methdod C<raw_object>.

The spy also provides a method called C<function> that will simply give you the number of the function used. It can be used to filter the output by function:

 while (1) {
    $spy->watch_port;

    next unless $spy->function == 3;
    say $spy->message;
    say $spy->unit;
    say $spy->pdu;
    say $spy->cdc;
    say '---';
 }

or you could filter by unit:

 while (1) {
    $spy->watch_port;

    next unless $spy->unit =~ m{\W3\W};
    say $spy->message;
    say $spy->unit;
    say $spy->pdu;
    say $spy->cdc;
    say '---';
 }


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
