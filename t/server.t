#! /usr/bin/env perl

use lib 't/lib';
use Test::Server;
use Test::More tests => 23;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Client';
    use_ok 'Device::Modbus::Server';
    use_ok 'Device::Modbus::ADU';
    use_ok 'Test::Server';
}

{
    my $server = Test::Server->new();
    ok $server->DOES('Device::Modbus::Server'),
        'The server object plays Device::Modbus::Server';

    is_deeply $server->units, {},
        'Units are saved in a hash reference which starts empty';

    eval { $server->add_server_unit('Device::Modbus::Unit', 3) };
    like $@, qr{This method should be subclassed},
        'Units are initialized when added to the server';

    eval { $server->init_server; };
    like $@, qr{Server must be initialized},
        'Initialization method must be subclassed';
}

{
    package My::Unit;
    use Test::More;
    use parent 'Device::Modbus::Unit';

    sub init_unit {
        my $unit = shift;

        #                Zone            addr qty   method
        #           -------------------  ---- ---  ---------
        $unit->put('holding_registers',    2,  1,  'hello');
        $unit->get('holding_registers',    2,  1,  'good_bye');
    }

    sub hello {
        my ($unit, $server, $req, $addr, $qty, $val) = @_;
        isa_ok $unit,      'Device::Modbus::Unit';
        isa_ok $server,    'Device::Modbus::Server';
        isa_ok $req,       'Device::Modbus::Request';
        is $addr,     2,   'Address passed correctly to write routine';
        is $qty,      1,   'Quantity passed correctly to write routine';
        is $val->[0], 565, 'Value passed correctly to write routine';
    }

    sub good_bye {
        my ($unit, $server, $req, $addr, $qty) = @_;
        isa_ok $unit,      'Device::Modbus::Unit';
        isa_ok $server,    'Device::Modbus::Server';
        isa_ok $req,       'Device::Modbus::Request';
        is $addr,  2,      'Address passed correctly to read routine';
        is $qty,   1,      'Quantity passed correctly to read routine';
        return 6;
    }
}

my $server = Test::Server->new();
isa_ok $server, 'Device::Modbus::Server';

my $unit = My::Unit->new(id => 3);
$server->add_server_unit($unit);

{
    my $req = Device::Modbus::Client->write_single_register(
        address => 2,
        value   => 565
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Response';
}
{
    my $req = Device::Modbus::Client->read_holding_registers(
        address  => 2,
        quantity => 1
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Response';
    is_deeply $resp->{values}, [6],
        'Response returned correctly';
}

done_testing();
