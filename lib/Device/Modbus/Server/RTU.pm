package Device::Modbus::Server::RTU;

use Device::Modbus;
use Device::Modbus::Transaction;
use Device::Modbus::Exception;
use Moo;

has spy_mode  => (is => 'ro', default => sub { 0 });

extends 'Device::Modbus::Server';
with    'Device::Modbus::RTU';

sub start {
    my $server = shift;

    while (1) {
        my $message = $self->read_port;
        next unless $message;
                
        my ($unit, $pdu, $footer) = $self->break_message($message);
        
        if ($server->spy_mode) {
            print '--> '.join '-', map { unpack 'C*' } $unit, split(//, $pdu);
            next;
        }

        # Listen only for the given Modbus address
        next if ($server->unit != $unit);

        # Go through the generic server routine
        my ($req, $resp) = $server->modbus_server($unit, $pdu);

        my $message_out;
        if (ref $resp) {
            $message_out = $response->pdu;
        }
        else {
            my $exception = Device::Modbus::Exception->new(
                function       => $req->function,
                exception_code => 0x04
            );
            $message_out = $exception->pdu;
        }
            
        $server->write(
            Device::Modbus::RTU->build_apu($unit, $message_out)
        ) || warn "Failed sending response!";
    }
}

1;
