package Device::Modbus::Client::RTU;

use Device::Modbus;
use Moo;

with 'Device::Modbus::RTU';

#### Connection management

sub send_request {
    my ($self, $req) = @_;
    my $pdu   = $req->pdu;
    my $apu   = $self->build_apu($req->unit, $pdu);
    my $bytes = $self->write($apu)
      || return undef;
    return undef unless $bytes eq length($apu);
    return $bytes;
}

sub receive_response {
    my $self = shift;

    my $message = $self->read_port;
    return unless $message;
    
    my ($unit, $pdu, $footer) = $self->break_message($message);
    
    my $resp = Device::Modbus->parse_response($pdu);
    $resp->unit($unit);
    
    return $resp;
}

1;
