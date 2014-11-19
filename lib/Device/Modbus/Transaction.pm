package Device::Modbus::Transaction;

use Moo;

has id          => (is => 'ro', required => 1);
has request     => (is => 'rw', handles => {request_pdu  => 'pdu'}, predicate => 1);
has response    => (is => 'rw', handles => {response_pdu => 'pdu'}, predicate => 1);
has timeout     => (is => 'rw', default => sub {1});
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

sub build_request_apu {
    my $self   = shift;
    my $pdu    = $self->request_pdu;
    my $header = $self->header($pdu);
    my $footer = $self->footer($pdu);
    my $apu    = $header . $pdu . $footer;
    return $apu;
}

sub build_response_apu {
    my $self   = shift;
    my $pdu    = $self->response_pdu;
    my $header = $self->header($pdu);
    my $footer = $self->footer($pdu);
    my $apu    = $header . $pdu . $footer;
    return $apu;
}

sub set_expiration_time {
    my ($self, $time) = @_;
    $self->expires($time + $self->timeout);
}

1;
