#!/usr/bin/perl

require "./config.pl";
require "./routines.pl";

my $log = "$ENV{'DOCUMENT_ROOT'}/sblogin/slurplog.txt";
unless ($ENV{'sbsession'}) {
	&getsession;
}

if (-e $log) {
    open(LOG, ">$log") or die "could not open '$log': $!";
    print LOG scalar localtime(), " : $ENV{'REMOTE_ADDR'} : $ENV{'HTTP_REFERER'}\n";
    close LOG;
}

chdir $sessionfiles or die "could not change dir to $sessionfiles: $!";
&rmtree("$ENV{'sbsession'}");

sleep 2;

print "Location: $loginpage\n\n";
exit 1;


sub getsession {
	$ENV{'HTTP_REFERER'} =~ m/^http:\/\/(sb\w+)\..*/;
	$sbsession ||=  $1;
	$ENV{'QUERY_STRING'} =~ m/sbsession=(sb\w+)/;
	$sbsession ||=  $1;
	$ENV{'HTTP_COOKIE'}  =~  m/sbsession\ ?=\ ?(sb\w+)/;
	$sbsession ||=  $1;
	$ENV{'HTTP_HOST'}    =~ m/^(sb\w+)\./;
	$sbsession ||=  $1;
	return $sbsession;
}


