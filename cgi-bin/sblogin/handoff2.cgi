#!/usr/bin/perl

# StrongBox version 2.8
# Copyright 2001 - 2012
# Ray Morris <support@bettercgi.com>
# All rights reserved.


# usage:
# handoff2.cgi?site=site.com[&path=/path/if/not/default/][&u=user]
#
# Incoming URL:
# http://www.site.com/cgi-bin/sblogin/handoff2.cgi?n=1088106084&t=18cbb4205ec5971&t2=8cc845ec9571ac[&u=user]




require './config.pl';
require './time.pl';
require './routines.pl';
require './custom_subs.pl';
# require './nfslock.pl';

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



print "QUERY_STRING: $ENV{'QUERY_STRING'}\n" if ($debug);
my $cgi = &parse_query();

if ( grep(/^$ENV{'REMOTE_ADDR'}/, @trustedips) ) {
    print "REMOTE_ADDR $ENV{'REMOTE_ADDR'} is trusted\n" if ($debug);
    $ENV{'REMOTE_ADDR'} = $cgi->{'remote_addr'} if ($cgi->{'remote_addr'});
    $ENV{'HTTP_USER_AGENT'} = $cgi->{'user_agent'} if ($cgi->{'user_agent'});
    $ENV{'HTTP_ACCEPT'} = $cgi->{'accept'} if ($cgi->{'accept'});
    if ($ENV{'HTTP_X_FORWARDED_FOR'} =~ m/([0-9\.]+)\s*$/) {
         $ENV{'REMOTE_ADDR'} = $1;
    }
}


if ($ENV{'HTTP_USER_AGENT'} =~ m/PLAYSTATION/) {
    $ENV{'HTTP_ACCEPT'} = 'ImAStupidPlaystation' unless ($ENV{'HTTP_ACCEPT'});
}
$ENV{'HTTP_ACCEPT'} = '*/*' if ($ENV{'HTTP_USER_AGENT'} =~ m/Android 2\.2/);

if ( (length($ENV{'HTTP_USER_AGENT'}) < 5) || (length($ENV{'HTTP_ACCEPT'}) < 3) ) {
    print "Location: $errpage\n\n";
    exit 1;
}
my $now = gettime();


if ($cgi->{'t'}) {
    &receive;
} else {
    &handoff;
}
exit 1;



####################################




sub handoff {
    my $sbsession = $1 if ($ENV{'HTTP_COOKIE'} =~ m/sbsession\ ?=\ ?([a-zA-Z0-9]*)/);
    $sbsession    = $1 if (  $ENV{'HTTP_REFERER'} =~ m/^(sb[a-zA-Z0-9]+)\./);
    $sbsession    = $ENV{'sbsession'} if ($ENV{'sbsession'});
    $sbsession    = $1 if (  $ENV{'HTTP_HOST'} =~ m/^(sb[a-zA-Z0-9]+)/  );
    $sbsession    = $main::sbsession if ($main::sbsession);

    $ENV{'QUERY_STRING'} =~ s/\&site=[^&]*//g;
    $ENV{'QUERY_STRING'} =~ s/^site=[^&]*//g;
    $ENV{'QUERY_STRING'} =~ s/\&PHPSESSID=[^&]*//g;
    $ENV{'QUERY_STRING'} =~ s/^PHPSESSID=[^&]*//g;
    $ENV{'QUERY_STRING'} =~ s/^site_id=[^&]*//g;
    $cgi->{'path'} = $ENV{'PATH_INFO'} if ($ENV{'PATH_INFO'});
    $ENV{'QUERY_STRING'} .= "&" if ($ENV{'QUERY_STRING'});
    $ENV{'QUERY_STRING'} .= "path=$ENV{'PATH_INFO'}" if ($ENV{'PATH_INFO'});

    $site_id = $cgi->{'siteid'} if ($cgi->{'siteid'});
    $cgi->{'site'} =~ s/http:\/\///;
    if ($cgi->{'site'} =~ m/(\/.*)/) {
        $cgi->{'path'} = $1 unless ($cgi->{'path'});
        $cgi->{'site'} =~ s/(\/.*)//;
    }

    my $user_agent = $ENV{'HTTP_USER_AGENT'};
    $user_agent =~ s/\n|\r//g;
    $user_agent =~ s/\.\.\///g;
    $user_agent = substr($user_agent, 0, 250);

    my $accept = $ENV{'HTTP_ACCEPT'};
    $accept =~ s/\n|\r//g;
    $accept =~ s/\.\.\///g;
    $accept = substr($accept, 0, 250);

    &do_plugins('handoff_presessionfiles', $sessionfiles, $sbsession);

    unless ( 
               (-d "$sessionfiles/$sbsession.$host/" . $user_agent) ||
               (-f "$sessionfiles/$sbsession.$host/$ENV{'REMOTE_ADDR'}" )
           ) {
            print "Location: $errpage\n\n";
            exit 1;
    }

    ($pname,$add1,$add2,$add3,$remote_country,$orgname)    = &sbsession2user($sbsession);
    my $details = &urlencode( join(':', $pname,$add1,$add2,$add3,$remote_country,$orgname) ) if ($pname);
    $details = "&d=$details&dt=" . md5_hex( $now . $key . join(':', $pname,$add1,$add2,$add3,$remote_country,$orgname) ) if ($details);
    $site_id = '' if ($site_id == 1);
    my $ticket = md5_hex($now . $key . $ENV{'REMOTE_ADDR'} . $site_id);
    my $browser_sig = "$ENV{'HTTP_USER_AGENT'}/$ENV{'HTTP_ACCEPT'}";
    my $ticket2 = md5_hex($now . $key . $browser_sig . $site_id );
    print "Location: http://$cgi->{'site'}/cgi-bin/sblogin/handoff2.cgi?n=$now&t=$ticket&t2=${ticket2}${details}&$ENV{'QUERY_STRING'}\n\n";
}



###############
# http://www.site.com/cgi-bin/sblogin/handoff2.cgi?n=1088106084&t=18cbb4205ec9571&t2=8cc845ec9571ac
sub receive {
    $sbsession = "000000000";
    $goodpage = $cgi->{'path'} if ($cgi->{'path'});
    $goodpage .= "#" . $cgi->{'anchor'} if ($cgi->{'anchor'});
    $uname = $cgi->{'u'};
    my $query = $ENV{'QUERY_STRING'};
    $query =~ s/^&*n=[^&]*//g;
    $query =~ s/^&*dt=[^&]*//g;
    $query =~ s/^&*t=[^&]*//g;
    $query =~ s/^&*t2=[^&]*//g;
    $query =~ s/^&*u=[^&]*//g;
    $query =~ s/^&*site=[^&]*//g;
    $query =~ s/^&*path=[^&]*//g;
    $query =~ s/^&*d=[^&]*//g;
    $query =~ s/^&*dt=[^&]*//g;
    $query =~ s/^&*path=[^&]*//g;
    $query =~ s/^&*site_id=[^&]*//g;
    $query =~ s/^&*//g;
    $query =~ s/&*$//g;
    $goodpage .= "?" . $query if ($query);
    print "goodpage = $goodpage" if ($debug);
     
    $site_id = $cgi->{'site_id'} if ($cgi->{'site_id'}); 
    $site_id = '' if ($site_id == 1);
    print "ticket: md5_hex($cgi->{'n'} . $key . $ENV{'REMOTE_ADDR'} . $cgi->{'site_id'})\n" if ($debug);
    my $ticket = md5_hex($cgi->{'n'} . $key . $ENV{'REMOTE_ADDR'} . $cgi->{'site_id'});

    my $browser_sig = "$ENV{'HTTP_USER_AGENT'}/$ENV{'HTTP_ACCEPT'}";
    my $ticket2 = md5_hex($cgi->{'n'} . $key . $browser_sig . $cgi->{'site_id'});

    $site_id = 1 if ($site_id eq '');
    if ($cgi->{'n'} + 1800 < $now) {
        print "time too old, \$cgi->{'n'}: $cgi->{'n'}, $now: $now\n" if ($debug);
        print "Location: $errpage\n\n"; 
    } elsif ( ($cgi->{'t'} ne $ticket) && ($cgi->{'t2'} ne $ticket2) ) {
        print "ticket invalid, \$cgi->{'t'}: $cgi->{'t'}, ticket: $ticket\n" if ($debug);
        print "Location: $errpage\n\n";
    } else {
        $sbsession = "sb" . &randstring(9);
        if ( $cgi->{'dt'} eq md5_hex($cgi->{'n'} . $key . $cgi->{'d'}) ) {
               ($pname,$add1,$add2,$add3,$remote_country,$orgname) = split(':', $cgi->{'d'});
               print "pname: $pname, uname: $uname\n" if ($debug);
               unless ($uname) {
                   $pname =~ m/(.*?)\.*$/;
                   $uname = $1;
               }
               $remote_country = 'XX' unless ($remote_country);
               $orgname = 'xx' unless ($orgname);
               &openlog();
               &writelog('goodhndf');
               &close_log;
        }
        $ENV{'HTTP_USER_AGENT'} =~ s/\n|\r//g;
        $ENV{'HTTP_USER_AGENT'} =~ s/\.\.\///g;
        $ENV{'HTTP_ACCEPT'} =~ s/\n|\r//g;
        $ENV{'HTTP_ACCEPT'} =~ s/\.\.\///g;

        $ENV{'HTTP_USER_AGENT'} = substr($ENV{'HTTP_USER_AGENT'}, 0, 250);
        $ENV{'HTTP_ACCEPT'} = substr($ENV{'HTTP_ACCEPT'}, 0, 250);

        &go_goodpage($sbsession);
        # go_goodpage will call go_goodpage_custom($sbsession), which will alter variables 
        # before calling back to the default go_goodpage();
        # That will look something like:
        # sub go_goodpage_custom {
        #     if ($site_id eq 'trial') {
        #         $sessionfiles = './htcookie_trial';
        #         $goodpage = '/trial/' if ($goodpage =~ /\/members\//);
        #     }
        #     return &go_goodpage($sbsession);
        # }
    }
}

######################


sub sbsession2user {
    my $sbsession = $_[0];
    &openlog();
    $startpos=$recchk * $reclen * -1;
    if ( ($recchk * $reclen) > (-s LOG) ) {
        seek(LOG, 0, 0);
    } else {
        seek(LOG,$startpos,2);
    }

    my $line = <LOG>;
    while ($line = <LOG>) {
        chomp($line);
        my ($lname,$trash1,$ladd1,$ladd2,$ladd3,$trash2,$lsession,$lcountry, $lorgname)=split(/\:/,$line);
        if ($lsession eq $sbsession) {
            ($pname,$add1,$add2,$add3,$remote_country,$orgname) = 
            ($lname,$ladd1,$ladd2,$ladd3,$lcountry, $lorgname);
            last;
        }
    }
    print "($pname,$add1,$add2,$add3,$remote_country,$orgname)\n" if ($debug);
    return ($pname,$add1,$add2,$add3,$remote_country,$orgname);
}



######################


__END__


    220         $fromcountry{$country}++ unless ($country eq 'XX');
    222         $orgs{$orgname}++ unless ($orgname eq 'xx');

openlog();

# sub writelog {
    $logstat = "$_[0]";
    my $time = time();
    $logstat = substr( "$logstat........", 0, 8 );
    seek( LOG, 0, 2 );
    print LOG
"$pname:$time:$add1:$add2:$add3:$logstat:$sbsession:$remote_country:$orgname\n";


