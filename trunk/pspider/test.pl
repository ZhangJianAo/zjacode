#!/usr/bin/perl -w

use Data::Dumper;
use PSpider::Storage;

$stor = PSpider::Storage->new();
$stor->{'db_file'} = 'test.db';
print "hello world!\n";
print $stor->db_file, "\n";
print Dumper($stor);
