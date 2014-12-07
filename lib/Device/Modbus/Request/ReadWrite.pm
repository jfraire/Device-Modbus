package Device::Modbus::Request::ReadWrite;

use overload '""' => \&stringify;
use Moo;

extends 'Device::Modbus::Message';

has read_address  => (is => 'ro', required => 1);
has read_quantity => (is => 'ro', required => 1);
has write_address => (is => 'ro', required => 1);
has write_quantity => (is => 'lazy');
has write_bytes    => (is => 'lazy');
has values         => (is => 'ro', required => 1);

sub _build_write_quantity {
    my $self = shift;
    return scalar @{$self->values};
}

sub _build_write_bytes {
    my $self = shift;
    return length pack 'n*', @{$self->values};
}

sub _build_pdu {
    my $self = shift;
    my @pdu  = (
        $self->function_code,  $self->read_address - 1,
        $self->read_quantity,  $self->write_address - 1,
        $self->write_quantity, $self->write_bytes,
        @{$self->values}
    );

    # Build the pdu
    return pack 'CnnnnCn*', @pdu;
}

sub parse_message {
    my ($class, %args) = @_;

    my ($code, $raddr, $rqty, $waddr, $wqty, $wbytes, @values) =
      unpack 'CnnnnCn*', $args{message};

    $raddr++;
    $waddr++;

    return $class->new(
        function       => $args{function},
        read_address   => $raddr,
        read_quantity  => $rqty,
        write_address  => $waddr,
        write_quantity => $wqty,
        write_bytes    => $wbytes,
        values         => \@values,
        pdu            => $args{message}
    );
}

sub stringify {
    my $self = shift;
    return 'Request: Function: [' . $self->function .'] '
        . 'Read address: [' . sprintf ('%#.2x', $self->read_address). '] '
        . 'Read quantity: ['. $self->read_quantity . '] '
        . 'Write address: [' . sprintf ('%#.2x', $self->write_address). '] '
        . 'Write bytes: [' . $self->write_bytes. '] '
        . 'Write values: ['. join('-', @{$self->values}) . '] ';
}

1;

