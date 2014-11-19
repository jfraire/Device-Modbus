package Device::Modbus::Client::TCP;

use Device::Modbus::Response;
use Device::Modbus::Transaction::TCP;
use IO::Socket::INET;
use Time::HiRes qw(time);
use Moo;

has host                 => (is => 'ro', default  => sub {'127.0.0.1'});
has port                 => (is => 'ro', default  => sub {502});
has unit                 => (is => 'ro', default  => sub {0xff});
has max_transactions     => (is => 'rw', default  => sub {16});
has waiting_room         => (is => 'rw', default  => sub {+{}});

has blocking             => (is => 'ro', default  => sub {1});
has socket               => (is => 'lazy', handles => ['connected']);

extends 'Device::Modbus::Client';

sub _build_socket {
    my $self = shift;

    return IO::Socket::INET->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
        Blocking => $self->blocking,
        Timeout  => $self->timeout,
        Proto    => 'tcp'
    );
}

#### Transaction management

my $transaction_id = 0;

sub next_trn_id {
    my $self = shift;

    return if scalar keys %{ $self->waiting_room }
        >= $self->max_transactions;

    $transaction_id++;
    $transaction_id = 1 if $transaction_id > 65_535;
    $self->waiting_room->{$transaction_id}++;
    return $transaction_id;
}

sub init_transaction {
    my $self = shift;
    my $id = $self->next_trn_id || return;
    my $trn = Device::Modbus::Transaction::TCP->new(
        id      => $id,
        timeout => $self->timeout,
        unit    => $self->unit
    );
    return $trn;
}

sub move_to_waiting_room {
    my ($self, $trn) = @_;
    $self->waiting_room->{$trn->id} = $trn;
}

sub get_from_waiting_room {
    my ($self, $trn_id) = @_;
    return delete $self->waiting_room->{$trn_id};
}

#### Connection management

sub send_request {
    my ($self, $trn) = @_;
    my $bytes = $self->socket->send($trn->build_request_apu)
        || return undef;
    $trn->set_expiration_time(time());
    $self->move_to_waiting_room($trn);
    return $bytes;
}

sub receive_response {
    my $self = shift;
    my $message;
    $self->socket->recv($message, 256);
    my ($trn_id, $unit, $pdu) = $self->break_response($message);
    my $trn = $self->get_from_waiting_room($trn_id);
    my $resp = Device::Modbus::Response->parse_response($pdu);
    $trn->response($resp);
    return $trn;
}

sub close {
    my $self = shift;
    return $self->socket->close;
}

#### Message parsing

sub break_response {
    my ($self, $message) = @_;
    my ($id, $proto, $length, $unit) = unpack 'nnnC', $message;
    my $pdu = substr $message, 7;
    warn "Length is not legal" if length($pdu) != $length-1; 
    return $id, $unit, $pdu;
}

1;
