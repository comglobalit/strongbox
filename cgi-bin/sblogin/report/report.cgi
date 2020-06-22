#!/usr/bin/perl 

BEGIN {
        $debug     = 0; $debug = 0 if ($ENV{'REMOTE_ADDR'} =~ /^74.192.17.33|^74.192.199.39/ );
        if ($debug) {
                print "Content-type: text/plain\n\n";
                open (STDERR, ">&STDOUT");
                select(STDERR); $| = 1;
                select(STDOUT); $| = 1;
        }
}


$localdebug = $debug;

use lib '../lib/';
use lib '..';
require '../config.pl';
require "./config_reports.pl";
use Time::Local;
 
require "../routines.pl";
&am_admin();

#$debug = $localdebug || $debug;

my  $cgi = &parse_query();

my $show_top = $cgi->{'show_top'};
my $begin_date = "$cgi->{'begin_month'}/$cgi->{'begin_day'}/$cgi->{'begin_year'}";
my $end_date = "$cgi->{'end_month'}/$cgi->{'end_day'}/$cgi->{'end_year'}";

print "\$end_date: $end_date\n" if ($debug);


my $begin = timegm(0,0,0,$cgi->{'begin_day'},$cgi->{'begin_month'} -1,$cgi->{'begin_year'});
my $end = timegm(59,59,23,$cgi->{'end_day'},$cgi->{'end_month'} - 1,$cgi->{'end_year'});
print "begin: $begin\nend: $end\n" if ($debug);

$cgi->{'goodonly'} = 0 unless ( defined($cgi->{'goodonly'}) );
my $totalattempts = 0;
my $totalerrors = 0;
my $totalusers = 0;
my $totalips = 0;
my $totalcountries = 0;

&rmoldreports;
&do_plugins('report_pre_read_log', $cgi);
&read_log;
&print_results_html;


sub read_log() {

    my @log;
    my $skipok = 1;
    foreach $logfile (@logfiles) {
        my $logsize = (-s "$logfile");
        open LOG, "$logfile";
        while (my $line = <LOG>) {
		    chomp $line;
		    my ($user, $time, $ip1, $ip2, $ip3, $lstat, $sbsession,$lcountry, $lorgname) = split(":", $line);
            # seek forward only if there will be a line to read after the seek.
            if (  $skipok && ($time < $begin) && ( tell(LOG) < $logsize - ($reclen * 101) )  ) {
                seek LOG, $reclen * 100, 1;
                $line = <LOG>;
                $line = <LOG>;
                chomp $line;
                my ($user, $time, $ip1, $ip2, $ip3, $lstat, $sbsession,$lcountry, $lorgname) = split(":", $line);
                if ($time > $begin) {
                    $skipok = 0;
                    if (tell(LOG) < $reclen * 102)  {
                        print "skipping back to start\n\n" if ($debug);
                        seek LOG, 0, 1;
                    } else {
                        print "skipping 102 records back\n\n" if ($debug);
                        seek LOG, $reclen * -102, 1;
                        $line = <LOG>;
                    }
                }
                next;
            }
            next if ($time < $begin);
            last if ($time > $end);
            print "lstat: $lstat\n\n" if ($debug);
            next unless ( ($cgi->{'goodonly'} == 0) || ($lstat =~ m/^good/) );
            next unless ( ($lcountry eq $contents{'cnty'}) || (! $contents{'cnty'}));
            push (@log, $line);
	    }
        close LOG;
    }

    foreach $entry (@log) {
        chomp $entry;
        print "entry: $entry\n\n" if ($debug);
        ($user, $time, $ip1, $ip2, $ip3, $lstat, $sbsession,$lcountry, $lorgname) = split(":", $entry);
        $user =~ s/[\.\-]+$//g;
        $totalattempts++;
        print "adding $entry\n" if ($debug);
        $totalusers++ if ($#{$ips_per_user{$user}} < 0);
        $totalips++ if ($#{$users_per_ip{"$ip1.$ip2.$ip3"}} < 0);

        push @{$ips_per_user{$user}}, "$ip1.$ip2.$ip3";
        push @{$users_per_ip{"$ip1.$ip2.$ip3"}}, "$user";
        push @{$countries_per_user{$user}}, "$lcountry" unless ($lcountry eq 'XX');
        push @{$orgnames_per_user{$user}}, "$lorgname" unless ($lorgname eq 'XX');
        $ip_status{"$ip1.$ip2.$ip3"} = $lstat;
        $ip_country{"$ip1.$ip2.$ip3"} = $lcountry;
        $ip_orgname{"$ip1.$ip2.$ip3"} = $lorgname unless ($lorgname eq 'XX');
        $user_status{$user} = $lstat;
        unless ($lstat =~ /^good/) {
            $errors_per_user{"$user:$lstat"}++;
            if ($lstat =~ /uniqsubs|totllgns|uniqcnty|uniqisps/i) {
                $sususer{$user}++;
            } elsif ($lstat =~ /dis_/i) {
                $disuser{$user}++;
            } elsif ($lstat =~ /attempts/i) {
                $susip{"$ip1.$ip2.$ip3"}++;
            }
            $totalerrors++;
        }
        $loginspercountry{$lcountry}++ unless ($lcountry eq 'XX');
        $loginsperorgname{$lorgname}++;
    }
	$totalcountries = scalar keys (%loginspercountry);
    $totalorgnames = scalar keys (%loginsperorgname);
}
                                                                                                       



sub print_results_html() {
        my %numips;
        my %logins;
        my %numcountries;
        my %numorgs;

	my $totalsuccess = $totalattempts - $totalerrors;
	my $disusers=  scalar keys(%disuser);
	my $sususer = scalar keys(%sususer);
	my $susips = scalar keys(%susip);


print qq |Content-type: text/html

|;

my $tmpl_header = $ENV{DOCUMENT_ROOT} . "/sblogin/report/header.php";
my $tmpl_bottom = $ENV{DOCUMENT_ROOT} . "/sblogin/report/bottom.php";
open TMPL_HEADER,$tmpl_header;
while (my $line = <TMPL_HEADER>) {
        chomp $line;
        $line =~ s!..php echo ._SERVER..HTTP_HOST.. ..!$host - Report for dates $begin_date - $end_date!;
        print $line;
}
print qq |<h1>StrongBox Report $begin_date - $end_date</h1>
<a href=\"/sblogin/report/\"><a href=\"/sblogin/report/\">Back to Main Page</a><br>

<ul>
<li>Site: $host</li>
<li>$totalattempts login attempts.
  <ul><li>$totalsuccess successful logins</li>
      <li>$totalerrors <a href="#errors">unsuccessful</a>.</li>
  </ul>
</li>

<li>$totalusers different <a href="#users">usernames</a> tried 
to login from
  <ul><li>$totalips different <a href="#ips">IP ranges</a></li>
      <li>from $totalorgnames ISPs</li>
      <li>in $totalcountries <a href="#countries">countries</a>.</li>
  </ul>
</li>
<li>$sususer usernames <a href="#suspended">suspended</a>, $disusers <a href="#disabled">disabled</a>.</li>
<li>$susips <a href="#suspendedips">IP ranges suspended</a>.</li>
</ul>
<hr>
|;
                                                                                                       
        print "<table><a name=\"users\"></a>\n";
	print "\t<caption>top $show_top users $begin_date - $end_date</caption>\n";
	print "<thead><th>username</th><th>last status</th><th>login attempts</th><th>IP ranges</th><th>Countries</th><th>ISPs</th></thead>\n\n";
        my $shown = 0;
        foreach $user (   sort SortIpsPerUser ( keys(%ips_per_user) )   ) {
                $logins{$user} = $#{$ips_per_user{"$user"}} + 1;
                my %ip_usage;
		foreach $ip (@{$ips_per_user{"$user"}}) {
                        $ip_usage{$ip}++;
                }
		$numips{$user} = scalar keys (%ip_usage);

		my %country_user;
		foreach $country (@{$countries_per_user{"$user"}}) {
                        $country_user{$country}++;
                }
                $numcountries{$user} = scalar keys (%country_user);

                my %orgname_user;
                foreach $org (@{$orgnames_per_user{"$user"}}) {
                        $orgname_user{$org}++;
                }
                $numorgs{$user} = scalar keys (%orgname_user);
                next if ($shown++ >= $show_top);
                $user_no_slash = $user;
                $user_no_slash =~ s/\///g;
                $user_encode = &urlencode($user_no_slash);
                $lccode = lc ($user_status{$user});
		print qq|
		<tr>
                    <td><a href="$reporturl/report_$user_encode.html">$user</a></td>
                    <td>(<a class="status" onClick="statushelp('$lccode')">$user_status{$user}</a>)</td>
		    <td>$logins{$user}</td>
		    <td>$numips{$user}</td>
		    <td>$numcountries{$user}</td>
                    <td>$numorgs{$user}</a>
                </tr>
		|;

		open(USER, ">$reportdir/report_$user_no_slash.html");
                print USER qq|
				<html>
				<head>
					<LINK REL=STYLESHEET TYPE="text/css" HREF="$reporturl/../../strongbox.css">
				        <script type="text/javascript">
						function statushelp(code) {
						PageURL="$reporturl/../../codes.html#" + code;
						WindowName="statuscodes";
						settings=
						"toolbar=no,location=no,directories=no,"+
						"status=no,menubar=no,scrollbars=yes,"+
						"resizable=yes,width=350,height=150";
						MyNewWindow=
						window.open(PageURL,WindowName,settings);
						}
                                                function countryhelp(code) {
                                                    PageURL="$reporturl/../countries.html#" + code;
                                                    WindowName="countrycodes";
                                                    settings=
                                                    "toolbar=no,location=no,directories=no,"+
                                                    "status=no,menubar=no,scrollbars=yes,"+
                                                    "resizable=yes,width=350,height=150";
                                                    MyNewWindow=
                                                    window.open(PageURL,WindowName,settings);
                                                }


					</script>

				<body>
                                        <div name=logout_link id=report_home_link><a href="/sblogin/report/"><h3>Strongbox Admin Area<h3></a></div><br>
					<h2>
					    $user ($user_status{$user}) $logins{$user} login attempts 
					    from $numips{$user} IP ranges in $numcountries{$user} countries on $numorgs{$user} ISPs
					</h2>
					<a href=\"$cgiurl/byuser.cgi?user=$user\">Detail Log</a><br>
					<table>
					<thead><th>Login Attempts</th><th>IP</th><th>Country</th><th>ISP</th></thead>
			|;
                foreach $ip (keys %ip_usage) {
                        $lccode = lc ($ip_status{$ip});
                        my $isp_org_enc = urlencode($ip_orgname{$ip});
                        print USER qq|
				    <tr>
			    <td>$ip_usage{$ip}</td>
			    <td><a href="$cgiurl/byip.cgi?ip=$ip">$ip</a> (<a class="status" onClick="statushelp('$lccode')">$ip_status{$ip}</a>)</td>
                            <td><a class="status" onClick="countryhelp('$ip_country{$ip}')">$ip_country{$ip}</a></td>
                            <td><a href="$cgiurl/byisp.cgi?isp=$ip_org_enc">$ip_orgname{$ip}</a></td>
			    </td>
                        </tr>
			|;
                }
                print USER "</table></body></html>\n\n";
                close USER;
                chmod(0666, "$reportdir/report_$user_no_slash.html");
        }
        print "</table><br><br>\n\n\n";
         



        print "<table><a name=\"ips\"><caption>top $show_top IPs $begin_date - $end_date</caption></a>\n\n";
	print "<thead><th>Login Attempts</th><th>IP</th><th>Country</th><th>ISP</th></thead>\n";
        $shown = 0;
        foreach $ip (   sort SortUsersPerIP ( keys(%users_per_ip) )   ) {
                last if ($shown == $show_top);
                $shown++;
                my $logins = $#{$users_per_ip{$ip}} + 1;
                my %user_attempts;
                my $ip_org_enc = urlencode($ip_orgname{$ip});
                $lccode = lc ($ip_status{$ip});
                print qq|
                <tr>
                    <td>$logins</td>
                    <td>
                        <a href=\"$reporturl/$ip.html\">$ip</a>
                        (<a class="status" onClick="statushelp('$lccode')">$ip_status{$ip}</a>) 
                    </td>
                    <td><a class="status" onClick="countryhelp('$ip_country{$ip}')">$ip_country{$ip}</a></td>
                    <td><a href="$cgiurl/byisp.cgi?isp=$ip_org_enc">$ip_orgname{$ip}</a></td>
                </tr>

                |;
                
                foreach $user (@{$users_per_ip{$ip}}) {
                        $user_attempts{"$user"}++;
                }
                open (IP, ">$reportdir/$ip.html");
		print IP qq|
                                <html>
                                <head>
					<LINK REL=STYLESHEET TYPE="text/css" HREF="$reporturl/../../strongbox.css">
                                        <script type="text/javascript">
                                                function statushelp(code) {
                                                PageURL="$reporturl/../../codes.html#" + code;
                                                WindowName="statuscodes";
                                                settings=
                                                "toolbar=no,location=no,directories=no,"+
                                                "status=no,menubar=no,scrollbars=yes,"+
                                                "resizable=yes,width=350,height=150";
                                                MyNewWindow=
                                                window.open(PageURL,WindowName,settings);
                                                }
                                            function countryhelp(code) {
                                                PageURL="$reporturl/../countries.html#" + code;
                                                WindowName="countrycodes";
                                                settings=
                                                "toolbar=no,location=no,directories=no,"+
                                                "status=no,menubar=no,scrollbars=yes,"+
                                                "resizable=yes,width=350,height=150";
                                                MyNewWindow=
                                                window.open(PageURL,WindowName,settings);
                                           } 
                                        </script>

                                </head>
                                <body>
			|;
                my $ip_org_enc = urlencode($ip_orgname{$ip});
                $lccode = lc ($ip_status{$ip});
                print IP qq|
                $ip (<a class="status" onClick="statushelp('$lccode')">$ip_status{$ip}</a>) 
                <a href="$cgiurl/byisp.cgi?isp=$ip_org_enc">$ip_orgname{$ip}</a> $ip_country{$ip} $logins total logins<br>
                <br>
                <a href="$cgiurl/byip.cgi?ip=$ip">Detail Log for $ip<a><br><br>
                |;
                if ($susip{$ip} && ($ip_status{$ip} ne 'gooduser') ) {
                    print IP "$ip recently suspended. <a href=\"cgiurl/usermanage.cgi?ip=$ip&action=reenableip\">Re-enable</a><br>\n";
                }
                $lccode = lc ($user_status{$user});
                print IP qq|
                <table>
		<thead><th>Username</th><th>Login Attempts</th></thead>
                |;
                foreach $user (keys %user_attempts) {
                        print IP "\t<tr>\n";
                        print IP "\t\t<td>\"<a href=\"$cgiurl/byuser.cgi?user=$user\">$user</a>\" (<a class=\"status\" onClick=\"statushelp('$lccode')\">$user_status{$user}</a>)</td>\n";
                        print IP "\t\t<td>" . $user_attempts{"$user"} . " logins</td>\n";
                      print IP "\t</tr>\n\n";
                }
                print IP "</table></body></html>\n\n";
                close IP;
                chmod(0666, "$reportdir/$ip.html");
        }
        print "</table><br><br>\n\n\n";
 

        print qq|
                    <table>
                        <caption>
                             <a name="disabled">Disabled Usernames $begin_date - $end_date</a>
                        </caption>
                        <thead>
                            <th>Username</th>
                            <th>Login Attempts</th>
                            <th>IP Ranges</th>
                            <th>ISPs</th>
                            <th>Countries</th>
                            </thead>
                 |;

        foreach $user ( keys(%disuser) ) {
                $lccode = lc ($user_status{$user});
                print qq|
                    <tr>
                        <td>
                            "<a href="$cgiurl/byuser.cgi?user=$user">$user</a>"
                            (<a class=\"status\" onClick=\"statushelp('$lccode')\">$user_status{$user}</a>)
                        </td>
                        <td>$logins{$user}</td>
                        <td>$numips{$user}</td>
                        <td>$numorgs{$user}</a>
                        <td>$numcountries{$user}</td>
                     <tr>
                    |;
        }
        print "</table><br><br>\n\n\n";




        print qq|
                    <table>
                        <caption>
                             <a name="suspended">Suspended Usernames $begin_date - $end_date</a>
                        </caption>
                        <thead>
                            <th>Username</th>
                            <th>Login Attempts</th>
                            <th>IP Ranges</th>
                            <th>ISPs</th>
                            <th>Countries</th>
                            </thead>
                 |;
                                                                                                                                                                                                        
        foreach $user ( keys(%sususer) ) {
                $lccode = lc ($user_status{$user});
                print qq|
                    <tr>
                        <td>
                            "<a href="$cgiurl/byuser.cgi?user=$user">$user</a>"
                            (<a class=\"status\" onClick=\"statushelp('$lccode')\">$user_status{$user}</a>)
                        </td>
                        <td>$user</td>
                        <td>$numips{$user}</td>
                        <td>$numorgs{$user}</a>
                        <td>$numcountries{$user}</td>
                     <tr>
                    |;
        }
        print "</table><br><br>\n\n";
                                                                                                                                                                                                        
        print qq|
                    <table>
                        <caption>
                             <a name="suspendedips">Suspended IPs $begin_date - $end_date</a>
                        </caption>
                        <thead>
                            <th>IP</th>
                            <th>Attempts</th>
                            <th>Blocked</th>
                            <th>ISP</th>
                            <th>Country</th>
                            </thead>
                 |;



        foreach $ip ( keys(%susip) ) {
                my $numattempts = scalar @{$users_per_ip{$ip}};
                my $ip_org_enc = urlencode($ip_orgname{$ip});
                print qq|
                    <tr>
                        <td>
                            "<a href="$cgiurl/byip.cgi?ip=$ip">$ip</a>"
                        </td>
                        <td>$numattempts</td>
                        <td>$susip{$ip}</td>
                        <td><a href="$cgiurl/byisp.cgi?isp=$ip_org_enc">$ip_orgname{$ip}</a></td>
                        <td><a class="status" onClick="countryhelp('$ip_country{$ip}')">$ip_country{$ip}</a></td>
                     <tr>
                    |;
        }
        print "</table><br><br>\n\n";



        print "<table><a name=\"errors\"><caption>top $show_top unsuccessful logins $begin_date - $end_date</caption></a>\n\n";
	print "<thead><th>username</th><th>status</th><th>Count</th></thead>\n";
        $shown = 0;
        foreach $usererror (   sort SortErrorsPerUser ( keys(%errors_per_user) )   ) {
                last if ($shown == $show_top);
                $shown++;
                $logins = $errors_per_user{$usererror};
                ($user, $error) = split(":", $usererror);
                $lccode = lc ($error);
                print "\t<tr>\n";
                print "\t\t<td>\"<a href=\"$cgiurl/byuser.cgi?user=$user\">$user</a>\"</td>\n";
                print "\t\t<td><a class=\"status\" onClick=\"statushelp('$lccode')\">$error</a></td>\n";
                print "\t\t<td>$logins times</td>\n";
                print "\t</tr>\n\n";
        }
        print "</table><br><br>\n\n";


	print "<table><a name=\"countries\"><caption>top $show_top countries $begin_date - $end_date</caption></a>\n\n";
	print "<thead><th>Country</th><th>Login Attempts</th></thead>\n";
        $shown = 0;
        foreach my $nation (   sort SortCountries ( keys(%loginspercountry) )   ) {
                last if ($shown == $show_top);
                $shown++;
                print "\t<tr><td><a href=\"$cgiurl/bycnty.cgi?cnty=$nation\">$nation</a>\</td><td>$loginspercountry{$nation}</td></tr>\n";
        }
        print "</table>";

open TMPL_BOTTOM,$tmpl_bottom;
while (my $line = <TMPL_BOTTOM>) {
        chomp $line;
        print $line;
}
                                                                                                       
                                                                                                       
}
                                                                                                       

                                                                                                       
sub SortIpsPerUser {
        $#{$ips_per_user{"$b"}} <=> $#{$ips_per_user{"$a"}};
}
                                                                                                       
sub SortUsersPerIP{
        $#{$users_per_ip{$b}} <=> $#{$users_per_ip{$a}};
}
                                                                                                       
sub SortErrorsPerUser {
   $errors_per_user{"$b"} <=> $errors_per_user{"$a"};
}
                                                                                                       
sub SortCountries {
	$loginspercountry{"$b"} <=> $loginspercountry{"$a"};
}
                                                                                                                             
sub rmoldreports {
        opendir (DIR, "$reportdir");
        @files = grep(!/^\.\.?$/, readdir(DIR));
        closedir (DIR);
        my $now = time();
        foreach $filename (@files) {
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                    $atime,$mtime,$ctime,$blksize,$blocks) = stat("$reportdir/$filename");
                print "$filename is " . ($now - $mtime) . " seconds old.\n<br>" if ($debug);
                if ( ($now - $mtime) > 86400 ) {
                        unlink "$reportdir/$filename";
                }
        }
}
                                                                                                                             

exit 1;



