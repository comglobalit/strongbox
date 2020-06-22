#===============================================================================
#
#         FILE:  Strongbox/Plugin/RedirExpired.pm
#
#  DESCRIPTION: Plugin for Strongbox to treat trial users differently.
#
#       AUTHOR:  Elias Torres-Arroyo elias@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  05/02/2012 17:50 PM
#     REVISION:  ---
#===============================================================================

package Strongbox::Plugin::RedirExpired;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.

use strict;
use warnings;

my $debug = $main::debug;


my $redirect_expired_page="https://join.titanmen.com/signup/signup.php";


sub begin_checkpasswd_mysql {
    my ($class, $dbh) = @_;
    # Get the other field
    $main::dbinfo->{'extra_fields'} .= 'expired, username , ';
    print "Changing extra_fields...\n" if ($debug);
    return 1;
}

sub end_checkpasswd_mysql {

    my $contents    = $main::contents;
	my ($class, $res, $dbh, $sth, $return, $sessionfiles ) = ($_[0], $_[1], $_[2], $_[3], \$_[4], $_[5]);
    $contents->{'goodpage'} = shift();

    if ($res->{'expired'}) {
      print $res->{'username'} . " is expired\n" if ($debug);
      print "setting status to 'badpuser' and sending it to $redirect_expired_page\n" if ($debug);
	  $$return = 'badpuser';
      $main::errpage = $redirect_expired_page;
    }
    return 1;
}

1;
