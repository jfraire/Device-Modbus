use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('Device::Modbus::Request') };

# Write Multiple Coils
{
    my $request = Device::Modbus::Request->write_multiple_coils(
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
}

# Write Multiple Registers
{
    my $request = Device::Modbus::Request->write_multiple_registers(
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
}

done_testing();
