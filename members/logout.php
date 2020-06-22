<?php

$host = preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']);
$host = preg_replace ( '/^www\./' , '', $host);
setcookie('sbsession', 'invalid', time() - 18000, '/', $host);
setcookie('sbsession', 'invalid', time() - 18000, '/', '.' . $host);
sblogout();
header("Location: http://$host/");  # Return user to the site's front page.


function sblogout() {
    if ( preg_match('/sbsession=(sb[0-9a-z]*)/', $_SERVER['HTTP_COOKIE'], $result) ) {
        $sbsession = $result[1];
    }
    if ( preg_match('/(^sb[0-9a-z]*)\./', $_SERVER['HTTP_HOST'], $result) ) {
        $sbsession = $result[1];
    }
    $host = preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']);
    if (!$_ENV['sbsession']) {
        $_ENV['sbsession'] = getenv('sbsession');
    }
    if ($_ENV['sbsession']) { 
        $sbsession = $_ENV['sbsession']; 
    } else {
        global $HTTP_ENV_VARS;
        if ($HTTP_ENV_VARS['sbsession']) {
            $sbsession = $HTTP_ENV_VARS['sbsession'];
        }
    }
    if ($sbsession) {
        if (file_exists($_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin')) {
            $sbhtcookie = $_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin/.htcookie';
        } else {
            $sbhtcookie = $_SERVER['DOCUMENT_ROOT'] . '/../cgi-bin/sblogin/.htcookie';
        }
        if ( file_exists("$sbhtcookie/$sbsession.$host") ) {
            DELETE_RECURSIVE_DIRS("$sbhtcookie/$sbsession.$host");
        }
    }
}




function DELETE_RECURSIVE_DIRS($dirname) {
  if(is_dir($dirname))$dir_handle=opendir($dirname);
  while($file=readdir($dir_handle))
  {
    if($file!="." && $file!="..")
    {
      if(!is_dir($dirname."/".$file))unlink ($dirname."/".$file);
      else DELETE_RECURSIVE_DIRS($dirname."/".$file);
    }
  }
  closedir($dir_handle);
  rmdir($dirname);
  return true;
}


?>
