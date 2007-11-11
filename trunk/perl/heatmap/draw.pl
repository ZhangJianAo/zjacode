#!/usr/bin/perl

use Data::Dumper;
use Image::Magick;

my $w = 1221;
my $h = 678;

my %points;
my $max_hit = 0;

#$cmd = "convert -size ${w}x${h} pattern:gray100 mask.png";
#system($cmd);

$mask = Image::Magick->new(size => "${w}x${h}");
$mask->ReadImage('xc:white');

while(<>)
{
    $points{$_}++;
    if ($max_hit < $points{$_}) {
	$max_hit = $points{$_};
    }
}

# print $max_hit;

#system("convert bolilla.png -fill white -colorize ".int($max_hit/100)."% bol.png");

$bol = Image::Magick->New;
$bol->Read('bolilla.png');
$bol->Colorize(fill => white, opacity => int($max_hit/100).'%');

foreach $p (keys %points) {
    my($x, $y) = split("\t", $p);
    $x = int($x) + ($w / 2) - 32;
    $y = ($h / 2) - int($y) - 32;
    if ((0 <= $x) && (0 <= $y)) {
	#$cmd = "composite -compose multiply -geometry +$x+$y bol.png mask.png mask.png";
	#print $cmd, "\n";
	#system($cmd);
	$mask->Composite(image => $bol, compose => Multiply, geometry => "+$x+$y");
    }
}

$mask->Negate();

$colorMap = Image::Magick->New;
$colorMap->Read('colors.png');
$width = $colorMap->Get('height');

for(my $x = 0; $x < $w; $x++) {
    for(my $y = 0; $y < $h; $y++) {
	my $index = $mask->GetPixel(geometry=>"+$x+$y", channel=>Gray);

	#print Dumper($index); exit 0;
	$index = 0.5;
	$index = int($index * $width);
	$index = $width-1 if $index >= $width;
	
	print $index, " ", $width, "\n";

	my @color = $colorMap->GetPixel(x=>0, y=>$index, channel=>All);


print Dumper(@color); exit 0;
	$mask->SetPixel(channel=>All, x=>$x, y=>$y, color=>\@color);
    }
}

$mask->Write(filename => 'mask.png');
$bol->Write('bol.png');

exit 0
#system('convert mask.png colors.png -fx "v.p{0,u*v.h}" final.png');
#system('composite -blend 40% final.png screen.png heatmap.png');
