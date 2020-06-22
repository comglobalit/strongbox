#!/usr/bin/perl

# StrongBox version 2.3
# Copyright 2001, 2002, 2003, 2004, 2005, 2006, 2007
# Ray Morris <support@webmastersguide.com>
# All rights reserved.


require "./config.pl";
require "./isp.pl";
require "./routines.pl";
require "./proxycheck.pl";


opendir(TIS, "./turing_mp3/") or die "Could not open ./turingimages/ directory: $!"; 
my @images = grep { /\.mp3$/ } readdir(TIS);
closedir TIS;

my $snd = $images[rand $#images];

unless (-d "$sessionfiles/turings/") {
    mkdir "$sessionfiles/turings/", 0777 or die "could not create directory '$sessionfiles/turings/': $!";
}

my $pic = $snd;
$pic =~ s/mp3/gif/;

open( CURRWORD, ">$sessionfiles/turings/$pic") or die "could not open : $!";
print CURRWORD "1\n";
close CURRWORD;
chmod 0666, "$sessionfiles/turings/$pic";


select((select(STDOUT), $| = 1)[0]);
print "Content-length: " . (-s "./turing_mp3/$snd" ) . "\n";
print qq|Pragma: no-cache
Cache-Control: no-cache
Expires: Tue, 25 Jan 2000 10:30:00 GMT
Vary: negotiate
Content-type: audio/mpeg

|;

use bytes;
my $commented;
my $randstring = &randstring(6);
open( IMG, "<./turing_mp3/$snd") or die "could not open : $!";
binmode IMG;
binmode STDOUT;
while ( $read = read (IMG,$buffer,1024) ) {
    $buffer =~ s/\-\-\-\-\-\-/$randstring/ unless $commented++;
    print STDOUT $buffer;
}
close IMG;

# print STDOUT pack('a4LLa' . $comment_len + 1, 'labl', $comment_len - 2, 3, &randstring($comment_len));

$SIG{PIPE} = 'IGNORE';
$SIG{CHLD} = 'IGNORE';
close STDERR;
close STDOUT;
close STDIN;

open STDERR, "/dev/null" or die "Could not open '/dev/null': $!";
open STDOUT, "/dev/null" or die "Could not open '/dev/null': $!";
open STDIN, "/dev/null" or die "Could not open '/dev/null': $!";
unless ($pid = fork) {
    unless (fork) {
        &ProxyCheck::isproxy($ENV{'REMOTE_ADDR'});
        &ip2org($ENV{'REMOTE_ADDR'}, 7) if ($uniqorgnames);
        exit 0;
    }
    exit 0;
}
waitpid($pid,0);



