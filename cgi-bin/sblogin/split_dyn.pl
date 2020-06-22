#!/usr/bin/perl
 
# Date: 2006-09-14
 

BEGIN {
    eval { require Inline; };
    if ( ($@) || (! -x '/usr/bin/gcc') ) {
        # warn "Failed to load Inline module for best performance, or gcc isn't executable.";
        eval {
            sub c_line_matches {
                my ($lname,$ltime,$ladd1,$ladd2,$ladd3)=split(/\:/,$_[0]);
                return 1 if ("$ladd1:$ladd2:$ladd3" eq $_[2]);
                return 1 if ($lname eq $_[1]);
            };
        };
    } else {
        if ( -d "$ENV{'DOCUMENT_ROOT'}/cgi-bin/sblogin/.htcookie" ) {
            unless ( -d "$ENV{'DOCUMENT_ROOT'}/cgi-bin/sblogin/.htcookie/.lib" ) {
                mkdir("$ENV{'DOCUMENT_ROOT'}/cgi-bin/sblogin/.htcookie/.lib", 0755);
            }
            import Inline ( Config => DIRECTORY => "$ENV{'DOCUMENT_ROOT'}/cgi-bin/sblogin/.htcookie/.lib" ) ;
        } else {
            unless ( -d "$ENV{'DOCUMENT_ROOT'}/../cgi-bin/sblogin/.htcookie/.lib" ) {
                mkdir("$ENV{'DOCUMENT_ROOT'}/../cgi-bin/sblogin/.htcookie/.lib", 0755);
            }
            import Inline ( Config => DIRECTORY => "$ENV{'DOCUMENT_ROOT'}/../cgi-bin/sblogin/.htcookie/.lib" );
        }

        import Inline 'C' => <<'END_C_CODE';
            int c_line_matches(char *line, char *pname, char *saddr) {
                char luser[64];
                char ltime[24];
                char laddr[32];
                int fprintret;

                // fprintret = sscanf(line,"%31[^:]:%11[^:]:%12s:",luser,ltime,laddr);
                fprintret = sscanf(line,"%31[^:]:%12[^:]:%11s:",luser,ltime,laddr);
                if (fprintret < 3) {
                    return(0);
                }
                if ( strcmp(luser, pname) == 0) {
                    return(1);
                }
                if ( strcmp(laddr, saddr) == 0) {
                    return(1);
                }
                return(0);
            }
END_C_CODE
    

    }
}


1;



