#
#===============================================================================
#
#         FILE:  Strongbox/Plugin/Multiarea.pm
#
#  DESCRIPTION: Plugin for Strongbox to do trial areas or multiple sites per domain. 
#
#       AUTHOR:  Ray Morris support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.2 automatic search of password file depending on the goodpage wanted
#      CREATED:  04/21/2010 04:03:14 PM
#     REVISION:  ---
#===============================================================================

# TODO 
# These functions all need to return only 1 to continue to 0 to stop further plugins.
# Other values are passed by reference and should be modified in place ($_[1] etc.)
# Mysql will not work until that is done.

package Strongbox::Plugin::Multiarea;

#my $area_regex  = '^/?([^/]*)/members';
my $area_regex  = '^/?vids/([0-9]+)/?';
my $newgoodpage = '/vids/$area/';
# Also set the two multiarea lines in members/.htaccess

$debug = $main::debug;

sub begin_checkpasswd_htpasswd {
    my ($class, $htpfile, $cgi) = @_;
	return 1 if ($htpfile =~ /\.htpasswd_admin$/);
	$htpfileref = \$_[1];
	print "PLUGIN " . __PACKAGE__ . " Checking if good page matches area_regex ($area_regex) ...\n" if ($debug);
    if ($cgi->{'goodpage'} =~ m/$area_regex/) {
        $area = $1;
		print "PLUGIN " . __PACKAGE__ . " matched $area ...\n" if ($debug);
		print "PLUGIN " . __PACKAGE__ . " looking for a password file inside $ENV{'DOCUMENT_ROOT'}/vids/ccbill$area ...\n" if ($debug);
		use File::Find;
		find(
			sub {
					if( $File::Find::name =~ '.htpasswd' ) {
						print "PLUGIN " . __PACKAGE__ . " found " . $File::Find::name . " ...\n" if ($debug);
						print "PLUGIN " . __PACKAGE__ . " setting that as password file\n" if ($debug);
						$$htpfileref = $File::Find::name;
					}
				} , "$ENV{'DOCUMENT_ROOT'}/vids/ccbill$area" # where to look for password files
		);
    }
    return 1;
}

#use strict;
#use warnings;

sub begin_checkpasswd_mysql {
    my ($class, $dbh) = @_;
    $main::mysql_extra_fields .= ' *, ';
    return 1;
}


sub end_checkpasswd_mysql {

    my $contents = $main::contents;
    my $class               = shift();
    my $res                 = shift();
    my $dbh                 = shift();
    my $sth                 = shift();
    my $return              = shift();
    my $sessionfiles        = shift();
    $contents->{'goodpage'} = shift();

    my $area;

    if ($res->{'trial'}) {
        $area = 'trial';
    } elsif ($res->{'site'}) {
        $area = $res->{'site'};
    } elsif ($res->{'siteid'}) {
        $area = $res->{'siteid'};
    } elsif ($contents->{'goodpage'} =~ m/$area_regex/) {
        $area = $1;
    }

    if ($area) {
        $sessionfiles = "$sessionfiles/areas/" . $area unless ($sessionfiles =~ /$area/);
        &main::mkpath($sessionfiles, 0777);
        $newgoodpage =~ s/\$area/$area/;
        $contents->{'goodpage'} = $newgoodpage;
    }
    return (1, $return, $sessionfiles, $contents->{'goodpage'});
}


sub handoff_presessionfiles {
    my $class        = shift();
    my $sessionfiles = shift();
    my $sbsession    = shift();

    unless (! -d  "$sessionfiles/$sbsession.$main::host") {
        my $area = 'trial';
        if ($ENV{'HTTP_REFERER'} =~ m/$area_regex/) {
            $area = $1;
            $sessionfiles = "$sessionfiles/areas/" . $area unless ($sessionfiles =~ /$area/);
            &main::mkpath($sessionfiles);
            $newgoodpage =~ s/\$area/$area/;
            $main::goodpage = $newgoodpage;
        }
    }
    return (1, $sessionfiles, $sbsession);
}


sub go_goodpage {
    my $class     = shift();
    my $args      = shift();
    my $goodpage  = $args->{'goodpage'};
    my $sbsession = $args->{'sbsession'};
    
    my $area;
    if ($args->{'goodpage'} =~ m/$area_regex/) {
        $area = $1;
    } elsif ( ($ENV{'REQUEST_URI'} =~ /handoff/) && ($ENV{'REQUEST_URI'} =~ m/$area_regex/) ) {
        $area = $1;
    }

    if ($area) {
		print "PLUGIN " . __PACKAGE__ . " changing good page and session directory (this should match .htaccess)\n" if ($debug);
        $main::sessionfiles = "$main::sessionfiles/areas/" . $area unless ($main::sessionfiles =~ /$area/);
        &main::mkpath($main::sessionfiles);
        $args->{'goodpage'} =~ s/\$area/$area/;
    }
    return (1, $args->{'goodpage'}, $sbsession);
}


sub video2 {
    my $class        = shift();
    my $sessionfiles = shift();
    my $sbsession    = shift();
    my $file         = shift();

    my $area;
    if ($file =~ m/$area_regex/) {
        $area = $1;
    }

    if ($area) {
        $sessionfiles = "$sessionfiles/areas/" . $area unless ($sessionfiles =~ /$area/);
        &main::mkpath($sessionfiles);
    }
    return (1, $sessionfiles, $sbsession, $file);
}

1;

