package Test::OtherUnit;

use Test::More;
use parent 'Device::Modbus::Unit';
use strict;
use warnings;

sub init_unit {
    my $unit = shift;

    #------r/w--Zone-------------------Adr-----Qty---Action---------
    $unit->get('discrete_coils',        19,    19,  'read_coils'    );
    $unit->put('discrete_coils',        19,   '*',  'write_coils'   );

    $unit->get('discrete_inputs',      196,     3,  'read_discrete' );
    $unit->get('input_registers',        8,     3,  'read_input'    );

    $unit->get('holding_registers', '3,10', '2,6',  'read_holding'  );
    $unit->put('holding_registers', '1,14', '1-3',  'write_holding' );
}

sub read_coils {
    my ($unit, $server, $req, $addr, $qty) = @_;
    is $req->function, 'Read Coils',
        'Received the Read Coils request';
    return (1) x 19;
}

sub write_coils {
    my ($unit, $server, $req, $addr, $qty, $val) = @_;
    if ($qty == 1) {
        is $req->function, 'Write Single Coil',
            'Received the Write Single Coil request';
    }
    else {
        is $qty, 10,
            'Received the Write Multiple Coils request';
    }
}

sub read_discrete {
    ok 1, 'Received Read Discrete Inputs request';
    return (1,1,1);
}

sub read_input {
    ok 1, 'Received Read Input Registers request';
    return (1,2,3);
}

sub read_holding {
    my ($unit, $server, $req, $addr, $qty) = @_;
    if ($addr == 10 && $qty == 2) {
        ok 1, 'Received Read Holding Registers request';
        return (1,2);
    }
    elsif ($addr == 3 && $qty == 6) {
        ok 1, 'Received Read/Write Registers request';
        return (1,2,3,4,5,6);
    }
}

sub write_holding {
    my ($unit, $server, $req, $addr, $qty, $val) = @_;
    if ($addr == 10 && $qty == 2) {
        ok 1, 'Received Read Holding Registers request';
        return (1,2);
    }
    elsif ($addr == 3 && $qty == 6) {
        ok 1, 'Received Read/Write Registers request';
        return (1,2,3,4,5,6);
    }
}

1;
