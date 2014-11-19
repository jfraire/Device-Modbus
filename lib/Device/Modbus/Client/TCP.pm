package Device::Modbus::Client::TCP;


use Time::HiRes qw(time);
use Moo;
use Carp;

has host                 => (is => 'ro', default  => '127.0.0.1');
has port                 => (is => 'ro', default  => 502);
has unit                 => (is => 'ro', default  => 0xff);
has max_transactions     => (is => 'rw', default  => 16);
has waiting_room         => (is => 'rw', default  => sub {+{}});

has blocking             => (is => 'ro', default  => 0 );
has socket               => (is => 'rwp');

extends 'Device::Modbus::Client';

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
        timeout => $self->timeout
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

1;
