package Strongbox::Plugin::Turing::AfterFail;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.

use strict;
use warnings;

my $turing_first_time = 0;
my $debug = $main::debug;

my $sessionfiles = $main::sessionfiles;
&x_forward_ip();
my $flag = $sessionfiles . '/failed_once/' . $main::ENV{'REMOTE_ADDR'};
print "PLUGIN " . __PACKAGE__ .  " setting flag to: $flag\n" if ($debug);

my $cookiehash;
if ($turing_first_time) {
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
                    use lib $main::sessionfiles . '/../lib';
                    require MD5;
                    import MD5 'md5_hex';
                }
      }
      if ($@) {
          die "I can't find any MD5 module anywhere, not even the pure perl one: $!";
      }
      $cookiehash = md5_hex($main::ENV{'REMOTE_ADDR'} . $main::key);
      print "PLUGIN " . __PACKAGE__ .  " setting cookiehash to $cookiehash\n" if ($debug);
}

sub showturing {
    my $class = shift();

    if ($turing_first_time) {
        return 1 unless ( defined($main::ENV{'HTTP_COOKIE'}) );
        return 1 unless ($main::ENV{'HTTP_COOKIE'} =~ /$cookiehash/);
    } elsif ( -f $flag && (-M $flag < 0.1) ) {
        # If they have had a failed login recently, show the Turing
        return 1;
    }
    return 0;
}

sub checkturing {
    my $class = shift();
    my $args = shift();

    if ($turing_first_time) {
        print "PLUGIN " . __PACKAGE__ .  " (checkturing) checking if cookiehash is set\n" if ($debug);
        return 1 unless ($main::ENV{'HTTP_COOKIE'} =~ /$cookiehash/);
    }
    print "PLUGIN " . __PACKAGE__ .  " (checkturing) cookiehash is NOT set, checking FLAG\n" if ($debug);
    # If they aren't flagged as having a failed login, we treat it as correct.
    unless ( -f $flag && (-M $flag < 0.09) ) {
        $args->{'return'} = 1;
	print "PLUGIN " . __PACKAGE__ .  "flag is there, so we'll treat turing it as correct\n" if ($debug);
        return 0;
    }
    return 1;
}

sub errlog {
    print "PLUGIN " . __PACKAGE__ .  " failed login, creating $flag\n" if ($debug);
    unless (-e $sessionfiles . '/failed_once') {
        mkdir($sessionfiles . '/failed_once', 0777) or die "could not mkdir '$sessionfiles/failed_once': $!"
    }
    unless (-f $flag) {
        open FLG, ">$flag" or die "could not open '$flag': $!";
        close FLG;
    }
}

sub sqllog_errlog_begin { &errlog(); }

sub go_goodpage {
    my $class = shift();
    my $args = shift();
    print &set_cookie('sbth', $cookiehash, 3000000, '/', $main::host), "\n";
    if ( -f $flag) {
        print "PLUGIN " . __PACKAGE__ .  " good login, removing flag: $flag\n" if ($debug);
        unlink($flag) or die "could not remove '$flag': $!";
    }
    &rmold unless ( time() % 20 );
}


sub set_cookie() {
  my ($name,$value,$expires,$path,$domain) = @_;
  $name=&cookie_scrub($name);
  $value=&cookie_scrub($value);
  $expires=$expires * 60;
  my $expire_at=&cookie_date($expires);
  my $namevalue="$name=$value";
  my $COOKIE="";
  if ($expires != 0) {
     $COOKIE= "Set-Cookie: $namevalue; expires=$expire_at; ";
  } else {
     $COOKIE= "Set-Cookie: $namevalue; ";   #current session cookie if 0
  }
  if ($path ne ""){
     $COOKIE .= "path=$path; ";
  }
  if ($domain ne ""){
     $COOKIE .= "domain=$domain; ";
  }

  return $COOKIE;
}

sub cookie_date() {
  my ($seconds) = @_;

  my %mn = ('Jan','01', 'Feb','02', 'Mar','03', 'Apr','04',
            'May','05', 'Jun','06', 'Jul','07', 'Aug','08',
            'Sep','09', 'Oct','10', 'Nov','11', 'Dec','12' );
  my $sydate=gmtime(time+$seconds);
  my ($day, $month, $num, $time, $year) = split(/\s+/,$sydate);
  my    $zl=length($num);
  if ($zl == 1) {
      $num = "0$num";
  }

  my $retdate="$day $num-$month-$year $time GMT";
  return $retdate;
}

sub rmold {
    print "PLUGIN " . __PACKAGE__ . " removing old AfterFail (failed_once/)\n" if ($debug);
    opendir( DIR, $sessionfiles . '/failed_once' ) or die "could not opendir '$sessionfiles/failed_once': $!";
    my @sessions = grep( !/^\.\.?$/, readdir(DIR) );
    closedir(DIR);
    foreach my $entry (@sessions) {
        if ( -M "$sessionfiles/failed_once/$entry" > 0.2 ) {
            unlink( "$sessionfiles/failed_once/$entry" );
        }
    }
}

sub cookie_scrub() {
  my($retval) = @_;
  $retval=~s/\;//;
  $retval=~s/\=//;
  return $retval;
}

sub x_forward_ip {
    push(@main::trustedips, $main::ENV{'SERVER_ADDR'});
    if (grep { $main::ENV{'REMOTE_ADDR'} =~ /^$_$/ } @main::trustedips) {
        print "REMOTE_ADDR $main::ENV{'REMOTE_ADDR'} is trusted\n" if ($debug);
        $main::ENV{'REMOTE_ADDR'} = $main::cgi->{'remote_addr'} if ($main::cgi->{'remote_addr'});
        $main::ENV{'HTTP_USER_AGENT'} = $main::cgi->{'user_agent'} if ($main::cgi->{'user_agent'});
        $main::ENV{'HTTP_ACCEPT'} = $main::cgi->{'accept'} if ($main::cgi->{'accept'});
	# TODO: Use better regex to math IPv4 and IPv6
        if ($main::ENV{'HTTP_X_FORWARDED_FOR'} =~ m/([0-9\.]+|[\da-f\:]+)\s*$/i) {
            $main::ENV{'REMOTE_ADDR'} = $1;
        }
    }
}

1;

