#!/usr/bin/perl

# Date: 2011-07-15
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


my $localdebug = $debug;
require "./config_reports.pl";
$debug = $localdebug;

use lib '..';
use lib '../lib/';
require './config.pl';
require "../routines.pl";
&am_admin();


print qq |Content-type: text/html

    <html>
	<head>
		<LINK REL=STYLESHEET TYPE="text/css" HREF="$reporturl/../strongbox.css">
		<script type="text/javascript">
		    function statushelp(code) {
			PageURL="$reporturl/../../codes.html#" + code;
			WindowName="statuscodes";
			settings=
			"toolbar=no,location=no,directories=no,"+
			"status=no,menubar=no,scrollbars=yes,"+
			"resizable=yes,width=350,height=150";
			MyNewWindow=
			window.open(PageURL,WindowName,settings);
		    }
                    function countryhelp(code) {
                        PageURL="$reporturl/../countries.html#" + code;
                        WindowName="countrycodes";
                        settings=
                        "toolbar=no,location=no,directories=no,"+
                        "status=no,menubar=no,scrollbars=yes,"+
                        "resizable=yes,width=350,height=150";
                        MyNewWindow=
                        window.open(PageURL,WindowName,settings);
                    }


		</script>
	      </head>
	<body>
	|;
 my $cgi = &parse_query();


$user = $cgi->{'user'};
$user =~ tr/A-Za-z0-9@_.,-//dc;
$user = substr( "$user", 0, 16 );
# $user = lc($user);

foreach $logfile (@logfiles) {
    open LOG, "$logfile";
    while (my $entry = <LOG>) {
        chomp $entry;
	( $luser, $time, $ip1, $ip2, $ip3, $lstat,$sbsession,$lcountry, $lorgname) = split ( ":", $entry );
	next if ( $lstat =~ m/^good/i );
	$luser =~ s/\.*$//g;
	$luser =~ s/\-*$//g;
	$luser =~ tr/A-Za-z0-9@_.,-//dc;
	$luser = substr( "$luser", 0, 16 );
	# $luser = lc($luser);
	if ( $user =~ m/^$luser$/i ) {
		$cnt_accesses++;
		$countries{$lcountry}++ unless($lcountry eq "XX");
		$ips{"$ip1.$ip2.$ip3"}++;
                $orgnames{"$ip1.$ip2.$ip3"} = $lorgname;
		$date = &ctime($time);
        	push (
			@tbody,
			qq|
	        	  <tr>
                         <tr>
                           <td>$date</td>
                           <td>$luser</td>
                           <td><a href="byip.cgi?ip=$ip1.$ip2.$ip3">$ip1.$ip2.$ip3</a></td>
                            <td><a class="status" onClick="countryhelp('$lcountry')">$lcountry</a></td>
                            <td><a href="byisp.cgi?isp=$orgnames{"$ip1.$ip2.$ip3"}">$orgnames{"$ip1.$ip2.$ip3"}</a></td>
                            <td>$sbsession</td>
			  </tr>
			|
			);
	} ## end if ( $user eq $luser )
    }
} ## end foreach $logfile (@logfiles)

print "<h3>$cnt_accesses bad referer attempts by $user from ";
print scalar keys(%ips) . " IP ranges in " . scalar keys(%countries); 
print " countries</h3>\n\n";


print "<table>\n\n";
print "<tr><th>Date</th><th>Username</th><th>IP</th><th>Country</th><th>ISP</th><th>Referer</th></tr>\n\n";
print reverse(@tbody);
print "\n\n</table>\n\n<h3>$cnt_accesses bad referer attempts by $user</h3>";




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




