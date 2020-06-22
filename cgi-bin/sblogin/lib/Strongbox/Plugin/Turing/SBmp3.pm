package Strongbox::Plugin::Turing::SBmp3;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.

use strict;
use warnings;

my $debug = $main::debug;

sub showturing {
    my $lcass = shift();
    my $now = time();
    print qq|
      <a target="_new" href="/cgi-bin/sblogin/turingsound.cgi?$now">Listen to a different word</a><br />
    |;
    return 1;
}

sub checkturing {
    my $class = shift();
    my $args = shift();

    # For backwards compatibility
    if ( defined($main::image_login) && ($main::image_login == 0) ) {
        $args->{'return'} = 1;
        return 0;
    }

    return 1 unless ($args->{'cgi'}->{'turing'});

    my $turingfile = $main::sessionfiles . "/turings/" . uc($args->{'cgi'}->{'turing'}) . ".mp3";

    return 1 unless (-f $turingfile);

    if (-M $turingfile > .01) {
        unlink $turingfile;
        return 1;
    }

    &rmoldturing unless (time() % 100);
    unlink $turingfile;
    $args->{'return'} = 1;
    return 0;
}

1;


