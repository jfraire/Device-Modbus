#! /usr/bin/env perl

use Test::MockObject;
use Test::More tests => 26;
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
            is unpack('H*', $apu), 'ff010013001399dc',
                'APU to write via the serial port is correct';
            return length($apu);
        },
        read               => sub {
            my $self = shift;
            if ($self->test_timeout) {
                sleep 1;
                return undef;
            }
            my $msg = pack 'H*', 'ff0500acff0059c5';
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

    can_ok $client, qw(send_request receive_response serial read_port);

    # This CRC is taken from the example in Modbus_over_serial_line_V1_02
    # which shows this result in binary and a different number in decimal
    is unpack('v', $client->crc_for(pack 'CC', 2, 7)), 4673,
        'CRC calculated correctly';

    is $client->header(65), chr(65),
        'RTU message header calculated correctly';

    my $message = pack('CC',2,7) . pack('v', 4673);

    is unpack('H*', $client->build_adu(2, pack 'C', 7)),
        unpack('H*', $message),
        'APU calculated correclty';

    my ($unit, $pdu, $footer) = $client->break_message($message);
    is $unit, 2,
        'Unit recovered from message';
    is $pdu, chr(7),
        'PDU recovered from message';
    is $footer, pack('v', 4673),
        'CRC recovered from message';
}


{
    # Tests reading a response.
    # This should time out. 
    my $client = Device::Modbus::Client::RTU->new(
        port    => '/dev/tty0',
        timeout => 0.1
    );
    isa_ok $client, 'Device::Modbus::Client::RTU';
    $client->serial->test_timeout(1);

    eval {
        $client->receive_response || die;
    };
    ok $@, 'Mocked serial port timed out correctly';
}
    
{
    # Tests send_request using mocked serial port.
    # The send is supposed to fail.
    
    my $client = Device::Modbus::Client::RTU->new(
        port    => '/dev/tty0',
    );
    isa_ok $client, 'Device::Modbus::Client::RTU';
    $client->serial->test_timeout(1);

    my $request = Device::Modbus->read_coils(
        address  => 19,
        quantity => 19
    );

    my $bytes;
    eval {
        $bytes = $client->send_request($request) || die;
    };
    ok $@, 'send_request returns false on failure';
}

{
    # Tests reading a response.
    # This should succeed. 
    my $client = Device::Modbus::Client::RTU->new(
        port    => '/dev/tty0',
    );
    isa_ok $client, 'Device::Modbus::Client::RTU';

    my $resp = Device::Modbus->single_coil_write(
        address  => 172,
        value    => 1
    );

    # my $apu = $client->build_apu($resp->unit, $resp->pdu);
    # diag "APU: " . unpack 'H*', $apu;

    my $received;
    eval {
        $received = $client->receive_response || die;
    };
    ok !$@, 'Survived receiving response through mocked serial port';

    is "$received", "$resp",
        'Mocked response was rebuilt correctly';
}

{
    # Tests send_request using mocked serial port.
    # The send is supposed to succeed.
    
    my $client = Device::Modbus::Client::RTU->new(
        port    => '/dev/tty0',
    );
    isa_ok $client, 'Device::Modbus::Client::RTU';

    my $request = Device::Modbus->read_coils(
        address  => 19,
        quantity => 19
    );

    my $bytes;
    eval {
        $bytes = $client->send_request($request) || die;
    };
    ok !$@, 'send_request survived with mocked-up serial port';

    is $bytes, length($request->pdu) + 3,
        'send_request returns the right number of bytes';
}

done_testing();
