package Device::Modbus::Server::RTU;

use Device::Modbus;
use Device::Modbus::RTU;
use Device::Modbus::Transaction;
use Device::Modbus::Exception;
use Device::SerialPort;
use Moo;

has spy_mode  => (is => 'ro', default => sub { 0 });
has serial    => (is => 'lazy', handles => [qw(read write close)]);
has port      => (is => 'ro', required => 1);
has baudrate  => (is => 'ro', default => sub { 9600 });
has databits  => (is => 'ro', default => sub { 8 });
has parity    => (is => 'ro', default => sub { 'even' });
has stopbits  => (is => 'ro', default => sub { 1 });
has unit      => (is => 'ro', default => sub { 1 });
has char_time => (is => 'lazy');

extends 'Device::Modbus::Server';

sub _build_char_time {
    my $self = shift;
    return sprintf '%d',
        1000 * (8 + $self->stopbits + $parity_bit) / $self->baudrate;
}

sub _build_serial {
    my $self = shift;

    my $parity_bit = $self->parity eq 'none' ? 0 : 1;
    my $char_time  = 

    my $serial = Device::SerialPort->new( $self->port );
    $serial->baudrate ( $self->baudrate   );
    $serial->parity   ( $self->parity     );
    $serial->stopbits ( $self->stopbits   );
    $serial->databits ( $self->databits   );
    $serial->handshake('none'             );

    $serial->read_char_time($self->char_time);
    $serial->read_const_time(3.5*$self->char_time);

    $serial->write_settings || croak "Unable to open port: $!";

    $serial->purge_all;

    %SIG{INT} = sub { $serial->close };

    return $serial;
}

sub start {
    my $server = shift;

    while (1) {
        my $timeout = 1000 * $self->timeout;
        my $message;
        while ($timeout) {
            my $ret = $self->read($message, 256);
            return undef if !defined $ret;
            last if $message;

            $timeout -= $self->char_time * ($ret + 3.5);
        }
        next unless $message;
        
        my ($unit, $pdu, $footer) =
            Device::Modbus::RTU->break_message($message);
        
        if ($server->spy_mode) {
            print '--> ' . join '-', map { unpack 'C*' } $unit, split(//, $pdu);
            next;
        }

        # Listen only in the given Modbus address
        next if ($server->unit != $unit);

        # Go through the generic server routine
        my $response = $server->modbus_server($unit, $pdu);

        my $message_out;
        if (ref $resp) {
            $message_out = $response->pdu;
        }
        else {
            my $exception = Device::Modbus::Exception->new(
                function       => $trn->request->function,
                exception_code => 0x04
            );
            $message_out = $exception->pdu;
        }
            
        $server->write(
            Device::Modbus::RTU->build_apu($unit, $message_out)
        ) || warn "Failed sending response!" unless $rc;
    }
}

1;
