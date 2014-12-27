#! /usr/bin/env perl

use Test::More tests => 18;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus';
    use_ok 'Device::Modbus::Server';
    use_ok 'Device::Modbus::Unit';
    use_ok 'Device::Modbus::Unit::Address';
}

{
    package My::Server;
    use Moo;
    with 'Device::Modbus::Server';

    sub start {
        print STDERR "# Required by Device::Modbus::Server\n";
    }
}

{
    package My::Unit;
    use Moo;
    extends 'Device::Modbus::Unit';

    has last_command => (is => 'rw', default => sub {[]});

    sub init_unit {
        my $unit = shift;

        #                Zone            addr qty    method
        #           -------------------  ---- ---   ---------
        $unit->put('discrete_coils',      742, 3, 'dc_die');
        $unit->get('discrete_coils',      742, 3, 'dc_die');
    }

    sub dc_die {
        die "# Should throw exception 4\n";
    }
}

my $server = My::Server->new();
ok $server->does('Device::Modbus::Server'),
    'The server object plays Device::Modbus::Server';

my $unit = $server->add_server_unit('My::Unit', 3);
isa_ok $unit, 'My::Unit';

{
    # Invalid address
    my $request = Device::Modbus->read_coils(
        address  => 19,
        quantity => 3
    );
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->exception_code => 2,
        'Address did not match and correct exception was returned';
    diag $resp;
}
{
    # Invalid quantity
    my $request = Device::Modbus->read_coils(
        address  => 742,
        quantity => 4
    );
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->exception_code => 3,
        'Quantity did not match and correct exception was returned';
    diag $resp;
}
{
    # Route handler dies
    my $request = Device::Modbus->read_coils(
        address  => 742,
        quantity => 3
    );
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->exception_code => 4,
        'Route handler died and correct exception was returned';
    diag $resp;
}

{
    # Invalid address
    my $request = Device::Modbus->write_multiple_coils(
        address  => 19,
        values   => [0,0,0]
    );
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->exception_code => 2,
        'Address did not match and correct exception was returned';
    diag $resp;
}
{
    # Invalid quantity
    my $request = Device::Modbus->write_single_coil(
        address  => 742,
        value    => 0
    );
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->exception_code => 3,
        'Quantity did not match and correct exception was returned';
    diag $resp;
}
{
    # Route handler dies
    my $request = Device::Modbus->write_multiple_coils(
        address  => 742,
        values   => [0,0,0]
    );
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->exception_code => 4,
        'Route handler died and correct exception was returned';
    diag $resp;
}

done_testing();
