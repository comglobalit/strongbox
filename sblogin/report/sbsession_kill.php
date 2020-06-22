<?php
if(!empty($_REQUEST['debug'])) { header('Content-Type: text/plain'); };


if ($_SERVER['PHP_SELF'] == '/sblogin/report/sbsession_kill.php') {
    if ( empty($_REQUEST['user']) ) {
        echo "please enter a user name\n";
        exit;
    }

    if ( sbsession_kill($_REQUEST['user']) ) {
        echo "User '" . $_REQUEST['user'] . "' has been logged out.\n\nPlease click your browser's back button to return to the previous page.";

    } else {
        echo "User '" . $_REQUEST['user'] . "' is not logged in.\n\nPlease click your browser's back button to return to the previous page.";
    }
}

function sbsession_kill($user){
    $sbsession = lookup_sbsession($user);

    if ( empty($sbsession) ) {
	if(!empty($_REQUEST['debug'])) { echo "session not found for $user\n"; };
        return FALSE;
    }

    $host = preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']);
    $host = preg_replace ( '/^www\./' , '', $_SERVER['HTTP_HOST']);
	if(!empty($_REQUEST['debug'])) { echo "host is $host\n"; };
    if ( file_exists($_SERVER['DOCUMENT_ROOT'] . "/cgi-bin/sblogin/.htcookie/$sbsession.$host")) {
	if(!empty($_REQUEST['debug'])) { echo "session found in /cgi-bin/sblogin/.htcookie/$sbsession.$host \n"; };
        delete_recursive($_SERVER['DOCUMENT_ROOT'] . "/cgi-bin/sblogin/.htcookie/$sbsession.$host");
        return TRUE;
    } else if ( file_exists($_SERVER['DOCUMENT_ROOT'] . "/../cgi-bin/sblogin/.htcookie/$sbsession.$host") ) {
	if(!empty($_REQUEST['debug'])) { echo "session found in /../cgi-bin/sblogin/.htcookie/$sbsession.$host \n"; };
        delete_recursive($_SERVER['DOCUMENT_ROOT'] . "/../cgi-bin/sblogin/.htcookie/$sbsession.$host");
      return TRUE;
    } else {
        return FALSE;
    }
}


function lookup_sbsession($user) {
    if (file_exists($_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin')) {
        $sblogname = $_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin/.htpasslog';
        $sblogdir = $_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin/.htcookie';
    } else {
        $sblogname = $_SERVER['DOCUMENT_ROOT'] . '/../cgi-bin/sblogin/.htpasslog';
        $sblogdir = $_SERVER['DOCUMENT_ROOT'] . '/../cgi-bin/sblogin/.htcookie';
    }
	if(!empty($_REQUEST['debug'])) { echo "sblogname = $sblogname\nsblogdir = $sblogdir \n"; };
    $host = preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']);
    $host = preg_replace ( '/^www\./' , '', $_SERVER['HTTP_HOST']);
	if(!empty($_REQUEST['debug'])) { echo "host = $host \n"; };
    if ( is_dir("$sblogdir/$user.$host") ) {
	return $user;
    }

    $sb_rec_len = 79;
    $sblog = fopen($sblogname, 'r');
    if ($sblog===false) {
        return false;
    }
    fseek($sblog, -1000 * $sb_rec_len, SEEK_END);
    $trash = fgets($sblog, 4096);
    do {
        $line = fgets($sblog, 4096);
        $fields = explode(":", $line);
        $sbuser = trim($fields[0],'.');
        if(strcasecmp($sbuser,$user)==0) {
            $sbsession = $fields[6];
        }
    } while ( !feof($sblog) );
    fclose($sblog);
    return $sbsession;
}


function delete_recursive($dirname) {
  if ( is_dir($dirname) ) {
      $dir_handle=opendir($dirname);
      while ( $file=readdir($dir_handle) ) {
          if ($file!="." && $file!="..") {
              if ( is_dir($dirname."/".$file) ) {
                  delete_recursive($dirname."/".$file);
              } else {
                  unlink ($dirname."/".$file);
              }
          }
      } 
      closedir($dir_handle);
      rmdir($dirname);
  } else {
      unlink ($file);
  }
  return true;
}

?>
