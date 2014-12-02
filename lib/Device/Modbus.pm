package Device::Modbus;

use strict;
use warnings;

our $VERSION = '0.01';

use Device::Modbus::Message;
use Device::Modbus::Request::Read;
use Device::Modbus::Request::WriteSingle;
use Device::Modbus::Request::WriteMultiple;
use Device::Modbus::Request::ReadWrite;
use Device::Modbus::Response::ReadDiscrete;
use Device::Modbus::Response::ReadRegisters;
use Device::Modbus::Response::WriteSingle;
use Device::Modbus::Response::WriteMultiple;
use Device::Modbus::Response::ReadWrite;

#############################################################
# Message building
#############################################################

### Request builders

sub read_coils {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Coils',
        @_
    );
    return $req;
}

sub read_discrete_inputs {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Discrete Inputs',
        @_
    );
    return $req;
}

sub read_input_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Input Registers',
        @_
    );
    return $req;
}

sub read_holding_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::Read->new(
        function => 'Read Holding Registers',
        @_
    );
    return $req;
}

sub write_single_coil {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteSingle->new(
        function => 'Write Single Coil',
        @_
    );
    return $req;
}

sub write_single_register {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteSingle->new(
        function => 'Write Single Register',
        @_
    );
    return $req;
}

sub write_multiple_coils {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteMultiple->new(
        function => 'Write Multiple Coils',
        @_
    );
    return $req;
}

sub write_multiple_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::WriteMultiple->new(
        function => 'Write Multiple Registers',
        @_
    );
    return $req;
}

sub read_write_registers {
    my $class = shift;
    my $req   = Device::Modbus::Request::ReadWrite->new(
        function => 'Read/Write Multiple Registers',
        @_
    );
    return $req;
}

### Response builders

sub coils_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadDiscrete->new(
        function => 'Read Coils',
        @_
    );
    return $res;
}

sub discrete_inputs_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadDiscrete->new(
        function => 'Read Discrete Inputs',
        @_
    );
    return $res;
}

sub holding_registers_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadRegisters->new(
        function => 'Read Holding Registers',
        @_
    );
    return $res;
}

sub input_registers_read {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadRegisters->new(
        function => 'Read Input Registers',
        @_
    );
    return $res;
}

sub single_coil_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteSingle->new(
        function => 'Write Single Coil',
        @_
    );
    return $res;
}

sub single_register_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteSingle->new(
        function => 'Write Single Register',
        @_
    );
    return $res;
}

sub multiple_coils_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteMultiple->new(
        function => 'Write Multiple Coils',
        @_
    );
    return $res;
}

sub multiple_registers_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::WriteMultiple->new(
        function => 'Write Multiple Registers',
        @_
    );
    return $res;
}

sub registers_read_write {
    my $class = shift;
    my $res   = Device::Modbus::Response::ReadWrite->new(
        function => 'Read/Write Multiple Registers',
        @_
    );
    return $res;
}

#############################################################
# Message parsing
#############################################################

### Request parsing

sub parse_request {
    my ($class, $binary_req) = @_;

    my $request;
    my $function_code = unpack 'C', $binary_req;
    my $function = Device::Modbus::Message->function_for($function_code);

    if ($function_code > 0 && $function_code <= 4) {
        $request = Device::Modbus::Request::Read->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 5 || $function_code == 6) {
        $request = Device::Modbus::Request::WriteSingle->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x0f || $function_code == 0x10) {
        $request = Device::Modbus::Request::WriteMultiple->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x17) {
        $request = Device::Modbus::Request::ReadWrite->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    else {
        return $function_code;
    }

    return $request;
}

### Response parsing

sub parse_response {
    my ($class, $binary_req) = @_;

    my $response;
    my $function_code = unpack 'C', $binary_req;
    my $function = Device::Modbus::Message->function_for($function_code);

    if ($function_code == 0x01 || $function_code == 0x02) {
        $response = Device::Modbus::Response::ReadDiscrete->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x03 || $function_code == 0x04) {
        $response = Device::Modbus::Response::ReadRegisters->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x05 || $function_code == 0x06) {
        $response = Device::Modbus::Response::WriteSingle->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x0f || $function_code == 0x10) {
        $response = Device::Modbus::Response::WriteMultiple->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    elsif ($function_code == 0x17) {
        $response = Device::Modbus::Response::ReadWrite->parse_message(
            function => $function,
            message  => $binary_req,
        );
    }
    else {
        return $function_code;
    }

    return $response;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::Modbus - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Device::Modbus;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Device::Modbus, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Julio Fraire, E<lt>julio@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
