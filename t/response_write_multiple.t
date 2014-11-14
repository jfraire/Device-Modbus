use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Device::Modbus::Response') };

# Write Multiple Coils response
{
    my $response = Device::Modbus::Response->multiple_coils_write(
        address  => 20,
        quantity => 10
    );

    isa_ok $response, 'Device::Modbus::Response::WriteMultiple';
    is $response->function_code, 0x0f,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0f0013000a',
        'PDU for Write Multiple Coils function is correct';
}

# Write Multiple Registers response
{
    my $response = Device::Modbus::Response->multiple_registers_write(
        address  => 2,
        quantity => 2
    );

    isa_ok $response, 'Device::Modbus::Response::WriteMultiple';
    is $response->function_code, 0x10,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '1000010002',
        'PDU for Write Multiple Registers function is correct';
}

done_testing();
