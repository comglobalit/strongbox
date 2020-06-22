#
#===============================================================================
#
#         FILE:  Strongbox/Plugin/NATSloginlog.pm
#
#  DESCRIPTION: Plugin for Strongbox to post to the NATS log of log ins
#
#       AUTHOR:  Ray Morris support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  05/25/2011 04:03:14 PM
#     REVISION:  ---
#===============================================================================

package Strongbox::Plugin::NATSloginlog;

# Path to loginlog script
# For NATS3: http://site.com/loginlog.php?siteid=1&
# For NATS4: http://site.com/member_loginlog.php?siteid=1&
# See http://wiki.toomuchmedia.com/index.php/Nats4_Member_Logging
#     http://wiki.toomuchmedia.com/index.php/NATS3_Member_Logging

my $url = 'http://site.com/pathToNATSLoginLogPHPscript/loginlog.php?siteid=1&';

use strict;
use warnings;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.


sub go_goodpage {
    my $class     = shift();
    my $args      = shift();
 
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(4);

    my $response = $ua->get($url . "username=$main::uname&ip=" . $main::ENV{'REMOTE_ADDR'} );

    unless ($response->is_success) {
        warn "could not GET '$url': " . $response->status_line;
    }
    return 1;
}


1;

