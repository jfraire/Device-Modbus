#! /usr/bin/env perl

use Device::Modbus;
use Device::Modbus::Spy;
use Modern::Perl;

say "Starting Modbus Spy";

my $spy = Device::Modbus::Spy->new(
    port     => '/dev/ttyUSB0',
    baudrate => 9600,
    parity   => 'none',
);

while (1) {
    say $spy->watch_port;
    say $spy->object if defined $spy->object;
    say '---';
}
