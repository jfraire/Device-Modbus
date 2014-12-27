use strict;
use warnings;

use Test::More tests => 30;

BEGIN {
    use_ok('Device::Modbus');
    use_ok('Device::Modbus::TCP');
    use_ok('Device::Modbus::Transaction');
    use_ok('Device::Modbus::Client::TCP');
};

{
    my $client = Device::Modbus::Client::TCP->new();
    isa_ok $client, 'Device::Modbus::Client::TCP';
    is $client->host, '127.0.0.1',
        'By default, client would talk to localhost';
    is $client->port, 502,
        'By default, client uses port 502';
    is $client->max_transactions, 16,
        'The Modbus standard calls for a maximum of 16 transactions';
    is $client->timeout, 2,
        'Timeout for the client is correct';


    is scalar keys $client->waiting_room, 0,
        'The waiting room is empty';
    is $client->next_trn_id, 1,
        'The first transaction id for the client is 1';
    is scalar keys $client->waiting_room, 1,
        'Space in the waiting room has been saved for new transaction';
    is $client->waiting_room->{1}, 1,
        'A simple place holder is in the waiting room';
    is $client->get_from_waiting_room(1), 1,
        'And transactions are retrievable by id from waiting room';
    is scalar keys $client->waiting_room, 0,
        'The waiting room is empty after retrieving id 1';


    my $req = Device::Modbus->read_coils(
        address  => 20,
        quantity => 19
    );
    isa_ok $req, 'Device::Modbus::Request::Read';


    my $trn = $client->init_transaction($req);
    isa_ok $trn, 'Device::Modbus::Transaction';
    is $trn->id, 2,
        'Transaction id was increased by one';
    is $trn->timeout, $client->timeout,
        'Transaction timeout inherited from client';
    is scalar keys $client->waiting_room, 1,
        'Space in the waiting room has been saved for new transaction';
    is $client->waiting_room->{$trn->id}, 1,
        'A simple place holder is in the waiting room';


    $client->move_to_waiting_room($trn);
    is_deeply $client->waiting_room->{$trn->id}, $trn,
        'The transaction is now in the waiting room';


    $trn = $client->request_transaction($req);
    isa_ok $trn, 'Device::Modbus::Transaction';
    is scalar keys $client->waiting_room, 2,
        'Requested transaction is expected in waiting room';

    is_deeply $trn->request, $req,
        'Request is indeed in the transaction';

    my $mbap = pack 'nnnC', 3, 0, length($req->pdu)+1, 0xff;
    is unpack('h*', Device::Modbus::TCP->header($trn, $req->pdu)), unpack('h*', $mbap),
        'MBAP header is calculated as expected';

    my $apu = Device::Modbus::TCP->build_apu($trn, $req->pdu);
    is  unpack('h*', $apu),
        unpack('h*', $mbap . $req->pdu),
        'And the request APU is also as expected';

    my ($zid, $zunit, $zpdu) = Device::Modbus::TCP->break_message($apu);
    is $zid, $trn->id,     'Transaction id parsed back from APU';
    is $zunit, $trn->unit, 'Unit id parsed back from APU';
    is $zpdu,  $req->pdu,  'PDU parsed back from APU';    
}

done_testing();
