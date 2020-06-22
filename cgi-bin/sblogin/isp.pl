#!/usr/bin/perl
 
use lib "./lib";
use Net::Whois::IP;

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

sub ip2org() {
    my $timeout = $_[1];
    $_[0] =~ /^([0-9]*\.[0-9]*\.[0-9]*)/;
    my $subnet = $1;
    $timeout ||= 6;
    &rmold($tmpdir, 7, 0) unless (time() % 100);
    if (-f "$tmpdir/sblookup-$subnet") {
        print "file exists: $tmpdir/sblookup-$subnet\n" if ($debug);
        my ($country, $orgname) = &ip2org_file($_[0]);
        return (uc($country), $orgname);
    } else {
        mkdir("$tmpdir", 0777) || die "Cannot mkdir $tmpdir: $!" unless (-e $tmpdir);
        print "creating: $tmpdir/sblookup-$subnet\n" if ($debug);
        open(CACHE, ">$tmpdir/sblookup-$subnet") or die "could not open '$tmpdir/sblookup-$subnet': $!";
        chmod 0666, "$tmpdir/sblookup-$subnet";
        my ($country, $orgname) = &ip2org_whois($_[0], $timeout);
        $country = substr($country, 0, 2);
	print "country: $country, isp: $orgname\n" if ($debug);
        print CACHE "$country:$orgname";
        close CACHE;
        return (uc($country), $orgname);
    }
}

sub ip2org_file() {
    $_[0] =~ /^([0-9]*\.[0-9]*\.[0-9]*)/;
    my $subnet = $1;
    open(CACHE, "<$tmpdir/sblookup-$subnet") or die "could not open '$tmpdir/sblookup-$subnet': $!";
    $line = <CACHE>;
    close CACHE;
    unlink "$tmpdir/sblookup-$subnet" if ( ($line =~ /^X/) && (-M "$tmpdir/sblookup-$subnet" > 0.1) );
    print "isp cache file says: $line\n" if ($debug);
    return split(/:/, $line);
}

sub ip2org_whois {
    my $ip = $_[0];
    my $timeout = $_[1];
    $timeout ||= 6;

    my $country = 'XX';
    my $orgname = 'XX';


    eval {
        local $SIG{ALRM} = sub {die "GOT TIRED OF WAITING"};
        my $oldalarm = alarm($timeout);
        # setalarm($timeout, sub {die "GOT TIRED OF WAITING"});
        my $response = whoisip_query($_[0]);
        if ($debug) {
            foreach (sort keys(%{$response}) ) { 
                print "$_: " . $response->{$_} . "\n"; 
            }
        }
        $orgname = $response->{'OrgName'};
        $techemaildomain = $1 if $response->{'OrgTechEmail'} =~ /\@(.*)/;
        unless($techemaildomain) {
            $techemaildomain = $1 if $response->{'TechEmail'} =~ /\@(.*)/;
        }
        $orgname = $techemaildomain unless ($orgname);
        $orgname = $response->{'OrgTechName'} unless ($orgname);
        $orgname = $response->{'org-name'} unless ($orgname);
        $orgname = $response->{'CustName'} unless ($orgname);
        $orgname = $response->{'descr'} unless ($orgname);
        $orgname = $response->{'NetName'} unless ($orgname);
        $orgname = $response->{'netname'} unless ($orgname);
        $orgname = $response->{'owner'} unless ($orgname);
        # $orgname = $response->{'descr'} unless ($orgname);
        $country = $response->{'Country'};
        $country = $response->{'country'} unless ($country);
    };
    if ($@ =~ /GOT TIRED OF WAITING/) {
        alarm $oldalarm;
        return('XX', 'XX...........');
    }
    alarm $oldalarm;
    $orgname = $1 if ($orgname =~ /^([0-9]*\.[0-9]*\.)/);
    chomp $orgname;
    chomp $country;
    $orgname =~ s/\r*$//;
    $country =~ s/\r*$//;
    $orgname = substr("$orgname........................",0,13);
    return ($country, $orgname);
}

sub rmold {
    my $dirpath = $_[0];
    my $age     = $_[1];
    my $rmbase  = $_[2];
    $rmbase = 1 unless ( defined($_[2]) );

    return unless (-e "$dirpath");
    if ( (-f $dirpath) && (-A $dirpath > $age) ){
            unlink $dirpath or die "could not remove \"$dirpath\": $!";
    } else {
            opendir(DH, $dirpath);
            my @files = readdir(DH);
            closedir(DH);
            foreach my $file(@files) {
                    next if ( ($file eq ".") || ($file eq "..") );
                    if (-d "$dirpath/$file") {
                        &rmold("$dirpath/$file", $age, 1);
                    } elsif (-A "$dirpath/$file" > $age) {
                        unlink "$dirpath/$file" or die "could not remove \"$dirpath/$file\": $!";
                    }
            }
            if ( $rmbase && (-A $dirpath > $age) ) {
                rmdir($dirpath) or 1;   # Ok to not delete empty directory
            }
        }
}

1;
