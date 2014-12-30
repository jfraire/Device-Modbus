package Device::Modbus::Server::RTU;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use Moo;

has log_level => (is => 'rw', default => sub { 2 });
has running   => (is => 'rw', default => sub { 0 });

with 'Device::Modbus::Server', 'Device::Modbus::RTU';

sub BUILD {
    my $self = shift;

    # Install a signal handler to shut down: QUIT
    $SIG{QUIT} = sub {
        $self->stop;
        $self->log(2, 'Server is shutting down');
    };
}

sub stop {
    my $self = shift;
    $self->running(0);
}

sub start {
    my $self = shift;

    $self->running(1);
    $self->log(2, 'Server has started');
    
    while ($self->running) {
        my $message = $self->read_port;
        next unless $message;

        $self->log(4, 'Message received: ' . unpack 'H*', $message);
        
        my ($unit, $pdu, $footer) = $self->break_message($message);
        if (!defined $unit) {
            $self->log(1, sub {
                "Failed breaking received message! "
                . unpack 'H*', $message;
            });
            next;
        }
        
        # Listen only for the given Modbus address
        next if (!exists $self->units->{$unit});

        # Go through the generic server routine
        my $req  = Device::Modbus->parse_request($pdu);
        $self->log(4, sub {"-> $req"});

        my $resp = $self->modbus_server($unit, $req);
        $self->log(4, sub {"<- $resp"});

        my $adu = $self->build_adu($resp);
        $self->write($adu)
            || $self->log(1, "Failed sending response!");
    }
}


# Logger routine. It will simply print messages on STDERR.
# It accepts a logging level and a message. If the level is equal
# or less than $self->log_level, the message is processed.
# To avoid unnecessary processing, messages that require processing can
# be sent in the form of a code reference to minimize performance hits.
# It will add a stringified level, the localtime string
# and caller information.
# It conforms to the interface provided by Net::Server; the subroutine
# idea comes from Log::Log4Perl.
my %level_str = (
    0 => 'ERROR',
    1 => 'WARNING',
    2 => 'NOTICE',
    3 => 'INFO',
    4 => 'DEBUG',
);

sub log {
    my ($self, $level, $msg) = @_;
    return unless $level <= $self->log_level;
    my $time = localtime();
    my ($package, $filename, $line) = caller;

    my $message = ref $msg ? $msg->() : $msg;
    
    print STDOUT
        "$level_str{$level} : $time > $0 in $package "
        . "($filename line $line): $message\n";
    return 1;
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
