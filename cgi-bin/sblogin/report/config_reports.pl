# require "../config.pl"; 
 
# Date: 2012-01-23

 use lib "../lib";

 $cryptpasswords = 'MD5_salt'; # 0, 'MD5_salt', 'DES' or 'SHA1'
 @logfiles = ( '../.htpasslog' );

 $start_time = time() - 86400;

 $output = "./report_data";
 $gzip = "gzip -cN ";
 $deluxe = 0;



 $reportdir = "$ENV{'DOCUMENT_ROOT'}/sblogin/report/pages";
 $reporturl ="/sblogin/report/pages";
 $cgiurl = "/cgi-bin/sblogin/report";



  @httpdlogs = ( "../../../../logs/access_log" );


  # @httpdlogs = &latestfiles("/home/hsphere/local/home/somesite/logs/somesite.com", "linda");
  print "log files: " . join(" ", @httpdlogs) . "\n" if ($debug);


  sub yesterday_today {
     # This block will use log file names like access-2004-04-30.log.gz
     ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
     $year += 1900;
     $mon += 1;
     $file_today = sprintf("access-$year-%.2d-%.2d.log.gz", $mon, $mday);
 
     ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time() - (60*60*24));
     $year += 1900;
     $mon += 1;
     $file_yesterday = sprintf("access-$year-%.2d-%.2d.log.gz", $mon, $mday);
   
  
     @httpdlogs = (
                        "/usr/bin/gzcat /usr/domain/logs/asite.com/$file_yesterday |",
                        "</usr/domain/logs/asite.com/$file_today"
                );
  }




  sub latestfiles {
	$dir = $_[0];
	$partname = $_[1];

	my @return;

	my @files = grep {-f} glob "$dir/*$partname*";
	$fNT{$_} = sprintf "%010d", (stat $_)[9] for @files;#create hash with file and file last modified date
	@sorted = sort {$fNT{$b} <=> $fNT{$a}} keys %fNT;
	
	# return list in earliest to latest order
        if ($sorted[0] =~ m/gz$/) {
                $return[1] = "$gzcat $sorted[0] |";
        } else {
                $return[1] = "<$sorted[0]";
        }

        if ($sorted[1] =~ m/gz$/) {
                $return[0] = "$gzcat $sorted[0] |";
        } else {
                $return[0] = "<$sorted[0]";
        }

	return @return;
	
  }


1;

