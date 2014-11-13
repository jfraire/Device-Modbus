package Device::Modbus::Response::WriteSingle;

use Moo;
use Carp;

extends 'Device::Modbus::Response';

has address  => (is => 'ro', required => 1);
has value    => (is => 'ro', required => 1);

sub _build_pdu {
    my $self = shift;
    my $value = $self->value;
    if ($self->function eq 'Write Single Coil') {
        $value = $self->{value} ? 0xFF00 : 0;
    }
    my @pdu  = ($self->function_code, $self->address-1, $value);
    return pack 'Cnn', @pdu;
}

sub parse_message {
    my ($class, %args) = @_;

    my ($code, $address, $value) = unpack 'Cnn', $args{message};

    $value = 1 if $code == 5 && $value;

    $address++;

    return $class->new(
        function => $args{function},
        address  => $address,
        value    => $value,
        pdu      => $args{message}
    );
}

1;
