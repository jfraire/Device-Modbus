package Device::Modbus::Response;

use Moo;

extends 'Device::Modbus';

has function => (is => 'ro', required => 1);
has pdu      => (is => 'rw', lazy => 1, builder  => 1);

require Device::Modbus::Exception;
require Device::Modbus::Response::ReadDiscrete;
require Device::Modbus::Response::ReadRegisters;
require Device::Modbus::Response::WriteSingle;
require Device::Modbus::Response::WriteMultiple;
require Device::Modbus::Response::ReadWrite;

### Response builders

sub coils_read {
    my $class = shift;
    my $req = Device::Modbus::Response::ReadDiscrete->new(
        function => 'Read Coils',
        @_
    );
    return $req;
}

sub discrete_inputs_read {
    my $class = shift;
    my $req = Device::Modbus::Response::ReadDiscrete->new(
        function => 'Read Discrete Inputs',
        @_
    );
    return $req;
}

sub holding_registers_read {
    my $class = shift;
    my $req = Device::Modbus::Response::ReadRegisters->new(
        function => 'Read Holding Registers',
        @_
    );
    return $req;
}

sub input_registers_read {
    my $class = shift;
    my $req = Device::Modbus::Response::ReadRegisters->new(
        function => 'Read Input Registers',
        @_
    );
    return $req;
}

sub single_coil_write {
    my $class = shift;
    my $req = Device::Modbus::Response::WriteSingle->new(
        function => 'Write Single Coil',
        @_
    );
    return $req;
}

sub single_register_write {
    my $class = shift;
    my $req = Device::Modbus::Response::WriteSingle->new(
        function => 'Write Single Register',
        @_
    );
    return $req;
}

sub multiple_coils_write {
    my $class = shift;
    my $req = Device::Modbus::Response::WriteMultiple->new(
        function => 'Write Multiple Coils',
        @_
    );
    return $req;
}

sub multiple_registers_write {
    my $class = shift;
    my $req = Device::Modbus::Response::WriteMultiple->new(
        function => 'Write Multiple Registers',
        @_
    );
    return $req;
}

sub read_write_registers {
    my $class = shift;
    my $req = Device::Modbus::Response::ReadWrite->new(
        function => 'Read/Write Multiple Registers',
        @_
    );
    return $req;
}

### Response parsing

sub parse_response {
    my ($class, $binary_req) = @_;

    my $response;
    my $function_code = unpack 'C', $binary_req;
    my $function      = Device::Modbus::function_for($function_code);

    if ($function_code == 0x01 || $function_code == 0x02) {
        $response = Device::Modbus::Response::ReadDiscrete->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x03 || $function_code == 0x04) {
        $response = Device::Modbus::Response::ReadRegisters->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x05 || $function_code == 0x06) {
        $response = Device::Modbus::Response::WriteSingle->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x0f || $function_code == 0x10) {
        $response = Device::Modbus::Response::WriteMultiple->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x17) {
        $response = Device::Modbus::Response::ReadWrite->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    else {
        return Device::Modbus::Exception->new(
            function_code  => $function_code,
            exception_code => 1,
            request        => $binary_req
        );
    }

    return $response;
}

1; 

