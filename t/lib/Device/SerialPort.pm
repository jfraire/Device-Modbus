package Device::SerialPort;

use Moo;

# This is a fake Device::SerialPort class for testing!
# Read and write are set as read/write attributes so that you can
# save their returned values to cheat your tests HE HE He he he...

has port               => (is => 'rw');
has baudrate           => (is => 'rw');
has databits           => (is => 'rw');
has stopbits           => (is => 'rw');
has parity             => (is => 'rw');
has handshake          => (is => 'rw');
has read_char_time     => (is => 'rw');
has read_const_time    => (is => 'rw');
has write_settings     => (is => 'rw', default => 1);
has purge_all          => (is => 'rw', default => 1);
has close              => (is => 'rw', default => 1);
has lines_to_read      => (is => 'rw', default => sub { sub {0, ''} } );
has when_writing_do    => (is => 'rw', default => sub {
    sub {
        my $msg = shift;
        print STDOUT '# Wrote ' . unpack 'H*', $msg;
        return length $msg;
    }
});

print STDERR "# Importing fake Device::SerialPort\n";

sub BUILDARGS {
    my $class = shift;
    my %obj = ();
    
    if (@_) {
        $obj{port} = shift;
    }

    return \%obj;
}

sub read {
    my $self = shift;
    return $self->lines_to_read->();
}

sub write {
    my $self = shift;
    return $self->when_writing_do->(@_);
}

1;
