package Device::Modbus::Client::RTU;

use Device::Modbus;
use Moo;

with 'Device::Modbus::RTU';

#### Connection management

sub send_request {
    my ($self, $req) = @_;

    # Send request
    my $pdu   = $req->pdu;
    my $apu   = $self->build_adu($req);
    my $bytes = $self->write($apu)
      || return undef;
    return undef unless $bytes eq length($apu);

    # Get response
    my $message = $self->read_port;
    return unless $message;
    
    my ($unit, $rpdu, $footer) = $self->break_message($message);
    
    my $resp = Device::Modbus->parse_response($rpdu);
    $resp->unit($unit);
    
    return $resp;
}

=for comment

sub receive_response {
    my $self = shift;

    my $message = $self->read_port;
    return unless $message;
    
    my ($unit, $pdu, $footer) = $self->break_message($message);
    
    my $resp = Device::Modbus->parse_response($pdu);
    $resp->unit($unit);
    
    return $resp;
}

=cut

1;
