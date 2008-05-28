#!/usr/bin/perl

use Data::Dumper;
use HTTP::Date;
use HTML::LinkExtractor;
use LWP::UserAgent;
use DBI;
use Digest::MD5 qw(md5_hex);

sub get_page {
    my $url = shift;

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);

    if ($response->is_success) {
	return $response->content;
    } else {
	return 0;
    }
}

sub extra_links {
    my $page = shift;
    my $base_url = shift;

    my $lx = new HTML::LinkExtractor();
    $lx->parse(\$page);
    my $links = $lx->links;
    my @ret;

    foreach my $link (@{$links}) {
	if (exists $link->{'href'}) {
	    $url = URI->new_abs($link->{'href'}, $base_url);
	    if ($url =~ /http:\/\/www.douban.com\/(movie|subject\/\d+\/$)/i) {
		push(@ret, $url->as_string);
	    }
	}
    }

    return @ret;
}

sub extra_data {
    my ($url, $page) = @_;
    if ($url =~ /subject\/(\d+)\//) {
	$id = $1;
	$file_name = $id.'.html';
	open(F, '>', $file_name);
	print(F $page);
	close(F);
    }
}

sub start {
    my $time = shift;
    while(my @rows = get_pages($time, 10)) {
	foreach my $row (@rows) {
	    print 'crawl page:'.$row->{'url'}."\n";
	    $page = get_page($row->{'url'});
	    save_page($row->{'url'}, $page, $time);
	    @links = extra_links($page, $row->{'url'});
	    
	    add_page($_) foreach @links;
	    
	    extra_data($row->{'url'}, $page);

#	    sleep(5);
	}
    }
}

sub usage {
    print "usage:\npspider [init|add|start|list]\n";
}

$ARGC = @ARGV;
if (1 > $ARGC) {
    usage();
    exit;
}

my $mod = $ARGV[0];

if ('init' eq $mod) {
    print "init haha\n";
    init_db();
} elsif ('add' eq $mod) {
    $url = $ARGV[1];
    add_page($url);
} elsif ('list' eq $mod) {
    $arg = $ARGV[1];
    if (0 >= length($arg)) {
	list_pages(time());
    } else {
	list_pages(str2time($arg));
    }
} elsif ('start' eq $mod) {
    $arg = $ARGV[1];
    $time = str2time($arg);
    start($arg);
#    start();
}
