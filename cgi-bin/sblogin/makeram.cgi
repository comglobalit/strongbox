#!/usr/bin/perl

# Date: 2009-07-29

# Strongbox 2.3
# Copyright Ray Morris <support@bettercgi.com>
# All rights reserved.

# This script inserts the newton (subdomain) into 
# rm URLs inside of ram files for RealMedia.

my $file = $ENV{'PATH_INFO'};
$file = $ENV{'QUERY_STRING'} unless ($file);
$file =~ s/\.ram$//;

$host=$ENV{'HTTP_HOST'};
$host =~ s/^www\.//;
$host =~ s/^sb[0-9a-z]+\.//;


my $sbsession = &get_session();

# print "Content-type: audio/x-pn-realaudio\n\n";

if (-e "$ENV{DOCUMENT_ROOT}$file.rm") {
    print "Content-type: audio/x-pn-realaudio\n\n";
    print "http://$sbsession.${host}$file.rm\n";
} elsif ("$ENV{DOCUMENT_ROOT}$file.ram") {
    print "Content-type: audio/x-pn-realaudio\n\n";
    open(RAM, "$ENV{DOCUMENT_ROOT}$file.ram") or die "could not open '$ENV{DOCUMENT_ROOT}$file.ram': $!";
    while(<RAM>) {
        s/www.$host/$sbsession.$host/g;
        s/$host/$sbsession.$host/g;
        print;
    }
} else {
    print "Status: 404\n";
}

sub get_session {
        my $sbsession;
        if ($ENV{'HTTP_COOKIE'} =~ m/sbsession\ ?=\ ?(sb[0-9a-z]+)/) {
                $sbsession = $1;
        }
        if ($ENV{'HTTP_REFERER'} =~ m/^http:\/\/(sb[0-9a-z]+)\./) {
                $sbsession = $1;
        }
        if ($ENV{'HTTP_HOST'} =~ m/^(sb[0-9a-z]+)\./) {
                $sbsession = $1;
        }

        return $sbsession;
}


