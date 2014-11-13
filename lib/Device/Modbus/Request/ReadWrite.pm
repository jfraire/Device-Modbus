package Device::Modbus::Request::ReadWrite;

use Moo;
use Carp;

extends 'Device::Modbus::Request';

has read_address   => (is => 'ro', required => 1);
has read_quantity  => (is => 'ro', required => 1);
has write_address  => (is => 'ro', required => 1);
has write_quantity => (is => 'lazy');
has write_bytes    => (is => 'lazy');
has values         => (is => 'ro', required => 1);

sub _build_write_quantity {
    my $self = shift;
    return scalar @{$self->values};
}

sub _build_write_bytes {
    my $self = shift;
    return 2*$self->write_quantity;
}

sub _build_pdu {
    my $self = shift;
    my @pdu = (
        $self->function_code,
        $self->read_address - 1,
        $self->read_quantity,
        $self->write_address - 1,
        $self->write_quantity,
        $self->write_bytes,
        @{$self->values}
    );

    # Build the pdu
    return pack 'CnnnnCn*', @pdu;
}

sub parse_message {
    my ($class, %args) = @_;

    my ($code, $raddr, $rqty, $waddr, $wqty, $wbytes, @values)
        = unpack 'CnnnnCn*', $args{message};

    $raddr++;
    $waddr++;
    
    unless (
           $rqty >= 1 && $rqty <= 0x007d
        && $wqty >= 1 && $wqty <= 0x0079
        && $wbytes == 2*$wqty )
    {
        return Device::Modbus::Exception->new(
            function_code  => $code,
            exception_code => 3
        );
    }

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

1;

