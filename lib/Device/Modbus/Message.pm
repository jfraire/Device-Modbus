package Device::Modbus::Message;

use Moo;

has function      => (is => 'ro', required => 1);
has pdu           => (is => 'rw', lazy => 1, builder => 1);
has unit          => (is => 'rw', default => sub {0xff});

#### Functions and function codes

my %code_for = (

    # Bit access functions    fcn
    'Read Discrete Inputs' => 0x02,
    'Read Coils'           => 0x01,
    'Write Single Coil'    => 0x05,
    'Write Multiple Coils' => 0x0F,

    # 16-bits access functions         fcn
    'Read Input Registers'          => 0x04,
    'Read Holding Registers'        => 0x03,
    'Write Single Register'         => 0x06,
    'Write Multiple Registers'      => 0x10,
    'Read/Write Multiple Registers' => 0x17,
);

my %function_for = reverse %code_for;

sub function_code {
    my $self = shift;
    my $fcn  = $self->function;
    return $code_for{$fcn} if exists $code_for{$fcn};
    return undef;
}

sub function_for {
    my ($class, $code) = @_;
    return $function_for{$code} if exists $function_for{$code};
    return undef;
}

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
    my $quantity = scalar @values;

    # Turn the values array into an array of binary numbers
    my @values_binary;
    while (@values) {
        push @values_binary, pack 'b*', join '', splice @values, 0, 8;
    }
    return $quantity, \@values_binary;
}

# Receives a quantity of bits and an array of 8-bit numbers.
# The numbers are exploded into an array of bit values.
# The numbers start with the lower address in the LSB,
# and the first number contains the lower address.
# Returns an array of ones and zeros.
sub explode_bit_values {
    my ($self, $quantity, @values) = @_;
    @values = map { sprintf "%08B", $_ } @values;
    @values = map { reverse split // } @values;
    @values = splice @values, 0, $quantity;
    return @values;
}

1;
