#!/usr/bin/perl

my %points;
my $max_hit = 0;

while(<>)
{
    $points{$_}++;
    if ($max_hit < $points{$_}) {
	$max_hit = $points{$_};
    }
}

print $max_hit;
