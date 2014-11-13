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

    # Values must be either 1 or 0
    my @values = map { $_ ? 1 : 0 } @{$self->values};
    my $quantity = scalar @values;
    $self->quantity($quantity);

    # Turn the values array into an array of binary numbers
    my @values_binary;
    while (@values) {
        push @values_binary, pack 'b*', join '', splice @values, 0, 8;
    }

    # Build the pdu
    my @pdu = ($self->function_code, $self->address-1, $quantity,
        scalar(@values_binary));
    return pack('CnnC', @pdu) . join '', @values_binary;
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

        # values need to be turned into an array of 1s and 0s
        @values = map { sprintf "%08B", $_ } @values;
        @values = map { reverse split //   } @values;
        @values = splice @values, 0, $quantity;
    } else {
        ($code, $address, $quantity, $bytes, @values)
            = unpack 'CnnCn*', $args{message};
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
