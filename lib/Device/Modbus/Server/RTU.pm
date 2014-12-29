package Device::Modbus::Server::RTU;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use Moo;

has unit => (is => 'ro', required => 1);

with 'Device::Modbus::Server', 'Device::Modbus::RTU';

sub start {
    my $self = shift;

    while (1) {
        my $message = $self->read_port;
        next unless $message;
                
        my ($unit, $pdu, $footer) = $self->break_message($message);
        warn "Failed breaking message!" unless defined $unit; 
        
        # Listen only for the given Modbus address
        next if ($self->unit != $unit);

        # Go through the generic server routine
        my $req  = Device::Modbus->parse_request($pdu);
        my $resp = $self->modbus_server($unit, $req);

        $self->write(
            $self->build_adu($resp)
        ) || warn "Failed sending response!";
    }
}

1;

__END__

=head1 NAME Device::Modbus::Server::RTU - Modbus RTU server in Perl

=head1 SYNOPSIS

    use My::Unit;
    use Modbus::Server::RTU;
    use strict;
    use warnings;

    my $server = Modbus::Server::RTU->new(
        port => '/dev/ttyUSB0',
    );

    $server->add_server_unit('My::Unit', 1);
    $server->start;

=head1 DESCRIPTION

This module implements a simple Modbus RTU server. It works over a serial port, normally using an RS485 bus.

=head1 USAGE

Please see L<Device::Modbus::Server> first, as it contains a much broader discussion of this server. The server for Modbus RTU is so simple that we only have to discuss the constructor here.

=head2 Constructor

The constructor is in fact a result of applying the role Device::Modbus::RTU, which contains the definition of the serial port. It can take the following arguments:

=over

=item * port (required)

=item * databits (default: 8)

=item * stopbits (default: 1)

=item * parity (default: even. Other valid values are 'none' and 'odd')

=item * baudrate (default: 9600)

=item * timeout (default: 2, in seconds)

=back

All these attributes have accessors of the same name.

Device::Modbus::RTU uses L<Device::SerialPort> and so it is does not work in Windows (but this should be easy to change).

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
