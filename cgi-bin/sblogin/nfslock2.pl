#!/usr/bin/perl -w
 
# Date: 2009-10-12
 
use lib './lib';
use lib '../lib';

use LockFile::Simple qw(lock trylock unlock);

{
    my  $lockmgr;
    sub locklog {
        my $lockpath = './.htcookie/loglock';
        $lockmgr = LockFile::Simple->make(-format => $lockpath, -max => 20, -delay => 1, -nfs => 1, -hold => 30, -stale => 1);
        $lockmgr->lock('./.htpasslog') || die "can't lock .htpasslog\n";
    }

    sub unlocklog {
        return unless defined($lockmgr);
        $lockmgr->unlock('./.htpasslog');
    }
}


1;

