#! /usr/env/perl

use Test::More tests => 48;
use List::Util qw(shuffle);
use lib 't/lib'; # load fake Device::SerialPort
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus';
    use_ok 'Device::Modbus::Spy';
    use_ok 'Device::Modbus::Client::RTU';
}

my @requests = (
    Device::Modbus->read_coils(
        unit     => 5,
        address  => 19,
        quantity => 19
    ),
    Device::Modbus->read_discrete_inputs(
        address  => 196,
        quantity => 218-196
    ),
    Device::Modbus->read_holding_registers(
        address  => 107,
        quantity => 110-107
    ),
    Device::Modbus->read_input_registers(
        address  => 8,
        quantity => 1
    ),
    Device::Modbus->write_single_coil(
        unit     => 3,
        address  => 172,
        value    => 1
    ),
    Device::Modbus->write_single_register(
        address  => 1,
        value    => 0x03
    ),
    Device::Modbus->write_multiple_coils(
        address  => 19,
        values   => [1,0,1,1,0,0,1,1,0,0]
    ),
    Device::Modbus->write_multiple_registers(
        address  => 1,
        values   => [0x000A, 0x0102]
    ),
    Device::Modbus->read_write_registers(
        read_address  => 3,
        read_quantity => 6,
        write_address => 14,
        values        => [0x00ff, 0x00ff, 0x00ff]
    ),    
);

my @responses = (
    Device::Modbus->single_coil_write(
        address  => 172,
        value    => 1
    ),
    Device::Modbus->registers_read_write(
        values   => [0x00fe, 0x0acd, 0x0001, 0x0003, 0x000d, 0x00ff]
    ),
    Device::Modbus->coils_read(
        values  => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0,0,0,0,0]        
    ),
    Device::Modbus->discrete_inputs_read(
        values  => [0,0,1,1,0,1,0,1,  1,1,0,1,1,0,1,1,  1,0,1,0,1,1,0,0]        
    ),
    Device::Modbus->holding_registers_read(
        values  => [0x022b, 0x0000, 0x0064]
    ),
    Device::Modbus->input_registers_read(
        values  => [0x000a]
    ),
    Device::Modbus->multiple_coils_write(
        address  => 19,
        quantity => 10
    ),
    Device::Modbus->multiple_registers_write(
        address  => 1,
        quantity => 2
    ),
    Device::Modbus->single_register_write(
        address  => 1,
        value    => 0x03
    )
);

my @exceptions = (
    Device::Modbus::Exception->new(
        function       => 'Read Coils',
        exception_code => 1
    ),
    Device::Modbus::Exception->new(
        function       => 'Write Single Coil',
        exception_code => 2
    ),
    Device::Modbus::Exception->new(
        function       => 'Read Input Registers',
        exception_code => 3
    ),
    Device::Modbus::Exception->new(
        unit           => 3,
        function       => 'Write Multiple Registers',
        exception_code => 4
    ),
);

my $spy = Device::Modbus::Spy->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
);
isa_ok $spy, 'Device::Modbus::Spy';

my $client = Device::Modbus::Client::RTU->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
);

foreach my $msg ( shuffle (@requests, @responses, @exceptions)) {
    # Build ADU
    my $adu = $client->build_adu($msg);
    
    # Feed it to the spy
    $spy->parse_message($adu);

    my $class = ref $msg =~ /Device::Modbus::Request/ ?
        'Request' : 'Response';

    is $spy->raw_object->function, $msg->function, 
        "Retrieved function ($class): " . $msg->function;

    if (ref($msg) =~ /WriteSingle/) {
        # Well, for these functions responses and requests look the same
        is_deeply {%{$spy->raw_object}}, {%$msg},
            'Object rebuilt correctly for ' . $msg->function;
    }
    else {
        is $spy->raw_object . '', "$msg", 
            'Object rebuilt correctly for ' . $msg->function;
    }
}

done_testing();
