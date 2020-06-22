# StrongBox version 5.0
# Copyright 2001-2015, Ray Morris <support@bettercgi.com>
# Copyright information: https://www.bettercgi.com/copyright/
                                                                                                                             
# This script uses the IP-to-Country Database
# provided by WebHosting.Info (http://www.webhosting.info),
# available from http://ip-to-country.webhosting.info."

package ProxyCheck;

use IO::Socket;
# use strict;

my $debug = $main::debug;

$ENV{'TMPDIR'} ||= ($ENV{'TMP'});
$ENV{'TMPDIR'} ||= ($ENV{'TEMP'});
$ENV{'TMPDIR'} ||= '/tmp' if (-d '/tmp');
$ENV{'TMPDIR'} ||= 'c:/temp' if (-d 'c:/temp');
$ENV{'TMPDIR'} ||= 'c:/windows/temp' if (-d 'c:/windows/temp');
die "No temporary directory found.  (Admin should set TMPDIR!)" unless ($ENV{'TMPDIR'});
$tmpdir = "$ENV{'TMPDIR'}/sblookup_" . $> ;

unless (-d $tmpdir) {
    my $oldumask = umask(0000);
    mkdir($tmpdir, 0777) or die ("could not create temp directory '$tmpdir': $!");
    # mkdir($tmpdir, 0777) or $tmpdir = "/tmp";
    umask($oldumask);
}


my($sock, $server_host, $msg, $port, $ipaddr, $thishost,
   $MAXLEN, $PORTNO, $TIMEOUT);

$MAXLEN  = 1024;
$PORTNO  = 5151;
$TIMEOUT = 1;
$server_host = "proxycheck.comglobalit.com";


# For broken Net::DNS :
# $server_host = `dig +short proxycheck.bettercgi.com`;

my %country;
my %proxy;
my %aol;
my %checked;

$thishost = $ENV{'HTTP_HOST'};
$thishost =~ s/www\.//;
$thishost =~ s/sb[^\.]+\.//;
$thishost =~ s/\:.*//;

# 1 = UDP based
# 2 = DNS based
$protocol_version = 1;

sub checkip {
	my $queryip = $_[0];
        $TIMEOUT = $_[1] if ($_[1]);
        $checked{$queryip} = 1;
        my $msg;
        my $cachefile = "$tmpdir/proxycheck-$queryip";
        $country{$queryip} = "XX";
        $proxy{$queryip} = 0;
        $checked{$_[0]} = 1;

        print "In proxycheck.pl, checking $queryip...\n" if ($debug);
        my $oldalarm;
        if ( -f $cachefile ) {
            open(CACHE, "<$cachefile") or die "could not open '$cachefile': $!";
            $msg = <CACHE>;
            print "Got cached msg from $cachefile , msg = $msg \n" if ($debug);
            close CACHE;
        } else {
            eval {
                #local $SIG{ALRM} = sub { die "alarm time out, check Strongbox User's Manual\n" };
                local $SIG{ALRM} = sub { die "Strongbox Remote Proxy Check Feature not enabled.\n" };
                $oldalarm = alarm $TIMEOUT;
		if ( $protocol_version == 1 ) {
			my $ip;
			print "Using UDP based check, protocol v$protocol_version...\n" if ($debug);
			print "resolving $server_host...\n" if ($debug);
			unless ( ( $ip = inet_aton($server_host) ) && ( $address = inet_ntoa($ip) )  ) {
			    print "error resolving server: $!\n" if ($debug);
			    warn "error resolving server: $!";
			    alarm($oldalarm);
			    return 0;
			}
			print "\$address: $address\n" if ($debug);

			$sock = IO::Socket::INET->new(  Proto => 'udp',
							PeerPort  => $PORTNO,
							PeerAddr  => $address
						      )
			    or warn "Creating socket: $!\n";

			$msg = "query:$queryip:$thishost";
			print "sending query '$msg'\n" if ($debug);
			$sock->send($msg) or die "Proxycheck failed, check outgoing firewall. Error '$!'";
			print "waiting for reply\n" if ($debug);
			$sock->recv($msg, $MAXLEN)      or die "recv: $!";
			print "got reply $msg\n" if ($debug);
			alarm $oldalarm;
		} elsif ( $protocol_version == 2 ) {
			print "Using DNS based check, procol v$protocol_version...\n" if ($debug);
			$msg = "$queryip.pcv2.$thishost.proxycheck2.bettercgi.com.";
			print "query: $msg\n" if ($debug);
			# If gethostbyname doesn't work for any reason, or prefer to use dig
			# $response = inet_aton(`dig +short $msg`);
            $ENV{RES_OPTIONS} = "timeout:$TIMEOUT attempts:1";
			$response = scalar gethostbyname($msg);
			my ($code, $country) = unpack('nA2', $response);
			print "response = " . inet_ntoa($response) ."\ncode: $code\ncountry = $country\n" if ($debug);
			$msg = "answer:$queryip:$code:$country";
			alarm $oldalarm;
		}
                1;  # return value from eval on normalcy
            };
            print "\$@\: ", $@, "\n" if ($debug);
            if ($@) {
                warn "timed out - check firewall and resolver - $@";
                $proxy{$queryip} = 0;
                $country{$queryip} = 'XX';
                $aol{$queryip} = 0;
                alarm($oldalarm);
                return 0;
            }

            open(CACHE, ">$cachefile") or die "could not open '$cachefile': $!";
            print CACHE $msg;
            close CACHE;
            chmod 0666, "$cachefile";
        }

        my ($command, $arg, $code, $where) = split (":", $msg);
        if ( ($command eq "answer") && ($code < 400) && ($arg eq $queryip) ) {
            $proxy{$queryip} = 1;
        } else {
            $proxy{$queryip} = 0;
	}
        $where = substr($where, 0,2);
        if ($where) {
	    $country{$queryip} = $where;
        } else {
            $country{$queryip} = 'XX';
        }
        if ($code == 555) {
            $aol{$queryip} = 1;
        } else {
            $aol{$queryip} = 0;
        }
}



sub fromcountry {
    &checkip($_[0]) unless ($checked{$_[0]});
    return uc($country{$_[0]});
}


sub isproxy {
    &checkip($_[0], $_[1]) unless ($checked{$_[0]});
    return $proxy{$_[0]};
}

sub isaol {
    &checkip($_[0], $_[1]) unless ($checked{$_[0]});
    return $aol{$_[0]};
}


1;


