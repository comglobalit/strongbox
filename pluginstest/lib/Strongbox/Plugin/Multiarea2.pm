#
#===============================================================================
#
#         FILE:  Strongbox/Plugin/Multiarea.pm
#
#  DESCRIPTION: Plugin for Strongbox to do trial areas or multiple sites per domain. 
#
#       AUTHOR:  Ray Morris support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  04/21/2010 04:03:14 PM
#     REVISION:  ---
#===============================================================================

package Strongbox::Plugin::Multiarea2;

use strict;
use warnings;


sub printhi {
   my $class = shift();
   print "hello world $class\n";
}

# In most cases, pass references so they can be altered and 
# passed to the next plugin in turn.  return 0 to continue to 
# next plugin, 1 to stop the loop.

sub say {
    my $class = shift();
    my $msg = shift();
    my $nameref = shift();

    $$nameref = 'ray';
    print "saying $msg\n";
    return (0, 'said');
}

1;

