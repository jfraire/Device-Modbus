package Device::Modbus::TCP;

use strict;
use warnings;

#### APU building

sub header {
    my ($class, $trn, $pdu) = @_;
    my $header = pack 'nnnC', $trn->id,    # Transaction id
      0x0000,                              # Protocol number (Modbus)
      length($pdu) + 1,                    # Length of PDU + 1 byte for unit
      $trn->unit;    # Unit number (used for serial sub-networks)
    return $header;
}

# No header for TCP
sub footer {
    return '';
}

#### Build messages

sub build_apu {
    my ($class, $trn, $pdu) = @_;
    my $header = $class->header($trn, $pdu);
    my $footer = $class->footer($trn, $pdu);
    my $apu = $header . $pdu . $footer;
    return $apu;
}

#### Message parsing

sub break_message {
    my ($class, $message) = @_;
    my ($id, $proto, $length, $unit) = unpack 'nnnC', $message;
    my $pdu = substr $message, 7;
    return if length($pdu) != $length - 1;
    return $id, $unit, $pdu;
}

1;
