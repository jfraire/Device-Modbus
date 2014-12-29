package Device::Modbus::TCP;

use Moo::Role;

#### APU building

sub header {
    my ($self, $trn, $req) = @_;
    my $header = pack 'nnnC', $trn->id,    # Transaction id
      0x0000,                              # Protocol number (Modbus)
      length($req->pdu) + 1,               # Length of PDU + 1 byte for unit
      $req->unit;                          # Unit number
    return $header;
}

# No header for TCP
sub footer {
    return '';
}

#### Build messages

sub build_adu {
    my ($self, $trn, $req) = @_;
    my $header = $self->header($trn, $req);
    my $footer = $self->footer($trn, $req);
    my $apu = $header . $req->pdu . $footer;
    return $apu;
}

#### Message parsing

sub break_message {
    my ($self, $message) = @_;
    my ($id, $proto, $length, $unit) = unpack 'nnnC', $message;
    return if length($message) <= 7;
    my $pdu = substr $message, 7;
    return if length($pdu) != $length - 1;
    return $id, $unit, $pdu;
}

1;
