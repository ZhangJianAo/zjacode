#!/usr/bin/perl

#program used to save mutt mail attachment to my windows machine

use Net::FTP;

$filename = $ARGV[0];

if ('' eq $filename) {
    print("Must Specific the file name\n");
} else {
    $fullname = '/home/zja/mailtmp/'.$filename;
    open(TMPF, ">$fullname");

    while(<STDIN>) {
	print TMPF $_;
    }

    close(TMPF);
    
    $ftp = Net::FTP->new("myWindows");
    $ftp->login("anonymous", 'anonymous@my.com');
    $ftp->cwd("/pub/mail");
    $ftp->binary();
    $ftp->put($fullname, $filename);
    $ftp->quit;
}
