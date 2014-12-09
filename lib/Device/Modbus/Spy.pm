package Device::Modbus::Spy;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use Moo;

with 'Device::Modbus::RTU';

has unit        => (is => 'rwp');
has pdu         => (is => 'rwp');
has cdc         => (is => 'rwp');
has function    => (is => 'rwp');
has message     => (is => 'rwp');
has old_msg     => (is => 'rw', default => sub { return { unit => 0, fcn => 0 } });
has is_request  => (is => 'rw', default => sub { 1 });

sub watch_port {
    my $self = shift;

    my $message;
    while (1) {
        $message = $self->read_port;
        last if $message;
    }
    
    ### Break message
    my ($unit, $pdu, $footer) = $self->break_message($message);

    ### Parse message
    my $function_code = unpack 'C', $pdu;

    my %this_msg = ( unit => $unit, fcn => $function_code );

    # There should be a request and then a response, but which is which?

    # It is a request if unit and function are different than the last message
    if ($this_msg{unit} != $self->old_msg->{unit} || $this_msg{fcn} != $self->old_msg->{fcn}) {
        $self->is_request(1);
    }
    else {

        # Reading functions. Requests are 5 bytes always, and responses
        # only some times...

        $self->is_request(0) if ($function_code <= 4 && length($pdu) != 5);

        # Write multiple coils or register responses are always 5 bytes
        if (($function_code == 15 || $function_code == 16) && length($pdu) != 5) { 
            $self->is_request(1);
        }

        # Read/Write responses have the length of the PDU in its 2nd byte
        if ($function_code == 23) {
            my $bytes = unpack 'C', substr $pdu, 1, 1;
            $self->is_request(0) if length($pdu) == 2 + $bytes;
        }
    }

    my $msg;

    # What if it is an exception?
    if ($function_code > 0x80) {
        my $exc = Device::Modbus->parse_exception($pdu);
        $msg = "*** (!) $exc";
    }
    else {
        # Parse the message twice anyway
        my $req  = Device::Modbus->parse_request($pdu);
        my $resp = Device::Modbus->parse_response($pdu);

        if (defined $req && $self->is_request) {
            $msg = "--> $req";
        }
        elsif (defined $resp && !$self->is_request) {
            $msg = "<-- $resp";
        }
        elsif (defined $req) {
            # Response was not parsed correctly even though we expected
            # a response
            $self->is_request(1);
            $msg = "--> (!) $req";
        }
        elsif (defined $resp) {
            # Request was not parsed correctly even though we expected
            # a request
            $self->is_request(0);
            $msg = "<-- (!) $resp";
        }
        else {
            $msg = "*** (!) Unable to parse PDU";
        }
    }

    $self->_set_message($msg);
    $self->_set_function($function_code);
    $self->_set_unit("Unit: [$unit]");
    $self->_set_pdu("PDU:  [".join('-', map { unpack 'H*' } split //, $pdu)."]");
    $self->_set_cdc("CDC:  [".join('-', map { unpack 'H*' } split //, $footer)."]");

    # Toggle $is_request
    $self->is_request($self->is_request ? 0 : 1);
    $self->old_msg({%this_msg});

    return $self;
}

1;
