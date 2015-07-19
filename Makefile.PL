use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME              => 'Device::Modbus',
    VERSION_FROM      => 'lib/Device/Modbus.pm',
    PREREQ_PM         => {
		'Net::Server'        => 2.008,
		'Device::SerialPort' => 1.04,
	},
	BUILD_REQUIRES    => {
		'Test::More'               => 0.98,
		'Test::Device::SerialPort' => 0.0501,
	},
    ABSTRACT_FROM     => 'lib/Device/Modbus.pm',
    AUTHOR            => 'Julio Fraire <julio.fraire@gmail.com>',
    META_MERGE        => {
		'meta-spec' => {
			version	=> 2,
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/jfraire/Device-Modbus.git',
				web  => 'https://github.com/jfraire/Device-Modbus',
			},
		},
	},
);
