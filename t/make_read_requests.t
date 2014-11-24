use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('Device::Modbus') };

# Read Coils request
{
    my $request = Device::Modbus->read_coils(
        address  => 20,
        quantity => 19
    );

    isa_ok $request, 'Device::Modbus::Request::Read';
    is $request->function, 'Read Coils',
        'Function name is saved in request object correctly';
    is $request->function_code, 0x01,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0100130013',
        'PDU for Read Coils function is correct';
}

# Read Discrete Inputs
{
    my $request = Device::Modbus->read_discrete_inputs(
        address  => 197,
        quantity => 218-196
    );

    isa_ok $request, 'Device::Modbus::Message';
    is $request->function_code, 0x02,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0200c40016',
        'PDU for Read Discrete Inputs function is correct';
}

# Read Holding Registers
{
    my $request = Device::Modbus->read_holding_registers(
        address  => 108,
        quantity => 110-107
    );

    isa_ok $request, 'Device::Modbus::Message';
    is $request->function_code, 0x03,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '03006b0003',
        'PDU for Read Holding Registers function is correct';
}

# Read Input Registers
{
    my $request = Device::Modbus->read_input_registers(
        address  => 9,
        quantity => 1
    );

    isa_ok $request, 'Device::Modbus::Message';
    is $request->function_code, 0x04,
        'Function code returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0400080001',
        'PDU for Read Input Registers function is correct';
}

done_testing();

