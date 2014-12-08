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

$spy->start;
