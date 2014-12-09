use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME              => 'Device::Modbus',
    VERSION_FROM      => 'lib/Device/Modbus.pm',
    PREREQ_PM         => {
		Moo         => 1.006,
		Net::Daemon => 0.48
	},
    ABSTRACT_FROM     => 'lib/Device/Modbus.pm',
    AUTHOR            => 'Julio Fraire <julio.fraire@gmail.com>',
    META_MERGE        => {
		'meta-spec'   => {
			version => 2,
		},
		resources     => {
			repository => {
				type => 'git',
				url  => 'https://github.com/jfraire/Device-Modbus.git',
				web  => 'https://github.com/jfraire/Device-Modbus',
			},
		},
	},
);
