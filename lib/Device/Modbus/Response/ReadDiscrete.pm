package Device::Modbus::Response::ReadDiscrete;

use overload '""' => \&stringify;
use Moo;

extends 'Device::Modbus::Message';

has bytes        => (is => 'lazy');
has values       => (is => 'ro', required => 1);
has _flat_values => (is => 'lazy');

sub _build_bytes {
    my $self = shift;
    my $values = $self->_flat_values;
    return scalar @$values;
}

sub _build__flat_values {
    my $self = shift;
    my ($quantity, $values) = $self->flatten_bit_values($self->values);
    return $values;
}

sub _build_pdu {
    my $self   = shift;
    my $values = $self->_flat_values;
    my $bytes  = $self->bytes;
    my @pdu    = ($self->function_code, $bytes);
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
        . 'Values: ['. join(', ', @{$self->values}) . ']';
}

1;
