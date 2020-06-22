#!/usr/bin/perl
 
# Date: 2009-02-20
 

use HTTP::Request;
use LWP::UserAgent;


sub custom_init {
    foreach my $param ('authuser', 'username', 'user', 'uid', 'loginuser', 'id', 'code[1]', 'code%5B1%5D') {
        $cgi->{'uname'} |= $cgi->{$param};
    }
    
    foreach my $param ('password', 'pass', 'id', 'code[1]', 'code%5B1%5D') {
        $cgi->{'pword'} |= $cgi->{$param};
    }
    print "uname: " . $cgi->{'uname'} . " in avs.pl custom_init\n" if ($debug);
}



sub checkpasswd_avs {
    my $uname = $_[0];
    my $pword = $_[1];
    $method = 'GET';

    if ($cgi->{'goodpage'} =~ /\/report/) {
        my ($status, $file) = &checkpasswd_htpasswd($uname, $pword); 
        return $status;
    }
    $ARGV[0] = $ENV{'PATH_INFO'} unless ($ARGV[0]);
    $ARGV[0] =~ s/^\///;

    $avs_url = "$ARGV[0]";
    $avs_url = "http://" . $avs_url unless ($avs_url =~ m/^http/);
    # $cgi->{'raw'} = 'code[1]=7thj1hbm&docId=84617&x=23&y=10&data=';


    $ua = new LWP::UserAgent;
    my $req;
    if ($method eq 'GET') {
        $req = new HTTP::Request GET => $avs_url . '?' . $cgi->{'raw'};
    } else {
        $req = new HTTP::Request POST => $avs_url;
        $req->content_type('application/x-www-form-urlencoded');
        $req->content($cgi->{'raw'});
    }
    $req->header( 'X-Forwarded-For' => $ENV{'REMOTE_ADDR'} );
    $req->header( 'Accept-Charset' => $ENV{'HTTP_ACCEPT_CHARSET'} );
    $req->header( 'Accept' => $ENV{'HTTP_ACCEPT'} );
    $req->header( 'Accept-Language' => $ENV{'HTTP_ACCEPT_LANGUAGE'} );
    $req->header( 'Referer' => $ENV{'HTTP_REFERER'} );
    $req->header( 'User-Agent' => $ENV{'HTTP_USER_AGENT'} );
    $req->header( 'Via' => 'HTTP/1.1 localhost' );
    print "avs_url: $avs_url\npostdata: " . $req->content() . "\n\n" if ($debug);

    my $res = $ua->simple_request($req);
    $response = $res->content;
    if ($debug) {
        $code    = $res->code;
        $message = $res->message;
        $headers = $res->headers_as_string;
        foreach ( keys %{ $res->headers() } ) {
            print "$_ = ", $res->headers()->{$_}, "\n";
        }
        print '<textarea rows="40" cols="40">';
        print "avs response: code: $code\nmessage: $message\ncontent: $response\n";
        print "</textarea>\n\n";
    }
    $location = $res->headers()->{'location'};

    if ($res->headers()->{'set-cookie'}) {
        if (ref($res->headers()->{'set-cookie'}) eq "ARRAY") {
            foreach my $cookie (@{$res->headers()->{'set-cookie'}}) {
                 print "Set-Cookie: $cookie\n";
            }
        } else {
            print "Set-Cookie: ", $res->headers()->{'set-cookie'}, "\n";
        }
    }
    if ($avs_deny_string) {
        if ($response =~ m/$avs_deny_string/) {
            return 'badpword';
        } else {
            $goodpage = $location;
            $goodpage =~ s/.*$host//;
            $cgi->{'goodpage'} = $goodpage;
            print "an avs.pl, set goodpage to $goodpage\n" if ($debug);
            return 'gooduser';
        }
    } elsif ($avs_approve_string) {
        if ($response =~ m/$avs_approve_string/) {
            $goodpage = $location;
            $goodpage =~ s/.*$host//;
            $cgi->{'goodpage'} = $goodpage;
            print "an avs.pl, set goodpage to $goodpage\n" if ($debug);
            return 'gooduser';
        } else {
            return 'badpword';

        }
    }
    
    if ( $res->code =~ m/4\d\d/ or $code =~ m/5\d\d/ ) {
        &errlog("avs_fail");
        return 'badpword';
    }


    $location = $res->headers()->{'location'};
    return 'badpword' if ($location =~ m/$avs_deny_string/i);

    if ( "$location" eq "" ) {
        if ( $response =~ m/$host.*?[ '">]/is ) {
            $goodpage = $&;
            chop $goodpage;
            $goodpage =~ s/.*$host//;
            print "goodpage: $goodpage\n\n" if ($debug);
            return 'gooduser';
        } else {
            return 'badpword';
        }
    } elsif ( $location =~ m/$host/ ) {
        $goodpage = $location;
        $goodpage =~ s/.*$host//;
        $cgi->{'goodpage'} = $goodpage;
        print "an avs.pl, set goodpage to $goodpage\n" if ($debug);
        return 'gooduser';
    } else {
        return 'badpword';
    }
}


1;


