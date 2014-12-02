package Device::Modbus::Exception;

use Moo;
extends 'Device::Modbus::Message';

has exception_code => (is => 'ro', required => 1);

sub _build_pdu {
    my $self = shift;
    return pack 'Cn', $self->function_code + 0x80, $self->exception_code;
}

1;

