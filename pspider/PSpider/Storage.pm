package PSpider::Storage;

use Digest::MD5 qw(md5_hex);

sub new {
    my $self = shift;
    $self = {} if (!defined($self));

    return bless $self;
}

sub db_file {
    my $self = shift;
    return $self->{'db_file'};
}

sub get_dbh {
    my $self = shift;
    if (!$self->{'dbh'}) {
	my $db_file = $self->db_file;
	$self->{'dbh'} = DBI->connect("dbi:SQLite:dbname=$db_file","","") or die DBI->errstr;
    }
    return $self->{'dbh'};
}

sub init_db {
    my $self = shift;
    my $dbh = $self->get_dbh();

    my $create_sql = 'CREATE TABLE pages(url PRIMARY KEY, hash, last);
CREATE INDEX idx_hash ON pages(hash);
CREATE INDEX idx_last ON pages(last);';

    $dbh->do($create_sql) or die $dbh->errstr;
}

sub save_page {
    my $self = shift;
    my ($url, $content, $time) = @_;
    my $hash = md5_hex($content);
    my $dbh = $self->get_dbh();
    $sql = sprintf('UPDATE pages SET hash=%s, last=%d WHERE url = %s',
		   $dbh->quote($hash), $time, $dbh->quote($url));

    $dbh->do($sql) or die $dbh->errstr;
}

sub add_page {
    my $self = shift;
    my $url = shift;

    return if (0 >= length($url));

    my $dbh = $self->get_dbh();
    my $sql = sprintf('INSERT OR IGNORE INTO pages(url, last) VALUES(%s, 0)', $dbh->quote($url));

    $dbh->do($sql) or die $dbh->errstr;
}

sub get_pages {
    my $self = shift;
    my $time = shift;
    my $limit = shift;
    my $sql = sprintf('SELECT * FROM pages WHERE last < %d LIMIT %d', $time, $limit);
    my $dbh = $self->get_dbh();
    my $rows = $dbh->selectall_arrayref($sql, {Slice => {}});
    return @{$rows};
}

sub list_pages {
    my $self = shift;
    my $time = shift;
    my $dbh = $self->get_dbh();
    my $sql = sprintf('SELECT * FROM pages WHERE last < %d', $time);
    my $sth = $dbh->prepare($sql) or die $dbh->errstr;
    my $rv = $sth->execute or die $sth->errstr;
    while(my @row = $sth->fetchrow_array) {
	printf("'%s'\t'%s'\t'%d'\n", $row[0], $row[1], $row[2]);
    }
}

1;
