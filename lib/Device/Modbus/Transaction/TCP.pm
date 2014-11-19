package Device::Modbus::Transaction::TCP;

use Moo;

has unit => (is => 'ro', default => 0xff);

extends 'Device::Modbus::Transaction';

# Build the MBAP header
sub header {
    my ($self, $pdu) = @_;
    my $header = pack 'nnnC',
        $self->id,             # Transaction id
        0x0000,                # Protocol number (Modbus)
        length($pdu)+1,        # Length of PDU + 1 byte for unit
        $self->unit;           # Unit number (used for serial sub-networks)
    return $header;
}

# No header for TCP
sub footer {
    return '';
}

1;
