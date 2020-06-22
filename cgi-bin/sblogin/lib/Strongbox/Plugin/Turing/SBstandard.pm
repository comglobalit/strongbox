package Strongbox::Plugin::Turing::SBstandard;

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
       <br />
      <img name="turingimage" id="turingimage" alt="visible_turing, audible turing also available"  src="/cgi-bin/sblogin/turingimage.cgi?$now"><br />
       Enter the word shown in the image</b>:<br />
       <input type="text" name="turing" size="6"><br />
       <br />
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

    my $turingfile = $main::sessionfiles . "/turings/" . uc($args->{'cgi'}->{'turing'}) . ".gif";

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


