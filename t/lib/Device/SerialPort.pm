package Device::SerialPort;

use Moo;

# This is a fake Device::SerialPort class for testing!
# Read and write are set as read/write attributes so that you can
# save their returned values to cheat your tests HE HE He he he...

has port               => (is => 'rw');
has baudrate           => (is => 'rw');
has databits           => (is => 'rw');
has stopbits           => (is => 'rw');
has parity             => (is => 'rw');
has handshake          => (is => 'rw');
has read_char_time     => (is => 'rw');
has read_const_time    => (is => 'rw');
has write_settings     => (is => 'rw', default => 1);
has purge_all          => (is => 'rw', default => 1);
has read               => (is => 'rw');
has write              => (is => 'rw');
has close              => (is => 'rw', default => 1);

1;
