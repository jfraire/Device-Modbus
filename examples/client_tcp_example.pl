#! /usr/bin/perl

use Device::Modbus;
use Device::Modbus::Client::TCP;
use Modern::Perl;

my $client = Device::Modbus::Client::TCP->new();

my $req    = Device::Modbus->read_holding_registers(
    unit     => 1,
    address  => 6,
    quantity => 5
);

foreach (1..5) {
    my $trn = $client->request_transaction($req);
    say "-> $req";
    $client->send_request($trn) || die "Send error";
    $client->receive_response   || die "Receive error";
    my $response = $trn->response;
    say "<- $response";
}

$client->close;
