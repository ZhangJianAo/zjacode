#!/usr/bin/perl

if ($ARGV[0] =~ /-[sn]/) {
	$parm = $ARGV[0];
}
else {
	print <<END;
trainbogo.pl Write by zja
Usage:
	trainbogo.pl [-s | -n] file ...
END
	exit;
}

for($i = 1; $i < @ARGV; $i++) {
	print `bogofilter $parm < $ARGV[$i]`;
}
