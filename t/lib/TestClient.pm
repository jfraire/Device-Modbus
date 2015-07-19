package TestClient;

use Carp;
use strict;
use warnings;

use parent 'Device::Modbus::Client';

sub new {
    my $class    = shift;
    my @messages = @_;
    my $self     = {
        index    => 0,
        messages => \@messages,
    };
    return bless $self, $class;
}

sub set_index {
    my ($self, $index) = @_;
    $self->{index} = $index;
}

sub read_port {
    my ($self, $chars, $tmpl) = @_;
    my $str = substr $self->{messages}[$self->{index}], 0, $chars, '';
    die "Timeout error" unless length($str) == $chars;
    return unpack $tmpl,$str;        
}

1;
