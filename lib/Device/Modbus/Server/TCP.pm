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

    my $trn = Device::Modbus::Transaction->new(
        id      => $trn_id,
        unit    => $unit
    );

    my $req = Device::Modbus->parse_request($pdu);
    
    # Treat unimplemented functions -- return exception 1
    # (exception is saved in request object)
    if (!ref $req) {
        my $exception = Device::Modbus::Exception->new(
            function       => $req,    # Function requested
            exception_code => 1        # Unimplemented function
        );
            
        $sock->send(Device::Modbus::TCP->build_apu($trn, $exception->pdu));
        $self->Log('notice',
            "Function unimplemented: $req in transaction $trn_id"
            . ' from '
            . $sock->peerhost);
        return;
    }

    
    # Real work goes here.
    $self->Log('notice', "Received a " . $req->function
        . " request (transaction $trn_id)");

    $trn->request($req);
    my $response;
    my $exception;

    eval { $response = $self->run_app($trn) };

    if (defined $response && !$@) {
        return $sock->send(Device::Modbus::TCP->build_apu($trn, $response->pdu));
    }
    else {
        my $err_msg =
              "Client:      " . $sock->peerhost
            . "Unit:        " . $trn->unit
            . "Transaction: " . $trn->id
            . "Function:    " . $trn->request->function
            ;
        if ($@) {
            $self->Error("Application crashed: $@\n" . $err_msg);
        }
        elsif (!defined $response) {
            $self->Error("Application did not return a response: $@\n"
                . $err_msg);
        }
    
        $exception = Device::Modbus::Exception->new(
            function_code  => $trn->request->function_code,
            exception_code => 0x04
        );
    }
    $sock->send(Device::Modbus::TCP->build_apu($trn, $exception->pdu));
}
 
1;
