#!/usr/bin/perl
 
# Date: 2010-04-22
 

# custom_subs.pl is deprecated. Use plugins instead.


# StrongBox version 2.3
# Copyright 2001, 2002, 2003, 2004, 2005, 2006
# Ray Morris <support@webmastersguide.com>


# require './notify.cgi';

=head1 Strongbox custom subroutines

# Custom sub routines called during Strongbox execution 
# (if defined) in order to allow for advanced customization.
# Use these, and even add calls to new ones, rather than 
# adding code inline to Strongbox.  But contact us first
# so we can officially give you permission to modify it.
# Unfortunately we could lose all of our copyright rights
# if we don't sue people who modify Strongbox without
# us giving them specific permission first.


# supported subs:

# sub rewrite_htpfile($htpfile);  
#     Dynamically change the name of the password file(s).
#     Called immediately before the file is read.
#     Return undef to skip this file.

# sub go_goodpage_custom($sbsession) 
#     Dynamically change the URL of the page where members'
#     sent after they login. Returns new members' URL.
#     Called immediately before the user is redirected.

# sub end_checkpasswd_mysql($dbh, $sth, $return)
#     Called as Strongbox completes checking a user/pass via MySQL

# sub errlog_custom($sbstatus)

# sub end_checkpasswd_htpasswd ($userpass, $htpfile)

# example:
# sub rewrite_htpfile {
#    my $htpfile = $_[0];
#    if ( $cgi->{'goodpage'} =~ m/lessons\/[0-9][0-9][0-9][0-9]\//) {
#        $site_id = $1;
#        print "site_id: $site_id\n" if ($debug);
#        $htpfile =~ s/LESSON/$site_id/g;
#    } elsif ( $cgi->{'goodpage'} =~ m/report/ ) {
#        $htpfile =~ s/LESSON/reports/g;
#    }
#    return $htpfile;
# }

=cut
#### Enter your changes below here ####

#sub rewrite_htpfile {
#    my $htpfile = $_[0];
#    if ($htpfile =~ m/trial/) {
#        $cgi->{'goodpage'} = '/trial/';
#        $sessionfiles = "./.htcookie_trial"; 
#    }
#    return  $htpfile;
#}


# sub checkpasswd_htpasswd_custom {
#     print "running custom checkpasswd_htpasswd\n" if ($debug);
#     if ($cgi->{'goodpage'} =~ m/videos\/movie([0-9]+)/) {
#         print "matched video download for video # $1\n" if ($debug);
#         @htpfiles = ( "$ENV{'DOCUMENT_ROOT'}/../cgi-bin/mov$1/.htpasswd" );
#     }
#     return &checkpasswd_htpasswd(@_);
# }



# sub go_goodpage_custom {
#    my $sbsession = $_[0];
#    my @peers = ('membersdvd2.asiagirlslive.com');
#    foreach $peer (@peers) {
#        &send_notify("http://$peer/cgi-bin/sblogin/notify.cgi");
#    }
#     &return($sbsession);
# }


# For trial areas:
# go_goodpage will call go_goodpage_custom($sbsession), which will alter variables 
# before calling back to the default go_goodpage();
# That will look something like:
# sub go_goodpage_custom {
#     if ($site_id eq 'trial') {
#         $sessionfiles = './htcookie_trial';
#         $goodpage = '/trial/' if ($goodpage =~ /\/members\//);
#     }
#     return &go_goodpage($sbsession);
# }


# sub rewrite_htpfile {
#     my $htpfile = $_[0];
#     if ($cgi->{'goodpage'} =~ m/\/CD\/([0-9a-z]+)/i) {
#         $htpfile = ( "$ENV{'DOCUMENT_ROOT'}/../data/.CD" . $1 .'htpasswd' );
#     }
#     return $htpfile;
# }


# sub checkpasswd_changeDB {

#  $mysql_db              = 'nats';
#  $mysql_user            = 'nats';
#  $mysql_password        = '';
# 
#  return 'badpuser';
#  }


#sub end_checkpasswd_mysql {
#        my $res = $_[0];
#        if ( $res->{'trial'} && ( $res->{'siteid'} != 14 ) ) {
#            $sessionfiles = "./.htcookie_trial";
#            $cgi->{'goodpage'} = "/membersarea/";
#        }
# }


# For trial areas, this will look something like:
# sub handoff_presessionfiles {
#     my $sessionfiles = shift();
#     my $sbsession = shift();
#     unless (! -d  "$sessionfiles/$sbsession.$host") {
#         $sessionfiles = './htcookie_trial';
#         $goodpage = '/trial/' if ($goodpage =~ /members/);
#         $site_id = 'trial' if ($site_id == 1);
#     }
# }



# sub end_checkpasswd_mysql {
#        my $res = $_[0];
#        my $status = $_[3];
#        if ($status eq 'gooduser') {
#            print "Set-Cookie: sbuser=$uname&pwhash=" . $res->{'pw'} . "; path=/; domain=$host\n";
#        }
# }


# sub custom_init {
#     if ($cgi->{'uname'} eq 'mpg9uGiA' ) {
#         @banned_countries     = ( );
#     }
# }

1;


