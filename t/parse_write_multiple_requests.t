use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Device::Modbus::Request') };

# Write Multiple Coils
{
    my $message = pack 'H*', '0f0013000a02cd01';
    my $request = Device::Modbus::Request->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::WriteMultiple';
    is $request->function, 'Write Multiple Coils',
        'Write Multiple Coils name is retrieved correctly';
    is $request->function_code, 0x0f,
        'Function code returned correctly';
    is $request->address, 20,
        'Initial address returned correctly';
    is $request->quantity, 10,
        'Number of coils returned correctly';
    is_deeply $request->values, [1,0,1,1,0,0,1,1,1,0],
        'Values of coils returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

# Write Multiple Registers
{
    my $message = pack 'H*', '100001000204000a0102';
    my $request = Device::Modbus::Request->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::WriteMultiple';
    is $request->function, 'Write Multiple Registers',
        'Write Multiple Registers name is retrieved correctly';
    is $request->function_code, 0x10,
        'Function code returned correctly';
    is $request->address, 2,
        'Initial address returned correctly';
    is $request->quantity, 2,
        'Number of coils returned correctly';
    is_deeply $request->values, [0x000A, 0x0102],
        'Values of coils returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

done_testing();

