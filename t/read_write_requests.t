use strict;
use warnings;

use Test::More tests => 20;
BEGIN { use_ok('Device::Modbus') };

# Issue a Read/Write Multiple Registers request
{
    my $request = Device::Modbus->read_write_registers(
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
    my $request = Device::Modbus->parse_request($message);

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

    like "$request", qr{Read/Write Multiple Registers},
        'Function is correctly stringified';
    like "$request", qr{Read address: \[0x04\]},
        'Read address is correctly stringified';
    like "$request", qr{Read quantity: \[6\]},
        'Read quantity is correctly stringified';
    like "$request", qr{Write address: \[0x0f\]},
        'Write address is correctly stringified';
    like "$request", qr{Write bytes: \[6\]},
        'Write bytes is correctly stringified';
    like "$request", qr{Write values: \[255-255-255\]},
        'Write values is correctly stringified';
}


done_testing();
