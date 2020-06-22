#!/usr/bin/perl

# Date: 2006-02-07


# echo -e "Content-type: text/plain\n\n"
# echo "DOCUMENT_ROOT: $DOCUMENT_ROOT"
# echo -n "CGIBIN: "
# pwd


print "Content-type: text/plain\n\n";
print "DOCUMENT_ROOT: $ENV{'DOCUMENT_ROOT'}\n";
$ENV{'SCRIPT_FILENAME'} =~ m@(.*[/\\])[^/\\]*$@;
print "CGIBIN: $1\n";

