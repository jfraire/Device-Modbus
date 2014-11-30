package Device::Modbus::Client::RTU;

use Device::Modbus;
use Device::Modbus::RTU;
use Device::SerialPort;
use Carp;
use Moo;

has serial    => (is => 'lazy', handles => [qw(read write close)]);
has port      => (is => 'ro', required => 1);
has baudrate  => (is => 'ro', default => sub { 9600 });
has databits  => (is => 'ro', default => sub { 8 });
has parity    => (is => 'ro', default => sub { 'even' });
has stopbits  => (is => 'ro', default => sub { 1 });
has unit      => (is => 'ro', default => sub { 1 });
has char_time => (is => 'lazy');

sub _build_char_time {
    my $self = shift;
    my $parity_bit = $self->parity eq 'none' ? 0 : 1;
    return sprintf '%d',
        ($self->databits + $self->stopbits + $parity_bit)
        * 1000 / $self->baudrate;
}


sub _build_serial {
    my $self = shift;

    my $parity_bit = $self->parity eq 'none' ? 0 : 1;
    my $char_time  = sprintf '%d',
        1000 * (8 + $self->stopbits + $parity_bit) / $self->baudrate; 

    my $serial = Device::SerialPort->new( $self->port );
    croak "Unable to open serial port " . $self->port unless $serial;
    
    $serial->baudrate ( $self->baudrate   );
    $serial->databits ( $serial->databits );
    $serial->parity   ( $self->parity     );
    $serial->stopbits ( $serial->stopbits );
    $serial->handshake('none'             );

    $serial->read_char_time($self->char_time);
    $serial->read_const_time(3.5*$self->char_time);

    $serial->write_settings || croak "Unable to open port: $!";

    $serial->purge_all;

    return $serial;
}


#### Connection management

sub send_request {
    my ($self, $req) = @_;
    my $pdu   = $req->pdu;
    my $apu   = Device::Modbus::RTU->build_apu($self->unit, $pdu);
    my $bytes = $self->write($apu)
        || return undef;
    return undef unless $bytes eq length($apu);
}

sub receive_response {
    my $self = shift;

    my $timeout = 1000 * $self->timeout;
    my $message;
    while ($timeout) {
        my $ret = $self->read($message, 256);
        return undef if !defined $ret;
        return 0 unless length $message;

        $timeout -= $self->char_time * ($ret + 3.5);
    }
    
    my ($unit, $pdu, $footer) =
        Device::Modbus::RTU->break_message($message);

    my $resp = Device::Modbus->parse_response($pdu);
    return $resp;
}

1;
