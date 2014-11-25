#! /usr/bin/env perl

# This program is based on the example shown in Net::Daemon
# documentation, by Malcolm H. Nooning


use Net::Daemon;
use Modern::Perl;

package NakedModbus;

use Data::Dumper;
use Device::Modbus;
use Device::Modbus::Exception;
use Device::Modbus::TCP;
use Device::Modbus::Transaction;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(Net::Daemon); # to inherit from Net::Daemon

sub Version { 'Modbus Naked Server 0.01'; }
 
sub Run {
    my $self = shift;
    my $sock = $self->{'socket'};

    # Read request
    my $msg;
    my $rc = $sock->recv($msg, 260);
    unless (defined $rc) {
        $self->Error('Communication error');
        return;
    }
    $self->Log('notice', 'Received message from ' . $sock->peerhost);

    # Parse request and issue a new transaction
    my ($trn_id, $unit, $pdu) = Device::Modbus::TCP->break_message($msg);
    if (!defined $trn_id) {
        $self->Error('Request error');
        return;
    }

    my $trn = Device::Modbus::Transaction->new(
        id      => $trn_id,
        unit    => $unit
    );

    my $req = Device::Modbus->parse_request($pdu);
    
    # Treat unimplemented functions -- return exception 1
    # (exception is saved in request object)
    if (!ref $req) {
        my $exception = Device::Modbus::Exception->new(
            function       => $req,    # Function requested
            exception_code => 1        # Unimplemented function
        );
            
        $sock->send(Device::Modbus::TCP->build_apu($trn, $exception->pdu));
        $self->Log('notice',
            "Function unimplemented: $req in transaction $trn_id"
            . ' from '
            . $sock->peerhost);
        return;
    }

    
    # Real work goes here.
    $self->Log('notice', "Received a " . $req->function
        . " request (transaction $trn_id)");

    $trn->request($req);
    my $response;
    my $exception;

    eval { $response = $self->run_app($trn) };

    if (defined $response && !$@) {
        return $sock->send(Device::Modbus::TCP->build_apu($trn, $response->pdu));
    }
    else {
        my $err_msg =
              "Client:      " . $sock->peerhost
            . "Unit:        " . $trn->unit
            . "Transaction: " . $trn->id
            . "Function:    " . $trn->request->function
            ;
        if ($@) {
            $self->Error("Application crashed: $@\n" . $err_msg);
        }
        elsif (!defined $response) {
            $self->Error("Application did not return a response: $@\n"
                . $err_msg);
        }
    
        $exception = Device::Modbus::Exception->new(
            function_code  => $trn->request->function_code,
            exception_code => 0x04
        );
    }

    $sock->send(Device::Modbus::TCP->build_apu($trn, $exception->pdu));
}

sub run_app {
    my ($server, $trn) = @_;
    say Dumper $trn;
    my $res = Device::Modbus->holding_registers_read(
        values  => [1,2,3,4,5,6]        
    );
    return $res;
}
 
package main;
 
my $server = NakedModbus->new(
    {localport => 502, pidfile => 'none', logfile => 'STDERR'},
    \@ARGV
);
$server->Bind();
