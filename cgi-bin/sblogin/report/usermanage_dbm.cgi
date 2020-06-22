#!/usr/bin/perl 

BEGIN {
    $debug = 0;
    if ($debug) {
        print "Content-type: text/plain\n\n";
        open (STDERR, ">&STDOUT");
        select(STDERR); $| = 1;
        select(STDOUT); $| = 1;
     }
}


use lib '..';


use Time::Local; 

use lib '../lib/';
require "../config.pl";
require "./config_reports.pl";
require "../routines.pl";
&am_admin();

if ($cryptpasswords eq 'SHA1') {
    use lib '../lib';
    &getsha1;
}



my $cgi = &parse_query();


print "cgi->{'action'}: $cgi->{'action'}.\n" if ($debug);

if ($cgi->{'action'} eq "add") {
    &add($cgi->{'uname'}, $cgi->{'pword'}, $cgi->{'neverexpire'});
    &displayok;
} elsif ($cgi->{'action'} eq "changepw") {
    if ( &changepw($cgi->{'uname'}, $cgi->{'pword'}) ) {
        &displayok;
    } else {
        &displaynotfound($cgi->{'uname'});
    }
} elsif ($cgi->{'action'} eq "reenable") {
    if ( &changepw($cgi->{'uname'}, $cgi->{'pword'}) == 0 ) {
       &displaynotfound($cgi->{'uname'});
    } elsif ( &enablelog($cgi->{'uname'}) == 0 ) {
       &displaynotsuspended($cgi->{'uname'});
    } else {
       &displayok;
    }
} elsif ($cgi->{'action'} eq "reenableip") {
    $cgi->{'ip'} =~ m/([0-9]+)[^0-9]*([0-9]+)[^0-9]*([0-9]+)/;
    my $ip = sprintf("%03u:%03u:%03u", $1, $2, $3);
    if ( &enablelogip($ip) ) {
        &displayokip;
    } else {
        &displaynotfound($cgi->{'ip'} . " ($ip)");
    }
} elsif ($cgi->{'action'} eq "remove") {
    if ( &delete($cgi->{'uname'}) ) {
        &displaydelete;
    } else {
        &displaynotfound($cgi->{'uname'});
    }
} elsif ($cgi->{'action'} eq "removeexpired") {
    &deleteexpired();
    &displaydelete;
} elsif ($cgi->{'action'} eq "list") {
    &listusers();
} elsif ($cgi->{'action'} eq "trimlog") {
    &trimlog();
} else {
    &displaybadaction;
}




sub enablelog {
    my $pname         = $_[0];
    my $userfound     = 0;
    $pname            = substr("$pname..........................",0,16);

    my $twodaysago    = time() - 172800;
 
    my %resetips;
    my $resetuser     = 0;
    my $resettotal    = 1;
    
    # Note : Permanent disable is based on recchk, not time.
    
    foreach $logfile (@logfiles) {
        open LOG, "+<$logfile"
          or die "Cannot open +<$logfile: $!";
        flock LOG, 2;
        $startpos=$recchk * $reclen * -1;
        seek(LOG,$startpos,2);
        seek(LOG, 0, 0) if (tell(LOG) < 0);
        my $trash=<LOG>;
        
        while (<LOG>) {
            ($lname,$ltime,$ladd1,$ladd2,$ladd3,$lstat,@therest)=split(/\:/, $_);
                if  ($lname eq $pname) {
                    if ( ($lstat =~ /^dis/) || ($lstat =~ /^uniq/) ) {
                        seek(LOG, -1 * length($_), 1) or die "Seeking: $!";
                        print LOG "$lname:$ltime:$ladd1:$ladd2:$ladd3:" . uc($lstat) . ":" . join(":", @therest);
                        $userfound++;
                    } elsif ($ltime > $twodaysago) {
                        $resetips{"$ladd1:$ladd2:$ladd3"}++ if ($lstat eq 'attempts');
                        seek(LOG, -1 * length($_), 1) or die "Seeking: $!";
                        print LOG "$lname:$ltime:$ladd1:$ladd2:$ladd3:" . uc($lstat) . ":" . join(":", @therest);
                        $userfound++;
                    }
                }
        }
        flock LOG, 8;
        close LOG;
    }
    foreach my $iprange (keys %resetips) {
        &enablelogip($iprange);
    }
    return $userfound;
}





sub enablelogip {
    my $ip = $_[0];
    foreach $logfile (@logfiles) {
        open LOG, "+<$logfile"
          or die "Cannot open +<$logfile: $!";
        flock LOG, 2;
        $startpos=$recchk * $reclen * -1;
        seek(LOG,$startpos,2);
        seek(LOG, 0, 0) if (tell(LOG) < 0);
        my $trash=<LOG>;

        while (<LOG>) {
            ($lname,$ltime,$ladd1,$ladd2,$ladd3,$lstat,@therest)=split(/\:/, $_);
            # print "if ($ladd1:$ladd2:$ladd3 eq $ip)\n" if ($debug);
            if ("$ladd1:$ladd2:$ladd3" eq $ip) {
                $userfound++;
                print "$ladd1:$ladd2:$ladd3 eq $ip, lstat: $lstat\n" if ($debug);
                unless ( ($lstat =~ /^good/) || ($lstat =~ /^reenable/) ) {
                    seek(LOG, -1 * length($_), 1) or die "Seeking: $!";
                    print LOG "$lname:$ltime:$ladd1:$ladd2:$ladd3:" . uc($lstat) . ':' . join(":", @therest);
                }
            }
        }
        flock LOG, 8;
        close LOG;
    }
    return $userfound;
}



sub changepw {
    my $uname = $_[0];
    my $pword = $_[1];
    my $found = 0;

    return 1 unless ($pword);

    foreach $htpfile (@htpfiles) {
        my %DB = ();
        unless ( dbmopen (%DB, $htpfile, 0666) ) {
            die "couldn't open dbm password file '$htpfile': $!";
        }

        unless ( defined($DB{$uname}) ) {
            dbmclose(%DB);
            next;
        }
        $found++;
        my ($cpass, @more) = split(/:/, $DB{$uname});
        if ($cryptpasswords eq 'MD5_salt') {
            my $salt = '$1$' . &randstring(7) . '$';
            $cpass = crypt($pword, $salt);
        } elsif ($cryptpasswords eq 'SHA1') {
            $cpass = '{SHA}' .  sha1_base64($pword) . '=';
        } elsif ($cryptpasswords) {
            my $salt = &randstring(2);
            $cpass = crypt($pword, $salt);
        } else {
            $cpass = $pword;
        }

        $additional = join(":", @more);
        $additional = ":$additional" if ($additional);
        $DB{$uname} = "$cpass$additional";
        dbmclose(%DB);
    }
    return $found;
}





sub add {
    my $uname = $_[0];
    my $pword = $_[1];
    my $neverexpire = $_[2];

    my $additional;
    unless ($neverexpire) {
        my $expmonth = $cgi->{'exp_month'} - 1;
        my $expyear = $cgi->{'exp_year'} - 1900;
        my $expday = $cgi->{'exp_day'};
        my $exptime = timegm(59,59,23, $expday, $expmonth, $expyear) || 0;
        if ($exptime) {
            $additional = "\:exp=$exptime";
        }
    }


    foreach $htpfile (@htpfiles) {
        my %DB = ();
        unless ($htpfile =~ m/^\//) {
            $htpfile = "../$htpfile";
        }
        unless ( dbmopen (%DB, $htpfile, 0666) ) {
            die "couldn't open dbm password file '$htpfile': $!";
        }

        if ( defined($DB{$uname}) ) {
            &displayalreadyexists;
            dbmclose(%DB);
            exit;
        }
        dbmclose(%DB);
    }


    $htpfile = $htpfiles[0];
    unless ($htpfile =~ m/^\//) {
           $htpfile = "../$htpfile";
    }
    print "Adding user $uname with pword $pword...\n" if ($debug);
    if ($cryptpasswords eq 'MD5_salt') {
        my $salt = '$1$' . &randstring(7) . '$';
        $cpass = crypt($pword, $salt);
    } elsif ($cryptpasswords eq 'SHA1') {
        $cpass = '{SHA}' .  sha1_base64($pword) . '=';
    } elsif ($cryptpasswords) {
        my $salt = &randstring(2);
        $cpass = crypt($pword, $salt);
    } else {
        $cpass = $pword;
    }

    my %DB = ();
    unless ($htpfile =~ m/^\//) {
        $htpfile = "../$htpfile";
    }
    unless ( dbmopen (%DB, $htpfile, 0666) ) {
        die "couldn't open dbm password file '$htpfile': $!";
    }
    $DB{$uname} = "$cpass$additional";
    dbmclose(%DB);
    return 1;
}




sub delete {
    my $uname = $_[0];
    my $found = 0;

    foreach $htpfile (@htpfiles) {
            unless ($htpfile =~ m/^\//) {
                    $htpfile = "../$htpfile";
            }

            my %DB = ();
            unless ($htpfile =~ m/^\//) {
                $htpfile = "../$htpfile";
            }
            unless ( dbmopen (%DB, $htpfile, 0666) ) {
                 die "couldn't open dbm password file '$htpfile': $!";
            }
            if ( defined($DB{$uname}) ) {
                delete($DB{$uname});
                $found++;
            }
        dbmclose(%DB);
    }
    return $found;
}




sub deleteexpired {
    my $now = time();

    foreach $htpfile (@htpfiles) {
        my %DB = ();
        unless ($htpfile =~ m/^\//) {
            $htpfile = "../$htpfile";
        }
        unless ( dbmopen (%DB, $htpfile, 0666) ) {
             die "couldn't open dbm password file '$htpfile': $!";
        }

        while ( ($user,$val) = each %DB ) {
            next unless $val =~ m/:exp=([0-9]*)/;
            my $lexptime = $1;
            print "now: $now\tlexptime: $lexptime\n" if ($debug);
            my ($cpass, @more) = split(":", $val);
            $additional = join(":", @more);
            if ( $lexptime && ($lexptime < $now) ) {
                $cgi->{'uname'} .= "$user ";
                delete($DB{$user});
            }
        }
        dbmclose(%DB);
    }
}







sub displayok {
    print qq|Content-type: text/html

        <html><body>
            "$cgi->{'uname'}" is now active.<br>
        |;

        if ($cgi->{'pword'}) {
              print "Password for $cgi->{'uname'} is $cgi->{'pword'}";
        } else {
            print "Password is unchanged.";
        }
        
    print "</body></html>\n\n";
}

sub displayokip {
        print qq|Content-type: text/html

                <html><body>
                        "$cgi->{'ip'}" reenabled.<br>
        |;

        print "</body></html>\n\n";
}



sub displaynotfound {
        my $input = $_[0];
        print qq|Content-type: text/html

                <html><body>
                        "$input" not found.<br>
                </body></html>
        |;
}


sub displayalreadyexists {
        my $input = $_[0];
        print qq|Content-type: text/html

                <html><body>
                        "$input" already exists.<br>
                </body></html>
        |;
}


sub displaynotsuspended {
        my $input = $_[0];
        print qq|Content-type: text/html

                <html><body>
                        "$input" is not currently suspended.<br>
                </body></html>
        |;
}


sub displaydelete {
        print qq|Content-type: text/html

                <html><body>
                        Username(s) "$cgi->{'uname'}" deleted from the password file.<br>
                </body></html>
        |;

}



sub displaybadaction {
        print qq|Content-type: text/html

                <html><body>
                        Bad <em>action</em>.  I don't know how to "$cgi->{'action'}".<br>
                </body></html>
        |;

}





sub listusers {
    print qq|Content-type: text/html

                <html><body>
        <pre>|;

    foreach $htpfile (@htpfiles) {
        print "\n\n\n$htpfile\n\n";
        my %DB = ();
        unless ($htpfile =~ m/^\//) {
            $htpfile = "../$htpfile";
        }
        unless ( dbmopen (%DB, $htpfile, 0666) ) {
             die "couldn't open dbm password file '$htpfile': $!";
        }

        while ( ($user,$val) = each %DB ) {
            $totalusers = $totalusers + 1;
            print "$user   $val\n";
        }
        print "\n\nDBM file $htpfile \n has $totalusers users in it.\n\n<hr\ >";
        dbmclose(%DB);
    }
    print "</pre></body></html>\n\n";
}




sub trimlog {

    foreach $logfile (@logfiles) {
    open LOG, "+<$logfile" or die "could not open +<$logfile : $!";
        flock(LOG,2);
    seek(LOG,-132800,2);
    print "current position: " . tell() . "\n" if ($debug);
    my $garbage = <LOG>;
    
    @lines = <LOG>;
    
    seek(LOG,0,0);
        foreach my $line (@lines) {
        print LOG $line;
        }
    truncate LOG, tell();
        flock(LOG, 8); #unlock
        close LOG;
    }
     print qq|Content-type: text/html

                <html><body>
                The login log(s) has been trimmed and now
        shows only the last 2,250 logins.<br>
        The log is now 132KB.
        </body></html>
        |;
}


