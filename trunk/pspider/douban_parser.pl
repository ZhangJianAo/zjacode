#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use HTML::Parser;
use DBI;
use utf8;
use HTML::TreeBuilder;

my $filename = $ARGV[0];
print $filename, "\n";
parse_file($filename);

sub parse_file {
    my $file_name = shift;

    my $id = 0;
    if ($file_name =~ /^(\d+)\.html/) {
	$id = $1;
    }
    my $name = 0;
    my $img = 0;
    my $info = 0;
    my $desc = 0;

    my $tree = HTML::TreeBuilder->new();
    $tree->parse_file($file_name);

    my $t = $tree->find_by_tag_name('h1');
    if ($t) {
	$name = $t->as_text;
    }

    my $pic = $tree->find_by_attribute('id', 'mainpic');
    if ($pic) {
	my $img_el = $pic->find_by_tag_name('img');
	if ($img_el) {
	    $img = $img_el->attr('src');
	}
    }

    my $info_el = $tree->find_by_attribute('id', 'info');
    if ($info_el) {
	my $info_txt = $info_el->as_HTML('');
	$info_txt =~ s/<br[^>]*>/\n/ig;
	$info_txt =~ s/<a *href="([^'"]+)".*?<\/a>/$1/ig;
	$info_txt =~ s/<[^>]*>//ig;
	$info_txt =~ s/\n\n+/\n/ig;
	$info = $info_txt;
    }

    my $father = $tree->find_by_attribute('id', 'in_tablem');
    if ($father) {
	my @children = $father->content_list;

	for(my $i = 0; $i < @children; $i++) {
	    if ('h2' eq $children[$i]->tag) {
		$desc = $children[$i+1];
		last;
	    }
	}
    }

    if ($desc) {
	my $innerHtml = $desc->as_HTML('');
	$innerHtml =~ s/<br[^>]*>/\n/g;
	if ($innerHtml =~ /<div class="indent">(.*?)</is) {
	    $desc = $1;
	} else {
	    $desc = 0;
	}
    }

    if ($id && $name && $img && $info && $desc) {
	my $dbh = DBI->connect("dbi:SQLite:dbname=douban.db","","", { sqlite_encoding => 'UTF-8' });
	my $sql = sprintf('INSERT OR IGNORE INTO movies(id, name, img, info, desc) VALUES(%d, %s, %s, %s, %s)',
			  $id,
			  $dbh->quote($name),
			  $dbh->quote($img),
			  $dbh->quote($info),
			  $dbh->quote($desc));

	$dbh->do($sql) or die $dbh->errstr;
	$dbh->disconnect;

	unlink $file_name;
    } else {
	system('mv', $file_name, '../douban_pages/');
    }
}
