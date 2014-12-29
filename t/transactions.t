use strict;
use warnings;

use Test::More tests => 19;

BEGIN {
    use_ok('Device::Modbus');
    use_ok('Device::Modbus::Transaction');
};

# Build transaction for a Read Coils request
{
    my $trn = Device::Modbus::Transaction->new(
        id      => 1,
        timeout => 0.2
    );
    isa_ok $trn, 'Device::Modbus::Transaction';

    my $request = Device::Modbus->read_coils(
        address  => 19,
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
    my $trn = Device::Modbus::Transaction->new(
        id      => 38999,
        timeout => 0.2
    );
    isa_ok $trn, 'Device::Modbus::Transaction';
    ok ! $trn->has_response,
        'Like most things in the world, transaction does not have a response';

    my $response = Device::Modbus->coils_read(
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
}


done_testing();
