#!/usr/bin/perl

# Date: 2006-01-21

my %order;
my %config;


open(ORDER,  $ARGV[0]) or die "could not open '$ARGV[0]': $!";
while(my $line = <ORDER>) {
    foreach $param ('domain', 'ftp_user', 'ftp_pass', 'admin_user', 'email') {
        if ($line =~ /^$param/) {
            chomp $line;
            my ($key, $value) = split(/: /, $line);
            $value =~ s/^ *//g;
            $value =~ s/ *$//g;
            if ($param eq 'domain') {
                $value =~ s/http:\/\///;
                $value =~ s/www\.//;
                $value =~ m/^([a-zA-Z0-9\.-]*)/;
                $value = lc($value);
                $value = $1;
            }
            $order{$param} = $value;
        }
    }
}
close ORDER;


my $bmname = $order{'domain'};
$bmname =~ s/\.[^\.]*$//;
$bmname = substr($bmname,0,15);


my $bookmarkexists = 0;
open(NCBM, "$ENV{'HOME'}/.ncftp/bookmarks") or die "could not open bookmarks: $!";
while( my $line = <NCBM> ) {
    $bookmarkexists++ if ($line =~ m/^$bmname/);
}
close NCBM;

if ($bookmarkexists) {
    print "Bookmark exists already\n";
} else {
    open(NCBM, ">>$ENV{'HOME'}/.ncftp/bookmarks") or die "could not open bookmarks: $!";
    print NCBM "$bmname,$order{'domain'},$order{'ftp_user'},$order{'ftp_pass'},,,I,21,,1,1,1,1,,,,,,,,S,0\n";
    close NCBM;
}


$order{'key'} = &randstring(28);

open(CFGDEF, "$ENV{'HOME'}/sb/install/cgi-bin/sblogin/config.pl") or die "could not open default config: $!";
open(CFGNEW, '../pages/config.pl') or die "could not open new config: $!";
while(my $line = <CFGDEF>) {
    foreach $param ('admin_user', 'email', 'key') {
        my $template = "#" . $param . "#";
        $line =~ s/$template/$order{$param}/g;
    }
    print CFGNEW $line;
}
close CFGDEF;
close CFGNEW;




my $wildcard = `checkwildcard.sh $order{'domain'}`;
chomp $wildcard;

print "wildcard: '$wildcard'\n";

if ($wildcard) {
    system("ncftp $bmname");
} else {
    print "Wildcard needed.\n";
}



sub randstring {
        my $length = $_[0];
        my $i = 0;
        my $string = "";
        while ($i++ < $length) {
                $code = 58;
                while ( ($code > 57) && ($code < 97)  ) {
                        $code = int(rand(74) + 48);
                }
                $string .= sprintf("%c", $code);
        }
        return $string;
}

