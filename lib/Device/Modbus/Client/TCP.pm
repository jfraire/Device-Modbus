package Device::Modbus::Client::TCP;

use Device::Modbus;
use Device::Modbus::TCP;
use IO::Socket::INET;
use Time::HiRes qw(time);
use Moo;

has host     => (is => 'ro', default => sub {'127.0.0.1'});
has port     => (is => 'ro', default => sub {502});
has unit     => (is => 'ro', default => sub {0xff});
has blocking => (is => 'ro', default => sub {1});
has timeout  => (is => 'rw', default => 0.2);
has socket => (is => 'rw', builder => 1, handles => [qw(connected close)]);

has waiting_room     => (is => 'rw', default => sub { +{} });
has max_transactions => (is => 'rw', default => sub {16});

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

#### Transaction handling

my $transaction_id = 0;

# Probably useless...
sub request_transaction {
    my ($self, $req) = @_;
    my $trn = $self->init_transaction || return undef;
    $trn->request($req);
    return $trn;
}

sub next_trn_id {
    my $self = shift;

    return if scalar keys %{$self->waiting_room} >= $self->max_transactions;

    $transaction_id++;
    $transaction_id = 1 if $transaction_id > 65_535;
    $self->waiting_room->{$transaction_id}++;
    return $transaction_id;
}

sub init_transaction {
    my $self = shift;
    my $id   = $self->next_trn_id || return;
    my $trn  = Device::Modbus::Transaction->new(
        id      => $id,
        timeout => $self->timeout,
        unit    => $self->unit
    );
    return $trn;
}

#### Transaction management

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
    my $pdu   = $trn->request_pdu;
    my $apu   = Device::Modbus::TCP->build_apu($trn, $pdu);
    my $bytes = $self->socket->send($apu)
      || return undef;
    return undef unless $bytes eq length($apu);
    $trn->set_expiration_time(time());
    $self->move_to_waiting_room($trn);
    return $bytes;
}

sub receive_response {
    my $self = shift;
    my $message;

    my $ret = $self->socket->recv($message, 260);
    return undef if !defined $ret;
    return 0 unless length $message;

    my ($trn_id, $unit, $pdu) = Device::Modbus::TCP->break_message($message);
    return undef unless defined $trn_id;

    my $trn  = $self->get_from_waiting_room($trn_id);
    my $resp = Device::Modbus->parse_response($pdu);
    $trn->response($resp);
    return $trn;
}

1;
