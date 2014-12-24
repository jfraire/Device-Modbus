#! /usr/bin/env perl

use Test::More tests => 22;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Server';
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
    my $server = My::Server->new();
    ok $server->does('Device::Modbus::Server'),
        'The server object plays Device::Modbus::Server';

    is_deeply $server->units, {},
        'Units are saved in a hash reference which starts empty';

    $server->add_server_unit('Device::Modbus::Unit', 3);
    isa_ok $server->get_server_unit(3), 'Device::Modbus::Unit';

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
        isa_ok $unit,    'Device::Modbus::Unit';
        ok $server->does('Device::Modbus::Server'), 'Server role implemented';
        isa_ok $req,     'Device::Modbus::Message';
        is $addr,  2, 'Address passed correctly to write routine';
        is $qty,   1, 'Quantity passed correctly to write routine';
        is $val, 565, 'Value passed correctly to write routine';
    }

    sub good_bye {
        my ($unit, $server, $req, $addr, $qty) = @_;
        isa_ok $unit,    'Device::Modbus::Unit';
        ok $server->does('Device::Modbus::Server'), 'Server role implemented';
        isa_ok $req,     'Device::Modbus::Message';
        is $addr,  2, 'Address passed correctly to write routine';
        is $qty,   1, 'Quantity passed correctly to write routine';
        return 6;
    }
}

my $server = My::Server->new();
ok $server->does('Device::Modbus::Server'),
    'The server object plays Device::Modbus::Server';

my $unit = My::Unit->new(id => 3);

$server->add_server_unit($unit);
{
    my $req = Device::Modbus->write_single_register(
        address => 2,
        value   => 565
    );

    my $pdu = $req->pdu();

    my $resp;
    eval { $resp = $server->modbus_server(3, $pdu); };
    ok !$@, 'Running modbus_server survived';

    isa_ok $resp, 'Device::Modbus::Response::WriteSingle';
    # diag $resp;
}
{
    my $req = Device::Modbus->read_holding_registers(
        address  => 2,
        quantity => 1
    );

    my $pdu = $req->pdu();

    my $resp;
    eval { $resp = $server->modbus_server(3, $pdu); };
    ok !$@, 'Running modbus_server survived';

    isa_ok $resp, 'Device::Modbus::Response::ReadRegisters';
    is_deeply $resp->values, [6],
        'Response returned correctly';
    # diag $resp;
}

done_testing();
