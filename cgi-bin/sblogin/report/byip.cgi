#!/usr/bin/perl

# Date: 2012-04-24
BEGIN {
        $debug = 0;
	if ($debug) {
		print "Content-type: text/plain\n\n";
		open( STDERR, ">&STDOUT" );

		select(STDERR);
		$| = 1;
		select(STDOUT);
		$| = 1;
	} ## end if ($debug)

} ## end BEGIN


use lib '..';
use lib '../lib/';
require '../config.pl';
require "../routines.pl";
&am_admin();
my $localdebug = $debug;
require "./config_reports.pl";
$debug = $localdebug;

my $cgi = &parse_query();

print qq |Content-type: text/html

|;

my $tmpl_header = $ENV{DOCUMENT_ROOT} . "/sblogin/report/header.php";
my $tmpl_bottom = $ENV{DOCUMENT_ROOT} . "/sblogin/report/bottom.php";
open TMPL_HEADER,$tmpl_header;
while (my $line = <TMPL_HEADER>) {
        chomp $line;
        $line =~ s!..php echo ._SERVER..HTTP_HOST.. ..!$host - Report for IP $cgi->{'ip'}!;
        print $line;
}
print "<h1>Report for IP $cgi->{'ip'}</h1><a href=\"/sblogin/report/\"><a href=\"/sblogin/report/\">Back to Main Page</a><br>";

my @addr = split(/\./, $cgi->{'ip'});
$fill="000";
$add1=substr("$fill$addr[0]",-3);
$add2=substr("$fill$addr[1]",-3);
$add3=substr("$fill$addr[2]",-3);
$add4=substr("$fill$addr[3]",-3);
$saddr="$add1.$add2.$add3";

# $user = lc($user);

my $orgname;
my $country;
my $isblocked = 0;

foreach $logfile (@logfiles) {
    open LOG, "$logfile";
    while (my $entry = <LOG>) {
        chomp $entry;
	( $luser, $time, $ip1, $ip2, $ip3, $lstat,$sbsession,$lcountry, $lorgname) = split ( ":", $entry );
	$luser =~ s/\.*$//g;
	$luser =~ s/\-*$//g;
        $luser =~ tr/A-Za-z0-9\ @_.,\*\&\$\/\!\#-//dc;
	$luser = substr( "$luser", 0, 16 );
	# $luser = lc($luser);
	if (  $saddr eq "$ip1.$ip2.$ip3" ) {
        $orgname = $lorgname;
        $country = $lcountry;
		$cnt_accesses++;
		$usernames{$luser}++;
        $isblocked = 0 if ($lstat eq 'gooduser');
        $isblocked = 1 if ($lstat eq 'attempts');
		$date = &ctime($time);
        $lccode = lc ($lstat);
		if ($deluxe) {
			push (
				@tbody,
				qq|
			  <tr>
			    <td><a href="session_page_report.cgi?$time">$date</a></td>
			    <td><a href="byuser.cgi?user=$luser">$luser</a></td>
			    <td><a class=\"status\" onClick='statushelp(\"$lccode\")'>$lstat</a></td>
			  </tr>
			|
			);
		} else {
			push (
				@tbody,
				qq|
			  <tr>
                          <tr>
                            <td><span id="date-$time-$cnt_accesses" title="UTC Time: $date">$date</span><script type="text/javascript">convert_to_local(document.getElementById("date-$time-$cnt_accesses"),$time); </script></td>
                            <td><a href="byuser.cgi?user=$luser">$luser</a></td>
                            <td><a class=\"status\" onClick='statushelp(\"$lccode\")'>$lstat</a></td>
			  </tr>
			|
			);
		} ## end else [ if ($deluxe)
	} ## end if ( $user eq $luser )
    }
} ## end foreach $logfile (@logfiles)

$orgname_enc = urlencode($orgname);
print "<ul><li>Site: $host</li>";
print "<li>$cnt_accesses login attempts from $saddr (<a href=\"byisp.cgi?isp=$orgname\">$orgname</a> in <a class=\"status\" onClick=\"countryhelp('$country')\">$country</a> with ";
print scalar keys(%usernames) . " usernames)</li></ul>\n\n<table>\n"; 
print "<tr><th>Date</th><th>Username</th></th><th>Result</th></tr>\n\n";
print "$saddr recently suspended. <a href=\"usermanage.cgi?ip=$saddr&action=reenableip\">Re-enable</a><br>\n" if ($isblocked);
print reverse(@tbody);
print "\n\n</table>\n\n<h3>$cnt_accesses login attempts from $saddr</h3>";

open TMPL_BOTTOM,$tmpl_bottom;
while (my $line = <TMPL_BOTTOM>) {
        chomp $line;
        print $line;
}

sub ctime {
	local ($time) = @_;
	local ($[)    = 0;
	local ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst );

	@DoW = ( 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' );
	@MoY = (
		'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
		'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
	);

	# Determine what time zone is in effect.
	# Use GMT if TZ is defined as null, local time if TZ undefined.
	# There's no portable way to find the system default timezone.

	# $TZ = defined( $ENV{'TZ'} ) ? ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) : '';
	# ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
	#  ( $TZ eq 'GMT' ) ? gmtime($time) : localtime($time);
         ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime($time);
         
        my $TZ = 'GMT';
	# Hack to deal with 'PST8PDT' format of TZ
	# Note that this can't deal with all the esoteric forms, but it
	# does recognize the most common: [:]STDoff[DST[off][,rule]]
	if ( $TZ =~ /^([^:\d+\-,]{3,})([+-]?\d{1,2}(:\d{1,2}){0,2})([^\d+\-,]{3,})?/ ) {
		$TZ = $isdst ? $4 : $1;
	}
	$TZ .= ' ' unless $TZ eq '';

	$year += 1900;
	sprintf( "%s %s %2d %2d:%02d:%02d %s%4d\n",
		$DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $TZ, $year );
} ## end sub ctime




