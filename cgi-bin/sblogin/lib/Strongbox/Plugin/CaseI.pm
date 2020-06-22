#
#===============================================================================
#
#         FILE:  Strongbox/Plugin/CaseI.pm
#
#  DESCRIPTION: Plugin for Strongbox to make user names and passwords not case sensitive, 
#  by upper casing whatever is entered. A matching modification to the processor's script 
#  is normally required.
#
#       AUTHOR:  Ray Morris support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  05/04/2010 04:03:14 PM
#     REVISION:  ---
#===============================================================================

# FIXME: this has end_parse_query defined twice, and there seems to be 
# no correct hook for altering the SQL.

package Strongbox::Plugin::CaseI;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.

use strict;
use warnings;

my $debug = $main::debug;

sub end_parse_query {
    my ($class, $sql) = @_
    $sql =~ s/ENCRYPT\(\?/ENCRYPT(UPPER(?)/ if ( Strongbox::CaseI->can('can') );
}

sub end_parse_query {
    my ($class, $cgi) = @_;
    $cgi->{'uname'} = uc($cgi->{'uname'});
    $cgi->{'pword'} = uc($cgi->{'pword'});
    $cgi->{'user'} = uc($cgi->{'user'});
    return (1, $cgi);
}


sub begin_checkpasswd_mysql {
    my ($class, $dbh) = @_;
    $main::mysql_where .= 'AND first_use IS NULL OR ( DATE_ADD(first_use, INTERVAL sub_length DAY) > NOW() )';
    return (1);
}

sub end_checkpasswd_mysql {

    my $contents    = $main::contents;
    my $class               = shift();
    my $res                 = shift();
    my $dbh                 = shift();
    my $sth                 = shift();
    my $return_ref              = shift();
    my $sessionfiles_ref        = shift();
    $cgi->{'goodpage'} = shift();

    return (1, $return, $sessionfiles, $contents->{'goodpage'}) unless ($return =~ /^good/);

    my $sql = "UPDATE $main::mysql_table SET first_use=NOW() WHERE $main::mysql_ckuser=? AND first_use IS NULL";
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute($main::uname);
    $sth2->finish();

    return (1, $return, $sessionfiles, $contents->{'goodpage'});
}

1;

