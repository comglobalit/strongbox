# StrongBox version 1.3
# Copyright 2001, 2002, 2003
# Ray Morris <support@webmastersguide.com>
 


sub encrypt() {
	my $smessage = $_[0];
	my $skey = $_[1];
	my $j = 0;
	my @message = split(//, $smessage);
	my @key = split(//, $skey);
	for (my $i = 0; $i <= $#message; $i++)
     	{
		$message[$i] =  sprintf("%02x",(ord($message[$i]) ^ ord($key[$j]) % 255));;
		$j = ($j + 1) % $#key;
     	}
	return(join('', @message));
}

sub decrypt() {
        my $smessage = $_[0];
        my $skey = $_[1];
        my $j = 0;
        my @message = split(//, $smessage);
        my @key = split(//, $skey);
	my $out;
        for (my $i = 0; $i <= $#message; $i = $i + 2)
        {
                $out =  $out . chr(    (hex($message[$i] . $message[$i + 1])) ^ ord($key[$j])    );
                $j = ($j + 1) % $#key;
        }
        return($out);
}


return 1;

