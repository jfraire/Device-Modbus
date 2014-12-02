package Device::Modbus::RTU;

use Device::SerialPort;
use Carp;
use Moo::Role;

has serial    => (is => 'lazy', handles  => [qw(read write close)]);
has port      => (is => 'ro',   required => 1);
has baudrate  => (is => 'ro',   default  => sub {9600});
has databits  => (is => 'ro',   default  => sub {8});
has parity    => (is => 'ro',   default  => sub {'even'});
has stopbits  => (is => 'ro',   default  => sub {1});
has timeout   => (is => 'rw',   default  => sub {2});
has char_time => (is => 'lazy');

sub _build_char_time {
    my $self = shift;
    my $parity_bit = $self->parity eq 'none' ? 0 : 1;
    return ($self->databits + $self->stopbits + $parity_bit) * 1000
      / $self->baudrate;
}

sub _build_serial {
    my $self = shift;

    my $parity_bit = $self->parity eq 'none' ? 0 : 1;
    my $char_time = sprintf '%d',
      1000 * (8 + $self->stopbits + $parity_bit) / $self->baudrate;

    my $serial = Device::SerialPort->new($self->port);
    croak "Unable to open serial port " . $self->port unless $serial;

    $serial->baudrate($self->baudrate);
    $serial->databits($serial->databits);
    $serial->parity($self->parity);
    $serial->stopbits($serial->stopbits);
    $serial->handshake('none');

    $serial->read_char_time($self->char_time);
    $serial->read_const_time(3.5 * $self->char_time);

    $serial->write_settings || croak "Unable to open port: $!";

    $serial->purge_all;

    $SIG{INT} = sub { $serial->close; die "Good bye\n"; };

    return $serial;
}

sub read_port {
    my $self = shift;

    my $timeout = 1000 * $self->timeout;
    my $message = '';
    while ($timeout > 0) {
        my ($bytes, $read) = $self->read(256);
        $message .= $read;
        $timeout -= $self->char_time * (256 + 3.5);
        last if $message;
    }

    return undef unless $message;

    return $message;
}

#### APU building

sub header {
    my ($self, $unit) = @_;
    my $header = pack 'C', $unit;
    return $header;
}

# Taken from MBClient (and verified against Modbus docs)
sub crc_for {
    my ($self, $str) = @_;
    my $crc = 0xFFFF;
    my ($chr, $lsb);
    for my $i (0..length($str)-1) {
        $chr  = ord(substr($str, $i, 1));
        $crc ^= $chr;
        for (1..8) {
            $lsb = $crc & 1;
            $crc >>= 1;
            $crc ^= 0xA001	if $lsb;
        }
	}
    return pack 'v', $crc;
}

sub footer {
    my ($self, $header, $pdu) = @_;
    return $self->crc_for($header . $pdu);
}

#### Build messages

sub build_apu {
    my ($self, $unit, $pdu) = @_;
    my $header = $self->header($unit);
    my $footer = $self->footer($header, $pdu);
    my $apu    = $header . $pdu . $footer;
    return $apu;
}

#### Message parsing

sub break_message {
    my ($self, $message) = @_;

    my $unit   = unpack 'C', substr($message, 0, 1);
    my $pdu    = substr($message, 1, -2);
    my $footer = substr($message, -2);

    my $verify = $self->crc_for($unit, $pdu);
#    print STDERR "Expected $verify but got $footer\n"
#        unless $verify eq $footer;

    return ($unit, $pdu, $footer);
}

1;
