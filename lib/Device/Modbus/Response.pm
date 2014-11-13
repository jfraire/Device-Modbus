package Device::Modbus::Response;

use Moo;

extends 'Device::Modbus';

has function => (is => 'ro', required => 1);
has pdu      => (is => 'rw', lazy => 1, builder  => 1);

require Device::Modbus::Exception;
require Device::Modbus::Response::ReadCoils;

### Request builders

sub coils_read {
    my $class = shift;
    my $req = Device::Modbus::Response::ReadCoils->new(
        function => 'Read Coils',
        @_
    );
    return $req;
}

=for later

sub discrete_inputs_read {
    my $class = shift;
    my $req = Device::Modbus::Request::Read->new(
        function => 'Read Discrete Inputs',
        @_
    );
    return $req;
}

=cut

### Response parsing

sub parse_response {
    my ($class, $binary_req) = @_;

    my $request;
    my $function_code = unpack 'C', $binary_req;
    my $function      = Device::Modbus::function_for($function_code);

    if ($function_code == 0x01) {
        $request = Device::Modbus::Response::ReadCoils->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }

=for later

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
            exception_code => 1,
            request        => $binary_req
        );
        die "Unimplemented function";
    }

=cut

    return $request;    
}

1; 

