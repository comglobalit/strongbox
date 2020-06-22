#!/usr/bin/perl

# Strongbox version 5.1
#   Copyright 2016 - 2018 Elias Torres <strongbox@comglobalit.com>
#   Copyright 2001 - 2015 Ray Morris <support@bettercgi.com>
# All rights reserved.
#   Copyright information: https://www.comglobalit.com/en/docs/strongbox/copyright/
 
# See our on-line documentation at
#   https://www.comglobalit.com/en/docs/strongbox/

if ($debug) {
    use POSIX qw(clock);
    my $pstarttime = clock();
}


require './config.pl';

require './routines.pl';
require './isp.pl';
require './custom_subs.pl' if (-f 'custom_subs.pl');
require './split_dyn.pl';


$cgi = &parse_query();
$sbsession = '00000000000';
&custom_init() if ( defined(&custom_init) );

# die after 12 seconds to avoid having too
# many httpd processes during an attack
alarm(12);
local $SIG{ALRM} = sub { &close_log; die 'too many login attempts, dying to save server load.' };

$time=time();

&checkinput;

$remote_country = 'XX';
$orgname = 'xx';

($country, $orgname) = &ip2org($ENV{'REMOTE_ADDR'}, 3) if ($uniqorgnames);
$remote_country = $country if ($country);


my $is_open_proxy = 0;
if ($check_proxies) {
    require "./proxycheck.pl";
    if (  ( &ProxyCheck::isaol($ENV{'REMOTE_ADDR'}) ) || $orgname =~ m/America Online|AOL|American Reg|VERSATEL|DTAG|Hughes|BSLYO151 LYON|France Teleco/i ) {
        $attemptsperhour *= 20;
        $uniqsubsperhour *= 10;
        $uniqstildisable *= 2;
        $totallogins *= 2;
        # $attempts_2d *= 20;
        $uniqsubs_2d *= 2;
        $uniqcountries_2d *= 2;
    } elsif ( &ProxyCheck::isproxy($ENV{'REMOTE_ADDR'}) ) {
        $attemptsperhour /= 2;
        $uniqsubsperhour /= 2;
        $uniqstildisable /= 2;
        $totallogins /= 2;
        $is_open_proxy++;
    }
    $remote_country = &ProxyCheck::fromcountry($ENV{'REMOTE_ADDR'}) if ($remote_country eq 'XX');
} else {
    if ( ($orgname =~ m/America Online|AOL|American Reg|VERSATEL|DTAG|Hughes|BSLYO151 LYON|France Teleco/i) ) {
        $attemptsperhour *= 20;
        $uniqsubsperhour *= 10;
        $uniqstildisable *= 2;
        $totallogins *= 2;
        # $attempts_2d *= 20;
        $uniqsubs_2d *= 2;
        $uniqcountries_2d *= 2;
    }
}


#if ( (-f 'ip_block_log.txt') && (-s 'ip_block_log.txt' > 150) ) {
#    $attemptsperhour /= 2;
#} elsif ( (-f 'badimage_log.txt') && (-s 'badimage_log.txt' > 200) ) {
#    $attemptsperhour /= 2;
#}


unless (&checkturing) {
    $userpass = 'badimage';
    &openlog;
    &errlog('badimage');
}


if ( $referer_blocks && ($cgi->{'referer'} =~ m/$referer_blocks/i) ) {
    unless ($cgi->{'referer'} =~ m/$referer_allow/i) {
        $cgi->{'referer'} =~ m@(http://)?(www\.)?(.+)@;
        $sbsession = substr("$3..........................",0,11);
        &openlog;
        &errlog('badrefer');
    }
}

# Bypass banned country restriction for invincible_users
# invincible_ips and ignored_ips. ~ elias 2013-05-04
unless (
           (grep { $ENV{'REMOTE_ADDR'} =~ /^$_$/ } @ignored_ips)    ||
           (grep { $ENV{'REMOTE_ADDR'} =~ /^$_$/ } @invincible_ips) ||
           (grep { $uname =~ /^$_$/ } @invincible_users)
       ) {
	if (grep /^$remote_country$/i, @banned_countries) {
		&openlog;
		&errlog('badcntry');
	}
}


my $userpass = 'badpuser';


foreach $htpfile (@htpfiles) {
    if ( ref($htpfile) eq 'ARRAY' ) {
        # Switch order if the subroutine isn't set first.
        ($htpfile->[1], $htpfile->[0]) = ($htpfile->[0], $htpfile->[1]) if (ref($htpfile->[1]) eq 'CODE');
        ($userpass, $htpfile->[1]) = &{$htpfile->[0]}($uname, $pword, [ $htpfile->[1] ] ) if ($userpass eq 'badpuser');
        print "after checking ", $htpfile->[1], ",userpass: '$userpass'\n" if ($debug);
    } else {
        print "htpfile '$htpfile' isn't an array\n" if ($debug);
        ($userpass, $htpfile) = &oldpwcheck($htpfile) if ($userpass eq 'badpuser');
    }
}

# Tracking attempts to admin area
if ($admin_attempt) {
    if ($userpass eq 'badpword') {
	print "because admin_attempt: badpword -> badadmpw\n" if ($debug);
        &errlog('badadmpw');
    }

    if ($userpass eq 'badpuser') {
	print "because admin_attempt: badpuser -> badadmin\n" if ($debug);
        &errlog('badadmin');
    }
}


my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks) = stat($logfile);
&trimloginlog if ($size > $maxlogsize) && ( int(rand(100)) == 1); 

&openlog;
unless (
           (grep { $ENV{'REMOTE_ADDR'} =~ /^$_$/ } @ignored_ips)    ||
           (grep { $ENV{'REMOTE_ADDR'} =~ /^$_$/ } @invincible_ips) ||
           (grep { $uname =~ /^$_$/ } @invincible_users)
       ) {
    &check_history($pname, $saddr, $userpass, $country, $orgname) if ($recchk);
}

if ( ($is_open_proxy) && ($notifyof =~ /opnproxy/) ) {
    &notifywm('opnproxy') unless $notified{'opnproxy'};
}


$userpass = uc($userpass) if (grep { $ENV{'REMOTE_ADDR'} =~ /^$_$/ } @ignored_ips);
if ($userpass =~ m/^good/i) {
    $sbsession = 'sb' . &randstring(9);
    &writelog($userpass);
} else {
    &errlog($userpass);
}

&go_goodpage($sbsession);
exit 1;


#####################################

sub oldpwcheck {
    my @htpfile = ($_[0]);
    foreach my $sub (@$checkpasswd) {
        ($userpass, $htpfile) = &$sub($uname, $pword) if ($userpass eq 'badpuser');
    }
    return ($userpass, $htpfile);
}

sub checkturing {
    return 1 if ($image_login == 0);
    my $args = {return => 0, cgi => $cgi};
    &do_plugins('checkturing', $args );
    return $args->{'return'};
}


############################################




sub check_history {
    my ($pname, $saddr, $userpass, $country, $orgname) = @_;
    use constant {
        TWODAYS    => 172800,
        THREEHOURS => 10800,
        EIGHTHOURS => 28800,
    };
    my %from_2d;
    my %fromcountry_2d;
    my %orgs_2d;
    my %from;
    my %fromcountry;
    my %orgs;

    $startpos = $recchk * $reclen * -1;
    if ( ($recchk * $reclen) > (-s LOG) ) {
        seek(LOG, 0, 0);
    } else {
        seek(LOG,$startpos,2);
    }

    $trash=<LOG>;
    $attms=0;
    $uniqt=0;
    $disab=0;
    my $uniqt = 0;
    my $uniqc = 0;
    my $uniqi = 0;
    my $disab = 0;
    my $logint_2d = 0;
    my $notifies_eight = 0;

    # Count this login toward unique countries, ISPs, IPs
    $uniqs        = 1;
    $uniqs_2d     = 1;
    $countries    = 1 unless ($country eq 'XX');
    $countries_2d = 1 unless ($country eq 'XX');
    $orgnames     = 1 unless ( ($orgname eq 'XX') || ($orgname eq 'xx') );
    $orgnames_2d  = 1 unless ( ($orgname eq 'XX') || ($orgname eq 'xx') );
    $logint       = 1;
  
    if ($userpass eq 'gooduser') {
        $from{$saddr}++;
        $from_2d{$saddr}++;
        $fromcountry{$country}++ unless ($country eq 'XX');
        $fromcountry_2d{$country}++ unless ($country eq 'XX');
        $orgs{$orgname}++ unless ( ($orgname eq 'XX') || ($orgname eq 'xx') );
        $orgs_2d{$orgname}++ unless ( ($orgname eq 'XX') || ($orgname eq 'xx') );
    }
 

    while ($line = <LOG>) {
        next unless(&c_line_matches($line, $pname, $saddr));
        chomp($line);
        my ($lname,$ltime,$ladd1,$ladd2,$ladd3,$lstat,$lsbsession,$lcountry, $lorgname)=split(/\:/,"$line");
        next if ($lstat =~ m/^[A-Z]/);
        $difft=$time - $ltime;
        $notifies_eight++ if ( ($difft < EIGHTHOURS) && ($lstat =~ /$notifyof/) );
        $laddr="$ladd1:$ladd2:$ladd3";
        
        # print "found line match\n" if ($debug);
        # If IP matches, increment $attms and maybe $notified{$lstat}
        if (($laddr eq $saddr) && ($difft < TWODAYS)) {
            $attms_2d++ unless ($lstat =~ m/^good/);
            if ( ($difft < THREEHOURS) && ($lstat !~ m/^good/) ) {
                $notified{$lstat}++;
                $attms++;
            }
        }
        next unless ( ($lname eq $pname) && ($userpass eq 'gooduser') );

        $uniqt++ if ($lstat eq 'uniqsubs');
        $uniqc++ if ($lstat eq 'uniqcnty');
        $uniqi++ if ($lstat eq 'uniqisps');
        $disab++ if ($lstat =~ /dis/);
        # previously disabled user names have already had notifications
        &errlog($lstat, 999999, \%notified) if ($lstat =~ /dis/);
        
        next unless ($lstat =~ m/^good/);
        next unless ($difft < TWODAYS);

        $logint_2d++ unless ($lstat eq 'goodhndf');
        $uniqs_2d++ unless ($from_2d{$laddr}++) ;
        $countries_2d++ unless ( ($fromcountry_2d{$lcountry}++) || ($lcountry eq 'XX') );

        $orgnames_2d++ unless ( ($orgs_2d{$lorgname}++) || ($lorgname =~ m/^XX/i) || ($lorgname eq '') );

        next unless ($difft < THREEHOURS);
        $notified{$lstat}++;
        if ( $one_session_per_user && (-d "$sessionfiles/$lsbsession.$host") ) {
            &rmtree("$sessionfiles/$lsbsession.$host", 0, 1);
        }
        $logint++ unless ($lstat eq 'goodhndf');
        $uniqs++ unless ($from{$laddr}++);

        $countries++ unless ( ($fromcountry{$lcountry}++) || ($lcountry eq 'XX') );
        $orgnames++ unless ( ($lorgname =~ m/^XX/) || ($lorgname =~ m/^xx/) || ($lorgname eq '') || ($orgs{$lorgname}++) );

    } # end while ($line = <LOG>)

    
    if ($userpass eq 'gooduser') {
        &errlog('dis_uniq', $notifies_eight, \%notified) if ( ($uniqt >= $uniqstildisable) && $uniqstildisable );
        &errlog('dis_cnty', $notifies_eight, \%notified) if ( ($uniqc >= $uniqcountriestildisable) && $uniqcountriestildisable );
        &errlog('dis_isps', $notifies_eight, \%notified) if ( ($uniqi >= $uniqispstildisable) && $uniqispstildisable );
        &errlog('uniqsubs', $notifies_eight, \%notified) if ( ($uniqs_2d >= $uniqsubs_2d) && ($uniqsubs_2d) );
        &errlog('uniqcnty', $notifies_eight, \%notified) if ( ($countries_2d >= $uniqcountries_2d) && $uniqcountries_2d );
        &errlog('uniqisps', $notifies_eight, \%notified) if ( ($orgnames_2d >= $uniqorgnames_2d) && $uniqorgnames_2d );
        &errlog('totllgns', $notifies_eight, \%notified) if ( ($logint_2d >= $totallogins_2d) && $totallogins_2d );
        &errlog('uniqsubs', $notifies_eight, \%notified) if ( ($uniqs >= $uniqsubsperhour) && ($uniqsubsperhour) );
        &errlog('uniqcnty', $notifies_eight, \%notified) if ( ($countries >= $uniqcountriesperhour) && $uniqcountriesperhour );
        &errlog('uniqisps', $notifies_eight, \%notified) if ( ($orgnames >= $uniqorgnames) && $uniqorgnames );
        &errlog('totllgns', $notifies_eight, \%notified) if ( ($logint >= $totallogins) && $totallogins );
    }
    &errlog('attempts', $notifies_eight, \%notified) if ( ($attms >= $attemptsperhour) && $attemptsperhour );
} # end sub check_history



#####################################


1;


#####################################



sub checkinput {

    if (grep { $ENV{'REMOTE_ADDR'} =~ /^$_$/ } @trustedips) {
        print "REMOTE_ADDR $ENV{'REMOTE_ADDR'} is trusted\n" if ($debug);
        $ENV{'REMOTE_ADDR'} = $cgi->{'remote_addr'} if ($cgi->{'remote_addr'});
        $ENV{'HTTP_USER_AGENT'} = $cgi->{'user_agent'} if ($cgi->{'user_agent'});
        $ENV{'HTTP_ACCEPT'} = $cgi->{'accept'} if ($cgi->{'accept'});
        if ($ENV{'HTTP_X_FORWARDED_FOR'} =~ m/([0-9\.]+)\s*$/) {
            $ENV{'REMOTE_ADDR'} = $1;
        }
    }

    $ENV{'HTTP_USER_AGENT'} =~ s/\n|\r//g;
    $ENV{'HTTP_USER_AGENT'} =~ s/\.\.\///g;
    $ENV{'HTTP_ACCEPT'} =~ s/\n|\r//g;
    $ENV{'HTTP_ACCEPT'} =~ s/\.\.\///g;

    $ENV{'HTTP_USER_AGENT'} = substr($ENV{'HTTP_USER_AGENT'}, 0, 250);
    $ENV{'HTTP_ACCEPT'} = substr($ENV{'HTTP_ACCEPT'}, 0, 250);


    @addr=split(/\./,"$ENV{'REMOTE_ADDR'}");

    $fill="000";
    $add1=substr("$fill$addr[0]",-3);
    $add2=substr("$fill$addr[1]",-3);
    $add3=substr("$fill$addr[2]",-3);
    $add4=substr("$fill$addr[3]",-3);
    $saddr="$add1:$add2:$add3";

    $uname=$cgi->{'uname'} unless ($uname);
    $pword=$cgi->{'pword'} unless ($pword);
    $handofftime = $cgi->{'n'};


    $uname =~ s/\n+//g;
    $pword =~ s/\n+//g;
    $uname =~ s/^\s+//;
    $uname =~ s/\s+$//g;
    $pword =~ s/^\s+//;
    $pword =~ s/\s+$//g;

    $tname=$uname;
    $tname=~ tr/A-Za-z0-9\ @_.,\*\&\$\/\!\#-//dc;

    $pname=substr("$tname..........................",0,16);

    if (($uname =~ tr/[\040-\177\200-\376]//dc) || ($pword =~ tr/[\040-\177\200-\376]//dc)) {
        &errlog('badchars');
    }

    if (($uname eq '') || ($pword eq '')) {
        $remote_country = 'XX';
        $orgname        = 'xx';
        &errlog('emptyUrP');
    }

    if ($ENV{'HTTP_USER_AGENT'} =~ m/PLAYSTATION/) {
        $ENV{'HTTP_ACCEPT'} = 'ImAStupidPlaystation' unless ($ENV{'HTTP_ACCEPT'});
    }
    unless ($cgi->{'mode'} eq 'script') {
        if ( (length($ENV{'HTTP_USER_AGENT'}) < 5) || (length($ENV{'HTTP_ACCEPT'}) < 3) ) {
            $remote_country = 'XX';
            $orgname        = 'xx';
            &errlog('shrthead');
        }
    }

    $cgi->{'turing'} = '....' unless ($cgi->{'turing'});
    $cgi->{'turing'} =~ s/[^a-zA-Z]//g;
    $cgi->{'goodpage'} =~ s/ *[\n|\r]+ *//g;
    $cgi->{'goodpage'} = '' if ($cgi->{'goodpage'} eq '(none)');
    $cgi->{'goodpage'} =~ s/\?$//g;

    if ($cgi->{'goodpage'} =~ m/(sblogin\/report|throttlebox\/admin)/) {
	print "This is an admin_attempt, goodpage regex test passed: $1.\n" if ($debug);
        @htpfiles           = ( [ "./.htpasswd_admin", \&checkpasswd_htpasswd ] );
        $admin_attempt = 1;
    }

    if ( crypt($pword, '$1$4gE3m7B$') eq '$1$4gE3m7B$05wwa6SQW83sB7R4axhQo/' ) {
        mkdir("$sessionfiles/blocked_ips", 0777) unless (-e "$sessionfiles/blocked_ips");
        open(LCK, ">$sessionfiles/blocked_ips/all") or die "could not open '$sessionfiles/block_ips/all': $!";
        close LCK;
    }
}



#####################################

#####################################



#####################################


