use Test::More tests => 15;
use strict;
use warnings;

use Data::Dumper;

BEGIN { use_ok 'Device::Modbus::Unit' }

{

    my $unit = Device::Modbus::Unit->new(id => 3);

    isa_ok $unit, 'Device::Modbus::Unit';
    is  $unit->id, 3,
        'Unit created successfully and ID is correct';

    is ref $unit->addresses->{'holding_registers:read'}, 'ARRAY',
        'Addresses will be stored in a hash of array refs';
    is scalar @{$unit->addresses->{'holding_registers:read'}}, 0,
        'The arrays start empty';

    #                Zone           addr  qty    method
    #           ------------------- ----- --- -----------------
    $unit->get('holding_registers', '1-5', 5,  sub { return 6 });

    is scalar @{$unit->addresses->{'holding_registers:read'}}, 1,
        'Added an address to the holding_registers:read array';

    my $match = $unit->route('holding_registers', 'read', 3, 5);

    isa_ok $match, 'Device::Modbus::Unit::Address',
        'Routing mechanism works';

    is $match->routine->(), 6,
        "Executing 'get' routine works fine";
    undef $match;

    #                Zone            addr  qty    method
    #           -------------------  ---- -----  -----------------
    $unit->put('holding_registers',   33, '1,3',  sub { return 19 });

    is scalar @{$unit->addresses->{'holding_registers:write'}}, 1,
        'Added an address to the holding_registers:write array';

    $match = $unit->route('holding_registers', 'write', 33, 3);

    isa_ok $match, 'Device::Modbus::Unit::Address',
        'Routing mechanism works';

    is $match->routine->(), 19,
        "Executing 'put' routine works fine";
}

{
    package Hello;

    use Moo;
    extends 'Device::Modbus::Unit';

    sub hello {
        return 'Dolly';
    }

    sub good_bye {
        return 'Adieu';
    }
}

my $unit = Hello->new(id => 4);

#                Zone            addr qty   method
#           -------------------  ---- ---  ---------
$unit->put('holding_registers',    2,  1,  'hello');
$unit->get('holding_registers',    6,  1,  'good_bye');

my $match = $unit->route('holding_registers','write', 2,1);
isa_ok $match, 'Device::Modbus::Unit::Address';

is $match->routine->(), 'Dolly',
    'Named methods can be entered into the dispatch table -- put';

$match = $unit->route('holding_registers','read', 6, 1);
isa_ok $match, 'Device::Modbus::Unit::Address';

is $match->routine->(), 'Adieu',
    'Named methods can be entered into the dispatch table -- get';

done_testing();
