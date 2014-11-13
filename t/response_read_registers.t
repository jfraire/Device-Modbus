use strict;
use warnings;

use Test::More tests => 23;
BEGIN { use_ok('Device::Modbus::Response') };

# Build a response object for a read holding registers request
{
    my $response = Device::Modbus::Response->holding_registers_read(
        values  => [0x022b, 0x0000, 0x0064]        
    );

    isa_ok $response, 'Device::Modbus::Response::ReadRegisters';
    is $response->function, 'Read Holding Registers',
        'Function name is saved in request object correctly';
    is $response->function_code, 0x03,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0306022b00000064',
        'PDU for Read Holding Registers function is correct';
    is $response->bytes, 6,
        'Byte count is correct';
}

# Build a response object for a read holding registers request
{
    my $response = Device::Modbus::Response->input_registers_read(
        values  => [0x000a]        
    );

    isa_ok $response, 'Device::Modbus::Response::ReadRegisters';
    is $response->function, 'Read Input Registers',
        'Function name is saved in request object correctly';
    is $response->function_code, 0x04,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0402000a',
        'PDU for Read Input Registers function is correct';
    is $response->bytes, 2,
        'Byte count is correct';
}

# Parse an incoming response object -- Read holding registers
{
    my $message  = pack 'H*', '0306022b00000064';
    my $response = Device::Modbus::Response->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::ReadRegisters';
    is $response->function, 'Read Holding Registers',
        'Function name is retrieved correctly';
    is $response->function_code, 0x03,
        'Function code returned correctly';
    is $response->bytes, 6,
        'Initial address returned correctly';
    is_deeply $response->values, [0x022b, 0x0000, 0x0064],
        'Values recovered correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';
}

# Parse an incoming response object -- Read input registers
{
    my $message  = pack 'H*', '0402000a';
    my $response = Device::Modbus::Response->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::ReadRegisters';
    is $response->function, 'Read Input Registers',
        'Function name is retrieved correctly';
    is $response->function_code, 0x04,
        'Function code returned correctly';
    is $response->bytes, 2,
        'Initial address returned correctly';
    is_deeply $response->values, [0x000a],
        'Values recovered correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';
}

done_testing();
