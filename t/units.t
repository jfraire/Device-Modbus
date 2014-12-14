use Test::More;
use strict;
use warnings;

use Data::Dumper;

BEGIN { use_ok 'Device::Modbus::Unit' }

my $unit = Device::Modbus::Unit->new(id => 3);

isa_ok $unit, 'Device::Modbus::Unit';
is  $unit->id, 3,
    'Unit created successfully and ID is correct';

is_deeply $unit->addresses, {},
    'Addresses will be stored in a hash reference';

#                Zone            addr qty    method
#           -------------------  ---- --- -----------------
$unit->get('holding_registers',   3,   5,  sub { return 6 });

ok $unit->test('holding_registers', 'Read', 3, 5),
    'Unit now has an address for reading';

is ref $unit->get_address('holding_registers', 3, 5), 'CODE',
    "The 'get' routine of the requested address is there";

is $unit->get_address('holding_registers', 3, 5)->(), 6,
    "Executing 'get' routines works fine";



#                Zone            addr qty    method
#           -------------------  ---- ---  -----------------
$unit->put('holding_registers',    3,  5,  sub { return 19 });

ok $unit->test('holding_registers', 'Write', 3, 5),
    'Unit now has an address for writting';

is ref $unit->put_address('holding_registers', 3, 5), 'CODE',
    "The 'put' routine of the requested address is there";

is $unit->put_address('holding_registers', 3, 5)->(), 19,
    "Executing 'put' routines works fine";

done_testing();
