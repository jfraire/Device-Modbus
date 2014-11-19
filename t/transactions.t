use strict;
use warnings;

use Test::More tests => 27;

BEGIN {
    use_ok('Device::Modbus::Request');
    use_ok('Device::Modbus::Response');
    use_ok('Device::Modbus::Transaction');
    use_ok('Device::Modbus::Transaction::TCP');
};

# Build transaction for a Read Coils request
{
    my $trn = Device::Modbus::Transaction::TCP->new(
        id      => 1,
        timeout => 0.2
    );
    isa_ok $trn, 'Device::Modbus::Transaction::TCP';

    my $request = Device::Modbus::Request->read_coils(
        address  => 20,
        quantity => 19
    );

    isa_ok $request, 'Device::Modbus::Request::Read';
    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0100130013',
        'PDU for Read Coils function is correct';

    ok ! $trn->has_request,
        'Originally, transaction does not have a request object';
    ok ! $trn->has_response,
        'Like most things in the world, transaction does not have a response';

    $trn->request($request);
    ok $trn->has_request,
        'The request mutator works';
    is $trn->request_pdu, $pdu,
        'Request PDU retrieved correctly from transaction';
    is $trn->unit, 0xff,
        'Unit number (slave) is set to default value';

    my $mbap = pack 'nnnC', 1, 0, length($pdu)+1, 0xff;
    is $trn->header($trn->request_pdu), $mbap,
        'MBAP header is calculated as expected';

    is $trn->build_request_apu, $mbap . $pdu,
        'And the request APU is also as expected';

    $trn->set_expiration_time(5);
    is $trn->expires, 5.2,
        'Expiration time is set by adding time to timeout';

    is $trn->retries, 0,
        'By default, number of retries is zero';
    is $trn->max_retries, 3,
        'By default, maximum retries is 3';
        
    $trn->increment_retries for (1..3);
    is $trn->retries, 3,
        'Number of retries is incremented correctly';
}

{
    my $trn = Device::Modbus::Transaction::TCP->new(
        id      => 38999,
        unit    => 24,
    );
    isa_ok $trn, 'Device::Modbus::Transaction::TCP';
    ok ! $trn->has_response,
        'Like most things in the world, transaction does not have a response';

    my $response = Device::Modbus::Response->coils_read(
        values  => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1, 0]        
    );
    isa_ok $response, 'Device::Modbus::Response::ReadDiscrete';

    $trn->response($response);
    ok $trn->has_response,
        'The response mutator works';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0103cd6b05',
        'PDU for Read Coils function is correct';

    is $trn->response_pdu, $pdu,
        'Request PDU retrieved correctly from transaction';
    is $trn->unit, 24,
        'Unit number (slave) works correctly';

    my $mbap = pack 'nnnC', 38999, 0, length($pdu)+1, 24;
    is $trn->header($trn->response_pdu), $mbap,
        'MBAP header is calculated as expected';

    is $trn->build_response_apu, $mbap . $pdu,
        'And the response APU is also as expected';
}


done_testing();
