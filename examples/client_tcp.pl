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
    say "-> $req";
    $client->send_request($req) || die "Send error";
    my $response = $client->receive_response;
    say "<- $response";
}

$client->close;
