package Device::Modbus::Server::TCP;

use Device::Modbus;
use Device::Modbus::TCP;
use Device::Modbus::Transaction;
use Device::Modbus::Exception;
use Moo;

with 'Device::Modbus::TCP', 'Device::Modbus::Server';
extends qw(Net::Daemon);

sub FOREIGNBUILDARGS {
    my ($class, $attrs, $args) = @_;

    # These are default options, to override by config file or
    # command-line arguments
    $attrs = {} unless defined $attrs;
    my %attrs = (
        pidfile   => 'none',
        localport => 502,
        logfile   => 'STDERR',
        verbose   => 0,
        %$attrs
    );

    return \%attrs, $args;
}

sub Run {
    my $self = shift;
    my $sock = $self->{'socket'};

    while (1) {
        # Read request
        my $msg;
        my $rc = $sock->recv($msg, 260);
        unless (defined $rc) {
            $self->Error('Communication error while receiving data');
            last;
        }
        next unless $msg;
        
        $self->Log('notice', 'Received message from ' . $sock->peerhost);

        # Parse request and issue a new transaction
        my ($trn_id, $unit, $pdu) = $self->break_message($msg);
        if (!defined $trn_id) {
            $self->Error('Request error: Transaction number not received');
            return;
        }

        #### Call generic server routine
        my $resp = $self->modbus_server($unit, $pdu);

        # Transaction is needed to build response message
        my $trn = Device::Modbus::Transaction->new(
            id      => $trn_id,
            unit    => $unit
        );

        my $apu = $self->build_apu($trn, $resp->pdu);
        $rc = $sock->send($apu);

        unless (defined $rc) {
            $self->Error('Communication error while sending response');
            last;
        }
    }
    $sock->close;
}

sub start {
    shift->Bind;
}
 
1;
