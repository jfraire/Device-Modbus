use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Device::Modbus::Response') };

# Read/Write Multiple Registers response
{
    my $response = Device::Modbus::Response->read_write_registers(
        values   => [0x00fe, 0x0acd, 0x0001, 0x0003, 0x000d, 0x00ff]
    );

    isa_ok $response, 'Device::Modbus::Response::ReadWrite';
    is $response->function_code, 0x17,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '170c00fe0acd00010003000d00ff',
        'PDU for Read/Write Multiple Registers function is correct';
}

# Parse Read/Write Multiple Registers response
{
    my $message = pack 'H*', '170c00fe0acd00010003000d00ff';
    my $response = Device::Modbus::Response->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::ReadWrite';
    is $response->function, 'Read/Write Multiple Registers',
        'Read/Write Multiple Registers name is retrieved correctly';
    is $response->function_code, 0x17,
        'Function code returned correctly';
    is $response->bytes, 12,
        'Quantity of read bytes returned correctly';
    is_deeply $response->values, [0x00fe, 0x0acd, 0x0001, 0x0003, 0x000d, 0x00ff],
        'Read values returned correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';
}

done_testing();
