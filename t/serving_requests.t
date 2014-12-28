#! /usr/bin/env perl

use Test::More tests => 30;
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
        $unit->put('discrete_coils',    '*', '*', 'dc_write');
        $unit->get('discrete_coils',    '*', '*', 'dc_read' );

        $unit->get('discrete_inputs',   '*', '*', 'di_read' );

        $unit->get('input_registers',   '*', '*', 'ir_read' );

        $unit->put('holding_registers', '*', '*', 'hr_write');
        $unit->get('holding_registers', '*', '*', 'hr_read' );
    }

    sub dc_write {
        my ($unit, $server, $req, $addr, $qty, $val) = @_;
        $val = join '', @$val if ref $val;
        push @{$unit->last_command}, (join ':', 'Write coils', $addr, $qty, $val);
    }

    sub dc_read {
        my ($unit, $server, $req, $addr, $qty) = @_;
        push @{$unit->last_command}, (join ':', 'Read coils', $addr, $qty);
        return (1) x $qty;
    }

    sub di_read {
        my ($unit, $server, $req, $addr, $qty) = @_;
        push @{$unit->last_command}, (join ':', 'Read discrete inputs', $addr, $qty);
        return (1) x $qty;
    }

    sub ir_read {
        my ($unit, $server, $req, $addr, $qty) = @_;
        push @{$unit->last_command}, (join ':', 'Read input registers', $addr, $qty);
        return (1) x $qty;
    }

    sub hr_read {
        my ($unit, $server, $req, $addr, $qty) = @_;
        push @{$unit->last_command}, (join ':', 'Read holding registers', $addr, $qty);
        return (1) x $qty;
    }

    sub hr_write {
        my ($unit, $server, $req, $addr, $qty, $val) = @_;
        $val = join '', @$val if ref $val;
        push @{$unit->last_command}, (join ':', 'Write holding registers', $addr, $qty, $val);
    }
}

my $server = My::Server->new;
ok $server->does('Device::Modbus::Server'),
    'The server object plays role Device::Modbus::Server';

my $unit = $server->add_server_unit('My::Unit', 3);
isa_ok $unit, 'My::Unit';

{
    my $request = Device::Modbus->read_coils(
        address  => 19,
        quantity => 4
    );
    
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Response::ReadDiscrete';
    note $resp;
    
    is shift @{$unit->last_command}, 'Read coils:19:4',
        'Read Coils server routine executed as expected';

    is_deeply $resp->values, [1,1,1,1],
        'Read Coils request served as expected';
}
{
    my $request = Device::Modbus->write_single_coil(
        address  => 19,
        value    => 1
    );
    
    my $resp = $server->modbus_server(3, $request);
    note $resp;

    isa_ok $resp, 'Device::Modbus::Response::WriteSingle';
    
    is shift @{$unit->last_command}, 'Write coils:19:1:1',
        'Write Single Coil server routine executed as expected';
}
{
    my $request = Device::Modbus->write_multiple_coils(
        address  => 23,
        values   => [1,0,1]
    );
    
    my $resp = $server->modbus_server(3, $request);
    note $resp;

    isa_ok $resp, 'Device::Modbus::Response::WriteMultiple';
    
    is shift @{$unit->last_command}, 'Write coils:23:3:101',
        'Write Single Coil server routine executed as expected';
}
{
    my $request = Device::Modbus->read_discrete_inputs(
        address  => 4,
        quantity => 3
    );
    
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Response::ReadDiscrete';
    note $resp;
    
    is shift @{$unit->last_command}, 'Read discrete inputs:4:3',
        'Read Discrete Inputs server routine executed as expected';

    is_deeply $resp->values, [1,1,1],
        'Read Discrete Inputs request served as expected';
}
{
    my $request = Device::Modbus->read_input_registers(
        address  => 44,
        quantity => 2
    );
    
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Response::ReadRegisters';
    note $resp;
    
    is shift @{$unit->last_command}, 'Read input registers:44:2',
        'Read Input Registers server routine executed as expected';

    is_deeply $resp->values, [1,1],
        'Read Input Registers request served as expected';
}
{
    my $request = Device::Modbus->read_holding_registers(
        address  => 14,
        quantity => 6
    );
    
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Response::ReadRegisters';
    note $resp;
    
    is shift @{$unit->last_command}, 'Read holding registers:14:6',
        'Read Holding Registers server routine executed as expected';

    is_deeply $resp->values, [1,1,1,1,1,1],
        'Read Holding Registers request served as expected';
}
{
    my $request = Device::Modbus->write_single_register(
        address  => 10,
        value    => 426
    );
    
    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Response::WriteSingle';
    note $resp;
    
    is shift @{$unit->last_command}, 'Write holding registers:10:1:426',
        'Write Holding Registers server routine executed as expected';
}
{
    my $request = Device::Modbus->write_multiple_registers(
        address => 31,
        values  => [66,22,77]
    );    

    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Response::WriteMultiple';
    note $resp;
    
    is shift @{$unit->last_command}, 'Write holding registers:31:3:662277',
        'Write Multiple Registers server routine executed as expected';
}
{
    my $request = Device::Modbus->read_write_registers(
        read_address  => 11,
        read_quantity =>  3,
        write_address =>  9,
        values        => [62,27,76]
    );

    my $resp = $server->modbus_server(3, $request);

    isa_ok $resp, 'Device::Modbus::Response::ReadWrite';
    note $resp;
    
    is shift @{$unit->last_command}, 'Write holding registers:9:3:622776',
        'Read/Write Registers server routine executed as expected (writing)';
    is_deeply $resp->values, [1,1,1],
        'Read/Write Registers request served as expected';
    is shift @{$unit->last_command}, 'Read holding registers:11:3',
        'Read/Write Registers server routine executed as expected (reading)';
}


done_testing();
