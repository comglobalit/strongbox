#!/usr/bin/perl

# Date: 2005-10-13



$reclen += 22;
$soft_fprint = md5_base64("$ENV{'HTTP_USER_AGENT'}/$ENV{'HTTP_ACCEPT'}");

BEGIN {
      eval {
                require Digest::MD5;
                import Digest::MD5 'md5_base64'
      };
      if ($@) {
            eval {
                require Digest::Perl::MD5;
                import Digest::Perl::MD5 'md5_base64'
            }
      }
      if ($@) { # no Digest::Perl::MD5 either
            eval {
                    use lib '.';
                    require MD5;
                    import MD5 'md5_base64';
                }
      }
      if ($@) { # no Digest::Perl::MD5 in current directory either
          die "I can't find any MD5 module anywhere, not even the pure perl one: $!";
      }
}


1;

