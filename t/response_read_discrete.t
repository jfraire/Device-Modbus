use strict;
use warnings;

use Test::More tests => 24;
BEGIN { use_ok('Device::Modbus') };

# Build a response object for a read coils request
{
    my $response = Device::Modbus->coils_read(
        values  => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1, 0]        
    );

    isa_ok $response, 'Device::Modbus::Response::ReadDiscrete';
    is $response->function, 'Read Coils',
        'Function name is saved in request object correctly';
    is $response->function_code, 0x01,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0103cd6b05',
        'PDU for Read Coils function is correct';
}

# Parse an incoming response object -- Read Coils
{
    my $message  = pack 'H*', '0103cd6b05';
    my $response = Device::Modbus->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::ReadDiscrete';
    is $response->function, 'Read Coils',
        'Function name is retrieved correctly';
    is $response->function_code, 0x01,
        'Function code returned correctly';
    is $response->bytes, 3,
        'Initial address returned correctly';
    is_deeply $response->values, [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0,0,0,0,0],
        'Values recovered correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';
}

# Build a response object for a read coils request
{
    my $response = Device::Modbus->discrete_inputs_read(
        values  => [0,0,1,1,0,1,0,1,  1,1,0,1,1,0,1,1,  1,0,1,0,1,1]        
    );

    isa_ok $response, 'Device::Modbus::Response::ReadDiscrete';
    is $response->function, 'Read Discrete Inputs',
        'Function name is saved in request object correctly';
    is $response->function_code, 0x02,
        'Function code returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0203acdb35',
        'PDU for Read Discrete Inputs function is correct';
}

# Parse an incoming response object
{
    my $message  = pack 'H*', '0203acdb35';
    my $response = Device::Modbus->parse_response($message);

    isa_ok $response, 'Device::Modbus::Response::ReadDiscrete';
    is $response->function, 'Read Discrete Inputs',
        'Function name is retrieved correctly';
    is $response->function_code, 0x02,
        'Function code returned correctly';
    is $response->bytes, 3,
        'Initial address returned correctly';
    is_deeply $response->values,  [0,0,1,1,0,1,0,1,  1,1,0,1,1,0,1,1,  1,0,1,0,1,1,0,0],
        'Values recovered correctly';
    is $response->pdu, $message,
        'Original message is saved in pdu';

    like "$response", qr{Read Discrete Inputs},
        'Function is correctly stringified';
    like "$response", qr{Bytes: \[3\]},
        'Bytes read is correctly stringified';
    my $values = join ', ', @{$response->values};
    like "$response", qr{Values: \[$values\]},
        'Values are correctly stringified';
}


done_testing();
