#!/usr/bin/perl -w

use strict;
use Term::ReadKey;
use Net::Dict;

my @words = ();
my $i = 0;
my $count = 1;

open(my $f, $ARGV[0]);

while(<$f>) {
    if ($_ =~ /\d* (\w*) \*/) {
	$words[$i] = $1;
	$i++;
    }
}

close($f);

my $index = int(rand($i));
print $count, ' ', $words[$index], "\n";

ReadMode 'cbreak';

while (my $key = ReadKey(0)) {
    if ('q' eq $key) { quitprog(); }
    if ('j' eq $key) {
	splice(@words, $index, 1);
	$i--;
        $count++;
	if (0 < $i) {
	    $index = int(rand($i));
	    print $count, ' ', $words[$index], "\n";
	} else {
	    quitprog();
	}
    }

    if ('e' eq $key) {
	my $dict = Net::Dict->new('dict.org');
	my $h = $dict->define($words[$index], 'gcide');
	foreach my $i (@{$h}) {
	    my ($db, $def) = @{$i};
	    print $db, ":\n";
            print $def, "\n";
	}
    }
}

sub quitprog {
    ReadMode 'normal';
    exit;
}
