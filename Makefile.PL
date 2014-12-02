use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME              => 'Device::Modbus',
    VERSION_FROM      => 'lib/Device/Modbus.pm',
    PREREQ_PM         => { Moo => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Modbus.pm',
       AUTHOR         => 'Julio Fraire <julio.fraire@gmail.com>') : ()),
);
