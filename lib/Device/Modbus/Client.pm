package Device::Modbus::Client;

use Device::Modbus;
use Device::Modbus::Request;
use Device::Modbus::Response;
use Device::Modbus::Exception;

use Carp;
use strict;
use warnings;

### Request building

sub read_coils {
    my ($self, %args) = @_;
    $args{function}   = 'Read Coils';
    validate_discrete_reads(%args);
    return Device::Modbus::Request->new(%args);    
}

sub read_discrete_inputs {
    my ($self, %args) = @_;
    $args{function}   = 'Read Discrete Inputs';
    validate_discrete_reads(%args);
    return Device::Modbus::Request->new(%args);    
}

sub read_input_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Read Input Registers';
    validate_register_reads(%args);
    return Device::Modbus::Request->new(%args);
}

sub read_holding_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Read Holding Registers';
    validate_register_reads(%args);
    return Device::Modbus::Request->new(%args);    
}

sub write_single_coil {
    my ($self, %args) = @_;
    $args{function}   = 'Write Single Coil';
    return Device::Modbus::Request->new(%args);
}

sub write_single_register {
    my ($self, %args) = @_;
    $args{function}   = 'Write Single Register';
    croak 'Argument value must exist and be defined'
        unless exists $args{value} && defined $args{value};
    croak 'Value of register to write must be between 0 and 65535'
        unless $args{value} >= 0 && $args{value} <= 0xFFFF;
    return Device::Modbus::Request->new(%args);
}

sub write_multiple_coils {
    my ($self, %args) = @_;
    $args{function}   = 'Write Multiple Coils';
    croak 'Argument values (array ref) must exist and be an array ref'
        unless exists $args{values} && ref $args{values} eq 'ARRAY';
    croak 'The values array ref must contain at least one element'
        unless @{$args{values}} >= 1;
    croak 'The values array ref must contain 1968 elements at most'
        unless @{$args{values}} <= 0x7B0;
    return Device::Modbus::Request->new(%args);    
}

sub write_multiple_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Write Multiple Registers';
    croak 'Argument values (array ref) must exist and be an array ref'
        unless exists $args{values} && ref $args{values} eq 'ARRAY';
    croak 'The values array ref must contain at least one element'
        unless @{$args{values}} >= 1;
    croak 'The values array ref must contain 123 elements at most'
        unless @{$args{values}} <= 0x7B;
    return Device::Modbus::Request->new(%args);    
}

sub read_write_registers {
    my ($self, %args) = @_;
    $args{function}   = 'Read/Write Multiple Registers';
    
    croak 'Argument read_quantity is required for read request'
        unless exists $args{read_quantity};
    croak 'Argument read_quantity is not defined for read request'
        unless defined $args{read_quantity};
    croak 'read_quantity must be a number between 1 and 125'
        unless $args{read_quantity} >= 1 && $args{read_quantity} <= 0x7D;
        
    croak 'Argument values (array ref) must exist and be an array ref'
        unless exists $args{values} && ref $args{values} eq 'ARRAY';
    croak 'The values array ref must contain at least one element'
        unless @{$args{values}} >= 1;
    croak 'The values array ref must contain 121 elements at most'
        unless @{$args{values}} <= 0x79;
        
    return Device::Modbus::Request->new(%args);    
}

# Validation routines for read requests
sub validate_discrete_reads {
    my %args = @_;
    croak 'Argument quantity is not defined for read request'
        unless defined $args{quantity};
    croak 'Quantity must be a number between 1 and 2000'
        unless $args{quantity} >= 1 && $args{quantity} <= 2000;    
}

sub validate_register_reads {
    my %args = @_;
    croak 'Argument quantity is required for read request'
        unless exists $args{quantity};
    croak 'Argument quantity is not defined for read request'
        unless defined $args{quantity};
    croak 'Quantity must be a number between 1 and 125'
        unless $args{quantity} >= 1 && $args{quantity} <= 125;
}

### Send request
sub send_request {
    my ($self, $request) = @_;
    my $adu = $self->new_adu($request);
    $self->write_port($adu);
}

### Response parsing    

# Parse the Application Data Unit
sub receive_response {
    my $self = shift;
    $self->read_port;
    my $adu  = $self->new_adu();
    $self->parse_header($adu);
    $self->parse_pdu($adu);
    $self->parse_footer($adu);
    return $adu;
}

sub parse_pdu {
    my ($self, $adu) = @_;
    my $response;
    
    my $code = $self->parse_buffer(1,'C');

    if ($code == 0x01 || $code == 0x02) {
        # Read coils and discrete inputs
        my ($byte_count) = $self->parse_buffer(1, 'C');
        croak "Invalid byte count: <$byte_count>"
            unless $byte_count > 0;

        my @values       = $self->parse_buffer($byte_count, 'C*');
        @values          = Device::Modbus->explode_bit_values(@values);

        $response = Device::Modbus::Response->new(
            code       => $code,
            bytes      => $byte_count,
            values     => \@values
        );
    }
    elsif ($code == 0x03 || $code == 0x04 || $code == 0x17) {
        # Read holding and input registers; read/write registers
        my ($byte_count) = $self->parse_buffer(1, 'C');

        croak "Invalid byte count: <$byte_count>"
            unless $byte_count > 0 && $byte_count <= 250 && $byte_count % 2 == 0;

        my @values       = $self->parse_buffer($byte_count, 'n*');

        $response = Device::Modbus::Response->new(
            code       => $code,
            bytes      => $byte_count,
            values     => \@values
        );
    }
    elsif ($code == 0x05 || $code == 0x06) {
        # Write single coil and single register
        my ($address, $value) = $self->parse_buffer(4, 'n*');

        if ($code == 0x05) {
            $value = 1 if $value;
        }

        $response = Device::Modbus::Response->new(
            code       => $code,
            address    => $address,
            value      => $value
        );
    }
    elsif ($code == 0x0F || $code == 0x10) {
        # Write multiple coils, multiple registers
        my ($address, $qty)   = $self->parse_buffer(4, 'n*');

        $response = Device::Modbus::Response->new(
            code       => $code,
            address    => $address,
            quantity   => $qty
        );
    }
    elsif (grep { $code == $_ } 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x8F, 0x90, 0x97) {
        my ($exc_code) = $self->parse_buffer(1, 'C');
        
        $response = Device::Modbus::Exception->new(
            code           => $code,
            exception_code => $exc_code
        );
    }
    else {
        croak "Unimplemented function: <$code>";
    }

    $adu->message($response);
    return $response;        
}

1;
__END__

=head1 NAME

Device::Modbus::Client - Modbus clients with Device::Modbus

=head1 SYNOPSIS

 my $r = $client->read_coils(
     address  => 23,
     quantity =>  6 );
 
 my $r = $client->read_discrete_inputs(
     address  => 55,
     quantity =>  7 );
 
 my $r = $client->read_holding_registers(
     address  => 1,
     quantity => 16 );

 my $r = $client->read_input_registers(
     address  => 6,
     quantity => 3 );

 my $r = $client->write_single_coil(
     address  => 33,
     value    => 1 );

 my $r = $client->write_single_register(
     address  => 33,
     value    => 3457 );

 my $r = $client->write_multiple_coils(
     address  => 64,
     values   => [1, 1, 0, 1] );

 my $r = $client->write_multiple_registers(
     address  => 64,
     values   => [345, 65, 67, 243] );

 my $r = $client->read_write_registers(
     read_address  => 14,
     read_quantity =>  3,
     write_address => 20,
     values        => [ 45, 87, 1, 298, 0, 0] );

 $client->send_request($r);
 my $adu = $client->receive_response;

 if ($adu->success) {
     $values = $adu->values;
 }

=head1 DESCRIPTION

This class implements Modbus clients. Clients must connect to servers, build requests, send them to the server, and receive their responses.

=head1 CLIENT METHODS

=head2 Requests that fetch information from a remote server

The following methods create request objects. They all receive the same arguments: an address and the quantity of bits or register to read. See the synopsis for examples.

=over

=item read_coils

=item read_discrete_inputs

=item read_holding_registers

=item read_input_registers

=back

=head2 Requests that send information to a remote server

The arguments for these methods are an address and a value or values. Again, see the synopsis:

=over

=item write_single_coil

=item write_single_register

=item write_multiple_coils

=item write_multiple_registers

=back

=head2 Request that reads and writes information from a remote server

This request receives two addresses (read and write), the quantity of records to read, and an array reference with the values to write:

=over

=item read_write_registers

=back

=head2 Other methods

Once you have one or more request objects, it is time to send them to the server:

=head3 send_request

This method receives a request object as its only argument.

=head3 receive_response

Finally, this method will return the response received from the server encapsulated into an ADU (Application Data Unit).

=head1 METHODS OF APPLICATION DATA UNITS

Responses from the server are returned to the client wrapped into an ADU object. The ADU has several methods to inspect the response and retrieve any requested information:

=head2 message

 my $resp = $adu->message;

Returns the actual response object.

=head2 function

 my $resp = $adu->function;

Returns the function name of the request and response objects.

=head2 code

 my $code = $adu->code;

Returns the function code of the request and response objects.

=head2 values

 my $values = $adu->values;

Returns an array reference with the values returned by the server. Valid only for reading requests.

=head2 success

 $val = $adu->values if $adu->success;

Returns a true value if the ADU contains a message and its function code is less than 0x80 (Modbus exception objects have a function code larger than 0x80).

=head1 SEE ALSO

Client methods to actually connect and close the connection to the server are available in L<Device::Modbus::RTU::Client> and L<Device::Modbus::TCP::Client>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

