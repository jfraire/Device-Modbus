package Device::Modbus::Request;

use Moo;

has function => (is => 'ro', required => 1);
has pdu      => (is => 'rw', lazy => 1, builder  => 1);

require Device::Modbus::Exception;
require Device::Modbus::Request::Read;
require Device::Modbus::Request::WriteSingle;
require Device::Modbus::Request::WriteMultiple;
require Device::Modbus::Request::ReadWrite;


my %code_for = (
    # Bit access functions             fcn
    'Read Discrete Inputs'          => 0x02, 
    'Read Coils'                    => 0x01, 
    'Write Single Coil'             => 0x05, 
    'Write Multiple Coils'          => 0x0F, 

    # 16-bits access functions         fcn 
    'Read Input Registers'          => 0x04, 
    'Read Holding Registers'        => 0x03, 
    'Write Single Register'         => 0x06, 
    'Write Multiple Registers'      => 0x10, 
    'Read/Write Multiple Registers' => 0x17, 
);

my %function_for = reverse %code_for;

sub function_code {
    my $self = shift;
    return $code_for{ $self->function };
}

### Request builders

sub read_coils {
    my $class = shift;
    my $req = Device::Modbus::Request::Read->new(
        function => 'Read Coils',
        @_
    );
    return $req;
}

sub read_discrete_inputs {
    my $class = shift;
    my $req = Device::Modbus::Request::Read->new(
        function => 'Read Discrete Inputs',
        @_
    );
    return $req;
}

sub read_input_registers {
    my $class = shift;
    my $req = Device::Modbus::Request::Read->new(
        function => 'Read Input Registers',
        @_
    );
    return $req;
}

sub read_holding_registers {
    my $class = shift;
    my $req = Device::Modbus::Request::Read->new(
        function => 'Read Holding Registers',
        @_
    );
    return $req;
}

sub write_single_coil {
    my $class = shift;
    my $req = Device::Modbus::Request::WriteSingle->new(
        function => 'Write Single Coil',
        @_
    );
    return $req;
}

sub write_single_register {
    my $class = shift;
    my $req = Device::Modbus::Request::WriteSingle->new(
        function => 'Write Single Register',
        @_
    );
    return $req;
}

sub write_multiple_coils {
    my $class = shift;
    my $req = Device::Modbus::Request::WriteMultiple->new(
        function => 'Write Multiple Coils',
        @_
    );
    return $req;
}
    
sub write_multiple_registers {
    my $class = shift;
    my $req = Device::Modbus::Request::WriteMultiple->new(
        function => 'Write Multiple Registers',
        @_
    );
    return $req;
}

sub read_write_registers {
    my $class = shift;
    my $req = Device::Modbus::Request::ReadWrite->new(
        function => 'Read/Write Multiple Registers',
        @_
    );
    return $req;
}

### Request parsing

sub parse_request {
    my ($class, $binary_req) = @_;

    my $request;
    my $function_code = unpack 'C', $binary_req;
    my $function      = $function_for{$function_code};

    if ($function_code > 0 && $function_code <= 4) {
        $request = Device::Modbus::Request::Read->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 5 || $function_code == 6) {
        $request = Device::Modbus::Request::WriteSingle->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x0f || $function_code == 0x10) {
        $request = Device::Modbus::Request::WriteMultiple->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x17) {
        $request = Device::Modbus::Request::ReadWrite->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    else {
        return Device::Modbus::Exception->new(
            function_code  => $function_code,
            exception_code => 1
        );
        die "Unimplemented function";
    }

    return $request;    
}

1; 
