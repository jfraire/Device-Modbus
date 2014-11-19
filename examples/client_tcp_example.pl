#! /usr/bin/perl

use Device::Modbus::Request;
use Device::Modbus::Client::TCP;
use Data::Dumper;
use Modern::Perl;

my $client = Device::Modbus::Client::TCP->new( unit => 1 );
my $req    = Device::Modbus::Request->read_holding_registers(
    address  => 122,
    quantity => 6
);

my $trn = $client->request_transaction($req);
$client->send_request($trn) || die "Maldición: no pude escribir $!";
$client->receive_response;

if (ref $trn->response eq 'Device::Modbus::Exception') {
    say Dumper $trn->response;
}
else {
    say "Values: ", join '-', @{$trn->response->values};
}
$client->close;
