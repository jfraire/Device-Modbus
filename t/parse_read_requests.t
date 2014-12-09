use strict;
use warnings;

use Test::More tests => 25;
BEGIN { use_ok('Device::Modbus') };

# Read Coils request
{
    my $message = pack 'H*', '0100130013';
    my $request = Device::Modbus->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::Read';
    is $request->function, 'Read Coils',
        'Function name is retrieved correctly';
    is $request->function_code, 0x01,
        'Function code returned correctly';
    is $request->address, 19,
        'Initial address returned correctly';
    is $request->quantity, 19,
        'Quantity of coils returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

# Read Discrete Inputs
{
    my $message = pack 'H*', '0200c40016';
    my $request = Device::Modbus->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::Read';
    is $request->function, 'Read Discrete Inputs',
        'Function name is retrieved correctly';
    is $request->function_code, 0x02,
        'Function code returned correctly';
    is $request->address, 196,
        'Initial address returned correctly';
    is $request->quantity, 218-196,
        'Quantity of discrete inputs returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

# Read Holding Registers
{
    my $message = pack 'H*', '03006b0003';
    my $request = Device::Modbus->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::Read';
    is $request->function, 'Read Holding Registers',
        'Function name is retrieved correctly';
    is $request->function_code, 0x03,
        'Function code returned correctly';
    is $request->address, 107,
        'Initial address returned correctly';
    is $request->quantity, 3,
        'Quantity of holding registers returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

# Read Input Registers
{
    my $message = pack 'H*', '0400080001';
    my $request = Device::Modbus->parse_request($message);

    isa_ok $request, 'Device::Modbus::Request::Read';
    is $request->function, 'Read Input Registers',
        'Function name is retrieved correctly';
    is $request->function_code, 0x04,
        'Function code returned correctly';
    is $request->address, 8,
        'Initial address returned correctly';
    is $request->quantity, 1,
        'Quantity of input registers returned correctly';
    is $request->pdu, $message,
        'Original message is saved in pdu';
}

done_testing();
