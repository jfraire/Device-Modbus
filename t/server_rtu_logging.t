
use lib 't/lib'; # Load fake Device::SerialPort
use IO::Scalar;
use Test::More tests => 9;
use strict;
use warnings;

# Tests for the logging routine in Device::Modbus::Server

BEGIN {
    use_ok 'Device::Modbus::Server::RTU';
}

{
    # Well, I need to see what is printed to STDOUT
    my $fake_STDOUT;                          # Will be written to
    my $fh = IO::Scalar->new(\$fake_STDOUT);  # $fh points to $fake_STDOUT
    local *STDOUT = *$fh;                     # Alias $fh as STDOUT

    print STDOUT 'Holy shit, it works!';
    is $fake_STDOUT, 'Holy shit, it works!',
        'STDOUT has been redirected to a scalar for testing';
}

my $server = Device::Modbus::Server::RTU->new(
    port => '/dev/ttyUSB0',
);
isa_ok $server, 'Device::Modbus::Server::RTU';

{
    my $fake_STDOUT;                          # Will be written to
    my $fh = IO::Scalar->new(\$fake_STDOUT);  # $fh points to $fake_STDOUT
    local *STDOUT = *$fh;                     # Alias $fh as STDOUT

    is $server->log_level, 2,
        'Log level set correctly';

    $server->log(3, 'This should not go through!');
    ok !$fake_STDOUT,
        'Lower level messages do not go through';

    $server->log(2, 'But this one does');
    like $fake_STDOUT, qr/But this one does$/,
        'Message with the right level did go through';

    $server->log(1, 'And this one too');
    like $fake_STDOUT, qr/And this one too$/,
        'Message with higher level passed also';

    $server->log(1, sub {
        ok 1, 'Subroutine messages are executed';
        return 'It did execute'
    });

    like $fake_STDOUT, qr/It did execute$/,
        'Subroutine message was executed and included in the log';

    note $fake_STDOUT;
}

done_testing();

    
