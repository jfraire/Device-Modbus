package Device::Modbus::Spy;

use Device::Modbus;
use Device::Modbus::Exception;
use Device::Modbus::Message;
use Carp;
use Moo;

with 'Device::Modbus::RTU';

has unit        => (is => 'rwp');
has pdu         => (is => 'rwp');
has cdc         => (is => 'rwp');
has function    => (is => 'rwp');
has message     => (is => 'rwp');
has object      => (is => 'rwp');
has old_msg     => (is => 'rw', default => sub { return { unit => 0, fcn => 0 } });
has is_request  => (is => 'rw', default => sub { 1 });

sub watch_port {
    my $self = shift;

    my $message;
    while (1) {
        $message = $self->read_port;
        last if $message;
    }

    my $ret_value = join '-', map { unpack 'H*' } split //, $message;

    if ($self->parse_message($message)) {
        $ret_value  = sprintf "Unit:     [%d]\n", $self->unit;
        $ret_value .= sprintf "Function: [%d] %s\n",
            $self->function,
            Device::Modbus::Message->function_for($self->function);
        $ret_value .= sprintf "PDU:      [%s]\n", $self->pdu;
        $ret_value .= sprintf "Bare message: [%s]\n", $self->message;
        $ret_value .= "----------\n";
    }

    return $ret_value;
}

sub parse_message {
    my ($self, $message) = @_;

    $self->clear_object(undef);
    
    ### Break message
    my ($unit, $pdu, $footer) = $self->break_message($message);
    defined $unit && defined $pdu && defined $footer || return undef;
    
    my $function_code = unpack 'C', $pdu;
    defined $function_code || return undef;

    $self->_set_unit($unit);
    $self->_set_function($function_code);
    $self->_set_pdu(join('-', map { unpack 'H*' } split //, $pdu));
    $self->_set_cdc(join('-', map { unpack 'H*' } split //, $footer));

    if ($function_code > 0x80) {
        my $exc = Device::Modbus->parse_exception($pdu);
        $self->_set_object($exc) if ref $exc;
    }
    else {
        my $req = Device::Modbus->parse_request($pdu);
        my $res = Device::Modbus->parse_response($pdu);

        if (!defined $req && $res) {
            $self->_set_object($res);
        }
        elsif ($req) {
            $self->_set_object($req);
        }
    }

    $self->object->unit($unit);

    return $self;
}

sub clear_object {
    my $self = shift;
    $self->_set_unit(undef);
    $self->_set_function(undef);
    $self->_set_pdu(undef);
    $self->_set_cdc(undef);
    $self->_set_message(undef);
    $self->_set_object(undef);
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
