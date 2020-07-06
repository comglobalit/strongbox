#!/usr/bin/perl
 
sub mkhtcookie() {
    my ($sbsession, $host, $admin_attempt) = @_;
    if ($md5_htcookie) {
        require "./md5.pl";
        $browser_sig =
            md5_hex( $ENV{'HTTP_USER_AGENT'} ) . "/"
          . md5_hex( $ENV{'HTTP_ACCEPT'} );
    }
    else {
        $browser_sig = "$ENV{'HTTP_USER_AGENT'}/$ENV{'HTTP_ACCEPT'}";
    }

    &mkpath("$sessionfiles/$sbsession.$host/$browser_sig");
    &touchfile("$sessionfiles/$sbsession.$host/$browser_sig/$site_id");
    &touchfile("$sessionfiles/$sbsession.$host/$ENV{'HTTP_USER_AGENT'}/$site_id");
    &touchfile("$sessionfiles/$sbsession.$host/$browser_sig/$sbsession.$host");
    &touchfile("$sessionfiles/$sbsession.$host/$ENV{'REMOTE_ADDR'}");
    &touchfile("$sessionfiles/$sbsession.$host/admin") if ($admin_attempt);
}


sub sbusermap {
    my ($sbsession, $uname) = @_;
    if (-f 'sbusermap.txt') {
        unless ( time() % 200 ) {
            if ( open(USERLOG, "<sbusermap.txt") ) {
                flock(USERLOG, 1);
                my @lines = <USERLOG>;
                if ($#lines > 500) {
                    flock(USERLOG, 8);
                    close USERLOG;
                    open(USERLOG, ">sbusermap.txt") or die "could not open 'sbusermap.txt': $!";
                    flock(USERLOG, 2);
                    my $i = 300;
                    while($lines[++$i]) {
                        print USERLOG $lines[$i];
                    }
                }
                flock(USERLOG, 8);
                close USERLOG;
            }
       }

       open(USERLOG, ">>sbusermap.txt") or die "could not open 'sbusermap.txt': $!";
       flock(USERLOG, 2);
       print USERLOG "$sbsession $uname\n";
       flock(USERLOG, 8);
       close USERLOG;
    }
}


sub validategoodpage {
    my ($cgigoodpage, $goodpage) = @_;
    if ( $cgigoodpage =~ /^\// ) {
        $goodpage = $cgigoodpage unless ( $cgigoodpage =~ m/sblogin\/login/ );
    }
    $goodpage =~ s/^\s+//;
    $goodpage =~ s/\s+$//;
    $goodpage =~ s/\?$//;

    $goodpage = $goodpage . "/" if ( ($goodpage =~ m@[^/]$@) && (-d $ENV{'DOCUMENT_ROOT'}. $goodpage) );
    chop($goodpage) if ($goodpage =~ m/\?$/);
    return $goodpage;
}


sub touchfile {
    my ($file) = (@_);
    open(FILE, ">>$file") or die "could not open '$file': $!";
    close FILE;
}


sub sendresponse {
    my ($sbsession, $host, $goodpage, $uname, $logstat, $mode, $cookies_only) = @_;
    if ( $mode eq "script" ) {
        print "Content-type: text/plain\n\nsbstatus: $logstat\nsbsession: $sbsession\n";
    } else {
        print "Set-Cookie: sbsession=$sbsession&sbuser=$uname; path=/; domain=$host;\n";
        if ($cookies_only) {
            print "Set-Cookie: sbcookiesonly=yes; path=/; domain=$host;\n";
            print "Location: http://$host" . "$goodpage\n\n";
        } else {
            print "Set-Cookie: sbcookiesonly=no; path=/; domain=$host;\n";
            print "Location: http://$sbsession.$host" . "$goodpage\n\n";
        }
    }
}

1;

