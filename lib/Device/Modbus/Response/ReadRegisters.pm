package Device::Modbus::Response::ReadRegisters;

use Moo;
use Carp;

extends 'Device::Modbus::Response';

has bytes    => (is => 'rw');
has values   => (is => 'ro', required => 1);

sub _build_pdu {
    my $self = shift;
    my $bytes = 2 * scalar @{$self->values};
    $self->bytes($bytes);
    my @pdu = ($self->function_code, $bytes, @{$self->values});
    return pack 'CCn*', @pdu;
}

sub parse_message {
    my ($class, %args) = @_;

    my ($code, $bytes, @values) = unpack 'CCn*', $args{message};

    return $class->new(
        function => $args{function},
        bytes    => $bytes,
        values   => \@values,
        pdu      => $args{message}
    );
}

1;
