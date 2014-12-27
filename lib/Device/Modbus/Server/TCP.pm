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
        user        => 'nobody',
        group       => 'nogroup',
        max_servers => 20,
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
        $self->log(4, "Request: $req");

        #### Call generic server routine
        my $resp = $self->modbus_server($unit, $req);
        $self->log(4, "Response: $resp");

        # Transaction is needed to build response message
        my $trn = Device::Modbus::Transaction->new(
            id      => $trn_id,
            unit    => $unit
        );

        my $apu = $self->build_apu($trn, $resp->pdu);

        eval {
            alarm $self->timeout;
            my $rc = $sock->send($apu);
            unless (defined $rc) {
                $self->log(1, 'Communication error while sending response');
                last;
            }
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
