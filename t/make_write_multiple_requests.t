use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('Device::Modbus') };

# Write Multiple Coils
{
    my $request = Device::Modbus->write_multiple_coils(
        address  => 20,
        values   => [1,0,1,1,0,0,1,1,1,0]
    );

    isa_ok $request, 'Device::Modbus::Request::WriteMultiple';
    is $request->function_code, 0x0F,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0f0013000a02cd01',
        'PDU for Write Multiple Coils function is correct';

    like "$request", qr{Write Multiple Coils},
        'Function is correctly stringified';
    like "$request", qr{Address: \[0x14\]},
        'Address is correctly stringified';
    like "$request", qr{Quantity: \[10\]},
        'Quantity of values is correctly stringified';
    like "$request", qr{Values: \[1, 0, 1, 1, 0, 0, 1, 1, 1, 0\]},
        'Values are correctly stringified';
}

# Write Multiple Registers
{
    my $request = Device::Modbus->write_multiple_registers(
        address  => 2,
        values   => [0x000A, 0x0102]
    );

    isa_ok $request, 'Device::Modbus::Request::WriteMultiple';
    is $request->function_code, 0x10,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '100001000204000a0102',
        'PDU for Write Multiple Registers function is correct';

    like "$request", qr{Write Multiple Registers},
        'Function is correctly stringified';
    like "$request", qr{Address: \[0x02\]},
        'Address is correctly stringified';
    like "$request", qr{Quantity: \[2\]},
        'Quantity of values is correctly stringified';
    like "$request", qr{Values: \[10, 258\]},
        'Values are correctly stringified';
}

done_testing();
