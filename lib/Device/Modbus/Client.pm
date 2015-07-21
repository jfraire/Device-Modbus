package Device::Modbus::Client;

use Device::Modbus;
use Device::Modbus::Request;
use Device::Modbus::Response;
use Device::Modbus::Exception;

use Carp;
use strict;
use warnings;
use v5.10;

### Request building

sub read_coils {
    my ($self, %args) = @_;
    $args{function}   = 'Read Coils';
    return Device::Modbus::Request->new(%args);    
}

sub read_discrete_inputs {
    my ($self, %args) = @_;
    $args{function}   = 'Read Discrete Inputs';
    return Device::Modbus::Request->new(%args);    
}

sub read_input_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Read Input Registers';
    return Device::Modbus::Request->new(%args);
}

sub read_holding_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Read Holding Registers';
    return Device::Modbus::Request->new(%args);    
}

sub write_single_coil {
    my ($self, %args) = @_;
    $args{function}   = 'Write Single Coil';
    return Device::Modbus::Request->new(%args);    
}

sub write_single_register {
    my ($self, %args) = @_;
    $args{function}   = 'Write Single Register';
    return Device::Modbus::Request->new(%args);    
}

sub write_multiple_coils {
    my ($self, %args) = @_;
    $args{function}   = 'Write Multiple Coils';
    return Device::Modbus::Request->new(%args);    
}

sub write_multiple_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Write Multiple Registers';
    return Device::Modbus::Request->new(%args);    
}

sub read_write_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Read/Write Multiple Registers';
    return Device::Modbus::Request->new(%args);    
}

### Send request
sub send_request {
    my ($self, $request) = @_;
    my $adu = $self->build_adu($request);
    $self->write_port($adu);
}

### Response parsing    

# Parse the Application Data Unit
sub receive_response {
    my $self = shift;
    my $adu  = $self->new_adu();    
    $self->parse_header($adu);
    $self->parse_pdu($adu);
    $self->parse_footer($adu);
    return $adu;
}

sub parse_pdu {
    my ($self, $adu) = @_;
    my $response;
    
    my $code = $self->read_port(1,'C');

    foreach ($code) {
        when ([0x01, 0x02,]) {
            # Read coils and discrete inputs
            my ($byte_count) = $self->read_port(1, 'C');
            croak "Invalid byte count: <$byte_count>"
                unless $byte_count > 0;

            my @values       = $self->read_port($byte_count, 'C*');
            @values          = Device::Modbus->explode_bit_values(@values);

            $response = Device::Modbus::Response->new(
                code       => $code,
                bytes      => $byte_count,
                values     => \@values
            );
        }
        when ([0x03, 0x04, 0x17]) {
            # Read holding and input registers; read/write registers
            my ($byte_count) = $self->read_port(1, 'C');

            croak "Invalid byte count: <$byte_count>"
                unless $byte_count > 0 && $byte_count <= 250 && $byte_count % 2 == 0;

            my @values       = $self->read_port($byte_count, 'n*');

            $response = Device::Modbus::Response->new(
                code       => $code,
                bytes      => $byte_count,
                values     => \@values
            );
        }
        when ([0x05, 0x06]) {
            # Write single coil and single register
            my ($address, $value) = $self->read_port(4, 'n*');

            if ($code == 0x05) {
                $value = 1 if $value;
            }

            $response = Device::Modbus::Response->new(
                code       => $code,
                address    => $address,
                value      => $value
            );
        }
        when ([0x0F, 0x10]) {
            # Write multiple coils, multiple registers
            my ($address, $qty)   = $self->read_port(4, 'n*');

            $response = Device::Modbus::Response->new(
                code       => $code,
                address    => $address,
                quantity   => $qty
            );
        }
        when ([0x81,0x82,0x83,0x84,0x85,0x86,0x8F,0x90,0x97]) {
            my ($exc_code) = $self->read_port(1, 'C');
            
            $response = Device::Modbus::Exception->new(
                code           => $code,
                exception_code => $exc_code
            );
        }
        default {
            croak "Unimplemented function: <$_>";
        }
    }

    $adu->message($response);
    return $response;        
}

1;
