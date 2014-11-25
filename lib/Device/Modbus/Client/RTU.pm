package Device::Modbus::Client::RTU;

use Device::Modbus;
use Device::Modbus::RTU;
use Device::SerialPort;
use Carp;
use Moo;

has serial    => (is => 'rw');
has port      => (is => 'ro', required => 1);
has baudrate  => (is => 'ro', default => sub { 9600 });
has parity    => (is => 'ro', default => sub { 'even' });
has stopbits  => (is => 'ro', default => sub { 1 });
has blocking  => (is => 'ro', default => sub { 1 });

extends 'Device::Modbus::Client';

sub connect {
    my $self = shift;

    my $parity_bit = $self->parity eq 'none' ? 0 : 1;
    my $char_time  = sprintf '%d',
        1000 * (8 + $self->stopbits + $parity_bit) / $self->baudrate; 

    my $serial = Device::SerialPort->new( $self->port );
    $serial->baudrate ( $self->baudrate   );
    $serial->parity   ( $self->parity     );
    $serial->stopbits ( $serial->stopbits );
    $serial->databits ( 8                 );
    $serial->handshake('none'             );

    $serial->read_char_time($char_time);
    $serial->read_const_time(3.5*$char_time);

    $serial->write_settings || croak "Unable to open port: $!";

    $serial->purghe_all;

    $self->serial($serial);
}


#### Connection management

sub send_request {
    my ($self, $trn) = @_;
    my $pdu   = $trn->request_pdu;
    my $apu   = Device::Modbus::RTU->build_apu($trn, $pdu);
    my $bytes = $self->serial->write($apu)
        || return undef;
    return undef unless $bytes eq length($apu);
    $trn->set_expiration_time(time());
    $self->move_to_waiting_room($trn);
    return $bytes;
}

sub receive_response {
    my $self = shift;
    my $message;
    
    my $ret = $self->serial->read($message, 256);
    return undef if !defined $ret;
    return 0 unless length $message;
    
    my ($trn_id, $unit, $pdu) = Device::Modbus::RTU->break_message($message);
    return undef unless defined $trn_id;
    
    my $trn = $self->get_from_waiting_room($trn_id);
    my $resp = Device::Modbus->parse_response($pdu);
    $trn->response($resp);
    return $trn;
}

sub close {
    my $self = shift;
    my $ret = $self->serial->close;
    $self->serial(undef);
    return $ret;
}

1;
