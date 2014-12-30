############################################################
# Tests for Device::Modbus::Server::RTU                    #
# Faking the serial port                                   #
############################################################

# NOTE NOTE NOTE
# This test file was quite difficult to get right. The server has not
# been tested in real life.
# Good luck if you need to modify this test

use lib 't/lib';   # Fake Device SerialPort;
use Test::More tests => 35;
use IO::Scalar;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Server::RTU';
    use_ok 'Test::Unit';
}



# NOTE NOTE NOTE
# Set debug level here
my $server = Device::Modbus::Server::RTU->new(
    port      => '/dev/ttyUSB0',
    log_level => 1,
);
isa_ok $server, 'Device::Modbus::Server::RTU';


# Test::OtherUnit has been written to work against the requests below.
# It contains some of the 35 tests that are run by this program
$server->add_server_unit('Test::OtherUnit', 5);
ok exists $server->units->{5},
    'Server should respond for unit 5';



# This is the list of requests -- all of them are for unit 5.
# We will send these trhought the faked serial port and wait for
# the responses, which will come through the serial port too.
my @requests = (
    # Zone: discrete coils
    Device::Modbus->read_coils(
        unit     => 5,
        address  => 19,
        quantity => 19
    ),
    Device::Modbus->write_single_coil(
        unit     => 5,
        address  => 19,
        value    => 1
    ),
    Device::Modbus->write_multiple_coils(
        unit     => 5,
        address  => 19,
        values   => [1,0,1,1,0,0,1,1,0,0]
    ),

    # Zone: discrete inputs
    Device::Modbus->read_discrete_inputs(
        unit     => 5,
        address  => 196,
        quantity => 3
    ),

    # Zone: input registers
    Device::Modbus->read_input_registers(
        unit     => 5,
        address  => 8,
        quantity => 3
    ),

    # Zone: holding registers
    Device::Modbus->read_holding_registers(
        unit     => 5,
        address  => 10,
        quantity => 2
    ),
    Device::Modbus->write_single_register(
        unit     => 5,
        address  => 1,
        value    => 0x03
    ),
    Device::Modbus->write_multiple_registers(
        unit     => 5,
        address  => 1,
        values   => [0x000A, 0x0102]
    ),
    Device::Modbus->read_write_registers(
        unit          => 5,
        read_address  => 3,
        read_quantity => 6,
        write_address => 14,
        values        => [0x00ff, 0x00ff, 0x00ff]
    ),    
);

# The trick here is to feed an array of ADUs to the faked read
# method of Device::SerialPort to fool the server into thinking that 
# ADUs come from the port. Because the read method in Device::SerialPort
# returns the byte length as well as the message, we need to calculate
# both.
# The faked read routine must return one request at a time.

# Build requests' ADUs and get their lengths
my @adus;
foreach my $req (@requests) {
    my $adu = $server->build_adu($req);
    push @adus, [ length($adu), $adu ];
}

# This anonymous subroutine will return one request each time it is
# called. It will die when it is finished :-)
my $iter = sub {
    die 'Finished with the requests' unless @adus;
    my $ret = shift @adus;
    # note "Reading ADU: " . unpack 'H*', $ret->[1];
    return @$ret;
};

# And now, we feed the iterator to the serial port... MUAH HA Ha ha...
$server->serial->lines_to_read( $iter );

# Our responses will come through the write method of the serial port
# so we need to fake it as well.
# The write method of Device::SerialPort will receive response ADUs
# too... they must be turned into response objects.
# Tests will be performed on the response objects.

my @tests = (
    # Read coils
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::ReadDiscrete';
        is $resp->function, 'Read Coils',
            'Received a response for Read Coils';
        is_deeply $resp->values, [(1) x 19,(0) x 5],
            'Read coils worked';
    },
    # Write single coil
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::WriteSingle';
        is $resp->function, 'Write Single Coil',
            'Received a response for Write Single Coil';
    },
    # Write multiple coils
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::WriteMultiple';
        is $resp->function, 'Write Multiple Coils',
            'Received a response for Write Multiple Coils';
    },
    # Read discrete inputs
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::ReadDiscrete';
        is $resp->function, 'Read Discrete Inputs',
            'Received a response for Read Discrete Inputs';
        is_deeply $resp->values, [1,1,1,0,0,0,0,0],
            'Read discrete input worked';
    },
    # Read input registers
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::ReadRegisters';
        is $resp->function, 'Read Input Registers',
            'Received a response for Read Input Registers';
        is_deeply $resp->values, [1,2,3],
            'Read input registers worked';
    },
    # Read holding registers
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::ReadRegisters';
        is $resp->function, 'Read Holding Registers',
            'Received a response for Read Holding Registers';
        is_deeply $resp->values, [1,2],
            'Read holding registers worked';
    },
    # Write single coil
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::WriteSingle';
        is $resp->function, 'Write Single Register',
            'Received a response for Write Single Register';
    },
    # Write multiple registers
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::WriteMultiple';
        is $resp->function, 'Write Multiple Registers',
            'Received a response for Write Multiple Registers';
    },
    # Read/Write holding registers
    sub {
        my $resp = shift;
        isa_ok $resp, 'Device::Modbus::Response::ReadWrite';
        is $resp->function, 'Read/Write Multiple Registers',
            'Received a response for Read/Write Registers';
        is_deeply $resp->values, [1,2,3,4,5,6],
            'Read/Write registers worked';
    },
);

# This is the sub that will intercept messages going to the serial port
my $write_iter = sub {
    my $adu = shift;

    # This routine is, in fact, a Modbus client
    # note "Response ADU: " . unpack 'H*', $adu;
    my ($unit, $pdu, $footer) = $server->break_message($adu);
    my $resp = Device::Modbus->parse_response($pdu);
    $resp->unit($unit);

    my $tests = shift @tests;
    $tests->($resp);
};

# Install the fake write method
$server->serial->when_writing_do($write_iter);


# And FINALLY run some tests :-)
# The reading routine fed to the fake port will die at the end
eval {
    $server->start;
};

like $@, qr/Finished with the requests/,
    'Tests were run to the end!';

done_testing()
