#!/usr/bin/perl
 
# StrongBox version 2.3
# Copyright 2001, 2002, 2003, 2004, 2005
# Ray Morris <support@webmastersguide.com>

use Socket;
use strict;
use IO::Socket;
# use Time::HiRes qw(time);

my $debug;

my $uselonglist = 0;


BEGIN{
	$debug = 0;
	if($debug){
		print"Content-type: text/plain\n\n";
		open(STDERR,">&STDOUT");
		select(STDERR);$|=1;
		select(STDOUT);$|=1;
	}
}


sub gettime {
       
	my @server;
	my $time = 0;
	my $i = 0;

        if ($uselonglist) {
            @server = &list;
        } else {
             @server = &slist;
        }
	until($time) {
                unless(defined($server[$i])) {last;}
                $time = &try_server_port123($server[$i]);
                $i++;
        }
	if ($time) {
		print "got time via port 123 from $server[$i]: $time\n" if ($debug);
		return int($time)
	}

	$time = 0;
	$i = 0;
	until($time) {
		unless(  defined($server[$i])  ) {last;}
		$time = &try_server_port37($server[$i]);
		$i++;
	}
	if ($time) {
                print "got time via port 37 from $server[$i]: $time\n" if ($debug);
                return int($time)
        }

	print "punting with call to time(): ". time() . "\n" if ($debug);
	return time();	# If we can't reach a time server, punt
}


sub try_server_port37 {
	my $server = $_[0];
	my($secsIn70years)    = 2208988800;
	my($buffer)           = '';
	my($proto)      = getprotobyname('tcp')        || 6;
	my($port)       = getservbyname('time', 'tcp') || 37;
    my $serverTime;
    my $oldalarm;
        
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            $oldalarm = alarm 1;
            my($serverAddr) = (gethostbyname($server))[4];
            socket(SOCKET, PF_INET, SOCK_STREAM, $proto)
                    or return(0);

            my($packFormat) = 'S n a4 x8';   # Windows 95, SunOs 4.1+

            # my($packFormat) = 'S n c4 x8';   # SunOs 5.4+ (Solaris 2)

            print "trying $server via time on port 37\n" if ($debug);
            connect(SOCKET, pack($packFormat, AF_INET(), $port, $serverAddr))
                    or return(0);

            read(SOCKET, $buffer, 4);
            close(SOCKET);
            $serverTime  = unpack("N", $buffer);
            $serverTime -= $secsIn70years;
        };
    alarm $oldalarm;
	return $serverTime;
}



sub try_server_port123 {
    my $server = $_[0];
  	my $timeout = 1;
	my $serverIPv4 ="";
  	if (gethostbyname($server)) {
    		$serverIPv4 = sprintf("%d.%d.%d.%d",unpack("C4",gethostbyname($server)));
  	}

	
  my ($LocalTime0, $LocalTime0F, $LocalTime0H, $LocalTime0FH, $LocalTime0FB);
  my ($LocalTime1, $LocalTime2);
  my ($LocalTime, $LocalTimeF, $LocalTimeT);
  my ($NetTime, $NetTime2, $Netfraction);
  my ($netround, $netdelay, $off);
  
  my ($Byte1, $Stratum, $Poll, $Precision,
      $RootDelay, $RootDelayFB, $RootDisp, $RootDispFB, $ReferenceIdent,
      $ReferenceTime, $ReferenceTimeFB, $OriginateTime, $OriginateTimeFB,
      $ReceiveTime, $ReceiveTimeFB, $TransmitTime, $TransmitTimeFB);
  my ($dummy, $RootDelayH, $RootDelayFH, $RootDispH, $RootDispFH, $ReferenceIdentT,
      $ReferenceTimeH, $ReferenceTimeFH, $OriginateTimeH, $OriginateTimeFH,
      $ReceiveTimeH, $ReceiveTimeFH, $TransmitTimeH, $TransmitTimeFH);
  my ($LI, $VN, $Mode, $sc, $PollT, $PrecisionV, $ReferenceT, $ReferenceIPv4);
  
  my $ntp_msg;  # NTP message according to NTP/SNTP protocol specification


# open the connection to the ntp server,
  # prepare the ntp request packet
  # send and receive
  # take local timestamps before and after

    my ($remote);
    my ($rin, $rout, $eout) ="";
    
    print "trying '$server' via ntp\n" if ($debug);
    # open the connection to the ntp server
    $remote = IO::Socket::INET -> new(Proto => "udp", PeerAddr => $server,
                                      PeerPort => 123,
                                      Timeout => $timeout) or return 0;

    # measure local time BEFORE timeserver query
    $LocalTime1 = time();
    # convert fm unix epoch time to NTP timestamp
    $LocalTime0 = $LocalTime1 + 2208988800;

    # prepare local timestamp for transmission in our request packet
    $LocalTime0F = $LocalTime0 - int($LocalTime0);
    $LocalTime0FB = frac2bin($LocalTime0F);
    $LocalTime0H = unpack("H8",(pack("N", int($LocalTime0))));
    $LocalTime0FH = unpack("H8",(pack("B32", $LocalTime0FB)));

    $ntp_msg = pack("B8 C3 N10 B32", '00011011', (0)x12, int($LocalTime0), $LocalTime0FB);
                   # LI=0, VN=3, Mode=3 (client), remainder msg is 12 nulls
                   # and the local TxTimestamp derived from $LocalTime1

    # send the ntp-request to the server
    $remote -> send($ntp_msg) or return undef;
    vec($rin, fileno($remote), 1) = 1;
    select($rout=$rin, undef, $eout=$rin, $timeout) or return 0;

    # receive the ntp-message from the server
    $remote -> recv($ntp_msg, length($ntp_msg)) or return 0;

    return(&interpret_ntp_data($ntp_msg));

}


sub slist {
    # It could take a long time to time out on all of the servers 
    # in longlist() if a firewall blocked our outgoing requests.
    my @remoteServer = (
        'localhost',
        'us.pool.ntp.org',
        'ntp0.cornell.edu',
        'rolex.usg.edu',
        'cuckoo.nevada.edu'
    );
    return @remoteServer;
}



sub list {
    # It will take a long time to time out 
    # on all of these servers if a firewall 
    # blocks our outgoing requests.
    my @remoteServer = (
        'localhost',
        'us.pool.ntp.org',
        'ntp0.cornell.edu',
        'rolex.usg.edu',
        'timex.usg.edu',
        'cuckoo.nevada.edu',
        'sundial.columbia.edu',
        'timex.cs.columbia.edu',
        'clock-1.cs.cmu.edu',
        'clock-2.cs.cmu.edu',
        'clock.psu.edu',
        'ntp-1.ece.cmu.edu',
        'ntp-2.ece.cmu.edu',
        'sushi.compsci.lyon.edu',
        'ntp.ucsd.edu',
        'ntp1.sf-bay.org',
        'ntp2.sf-bay.org',
        'time.berkeley.netdot.net',
        'time.five-ten-sg.com',
        'louie.udel.edu',
        'ntp.shorty.com',
        'ntp-0.cso.uiuc.edu',
        'ntp-1.cso.uiuc.edu',
        'ntp-2.cso.uiuc.edu',
        'cisco3.cerias.purdue.edu',
        'gilbreth.ecn.purdue.edu',
        'harbor.ecn.purdue.edu',
        'molecule.ecn.purdue.edu',
        'ntp1.kansas.net',
        'ntp.ourconcord.net',
        'ns.nts.umn.edu',
        'nss.nts.umn.edu',
        'chronos1.umt.edu',
        'chronos2.umt.edu',
        'chronos3.umt.edu',
        'clock1.unc.edu',
        'tick.jrc.us',
        'tock.jrc.us',
        'clock.linuxshell.net',
        'ntp.ctr.columbia.edu',
        'fuzz.psc.edu',
        'ntp.cox.smu.edu',
        'ntp.fnbhs.com',
        'ntp-1.vt.edu',
        'ntp-2.vt.edu',
        'ntp.cmr.gov',
        'ntp3.sf-bay.org',
        'ntp.cs.unp.ac.za',
        'reloj.kjsl.com',
        'raydesk1.wellfuckit.com'
    );
    return @remoteServer;
}



sub time_local {
	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
                                                localtime(time);
	return ($hour, $min);

}




  sub bin2frac { # convert a binary string to fraction
    my @bin = split '', shift;
    my $frac = 0;
    while (@bin) {
      $frac = ($frac + pop @bin)/2;
    }
    $frac;
  } # end sub bin2frac

  sub frac2bin { # convert a fraction to binary string (B32)
    my $frac = shift;
    my $bin ="";
    while (length($bin) < 32) {
      $bin = $bin . int($frac*2);
      $frac = $frac*2 - int($frac*2);
    }
    $bin;
  } # end sub frac2bin





sub interpret_ntp_data {
  # do some interpretations of the data

    my $ntp_msg = shift;
	
	my $sc;
	my $PrecisionV;

    # unpack the received ntp-message into long integer and binary values
    my ( $Byte1, $Stratum, $Poll, $Precision,
      $RootDelay, $RootDelayFB, $RootDisp, $RootDispFB, $ReferenceIdent,
      $ReferenceTime, $ReferenceTimeFB, $OriginateTime, $OriginateTimeFB,
      $ReceiveTime, $ReceiveTimeFB, $TransmitTime, $TransmitTimeFB) =
      unpack ("a C3   n B16 n B16 H8   N B32 N B32   N B32 N B32", $ntp_msg);

    # again unpack the received ntp-message into hex and ASCII values
    my ( $dummy1, $dummy2, $dummy3, $dummy4,
      $RootDelayH, $RootDelayFH, $RootDispH, $RootDispFH, $ReferenceIdentT,
      $ReferenceTimeH, $ReferenceTimeFH, $OriginateTimeH, $OriginateTimeFH,
      $ReceiveTimeH, $ReceiveTimeFH, $TransmitTimeH, $TransmitTimeFH) =
      unpack ("a C3   H4 H4 H4 H4 A4   H8 H8 H8 H8   H8 H8 H8 H8", $ntp_msg);

    my $LI = unpack("C", $Byte1 & "\xC0") >> 6;
    my $VN = unpack("C", $Byte1 & "\x38") >> 3;
    my $Mode = unpack("C", $Byte1 & "\x07");
    if ($Stratum < 2) {$sc = $Stratum;}
    else {
      if ($Stratum > 1) {
        if ($Stratum < 16) {$sc = 2;} else {$sc = 16;}
      }
    }
    my $PollT = 2**($Poll);
    if ($Precision > 127) {$Precision = $Precision - 255;}
    $PrecisionV = sprintf("%1.4e",2**$Precision);
    $RootDelay += bin2frac($RootDelayFB);
    $RootDelay = sprintf("%.4f", $RootDelay);
    $RootDisp += bin2frac($RootDispFB);
    $RootDisp = sprintf("%.4f", $RootDisp);
    my $ReferenceT = "";
    if ($Stratum eq 1) {$ReferenceT = "[$ReferenceIdentT]";}
    else {
      if ($Stratum eq 2) {
        if ($VN eq 3) {
          my $ReferenceIPv4 = sprintf("%d.%d.%d.%d",unpack("C4",$ReferenceIdentT));
          $ReferenceT = "[32bit IPv4 address $ReferenceIPv4 of the ref src]";
        }
        else {
          if ($VN eq 4) {$ReferenceT = "[low 32bits of latest TX timestamp of reference src]";}
        }
      }
    }

    $ReferenceTime += bin2frac($ReferenceTimeFB);
    $OriginateTime += bin2frac($OriginateTimeFB);
    $ReceiveTime += bin2frac($ReceiveTimeFB);
    $TransmitTime += bin2frac($TransmitTimeFB);

    $TransmitTime -= 2208988800;
	

    return($TransmitTime);

  } # end sub interpret_ntp_data 



return 1;


