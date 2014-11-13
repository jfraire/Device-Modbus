package Device::Modbus::Request::WriteMultiple;

use Moo;
use Carp;

extends 'Device::Modbus::Request';

has address  => (is => 'ro', required => 1);
has values   => (is => 'ro', required => 1);
has quantity => (is => 'rw');

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

    my ($quantity, $values) = Device::Modbus::flatten_bit_values($self->values);

    # Build the pdu
    my @pdu = ($self->function_code, $self->address-1, $quantity,
        scalar(@$values));
    return pack('CnnC', @pdu) . join '', @$values;
}

sub _build_pdu_to_write_multiple_registers {
    my $self = shift;
    
    # Values is an array reference of numbers
    my @values   = @{$self->values};
    my $quantity = scalar @values;
    $self->quantity($quantity);

    # Build the pdu
    my @pdu = ($self->function_code, $self->address-1,
        $quantity, 2*$quantity, @values);
    return pack 'CnnCn*', @pdu;
}


sub parse_message {
    my ($class, %args) = @_;

    my $code = unpack 'C', $args{message};
    my ($address, $quantity, $bytes, @values);
    
    if ($code == 0x0f) {
        ($code, $address, $quantity, $bytes, @values)
            = unpack 'CnnCC*', $args{message};

        unless ($quantity >= 1 && $quantity <= 0x07b0) {
            return Device::Modbus::Exception->new(
                function_code  => $code,
                exception_code => 3
            );
        }

        @values = Device::Modbus::explode_bit_values($quantity, @values);

    } else {
        ($code, $address, $quantity, $bytes, @values)
            = unpack 'CnnCn*', $args{message};

        unless ($quantity >= 1 && $quantity <= 0x7b) {
            return Device::Modbus::Exception->new(
                function_code  => $code,
                exception_code => 3,
                request        => $args{message}
            );
        }
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

1;
