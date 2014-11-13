package Device::Modbus::Exception;

use Moo;

has function_code  => (is => 'ro', required => 1);
has exception_code => (is => 'ro', required => 1);
has pdu            => (is => 'rw', lazy => 1, builder => 1);
has request        => (is => 'ro');

sub build_pdu {
    my $self = shift;
    return pack 'Cn', $self->function_code + 0x80, $self->exception_code;
}

1;
    
