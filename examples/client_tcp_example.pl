#! /usr/bin/perl

use Device::Modbus;
use Device::Modbus::Client::TCP;
use Data::Dumper;
use Modern::Perl;

my $client = Device::Modbus::Client::TCP->new();


my $req    = Device::Modbus->read_holding_registers(
    unit     => 1,
    address  => 6,
    quantity => 5
);

foreach (1..5) {
    my $trn = $client->request_transaction($req);
    $client->send_request($trn) || die "Send error";
    $client->receive_response   || die "Receive error";

    if (ref $trn->response eq 'Device::Modbus::Exception') {
        say Dumper $trn->response;
    }
    else {
        say "Values: ", join '-', @{$trn->response->values};
    }
}

$client->close;
