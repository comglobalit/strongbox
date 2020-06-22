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

use lib '../lib/';
my $localdebug = $debug;
require '../config.pl';
require "./config_reports.pl";
$debug = $localdebug || $debug;

use lib '..';
require "../routines.pl";
&am_admin();

my $cgi = &parse_query();

print qq |Content-type: text/html

|;

my $tmpl_header = $ENV{DOCUMENT_ROOT} . "/sblogin/report/header.php";
my $tmpl_bottom = $ENV{DOCUMENT_ROOT} . "/sblogin/report/bottom.php";
open TMPL_HEADER,$tmpl_header;
while (my $line = <TMPL_HEADER>) {
        chomp $line;
        $line =~ s!..php echo ._SERVER..HTTP_HOST.. ..!$host - Report for user $cgi->{'user'}!;
        print $line;
}

print "<h1>Report for user $cgi->{'user'}</h1><a href=\"/sblogin/report/\"><a href=\"/sblogin/report/\">Back to Main Page</a><br>";

$user = $cgi->{'user'};
$user =~ tr/A-Za-z0-9\ @_.,\*\&\$\/\!\#-//dc;
$user = substr( "$user", 0, 16 );
$user =~ s/\.$// if ( length($user) == 16 );
# $user = lc($user);

my $cnt_accesses = 0;
my $cnt_accesses_success = 0;

my $two_days_ago = time() - (60 * 60 * 24 * 3);
my $isblocked = 0;
foreach $logfile (@logfiles) {
    open LOG, "$logfile";
    while (my $entry = <LOG>) {
	    chomp $entry;
	    ( $luser, $time, $ip1, $ip2, $ip3, $lstat,$sbsession,$lcountry, $lorgname) = split ( ":", $entry );
	    $lstat = 'ok' if ( $lstat eq 'goodpage' );
        $lcstat = lc($lstat);
	    # $luser =~ s/\.*$//g;
	    # $luser =~ s/\-*$//g;
        $luser =~ tr/A-Za-z0-9\ @_.,\*\&\$\/\!\\\#-//dc;
        $luser =~ s/\>/&gt;/g;
        $luser =~ s/</&lt;/g;
        $luser =~ s/\.+$//;
        $luser_lower = lc($luser);
        $user_lower  = lc($user);
        if ( $luser_lower eq $user_lower ) {
    	    $cnt_accesses++;
		    $countries{$lcountry}++ unless($lcountry eq "XX");
		    $ips{"$ip1.$ip2.$ip3"}++;
            $orgnames{"$ip1.$ip2.$ip3"} = $lorgname;
                if ($lstat eq 'gooduser') {
                    $cnt_accesses_success++;
                    $countries_success{$lcountry}++ unless($lcountry eq "XX");
                    $ips_success{"$ip1.$ip2.$ip3"}++;
                } elsif(
                           ($lstat =~ m/^dis/) || 
                           ( ($lstat =~ m/^uniq/) && ($time > $two_days_ago) ) 
                       ) { 
                    $isblocked = 1;
                } elsif ($lstat eq uc($lstat) ) {
                    $cnt_accesses_clear++;
                    $countries_clear{$lcountry}++ unless($lcountry eq "XX");
                    $ips_clear{"$ip1.$ip2.$ip3"}++;
                } else {
                    print "else baby\n" if ($debug);
                }
            $date = &ctime($time);
            $org_enc = urlencode($orgnames{"$ip1.$ip2.$ip3"});
		if ($deluxe) {
			push (
				@tbody,
				qq|
			  <tr>
			    <td><a href="session_page_report.cgi?$time">$date</a></td>
                <td>$luser</td>
			    <td><a href="byip.cgi?ip=$ip1.$ip2.$ip3">$ip1.$ip2.$ip3</a></td>
                <td><a class="status" onClick="countryhelp('$country')">$lcountry</a></td>
                <td><a href="byisp.cgi?isp=$org_enc">$orgnames{"$ip1.$ip2.$ip3"}</a></td>
			    <td><a class=\"status\" onClick='statushelp(\"($lcstat)\")'>$lstat</a></td>
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
                            <td>$luser</td>
                            <td><a href="byip.cgi?ip=$ip1.$ip2.$ip3">$ip1.$ip2.$ip3</a></td>
                            <td><a class="status" onClick="countryhelp('$lcountry')">$lcountry</a></td>
                            <td><a href="byisp.cgi?isp=$org_enc"}">$orgnames{"$ip1.$ip2.$ip3"}</a></td>
                            <td><a class=\"status\" onClick='statushelp(\"$lcstat\")'>$lstat</a></td>
			  </tr>
			|
			);
		} ## end else [ if ($deluxe)
	} ## end if ( $user eq $luser )
    } ## end foreach $entry (@log)
    close LOG;
}

print "<ul>";
print "<li>Site: $host</li>";
print "<li>$cnt_accesses login attempts by $user from " . scalar keys(%ips);
print " IP ranges in " . scalar keys(%countries) . " countries</li>\n\n";

print "<li>$cnt_accesses_success successful logins by $user from ". scalar keys(%ips_success);
print " IP ranges in " . scalar keys(%countries_success) . " countries</li>\n";

if ($cnt_accesses_clear) {
    print "<li>&nbsp;&nbsp;$cnt_accesses_clear logins by $user from " . scalar keys(%ips_clear);
    print " IP ranges in " . scalar keys(%countries_clear) . " countries reset by administrator.</li>\n" ;
}
print "</ul>";

print "<p>\nTo see other user names tried by this person, click on their IP</p>\n\n";



if ($isblocked) {
    print qq|          
        <form action="./usermanage.cgi" method="post" style="margin-left: 0em;">
          <center><h3><u>User "$user" has been<br />Disabled or Denied</u></h3></center>
          <fieldset>
            <legend>
              <center>Clear ${user}'s History? <small>(change password optional)</small></center>
            </legend>
            <center>
               <br /><small>(leave blank for no password change)</small>:
               <input name="pword"></input>
            </center>
            <input type="hidden" name="uname" value="$user"></input>
            <input type="hidden" name="action" value="reenable"></input>
            <input class="submit" type="submit" name="submit" value="Reenable User" />
          </fieldset>
        </form>
    |;
}

print "<table>\n\n";
print "<tr><th>Date</th><th>Username</th><th>IP</th><th>Country</th><th>ISP</th><th>Result</th></tr>\n\n";
print reverse(@tbody);
print "\n\n</table>\n\n<h3>$cnt_accesses login attempts by $user</h3>";

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




