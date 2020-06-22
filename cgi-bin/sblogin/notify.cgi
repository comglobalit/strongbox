#!/usr/bin/perl

# Date: 2012-02-27


use HTTP::Request;
use LWP::UserAgent;

BEGIN {
      eval {
                require Digest::MD5;
                import Digest::MD5 'md5_hex'
      };
      if ($@) {
            eval {
                require Digest::Perl::MD5;
                import Digest::Perl::MD5 'md5_hex'
            }
      }
      if ($@) { # no Digest::Perl::MD5 either
            eval {
                    use lib '.';
                    require MD5;
                    import MD5 'md5_hex';
                }
      }
      if ($@) {
          die "I can't find any MD5 module anywhere, not even the pure perl one: $!";
      }
}




if ($0 =~ /notify.cgi$/) {
    &recieve_notify();
} else {
    # &send_notify();
}



sub recieve_notify {
    my $cgi = &parse_query();
    my $now = &gettime();
    $browser_sig = $cgi->{'http_user_agent'} . "/" . $cgi->{'http_accept'};
    my $ticket = md5_hex($cgi->{'n'} . $key . $browser_sig);
    $goodpageguard++; # To avoid infinite loop of servers notifying each other.
    if ($cgi->{'n'} + 1800 < $now) {
        print "time too old, \$cgi->{'n'}: $cgi->{'n'}, $now: $now\n" if ($debug);
        print "Location: $errpage\n\n";
    }
    elsif ( $cgi->{'t'} ne $ticket)
    {
        print "ticket invalid, \$cgi->{'t'}: $cgi->{'t'}, ticket: $ticket\n" if ($debug);
        print "Location: $errpage\n\n";
    }
    else
    {
        my $sbsession = $cgi->{'sbsession'};
        $main::sbsession = $sbsession;
        $ENV{'REMOTE_ADDR'} = $cgi->{'remote_addr'};
        $ENV{'HTTP_USER_AGENT'} = $cgi->{'http_user_agent'};
        $ENV{'HTTP_ACCEPT'} = $cgi->{'http_accept'};
        &go_goodpage($sbsession);
    }
}


sub send_notify {
    my $url = $_[0];
    my $now = &gettime();
    $browser_sig = $ENV{'HTTP_USER_AGENT'} . "/" . $ENV{'HTTP_ACCEPT'};
    my $ticket = md5_hex($now . $key . $browser_sig);
    my %postdata;
    $postdata{'sbsession'}       = &get_session();
    $postdata{'remote_addr'}     = $ENV{'REMOTE_ADDR'};
    $postdata{'http_user_agent'} = $ENV{'HTTP_USER_AGENT'};
    $postdata{'http_accept'}     = $ENV{'HTTP_ACCEPT'};
    $postdata{'n'} = $now;
    $postdata{'t'} md5_hex($now . $key . $browser_sig);
    my $ua = LWP::UserAgent->new;
    $ua->timeout(2);
    my $response = $ua->post( $url, \%postdata );
    if ($response->is_success) {
        print $response->content if ($debug);
        return 1;
    } else {
        die "send_notify: " . $response->status_line if ($debug);
        return 0;
    }
}


