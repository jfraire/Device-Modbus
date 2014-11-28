package Device::Modbus::Server::TCP;

use Device::Modbus;
use Device::Modbus::TCP;
use Device::Modbus::Transaction;
use Device::Modbus::Exception;
use parent 'Net::Daemon';

use strict;
use warnings;


sub new {
    my ($class, $attrs, $args) = @_;

    # These are default options, to override by config file or
    # command-line arguments
    my %attrs = (
        pidfile   => 'none',
        localport => 502,
        logfile   => 'STDERR',
        %$attrs
    );

    my $server = $class->SUPER::new(\%attrs, $args);
    return $server;
}

sub Run {
    my $self = shift;
    my $sock = $self->{'socket'};

    # Read request
    my $msg;
    my $rc = $sock->recv($msg, 260);
    unless (defined $rc) {
        $self->Error('Communication error');
        return;
    }
    $self->Log('notice', 'Received message from ' . $sock->peerhost);

    # Parse request and issue a new transaction
    my ($trn_id, $unit, $pdu) = Device::Modbus::TCP->break_message($msg);
    if (!defined $trn_id) {
        $self->Error('Request error');
        return;
    }

    my $resp = $self->modbus_server($unit, $pdu);

    # Transaction is needed to build response message
    my $trn = Device::Modbus::Transaction->new(
        id      => $trn_id,
        unit    => $unit
    );

    if (ref $resp) {
        return $sock->send(Device::Modbus::TCP->build_apu($trn, $response->pdu));
    }
    
    my $exception = Device::Modbus::Exception->new(
        function       => $trn->request->function,
        exception_code => 0x04
    );

    $sock->send(Device::Modbus::TCP->build_apu($trn, $exception->pdu));
}
 
1;
