#! /usr/bin/env perl

use Test::MockObject;
use Test::More tests => 22;
use strict;
use warnings;

BEGIN {
    Test::MockObject->fake_module('Device::SerialPort',
        new                => sub { return bless { test_timeout => 0 }, shift },
        baudrate           => sub { return 1 },
        databits           => sub { return 1 },
        stopbits           => sub { return 1 },
        parity             => sub { return 1 },
        handshake          => sub { return 1 },
        read_char_time     => sub { return 1 },
        read_const_time    => sub { return 1 },
        write_settings     => sub { return 1 },
        purge_all          => sub { return 1 },
        close              => sub { return 1 },
        test_timeout       => sub {
            my $self = shift;
            $self->{test_timeout}++ if shift;
            return $self->{test_timeout};
        },
        write              => sub {
            my ($self, $apu) = @_;
            if ($self->test_timeout) {
                return undef;
            }
            is unpack('H*', $apu), '020100130004cc3f',
                'APU to write via the serial port is correct';
            return length($apu);
        },
        read               => sub {
            my $self = shift;
            if ($self->test_timeout) {
                sleep 1;
                return undef;
            }
            my $msg = pack 'H*', '0201010991ca';
            return (length($msg), $msg);
        },
    );
    use_ok 'Device::Modbus';
    use_ok 'Device::Modbus::Client::RTU';
}

{
    my $client = Device::Modbus::Client::RTU->new(port => '/dev/tty0');
    isa_ok $client, 'Device::Modbus::Client::RTU';

    is $client->char_time, 10*1000/9600,
        'Milliseconds per character calculated correctly';

    my %defaults = (
        baudrate => 9600,
        parity   => 'even',
        databits => 8,
        stopbits => 1,
    );

    while (my ($key, $value) = each %defaults) {
        is $client->$key, $value,
            "Default value for $key is $value, as expected";
    }

    can_ok $client, qw(send_request serial read_port);

    # This CRC is taken from the example in Modbus_over_serial_line_V1_02
    # which shows this result in binary and a different number in decimal
    is unpack('v', $client->crc_for(pack 'CC', 2, 7)), 4673,
        'CRC calculated correctly';

    is $client->header(65), chr(65),
        'RTU message header calculated correctly';

    my $message = pack('CC',2,7) . pack('v', 4673);

    my ($unit, $pdu, $footer) = $client->break_message($message);
    is $unit, 2,
        'Unit recovered from message';
    is $pdu, chr(7),
        'PDU recovered from message';
    is $footer, pack('v', 4673),
        'CRC recovered from message';
}

my $req = Device::Modbus->read_coils(
    address  => 19,
    quantity => 4,
    unit     => 2
);

my $res = Device::Modbus->coils_read(
    address => 19,
    values  => [1,0,0,1],
    unit    => 2
);

{
    # Tests send_request using mocked serial port.
    # The send is supposed to fail.
    
    my $client = Device::Modbus::Client::RTU->new(
        port    => '/dev/tty0',
    );
    isa_ok $client, 'Device::Modbus::Client::RTU';
    $client->serial->test_timeout(1);

    eval {
        $client->send_request($req) || die;
    };
    ok $@, 'send_request returns false on failure';
}

{
    # Tests a successful send/receive. 
    my $client = Device::Modbus::Client::RTU->new(
        port    => '/dev/tty0',
    );
    isa_ok $client, 'Device::Modbus::Client::RTU';

#    diag unpack 'H*', $client->build_adu($req);
#    diag unpack 'H*', $client->build_adu($res);

    my $recv;
    eval {
        $recv = $client->send_request($req) || die;
    };
    ok !$@, 'Survived receiving response through mocked serial port';

    isa_ok $recv, 'Device::Modbus::Response::ReadDiscrete';
    # Per Modbus spec, values are multiple of 8 and are thus zero-padded
    is_deeply $recv->values, [1,0,0,1,0,0,0,0],
        'Mocked response values are as expected';
    is $recv->function, 'Read Coils',
        'Mocked response was rebuilt correctly';
}

done_testing();
