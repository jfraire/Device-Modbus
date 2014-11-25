package Device::Modbus::Client::TCP;

use Device::Modbus;
use Device::Modbus::TCP;
use IO::Socket::INET;
use Time::HiRes qw(time);
use Moo;

has host                 => (is => 'ro', default  => sub {'127.0.0.1'});
has port                 => (is => 'ro', default  => sub {502});
has max_transactions     => (is => 'rw', default  => sub {16});
has waiting_room         => (is => 'rw', default  => sub {+{}});

has blocking             => (is => 'ro', default  => sub {1});
has socket               => (is => 'rw', builder  => 1, handles => ['connected']);

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
    my $bytes = $self->socket->send(Device::Modbus::TCP->build_apu($trn, $pdu))
        || return undef;
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
    
    my $trn = $self->get_from_waiting_room($trn_id);
    my $resp = Device::Modbus->parse_response($pdu);
    $trn->response($resp);
    return $trn;
}

sub close {
    my $self = shift;
    my $ret = $self->socket->close;
    $self->socket(undef);
    return $ret;
}

1;
