#! /usr/bin/env perl

use Device::Modbus;
use Device::Modbus::Client::RTU;
use Data::Dumper;
use Modern::Perl;

my $client = Device::Modbus::Client::RTU->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
    unit     => 1
);

my $req = Device::Modbus->read_holding_registers(
    address  => 1,
    quantity => 1
);

say Dumper $req;

while (1) {
    say "Sent bytes: " . $client->send_request($req);
    my $resp = $client->receive_response;
    say Dumper $resp;
    sleep 1;
}
