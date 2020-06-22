#!/usr/bin/perl

# StrongBox version 2.3
# Copyright 2001, 2002, 2003, 2004, 2005, 2006, 2007
# Ray Morris <support@webmastersguide.com>
# All rights reserved.


require './config.pl';
require './routines.pl';

BEGIN {
        eval {
                require Digest::MD5;
                import Digest::MD5 'md5_hex'
        };
      if ($@) {
            eval {
                require Digest::Perl::MD5;
                import Digest::Perl::MD5 'md5_hex'
            }
      }
      if ($@) { # no Digest::Perl::MD5 either
            eval {
                    use lib '.';
                    require MD5;
                    import MD5 'md5_hex';
                }
      }
      if ($@) { # no Digest::Perl::MD5 either
          die "I can't find any MD5 module anywhere, not even the pure perl one: $!";
      }
}


print "Content-type: text/plain\n\n";

my $cgi = &parse_query();
&checkinput;


my $ticket = md5_hex( $cgi->{'uname'} . substr($key,0,6) );

unless ($ticket eq $cgi->{'ticket'}) {
    print "Tickets don't match\n$ticket\n";
    exit 1;
}


($add1, $add2, $add3, $sbsession, $remote_country, $orgname) =  ('000','000','000','00000000000','XX','xx');
&openlog();
&writelog('dis_spdr');
&close_log;

print $cgi->{'uname'}, " disabled.\n";
exit 1;


#####################################


sub checkinput {

    $uname=$cgi->{'uname'} unless ($uname);
    print "\$uname: $uname\n" if ($debug);
    $uname =~ s/\n+//g;
    $uname =~ s/^\s+//;
    $tname=$uname;
    $tname=~ tr/A-Za-z0-9\ @_.,\*\&\$\/\!\#-//dc;
    $pname=substr("$tname..........................",0,16);
    if (($uname =~ tr/[\040-\177\200-\376]//dc) || ($pword =~ tr/[\040-\177\200-\376]//dc)) {
        &errlog('badchars');
    }

    if ($uname eq '') {
        &errlog('emptyUrP');
    }
}



#####################################


