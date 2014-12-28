use lib 't/lib';
use strict;
use warnings;

use Test::More tests => 16;

BEGIN {
    use_ok('Device::Modbus');
    use_ok('Device::Modbus::Client::TCP');
    use_ok('Device::Modbus::Server::TCP');
    use_ok('Test::Unit');
};


# Launch server
my $pid = fork;

if (!$pid) {
    # We are the child
    my $unit   = Test::Unit->new(id => 1);
    my $server = Device::Modbus::Server::TCP->new(
        log_level         => 1,
        log_file          => '/tmp/mbserver.log',
        min_servers       => 1,
        max_servers       => 3,
        min_spare_servers => 0,
        max_spare_servers => 2,
        max_requests      => 10,
        check_for_dead    => 2,
        check_for_waiting => 2,
        port              => 22003,
    );

    $server->add_server_unit($unit);
    $server->start;
    exit(0);
}

# And the parent continues here
note "Forked with PID $pid to start server";
sleep 3;

# Now build a client and send some requests:
my $client = Device::Modbus::Client::TCP->new(port => 22003);
isa_ok $client, 'Device::Modbus::Client::TCP';

{
    # It should succeed
    my $req = Device::Modbus->read_holding_registers(
            unit     => 1,
            address  => 0,
            quantity => 3
    );
    note $req;

    my $trn = $client->request_transaction($req);

    $client->send_request($trn) || die "Send error";

    my $response = $trn->response;
    ok defined $response,
        'Response was received';
    note "$response";

    is_deeply $response->values, [100,101,102],
        'Response received correctly';
}
{
    # It should return an exception 2: Wrong address
    my $req = Device::Modbus->read_discrete_inputs(
            unit     => 1,
            address  => 1,
            quantity => 6
    );
    note $req;

    my $trn = $client->request_transaction($req);

    $client->send_request($trn) || die "Send error";

    my $response = $trn->response;
    ok defined $response,
        'Response was received';
    note "$response";

    isa_ok $response, 'Device::Modbus::Exception';
    is $response->exception_code, 2,
        'Exception code is correct - wrong address';
}
{
    # It should return an exception 3: Wrong quantity
    my $req = Device::Modbus->read_discrete_inputs(
            unit     => 1,
            address  => 0,
            quantity => 3
    );
    note $req;

    my $trn = $client->request_transaction($req);

    $client->send_request($trn) || die "Send error";

    my $response = $trn->response;
    ok defined $response,
        'Response was received';
    note "$response";

    isa_ok $response, 'Device::Modbus::Exception';
    is $response->exception_code, 3,
        'Exception code is correct - invalid quantity';
}
{
    # It should return an exception 4: Server processing error
    my $req = Device::Modbus->read_discrete_inputs(
            unit     => 1,
            address  => 0,
            quantity => 6
    );
    note $req;

    my $trn = $client->request_transaction($req);

    $client->send_request($trn) || die "Send error";

    my $response = $trn->response;
    ok defined $response,
        'Response was received';
    note "$response";

    isa_ok $response, 'Device::Modbus::Exception';
    is $response->exception_code, 4,
        'Exception code is correct - server error';
}

done_testing();

END {
    $client->close if defined $client;
    if ($pid) {
        note "Sending terminate signal to server process $pid";
        kill 1, $pid;
        note "Wait to end server: ", wait();
    }
}
