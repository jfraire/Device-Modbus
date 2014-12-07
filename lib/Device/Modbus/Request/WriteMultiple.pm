package Device::Modbus::Request::WriteMultiple;

use overload '""' => \&stringify;
use Moo;

extends 'Device::Modbus::Message';

has address => (is => 'ro', required => 1);
has values  => (is => 'ro', required => 1);
has quantity => (is => 'lazy');

sub _build_pdu {
    my $self = shift;
    if ($self->function_code == 0x0f) {
        return $self->_build_pdu_to_write_multiple_coils;
    }
    else {
        return $self->_build_pdu_to_write_multiple_registers;
    }
}

sub _build_pdu_to_write_multiple_coils {
    my $self = shift;

    my ($quantity, $values) = $self->flatten_bit_values($self->values);

    # Build the pdu
    my @pdu =
      ($self->function_code, $self->address - 1, $quantity, scalar(@$values));
    return pack('CnnC', @pdu) . join '', @$values;
}

sub _build_pdu_to_write_multiple_registers {
    my $self = shift;

    # Values is an array reference of numbers
    my @values   = @{$self->values};
    my $quantity = $self->quantity;

    # Build the pdu
    my @pdu = (
        $self->function_code, $self->address - 1,
        $quantity, 2 * $quantity, @values
    );
    return pack 'CnnCn*', @pdu;
}

sub _build_quantity {
    my $self   = shift;
    my @values = @{$self->values};
    return scalar @values;
}

sub parse_message {
    my ($class, %args) = @_;

    my $code = unpack 'C', $args{message};
    my ($address, $quantity, $bytes, @values);

    if ($code == 0x0f) {
        ($code, $address, $quantity, $bytes, @values) = unpack 'CnnCC*',
          $args{message};
        @values =
          Device::Modbus::Message->explode_bit_values($quantity, @values);

    }
    else {
        ($code, $address, $quantity, $bytes, @values) = unpack 'CnnCn*',
          $args{message};
    }

    $address++;
    return $class->new(
        function => $args{function},
        address  => $address,
        quantity => $quantity,
        values   => \@values,
        pdu      => $args{message}
    );
}

sub stringify {
    my $self = shift;
    return 'Request: Function: [' . $self->function .'] '
        . 'Address: [' . sprintf ('%#.2x', $self->address). '] '
        . 'Quantity: ['. $self->quantity . '] '
        . 'Values: [' . join('-', @{$self->values}) . ']';
}

1;
