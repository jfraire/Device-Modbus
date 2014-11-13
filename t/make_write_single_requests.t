use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('Device::Modbus::Request') };

# Write Single Coil
{
    my $request = Device::Modbus::Request->write_single_coil(
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
}

# Write Single Register
{
    my $request = Device::Modbus::Request->write_single_register(
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
}

done_testing();
