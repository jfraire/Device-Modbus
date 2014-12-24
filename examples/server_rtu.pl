#! /usr/bin/env perl


package Test::Modbus;

use Device::Modbus;
use parent 'Device::Modbus::Unit';
use strict;
use warnings;

my %mem = (
    discrete_inputs   => [0,1,0,1,0,1],
    input_registers   => [200,201,202],
    holding_registers => [100,101,102],
);

sub init_unit {
    my $unit = shift;

    $unit->get('discrete_inputs',    0, 6, sub { return @{$mem{discrete_inputs}}[0..5];  });
    $unit->get('holding_registers',  0, 3, sub { return @{$mem{holding_registers}}[0..2];});
    $unit->put('holding_registers',  0, 3, 'store_hr');
}

sub store_hr {
    my ($unit, $server, $req, $addr, $qty, $val) = @_;
    splice @{$mem{holding_registers}}, $addr, $qty, @$val;
    return scalar @$val;
}

package main;
use Modbus::Server::RTU;

my $unit   = Test::Modbus->new(id => 1);
my $server = Modbus::Server::RTU->new(
    port => '/dev/ttyUSB0',
    unit => 3
);

$server->add_server_unit($unit);
$server->start;
