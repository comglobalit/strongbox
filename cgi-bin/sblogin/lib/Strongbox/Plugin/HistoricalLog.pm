#
#===============================================================================
#
#         FILE:  Strongbox/Plugin/HistoricalLog.pm
#
#  DESCRIPTION: Plugin for Strongbox to keep logs of successful logins for about two years
#
#       AUTHOR:  Ray Morris support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  12/10/2010 05:55:00 PM
#     REVISION:  ---
#===============================================================================

package Strongbox::Plugin::HistoricalLog;

# Pass references if needed. They can be altered and passed to the next plugin 
# in turn.  The first argument returned tells whether to continue processing this hook.
# return 1 to continue to the next plugin, 0 to stop the loop.

use strict;
use warnings;

my $debug = 0;

undef &trimloginlog;
sub trimloginlog {
    my ($class, $logfile, $maxlogsize) = @_;
    my $hlogfile = $logfile . '_hist';
    my $newstart = (-s $logfile) - ($maxlogsize / 2);
    return unless ($newstart > 0);
    if (  (rand(10) > 9) && ( (-s $hlogfile) > ($maxlogsize * 50) )  ) {
        &trimarchivelog($hlogfile, $maxlogsize);
    }

    open HLOG, ">>$hlogfile" or die "could not open '$hlogfile': $!";
    open RLOG, "<$logfile" or die "could not open '$logfile': $!";
    my $garbage = <RLOG>;
    while( ( tell(RLOG) < $newstart ) && (my $line = <RLOG>) ) {
        print HLOG $line if ($line =~ m/\:good/i);
    }
    close HLOG;
    open WLOG, "+<$logfile" or die "could not open '$logfile': $!";
    while( <RLOG> ) {
        print WLOG;
    }
    close RLOG;
    truncate WLOG, tell WLOG;
    close WLOG;
    return (0, $logfile, $maxlogsize);
}

sub trimarchivelog {
    my ($logfile, $maxlogsize) = @_;
    # Trim the historical archive log
    my $newstart = (-s $logfile) - ($maxlogsize * 25);
    return unless ($newstart > 0);
    open RLOG, "<$logfile" or die "could not open '$logfile': $!";
    open WLOG, "+<$logfile" or die "could not open '$logfile': $!";
    seek(RLOG, $newstart, 0);
    my $garbage = <RLOG>;
    while(<RLOG>) {
        print WLOG;
    }
    close RLOG;
    truncate WLOG, tell WLOG;
    close WLOG;
    return 0;
}

sub report_pre_read_log {
    my $cgi = shift();
    return unless ($cgi->{'begin_month'});

    $begin_date = "$cgi->{'begin_month'}/$cgi->{'begin_day'}/$cgi->{'begin_year'}";
    $begin = timegm(0,0,0,$cgi->{'begin_day'},$cgi->{'begin_month'} -1,$cgi->{'begin_year'});
    if (  $begin < ( time() - (10 * 24 * 60 *  60) )  ) {
        unshift(@logfiles, '../.htpasslog_hist');
    }
    return 1;
}


1;

