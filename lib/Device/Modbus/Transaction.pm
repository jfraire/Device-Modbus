package Device::Modbus::Transaction;

use Moo;

has id          => (is => 'ro', required => 1);
has unit        => (is => 'ro', default => sub {0xff});
has request     => (is => 'rw', handles => {request_pdu  => 'pdu'}, predicate => 1);
has response    => (is => 'rw', handles => {response_pdu => 'pdu'}, predicate => 1);
has timeout     => (is => 'rw');
has expires     => (is => 'rw');
has max_retries => (is => 'rw', default => sub {3});
has retries     => (is => 'rw', default => sub {0});

sub increment_retries {
    my $self = shift;
    my $retries = $self->retries;
    $retries++;
    $self->retries($retries);
    return $retries;
}

sub set_expiration_time {
    my ($self, $time) = @_;
    $self->expires($time + $self->timeout);
}

1;
