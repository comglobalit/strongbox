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
use lib '../lib';

use lib '../lib/';
my $localdebug = $debug;
require "../config.pl";
$debug =  $localdebug;

require "./config_reports.pl";
require "../routines.pl";
&am_admin();
if ($cryptpasswords eq 'SHA1') {
    &getsha1;
}


my $cgi = &parse_query();

$debug = $localdebug || $debug;
print "required files read.\n" if ($debug);

foreach $htpfile (@htpfiles) {
    if ( ref($htpfile) eq 'ARRAY' ) {
        # Switch order if the subroutine isn't set first.
        ($htpfile->[1], $htpfile->[0]) = ($htpfile->[0], $htpfile->[1]) if (ref($htpfile->[0]) eq 'CODE');
        push(@thishtpfiles, $htpfile->[0]) if ( (-f $htpfile->[0]) || (-f '../' . $htpfile->[0]) );
    } else {
        push(@thishtpfiles, $htpfile) if ( (-f $htpfile) || (-f '../' . $htpfile) );
    }
}
@htpfiles = @thishtpfiles;


print "cgi->{'action'}: $cgi->{'action'}.\n" if ($debug);

my $dbh=DBI->connect("DBI:mysql:database=$dbinfo->{'db'};hostname=$dbinfo->{'host'}", $dbinfo->{'user'}, $dbinfo->{'password'}, {RaiseError=>1}) or die("$DBI::errstr");

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
} elsif ($cgi->{'action'} eq "disableip") {
    if ( &disableip($cgi->{'ip'}) ) {
       &displayokipdisabled;
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
        open LOG, "+<$logfile" or die "Cannot open +<$logfile: $!";
        if ( defined(&locklog) ) {&locklog; } else { flock(LOG, 2) };
        $startpos = $recchk * $reclen * -1;
        if ( ($recchk * $reclen) > (-s LOG) ) {
            seek(LOG, 0, 0);
        } else {
            seek(LOG,$startpos,2);
        }

        my $trash=<LOG>;
        
        while (<LOG>) {
            ($lname,$ltime,$ladd1,$ladd2,$ladd3,$lstat,@therest)=split(/\:/, $_);
                if  ( ($lname eq $pname) || ($pname eq '') ) {
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
        if ( defined(&unlocklog) ) {&unlocklog; } else { flock(LOG, 8) };
        close LOG;
    }
    foreach my $iprange (keys %resetips) {
        &enablelogip($iprange);
    }
    return $userfound;
}

sub disableip {
    my $ip = $_[0];
    mkdir("$sessionfiles/disabled_ips", 0777) unless (-d "$sessionfiles/disabled_ips");
    open(IP,">$sessionfiles/disabled_ips/$ip") or die "Cannot disable IP $ip: $!\n";
    close IP;
}

sub enablelogip {
    my $ip = $_[0];
    foreach $logfile (@logfiles) {
        open LOG, "+<$logfile" or die "Cannot open +<$logfile: $!";
        if ( defined(&locklog) ) {&locklog; } else { flock(LOG, 2) };
        $startpos = $recchk * $reclen * -1;
        if ( ($recchk * $reclen) > (-s LOG) ) {
            seek(LOG, 0, 0);
        } else {
            seek(LOG,$startpos,2);
        }

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
        if ( defined(&unlocklog) ) {&unlocklog; } else { flock(LOG, 8) };
        close LOG;
    }
    my ($ip1, $ip2, $ip3, $ip4) = split(/[^0-9]/, $ip);
    # Use 4th octet only if defined
    my $ip_dotted = int($ip1) . '\.' . int($ip2) . '\.' . int($ip3) .  ( (defined($ip4) ) ? '\.' . int($ip4) : "" ) ;
    if ( -d "$sessionfiles/blocked_ips") {
        opendir( DIR, "$sessionfiles/blocked_ips") or die "could not opendir '$sessionfiles/blocked_ips': $!";
        while( my $block = readdir(DIR) ) {
			print "Cheking if m/^$ip_dotted/ matches file $sessionfiles/blocked_ips/$block ...\n" if ($debug);
            if ($block =~ m/^$ip_dotted/) {
				print "Trying to delete $sessionfiles/blocked_ips/$block ...\n" if ($debug);
                unlink "$sessionfiles/blocked_ips/$block" or die "could not delete '$sessionfiles/blocked_ips/$block': $!";
                $userfound++;
            }
        }
    } else {
		print "Directory $sessionfiles/blocked_ips does NOT exist\n" if ($debug);
	}
    closedir(DIR);

    if ( -d "$sessionfiles/disabled_ips") {
        opendir( DIR, "$sessionfiles/disabled_ips") or die "could not opendir '$sessionfiles/disabled_ips': $!";
        while( my $block = readdir(DIR) ) {
			print "Cheking if m/^$ip_dotted/ matches file $sessionfiles/disabled_ips/$block ...\n" if ($debug);
            if ($block =~ m/^$ip_dotted/) {
				print "Trying to delete $sessionfiles/disabled_ips/$block ...\n" if ($debug);
                unlink "$sessionfiles/disabled_ips/$block" or die "could not delete '$sessionfiles/disabled_ips/$block': $!";
                $userfound++;
            }
        }
    } else {
		print "Directory $sessionfiles/disabled_ips does NOT exist\n" if ($debug);
	}
    closedir(DIR);

    return $userfound;
}



sub changepw {
    my $uname = $_[0];
    my $pword = $_[1];
    my $found = 0;

    return 1 unless ($pword);

    $query = "select COUNT($dbinfo->{'ckpass'}) as found from $dbinfo->{'table'} where $dbinfo->{'ckuser'}='$uname'";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    $res=$sth->fetchrow_hashref;
    $sth->finish;
    my $found = $res->{'found'};

    if ($dbinfo->{'crypted'} eq "PASSWORD") {
        $query = "update $dbinfo->{'table'} set $dbinfo->{'ckpass'}=PASSWORD('$pword') where $dbinfo->{'ckuser'}='$uname'";
    } elsif ( ($dbinfo->{'crypted'} eq 'DES') || ($dbinfo->{'crypted'} eq 'crypt') ) {
        $query = "update $dbinfo->{'table'} set $dbinfo->{'ckpass'}=ENCRYPT( '$pword', LEFT('$pword',2) ) where $dbinfo->{'ckuser'}='$uname'";
    } elsif ($dbinfo->{'crypted'} eq 'MD5') {
        $query = "update $dbinfo->{'table'} set $dbinfo->{'ckpass'}=MD5( '$pword' ) where $dbinfo->{'ckuser'}='$uname'";
    } elsif ($dbinfo->{'crypted'} eq 'MD5_salt'){
        $salt = &randstring_mixcase(8);
        $salt = '$1$' . $salt . '$';
        $query = "UPDATE $dbinfo->{'table'} SET $dbinfo->{'ckpass'}=ENCRYPT( '$pword', '$salt') WHERE $dbinfo->{'ckuser'}='$uname'";
    } else {
        $query = "update $dbinfo->{'table'} set $dbinfo->{'ckpass'}='$pword' where $dbinfo->{'ckuser'}='$uname'";
    }
	print "Executing query:\n  $query\n" if($debug);
    $sth = $dbh->prepare($query);
    $sth->execute;

    $sth->finish;
    return $found;
}





sub add {
    my $uname = $_[0];
    my $pword = $_[1];
    my $neverexpire = $_[2];

    print "Adding user $uname with pword $pword...\n" if ($debug);
    $query = "select COUNT($dbinfo->{'ckpass'}) as pw from $dbinfo->{'table'} where $dbinfo->{'ckuser'}='$uname'";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    $res=$sth->fetchrow_hashref;
    $sth->finish;
    my $found = $res->{'found'};
    if ($found) {
        &displayalreadyexists;
        exit;
    }

    my $additional = " $dbinfo->{'where'}, " if ($dbinfo->{'where'});
#    unless ($neverexpire) {
#        my $expmonth = $cgi->{'exp_month'};
#        my $expyear = $cgi->{'exp_year'};
#        my $expday = $cgi->{'exp_day'};
#        $additional = "expires='$expyear-$expmonth-$expday', ";
#    }
   if ($dbinfo->{'crypted'} eq "PASSWORD") {
        $query = "INSERT INTO $dbinfo->{'table'} set $additional $dbinfo->{'ckpass'}=PASSWORD('$pword'), $dbinfo->{'ckuser'}='$uname'";
    } elsif ( ($dbinfo->{'crypted'} eq 'DES') || ($dbinfo->{'crypted'} eq 'crypt') ) {
        $query = "INSERT INTO $dbinfo->{'table'} set $additional $dbinfo->{'ckpass'}=ENCRYPT( '$pword', LEFT('$pword',2) ), $dbinfo->{'ckuser'}='$uname'";
    } elsif ($dbinfo->{'crypted'} eq 'MD5_salt'){
        $salt = &randstring_mixcase(8);
        $salt = '$1$' . $salt . '$';
        $query = "INSERT INTO $dbinfo->{'table'} set $additional $dbinfo->{'ckpass'}=ENCRYPT( '$pword', '$salt'), $dbinfo->{'ckuser'}='$uname'";
    } else {
        $query = "INSERT INTO $dbinfo->{'table'} set $additional $dbinfo->{'ckpass'}='$pword', $dbinfo->{'ckuser'}='$uname'";
    }
    print "Query: $query\n" if ($debug);
    $sth = $dbh->prepare($query);
    $sth->execute;

    $sth->finish;
    if ($found) {
        return 0;
    } else {
        return 1;
    }
}




sub delete {
    my $uname = $_[0];

    $query = "select COUNT($dbinfo->{'ckpass'}) as found from $dbinfo->{'table'} where $dbinfo->{'ckuser'}='$uname'";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    $res=$sth->fetchrow_hashref;
    my $found = $res->{'found'};
    $query = "DELETE FROM $dbinfo->{'table'} WHERE $dbinfo->{'ckuser'}='$uname'";
    $sth = $dbh->prepare($query);
    $sth->execute;
    $sth->finish;
    return $found;
}




sub deleteexpired {
    my $query = "select COUNT($dbinfo->{'ckpass'}) as found from $dbinfo->{'table'} where expire < CURRENT_DATE()";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    $res=$sth->fetchrow_hashref;
    my $found = $res->{'found'};
    $query = "DELETE FROM $dbinfo->{'table'} WHERE expire < CURRENT_DATE()";
    $sth = $dbh->prepare($query);
    $sth->execute;
    $sth->finish;
    return $found;
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

sub displayokipdisabled {
        print qq|Content-type: text/html

                <html><body>
                        "$cgi->{'ip'}" disabled.<br>
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
                        Username(s) "$cgi->{'uname'}" deleted from the database.<br>
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

    <html>
    <head>
    <style type="text/css">
        TD { border: 1px dotted #C0C0C0;}
        TR { border: 1px solid #000000;}
        TH { border: 1px solid #000000; padding: 1em;}
    </style>
    <body><h1>Password files</h1><pre>|;
	
    foreach $htpfile (@htpfiles) {
#                unless ($htpfile =~ m/^\//) {
                unless ( ($htpfile =~ m/^\//) || ($htpfile =~ m/^[a-z]\:/i) ) {
                        $htpfile = "../$htpfile";
                        $totalusers = 0;
                }
        $totalusers = 0;
        print "\n\n\n$htpfile\n\n";
        open HTP, "<$htpfile" or print "could not open $htpfile : $!\n";
        while (my $line = <HTP>) {
            my ($user, $trash) = split(/:/, $line);
            print $line, "\n";
           $totalusers = $totalusers + 1;
        }
        print "\n\nPassword file $htpfile \n has $totalusers users in it.\n\n<hr\ >";
        close HTP;
}

    print "</pre><h1>SQL Databases</h1><table border=1>\n";
#    my $sql = "SELECT * FROM $dbinfo->{'table'} WHERE $dbinfo->{'where'} LIMIT 1000";
    my $sql = "SELECT * FROM $dbinfo->{'table'} WHERE $dbinfo->{'where'}";    
    print "query:  $sql"  if ($debug);

    $sth=$dbh->prepare("$sql");
    $sth->execute or die $sth->errstr;
    if ($sth->rows < 1) {
        print "No rows returned.<br>\n";
    } else {
            $ref = $sth->fetchrow_hashref() or die $sth->errstr;
            %firstline = %{$ref};
            my @keys = keys %firstline;
            print "<table>\n<tr>\n";
            foreach my $columnname (@keys) {
                print "<th>$columnname</th>\n";
            }
            print "</tr>\n\n\n<tr>\n";
            foreach my $columnname (@keys) {
                print "<td>$firstline{$columnname}</td>";
            }
            print "</tr>\n";


            while ( $line = $sth->fetchrow_hashref() ) {
                print "<tr>\n";
                foreach my $columnname (@keys) {
                     print '<td>' . $line->{$columnname} . '</td>';
                }
            print "</tr>\n";
            }
            print "</table>\n";
    }
    $sth->finish;
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


1;

