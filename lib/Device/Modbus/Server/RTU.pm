package Device::Modbus::Server::RTU;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use Moo;

has unit => (is => 'ro', required => 1);

with 'Device::Modbus::Server', 'Device::Modbus::RTU';

sub start {
    my $self = shift;

    while (1) {
        my $message = $self->read_port;
        next unless $message;
                
        my ($unit, $pdu, $footer) = $self->break_message($message);
        
        # Listen only for the given Modbus address
        next if ($self->unit != $unit);

        # Go through the generic server routine
        my $req  = Device::Modbus->parse_request($pdu);
        my $resp = $self->modbus_server($unit, $req);

        $self->write(
            $self->build_apu($unit, $resp->pdu)
        ) || warn "Failed sending response!";
    }
}

1;
