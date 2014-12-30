package Test::Server;
use Moo;
with 'Device::Modbus::Server';

has log_level => (is => 'rw', default => 2);

sub start {
    print STDERR "# Required by Device::Modbus::Server\n";
}

my %level_str = (
    0 => 'ERROR',
    1 => 'WARNING',
    2 => 'NOTICE',
    3 => 'INFO',
    4 => 'DEBUG',
);

sub log {
    my ($self, $level, $msg) = @_;
    return unless $level <= $self->log_level;
    my $time = localtime();
    my ($package, $filename, $line) = caller;

    my $message = ref $msg ? $msg->() : $msg;
    
    print STDOUT
        "$level_str{$level} : $time > $0 in $package "
        . "($filename line $line): $message\n";
    return 1;
}

1;
