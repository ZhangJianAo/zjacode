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

{
    my $dbh;
    sub get_dbh {
	if (! $dbh) {
	    $dbh = DBI->connect("dbi:SQLite:dbname=pspider.db","","");
	}
	return $dbh;
    }
}

sub save_page {
    my ($url, $content, $time) = @_;
    my $hash = md5_hex($content);
    my $dbh = get_dbh();
    $sql = sprintf('UPDATE pages SET hash=%s, last=%d WHERE url = %s', $dbh->quote($hash), $time, $dbh->quote($url));

    $dbh->do($sql) or die $dbh->errstr;
}

sub add_page {
    my $url = shift;
    if (0 >= length($url)) {
	return;
    }

    my $dbh = get_dbh();
    my $sql = sprintf('INSERT OR IGNORE INTO pages(url, last) VALUES(%s, 0)', $dbh->quote($url));

    $dbh->do($sql) or die $dbh->errstr;
}

sub init_db {
    my $dbh = get_dbh();

    my $create_sql = 'CREATE TABLE pages(url PRIMARY KEY, hash, last);
CREATE INDEX idx_hash ON pages(hash);
CREATE INDEX idx_last ON pages(last);';

    $dbh->do($create_sql) or die $dbh->errstr;

    print "init_db....ok\n";
}

sub list_pages {
    my $time = shift;
    my $dbh = get_dbh();
    my $sql = sprintf('SELECT * FROM pages WHERE last < %d', $time);
    my $sth = $dbh->prepare($sql) or die $dbh->errstr;
    my $rv = $sth->execute or die $sth->errstr;
    while(my @row = $sth->fetchrow_array) {
	printf("'%s'\t'%s'\t'%d'\n", $row[0], $row[1], $row[2]);
    }
}

sub get_pages {
    my $time = shift;
    my $limit = shift;
    my $sql = sprintf('SELECT * FROM pages WHERE last < %d LIMIT %d', $time, $limit);
    my $dbh = get_dbh();
    my $rows = $dbh->selectall_arrayref($sql, {Slice => {}});
    return @{$rows};
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
