#!/usr/bin/perl

require './config.pl';
require './routines.pl';

$cgi = &parse_query();

print "Content-type: text/html\n\n";

&do_plugins('showturing', {  } );

