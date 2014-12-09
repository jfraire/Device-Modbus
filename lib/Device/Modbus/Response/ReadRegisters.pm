package Device::Modbus::Response::ReadRegisters;

use overload '""' => \&stringify;
use Moo;

extends 'Device::Modbus::Message';

has bytes    => (is => 'lazy');
has values   => (is => 'ro', required => 1);

sub _build_bytes {
    my $self = shift;
    return 2 * scalar @{$self->values};
}

sub _build_pdu {
    my $self = shift;
    my @pdu = ($self->function_code, $self->bytes, @{$self->values});
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

sub stringify {
    my $self = shift;
    return 'Response: Function: [' . $self->function .'] '
        . 'Bytes: [' . $self->bytes . '] '
        . 'Values: ['. join(', ', @{$self->values}) . ']';
}

1;
