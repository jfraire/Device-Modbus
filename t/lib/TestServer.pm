package TestServer;

use Device::Modbus::ADU;
use strict;
use warnings;

use parent 'Device::Modbus::Server';

sub new {
    my $class    = shift;
    my @messages = @_;
    my %args     = (
        index    => 0,
        messages => \@messages,
        units    => {},
    );
    return $class->proto(%args);
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

sub new_adu { return Device::Modbus::ADU->new(); }
sub parse_header { }
sub parse_footer { }

1;
