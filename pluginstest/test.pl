#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  test.pl
#
#        USAGE:  ./test.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Ray Morris (), support@bettercgi.com
#      COMPANY:  RMEE Inc
#      VERSION:  1.0
#      CREATED:  04/21/2010 04:08:42 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;



my @plugins = ( 'Strongbox::Plugin::Multiarea' );

&load_plugins;

sub load_plugins {
    use lib 'lib';
    foreach my $plugin (@plugins) { eval "require $plugin;"; }
}

# Ex: my $something = &do_plugins('say', ['hello', \$name]);

sub do_plugins {
    my $method = shift();
    my $args = shift;
    my @return;
    foreach my $plugin (@plugins) {
        @return = $plugin->$method(@$args) if ( $plugin->can($method) );
        last unless ( shift(@return) );
    }
    return @return;
}

