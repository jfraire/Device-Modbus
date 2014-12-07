#! /usr/bin/env perl

use Device::Modbus;
use Device::Modbus::Client::RTU;
use Data::Dumper;
use Modern::Perl;

my $client = Device::Modbus::Client::RTU->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
);

my $req = Device::Modbus->read_holding_registers(
    address  => 1,
    quantity => 1,
    unit     => 1
);

while (1) {
    $client->send_request($req);
    say "-> $req";
    my $resp = $client->receive_response;
    say "<- $resp";
    sleep 1;
}
