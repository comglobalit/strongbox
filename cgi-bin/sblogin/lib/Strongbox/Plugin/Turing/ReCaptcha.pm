# unless ( defined($cgi->{'hjs'}) ) {
#     foreach $plugin (@plugins) {
#         $plugin = 'Strongbox::Plugin::Turing::SBstandard' if ($plugin eq 'Strongbox::Plugin::Turing::ReCaptcha');
#     }
#     require './SBstandard.pm';
# }



package Strongbox::Plugin::Turing::ReCaptcha;

# Pass references if needed. They can be altered and passed to 
# the next plugin in turn.  return 1 to continue to the next plugin,
# 0 to stop the loop.


use Captcha::reCAPTCHA;
use strict;
use warnings;


my $public_key  = '6LdEcssSAAAAALGASHSGGrmeAZG3RtuSlZSaTBo5';
my $private_key = '6LdEcssSAAAAAGcce8q7LCYo4KF_BN8KROHV-zXl';
my $theme = 'red'; # red, white, clean, or blackglass

my $debug = $main::debug;

sub showturing {
    my $class = shift();

# unless ( defined($cgi->{'hjs'}) ) {
#    require './SBstandard.pm';
#     &Strongbox::Plugin::Turing::SBstandard::showturing();
# }

    print qq|
 <script type="text/javascript">var RecaptchaOptions = { theme : '$theme' }; </script>
 <script type="text/javascript"
     src="http://www.google.com/recaptcha/api/challenge?k=$public_key">
  </script>
  <noscript>
     <iframe src="http://www.google.com/recaptcha/api/noscript?k=$public_key"
         height="300" width="500" frameborder="0"></iframe><br>
     <textarea name="recaptcha_challenge_field" rows="3" cols="40">
     </textarea>
     <input type="hidden" name="recaptcha_response_field" value="manual_challenge">
  </noscript>
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
    unless ($args->{'cgi'}->{'recaptcha_challenge_field'} && $args->{'cgi'}->{'recaptcha_response_field'}) {
        print "recaptcha_challenge_field or recaptcha_response_field is empty\n" if ($debug);
        return 1;
    }

    my $c = Captcha::reCAPTCHA->new;

    my $challenge = $args->{'cgi'}->{'recaptcha_challenge_field'};
    my $response = $args->{'cgi'}->{'recaptcha_response_field'};

    # Verify submission
    my $result = $c->check_answer($private_key, $ENV{'REMOTE_ADDR'}, $challenge, $response);

    if ( $result->{'is_valid'} ) {
        $args->{'return'} = 1;
        print "recaptcha says it's valid\n" if ($debug);
        return 0;
    } else {
        print "recaptcha says it's not valid because ". $result->{error} . "\n" if ($debug);
        $args->{'return'} = 0;
        return 1;
    }
}

1;

