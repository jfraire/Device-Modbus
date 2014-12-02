package Device::Modbus::Server::RTU;

use Device::Modbus;
use Device::Modbus::Exception;
use Moo;

has spy_mode  => (is => 'ro', default  => sub { 0 });
has unit      => (is => 'ro', required => 1);

extends 'Device::Modbus::Server';
with    'Device::Modbus::RTU';

sub start {
    my $self = shift;

    while (1) {
        my $message = $self->read_port;
        next unless $message;
                
        my ($unit, $pdu, $footer) = $self->break_message($message);
        
        if ($self->spy_mode) {
            print '--> '.join '-', map { unpack 'C*' } $unit, split(//, $pdu);
            next;
        }

        # Listen only for the given Modbus address
        next if ($self->unit != $unit);

        # Go through the generic server routine
        my ($req, $resp) = $self->modbus_server($unit, $pdu);

        if (ref $req eq 'Device::Modbus::Exception') {
            $resp = $req;
        }
        elsif (!defined $resp)  {
            $resp = Device::Modbus::Exception->new(
                function       => $req->function,
                exception_code => 0x04,
                unit           => $unit
            );
        }
            
        $self->write(
            $self->build_apu($unit, $resp->pdu)
        ) || warn "Failed sending response!";
    }
}

1;
