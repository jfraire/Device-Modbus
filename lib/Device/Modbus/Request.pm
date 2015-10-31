package Device::Modbus::Request;

use parent 'Device::Modbus';
use Device::Modbus::Exception;
use Carp;
use strict;
use warnings;
use v5.10;

my %parameters_for = (
    'Read Coils'
        => [qw(code address quantity)],
    'Read Discrete Inputs'
        => [qw(code address quantity)],
    'Read Holding Registers'
        => [qw(code address quantity)],
    'Read Input Registers'
        => [qw(code address quantity)],
    'Write Single Coil'
        => [qw(code address value)],
    'Write Single Register'
        => [qw(code address value)],
    'Write Multiple Coils'
        => [qw(code address quantity bytes values)],
    'Write Multiple Registers'
        => [qw(code address quantity bytes values)],
    'Read/Write Multiple Registers'
        => [qw(code read_address read_quantity
            write_address write_quantity bytes values)],
);


my %format_for = (
    0x01 => 'Cnn',
    0x02 => 'Cnn',
    0x03 => 'Cnn',
    0x04 => 'Cnn',
    0x05 => 'Cnn',
    0x06 => 'Cnn',
    0x0F => 'CnnCC*',
    0x10 => 'CnnCn*',
    0x17 => 'CnnnnCn*',
);

sub new {
    my ($class, %args) = @_;
    croak 'A function name or code is required when creating a request'
        unless $args{function} || $args{code};

    if ($args{function}) {
        croak "Function $args{function} is not supported"
            unless exists $Device::Modbus::code_for{$args{function}};
        $args{code} = $Device::Modbus::code_for{$args{function}};
    }
    else {
        croak "Function code $args{code} is not supported"
            unless exists $Device::Modbus::function_for{$args{code}};
        $args{function} = $Device::Modbus::function_for{$args{code}};
    }        

    # Validate we have all the needed parameters
    foreach (@{$parameters_for{$args{function}}}) {
        # These are calculated
        next if $_ ~~ ['bytes', 'write_quantity'];
        next if $_ eq 'quantity' && $args{code} ~~ [0x0F, 0x10];

        # But the rest are required
        croak "Function $args{function} requires '$_'"
            unless exists $args{$_};
    }

    # Validate parameters
    foreach ($args{code}) {
        when ([0x01, 0x02]) {
            unless (defined $args{quantity} && $args{quantity} >= 1 && $args{quantity} <= 0x7D0) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        when ([0x03, 0x04]) {
            unless (defined $args{quantity} && $args{quantity} >= 1 && $args{quantity} <= 0x7D) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        when (0x05) {
            $args{value} = 1 if $args{value};
            unless (defined $args{value} && $args{value} >= 0 && $args{value} <= 0xFFFF) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        when (0x06) {
            unless (defined $args{value} && $args{value} >= 0 && $args{value} <= 0xFFFF) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        when (0x0F) {
            unless (defined $args{values} && @{$args{values}} >= 1 && @{$args{values}} <= 0x7B0) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        when (0x10) {
            unless (defined $args{values} && @{$args{values}} >= 1 && @{$args{values}} <= 0x7B) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        when (0x17) {
            unless (
                   defined $args{read_quantity}
                && defined $args{values}
                && $args{read_quantity}  >= 1
                && $args{read_quantity}  <= 0x7D
                && @{$args{values}} >= 1
                && @{$args{values}} <= 0x79) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
    }

    return bless \%args, $class;
}

sub pdu {
    my $self = shift;

    foreach ($self->{code}) {
        when ([0x01, 0x02, 0x03, 0x04]) {
            return  pack $format_for{$_},
                $self->{code}, $self->{address}, $self->{quantity};
        }
        when ([0x05, 0x06]) {
            my $value = $self->{value};
            $value = 0xFF00 if $_ == 0x05 && $self->{value};
            return pack $format_for{$_},
                $self->{code}, $self->{address}, $value;
        }
        when (0x0F) {
            my $values   = $self->flatten_bit_values($self->{values});
            my $quantity = scalar @{$self->{values}};
            my $pdu = pack $format_for{$_},
                $self->{code}, $self->{address},
                $quantity, scalar @$values;
            return $pdu . join '', @$values;
        }
        when (0x10) {
            my $quantity = scalar @{$self->{values}};
            my $bytes    = 2*$quantity;
            return pack $format_for{$_},
                $self->{code}, $self->{address}, $quantity, $bytes,
                @{$self->{values}};
        }
        when (0x17) {
            my $quantity = scalar @{$self->{values}};
            my $bytes    = 2*$quantity;
            return pack $format_for{$_},
                $self->{code},
                $self->{read_address},
                $self->{read_quantity},
                $self->{write_address},
                $quantity,
                $bytes,
                @{$self->{values}};
        }
    }
}

1;

__END__

=head1 NAME

Device::Modbus::Request - Modbus requests for Device::Modbus

=head1 DESCRIPTION

This class builds Modbus request objects. These objects can then be sent by a Device::Modbus client or received by a server. See the main documentation at L<Device::Modbus>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

