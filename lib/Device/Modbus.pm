package Device::Modbus;

use strict;
use warnings;

our $VERSION = '0.01';

my %code_for = (
    # Bit access functions             fcn
    'Read Discrete Inputs'          => 0x02, 
    'Read Coils'                    => 0x01, 
    'Write Single Coil'             => 0x05, 
    'Write Multiple Coils'          => 0x0F, 

    # 16-bits access functions         fcn 
    'Read Input Registers'          => 0x04, 
    'Read Holding Registers'        => 0x03, 
    'Write Single Register'         => 0x06, 
    'Write Multiple Registers'      => 0x10, 
    'Read/Write Multiple Registers' => 0x17, 
);

my %function_for = reverse %code_for;

sub code_for {
    my $fcn = shift;
    return $code_for{$fcn} if exists $code_for{$fcn};
    return undef;
}

sub function_for {
    my $code = shift;
    return $function_for{$code} if exists $function_for{$code};
    return undef;
}

sub function_code {
    my $self = shift;
    return $code_for{ $self->function };
}

# Receives an array reference of bit values and builds an array
# of 8-bit numbers. Each number starts with the lower address
# in the LSB.
# Returns the quantity of bits packed and a reference to the array
# of 8-bit numbers
sub flatten_bit_values {
    my $values = shift;
    
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
    my ($quantity, @values) = @_;
    @values = map { sprintf "%08B", $_ } @values;
    @values = map { reverse split //   } @values;
    @values = splice @values, 0, $quantity;
    return @values;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::Modbus - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Device::Modbus;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Device::Modbus, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Julio Fraire, E<lt>julio@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
