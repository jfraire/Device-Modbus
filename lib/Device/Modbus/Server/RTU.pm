package Device::Modbus::Server::RTU;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use Moo;

has spy_mode  => (is => 'ro', predicate => 1);
has unit      => (is => 'ro', predicate => 1);

extends 'Device::Modbus::Server';
with    'Device::Modbus::RTU';

sub BUILD {
    my $self = shift;
    croak "The server must be a spy or it must have a unit number"
        unless $self->has_spy_mode || $self->has_unit;
}

sub start {
    my $self = shift;

    while (1) {
        my $message = $self->read_port;
        next unless $message;
                
        my ($unit, $pdu, $footer) = $self->break_message($message);
        
        if ($self->spy_mode) {
            print '--> '.join '-', map { unpack 'C*' } $unit, split(//, $pdu);
            next unless $self->has_unit;
        }

        # Listen only for the given Modbus address
        next if ($self->unit != $unit);

        # Go through the generic server routine
        my $func = ord(substr $pdu,0,1);
        my $resp = $self->modbus_server($unit, $pdu);

        if (!defined $resp)  {
            $resp = Device::Modbus::Exception->new(
                unit           => $unit,
                function       => Device::Modbus::Exception->function_for($func),
                exception_code => 0x04
            );
        }
            
        $self->write(
            $self->build_apu($unit, $resp->pdu)
        ) || warn "Failed sending response!";
    }
}

1;
