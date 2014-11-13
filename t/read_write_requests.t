use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('Device::Modbus::Request') };

# Issue a Read/Write Multiple Registers request
{
    my $request = Device::Modbus::Request->read_write_registers(
        read_address  => 4,
        read_quantity => 6,
        write_address => 15,
        values        => [0x00ff, 0x00ff, 0x00ff]
    );

    isa_ok $request, 'Device::Modbus::Request::ReadWrite';
    is $request->function_code, 0x17,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '1700030006000e00030600ff00ff00ff',
        'PDU for Read Write Registers function is correct';
}

# Parse a Read/Write Multiple Registers request
{
    my $message = pack 'H*','1700030006000e00030600ff00ff00ff';
    my $request = Device::Modbus::Request->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::ReadWrite';
    is $request->function, 'Read/Write Multiple Registers',
        'Read/Write Register request name is retrieved correctly';
    is $request->function_code, 0x17,
        'Function code returned correctly';
    is $request->read_address, 4,
        'Initial address returned correctly';
    is $request->read_quantity, 6,
        'Read quantity returned correctly';
    is $request->write_address, 15,
        'Write address returned correctly';
    is $request->write_quantity, 3,
        'Quantity of registers to write returned correctly';
    is $request->write_bytes, 6,
        'Quantity of bytes to write returned correctly';
    is_deeply $request->values, [0x00ff, 0x00ff, 0x00ff],
        'Values to write returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}


done_testing();
