#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  nfslock4.pl
#
#        USAGE:  ./nfslock4.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/01/2011 10:44:39 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;


use lib './lib';
use lib '../lib';

{
    use File::NFSLock qw(uncache);
    use Fcntl qw(LOCK_EX LOCK_NB);

    my $lock;
    sub locklog {
        my $lockfile = "$main::sessionfiles/locklog";
        $lockfile = "../$main::sessionfiles/locklog" unless ( -e $main::sessionfiles);
        $lock = new File::NFSLock { file => $lockfile, lock_type => LOCK_EX,
                                 blocking_timeout => 6, stale_lock_timeout => 20 }
                or die "could not lock '$lockfile': $!";
    }


    sub unlocklog {
        $lock->unlock();
    }
}


1;


