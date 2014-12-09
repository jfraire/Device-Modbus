#! /usr/bin/env perl

use Device::Modbus;
use Device::Modbus::Spy;
use Modern::Perl;

say "Starting Modbus Spy";

my $spy = Device::Modbus::Spy->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
);

while (1) {
    $spy->watch_port;

    say $spy->message;
    say $spy->unit;
    say $spy->pdu;
    say $spy->cdc;
    say '---';
}
