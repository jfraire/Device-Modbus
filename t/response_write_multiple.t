use strict;
use warnings;

use Test::More tests => 22;
BEGIN { use_ok('Device::Modbus') };

# Write Multiple Coils response
{
    my $response = Device::Modbus->multiple_coils_write(
        address  => 19,
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
    my $response = Device::Modbus->multiple_registers_write(
        address  => 1,
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

# Parse Write Multiple Coils response
{
    my $message = pack 'H*', '0f0013000a';
    my $response = Device::Modbus->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::WriteMultiple';
    is $response->function, 'Write Multiple Coils',
        'Write Multiple Coils name is retrieved correctly';
    is $response->function_code, 0x0f,
        'Function code returned correctly';
    is $response->address, 19,
        'Initial address returned correctly';
    is $response->quantity, 10,
        'Quantity of coils returned correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';
}

# Parse Write Multiple Registers response
{
    my $message = pack 'H*', '1000010002';
    my $response = Device::Modbus->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::WriteMultiple';
    is $response->function, 'Write Multiple Registers',
        'Write Multiple Registers name is retrieved correctly';
    is $response->function_code, 0x10,
        'Function code returned correctly';
    is $response->address, 1,
        'Initial address returned correctly';
    is $response->quantity, 2,
        'Quantity of registers returned correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';

    like "$response", qr{Write Multiple Registers},
        'Function is correctly stringified';
    like "$response", qr{Address: \[0x01\]},
        'Address is correctly stringified';
    like "$response", qr{Quantity: \[2\]},
        'Quantitty is correctly stringified';
}

done_testing();
