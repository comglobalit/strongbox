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


use lib '..';
use lib '../lib/';
require '../config.pl';
require "../routines.pl";
&am_admin();
my $localdebug = $debug;
require "./config_reports.pl";
$debug = $localdebug;

foreach $logfile (@logfiles) {
    open LOG, "$logfile";
    my @thisfile = <LOG>;
    push (@log, @thisfile);
    close LOG;
}

print qq |Content-type: text/html

    <html>
	<head>
		<LINK REL=STYLESHEET TYPE="text/css" HREF="$reporturl/../../strongbox.css">
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
           <div name=logout_link id=report_home_link><a href="/sblogin/report/"><h3>Strongbox Admin Area<h3></a></div><br>
	|;
 my $cgi = &parse_query();


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
foreach $entry (@log) {
	chomp $entry;
	( $luser, $time, $ip1, $ip2, $ip3, $lstat,$sbsession,$lcountry, $lorgname) = split ( ":", $entry );
        $isblocked = 0 if ($lstat eq "gooduser");
        $isblocked = 1 if ($lstat eq "attempts");
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

		$date = &ctime($time);
		if ($deluxe) {
			push (
				@tbody,
				qq|
			  <tr>
			    <td><a href="session_page_report.cgi?$time">$date</a></td>
			    <td><a href="byuser.cgi?user=$luser">$luser</a></td>
			    <td><a class=\"status\" onClick='statushelp(\"$lstat\")'>$lstat</a></td>
			  </tr>
			|
			);
		} else {
			push (
				@tbody,
				qq|
			  <tr>
                          <tr>
                            <td>$date</td>
                            <td><a href="byuser.cgi?user=$luser">$luser</a></td>
                            <td><a class=\"status\" onClick='statushelp(\"$lstat\")'>$lstat</a></td>
			  </tr>
			|
			);
		} ## end else [ if ($deluxe)
	} ## end if ( $user eq $luser )
} ## end foreach $entry (@log)

$orgname_enc = urlencode($orgname);
print "<h3>$cnt_accesses login attempts from $saddr (<a href=\"byisp.cgi?isp=$orgname\">$orgname</a> in <a class=\"status\" onClick=\"countryhelp('$country')\">$country</a> with ";
print scalar keys(%usernames) . " usernames</h3>\n\n<table>\n"; 
print "<tr><th>Date</th><th>Username</th></th><th>Result</th></tr>\n\n";
print "$saddr recently suspended. <a href=\"usermanage.cgi?ip=$saddr&action=reenableip\">Re-enable</a><br>\n" if ($isblocked);
print reverse(@tbody);
print "\n\n</table>\n\n<h3>$cnt_accesses login attempts from $saddr</h3>";




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




