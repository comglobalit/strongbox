#!/usr/bin/perl
 
# Date: 2011-06-02
 
require 'approved.pl';


{
    my $plugin_subs = ();
    my $pluginsloaded;
    &load_plugins unless ($pluginsloaded++);
    sub load_plugins {
        use lib 'lib';
        foreach my $plugin (@plugins) {
            eval "require $plugin;";
            warn ($@) if ($@);
            while ( my ($key, $value) = each %{$plugin . '::'} ) {
              push(@{$plugin_subs->{$key}}, $plugin);
            }
            print "loaded $plugin plugin.\n" if ($debug);
        }  
    }   
    
    # Ex; &do_plugins('say', { errstat => $errstat, dbh_log => $dbh_log } );
    # plugins only return true or false.  Use references to return data.
    sub do_plugins {
        my $method = shift();
        foreach my $plugin (@{$plugin_subs->{$method}}) {
           print "in do_plugins, \@_:" . join(', ', @_) . "\n" if ($debug);
           last unless $plugin->$method(@_);
        }
    }        
} 


{ my $guard = 0;
sub getsha1 {
    return if ($guard++);
    eval {
             require Digest::SHA1;
             import Digest::SHA1  qw(sha1_base64);
      };
      if ($@) {
            eval {
                require Digest::Perl::MD5;
                import Digest::Perl::MD5 'sha1_base64'
            }
      }
      if ($@) {
            eval {
                    use lib 'lib';
                    require Digest::SHA::PurePerl;
                    import Digest::SHA::PurePerl 'sha1_base64';
                }
      }
      if ($@) { # no Digest::SHA::PurePerl either
          die "I can't find any SHA module anywhere, not even the pure Perl one: $!";
      }
}
}



sub rmtree {
    my $dirpath = shift;
    return unless ( -e "$dirpath" );
    if ( -f $dirpath ) {
        unlink $dirpath or warn "could not remove \"$dirpath\": $!";
    }
    else {
        opendir( DH, $dirpath ) or warn "couldn't opendir '$dirpath': $!";
        my @files = readdir(DH);
        closedir(DH);
        foreach my $file (@files) {
            next if ( ( $file eq "." ) || ( $file eq ".." ) );
            if ( -d "$dirpath/$file" ) {
                &rmtree("$dirpath/$file");
            }
            elsif (-f "$dirpath/$file") {
                unlink "$dirpath/$file"
                  or warn "could not remove \"$dirpath/$file\": $!";
            }
        }
        if (-d $dirpath) {
            rmdir($dirpath) or warn "could not remove \"$dirpath\": $!";
        }
    }
}



sub mkpath {
    my $path = "$_[0]";
    print "mkpath called for '$path'\n" if ($debug);
    return if ( -e "$path" );
    my $full = '';
    my @dir = split( /\//, "$path" );
    foreach my $elem (@dir) {
        $full .= "$elem/";
        unless ( -d "$full" ) {
            print "mkdir($full, 0777\n" if ($debug);
            mkdir("$full", 0777) or die "Could not create dir $full: $!";
            chmod(0777, "$full") or die "Could not chmod dir $full: $!";
        }
    }
}


sub urlencode {
    my ($text) = $_[0];
    $text =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $text;
}

###########################################

sub parse_query {
    return $cgi if ( $cgi->{'raw'} );
    my $buffer;
    my $cgi = {};
    if ( $ENV{'REQUEST_METHOD'} eq "POST" ) {
        read( STDIN, $buffer, $ENV{'CONTENT_LENGTH'} );
    }
    else {
        $buffer = $ENV{'QUERY_STRING'};
    }

    $cgi->{'raw'}          = $buffer;
    $cgi->{'PATH_INFO'}    = $ENV{'PATH_INFO'};
    $cgi->{'QUERY_STRING'} = $ENV{'QUERY_STRING'};

    my @pairs = split( /&/, $buffer );
    foreach my $pair (@pairs) {
        my ($name, $value) = split( /=/, $pair );
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $value =~s/\0//g;
        if ( $cgi->{$name} ) {
            $cgi->{$name} .= "|$value";
            push( @{ $cgi->{ $name . '_array' } }, $value );
        }
        else {
            $cgi->{$name} = $value;
        }
        print "\$cgi->{$name}:" . $cgi->{$name} . "\n" if ($debug);
    }
    # Use this plugin only if the same input field is used for multiple
    # functions, such as uc($uname) for login, reports, and "add user".
    &do_plugins('end_parse_query', $cgi);
    return $cgi;
}



sub randstring {
    # 9 characters from a-z and 0-9 represents 60,000,000,000,000
    # (60 trillion US) possible strings. If someone guessed 100 times
    # per second it would take 985 years to brute force a Strongbox
    # session ID generated with this method.
    my $string;
    my $length = $_[0];
    my $i      = 0;
    while ( $i++ < $length ) {
        $code = 58;
        while ( ( $code > 57 ) && ( $code < 97 ) ) {
            $code = int( rand(74) + 48 );
        }
        $string .= sprintf( "%c", $code );
    }
    return $string;
}


sub randstring_mixcase {
    my $length = $_[0];

    my $session;
    my $i = 0;
    while ( $i++ < $length ) {
        $code = 58;
        while (( ( $code > 57 ) && ( $code < 65 ) )
            || ( ( $code > 90 ) && ( $code < 97 ) ) )
        {
            $code = int( rand(74) + 48 );
        }
        $session .= sprintf( "%c", $code );
    }
    print "session: $session\n" if ($debug);
    return $session;
}


sub checkpasswd_htpasswd {
    my $uname = $_[0];
    my $pword = $_[1];
    my @thishtpfiles;
    if ($_[2]) {
        @thishtpfiles = @{$_[2]};
    } else {
        @thishtpfiles = @htpfiles;
    }
    my $cpword;
    my $foundinhtpfile;
    my $userpass = 'badpuser';

    foreach $htpfile (@thishtpfiles) {
        print "before plugin, $htpfile: '$htpfile'\n" if ($debug);
        &do_plugins('begin_checkpasswd_htpasswd', $htpfile, $cgi);
        print "after plugin, $htpfile: '$htpfile'\n" if ($debug);
        if ( defined(&rewrite_htpfile) ) {
            next unless ( $htpfile = &rewrite_htpfile($htpfile) );
        }
        unless ( open( HTP, "<  $htpfile" ) ) {
            warn "couldn't open password file '$htpfile': $!";
            &errlog("htpffail$!");
        }
        while (<HTP>) {
            s/[\r|\n]*$//;
            ($htuser, $htpasswd, @additional) = split(/:/);
            next unless ( ($htuser) && ($htpasswd) );
            if ($htuser eq $uname) {
                if ($htpasswd =~ m/^\{SHA/) {
                    &getsha1;
                    $cpword = '{SHA}' .  sha1_base64($pword) . '=';
                } else {
                    # glibc2 (1997) and higher crypt() supports MD5 of the form $1$salt$MD5hash
                    $cpword = crypt($pword, $htpasswd);
                }
                    
                if ($htpasswd ne $cpword) {
                    $userpass = 'badpword';
                } elsif (  my @expire = grep(/exp=[0-9]+/, @additional ) ) {
                    $expire[0] =~ m/exp=([0-9]+)/;
                    if ( $1  < time() ) {
                        print "expires at $1, time is currently ", time(), "\n" if ($debug);
                        $userpass = 'badexpir';
                    } else {
                        $userpass = 'gooduser';
                        last;
                    }
                } else {
                    $userpass = 'gooduser';
                    last;
                } 
            } # end if ($htuser eq $uname)
        } # while (<HTP>)

        close(HTP);
        $foundinhtpfile = $htpfile;
        last unless ( $userpass eq 'badpuser' );
    } # end  foreach $htpfile (@thishtpfiles)
    &end_checkpasswd_htpasswd($userpass, $foundinhtpfile) if ( defined(&end_checkpasswd_htpasswd) );
    return ($userpass, $foundinhtpfile);
}


sub checkpasswd_dbm {
    my $uname = $_[0];
    my $pword = $_[1];
    if ($_[2]) {
        @thishtpfiles = @{$_[2]};
    } else {
        @thishtpfiles = @htpfiles;
    }
    my $cpword;
    my $userpass = "badpuser";

    # @AnyDBM_File::ISA = qw(DB_File NDBM_File GDBM_File SDBM_File);
    # require Fcntl;
    # import Fcntl;
    # require AnyDBM_File;
   

    foreach $htpfile (@thishtpfiles) {
        if ( defined(&rewrite_htpfile) ) {
            next unless ( $htpfile = &rewrite_htpfile($htpfile) );
        }
        # remove extension if any
        my $chop = join '|', qw{db.? pag dir};
        # $htpfile =~ s/\.($chop)$//;
        print "\n\n\n$htpfile\n\n" if ($debug);
        my %DB = ();
        unless ( dbmopen (%DB, $htpfile, 0644) ) {
           warn "couldn't open dbm password file '$htpfile': $!";
           &errlog("htpffail$!");
        }

        unless ( defined($DB{$uname}) ) {
            print "user name $uname not found. ($DB{$uname})\n" if ($debug);
            dbmclose(%DB);
            next;
        }
        ($htpasswd, @additional) = split(/:/, $DB{$uname});      
        if ($htpasswd =~ m/^\{SHA/) {
            &getsha1;
            $cpword = '{SHA}' .  sha1_base64($pword) . '=';
        } else {
            # glibc2 (1997) and higher crypt() supports MD5 of the form $1$salt$MD5hash
            $cpword = crypt($pword, $htpasswd);
        }
 
        print "\$htpasswd: $htpasswd, \$cpword: $cpword\n" if ($debug);      
        if ($htpasswd ne $cpword) {
            $userpass = 'badpword';
        } elsif (  my @expire = grep(/exp=[0-9]+/, @additional ) ) {
            $expire[0] =~ m/exp=([0-9]+)/;
            if ( $1  < time() ) {
                print "expires at $1, time is currently ", time(), "\n" if ($debug);
                $userpass = 'badexpir';
            } else {
                 $userpass = 'gooduser';
                last;
            }
         } else {
            $userpass = 'gooduser';
            last;
        }
        dbmclose(%DB);
        # untie(%DB);
    } # end  foreach $htpfile (@thishtpfiles)
    return ($userpass, $htpfile);
}


sub checkpasswd_mysql {

    my $uname  = shift();
    my $pword  = shift();
    my $dbs    = shift();
    my $return = "htpffail";
    my $query  = "";
    my $crypted;

    $db = $dbs->[0];

    unless ($db) {
        $db = {
            'db'              => $mysql_db,
            'user'            => $mysql_user,
            'password'        => $mysql_password,
            'host'            => $mysql_host,
            'table'           => $mysql_table,
            'ckuser'          => $mysql_ckuser,
            'ckpass'          => $mysql_ckpass,
            'crypted'         => $mysql_crypted,
            'where'           => $mysql_where,
            'extra_fields'    => $mysql_extra_fields,
            'socket'          => $mysql_socket,
            'memberlevel'     => $mysql_memberlevel
        };
    }

    my $dbh = DBI->connect( "DBI:mysql:database=$db->{'db'};hostname=$db->{'host'}",
        $db->{'user'}, $db->{'password'}, { RaiseError => 1, mysql_socket => $db->{'socket'} } )
      or die("$DBI::errstr");

    &do_plugins('begin_checkpasswd_mysql', $dbh);

    if ($db->{'query'}) {
        eval "\$query = qq+$db->{'query'}+";  # Needed to use uname, pword, etc, in query
    }
    else {
        if ( $db->{'crypted'} eq 'PASSWORD' ) {
            $crypted = "PASSWORD(?)";
        } elsif ( ($db->{'crypted'} eq 'DES') || ($db->{'crypted'} eq 'crypt') || ($db->{'crypted'} eq 'MD5_salt') ) {
            $crypted = "ENCRYPT( ?, $db->{'ckpass'})";
        } elsif ( ($db->{'crypted'} eq 'MD5')  || ($db->{'crypted'} eq 'any') ) {
             $crypted = "MD5(?)";
        } elsif ( ref($dbinfo->{'crypted'}) eq 'CODE' ) {
            $crypted = "?, '" . &{$dbinfo->{'crypted'}}($pword) . "'";
        } elsif ($db->{'crypted'}) {
            $crypted = $db->{'crypted'};
        } else {
            $crypted = "?";
        }
        $query = "select $db->{'extra_fields'} $crypted as pword, $db->{'ckpass'} as pw from $db->{'table'} where $db->{'ckuser'}=?";
        $query .= ' AND ' . "(  $db->{'where'}  )" if ($db->{'where'});
        $query .= " ORDER BY $crypted=$db->{'ckpass'} DESC ";
        $query .= ', ' . $db->{'order'} if ($db->{'order'});
        $query .= ' LIMIT 1 ';
    }

    print "query: $query\n\n" if ($debug);
    my $sth = $dbh->prepare($query);

    my $binds = $query =~ tr/?/?/;
    if ($binds == 3) {
        $sth->execute($pword, $uname, $pword);
    } elsif ($binds == 2) {
        $sth->execute($pword, $uname);
    } elsif ($binds == 1) {
        $sth->execute($uname);
    } else {
        $sth->execute();
    }


    if ( $sth->rows < 1 ) {
        $return = 'badpuser';
    } else {
        print "found user.\n" if ($debug);
        $return = 'badpword';
        $res    = $sth->fetchrow_hashref;

        if ( $db->{'crypted'} eq 'any' ) {
            &getsha1;
            my $shapw = '{SHA}' .  sha1_base64($pword) . '=';
            my $cpword = crypt($pword, $res->{'pw'}); # glibc2 crypt() supports MD5 of the form $1$salt$MD5hash
            if ( ($res->{'pw'} eq $pword) || ($res->{'pw'} eq $res->{'pword'}) || ($res->{'pw'} eq $shapw) || ($res->{'pw'} eq $cpword) ) {
                print "password good.\n" if ($debug);
                $return = 'gooduser';
            }
        } else {
            if ($res->{'pword'} eq $res->{'pw'}) {
                print "password good.\n" if ($debug);
                $return = "gooduser";
            }
        }
    }

    &end_checkpasswd_mysql($res, $dbh, $sth, $return) if ( defined(&end_checkpasswd_mysql) );
    &do_plugins('end_checkpasswd_mysql', $res, $dbh, $sth, $return, $sessionfiles, $cgi->{'goodpage'});

    print "\$cgi->{'goodpage'}: $cgi->{'goodpage'}\n" if ($debug);
    $sth->finish;
    $dbh->disconnect;

    return ($return, $db->{'host'} . $db->{'table'});
}

# External script authentication
# Initial code: elias 2014-05-01
# username and password will be passed as command line arguments
# the script will write a 1 to STDOUT if it receives a valid user and pw
# Example of use in config.pl
#   [\&checkpasswd_externalscript, "php -q $ENV{'DOCUMENT_ROOT'}/sblogin/.htwpauth.php" ],

sub checkpasswd_externalscript {
    my $uname = $_[0];
    my $pword = $_[1];
    my $ext_script = $_[2]->[0];
    print "uname = $uname \n" if ($debug);
    print "pword = $pword \n" if ($debug);
    print "ext_script = $ext_script \n" if ($debug);
    my $userpass = 'badpuser';

    print "DANGER!!! What if the password is entered as \"(; rm -rf /)\"?\nInstead, see cgi-bin/sblogin/avs.pl\n"; exit;
    # $result = `$ext_script $uname $pword`;
    print "result = $result\n"  if ($debug);

    if ($result eq 1) {
        $userpass = 'gooduser';
    }

    return ($userpass, $ext_script );
}


sub apache_escape {
    my $value = $_[0];
    $value =~
s/([^a-z-A-Z0-9\$\-\_\.\+\!\*\'\(\)\,\:\@\&\=\/\~])/sprintf("%%%02x",ord($1))/eg;
    return $value;
}


sub notifywm {
    alarm(10);
    my $status = shift();
    require './notifywm.pl';
    
    my $msg = &get_wm_msg($status, $uname, $host);

    my $subject = "Strongbox on $host: $tname $status";
    for $disabto (@email_addresses) {
        if ($mailpgm) {
            open MAIL, "$mailpgm" or warn "Couldn't send mail through $mailpgm: $!";
            print MAIL "From: $disabto\nTo: $disabto\nSubject: $subject\n\n$msg";
            close(MAIL);
        } else {
            %mail = ( To      => $disabto,
                      From    => $disabto,
                      Subject => $subject,
                      Message => $msg
                    );
            sendmail(%mail) or warn $Mail::Sendmail::error;
        }
    }

}


sub position_file {
    my $handle      = $_[0];
    my $extract_sub = $_[1];    # \&string_to_timestamp; # $_[1];
    my $findnum     = $_[2];

    seek( $handle, 0, 2 );      # go to end of file
    my $unsearched = tell($handle);
    $unsearched = int( $unsearched / 2 );
    seek( $handle, ( 0 - $unsearched ), 1 )
      ;                         # seek back middle of unsearched section
    my $currdate = 0;

    while ( $currdate != $findnum ) {
        my $garbage = <$handle>;
        my $line    = <$handle>;
        $currdate = &$extract_sub($line);
        seek( $handle, ( 0 - length($line) ), 1 );

        if ( $unsearched < 1000 ) {
            $currdate = 0;
            print "only $unsearched bytes left to search\n" if ($debug);
            seek( $handle, 0 - int($unsearched), 1 );
            my $garbage = <$handle>;
            while ( ( $currdate < $findnum ) && ( $line = <$handle> ) ) {
                $currdate = &$extract_sub($line);
            }
            seek( $handle, ( 0 - length($line) ), 1 );
            return;
        }
        $unsearched = int( $unsearched / 2 );
        if ( $currdate > $findnum ) {
            seek( $handle, 0 - int($unsearched), 1 );    # seek back
        }
        elsif ( $currdate < $findnum ) {
            seek( $handle, $unsearched, 1 );             # seek forward
        }
        elsif ( $currdate == $findnum ) {
            return;
        }
        seek( $handle, ( 0 - length($garbage) ), 1 );
    }
}


sub trimloginlog {
    open LOG, "+<$logfile" or die "could not open +<$logfile : $!";

    # flock(LOG,2);
    seek( LOG, $maxlogsize / 2, 0 );
    my $garbage = <LOG>;

    @lines = <LOG>;

    seek( LOG, 0, 0 );
    foreach my $line (@lines) {
        print LOG $line;
    }
    truncate LOG, tell();
}


sub htmlspecialcharacters {
    $in = $_[0];
    $in =~ s/&/&amp;/g;
    $in =~ s/</&lt;/g;
    $in =~ s/>/&gt;/g;
    $in =~ s/"/&quot;/g;
    return $in;
}


sub parsecookie {
    local ( $ck, @entries, $item, $key, $value, %cookie );
    $ck = $ENV{HTTP_COOKIE};
    @entries = split( /;\s/, $ck );
    foreach $item (@entries) {
        ( $key, $value ) = split( /=/, $item );
        $value =~ s/^"//;
        $value =~ s/"$//;
        $cookie{$key} = $value;
    }
    return (%cookie);
}


sub rmoldsessions {
    alarm(30);
    print "removing old sessions\n" if ($debug);
    opendir( DIR, "$sessionfiles" ) or die "couldn't opendir '$sessionfiles': $!";
    @sessions = grep( !/^(\.|disabled)/, readdir(DIR) );
    closedir(DIR);

    foreach $entry (@sessions) {
        if ( -M "$sessionfiles/$entry" > $session_time ) {
            &rmtree( "$sessionfiles/$entry");
        }
    }

    print "removing old chickcaptcha files\n" if ($debug);
    opendir( DIR, "$sessionfiles/chickcaptcha" ) or warn "couldn't opendir '$sessionfiles/chickcaptcha': $!";
    @sessions = grep( !/^\./, readdir(DIR) );
    closedir(DIR);

    foreach $entry (@sessions) {
        if ( -M "$sessionfiles/chickcaptcha/$entry" > $session_time ) {
            &rmtree( "$sessionfiles/chickcaptcha/$entry");
        }
    }
}


sub rmoldturing {
    print "removing old turings\n" if ($debug);
    opendir( DIR, "$sessionfiles/turings" ) or die "could not opendir '$sessionfiles/turings': $!";
    @sessions = grep( !/^\.\.?$/, readdir(DIR) );
    closedir(DIR);
    foreach $entry (@sessions) {
        if ( -M "$sessionfiles/turings/$entry" > 0.2 ) {
            &rmtree( "$sessionfiles/turings/$entry" );
        }
    }
}


sub go_goodpage {
    my $sbsession = $_[0];
    &rmoldsessions unless ( time() % 10 );

    $goodpage = &validategoodpage($cgi->{'goodpage'}, $goodpage);
    &do_plugins('go_goodpage', { goodpage => $goodpage, sbsession => $sbsession });
    &mkhtcookie($sbsession, $host, $admin_attempt);
    &sendresponse($sbsession, $host, $goodpage, $uname, $logstat, $cgi->{'mode'}, $cookies_only);
    &sbusermap($sbsession, $uname);
    &after_goodpage($sbsession, $goodpage) if (defined(&after_goodpage) && (! $after_goodpage_guard++));
}

#######################################

sub openlog {
    open( LOG, "+>>$logfile" ) or die "could not open '$logfile': $!";
    if ( defined(&locklog) ) {&locklog; } else { flock(LOG, 2) };
    $SIG{INT}     = 'close_log';
    $SIG{HUP}     = 'close_log';
    $SIG{TERM2}   = 'close_log';
    $SIG{__DIE__} = 'close_log';
    $SIG{ABRT}    = 'close_log';
    $SIG{TERM}    = 'close_log';
}

######################################

sub close_log {
    if ( defined(&unlocklog) ) {&unlocklog; } else { flock(LOG, 8) };
    close(LOG);
}

######################################

sub writelog {
    $logstat = "$_[0]";
    my $time = time();

    &do_plugins('writelog', $goodpage, $sbsession);
    $logstat = substr( "$logstat........", 0, 8 );
    seek( LOG, 0, 2 );
    print LOG "$pname:$time:$add1:$add2:$add3:$logstat:$sbsession:$remote_country:$orgname\n";

    if ( defined(&unlocklog) ) {&unlocklog; } else { flock(LOG, 8) };
    close(LOG);
}


############################################

{ my $guard;
sub errlog {
    $errstat = "$_[0]";
    my $notifies_eight    = $_[1] if ( defined($_[1]) );
    my $notified          = $_[2] if ( ($_[2]) );

    if ( (! $guard++) && defined(&errlog_custom) ) {
        &errlog_custom($errstat);
        exit;
    }

    &do_plugins('errlog', {errstat => $errstat});
    if ( defined(&unlocklog) ) {&unlocklog; } else { flock(LOG, 8) };
    unless ( open(LOG, ">>$logfile") ) {
        &notifywm("logfail");
        exit;
    }
    if ( defined(&locklog) ) {&locklog; } else { flock(LOG, 2) };

    alarm(2);
    # sleep with LOG flocked (no other logins allowed)
    select( undef, undef, undef, 0.50 );
    &writelog($errstat);

    if ($use_ip_block_files && ($attms > 14) ) {
        if (
            ($errstat eq 'attempts') ||
            ($errstat eq 'badimage') ||
            ( ($image_login == 0) && ($errstat eq 'badpuser') )
           )
        {
            mkdir("$sessionfiles/blocked_ips", 0777) unless (-d "$sessionfiles/blocked_ips");
            open(BI, ">$sessionfiles/blocked_ips/$ENV{'REMOTE_ADDR'}");
            close BI;
        }
    }

    if ( $errstat eq 'attempts' ) {
        if ($ip_block_log) {
           open IPLOG, ">>$ip_block_log" or warn "Could not open '$ip_block_log': $!";
           print IPLOG time(), " $ENV{'REMOTE_ADDR'}\n";
           close IPLOG;
        }
        select( undef, undef, undef, 1 );
    } elsif ( ($errstat eq 'badimage') && ($badimage_log) ) {
        open BILOG, ">>$badimage_log" or warn "Could not open '$badimage_log': $!";
        print BILOG time(), " $ENV{'REMOTE_ADDR'}\n";
        close BILOG;
    }

    if ( $errstat =~ /^$notifyof$/ ) {
        alarm(4);
        select( undef, undef, undef, 1 );    # More sleeping for hackers
        unless (
                   (  defined($notified->{$errstat}) && ( $notified->{$errstat} >= ($max_notices_per_day / 8) )  ) ||
                   ( $notifies_eight >= ($max_notices_per_day / 3) )
               ) {
            &notifywm($errstat);
        }

    }
    my $persistfile = "$sessionfiles/turings/" . crypt($uname . $pword, 'fp');
    $persistfile =~ s@/@_@;
    if ( (int(rand(70)) == 1) || (-f $persistfile) ) {
        $sbsession = 'sb' . &randstring(9);
        $goodpage = &validategoodpage($cgi->{'goodpage'}, $goodpage);
        my $persistname = crypt($uname . $pword, 'fp');
        open(PERSIST, ">$persistfile") or die "could not open '$persistfile': $!";
        close PERSIST;
        &sendresponse($sbsession, $host, $goodpage, $uname, $logstat, $cgi->{'mode'}, $cookies_only);
    } else {
        &goerrpage($errstat);
    }
    exit;
}
}


###########################################

sub goerrpage {
    my $errstat = $_[0];

    if ( $cgi->{'mode'} eq "script" ) {
        print "Content-type: text/plain\n\nsbstatus: $errstat\nsbsession: $sbsession\n";
    } else {
        if ( $errstat eq "badimage" ) {
            print "Location: $badimagepage?" . $font . "\n\n";
        } else {
            my $font = $attms / 10 + 1;
            print "Location: $errpage?" . $font . "\n\n";
        }
    }
}

###########################################

sub get_session {
    my $sbsession;
    if ( $ENV{'HTTP_COOKIE'} =~ m/sbsession\ ?=\ ?(sb[0-9a-z]+)/ ) {
        $sbsession = $1;
    }
    if ( $ENV{'HTTP_REFERER'} =~ m/^http:\/\/(sb[0-9a-z]+)\./ ) {
        $sbsession = $1;
    }
    if ( $ENV{'HTTP_REFERER'} =~ m/sbsession=(sb[0-9a-z]+)/ ) {
        $sbsession = $1;
    }
    if ( $ENV{'HTTP_HOST'} =~ m/^(sb[0-9a-z]+)\./ ) {
        $sbsession = $1;
    }
    if ( $ENV{'QUERY_STRING'} =~ m/sbsession=(sb[0-9a-z]+)/ ) {
        $sbsession = $1;
    }
    return $sbsession;
    # cookie is checked last for download managers, where an old URL may be used with a fresh cookie.
}

###########################################

sub am_admin {    
    my $sbsession = &get_session();
    $sessionfiles = "../$sessionfiles" unless (-d $sessionfiles);
    unless (-f "$sessionfiles/$sbsession.$host/admin" ) {
        print "Location: http://$host/sblogin/report.html\n\n";
        exit 1;
    }
}


#################



return 1;

