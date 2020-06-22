#
#===============================================================================
#
#         FILE:  Strongbox/Plugin/AuthAnd.pm
#
#  DESCRIPTION: Plugin for Strongbox to require authentication from ALL of some
#               different sources.
#
#       AUTHOR:  Ray Morris support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  04/04/2012 04:03:14 PM
#     REVISION:  ---
#===============================================================================
# Usage:
# @htpfiles  = (
#                [ \&Strongbox::Plugin::AuthAnd::auth_and,
#                        [
#                            [\&checkpasswd_mysql,    $dbinfo ],
#                            [\&checkpasswd_htpasswd, "$ENV{'DOCUMENT_ROOT'}/cgi-bin/mjv4RAoTG3LarnyZbsfXxCPNgkEK2Hiz/password/.htpasswd"]
#                        ]
# 
#                ],
#                [\&checkpasswd_htpasswd, "./.htpasswd_admin" ]
#              );



package Strongbox::Plugin::AuthAnd;
require Exporter;
@ISA = qw(Exporter);
@EXPORT    = qw( auth_and );

use strict;
use warnings;

my $debug = $main::debug;

sub auth_and {
    my $uname = shift();
    my $pword = shift();
    my $htpref = shift();
    my $userpass = 'badpuser';
    # It needs to be packaged up because it's passed through as a single argument.
    my @htpfiles = @{$htpref->[0]};
    use Data::Dumper;

    # print "here \@htpfiles:  ", Dumper( [ @htpfiles ] );
    foreach my $htpfile (@htpfiles) {
        if ( ref($htpfile) eq 'ARRAY' ) {
            ($userpass, $htpfile->[1]) = &{$htpfile->[0]}($uname, $pword, [ $htpfile->[1] ] );
            print "in AuthAnd, checked ", $htpfile->[1], " via " . $htpfile->[0] . ", userpass: '$userpass'\n" if ($debug);
        } else {
            ($userpass, $htpfile) = &main::oldpwcheck($htpfile) if ($userpass eq 'badpuser');
        }
        return ($userpass, $htpfile) if ($userpass eq 'badpuser');
    }
    return ($userpass, $htpfiles[0]->[1]);
}


1;


