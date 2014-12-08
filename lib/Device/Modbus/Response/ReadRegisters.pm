package Device::Modbus::Response::ReadRegisters;

use overload '""' => \&stringify;
use Moo;

extends 'Device::Modbus::Message';

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

sub stringify {
    my $self = shift;
    return 'Response: Function: [' . $self->function .'] '
        . 'Bytes: [' . $self->bytes . '] '
        . 'Values: ['. join(', ', @{$self->values}) . ']';
}

1;
