package Device::Modbus::Spy;

use Device::Modbus;
use Device::Modbus::Exception;
use Carp;
use Moo;

with 'Device::Modbus::RTU';

sub start {
    my $self = shift;

    my $is_request = 1;
    while (1) {
        my $message = $self->read_port;
        next unless $message;

        ### Break message
        my ($unit, $pdu, $footer) = $self->break_message($message);
        print "Unit: [$unit]\n";
        print "PDU:  [".join('-', map { unpack 'H*' } split //, $pdu)."]\n";
        print "CDC:  [".join('-', map { unpack 'H*' } split //, $footer)."]\n";

        ### Parse message
        my $function_code = unpack 'C', $pdu;

        # There should be a request and then a response, but which is which?
        # Requests to write single registers and coils are the same
        # as their responses

        # Reading functions. Requests are 5 bytes always, and responses
        # only some times...
        $is_request = 0 if ($function_code <= 4 && length($pdu) != 5);

        # Write multiple coils or register responses are always 5 bytes
        $is_request = 0 if (($function_code == 15 || $function_code == 16)
            && length($pdu) == 5);

        # Read/Write responses have the length of the PDU in its 2nd byte
        if ($function_code == 23) {
            my $bytes = unpack 'C', substr $pdu, 1, 1;
            $is_request = 0 if length($pdu) == 2+$bytes;
        }

        # What if it is an exception?
        if ($function_code > 0x80) {
            my $exc = Device::Modbus->parse_exception($pdu);
            print "*** (!) $exc\n";
        }
        else {
            # Parse the message twice anyway
            my $req  = Device::Modbus->parse_request($pdu);
            my $resp = Device::Modbus->parse_response($pdu);

            if (defined $req && $is_request) {
                print "--> $req\n";
            }
            elsif (defined $resp && !$is_request) {
                print "<-- $resp\n";
            }
            elsif (defined $req) {
                # Response was not parsed correctly even though we expected
                # a response
                $is_request = 1;
                print "--> (!) $req\n";
            }
            elsif (defined $resp) {
                # Request was not parsed correctly even though we expected
                # a request
                $is_request = 0;
                print "<-- (!) $resp\n";
            }
            else {
                print "*** (!) Unable to parse PDU\n";
            }
        }

        # Toggle $is_request
        $is_request = $is_request ? 0 : 1;
        print "\n";
    }
}

1;
