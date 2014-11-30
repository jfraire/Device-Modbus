#! /usr/bin/env perl

use Test::More tests => 9;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Client::RTU';
}

my $client = Device::Modbus::Client::RTU->new(port => '/dev/tty0');
isa_ok $client, 'Device::Modbus::Client::RTU';

is $client->char_time, int(10*1000/9600),
    'Milliseconds per character calculated correctly';

my %defaults = (
    baudrate => 9600,
    parity   => 'even',
    databits => 8,
    stopbits => 1,
    unit     => 1,
);

while (my ($key, $value) = each %defaults) {
    is $client->$key, $value,
        "Default value for $key is $value, as expected";
}

can_ok $client, qw(send_request receive_response serial);

done_testing();
