#!/usr/bin/perl -w
 
# Date: 2009-10-12
 

use lib './lib';
use File::NFSLock qw(uncache);
use Fcntl qw(LOCK_EX LOCK_NB);

{
    my  $lockmgr;
    sub locklog {
        my $lockpath = './.htcookie/loglock';
        $lockmgr = LockFile::Simple->make(-format => $lockpath, -max => 20, -delay => 1, -nfs => 1, -hold => 30, -stale => 1);
        $lockmgr->lock('./.htpasslog') || die "can't lock .htpasslog\n";
    }

    sub unlocklog {
         $lockmgr->release;
    }
}


{
    my $lock;
    sub locklog {
        $lock = new File::NFSLock { file => '.htpasslog', lock_type => LOCK_EX,
                                 blocking_timeout => 6, stale_lock_timeout => 20 }
                or die "could not lock .htpasslog: $!";
    }


    sub unlocklog {
        $lock->unlock();
    }
}

1;

