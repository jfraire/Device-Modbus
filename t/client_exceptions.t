#! /usr/bin/env perl

use Test::More;
use lib 't/lib';
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Client';
    use_ok 'TestClient';
}

my $client = TestClient->new;

### Validation of read requests
{
    eval {
        my $r = $client->read_coils(
            address => 23,
        );
    };
    like $@, qr/quantity is not defined/,
        'Read requests croak for missing quantity';
}

{
    eval {
        my $r = $client->read_coils(
            address  => 23,
            quantity => undef
        );
    };
    like $@, qr/quantity is not defined/,
        'Read requests croak for undefined quantity';
}

{
    eval {
        my $r = $client->read_coils(
            address  => 23,
            quantity => 0
        );
    };
    like $@, qr/Quantity must be a number/,
        'Read requests croak for a quantity of zero';
}

{
    eval {
        my $r = $client->read_coils(
            address  => 23,
            quantity => 0x7D1
        );
    };
    like $@, qr/Quantity must be a number/,
        'Read requests croak for a quantity of zero';
}

{
    my $r = $client->read_coils(
        address  => 23,
        quantity => 1
    );
    is ref($r), 'Device::Modbus::Request',
        'Read requests are valid when quantity is just one';
}

{
    my $r = $client->read_coils(
        address  => 23,
        quantity => 0x7D0
    );
    is ref($r), 'Device::Modbus::Request',
        'Read requests are valid when quantity is 2000';
}

### Validation of write single register
{
    eval {
        my $r = $client->write_single_register(
            address => 23,
        );
    };
    like $@, qr/value must exist/,
        'Write single register dies if value is missing';
}

{
    eval {
        my $r = $client->write_single_register(
            address => 23,
            value   => undef
        );
    };
    like $@, qr/value must exist/,
        'Write single register dies if value is undefined';
}

{
    eval {
        my $r = $client->write_single_register(
            address => 23,
            value   => 65536
        );
    };
    like $@, qr/between 0 and 65535/,
        'Write single register dies if value is greater than 65535';
}

{
    eval {
        my $r = $client->write_single_register(
            address => 23,
            value   => -1
        );
    };
    like $@, qr/between 0 and 65535/,
        'Write single register dies if value is negative';
}

{
    my $r = $client->write_single_register(
        address  => 23,
        value    =>  0
    );
    is ref($r), 'Device::Modbus::Request',
        'Write single register is valid when value is zero';
}

{
    my $r = $client->write_single_register(
        address  => 23,
        value    =>  0xFF
    );
    is ref($r), 'Device::Modbus::Request',
        'Write single register is valid when value is 0xFF';
}

### Validation of write multiple coils
{
    eval {
        my $r = $client->write_multiple_coils(
            address => 23,
        );
    };
    like $@, qr/values \(array ref\) must exist/,
        'Write multiple coils dies if values array ref is missing';
}

{
    eval {
        my $r = $client->write_multiple_coils(
            address => 23,
            values  => 6
        );
    };
    like $@, qr/values \(array ref\) must exist/,
        'Write multiple coils dies if values is not an array ref';
}

{
    eval {
        my $r = $client->write_multiple_coils(
            address => 23,
            values  => []
        );
    };
    like $@, qr/at least one element/,
        'Write multiple coils dies if values is empty';
}

{
    eval {
        my $r = $client->write_multiple_coils(
            address => 23,
            values  => [(1) x 1969 ]
        );
    };
    like $@, qr/1968 elements at most/,
        'Write multiple coils dies if there are over 1968 values';
}

{
    my $r = $client->write_multiple_coils(
        address  => 23,
        values   =>  [ 0 ]
    );
    is ref($r), 'Device::Modbus::Request',
        'Write multiple coils is valid for a single coil';
}

{
    my $r = $client->write_multiple_coils(
        address  => 23,
        values   =>  [ (0) x 1968 ]
    );
    is ref($r), 'Device::Modbus::Request',
        'Write multiple coils is valid for 1968 coils';
}

### Validation of write multiple registers
{
    eval {
        my $r = $client->write_multiple_registers(
            address => 23,
        );
    };
    like $@, qr/values \(array ref\) must exist/,
        'Write multiple registers dies if values array ref is missing';
}

{
    eval {
        my $r = $client->write_multiple_registers(
            address => 23,
            values  => undef
        );
    };
    like $@, qr/values \(array ref\) must exist/,
        'Write multiple registers dies if values array ref is undef';
}

{
    eval {
        my $r = $client->write_multiple_registers(
            address => 23,
            values  => []
        );
    };
    like $@, qr/at least one element/,
        'Write multiple registers dies if values array ref is empty';
}

{
    eval {
        my $r = $client->write_multiple_registers(
            address => 23,
            values  => [(1) x 124]
        );
    };
    like $@, qr/123 elements at most/,
        'Write multiple registers dies with more than 123 registers';
}

{
    my $r = $client->write_multiple_registers(
        address  => 23,
        values   =>  [ 0 ]
    );
    is ref($r), 'Device::Modbus::Request',
        'Write multiple registers is valid for a single register';
}

{
    my $r = $client->write_multiple_registers(
        address  => 23,
        values   =>  [ (0) x 123 ]
    );
    is ref($r), 'Device::Modbus::Request',
        'Write multiple registers is valid for a 123 registers';
}

### Read/Write registers
{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            values => [1,2,3],
        );
    };
    like $@, qr/read_quantity is required/,
        'Read/Write registers dies when quantity of regs to read is undef';
}

{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            read_quantity => undef,
            values => [1,2,3],
        );
    };
    like $@, qr/read_quantity is not defined/,
        'Read/Write registers dies when qty or regs to read is undef';
}

{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            read_quantity => 0,
            values => [1,2,3],
        );
    };
    like $@, qr/read_quantity .*? between 1 and 125/,
        'Read/Write registers dies with qty of regs to read is zero';
}

{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            read_quantity => 126,
            values => [1,2,3],
        );
    };
    like $@, qr/read_quantity .*? between 1 and 125/,
        'Read/Write registers dies with qty of regs to read is over 125';
}

{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            read_quantity => 123,
        );
    };
    like $@, qr/values \(array ref\) must exist/,
        'Read/Write registers dies without values of regs to write';
}

{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            read_quantity => 123,
            values        => 6
        );
    };
    like $@, qr/values \(array ref\) must exist/,
        'Read/Write registers dies when values is not an array ref';
}

{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            read_quantity => 123,
            values        => []
        );
    };
    like $@, qr/at least one element/,
        'Read/Write registers dies when values is empty';
}

{
    eval {
        my $r = $client->read_write_registers(
            read_address  => 23,
            write_address => 25,
            read_quantity => 123,
            values        => [(22) x 122]
        );
    };
    like $@, qr/at most/,
        'Read/Write registers dies with more than 121 regs to write';
}

{
    my $r = $client->read_write_registers(
        read_address  => 23,
        write_address => 25,
        read_quantity => 125,
        values        => [(22) x 121]
    );
    is ref($r), 'Device::Modbus::Request',
        'Read/Write registers is valid for a 125 registers to read';
}

{
    my $r = $client->read_write_registers(
        read_address  => 23,
        write_address => 25,
        read_quantity => 123,
        values        => [(22) x 121]
    );
    is ref($r), 'Device::Modbus::Request',
        'Read/Write registers is valid for a 121 registers to write';
}

done_testing();
