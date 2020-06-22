#!/usr/bin/perl 

BEGIN {
        $debug = 0;
        if ($debug) {
                print "Content-type: text/plain\n\n";
                open (STDERR, ">&STDOUT");
                                                                                                       
                select(STDERR); $| = 1;
                select(STDOUT); $| = 1;
        }
}
 
use lib '..';
# use lib '../lib/';
require '../config.pl';
$localdebug = $debug;
require "./config_reports.pl";

use Time::Local;
 
require "../routines.pl";
$debug = $localdebug;
&am_admin();

my $cgi = &parse_query();

my $show_top = $cgi->{'show_top'};
my $begin_date = "$cgi->{'begin_month'}/$cgi->{'begin_day'}/$cgi->{'begin_year'}";


my $begin = timegm(0,0,0,$cgi->{'begin_day'},$cgi->{'begin_month'} -1,$cgi->{'begin_year'});
my $end = time();
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($end);
my $end_date = sprintf("%02d/%02d/%04d", $mon + 1, $mday, $year + 1900);

print "begin: $begin\nend: $end\n" if ($debug);

# my $totalattempts = 0;
my $totalerrors = 0;
my $totalusers = 0;
my $totalips = 0;

&read_log;
&print_results_html;


sub read_log() {
    foreach $logfile (@logfiles) {
        open LOG, "$logfile";
        while (my $entry = <LOG>) {
         chomp $entry;
         ($user, $time, $ip1, $ip2, $ip3, $lstat, $sbsession,$lcountry) = split(":", $entry);

         next if ($time < $begin);
         last if ($time > $end);
         $user =~ s/\.*$//g;
         $user =~ s/\-*$//g;

	  print "analyzing $entry\n" if ($debug);
          if ($cgi->{'show_codes'} =~ m/$lstat/) {
             print "$lstat matched $cgi->{'show_codes'}\n" if ($debug);
             # $statae_per_user{$user{$lstat}}++
             if ($lstat eq "attempts") {
                $totalips{"$ip1.$ip2.$ip3"}++;
             }
             else
             {
                $statae_per_user{$user}{$lstat}++;
                $totalusers++ unless ($totalusers{$user}++);
             }
           }
           else
           {
              print "$lstat not found in $cgi->{'show_codes'}\n" if ($debug);
           }
    }
  } ## end foreach $logfile (@logfiles)
}
                                                                                                       




sub print_results_html() {
   my $ipcount = scalar keys (%totalips);
   print "Content-type: text/html\n\n";
   print "<html>\n";
   print qq|<head>
             <title>top $show_top logins $begin_date - $end_date</title>
	          <LINK REL=STYLESHEET TYPE="text/css" HREF="$reporturl/../../strongbox.css">	
	          <script type="text/javascript">
	             function statushelp(code) {	
		             PageURL="$reporturl/../../codes.html#" + code;
		             WindowName="statuscodes";
		             settings=
		             "toolbar=no,location=no,directories=no,"+
		             "status=no,menubar=no,scrollbars=yes,"+
		             "resizable=yes,width=350,height=150";
                             MyNewWindow=window.open(PageURL,WindowName,settings); 
		          }
                      function countryhelp(code) {
                        PageURL="$reporturl/../countries.html#" + code;
                        WindowName="countrycodes";
                        settings=
                        "toolbar=no,location=no,directories=no,"+
                        "status=no,menubar=no,scrollbars=yes,"+
                        "resizable=yes,width=350,height=150";
                        MyNewWindow=
                        window.open(PageURL,WindowName,settings);
                    }


               </script>
            </head>
            <body>
               <h2>StrongBox Report $begin_date - $end_date</h2>
               $totalusers different usernames denied.<br>
               $ipcount IP ranges suspended.<br>
               <hr>
|;
                                                                                                       
   print "<table><caption>denied users $begin_date - $end_date</caption>\n";

   foreach $user  ( keys(%statae_per_user) ) {
      print "\t<tr>\n";
      print "\t\t<td><a href=\"byuser.cgi?user=$user\">\"$user\"</a></td>\n";
      print "\t\t<td>";
      %statae = %{$statae_per_user{$user}};
      foreach $status ( keys(%statae)  ) {
      # foreach $status  ( keys(%{statae_per_user{$user}}) ) {
         print "<a class=\"status\" onClick='statushelp(\"$status\")'>$status</a> ";
      }
      print "\t\t</td>\n\t</tr>\n\n";
   }
   print "</table>\n\n<hr>\n\n";


   if ( $cgi->{'show_codes'} =~ m/attempts/ ) {
      print "<h2>denied IP addresses $begin_date - $end_date</h2>\n<ul>\n";
      foreach $ip (   sort SortErrorsPerIP ( keys(%totalips) )   ) {
      # foreach $ip ( keys(%{totalips}) ) {
         print "<li><a href=\"byip.cgi?ip=$ip\">$ip</a> ($totalips{$ip} blocked logins)</li>\n";
      }
      print "</ul>\n";
   }

   print "\n</body>\n</html>\n";                                   
}



                                                                                                       
sub SortErrorsPerIP {
        $totalips{"$b"} <=> $totalips{"$a"};
}



                                                                                                       
sub SortIpsPerUser {
        $#{$ips_per_user{"$b"}} <=> $#{$ips_per_user{"$a"}};
}
                                                                                                       
sub SortUsersPerIP{
        $#{$users_per_ip{$b}} <=> $#{$users_per_ip{$a}};
}
                                                                                                       
sub SortErrorsPerUser {
   $errors_per_user{"$b"} <=> $errors_per_user{"$a"};
}
                                                                                                       


exit 1;



