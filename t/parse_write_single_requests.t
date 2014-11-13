use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Device::Modbus::Request') };

# Write Single Coil
{
    my $message = pack 'H*', '0500acff00';
    my $request = Device::Modbus::Request->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::WriteSingle';
    is $request->function, 'Write Single Coil',
        'Write Single Coil name is retrieved correctly';
    is $request->function_code, 0x05,
        'Function code returned correctly';
    is $request->address, 173,
        'Initial address returned correctly';
    is $request->value, 1,
        'Quantity of coils returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

# Write Single Register
{
    my $message = pack 'H*', '0600010003';
    my $request = Device::Modbus::Request->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::WriteSingle';
    is $request->function, 'Write Single Register',
        'Write Single Register name is retrieved correctly';
    is $request->function_code, 0x06,
        'Function code returned correctly';
    is $request->address, 2,
        'Initial address returned correctly';
    is $request->value, 3,
        'Quantity of coils returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

done_testing();
