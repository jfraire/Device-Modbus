package Device::Modbus::Server::TCP;

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
    my ($trn_id, $unit, $pdu) = $self->break_message($msg);
    if (!defined $trn_id) {
        $self->Error('Request error');
        return;
    }

    my $req = Device::Modbus->parse_request($pdu);
    my $trn = Device::Modbus::Transaction->new(
        id      => $trn_id,
        unit    => $unit,
        request => $req
    );
    
    # Treat unimplemented functions -- return exception 1
    # (exception is saved in response object)
    if (ref $req eq 'Device::Modbus::Exception') {
        $sock->send($trn->build_request_apu);
        $self->Log('notice', "Function unimplemented: "
            . $req->function
            . ' in transaction '
            . $trn->$trn_id
            . ' from '
            . $sock->peerhost);
        return;
    }
    
    # Real work goes here.
    $self->Log('notice', "Received a " . $req->function . " request");

    my $response;
    my $exception;
    eval { $response = $self->run_app($trn) };

    if (defined $response && !$@) {
        $trn->response($response);
        $sock->send($trn->build_response_apu);
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

    $trn->response($exception);
    $sock->send($trn->build_response_apu);
}

#### Message parsing

sub break_message {
    my ($self, $message) = @_;
    my ($id, $proto, $length, $unit) = unpack 'nnnC', $message;
    my $pdu = substr $message, 7;
    return if length($pdu) != $length-1; 
    return $id, $unit, $pdu;
}
 
1;
