use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Device::Modbus') };

# Write Single Coil
{
    my $request = Device::Modbus->write_single_coil(
        address  => 173,
        value    => 1
    );

    isa_ok $request, 'Device::Modbus::Request::WriteSingle';
    is $request->function_code, 0x05,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500acff00',
        'PDU for Write Single Coil function is correct';

    like "$request", qr{Write Single Coil},
        'Function is correctly stringified';
    like "$request", qr{Address: \[0xad\]},
        'Address is correctly stringified';
    like "$request", qr{Value: \[1\]},
        'Value is correctly stringified';
}

# Write Single Register
{
    my $request = Device::Modbus->write_single_register(
        address  => 2,
        value    => 0x03
    );

    isa_ok $request, 'Device::Modbus::Request::WriteSingle';
    is $request->function_code, 0x06,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0600010003',
        'PDU for Write Single Register function is correct';

    like "$request", qr{Write Single Register},
        'Function is correctly stringified';
    like "$request", qr{Address: \[0x02\]},
        'Address is correctly stringified';
    like "$request", qr{Value: \[3\]},
        'Value is correctly stringified';
}

done_testing();
