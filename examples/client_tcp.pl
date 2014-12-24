#! /usr/bin/perl

use Device::Modbus;
use Device::Modbus::Client::TCP;
use Modern::Perl;

my $client = Device::Modbus::Client::TCP->new();

my @reqs = (
    Device::Modbus->read_holding_registers(
        unit     => 1,
        address  => 0,
        quantity => 3
    ),
    Device::Modbus->write_multiple_registers(
        unit     => 1,
        address  => 0,
        values   => [22,23,24]
    ),
    Device::Modbus->read_holding_registers(
        unit     => 1,
        address  => 0,
        quantity => 3
    ),
);



foreach my $req (@reqs) {
    my $trn = $client->request_transaction($req);
    say "-> $req";
    $client->send_request($trn) || die "Send error";
    $client->receive_response   || die "Receive error";
    my $response = $trn->response;
    say "<- $response";
}

$client->close;
