package Device::Modbus::Server::TCP;

use Device::Modbus;
use Device::Modbus::TCP;
use Device::Modbus::Transaction;
use Device::Modbus::Exception;
use Moo;

with 'Device::Modbus::TCP', 'Device::Modbus::Server';
extends qw(Net::Server::PreFork);

has timeout => (is => 'rw', default => sub { 3 });

sub default_values {
    return {
        log_level   => 2,
        log_file    => undef,
        port        => 502,
        host        => '*',
        ipv         => 4,
        proto       => 'tcp',
    };
}

sub process_request {
    my $self = shift;
    my $sock = $self->{server}->{client};

    local $SIG{'ALRM'} = sub { die "Connection timed out\n" };

    while (1) {
        # Read request
        my $msg;
        eval {
            alarm $self->timeout;
            until (defined $msg) {
                my $rc = $sock->recv($msg, 260);
                unless (defined $rc) {
                    $self->log(1, 'Communication error while receiving data');
                    return;
                }
            }
            alarm 0;
        };
        if ($@ =~ /Connection timed out/ || length($msg) == 0) {
            last;
        }
        
        $self->log(3, 'Received message from ' . $sock->peerhost);

        # Parse request and issue a new transaction
        my ($trn_id, $unit, $pdu) = $self->break_message($msg);
        if (!defined $trn_id) {
            $self->log(1, 'Request error: Transaction number not received');
            return;
        }

        ### Parse message
        my $req = Device::Modbus->parse_request($pdu);
        $self->log(4, "> $req");

        #### Call generic server routine
        my $resp = $self->modbus_server($unit, $req);
        $self->log(4, "< Response: $resp");

        # Transaction is needed to build response message
        my $trn = Device::Modbus::Transaction->new(id => $trn_id);

        my $apu = $self->build_adu($trn, $resp);

        eval {
            alarm $self->timeout;
            my $rc = $sock->send($apu);
            unless (defined $rc) {
                $self->log(1, 'Communication error while sending response');
                last;
            }
            $self->log(4, 'Sent response');
            alarm 0;
        };
        if ($@ =~ /Connection timed out/) {
            last;
        }
    }
    $self->log(3, 'Client disconnected');
}

sub start {
    shift->run;
}
 
1;

__END__

=head1 NAME Device::Modbus::Server::TCP -- Modbus TCP server class

=head1 SYNOPSIS

    use My::Unit;
    use Device::Modbus::Server::TCP;
    use strict;
    use warnings;

    my $server = Device::Modbus::Server::TCP->new(
        log_level         =>  2,
        min_servers       => 10,
        max_servers       => 30,
        min_spare_servers => 5,
        max_spare_servers => 10,
        max_requests      => 1000,
    );

    $server->add_server_unit('My::Unit', 1);
    $server->start;

=head1 DESCRIPTION

One of the goals for L<Device::Modbus> is to have the ability to write Modbus servers that execute arbitrary code. This class defines the Modbus TCP version of such servers. Please see the documentation in L<Device::Modbus::Server> for a thorough description of the interface; refer to this document only for the details inherent to Modbus TCP.

=head1 USAGE

Besides the description in L<Device::Modbus::Server>, this server obtains its functionality from L<Net::Server::PreFork>, from which it inherits. Be sure to read carefully their documentation.

Device::Modbus::Server::TCP binds to the given port (502 by default) and then forks C<min_servers> child processes. The server will make sure that at any given time there are C<min_spare_servers> available to receive a client request, up to C<max_servers>. Each of these children will process up to C<max_requests> client connections. This should allow for a heavily hit server.

=head1 CONFIGURATION

All the configuration possibilities found in L<Net::Server::PreFork> are available. The default parameters for Device::Modbus::Server::TCP are:

    log_level   => 2,
    log_file    => undef,
    port        => 502,
    host        => '*',
    ipv         => 4,
    proto       => 'tcp',

=head1 Net::Server::PreFork METHODS USED

The methods defined by Net::Server::PreFork and used by Device::Modbus::Server::TCP are:

=head2 default_values

This is used only to pass the default parameters of the server. Note that this is the lowest priority form of configuration; these values can be overwritten by passing arguments to C<new>, by passing command-line arguments, by passing arguments to C<run>, or by using a configuration file. You can, of course, write your own C<default_values> method in a sub-class.

=head2 process_request

This is where the generic Modbus server method is called. It listens for requests, processes them, and returns the responses.

=head1 NOTES

In the examples directory, there is a program called LoadTester.pl which is a modified version of the one which comes with Net::Server. It uses a pre-forking client to issue as many requests as possible to a server and then reports its failure rate and load. This program was modified to work against the example server. It would be interesting to run the program in one computer and the server in another one to test server performance.

While Modbus RTU processes are single-process, this server is not. It is important to notice that, because of its forking nature, each process has its own copy of the units you defined. While there are indeed mechanisms for them to communicate (see Net::Server), in general they are completely independent. Global variables are then global by process only and not accross the whole process group. This boils down to the fact that the example server in this distribution, which keeps register values in a per-process global variable, will not work in a real work scenario. It would be necessary to persist registers outside of the server, like in a database.

Net::Server::PreFork is also at the heart of L<Starman>, a high-performance, Perl-based web server.

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

