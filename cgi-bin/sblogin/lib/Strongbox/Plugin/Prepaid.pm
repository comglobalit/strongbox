#
#===============================================================================
#
#         FILE:  Strongbox/Plugin/Prepaid.pm
#
#  DESCRIPTION: Plugin for Strongbox to initiate prepaid, time limited memberships.
#
#       AUTHOR:  Ray Morris support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  04/21/2010 04:03:14 PM
#     REVISION:  ---
#===============================================================================

package Strongbox::Plugin::Prepaid;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.

use strict;
use warnings;

my $debug = $main::debug;

sub begin_checkpasswd_mysql {
    my ($class, $dbh) = @_;
    $main::mysql_where .= 'AND first_use IS NULL OR ( DATE_ADD(first_use, INTERVAL sub_length DAY) > NOW() )';
    return 1;
}

sub end_checkpasswd_mysql {

    my $contents    = $main::contents;
    my $class               = shift();
    my $res                 = shift();
    my $dbh                 = shift();
    my $sth                 = shift();
    my $return              = shift();
    my $sessionfiles        = shift();
    $contents->{'goodpage'} = shift();

    return (1, $return, $sessionfiles, $contents->{'goodpage'}) unless ($return =~ /^good/);

    my $sql = "UPDATE $main::mysql_table SET first_use=NOW() WHERE $main::mysql_ckuser=? AND first_use IS NULL";
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute($main::uname);
    $sth2->finish();

    return (1, $return, $sessionfiles, $contents->{'goodpage'});
}

1;

