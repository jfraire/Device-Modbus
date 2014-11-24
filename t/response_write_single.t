use strict;
use warnings;

use Test::More tests => 19;
BEGIN { use_ok('Device::Modbus') };

# Write Single Coil
{
    my $response = Device::Modbus->single_coil_write(
        address  => 173,
        value    => 1
    );

    isa_ok $response, 'Device::Modbus::Response::WriteSingle';
    is $response->function_code, 0x05,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500acff00',
        'PDU for Write Single Coil function is correct';
}

# Write Single Register
{
    my $response = Device::Modbus->single_register_write(
        address  => 2,
        value    => 0x03
    );

    isa_ok $response, 'Device::Modbus::Response::WriteSingle';
    is $response->function_code, 0x06,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0600010003',
        'PDU for Write Single Register function is correct';
}

# Write Single Coil
{
    my $message = pack 'H*', '0500acff00';
    my $response = Device::Modbus->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::WriteSingle';
    is $response->function, 'Write Single Coil',
        'Write Single Coil name is retrieved correctly';
    is $response->function_code, 0x05,
        'Function code returned correctly';
    is $response->address, 173,
        'Initial address returned correctly';
    is $response->value, 1,
        'Quantity of coils returned correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';
}

# Write Single Register
{
    my $message = pack 'H*', '0600010003';
    my $response = Device::Modbus->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::WriteSingle';
    is $response->function, 'Write Single Register',
        'Write Single Register name is retrieved correctly';
    is $response->function_code, 0x06,
        'Function code returned correctly';
    is $response->address, 2,
        'Initial address returned correctly';
    is $response->value, 3,
        'Quantity of coils returned correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';
}

done_testing();
