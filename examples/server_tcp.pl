#! /usr/bin/env perl

package Test::Modbus::Server;

use Device::Modbus;
use parent 'Device::Modbus::Server::TCP';
use Modern::Perl;

my %memory = (
    discrete_inputs   => [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1],
    discrete_outputs  => [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0],
    input_registers   => [200,201,202,203,204,205,206,207,208,209],
    holding_registers => [100,101,102,103,104,105,106,107,108,109],
);

sub init_server {
    my $server = shift;

    $server->add_server_unit(1);
    
    $server->limits_discrete_inputs(1,1,16);
    $server->limits_discrete_outputs(1,1,16);
    $server->limits_input_registers(1,1,10);
    $server->limits_holding_registers(1,1,10);
}

sub process_request {
    my ($server, $unit, $req) = @_;
    my $resp;

    # Process write requests first
    if (ref $req eq 'Device::Modbus::Request::WriteSingle') {
        my $addr  = $req->address;
        my $value = $req->value;
        my $mem_model;
        given ($req->function) {
            when ('Write Single Coil') {
                $mem_model = 'discrete_outputs';
            }
            when ('Write Single Register') {
                $mem_model = 'holding_registers';
            }
        }
        $memory{holding_registers}->{$addr-1} = $value;

        $resp = Device::Modbus::Response::WriteSingle->new(
            function => $req->function,
            address  => $addr,
            value    => $value
        );
    }

    if (ref $req eq 'Device::Modbus::Request::WriteMultiple') {
        my $addr   = $req->address;
        my $values = $req->values;
        my $qty    = $req->quantity;
        my $mem_model;
        given ($req->function) {
            when ('Write Multiple Coils') {
                $mem_model = 'discrete_outputs';
            }
            when ('Write Multiple Registers') {
                $mem_model = 'holding_registers';
            }
        }
        splice @{$memory{$mem_model}}, $addr-1, $qty, @$values;

        $resp = Device::Modbus::Response::WriteMultiple->new(
            function => $req->function,
            address  => $addr,
            quantity => $qty
        );
    }

    if (ref $req eq 'Device::Modbus::Request::ReadWrite') {
        my $addr   = $req->write_address;
        my $values = $req->values;
        my $qty    = $req->write_quantity;
        splice @{$memory{holding_registers}}, $addr-1, $qty, @$values;
    }

    # Process read requests
    if (ref $req eq 'Device::Modbus::Request::Read') {
        my $addr = $req->address;
        my $qty  = $req->quantity;
        my ($mem, $class);

        given ($req->function) {
            when ('Read Coils') {
                $mem   = 'discrete_coils';
                $class = 'Device::Modbus::Response::ReadDiscrete';
            }
            when ('Read Discrete Inputs') {
                $mem   = 'discrete_inputs'; 
                $class = 'Device::Modbus::Response::ReadDiscrete';
            }
            when ('Read Input Registers') {
                $mem   = 'input_registers'; 
                $class = 'Device::Modbus::Response::ReadRegisters';
            }
            when ('Read Holding Registers') {
                $mem   = 'holding_registers'; 
                $class = 'Device::Modbus::Response::ReadRegisters';
            }
        }

        my @vals = @{ $memory{$mem} }[$addr-1..$addr+$qty-2];

        $resp = $class->new(
            function => $req->function,
            values   => \@vals
        );
    }

    return $resp;
}

package main;

my $server = Test::Modbus::Server->new;
$server->Bind;
       
