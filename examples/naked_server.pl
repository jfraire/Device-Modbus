#! -*- perl -*-

# This program is based on the example shown in Net::Daemon
# documentation, by Malcolm H. Nooning

use Net::Daemon;
use Modern::Perl;

package NakedModbus;

use Device::Modbus::Response;
use Device::Modbus::Request;
use Device::Modbus::Transaction::TCP;

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
        next;
    }
    $self->Log('notice', "Received message from " . $sock->peerhost);

    # Issue a new transaction
    my ($trn_id, $unit, $pdu) = $self->break_request($msg);
    if (!defined $trn_id) {
        $self->Error('Request error');
        next;
    }

    my $req = Device::Modbus::Request->parse_request($pdu);
    my $trn = Device::Modbus::Transaction::TCP->new(
        id      => $trn_id,
        unit    => $unit,
        request => $req,
        timeout => 3,
    );
    
    if (ref $req eq 'Device::Modbus::Exception') {
        # Send response... which is actually saved as request
        $sock->send($trn->build_request_apu);
        $self->Log('notice', "Request was not parsed successfully");
    }
    
    # Real work goes here.
    $self->Log('notice', "Received a " . $req->function . " request");
    
    # It will simply respond to read holding registers requests
    if ($req->function eq 'Read Holding Registers') {
        my $res = Device::Modbus::Response->holding_registers_read(
            values => [72,111,108,97,32,99]
        );
        $trn->response($res);
        $sock->send($trn->build_response_apu);
    }
}

sub break_request {
    my ($self, $message) = @_;
    my ($id, $proto, $length, $unit) = unpack 'nnnC', $message;
    my $pdu = substr $message, 7;
    return if length($pdu) != $length-1; 
    return $id, $unit, $pdu;
}
 
package main;
 
my $server = NakedModbus->new(
    {localport => 502, pidfile => 'none', logfile => 'STDERR'},
    \@ARGV
);
$server->Bind();
