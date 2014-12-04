package Device::Modbus::Server::TCP;

use Device::Modbus;
use Device::Modbus::TCP;
use Device::Modbus::Transaction;
use Device::Modbus::Exception;
use Role::Tiny::With;
use parent qw(Net::Daemon Device::Modbus::Server);

use Data::Dumper;

with 'Device::Modbus::TCP';
use strict;
use warnings;


sub new {
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

    my $server = $class->SUPER::new(\%attrs, $args);
    $server->init_server;
    return $server;
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
            return;
        }
        return unless $msg;
        
        $self->Log('notice', 'Received message from ' . $sock->peerhost);

        # Parse request and issue a new transaction
        my ($trn_id, $unit, $pdu) = $self->break_message($msg);
        if (!defined $trn_id) {
            $self->Error('Request error: Transaction number not received');
            return;
        }

        #### Call generic server routine
        my $func = ord(substr $pdu,0,1);
        my $resp = $self->modbus_server($unit, $pdu);

        # Transaction is needed to build response message
        my $trn = Device::Modbus::Transaction->new(
            id      => $trn_id,
            unit    => $unit
        );

        if (ref $resp) {
            my $apu = $self->build_apu($trn, $resp->pdu);
            $sock->send($apu);
            next;
        }
        
        my $exception = Device::Modbus::Exception->new(
            unit           => $unit,
            function       => Device::Modbus::Exception->function_for($func),
            exception_code => 0x04
        );

        my $apu = $self->build_apu($trn, $exception->pdu);
        $rc = $sock->send($apu);

        unless (defined $rc) {
            $self->Error('Communication error while sending response');
            return;
        }
    }
    $sock->close;
}
 
1;
