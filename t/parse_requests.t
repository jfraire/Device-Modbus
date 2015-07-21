#! /usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('TestServer');
    use_ok('Device::Modbus::ADU');
};

my @messages = (
    '0100130013',                    # Read coils
    '0200C40016',                    # Read discrete inputs
    '03006B0003',                    # Read holding registers
    '0400080001',                    # Read input registers
    '0500acff00',                    # Write single coil
    '0600010003',                    # Write single register
    '0f0013000a',                    # Write multiple coils
    '1000010002',                    # Write multiple registers
    '170c00fe0acd00010003000d00ff',  # Read/Write multiple registers
    '0500ac0000',                    # Write single coil - false value
);

my $server = TestServer->new(
    map { pack 'H*', $_ } @messages
);

# Read coils
{
    $server->set_index(0);
    my $adu = Device::Modbus::ADU->new;
    my $req = $server->parse_pdu($adu);
    isa_ok $req, 'Device::Modbus::Request';
    is $req->{code}, 0x01,
        'Read coils request has correct code number';
    is $req->{address}, 0x13,
        'Address is correct';
    is $req->{quantity}, 0x13,
        'The quantity of coils to read is correct';
}

# Read discrete inputs
{
    $server->set_index(1);
    my $adu = Device::Modbus::ADU->new;
    my $req = $server->parse_pdu($adu);
    isa_ok $req, 'Device::Modbus::Request';
    is $req->{code}, 0x02,
        'Read discrete inputs has correct code number';
    is $req->{address}, 0xC4,
        'Address is correct';
    is $req->{quantity}, 0x16,
        'The quantity of discrete inputs to read is correct';
}

# Read holding registers
{
    $server->set_index(2);
    my $adu = Device::Modbus::ADU->new;
    my $req = $server->parse_pdu($adu);
    isa_ok $req, 'Device::Modbus::Request';
    is $req->{code}, 0x03,
        'Read coils request has correct code number';
    is $req->{address}, 0x6B,
        'Address is correct';
    is $req->{quantity}, 0x03,
        'The quantity of holding registers to read is correct';
}

# Read input registers
{
    $server->set_index(3);
    my $adu = Device::Modbus::ADU->new;
    my $req = $server->parse_pdu($adu);
    is $req->{code}, 0x04,
        'Read coils request has correct code number';
    is $req->{address}, 0x08,
        'Address is correct';
    is $req->{quantity}, 0x01,
        'The quantity of input registers to read is correct';
}

done_testing();
