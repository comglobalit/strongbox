#!/usr/bin/perl
 
# Strongbox installation Script
# RMEE, Inc https://www.bettercgi.com/

# Date: 2012-04-05

# Configuration Options
my $passive		= 1;
my $protocol	= "ftp";
my $sftp;
my $port		= "21";
#my $port       = "21097";
my $http_port	= "80";
my $orderfile;
my $domain;
my $docroot;
my $members;
my $help=0;
my $cookiesonly;
my $searchpath	="";
my $proxy       = 1;

use Getopt::Long;
GetOptions (
	"docroot=s"		=> \$docroot,
	"domain=s"		=> \$domain,
	"members=s"		=> \$members,
	"orderfile=s"	=> \$orderfile,
	"passive!"		=> \$passive,
	"proxy!"		=> \$proxy,
	"port=i"		=> \$port,
	"protocol=s"	=> \$protocol,
	"sftp"			=> \$sftp,
	"help"			=> \$help,
	"cookiesonly"	=> \$cookiesonly,
	"searchpath=s"	=> \$searchpath,
);
$cookiesonly = '$cookies_only++;' if ($cookiesonly); # So that we can have 0 as the default value, for SSH install
$orderfile	= $ARGV[0] unless($orderfile);
$domain		= $ARGV[1] unless($domain);
$docroot	= $ARGV[2] unless($docroot);

# If first argument is a domain
if( not( -f $orderfile ) and ( -f "../../orders/strongbox/$orderfile.txt" ) ) {
  $orderfile	= "../../orders/strongbox/$orderfile.txt";
}

chomp(my $svn_version=`svn info -r HEAD | grep Revision: |cut -c11-`);

unless ( ( -f $orderfile or defined($domain) ) and $help eq 0 ) {
die "Usage:

  $0 order_file [domain]
  $0 domain

  Options:
    --docroot=/abs/path/in/ftp
    --domain=example.net
    --members=relative/path/from/docroot/
    --orderfile=...
    --passive	             # Use Passive FTP
    --cookiesonly            # Install in cookiesonly mode
    --port                   # FTP Port
    --searchpath=something   # Directory to be included in
                             # the \$regex to search for docroot
    --protocol=ftp|sftp      # not complete
    --sftp                   # not complete
    --proxy=1|0              # Force the HTTP Client to use the IP

Current Version of Strongbox in HEAD: $svn_version
Run \"svn info\" or \"svn status\" to see more.
\n";
}

$protocol = 'sftp' if($sftp);
if($protocol eq 'ftp' ) {
	use Net::FTP::Recursive;
} else {
	#use Net::SFTP::Recursive;
}
use MIME::Base64;
# use LWP::Simple;
require LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/4.0 (compatible; MSIE 5.0; Windows 95)');
$ua->default_header('Accept-Language' => "en-us,en;q=0.5");
$ua->default_header('Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7');
$ua->default_header('Referer' => 'http://www.google.com/');
$ua->timeout(30);


use strict;

my $order = &parseorder($orderfile);
my $additionalsite = 0;
$additionalsite++ if ($order->{'key'});

$order->{'domain'} = $domain if ($domain);
$order->{'cookiesonly'} = $cookiesonly;

my $basedir = '/home/elias/sb/sb5';
my $timeout = 15;
my $debug = 1;
$timeout = 30 if ($debug);
my $sftp = 0;
$sftp = 0;

my $config_tmp   = "config.pl.$$";
my $htaccess_tmp = "htaccess.$$";
my $badlogin_tmp = "badlogin.$$";

my $cgibin;
my $htpasswd;
my $authdbm;

my $success = 0;

&ncftpbm($order); # unless ($ARGV[1]);
my $ftp = &ftpconnect($order);


# $ftp->hash(\*STDERR,8092);

if ($docroot) {
    $ftp->cwd($docroot);
} else {
    $docroot =  &normalize_path( &finddocroot );
}



if ( $ftp->cwd('./cgi-bin') ) {
    $cgibin = &normalize_path("$docroot/cgi-bin");
    $ftp->put('pwd.cgi') or die "Could not put pwd.cgi: $! ". $ftp->message;
    $ftp->site('chmod', '755', 'pwd.cgi') or die "Could not chmod pwd.cgi: $! ". $ftp->message;
    $ftp->cwd('..');
} elsif ( $ftp->cwd('../cgi-bin') ) {
#     $cgibin = "$docroot/../cgi-bin";
    $cgibin  = &normalize_path( "$docroot/../cgi-bin" );
    $ftp->put('pwd.cgi') or die "Could not put pwd.cgi: $! ". $ftp->message;
    $ftp->site('chmod', '755', 'pwd.cgi') or die "Could not chmod pwd.cgi: $! ". $ftp->message;
    $ftp->cwd($docroot);
} else {
    die "Could not find cgi-bin.\n";
}

# $ftp->cwd($docroot);
if ($order->{'members'} || $members) {
    $members = $order->{'members'} unless ($members);
    $ftp->cwd($members) or die "Could not cd to '$members': $! ". $ftp->message;
} else {
    if ( $ftp->cwd('members') ) {
        $members = 'members';
    } else {
       my @files = $ftp->ls();
       print join("\n", @files);
       print "\n\nPlease select the members' directory:\n";
       $members = <STDIN>;
       chomp $members;
       $ftp->cwd($members) or die "Could not cd to '$members': $! ". $ftp->message;
    }
}
$order->{'members'} = $members;

chdir('../pages') or die "Could not chdir '../pages': $!";
$ftp->get('.htaccess', $htaccess_tmp) or die "Could not get .htaccess: $! ". $ftp->message;
$order->{'htpasswds'} = &htaccess2htpasswd($htaccess_tmp);

&makeconfig($order);
$ftp->cwd($docroot) or die "Could not cd to '$docroot': $! ". $ftp->message;;
chdir('../install') or die "Could not chdir '../install': $!";


# print "Config made, continue? (crtl-c to stop): ";
# my $line = <STDIN>;



unless ( &fileexists('sblogin') ) {
    $ftp->mkdir('sblogin') or die "Could not create 'docroot/sblogin': ". $ftp->message;
}
$ftp->cwd('sblogin') or die "Could not cd to 'docroot/sblogin': ". $ftp->message;
chdir('sblogin') or die "Could not lcd to 'sblogin': $!";
print STDERR "Uploading directory 'sblogin' ....\n";
my $errors = $ftp->rput(SkipExisting => 1, OmitAll => qr/\.svn|\.backups|\.svn-base/ );
print "$errors\n" if ($errors);

open(BADLT, 'badlogin.php') or die "could not open 'badlogin.php': $!";
open(BADLN, ">/tmp/$badlogin_tmp") or die "could not open '/tmp/$badlogin_tmp': $!";
while( my $line = <BADLT>) {
    $line =~ s/#cust_service_link#/$order->{'cust_service_link'}/;
    print BADLN $line;
}
close BADLT;
close BADLN;
$ftp->put("/tmp/$badlogin_tmp");
$ftp->rename($badlogin_tmp, 'badlogin.php');

$ftp->cwd('report') or die "Could not cd to 'docroot/sblogin/report': ". $ftp->message;
$ftp->site('chmod', '777', 'pages' ) or die "Could not chmod 'pages': $! ". $ftp->message;
$ftp->cwd('..') or die "Could not cd to 'docroot/sblogin/report/..': ". $ftp->message;

$ftp->cwd($cgibin) or die "Could not cd to '$cgibin': ", $ftp->message;


my $host = $order->{'domain'};
$host    = $order->{'ftp_host'} if ($order->{'ftp_host'});
#my $syscommand = "ssh -p 2222 -l raymor bettercgi.com  \"ncftpput -d stdout -R -u $order->{'ftp_user'} -p $order->{'ftp_pass'} $host $cgibin /home/raymor/domains/bettercgi.com/public_html/strongbox/install/cgi-bin/sblogin\"";

# Force the HTTP Client to use the IP in 
if($proxy) {
  $ua->proxy(['http'], "http://$host:$http_port/");
}

my $currremote = $ftp->pwd();
# $ftp->quit();
# if ( system($syscommand) ) {
#    $ftp = &ftpconnect($order);
#    $ftp->cwd($currremote);
    &uploadcgibinsblogin;
# } else {
#     $ftp = &ftpconnect($order);
#     $ftp->cwd($currremote);
#     $ftp->cwd('sblogin') or die "Could not cd to '$cgibin/sblogin': ". $ftp->message;
# }

print STDERR "chmod()ing files.\n";
my @files = $ftp->ls();
my @scripts = grep(/\.cgi$/, @files);
foreach my $file (@scripts) {
    $ftp->site('chmod', '755', $file ) or die "Could not chmod '$file': $!", $ftp->message;
}
$ftp->site('chmod', '777', '.htcookie' ) or die "Could not chmod '.htcookie': $! ". $ftp->message;
$ftp->site('chmod', '777', '.htcookie/turings' ) or die "Could not chmod '.htcookie/turings': $! ". $ftp->message;
$ftp->site('chmod', '777', '.htcookie/turings' ) or die "Could not chmod '.htcookie/chickcaptcha': $! ". $ftp->message;
$ftp->site('chmod', '666', '.htpasslog' ) or die "Could not chmod '.htpasslog': $! ". $ftp->message;
$ftp->site('chmod', '666', 'referer.log' ) or die "Could not chmod 'referer.log': $! ". $ftp->message;

print STDERR "uploading '/tmp/$config_tmp'\n";
chdir($basedir . '/install') or die "Could not lcd to '$basedir/install': $!";
$ftp->put("/tmp/$config_tmp") or die "Could not put '/tmp/$config_tmp': $!";
$ftp->rename($config_tmp, 'config.pl');


$ftp->cwd('report') or die "Could not cd to 'report': $!", $ftp->message; 
@files = $ftp->ls();
@scripts = grep(/\.cgi$/, @files);
foreach my $file (@scripts) {
        $ftp->site('chmod', '755', $file ) or die "Could not chmod '$file': $! " . $ftp->message;
}
if ($authdbm) {
    $ftp->rename('usermanage.cgi', 'usermanage_flat.cgi') or warn "Could not rename usermanage.cgi: $!" . $ftp->message;
    $ftp->rename('usermanage_dbm.cgi', 'usermanage.cgi') or warn "Could not rename usermanage.cgi: $!" . $ftp->message;
}


chdir($basedir . '/install') or die "Could not lcd to '$basedir/install': $!";
$ftp->cwd("$docroot/$members") or warn "could not cwd to '$docroot/$members': $!";
$ftp->rename('.htaccess', '.htaccess_old') or die "Could not rename old .htaccess: $!";
open(HTTMPL, "members/.htaccess") or die "could not open 'members/.htaccess': $!";
open(HTNEW, ">/tmp/.htaccess") or die "could not open : $!";
while(my $line = <HTTMPL>) {
    $line =~ s/#HTPASSWD#/$order->{'htpasswds'}/;
    print HTNEW $line;
}
close HTMPL;
close HTNEW;
$ftp->put("/tmp/.htaccess")  or warn "could not put /tmp/.htaccess: $!";
# $ftp->put("members/.htaccess")  or warn "could not put members/.htaccess: $!";
$ftp->put("members/.CC_PROCESSOR_INSTALLER_READ_THIS")  or warn "could not put .CC_PROCESSOR_INSTALLER_READ_THIS: $!";
$ftp->put("members/sbredir.php")  or warn "could not put sbredir.php: $!";
$ftp->put("members/logout.php")  or warn "could not put logout.php: $!";


print "\$cgibin: $cgibin, \$docroot: $docroot, do they match?\n" if ($debug);
if ($cgibin =~ m/$docroot/) {
    &nodotdot unless ($cgibin =~ m/\.\./);
}
chdir("$basedir/pages") or die "Could not chdir '$basedir/pages': $!";
&addhtaccess($htaccess_tmp);


print STDERR "Adding admin passwords...\n";
$order->{'sbinstallpass'} = &randstring(16) unless ($order->{'sbinstallpass'});
$order->{'sbinstalluser'} = "bcgi-" . &randstring(10) unless ($order->{'sbinstalluser'});
$ftp->cwd("$cgibin/sblogin/") or die "Could not cd to '$cgibin': $! " . $ftp->message;

chdir("$basedir/pages") or die "Could not chdir '$basedir/pages': $!";
open(HTP, ">.htpasswd_admin") or die "could not open '.htpasswd_admin': $!";
print STDERR " * Adding admin sbinstalluser: " . $order->{"sbinstalluser"} . "\n";
my $salt = '$1$' . &randstring(7) . '$';
print HTP $order->{'sbinstalluser'}, ':', crypt( $order->{'sbinstallpass'}, $salt), "\n";

# multiple adminusersa
foreach my $n ( '', 0..10 ) {
	$salt = '$1$' . &randstring(7) . '$';
    if ( $order->{"admin_pass$n"} ) {
        print STDERR " * Adding admin admin_pass$n: " . $order->{"admin_pass$n"} . "\n";
        print HTP $order->{"admin_user$n"}, ":", crypt( $order->{"admin_pass$n"}, $salt), "\n";
    }
}
close HTP;
$ftp->put('.htpasswd_admin') or die "Could not rename '.htpasswd_admin': $! " . $ftp->message;

# print STDERR "adding ", $order->{'sbinstalluser'}, ' ', $order->{'sbinstallpass'}, " to members' .htpasswd\n";
# &addtomembershtpasswd();


open(ORDER, ">>$orderfile") or die "could not open $orderfile: $!";
print ORDER "\n# ", scalar(localtime()), " ~ $ENV{'USER'}\n";
print ORDER "domaindone ", $order->{'domain'}, "\n";
print ORDER 'key: ' . $order->{'key'} . "\n" unless ($additionalsite);
print ORDER "htpasswd: $order->{'htpasswds'}", "\n" unless ($htpasswd eq '/');
print ORDER "members_dir: $members\n";
my ($docfull, $cgifull) = &get_full_paths($order->{'domain'});
print ORDER "docroot: $docroot\n";
print ORDER "cgi-bin: $cgibin\n";
print ORDER "install_host: $host\n";
print ORDER "revision: $svn_version\n";
print ORDER "\n";
close ORDER;

$ftp->cwd("$cgibin") or die "Could not cd to '$cgibin': $! " . $ftp->message;
$ftp->delete('pwd.cgi') or die "Could not delete pwd.cgi: $! " . $ftp->message;

print STDERR 'Installed on ' . $order->{'domain'} . ' user ', $order->{'sbinstalluser'}, ' pass ' . $order->{'sbinstallpass'} . "\n\n";
print STDERR "run postemail.sh $order->{'domain'} $order->{'email'}\n\n";

print STDERR "checking AcceptPathInfo ...\n";
&pathinfocheck();
$ftp->quit();



sub uploadcgibinsblogin {
    $ftp->mkdir('sblogin') or die "Could not create '$cgibin/sblogin': ". $ftp->message unless ( &fileexists('sblogin') );
    $ftp->cwd('sblogin') or die "Could not cd to '$cgibin/sblogin': ". $ftp->message;
    chdir('../cgi-bin/sblogin')  or die "Could not lcd to 'cgi-bin/sblogin': $!";
    print STDERR "Uploading 'cgi-bin/sblogin' ....\n";
    my $errors = $ftp->rput(SkipExisting => 1, OmitAll => qr/\.svn|\.backups/);
    die "Could not upload cgi-bin/sblogin: $errors" if ($errors);
}




sub finddocroot {
    my $dir;
    while(1) {
        if ($order->{'docroot'}) {
            $ftp->cwd($order->{'docroot'}) or die "Could not cwd to specified docroot $order->{'docroot'}";
            return $order->{'docroot'};
        }
        print $ftp->pwd(), "\n";
        $order->{'domain'} =~ m/(.*)\.[^\.]+/;
        my $dombase = $1;
        $order->{'domain'} =~ m/(members\.)?(.*)/;
        my $nomembers = $2;
        my @files = $ftp->ls or die "Can't list files: $!";
        # if ( grep(/^public_html$/, @files) ) {
        #     $ftp->cwd('public_html');
        #     return $ftp->pwde);
        # }
        print "current directory: ", $ftp->pwd() , "\n\n";
        # print  "\@files before regex: ", join("\n", @files), "\n\n";
#sites, html
        my $regex = "www|" . $order->{'domain'} . '|www\.' . $order->{'domain'} . "|$dombase|$nomembers|$searchpath|mainwebsite_html|webtemp|local|apache|web|virtuals2|paysites|dominios|client.feeds.com|httpdocs|htdocs|public_html|www_root|viparea|v_sl|virtuals2|MemberAreaCGG|MemberAreaCSS|htmlsss|subdomains|ccbillmember|httpdocs|htmls|v_sl|domains|celebarazzi.com";

        
        print "regex: $regex\n" if ($debug);
        my @dirs = grep(/^($regex)$/, @files);
        # print  "\@dirs: ", join(" ", @dirs), "\n\n";
        if ($#dirs == 0) {
            $ftp->cwd($dirs[0]);
        } elsif ($#dirs > 0) {
            print "Select directory: \n", join("\n   ", @dirs), "\n: ";
            $dir = <STDIN>;
            chomp $dir;
            $ftp->cwd($dir);
        }  elsif ($#dirs < 0) {
            #if ( grep(/^index\./, @files) ) {
            if (grep('index.php', @files) ) {
                $dir =  $ftp->pwd();
                # print "docroot is $dir\n";
                return $dir;
            } else {
                die "Could not determine docroot.\n";
            }
        }
        $dir =  $ftp->pwd();
    }
}


sub fileexists {
    if ( $ftp->size($_[0]) > 0 ) {
        return 1;
    } elsif ( $ftp->cwd($_[0]) ) {
        $ftp->cdup();
        return 1;
    } else {
        return 0;
    }
}



sub ftpconnect() {
    my $order = $_[0];
    $ftp->quit() if ( defined($ftp) && $ftp->connected );
    print 'domain: ', $order->{'domain'},  "\n";
    my $host = $order->{'domain'};
    $host    = $order->{'ftp_host'} if ($order->{'ftp_host'});
    $port    = $order->{'ftp_port'} || $port;
    print "host: $host, \$port: $port\n" if ($debug);
	my $ftp;
	if ($protocol eq 'ftp') {
    	$ftp=Net::FTP::Recursive->new(
			$host,
			Timeout=>$timeout * 2,
			Debug => $debug,
			Port => $port, 
			Passive => $passive,
			OmitAll => qr/\.svn|\.backups/,
			OmitDirs => '\.svn' )
		or die "Could not connect: $!";
		$ftp->login($order->{'ftp_user'},$order->{'ftp_pass'}) or die "Can't login to " . $order->{'domain'} . ": ", $ftp->message;
	} else {
		die "no SFTP";
#		my @sshargs = ('options', ["Port $port"] );
#		$ftp = Net::SFTP::Recursive->new(
#			$host,
#			debug => $debug,
#			user => $order->{'ftp_user'},
#			password => $order->{'ftp_pass'},
#			ssh_args => \@sshargs )
#		or die "Could not connect: $!";
	}

    print "Connected\n";
    print "Logged in\n";
    $ftp->binary unless ($protocol ne 'ftp');
    return($ftp);
}


sub htaccess2htpasswd {
    my $htaccess = $_[0];

    my ($docfull, $cgifull) = &get_full_paths($order->{'domain'});
    open(HTA, "<$htaccess") or die "could not open '.htaccess': $!";
    my @lines = <HTA>;
    my @mysql = grep(/mysql/i, @lines);
    @lines = grep(/^ *(AuthUserFile|AuthDBMUserFile)/i, @lines);
    close HTA;
    print STDERR "line: ", $lines[0], "\n";
    my $htpasswd;
    if ( $lines[0] =~ m/(AuthUserFile|AuthDBMUserFile) *"*([^" ]*)/i ) {
        $htpasswd = $2;
        chomp $htpasswd;
        $htpasswd =~ s/$docfull\///;
        $htpasswd =~ s/$cgifull\//$cgibin\//;
    } else {
        $htpasswd = '/';
    }
    $htpasswd =~ s/\r//g;
    if ( $lines[0] =~ m/AuthDBMUserFile/ ) {
        print STDERR "Using DMB, set check_passwd appropriately!\n";
        $authdbm++;
    }
 
    $htpasswd =~ s/\/usr// if ( $htpasswd =~ m/\/usrcgi/ );  
    print STDERR "\$htpasswd: '$htpasswd'\n";
    # if ($htpasswd =~ m/^\//) {
        print "Correct .htpasswd location ([Enter] if correct)?: ";
        my $line = <STDIN>;
        chomp $line;
        $htpasswd = $line if ( length($line) > 1 );
    # }
    open(ORDER, ">>$orderfile") or die "could not open : $!";
    if ($#mysql) {
        for my $line (@mysql) {
            $line =~ s/ /: /;
            print ORDER $line;
        }
        print ORDER "\n";
    }
    close ORDER;

    return $htpasswd;
 }



sub sbold2htpasswd {
   my ($docfull, $cgifull) = &get_full_paths($order->{'domain'});
   open(CFG, "<config.pl") or die "could not open 'config.pl': $!";
   my $line;
   until ($line =~ /htpfiles/) {
       $line = <CFG>;
   }
   $line = <CFG>;
   close HTA;
   
   $line =~ m/}\/(.*)"/;
   my $htpasswd = $1;
   chomp $htpasswd;
   $htpasswd =~ s/$docfull\///;
   $htpasswd =~ s/$cgifull\//$cgibin\//;
   print STDERR "\$htpasswd: $htpasswd\n";
   if ($htpasswd =~ m/^\//) {
       print "Correct .htpasswd location ([Enter] if correct)?: ";
       my $line = <STDIN>;
       chomp $line;
       $htpasswd = $line if ( length($line) > 1 );
   }
   return $htpasswd;
}




sub parseorder {
    my $debug = 0;
    my %order;
    open(ORDER,  $_[0]) or die "could not open '$_[0]': $!";
    while(my $line = <ORDER>) {
        foreach my $param ('domain', 'ftp_user', 'ftp_pass', 'admin_user', 'admin_pass', 'email', 'key', 'sbinstallpass', 'sbinstalluser', 'ftp_host', 'ftp_port', 'docroot', 'members', 'cust_service_link', 'remote_addr') {
            if ($line =~ /^$param[0-9]?:/) {
                chomp $line;
                my ($key, $value) = split(/: /, $line);
                # print "(\$key, \$value): ($key, $value)\n" if ($debug);
                $value =~ s/^ *//g;
                $value =~ s/ *$//g;
                $value =~ s/\r/ ++ /g;
                if ($param eq 'cust_service_link') {
                    $value = $order{'email'} unless ($value);
                    if ($value =~ m/\@/) {
                        $value = "mailto:$value";
                    } else {
                        $value = "http://$value" unless ($value =~ m/http/i);
                    }
                }
                if ($param eq 'domain') {
                    $value =~ s/http:\/\///;
                    $value =~ s/www\.//;
                    $value =~ m/^([a-zA-Z0-9\.-]*)/;
                    $value = $1;
                    $value = lc($value);
                }
                $order{$param} = $value unless ($order{$param});
            }
        }
    }
    close ORDER;
    return \%order;
}



sub ncftpbm {
    my $order = $_[0];
    my $bmname = $order->{'domain'};
    $bmname =~ s/\.[^\.]*$//;
    $bmname = substr($bmname,0,15);

    my $host = $order->{'domain'};
    $host    = $order->{'ftp_ip'} if ($order->{'ftp_ip'});
    my $port =  $order->{'ftp_port'} || 21;

    my $bookmarkexists = 0;
    open(NCBM, "$ENV{'HOME'}/.ncftp/bookmarks") or die "could not open bookmarks: $!";
    while( my $line = <NCBM> ) {
        $bookmarkexists++ if ($line =~ m/^$bmname/);
    }
    close NCBM;

    if ($bookmarkexists) {
    } else {
        my $passencoded = encode_base64($order->{'ftp_pass'});
        chomp $passencoded;
        $passencoded =~ s/==$/AA/;
        $passencoded =~ s/=$/A/;
        open(NCBM, ">>$ENV{'HOME'}/.ncftp/bookmarks") or die "could not open bookmarks: $!";
        print NCBM "$bmname," . $host .','.$order->{'ftp_user'}.",*encoded*$passencoded,,,I,$port,,1,1,1,1,,,,,,,S,0\n";
        close NCBM;
    }
}


sub makeconfig {
    my $order = $_[0];
    $order->{'key'} = &randstring(28) unless ($order->{'key'});

    $order->{'admin_user'} =~ s/([\@\$\%])/\\$1/g;

    open(CFGDEF, "$basedir/install/cgi-bin/sblogin/config.pl") or die "could not open default config: $!";
    open(CFGNEW, ">/tmp/$config_tmp") or die "could not open new config: $!";
    while(my $line = <CFGDEF>) {
        foreach my $param ('admin_user', 'email', 'key', 'htpasswds', 'members', 'cookiesonly', 'remote_addr') {
            my $template = "#" . $param . "#";
            $line =~ s/$template/$order->{$param}/g;
        }
        print CFGNEW $line;
    }
    close CFGDEF;
    close CFGNEW;
}


sub randstring {
    my $length = $_[0];
    my $i = 0;
    my $string = "";
    while ($i++ < $length) {
        my $code = 58;
        while ( ($code > 57) && ($code < 97)  ) {
            $code = int(rand(74) + 48);
        }
        $string .= sprintf("%c", $code);
    }
    return $string;
}


sub get_full_paths {
    my $host = $_[0];
#    my $cgifull='/home/adult/brutal-facesitting.com/members/cgi-bin/';
#    my $docfull='/home/adult/brutal-facesitting.com/members/';
     my $cgifull='';
     my $docfull='';
    
    if($proxy) {
	    $ua->proxy(['http'], "http://$host:$http_port/");
		print "setting proxy to http://$host:$http_port/ \n" if ($debug);
    }
    print "getting pwd.cgi from ", 'http://' . $order->{'domain'} . '/cgi-bin/pwd.cgi', "\n" if ($debug);
    my $response = $ua->get('http://' . $order->{'domain'} . '/cgi-bin/pwd.cgi');
    unless ($response->is_success) {
        die "Couldn't get pwd.cgi: " . $response->status_line;
    }

   # print $response->content, "\n";
    my @lines = split(/[\r\n]+/, $response->content);
    foreach my $line (@lines) {
        $cgifull = $1 if ($line =~ m/CGIBIN: *(.*)/);
        if ($line =~ m/DOCUMENT_ROOT: *(.*)/) {
            $docfull = $1;
            print $line, "\n\n";
        }
    }
    $docfull = &normalize_path($docfull);
    $cgifull = &normalize_path($cgifull);
   return($docfull, $cgifull);
}


sub normalize_path {
    $_ = $_[0];
    while(m#[^/\.]+/\.\.#) {
        s#[^/\.]+/\.\./##g;
        print $_, "\n";
    }
    s#//+#/#g;
    return $_;
}



sub addhtaccess {
    my $oldhtaccess = $_[0];

    my $extralines;
 
    my $olddir = $ftp->pwd();   
    $ftp->cwd($docroot);
    $ftp->cwd($members);

    open(HTOLD, $oldhtaccess) or die "could not open '$oldhtaccess': $!";
    while(my $line = <HTOLD>) {
        chomp $line;
        $line =~ s/\r$//;
        next if ($line =~ m/^ *$/);
        unless ($line =~ m/^ *Auth|<Limit|require|<\/limit>/i) {
            print "Extra .htaccess line: $line\n";
            $extralines .= "#  $line\n";
        }
    }
    if ($extralines) {

        $ftp->get('.htaccess', '/tmp/.htaccess');
        open(EXTRA, ">>/tmp/.htaccess") or die "could not open '/tmp/.htaccess': $!";
        print EXTRA "\n\n## The lines below are NOT part of Strongbox ##\n\n";
        print EXTRA "\n$extralines\n\n";
        close EXTRA;
        $ftp->put("/tmp/.htaccess", '.htaccess');
    }
    $ftp->cwd($olddir);
}


sub nodotdot {
    print "Uploading nodotdot .htaccess files\n\n";
    my $olddir = $ftp->pwd();
    $ftp->cwd("$docroot/$members");
    open(HTTMPL, "nodotdot/members/.htaccess") or die "could not open 'nodotdot/members/.htaccess': $!";
    open(HTNEW, ">/tmp/.htaccess") or die "could not open : $!";
    while(my $line = <HTTMPL>) {
        $line =~ s/#HTPASSWD#/$order->{'htpasswds'}/;
        print HTNEW $line;
    }
    close HTMPL;
    close HTNEW;
    $ftp->put("/tmp/.htaccess")  or warn "could not put /tmp/.htaccess: $!";

    # $ftp->put('nodotdot/members/.htaccess') or warn "failed upload nodotdot to $members";
    $ftp->cwd("$docroot/sblogin/report/");
    $ftp->put('nodotdot/sblogin/report/.htaccess') or warn "failed upload nodotdot to sblogin/report/";
    $ftp->cwd("$cgibin/sblogin/report/");
    $ftp->put('nodotdot/cgi-bin/sblogin/report/.htaccess') or warn "failed upload nodotdot to $cgibin/sblogin/report/";

    $ftp->cwd($olddir);
}



sub pathinfocheck {
    my $response = $ua->get('http://' . $order->{'domain'} . "/sblogin/login.php/$members/");


    if ($response->code  eq 404) {
        my $oldcwd = $ftp->pwd();
        $ftp->cwd("$docroot/sblogin/") or die "could not cd to '$docroot/sblogin/': $!";
        $ftp->get('.htaccess', $htaccess_tmp) or die "could not get '$docroot/sblogin/.htaccess': $!";

        print STDERR "PathInfo check returned 404, checking SSI ...\n";
        $response = $ua->get('http://' . $order->{'domain'} . "/sblogin/login.php");
        if ($response->content =~ m/PATH_INFO/) {
            print STDERR "SSI off, adding Options +FollowSymLinks +Includes...\n";
            open(HT, ">>$htaccess_tmp") or die "could not open '$htaccess_tmp': $!";
            print HT "\nOptions +FollowSymLinks +Includes\n\n";
            close HT;
            $ftp->put($htaccess_tmp, '.htaccess') or die "could not put '$docroot/sblogin/.htaccess': $!";
            $response = $ua->get('http://' . $order->{'domain'} . "/sblogin/login.php");
            if ($response->is_success) {
                if ($response->content =~ m/PATH_INFO/) {
                    print STDERR "After adding options, sblogin/login.php OK\n";
                }
            } else {
                print STDERR "After adding options, sblogin/login.php returned ", $response->code, "\n";
            }
        } else {
            open(HT, ">>$htaccess_tmp") or die "could not open '$htaccess_tmp': $!";
            print HT "\nAcceptPathInfo On\n";
            close HT;
            $ftp->put($htaccess_tmp, '.htaccess') or die "could not put '$docroot/sblogin/.htaccess': $!";
            $ftp->cwd("$docroot/$members");
            $ftp->get('.htaccess', $htaccess_tmp) or die "could not get '$docroot/$members/.htaccess' or AcceptPathInfo: $!";
            open(HT, ">>$htaccess_tmp") or die "could not open '$htaccess_tmp': $!";
            print HT "\nAcceptPathInfo On\n";
            close HT;
            $ftp->put($htaccess_tmp, '.htaccess') or die "could not put '$docroot/$members/.htaccess' for AcceptPathInfo: $!";
        }
        $ftp->cwd($oldcwd);
        $response = $ua->get('http://' . $order->{'domain'} . "/sblogin/login.php/$members/");
    } 

    if ($response->is_success) {
        print STDERR "PathInfo check OK, returned: ", $response->status_line, "\n";
    } else {
         warn "Couldn't get sblogin/login.php/$members/: " . $response->status_line;
    }
}



sub parse_files_skip_existing {
    my(@to_return) = ();

    foreach my $line (@_) {
        next unless $line =~ /^
                               (\S+)\s+             #permissions
                                \d+\s+              #link count
                                \S+\s+              #user owner
                                \S+\s+              #group owner
                                \d+\s+              #size
                                \w+\s+\w+\s+\S+\s+  #last modification date
                                (.+?)\s*            #filename
                                (?:->\s*(.+))?      #optional link part
                               $
                              /x;

        my($perms, $filename, $linkname) = ($1, $2, $3);

        next if $filename =~ /^\.{1,2}$/;

        my $file;
        if ($perms =~/^-/){
            $file = Net::FTP::Recursive::File->new( plainfile => 1,
                                                    filename  => $filename );
        }
        elsif ($perms =~ /^d/) {
            $file = Net::FTP::Recursive::File->new( directory => 1,
                                                    filename  => $filename );
        } elsif ($perms =~/^l/) {
            $file = Net::FTP::Recursive::File->new( 'symlink' => 1,
                                                    filename  => $filename,
                                                    linkname  => $linkname );
        } else {
            next; #didn't match, skip the file
        }

        

        push(@to_return, $file);
    }

    return(@to_return);
}


sub addtomembershtpasswd {
    if ($order->{'htpasswds'} =~ m/^\//) {
        print STDERR "Could not modify passwords list due to full path ", $order->{'htpasswds'}, "\n";
    } else {
        print "Adding sbinstall to password list.\n";
        $ftp->cwd($docroot) or die "Could not cd to '$docroot': $! " . $ftp->message;
        $order->{'htpasswds'} =~ m@(.*)/([^/]*)$@;
        my $htdirname = $1;
        my $htfname   = $2;
        print STDERR "\$htfname: $htfname\n" if ($debug);
        $ftp->cwd($htdirname);
    
        chdir("$basedir/pages") or die "Could not chdir '$basedir/pages': $!";
        print "getting '$htfname'\n";
        $ftp->get($htfname) or die "Could not get '$htfname': $! " . $ftp->message;
    
        if ($authdbm) {
            print "getting '$htfname.db'\n";
            $ftp->get($htfname . '.db') or die "Could not get '$htfname': $! " . $ftp->message;
            print STDERR "Using AuthDBM.\n";
            my %DB = ();
            dbmopen (%DB, $htfname . '.db', 0666) or die "couldn't open dbm password file '$htfname': $!";
            $DB{$order->{'sbinstalluser'}} = crypt( $order->{'sbinstallpass'}, &randstring(2) );
            dbmclose(%DB);
            $ftp->rename($htfname, $htfname. '.db_old') or die "Could not rename '$htfname': $! " . $ftp->message;
            $ftp->put($htfname. '.db') or die "Could not rename '$htfname.db': $! " . $ftp->message;
            $ftp->site('chmod', '666', $htfname. '.db') or die "Could not chmod '$htfname.db': $! " . $ftp->message;
        } else {
            print "getting '$htfname'\n";
            $ftp->get($htfname) or die "Could not get '$htfname': $! " . $ftp->message;
            open(HTP, ">>$htfname") or die "could not open '$htfname': $!";
            print HTP $order->{'sbinstalluser'}, ':', crypt( $order->{'sbinstallpass'}, &randstring(2) ), "\n";
            close HTP;
            $ftp->rename($htfname, $htfname . '_old') or die "Could not rename '$htfname': $! " . $ftp->message;
            $ftp->put($htfname) or die "Could not rename '$htfname': $! " . $ftp->message;
            $ftp->site('chmod', '666', $htfname) or die "Could not chmod '$htfname': $! " . $ftp->message;
    
        }
    }
}
    
    
