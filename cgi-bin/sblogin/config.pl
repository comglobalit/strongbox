# Strongbox version 5.1
#   Copyright 2016 - 2020 Elias Torres <strongbox@comglobalit.com>
#   Copyright 2001 - 2015 Ray Morris <support@bettercgi.com>
# All rights reserved.
#   Copyright information: https://www.comglobalit.com/en/docs/strongbox/copyright/

# See our on-line documentation at
#   https://www.comglobalit.com/en/docs/strongbox/

# About this file
#   This is a Perl, take care of syntax.
#   Please make backups before doing changes.
#   https://www.comglobalit.com/en/docs/strongbox/configuration-variables/

# Enable debuggging globally or only for some IPs
# This shows errors and HTTP replies in browser
BEGIN { $debug = 0; $debug = 0 if ($ENV{'REMOTE_ADDR'} =~ /^69.60.116.126|^190.106.72.18|^186.15.83.13/ ); }

our @plugins = ( 
                # 'Strongbox::Plugin::Multiarea'
                # 'Strongbox::Plugin::Prepaid'
                # 'Strongbox::Plugin::CaseI' 
                # 'Strongbox::Plugin::NATSloginlog'
		# See https://www.comglobalit.com/en/docs/strongbox/human-test/
                'Strongbox::Plugin::Turing::AfterFail',
                # 'Strongbox::Plugin::Turing::ReCaptcha',
                'Strongbox::Plugin::Turing::ChickCaptcha',
                # 'Strongbox::Plugin::Turing::SBstandard',
                # 'Strongbox::Plugin::Turing::SBmp3'
              );

# Authentication
#   See https://www.comglobalit.com/en/docs/strongbox/authentication-methods/
#   In case your users located in a database you need to require the DBI module
#   See https://www.comglobalit.com/en/docs/strongbox/requirements/#dependencies

# require DBI;
our $dbinfo = {
    'db'              => 'natsdb',
    'user'            => '',
    'password'        => '',
    'host'            => 'localhost',
    'table'           => 'members',
    'ckuser'          => 'username',
    'ckpass'          => 'password',
    'crypted'         => 0,              # 'crypt', 'DES', 'PASSWORD', 'MD5', 'MD5_salt', 0, or \&somesub
    'where'           => " status=1 ",
    'extra_fields'    => undef,          #  ' *, '
    'socket'          => undef,          # '/tmp/mysql.sock'
};

# The location of your password file(s).  This is probably in your old .htaccess
# See: https://www.comglobalit.com/en/docs/strongbox/authentication-methods/

@htpfiles  = (
               # Database Authentication
#               [\&checkpasswd_mysql,    $dbinfo ],

               # Password File Authentication
	           [\&checkpasswd_htpasswd, "$ENV{'DOCUMENT_ROOT'}/#htpasswds#" ],

               # Do NOT add regular users to the following password file
               # See https://www.comglobalit.com/en/docs/strongbox/admin-users/

               # Note to CCBILL, Verotel, etc.
               # Do NOT add users to .htpasswd_admin - that file lists 
               # users with ADMINISTRATIVE access, not regular members.

               [\&checkpasswd_htpasswd, "./.htpasswd_admin" ]
             );

# Admin usernames are less likely to get suspended.
# The usernames listed here can NOT get suspended.
# Use this feature with extreme caution.  Do NOT use this
# to have several people pretend to be the same user with admin privileges.
# Each of these lists are arrays of regular expressions.
@invincible_users     = ( );
@invincible_ips       = ( '69.60.116.126' );

# Verotel does a lot of "testing".  Don't count their IP against the user.
# Also Segpay listed here.
# CCBILL: https://www.ccbill.com/cs/wiki/tiki-index.php?page=Member+Management+Server+Preparation
#         64.38.240.0-255, 64.38.241.0-255, 64.38.212.0-255,64.38.215.0-255

@ignored_ips          = ( '69.60.116.126', '190.106.72.18', '64\.38\.24[0-5]\.[0-9]*', '64.38.194.13', '#remote_addr#' );

# For script mode where another script calls Strongbox
@trustedips        = ('127.0.0.1', $ENV{'SERVER_ADDR'} );

# Your main members' URI, typically this will be "/members/"
$goodpage             = '/#members#/';

# Developer note - 
# To dynamically change $goodpage at runtime
# we can write a custom plugin for you.
# Contact us for a quote.

# Login attempts from these countries will fail.
# Please note that Country detection is not always
# reliable or 100% accurate
@banned_countries     = ( );

$referer_blocks       = 'pass|hack';
$referer_allow        = '';


 $host=$ENV{'HTTP_HOST'};
 $host =~ s/^www\.//;
 $host =~ s/^sb[0-9a-z]+\.//;
 # IE on Mac may include the port in the host header
 $host =~ s/:80$//g;


# Notification Emails
# Documentation: https://www.comglobalit.com/en/docs/strongbox/notification-emails/
# type: Perl array
# example: @email_addresses    = ( 'guy@example.net', 'webmistress@example.com' );
@email_addresses      = ( '#email#' );


# The are the login status codes for which you will
# get email notices.  On busier sites you may want to
# use the shorter list and get fewer notices.
# See https://www.comglobalit.com/en/docs/strongbox/status-codes/
$notifyof             = 'attempts|avs45err|badadmin|badadmpw|badchars|badrefer|dis_cnty|dis_uniq|dis_isps|htpffail|logffail|totllgns|uniqcnty|uniqisps|uniqsubs';
$max_notices_per_day  = 5;


$image_login          = 0;
$one_session_per_user = 1;
$check_proxies        = 0;
# Cookies-only mode, when Newtons are disabled
# https://www.comglobalit.com/en/docs/strongbox/newtons/
$cookies_only         = 0; #cookiesonly#
# $cookies_only         = 1 if ($ENV{'HTTP_COOKIE'});
$allowembedvideo      = 0;
$use_ip_block_files   = 1;

# Sesion time in days
$session_time         = 0.2;


$loginpage         = "http://$host/sblogin/login.php";
# URL to send them to if they enter a bad password
$errpage           = "http://$host/sblogin/badlogin.php";
# $badimagepage      = "http://$host/sblogin/badimage.shtml";
$badimagepage      = "http://$host/sblogin/badlogin.php";

# Optional Log files that record failures
# Used by webmasters or Server Admins to feed
# custom tools or log analyzers
# $ip_block_log = './ip_block_log.txt';
# $badimage_log = './badimage_log.txt';

##############################################################
# These parameters were chosen based on years of analysis    #
# of thousands of sites. Be sure you know what you are doing #
# before making significant changes to them.  These tell     #
# to BLOCK the user.  Strongbox will ALLOW one less than the #
# setting here.
##############################################################

# These "perhour" variables are actually per _3_ hour period.
$attemptsperhour      = 8;
$uniqsubsperhour      = 5;
$uniqcountriesperhour = 3;
$totallogins          = 18;
$uniqorgnames         = 3;

# These limits apply to a 48 hour (2 day) period
$attempts_2d       = 16;
$uniqsubs_2d       = 8;
$totallogins_2d    = 36;
$uniqcountries_2d  = 3;
$uniqorgnames_2d   = 4;

$uniqstildisable         = 8;
$uniqcountriestildisable = 6;
$uniqispstildisable      = 6;




############################################################################
# It's unlikely that you will have any reason to edit anything below here. #
# If you think that anything down here needs to change, contact us.        #
############################################################################

# See https://www.comglobalit.com/en/docs/strongbox/single-sign-sso-strongbox-handoff/
$key               = '#key#';


# For NFS mounted clusters
# require "./nfslock.pl";

# This is for round robin DNS
# use Sys::Hostname;
# $hostname = hostname;
# my ($a,$b,$c,$d) = unpack('C4',gethostbyname($hostname));
# my ($w,$x,$y,$z) = unpack('C4',gethostbyname("n1.you.com"));
# if ("$a.$b.$c" eq "$w.$x.$y") {
#    $host = "n1.you.com";
# } else {
#    $host = "b1.you.com";
# }


$logfile           = '.htpasslog';
$turinglog         = '/dev/null';
$sessionfiles      = './.htcookie';
$maxlogsize        = 7000000;

# For Playstations
if ($ENV{'HTTP_USER_AGENT'} =~ m/PLAYSTATION/) {
    $ENV{'HTTP_ACCEPT'} = 'ImAStupidPlaystation' unless ($ENV{'HTTP_ACCEPT'});
}



unless ($mailpgm) {
    if ( -x '/usr/sbin/sendmail') {
            $mailpgm='|/usr/sbin/sendmail -t';
    } elsif (-x '/usr/lib/sendmail') {
            $mailpgm='|/usr/lib/sendmail -t';
    } elsif (-x '/sbin/sendmail') {
            $mailpgm='|/sbin/sendmail -t';
    } elsif (require Mail::Sendmail  && Mail::Sendmail->import) {
            1;
    } else {
            warn 'I can\'t find a working sendmail anywhere.';
            $mailpgm='|/bin/true';
    }
}



$recchk           = 70000;
$reclen           = 78;


$disablercvsecurity = 0;

$nometavids       = 1;
$forcedownloadvids = 0;
$download_rm      = 1;
if ($ENV{'HTTP_COOKIE'} =~ m/sbsession *=/) {
	$ENV{'HTTP_COOKIE'} =~ m/sbsession *=([a-zA-Z0-9]*)/;
        $ENV{'sbsession'} = $1;
}


$site_id          = 1;
$il_data          = $sessionfiles;
$il_image_dir     = "$ENV{'DOCUMENT_ROOT'}/sblogin/images";
$apache_escape    = 0;
$md5_htcookie     = 0;




# require './avs.pl';
# $checkpasswd = \&checkpasswd_avs;
# $avs_deny_string = 'Invalid';
# $avs_approve_string = '';

# require "./checkpasswd_htpasswd_hash.pl";

################# MySQL user/pass checking ############ 

# require "./sb2vb3.pl";
# $checkpasswd = \&checkpasswd_vb3;
# $checkpasswd = \&checkpasswd_vb3_member_level;
# $mysql_memberlevel     = 1;


# For very complex database systems where the above variables 
# are not sufficient you can provide your own SQL query.
# This query must use two bind variables (question marks), 
# $pword and $uname
# $mysql_query           = q|SELECT
#                             CONCAT_WS(
#                                        '|',
#                                        ENCRYPT(?, LEFT(password_legacy, 2) ),
#                                        MD5('$pword')
#                                      ) as pword,
#                             CONCAT_WS('', password_legacy, password_md5) as pw,
#                             access_level from user, user2plan, plan2site
#                           WHERE
#                             user.username=user2plan.username AND
#                             user2plan.plan_id=plan2site.plan_id AND
#                             plan2site.access_level <> 'none' AND
#                             plan2site.site_id='$site_id' AND
#                             user.username=?
#                          |;



#########################################################


$image_login        =  0 if ($debug);

BEGIN {
        if ($debug) {
                print "Content-type: text/html\n\n<html><body><pre>\n";
                open (STDERR, ">&STDOUT");
                select(STDERR); $| = 1;
                select(STDOUT); $| = 1;
        }
}


return 1;

