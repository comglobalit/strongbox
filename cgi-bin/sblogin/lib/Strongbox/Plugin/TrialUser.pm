#===============================================================================
#
#         FILE:  Strongbox/Plugin/TrialUser.pm
#
#  DESCRIPTION: Plugin for Strongbox to treat trial users differently.
#
#       AUTHOR:  Elias Torres-Arroyo elias@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  12/02/2011 17:00 PM
#     REVISION:  ---
#===============================================================================

package Strongbox::Plugin::TrialUser;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.

use strict;
use warnings;

my $debug = $main::debug;

sub begin_checkpasswd_mysql {
    my ($class, $dbh) = @_;
    # Check the desired conditions in database to create a field called trial
    $main::dbinfo->{'extra_fields'} .= 'IF( ( initial_days < 31 AND recur_days < 31 ) ,1,0) AS trial, ';
    print "Changing extra_fields...\n" if ($debug);
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

    # Not a gooduser? go away!
    return 1 unless $return eq 'gooduser';

    if ($res->{'trial'}) {
      # Create a new session if not defined before
      $main::sbsession = 'sb' . &main::randstring(9) if ( $main::sbsession eq '00000000000' );
      # Create a flag directory to indicate that this user is trial
      # so we can check for it in .htaccess
      my $trialpath = "$sessionfiles/trials/$main::sbsession";
      print $res->{'username'} . " is a trial user, creating $trialpath\n" if ($debug);
      &main::mkpath($trialpath, 0777);
    }
    return (1, $return, $sessionfiles, $contents->{'goodpage'});
}

1;
