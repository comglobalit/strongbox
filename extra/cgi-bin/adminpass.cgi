#!/usr/bin/perl

my $cgi = &parse_query();

my $user = $cgi->{'user'} || "adminuserame";
my $pass = $cgi->{'pass'} || &randstring(16) ;
$user =~ s|<.+?>||g;
$pass =~ s|<.+?>||g;
my $salt = '$1$' . &randstring(7) . '$';
my $cryptpass = crypt($pass, $salt);


print qq|Content-type: text/html

<html>
<head>
<title>Strongbox Admin User Password Generator</title>
</head>
<body>
<h1>Strongbox Admin Password Generator</h1>
<h2>Password File</h2>
Add this line to your file <b>cgi-bin/sblogin/.htpasswd_admin</b>:
<br />
<textarea cols="56">$user:$cryptpass</textarea><br /><br />
This line should replace any old line which starts with "$user:".
<p>Go back to <a href="https://github.com/comglobalit/strongbox/wiki/Strongbox-Admin-Users">Strongbox Admin Users documentation</a>
<h2>Use another one</h2>
<form method="post">
Username: <input type="text" id="user" name="user" value="$user"><br>
Password: <input type="text" id="pass" name="pass" value='$pass'><br>
<input type="submit" value="Create a new admin user">
</form>
</ul>
</body>
</html>
|;

sub randstring {
    my $length = $_[0];
    my $session;
    my $i = 0;
    while ( $i++ < $length ) {
        $code = 58;
        while (( ( $code > 57 ) && ( $code < 65 ) )
            || ( ( $code > 90 ) && ( $code < 97 ) ) )
        {   
            $code = int( rand(74) + 48 );
        }
        $session .= sprintf( "%c", $code );
    }
    return $session;
}


sub parse_query {
        return \%contents if ($contents{'raw'});
        if ($ENV{'REQUEST_METHOD'} eq "POST") {
           read(STDIN,$buffer,$ENV{'CONTENT_LENGTH'});
        } else {
                $buffer = $ENV{'QUERY_STRING'};
        }
        $contents{'raw'} = $buffer;
        $contents{'PATH_INFO'} = $ENV{'PATH_INFO'};
        $contents{'QUERY_STRING'} =  $ENV{'QUERY_STRING'};
        @pairs= split(/&/,$buffer);
        foreach $pair (@pairs) {
           ($name,$value) = split(/=/,$pair);
           $value =~ tr/+/ /;
           $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
      if ($contents{$name}) {
         $contents{$name} .= "|$value";
         push (@{$contents{$name . "_array"}}, $value);
      } else {
             $contents{$name} = $value;
      }
           print "\$contents{$name}:" . $contents{$name} . "\n" if ($debug);
        }
        return \%contents;
}
