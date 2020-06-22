#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  historicaltest.pl
#
#        USAGE:  ./historicaltest.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  12/16/2010 04:14:36 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use lib './lib';
my $debug = 1;

use Strongbox::Plugin::HistoricalLog;


my $logfile = '.htpasslog';
my $maxlogsize = 300000;

Strongbox::Plugin::HistoricalLog->trimloginlog($logfile, $maxlogsize);


