package Device::Modbus;

use Carp;
use strict;
use warnings;
use v5.10;

our %code_for = (
    'Read Coils'                    => 0x01,
    'Read Discrete Inputs'          => 0x02,
    'Read Holding Registers'        => 0x03,
    'Read Input Registers'          => 0x04,
    'Write Single Coil'             => 0x05,
    'Write Single Register'         => 0x06,
    'Write Multiple Coils'          => 0x0F,
    'Write Multiple Registers'      => 0x10,
    'Read/Write Multiple Registers' => 0x17,
);

our %function_for = reverse %code_for;

#### Helper methods

# Receives an array reference of bit values and builds an array
# of 8-bit numbers. Each number starts with the lower address
# in the LSB.
# Returns the quantity of bits packed and a reference to the array
# of 8-bit numbers
sub flatten_bit_values {
    my ($self, $values) = @_;

    # Values must be either 1 or 0
    my @values = map { $_ ? 1 : 0 } @{$values};

    # Turn the values array into an array of binary numbers
    my @values_binary;
    while (@values) {
        push @values_binary, pack 'b*', join '', splice @values, 0, 8;
    }
    return \@values_binary;
}

# Receives a quantity of bits and an array of 8-bit numbers.
# The numbers are exploded into an array of bit values.
# The numbers start with the lower address in the LSB,
# and the first number contains the lower address.
# Returns an array of ones and zeros.
sub explode_bit_values {
    my ($self, @values) = @_;
    @values = map { sprintf "%08B", $_ } @values;
    @values = map { reverse split // } @values;
    return @values;
}

1;
