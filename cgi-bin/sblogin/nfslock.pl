#!/usr/bin/perl -w
 
# Date: 2005-09-21
 

 {
     my $lockpath = "./.htcookie/loglock";
     sub locklog {
         use POSIX;
         unlink $lockpath if ( (-f $lockpath) && (-M $lockpath > .0002) );

         $! = "";
         sysopen(FH, $lockpath, O_WRONLY | O_EXCL | O_CREAT);
         if ($!) {
             warn "Couldn't open lock file: $!" unless ($! =~ /^File exists/i);
         }
         until( sysopen(FH, $lockpath, O_WRONLY | O_EXCL | O_CREAT) ) {
             select(undef, undef, undef, 0.15);
         }
         close (FH);
         return 1;
      }

     sub unlocklog {
         unlink $lockpath if (-f $lockpath);
     }
 }


