#!/usr/bin/perl

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


use lib '../lib/';

my $localdebug = $debug;
require '../config.pl';
require "./config_reports.pl";
$debug = $localdebug;

use lib '..';
require "../routines.pl";
&am_admin();

use Time::Local;

my  $cgi = &parse_query();

my $show_top = $cgi->{'show_top'};
my $begin_date = "$cgi->{'begin_month'}/$cgi->{'begin_day'}/$cgi->{'begin_year'}";
my $end_date = "$cgi->{'end_month'}/$cgi->{'end_day'}/$cgi->{'end_year'}";


my $begin = timegm(0,0,0,$cgi->{'begin_day'},$cgi->{'begin_month'} -1,$cgi->{'begin_year'});
my $end = timegm(59,59,23,$cgi->{'end_day'},$cgi->{'end_month'} - 1,$cgi->{'end_year'});
print "begin: $begin\nend: $end\n" if ($debug);


print qq |Content-type: text/html

|;

my $tmpl_header = $ENV{DOCUMENT_ROOT} . "/sblogin/report/header.php";
my $tmpl_bottom = $ENV{DOCUMENT_ROOT} . "/sblogin/report/bottom.php";
open TMPL_HEADER,$tmpl_header;
while (my $line = <TMPL_HEADER>) {
        chomp $line;
		$line =~ s!..php echo ._SERVER..HTTP_HOST.. ..!$host!;
		print $line;
}

print "<h1>Raw Strongbox Log</h1><a href=\"/sblogin/report/\">Back to Main Page</a>";

foreach $logfile (@logfiles) {
    open LOG, "$logfile";
    while (my $entry = <LOG>) {
        chomp $entry;
	( $luser, $time, $ip1, $ip2, $ip3, $lstat,$sbsession,$lcountry, $lorgname) = split ( ':', $entry );
        next if ($time < $begin);
        last if ($time > $end);
        next unless ( ($cgi->{'goodonly'} == 0) || ($lstat =~ m/^good/) );
	$lstat = 'ok' if ( $lstat eq 'goodpage' );
	$luser =~ s/\.*$//g;
	$luser =~ s/\-*$//g;
	$luser =~ tr/A-Za-z0-9@_.,-//dc;
	$luser = substr( "$luser", 0, 16 );

        $cnt_accesses++;
        $countries{$lcountry}++ unless($lcountry eq "XX");
        $ips{"$ip1.$ip2.$ip3"}++;
        $orgnames{"$ip1.$ip2.$ip3"} = $lorgname;

        if ($lstat eq 'gooduser') {
            $cnt_accesses_success++;
            $countries_success{$lcountry}++ unless($lcountry eq "XX");
            $ips_success{"$ip1.$ip2.$ip3"}++;
        }
        $date = &ctime($time);
        push (
                @tbody,
                qq|
              <tr>
              <tr>
				<td><span id="date-$time-$cnt_accesses" title="UTC Time: $date">$date</span><script type="text/javascript">convert_to_local(document.getElementById("date-$time-$cnt_accesses"),$time); </script></td>
                <td>$luser</td>
                <td><a href="byip.cgi?ip=$ip1.$ip2.$ip3">$ip1.$ip2.$ip3</a></td>
                <td><a class="status" onClick="countryhelp('$lcountry')">$lcountry</a></td>
                <td><a href="byisp.cgi?isp=$orgnames{"$ip1.$ip2.$ip3"}">$orgnames{"$ip1.$ip2.$ip3"}</a></td>
                <td><a class=\"status\" onClick='statushelp(\"$lstat\")'>$lstat</a></td>
              </tr>
            |
            );
    }
} ## end foreach $logfile (@logfiles)


print "<h3>$cnt_accesses login attempts from ";
print scalar keys(%ips) . " IP ranges in " . scalar keys(%countries); 
print " countries</h3>\n\n";


print "<h3>$cnt_accesses_success succesful logins from ";
print scalar keys(%ips_success) . " IP ranges in " . scalar keys(%countries_success);
print " countries</h3>\n\n";



print "<table>\n\n";
print "<tr><th>Date</th><th>Username</th><th>IP</th><th>Country</th><th>ISP</th><th>Result</th></tr>\n\n";
print reverse(@tbody);
print "\n\n</table>" ; #\n\n<h3>$cnt_accesses login attempts by $user</h3>";


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




