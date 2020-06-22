#!/usr/bin/perl 

# Date: 2011-02-18

# StrongBox version 2.3
# Copyright 2001, 2002, 2003, 2004, 2005, 2006, 2008
# Ray Morris <support@webmastersguide.com>
# All rights reserved.

require "./config.pl";
require "./routines.pl";

BEGIN {
        $debug = 0 unless($debug);
        if ($debug) {
                print "Content-type: text/html\n\n<html><body><pre>\n";
                open (STDERR, ">&STDOUT");

                select(STDERR); $| = 1;
                select(STDOUT); $| = 1;
        }
}


my $file = $ENV{'PATH_INFO'};
$file = $ENV{'QUERY_STRING'} unless ($file);
# $file =~ s/ /\%20/g;
$file =~ m/\/([^\/]*)$/;
my $basename = $1;
$basename_encoded = &urlencode($basename);

my $isdialer = &isdialer;
my $sbsession = &get_session;



if ( length($ENV{'HTTP_USER_AGENT'}) < 5) {
        print "Location: $errpage\n\n";
        exit 1;
}

$ENV{'HTTP_USER_AGENT'} =~ s/\n|\r//g;
$ENV{'HTTP_USER_AGENT'} =~ s/\.\.\///g;
$ENV{'HTTP_ACCEPT'} =~ s/\n|\r//g;
$ENV{'HTTP_ACCEPT'} =~ s/\.\.\///g;

$ENV{'HTTP_USER_AGENT'} = substr($ENV{'HTTP_USER_AGENT'}, 0, 250);
$ENV{'HTTP_ACCEPT'} = substr($ENV{'HTTP_ACCEPT'}, 0, 250);
if ($ENV{'HTTP_USER_AGENT'} =~ m/PLAYSTATION/) {
    $ENV{'HTTP_ACCEPT'} = 'ImAStupidPlaystation' unless ($ENV{'HTTP_ACCEPT'});
}
$ENV{'HTTP_ACCEPT'} = '*/*' if ($ENV{'HTTP_USER_AGENT'} =~ m/Android 2\.2/);

$browser_sig = "$ENV{'HTTP_USER_AGENT'}/$ENV{'HTTP_ACCEPT'}";

&do_plugins('video2', $sessionfiles, $sbsession, $file);

unless (  
          (-f "$sessionfiles/$sbsession.$host/$ENV{'REMOTE_ADDR'}" ) ||
	  (-f "$sessionfiles/$sbsession.$host/$browser_sig/$site_id" ) ||
          ( $allowembedvideo && (-d "$sessionfiles/$sbsession.$host")  ) ||
	  ($isdialer)
       ) {
		print "Location: $loginpage/$file\n\n";
		exit 1;
}


&touch("$sessionfiles/$sbsession.$host/$basename");
&touch("$sessionfiles/$sbsession.$host/$basename_encoded");
print "Location: http://$sbsession.$host" . $file . "\n\n";
exit 0;


sub touch {
	my $file = $_[0];
	if (-f $file) {
		my $now = time();
        	utime $now, $now, $file;
	} else {
		open(FILE, ">$file") or die "Could not open video flag \"$file\": $!";
		print FILE "";
		close FILE;
	}
}


sub isdialer {
	my $isdialer = 0;
	# CCBill dialer IPs
	@allowed = (
		"194.149.242.1",
                "194.149.242.3",
                "194.149.242.241", 
                "195.68.121.1",
                "195.68.121.24",
                "212.71.31.210",
                "212.121.204.20",
                "212.147.118.14",
                "212.187.157.60",
                "212.155.171.128",
                "217.56.72.13",
                "195.243.119.43",
                "208.59.199.25"
	);

	foreach my $ip (@allowed) {
		if ($ENV{'REMOTE_ADDR'} =~ m/^$ip/) {
			$isdialer = 1;
			last;
		}
	}
	return $isdialer;
}	

