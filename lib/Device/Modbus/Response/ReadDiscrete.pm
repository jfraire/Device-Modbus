package Device::Modbus::Response::ReadDiscrete;

use Moo;

extends 'Device::Modbus::Message';

use overload '""' => \&stringify;
has bytes    => (is => 'rw');
has values   => (is => 'ro', required => 1);

sub _build_pdu {
    my $self = shift;
    my ($quantity, $values) = $self->flatten_bit_values($self->values);
    my $bytes = scalar @$values;
    $self->bytes($bytes);
    my @pdu = ($self->function_code, $bytes);
    return pack('CCC*', @pdu) . join '', @$values;
}

sub parse_message {
    my ($class, %args) = @_;

    my ($code, $bytes, @values) = unpack 'CCC*', $args{message};
    @values = Device::Modbus::Message->explode_bit_values(8*$bytes, @values);

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
        . 'Values: ['. join('-', @{$self->values}) . ']';
}

1;
