#!/usr/bin/perl

# StrongBox version 2.3
# Copyright 2001, 2002, 2003, 2004, 2005, 2006
# Ray Morris <support@webmastersguide.com>
# All rights reserved.


require "./config.pl";
require "./isp.pl";
require "./routines.pl";
require "./proxycheck.pl";


opendir(TIS, "./turing_images/") or die "Could not open ./turingimages/ directory: $!"; 
my @images = grep { /\.gif$/ } readdir(TIS);
closedir TIS;

my $pic = $images[rand $#images];

unless (-d "$sessionfiles/turings") {
    mkdir "$sessionfiles/turings", 0777 or die "could not create directory '$sessionfiles/turings': $!";
}

open( CURRWORD, ">$sessionfiles/turings/$pic") or die "could not open : $!";
print CURRWORD "1\n";
close CURRWORD;
chmod 0666, "$sessionfiles/turings/$pic";


# select((select(STDOUT), $| = 1)[0]);
select(STDOUT); $| = 1;

print "Content-length: " . (-s "./turing_images/$pic") . "\n";
print qq|Pragma: no-cache
Cache-Control: no-cache
Expires: Tue, 25 Jan 2000 10:30:00 GMT
Vary: negotiate
Content-type: image/gif

|;

use bytes;
open( IMG, "<./turing_images/$pic") or die "could not open : $!";
binmode IMG;
binmode STDOUT;
while ( $read = read (IMG,$buffer,1024) ) {
    if ( ($read < 1024) && ($read > 24) ) {
        substr($buffer, $read - 24, 20, &randstring_mixcase(20));
    }
    print STDOUT $buffer;
}
close IMG;

$SIG{PIPE} = 'IGNORE';
$SIG{CHLD} = 'IGNORE';
close STDERR;
close STDOUT;
close STDIN;

if ($check_proxies) {
    open STDERR, "/dev/null" or die "Could not open '/dev/null': $!";
    open STDOUT, "/dev/null" or die "Could not open '/dev/null': $!";
    open STDIN, "/dev/null" or die "Could not open '/dev/null': $!";
    unless ($pid = fork) {
        unless (fork) {
            &ProxyCheck::isproxy($ENV{'REMOTE_ADDR'}, 10);
            &ip2org($ENV{'REMOTE_ADDR'}, 7) if ($uniqorgnames);
            exit 0;
        }
        exit 0;
    }
    waitpid($pid,0);
}



