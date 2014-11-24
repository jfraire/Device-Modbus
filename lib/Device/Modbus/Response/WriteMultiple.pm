package Device::Modbus::Response::WriteMultiple;

use Moo;

extends 'Device::Modbus::Message';

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

    return $class->new(
        function => $args{function},
        address  => $address,
        quantity => $quantity,
        pdu      => $args{message}
    );
}

1;
