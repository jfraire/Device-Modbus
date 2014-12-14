package Device::Modbus::Unit;

use Carp;
use Moo;

has id         => (is => 'ro', required  => 1);
has addresses  => (is => 'rw', default   => sub {+{}}); 

sub put {
    my ($self, $zone, $addr, $qty, $method) = @_;
    my $key = "$zone:Write:$addr:$qty";
    if (!ref $method) {
        $method = $self->can($method); # returns a ref to method
    }
    croak "'put' could not resolve a code reference for address $addr"
        unless ref $method && ref $method eq 'CODE';

    $self->addresses->{$key}{put} = $method;
}

sub get {
    my ($self, $zone, $addr, $qty, $method) = @_;
    my $key = "$zone:Read:$addr:$qty";
    if (!ref $method) {
        $method = $self->can($method); # returns a ref to method
    }
    croak "'get' could not resolve a code reference for address $addr"
        unless ref $method && ref $method eq 'CODE';

    $self->addresses->{$key}{get} = $method;
}

sub test {
    my ($self, $zone, $mode, $addr, $qty) = @_;

    my $key = "$zone:$mode:$addr:$qty";

    my $test = exists $self->addresses->{$key};
    return $test;
}

sub get_address {
    my ($self, $zone, $addr, $qty) = @_;
    my $key = "$zone:Read:$addr:$qty";
    return $self->addresses->{$key}{get};
}

sub put_address {
    my ($self, $zone, $addr, $qty) = @_;
    my $key = "$zone:Write:$addr:$qty";
    return $self->addresses->{$key}{put};
}

1;
