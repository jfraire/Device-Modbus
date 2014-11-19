package Device::Modbus::Client;

use Moo;
use Carp;

has timeout => (is => 'rw', default  => 0.2);

#### Transaction handling

sub request_transaction {
    my ($self, $req) = @_;
    my $trn = $self->init_transaction || return undef;
    $trn->request($req);
    return $trn;
}

sub init_transaction {
    croak 'init_transaction must be implemented by a subclass of '
        . 'Device::Modbus::Client';
}

#### Communication interface

sub send_request {
    croak 'send_request method must be implemented by a subclass of '
        . 'Device::Modbus::Client';
}

sub read_response {
    croak 'read_response method must be implemented by a subclass of '
        . 'Device::Modbus::Client';
}

1;
