#!/usr/bin/perl
 
sub get_wm_msg {
    my $status = shift();
    my $uname  = shift();
    my $host   = shift();
    
    my $msg = "This is the Strongbox webmaster notification system on $host.\n";

    if ( $status =~ m/^logffail(.*)/ ) {
        $msg .= qq|\nSomeone tried to login as "$uname", but I can't open my log file.  Something has been changed or misconfigured.  The server says the log can't be opened because:  $1|;
    } 
    elsif ( $status =~ m/^htpffail(.*)/ ) {
        $msg .=  qq|\nSomeone tried to login as "$uname", but I can't access the password file. The server says the password file can't be opened because:  $1|;
    }
    elsif ( $status eq "attempts" ) {
        $msg .= qq|\nSomeone tried to login as "$uname", but they've been guessing too many username/password combinations, so it looks like a brute force attack.  I'm suspending their IP address until they stop trying different usernames and passwords for a couple of hours, at least.  *No action* on your part is needed at this time.
                |;
    }
    elsif ( $status eq "avs45err" ) {
        $msg .= qq|\nSomeone tried to login with username '$uname' but the AVS server returned a 400 or 500 class error.
                |;
    }
    elsif ( $status eq "badadmin" ) {
        $msg .= qq|\nSomeone tried to access the Strongbox Admin Area with username '$uname' but this username does not exist in the Strongbox Admin password file.  No action on your part is needed at this time.
                |;
    }
    elsif ( $status eq "badadmpw" ) {
        $msg .= qq|\nSomeone tried to the Strongbox Admin Area as "$cgi->{'uname'}", using "$cgi->{'pword'}" as their password.  This password did not match what is stored in the Strongbox Admin password file. \n\nBy chance, does this username also exist in the same location where the regular member data is stored?  If so, this will be problematic, so either it should be removed from the location where the regular member data is stored by using your processor or a different Strongbox Admin Account should be created.  For more information about Strongbox Admin Users, please see the Online Owner's Manual.
                |;
    }
    elsif ( $status eq "badchars" ) {
        $msg .= qq|\nSomeone tried to login as "$cgi->{'uname'}", using "$cgi->{'pword'}" as their password.  Either the username or password contains characters that I don't think are allowed.  I'm afraid they may be trying to hack me by entering Perl code as their password or something. If there is some punctuation or something in there that looks like it should be allowed, please forward this email in its entirety to the Strongbox Support Staff at strongbox\@comglobalit.com so they can add that character to my list of OK characters. 
                |;
    }
    elsif ( $status eq "badpword" ) {
        $msg .= qq|\nSomeone tried to login as "$uname", but did not enter the password correctly.  Most likely, the user made a typographical error, or has forgotten their password.  No action on your part is required at this time. 
                 |;
    }
    elsif ( $status eq "badrefer" ) {
        $msg .= qq|\nSomeone tried to login with username '$uname' but this person came from a site like easypasswords.com or ultrapasswords.com with the word 'pass' or 'hack' in the name.  No action on your part is required at this time. 
                |;
    }
    elsif ( $status eq "dis_cnty" ) {
        $msg .= qq|Someone tried to login as "$uname", but several times that same username has been used by people in too many different countries in a short period of time.  That password is probably on a password site or otherwise compromised.  I'm permanently disabling it.  If you are certain this is a legitimate member, we suggest that the password be changed, (preferably through your processor), and then reenable the username through the Strongbox Admin Area's Member Management section.
                |;
    }
    elsif ( $status eq "dis_isps" ) {
        $msg .= qq|\nSomeone tried to login with username '$uname' but people from too many ISPs are using this username too much. This username has been permanently disabled. 
                |;
    }
    elsif ( $status eq "dis_uniq" ) {
        $msg .= qq|\nSomeone tried to login as "$uname", but that same username has already logged in from several other ISPs or locations in the last couple of hours.  That password is probably on a password site or otherwise compromised.  I'm permanently disabling it.  You can change the password (preferably through your processor) and then reenable this username through the Member Management section of the Strongbox Admin Area, if you are certain it belongs to a legitimate customer.
	        |;
    }
    elsif ( $status eq "emptyUrP" ) {
        $msg .= qq|\nSomeone tried to login with either no username or no password, which means they likely tried to enter programming code in the other field in an attempt to hack me.  The username they tried to use was '$uname'.  I can probably handle whatever code they try to throw at me, so *no action* is needed on your part at this time.  
                |;
    }
    elsif ( $status eq "manipblk" ) {
        $msg .= qq|\nSomeone tried to login as '$uname' from an IP address that has been manually suspended by a Strongbox Admin user through Strongbox Admin Area.  You may wish to run a report on this username to determine if it is being abused, though I can probably determine the abuse and suspend the username accordingly if necessary, so *no action* is needed on your part at this time.  
                |;
    }
    elsif ( $status eq "opnproxy" ) {
        $msg .= qq|\nSomeone tried to login as "$uname" from an open proxy IP.  Open proxies are typically used for brute force attacks or other nefarious activity, so this IP address is suspicous.  Because it could be a legitimate user I didn't block them outright, but I'm watching them especially closely.  If I see anything else suspicious about them I'll suspend them and email you.  *No action* on your part is needed at this time.
                |;
    }
    elsif ( $status eq "test__sb" ) {
        $msg .= qq|\nThis is a test email to make sure that I can reach you OK when I see something that I'd like to let you know about. 
                |;
    }
    elsif ( $status eq "totllgns" ) {
        $msg .= qq|\nSomeone tried to login as "$uname", but that username has been used to log in quite a few times in the last few hours, and I'm suspicious.  I'm suspending that username for a couple hours until everyone stops trying to login with it for a while.  *No action* on your part is required at this time. 
                |;
    }
    elsif ( $status eq "uniqcnty" ) {
        $msg .= qq|\nSomeone tried to login as "$uname", but that same username has already been used recently by someone in other countries.  That username may be on a password site or otherwise compromised.  I'm suspending that username for a while, to see if this behavior stops soon.  If they keep it up, I'll disable that username permanently and email you to let you know. 
                |;
    }
    elsif ( $status eq "uniqsubs" ) {
        $msg .= qq|\nSomeone tried to login as "$uname", but that same username has already logged in from a couple other IPs or locations in the last couple of hours.  That username may be on a password site or otherwise compromised.  I'm suspending that username for a while, to see if this behavior stops soon.  If they keep it up, I'll disable that username permanently and email you to let you know.  *No action* on your part is required at this time. 
                |;
    }
    elsif ( $status eq "uniqisps" ) {
        $msg .=  qq|\nSomeone tried to login as "$uname", but that same username has already logged in from a couple other ISPs or locations in the last couple of hours.  That username may be on a password site or otherwise compromised.  I'm suspending that username for a while, to see if this behavior stops soon.  If they keep it up, I'll disable that username permanently and email you to let you know.  *No action* on your part is required at this time. 
                |;    
    }
    else {
        $msg .= qq|\nSomeone tried to login as "$uname" and I'm programmed to email you because the this login attempt resulted in a status code of "$status".  I'm not programmed to know what to tell you about what "$status" means, though.  If you would like this to be investigated further, please forward this email to the Strongbox Support Staff at strongbox\@comglobalit.com.
	        |;

    }

    $msg .= qq|\nYou can get more information about this by looking at the reports for today in the Strongbox Admin Area:
  |;

    my $report_url;
    my $thispath = "$ENV{'SCRIPT_FILENAME'}";
    $thispath =~ s/\/[^\/]+$//;
    my $thisurl = "$ENV{'SCRIPT_NAME'}";
    $thisurl =~ s/[^\/]+$/report\//;

    if ( -f "$thispath/report/report.cgi" ) {
        $thisurl =~ s/\/cgi-bin//;
        $report_url = "http://" . $host . $thisurl;

        $msg .= qq|$report_url
		|;

    }

    # $msg =~ s/^\s+//gm;    # Strip indenting
    
    $msg .= "\nRemote IP: $ENV{'REMOTE_ADDR'}\n";
    $msg .= "\nDomain: $host\n\n";
    $msg .= "\nEmail Notifications: https://github.com/comglobalit/strongbox/wiki/Strongbox-Notification-Emails\n\n";
    $msg .= " Learn about How to Help customers who have trouble logging in:\nhttps://github.com/comglobalit/strongbox/wiki/Helping-Customers-Who-Have-Trouble-Logging-In\n";
    $msg .= "Strongbox documentation: https://github.com/comglobalit/strongbox/wiki\n\n";

    return $msg;
}

1;

