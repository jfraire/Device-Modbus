package Device::Modbus::Unit::Address;

use Carp;
use Moo;

has route       => (is => 'ro',  required => 1);
has route_tests => (is => 'rwp');
has zone        => (is => 'ro',  required => 1);
has quantity    => (is => 'ro',  required => 1);
has qty_tests   => (is => 'rwp');
has read_write  => (is => 'ro',  required => 1);
has routine     => (is => 'rw',  required => 1);

sub BUILD {
    my $self = shift;
    my %valid_zone = (
        discrete_coils    => 'rw',
        discrete_inputs   => 'ro',
        input_registers   => 'ro',
        holding_registers => 'rw',
    );

    croak "Invalid Modbus model type: zone '" . $self->zone . "' does not exist"
        unless exists $valid_zone{$self->zone};
    croak "Modbus zone '" . $self->zone . "' is read-only"
        if ($self->zone eq 'discrete_inputs' || $self->zone eq 'input_registers')
        && $self->read_write eq 'write';
    croak "Address read_write must be either read or write"
        unless $self->read_write =~ /^read|write$/;
    croak "The routine for an address must be a code reference"
        unless ref $self->routine && ref $self->routine eq 'CODE';

    $self->_set_route_tests(_build_tests($self->route));
    $self->_set_qty_tests(_build_tests($self->quantity));

}


# Receives a route string and converts it into an array reference of
# anonymous subroutines. Each subroutine will test if a given value
# matches a part of the route.    
sub _build_tests {
    my $route = shift;

    # Star matches always
    return [ sub { 1 } ] if $route =~ /\*/;

    $route    =~ s/\s+//g;
    my @atoms = split /,/, $route;
    my @tests;
    foreach my $atom (@atoms) {
        # Range test
        if ($atom =~ /^(\d+)\-(\d+)$/) {
            my ($min, $max) = ($1, $2);
            push @tests, sub { my $val = shift; return $val >= $min && $val <= $max; };
        }
        # Equality test
        else {
            push @tests, sub { return shift == $atom; };
        }
    }

    return \@tests;
}

# Tests an address
sub test_route {
    my ($self, $value) = @_;
    foreach my $test (@{$self->route_tests}) {
        return 1 if $test->($value);
    }
    return 0;
}

# Tests a quantity
sub test_quantity {
    my ($self, $value) = @_;
    foreach my $test (@{$self->qty_tests}) {
        return 1 if $test->($value);
    }
    return 0;
}

1;
