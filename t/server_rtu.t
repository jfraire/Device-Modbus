###########################################
# Tests for Device::Modbus::Server::RTU   #
# We are faking both the serial port and  #
# intercepting STDOUT to analyze server   #
# logs.                                   #
###########################################

use lib 't/lib';   # Fake Device SerialPort;
use Test::More tests => 12;
use IO::Scalar;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Server::RTU';
    use_ok 'Test::Unit';
}

my $server = Device::Modbus::Server::RTU->new(port => '/dev/ttyUSB0');
isa_ok $server, 'Device::Modbus::Server::RTU';

$server->add_server_unit('Test::Unit', 1);
ok exists $server->units->{1},
    'Server should respond for unit 1';

ok !exists $server->units->{2},
    'And the way we are looking for units works';

# Test that the signal handlers to shut the server down 
{
    my $fake_STDOUT;                          # Will be written to
    my $fh = IO::Scalar->new(\$fake_STDOUT);  # $fh points to $fake_STDOUT
    local *STDOUT = *$fh;                     # Alias $fh as STDOUT

    is $server->running, 0,
        'Server is not running';

    $server->running(1);

    is $server->running, 1,
        'Server would be running now';

    # Send QUIT signal
    kill 3, $$;

    is $server->running, 0,
        'Server should shutdown now';
    like $fake_STDOUT, qr/shutting down$/,
        'Server did receive the signal to shut down';

    # Fail everything if the above test did not work.
    # The next test would enter an infinite loop otherwise.
    die "Server shut down signal did not work" if $server->running;
}
{
    # Now test that the server actually starts and stops
    
    my $fake_STDOUT;                          # Will be written to
    my $fh = IO::Scalar->new(\$fake_STDOUT);  # $fh points to $fake_STDOUT
    local *STDOUT = *$fh;                     # Alias $fh as STDOUT

    # Once the server starts, this program will block.
    # We must set an alarm to shut it down after some seconds.
    $SIG{ALRM} = sub { note "Shutting server down"; kill 3, $$ };

    alarm(3);
    diag "Kill me if I don't stop: my PID is $$";
    $server->start;

    # The server must be starting... if everything goes well,
    # the alarm will have it shut down.
    # In fact, if the following test is executed then everything went
    # OK.
    alarm(0);
    
    is $server->running, 0,
        'Server did stop';
    like $fake_STDOUT, qr/Server has started$/m,
        'Server did start and logged about it';
    like $fake_STDOUT, qr/shutting down$/,
        'And shutting down was logged as well';
}

done_testing()
