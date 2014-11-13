package Device::Modbus::Request;

use strict;
use warnings;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

use constant FUNCTION   => 0;
use constant TYPE       => 1;

my %params_for = (
    # Bit access functions               fcn   type
    'Read Discrete Inputs'          => [ 0x02, 'qty'     ],
    'Read Coils'                    => [ 0x01, 'qty'     ],
    'Write Single Coil'             => [ 0x05, 'value'   ],
    'Write Multiple Coils'          => [ 0x0F, 'values'  ],

    # 16-bits access functions           fcn   type
    'Read Input Registers'          => [ 0x04, 'qty'     ],
    'Read Holding Registers'        => [ 0x03, 'qty'     ],
    'Write Single Register'         => [ 0x06, 'value'   ],
    'Write Multiple Registers'      => [ 0x10, 'values'  ],
    'Read/Write Multiple Registers' => [ 0x17, 'special' ],
);



sub new {
    my ($class, %args) = @_;
    my $req = bless \%args, $class;
    if (!exists $req->{function}) {
        croak 'A Modbus request requires a function to execute';
    }
    if (!exists $params_for{$req->{function}}) {
        croak 'Unrecognized or unimplemented Modbus function: '
            . $req->{function};
    }
    if (!exists $req->{address}
        && $req->{function} ne 'Read/Write Multiple Registers') {
        croak 'Modbus function ' . $req->{function}
            . ' requires a starting address';
    }
    $req->build_pdu;
    return $req;
}
    

# Returns function name
sub function {
    my $self = shift;
    return $self->{function};
}

# Returns code for function
sub function_code {
    my $self = shift;
    return $params_for{$self->function}->[FUNCTION()];
}

# Returns existing pdu; builds pdu if necessary
sub pdu {
    my $self = shift;
    return $self->{pdu};
}

# Builds the pdu
sub build_pdu {
    my $self = shift;

    my $type = $params_for{$self->function}->[TYPE()];

    # pdu for functions 0x01-0x04
    if ($type eq 'qty') {
        $self->_build_pdu_for_type_qty;
    }
    # pdu for functions 0x05 and 0x06
    elsif ($type eq 'value') {
        $self->_build_pdu_for_type_value;
    }
    # pdu for functions 0x0F and 0x10
    elsif ($self->function eq 'Write Multiple Coils') {
        $self->_build_pdu_to_write_multiple_coils;
    }
    elsif ($self->function eq 'Write Multiple Registers') {
        $self->_build_pdu_to_write_multiple_registers;
    }
    elsif ($self->function eq 'Read/Write Multiple Registers') {
        $self->_build_pdu_to_read_write_registers;
    }
}


# Check that the argument 'values' exists and that it is an arrayref
sub _verify_args_for_type_values {
    my $self = shift;
    if (!exists $self->{values} || ref($self->{values}) ne 'ARRAY') {
        croak 'A Modbus request for function "' . $self->function
            . '" requires an array reference of values to write into '
            . 'the bit or register';
    }
}


# Build pdu for functions 0x01-0x04
sub _build_pdu_for_type_qty {
    my $self = shift;
    if (!exists $self->{quantity}) {
        croak 'A Modbus request for function "' . $self->function
            . '" requires a quantity of bits or registers';
    }

    my @pdu =
        ($self->function_code, $self->{address}-1, $self->{quantity});
    $self->{pdu} = pack 'Cnn', @pdu;
}

# Build pdu for functions 0x05 and 0x06
sub _build_pdu_for_type_value {
    my $self = shift;
    if (!exists $self->{value}) {
        croak 'A Modbus request for function "' . $self->function
            . '" requires a value to write into the bit or register';
    }

    my $value = $self->{value};
    if ($self->function eq 'Write Single Coil') {
        $value = $self->{value} ? 0xFF00 : 0;
    }

    my @pdu = ($self->function_code, $self->{address}-1, $value);
    $self->{pdu} = pack 'Cnn', @pdu;
}

# Build pdu for function 0x0F
sub _build_pdu_to_write_multiple_coils {
    my $self = shift;
    $self->_verify_args_for_type_values;

    # Values must be either 1 or 0
    my @values = map { $_ ? 1 : 0 } @{$self->{values}};
    $self->{quantity} = scalar @values;

    # Turn the values array into an array of binary numbers
    my @values_binary;
    while (@values) {
        push @values_binary, pack 'b*', join '', splice @values, 0, 8;
    }

    # Build a 16-bits number with the binary values
    my $string = unpack 'n*', join '', @values_binary;

    # Build the pdu
    my @pdu = ($self->function_code, $self->{address}-1,
        $self->{quantity}, scalar(@values_binary), $string);
    $self->{pdu} = pack 'CnnCn*', @pdu;
}

# Build pdu for function 0x10
sub _build_pdu_to_write_multiple_registers {
    my $self = shift;
    $self->_verify_args_for_type_values;
    
    # Values is an array reference of 2-byte register values
    $self->{quantity} = scalar @{$self->{values}};
    $self->{quantity} = int($self->{quantity})+1
        if $self->{quantity} > int($self->{quantity});

    # Build the pdu
    my @pdu = ($self->function_code, $self->{address}-1,
        $self->{quantity}, 2*$self->{quantity}, @{$self->{values}});
    $self->{pdu} = pack 'CnnCn*', @pdu;
}

sub _build_pdu_to_read_write_registers {
    my $self = shift;

    foreach my $required (qw|read_address
        read_quantity write_address write_values|) {
        croak "Parameter $required is required for a Read/Write"
            . " Multiple Registers Request"
            unless exists $self->{$required};
    }

    my @pdu = (
        $self->function_code,
        $self->{read_address} - 1,
        $self->{read_quantity},
        $self->{write_address} - 1,
        scalar(@{$self->{write_values}}),
        scalar(@{$self->{write_values}}) * 2,
        @{$self->{write_values}}
    );

    # Build the pdu
    $self->{pdu} = pack 'CnnnnCn*', @pdu;
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
