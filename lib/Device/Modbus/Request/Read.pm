package Device::Modbus::Request::Read;

use Moo;
use Carp;

extends 'Device::Modbus::Request';

has address  => (is => 'ro', required => 1);
has quantity => (is => 'ro', required => 1);

sub _build_pdu {
    my $self = shift;
    my @pdu  = ($self->function_code, $self->address-1, $self->quantity);
    return pack 'Cnn', @pdu;
}

sub parse_message {
    my ($class, %args) = @_;

    my ($code, $address, $quantity) = unpack 'Cnn', $args{message};

    $address++;
    if (   $code <= 2 && ($quantity < 1 || $quantity > 2000)
        || $code  > 2 && ($quantity < 1 || $quantity > 125 )) {
        return Device::Modbus::Exception->new(
            function_code  => $code,
            exception_code => 3
        );
    }

    return $class->new(
        function => $args{function},
        address  => $address,
        quantity => $quantity,
        pdu      => $args{message}
    );
}

1;
