#!/usr/bin/perl -w

use strict;
use Text::Iconv;

my $iconv = 0;
my $pass_head = 0;
my $c = 0;
my $buf = '';

my $converter = Text::Iconv->new("utf-8", "gbk");

while ('' ne ($c = getc(STDIN))) {
    $buf .= $c;
    if ('>' eq $c) {
	if (!$pass_head) {
	    if ($buf =~ /charset=utf-8/i) {
		$buf =~ s/utf-8/gbk/i;
		print $buf;
		$buf = '';
		$iconv = 1;
	    } elsif ($buf =~ /<\/head>/i) {
		$pass_head = 0;
	    }
	}
	
	if ($iconv) {
	    print $converter->convert($buf);
	} else {
	    print $buf;
	}

	$buf = '';
    }
}
