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
use Time::Local;

require '../config.pl';
require "routines.pl";
&am_admin();
my $localdebug = $debug;
require "./config_reports.pl";
$debug = $localdebug;

my $cgi = &parse_query();

my $begin_date;
my $begin;

if ($cgi->{'begin_month'}) {
    $begin_date = "$cgi->{'begin_month'}/$cgi->{'begin_day'}/$cgi->{'begin_year'}";
    $begin = timegm(0,0,0,$cgi->{'begin_day'},$cgi->{'begin_month'} -1,$cgi->{'begin_year'});
} else {
    $begin = time() - (7 * 24 * 60 * 60);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($begin);
    $mon++;
    $year += 1900;
    $begin_date = "$mon/$mday/$year";
}


my $end = time();
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($end);
my $end_date = sprintf("%02d/%02d/%04d", $mon + 1, $mday, $year + 1900);

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

 my $cnty = $cgi->{'cnty'};
 $cnty =~ s/^ *//;
 $cnty =~ s/ *$//;

my $country;
foreach $logfile (@logfiles) {
    open LOG, "$logfile";
    while (my $entry = <LOG>) {
        chomp $entry;
        ( $luser, $time, $ip1, $ip2, $ip3, $lstat,$sbsession,$lcountry, $lorgname) = split ( ":", $entry );
        next if ($time < $begin);
        last if ($time > $end);
        $lstat = "ok" if ( $lstat eq "goodpage" );
        $luser =~ s/\.*$//g;
        $luser =~ s/\-*$//g;
        $luser =~ tr/A-Za-z0-9\ @_.,\*\&\$\/\!\#-//dc;
        $luser = substr( "$luser", 0, 16 );
        $lip = "$ip1.$ip2.$ip3";
        $lorgname =~ s/^ *//;
        $lorgname =~ s/ *$//;
        # $luser = lc($luser);
        print "lorgname: '$lorgname', Country: '$cnty'\n" if ($debug);
        if (  $lcountry eq $cnty ) {
                $orgname = $lorgname;
                $cnt_accesses++;
                $usernames{$luser}++;

                $date = &ctime($time);
                $lccode = lc ($lstat);
                if ($deluxe) {
                        push (
                                @tbody,
                                qq|
                          <tr>
                            <td><a href="session_page_report.cgi?$time">$date</a></td>
                            <td><a href="byip.cgi?ip=$lip">$lip</a></td>
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
                            <td>$date</td>
                            <td><a href="byuser.cgi?user=$luser">$luser</a></td>
                            <td><a href="byip.cgi?ip=$lip">$lip</a></td>
                            <td><a class=\"status\" onClick='statushelp(\"$lccode\")'>$lstat</a></td>
                          </tr>
                        |
                        );
                } ## end else [ if ($deluxe)
        } ## end if ( $user eq $luser )
    }
} ## end foreach $logfile (@logfiles)

print "<h3>$cnt_accesses login attempts from <a class=\"status\" onClick=\"countryhelp('$cnty')\">$cnty</a> with ";
print scalar keys(%usernames) . " usernames</h3>\n\n<table>\n";
print "<tr><th>Date</th><th>Username</th></th><th>IP</th><th>Result</th></tr>\n\n";
print reverse(@tbody);
print "\n\n</table>\n\n";
print "<h3>$cnt_accesses login attempts from <a class=\"status\" onClick=\"countryhelp('$cnty')\">$cnty</a> with ";
print scalar keys(%usernames) . " usernames</h3>\n\n";

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



