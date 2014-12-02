#! /usr/bin/env perl

use Test::More tests => 15;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Client::RTU';
}

my $client = Device::Modbus::Client::RTU->new(port => '/dev/tty0');
isa_ok $client, 'Device::Modbus::Client::RTU';

is $client->char_time, 10*1000/9600,
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

can_ok $client, qw(send_request receive_response serial read_port);

# This CRC is taken from the example in Modbus_over_serial_line_V1_02
# which shows this result in binary and a different number in decimal
is unpack('v', $client->crc_for(pack 'CC', 2, 7)), 4673,
    'CRC calculated correctly';

is $client->header(65), chr(65),
    'RTU message header calculated correctly';

my $message = pack('CC',2,7) . pack('v', 4673);

is unpack('H*', $client->build_apu(2, pack 'C', 7)),
    unpack('H*', $message),
    'APU calculated correclty';

my ($unit, $pdu, $footer) = $client->break_message($message);
is $unit, 2,
    'Unit recovered from message';
is $pdu, chr(7),
    'PDU recovered from message';
is $footer, pack('v', 4673),
    'CRC recovered from message';

done_testing();
