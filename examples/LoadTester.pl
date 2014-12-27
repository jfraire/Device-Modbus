#!/usr/bin/perl

=head1 NAME

LoadTester.pl - Allow for testing load agains various servers

=head1 SYNOPIS

    # start - or find a server somewhere

    perl -e 'use base qw(Net::Server::PreForkSimple); __PACKAGE__->run'


    # change parameters in sub configure_hook
    # setup the load to test against the server in sub load

    # run this script

    LoadTester.pl

=cut

use Device::Modbus;
use Device::Modbus::Client::TCP;
use IO::Socket;
use strict;
use warnings;
use base qw(Net::Server::PreFork);
BEGIN {
    Time::HiRes->import('time') if eval { require Time::HiRes };
}

$| = 1;
__PACKAGE__->run(
    min_servers       => 25,
    max_servers       => 35,
    max_spare_servers => 10,
    min_spare_servers => 5,
);
exit;

###----------------------------------------------------------------###

### set up the test parameters
sub configure_hook {
    my $self = shift;
    $self->{'addr'}        = 'localhost';   # choose a remote addr
    $self->{'port'}        = 502;           # choose a remote port
    $self->{'file'}        = '/tmp/mysock'; # sock file for Load testing a unix socket
    $self->{'failed'}      = 0;             # failed hits (server was blocked)
    $self->{'hits'}        = 0;             # log hits
    $self->{'hits2'}       = 0;             # log hits
    $self->{'report_hits'} = 1000;          # how many hits in between reports
    $self->{'max_hits'}    = 20_000;        # how many impressions to do
    $self->{'time_begin'}  = time;          # keep track of time
    $self->{'time_begin2'} = time;          # keep track of time
    $self->{'sleep'}       = 0;             # sleep between hits?
    $self->{'ssl'}         = 0;             # use SSL ?
}


### these generally deal with sockets - ignore them
sub pre_bind { require IO::Socket::SSL if shift->{'ssl'} }
sub bind { shift()->log(2, "Running under pid $$") }
sub accept { 1 }
sub post_accept {}
sub get_client_info {}
sub allow_deny { 1 }
sub post_process_request {}


sub process_request {
    my $self = shift;
    sleep $self->{'sleep'} if $self->{'sleep'};

    ### try to connect and deliver the load
    $self->{modbus} = Device::Modbus::Client::TCP->new(
        host    => $self->{addr},
        port    => $self->{port},
        timeout => 0.5,
    );
    $self->{'remote'} = $self->{modbus}->socket;
    if (defined $self->{remote}) {
        $self->load;
        undef $self->{modbus};
        return;
    }

    #if ($self->{remote} = IO::Socket::UNIX->new(Peer => $self->{'file'})) {
    #  $self->load;
    #  return;
    #}

    print { $self->{'server'}->{'_WRITE'} } "$$ failed [$!]\n";
}


sub load {
    my $self = shift;
    my $client = $self->{'modbus'};
    my $req = Device::Modbus->read_holding_registers(
        unit     => 1,
        address  => 0,
        quantity => 3
    );
    my $trn = $client->request_transaction($req);
    my $r   = $client->send_request($trn);
    print { $self->{'server'}->{'_WRITE'} } "$$ failed [$!]\n"
        unless $r;
}


sub parent_read_hook {
    my ($self, $status) = @_;

    if ($status =~ /failed/i) {
        $self->{'failed'}++;
        print $status;
        if ($self->{'failed'} >= 300) {
            $self->{'time_end'} = time;
            $self->print_report;
            $self->server_close;
        }
        return 1;
    }
    return if $status !~ /processing/i;

    $self->{'hits'}++;
    $self->{'hits2'}++;
    print "*" if not $self->{'hits'} % 100;
    if (not $self->{'hits'} % $self->{'report_hits'}) {
        $self->{'time_end'} = time;
        $self->print_report;
        $self->{'hits2'} = 0;
        $self->{'time_begin2'} = time;
    }

    $self->server_close if $self->{'hits'} >= $self->{'max_hits'};
}


sub print_report {
    my $self = shift;
    my $time  = $self->{'time_end'} - $self->{'time_begin'};
    my $time2 = $self->{'time_end'} - $self->{'time_begin2'};

    print "\n$0 Results\n";
    print "--------------------------------------------\n";
    printf "(%d) overall hits in (%.3f) seconds: %.3f hits per second\n", $self->{'hits'}, $time, ($time ? $self->{'hits'}/$time : $self->{'hits'});
    printf "(%d) hits in (%.3f) seconds: %.3f hits per second\n", $self->{'hits2'}, $time2, ($time2 ? $self->{'hits2'}/$time2 : $self->{'hits2'});
    print "($self->{failed}) failed hits\n";
}
