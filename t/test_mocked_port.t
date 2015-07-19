#! /usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('TestClient') };

my $client = TestClient->new('abc', 'def');

is $client->read_port(1,'C'), ord('a'),
    'Read one character off the first message';
is $client->read_port(1,'C'), ord('b'),
    'Read one more character from the first message';

$client->set_index(1);
is_deeply [$client->read_port(2, 'CC')], [ord('d'), ord('e')],
    'Read two characters off the second message';
is $client->read_port(1,'C'), ord('f'),
    'Read last character off the second message';

done_testing();
