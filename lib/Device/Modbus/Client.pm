package Device::Modbus::Client;

use Device::Modbus::Transaction;
use Moo;
use Carp;

has unit        => (is => 'ro', default  => sub {0xff});
has timeout     => (is => 'rw', default  => 0.2);
has transaction => (is => 'rw');

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
    my $trn = Device::Modbus::Transaction->new(
        id      => $id,
        timeout => $self->timeout,
        unit    => $self->unit
    );
    $self->transaction($trn);
    return $trn;
}

sub clear_transaction {
    my $self = shift;
    my $trn = $self->transaction;
    $self->transaction(undef);
    return $trn;
}

#### Communication interface

sub send_request {
    croak 'send_request method must be implemented by a subclass of '
        . 'Device::Modbus::Client';
}

sub receive_response {
    croak 'read_response method must be implemented by a subclass of '
        . 'Device::Modbus::Client';
}

sub close {
    croak 'close method must be implemented by a subclass of '
        . 'Device::Modbus::Client';
}

1;
