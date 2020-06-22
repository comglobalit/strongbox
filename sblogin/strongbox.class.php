<?php


/*
    Typical usage:  
    require_once('strongbox.class.php');
    if ( empty($strongbox) ) { $strongbox = new strongbox; }
    $_SERVER['REMOTE_USER'] = $strongbox->get_sbuser_session();


    Functions for external use:
         
    list ($ok, $sbstatus, $sbsession) = $strongbox->login($username, $password)
    function lookup_sbuser() (don't create a session to save it)
    function get_sbuser_session() (saved in a session)
    function sb_isadmin()
    function get_sbsession()
    function sbsession_kill($user)
*/





function fix_session_cookie_host() {
    $host = preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']);
    $host = preg_replace ( '/^www\./' , '', $host);

    $currentCookieParams = session_get_cookie_params();
    session_set_cookie_params(
        $currentCookieParams["lifetime"],
        $currentCookieParams["path"],
        ".$host",
        $currentCookieParams["secure"],
        $currentCookieParams["httponly"]
    );
}

fix_session_cookie_host();

class strongbox {

    var $error_message;
    var $error_file;
    var $error_line;

    function strongbox() {
        $this->error_file = __FILE__;
    }
    
    function _error($message, $line) {
        $this->error_line = $line;
        $this->error_message = $message;
        return false;
    }

    function base_host() {
        $host = preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']);
        $host = preg_replace ( '/^www\./' , '', $host);
        return $host;
    }

   
    function sbsession_kill($user, $sblogin_dir = ""){
        if ( $sblogin_dir == "" ) {
            $sblogin_dir = $this->_get_sblogin_dir();
        }
	# Look for an active session for this user
        if (($sbsession = $this->lookup_sbsession($user, $sblogin_dir))===false)
	  return false;
	# If found an active session, delete it
        while ($session_dir = $this->_find_session_dir($sbsession, $sblogin_dir.'/.htcookie')) {
            if ($this->_delete_recursive($session_dir)===false) return false;
        } 
        return true;            
    }
    
    function lookup_sbsession($user, $sblogin_dir = "") {
        if ( $sblogin_dir == "" ) {
            $sblogin_dir = $this->_get_sblogin_dir();
        }

        $sblogname = $sblogin_dir . '/.htpasslog';
        
        if (!file_exists($sblogname)) 
            return $this->_error('Not found session log file: '.$sblogname,__LINE__);
        
        $sb_rec_len = 81;
        $sblog = @fopen($sblogname, 'r');
        if ($sblog===false) 
            return $this->_error('Error opening session log file '.$sblogname,__LINE__);
        
        fseek($sblog, -1000 * $sb_rec_len, SEEK_END);
        $sbsession = false;
        do {
            $line = fgets($sblog, 4096);
            $fields = explode(":", $line);
            $sbuser = trim($fields[0],'.');
            if(strcasecmp($sbuser,$user)==0) {
	        # Found a session
                $sbsession = $fields[6];
	        # Check if it's valid
		$host = $this->base_host();
	        if( !(file_exists("$sblogin_dir/.htcookie/$sbsession.$host") )) {
	            $sbsession = false;
	        }
            }
        } while ( (!feof($sblog)) && (!$sbsession));
        fclose($sblog);
        
        return $sbsession;
    }
    
    function _find_session_dir($sbsession, $sbcookie_dir) {
        $res = null;
        $dir_handle=opendir($sbcookie_dir);
        while ((is_null($res)) and (false !== ($file=readdir($dir_handle)))) {
            if (strpos($file,$sbsession)!==false)
	        $res = $sbcookie_dir.'/'.$file; 
        }
        closedir($dir_handle);
        return $res;
    }
    
    function _delete_recursive($dirname) {
        if ( is_dir($dirname) ) {
          $dir_handle=opendir($dirname);
          while ( $file=readdir($dir_handle) ) {
              if ($file!="." && $file!="..") {
                  if ( is_dir($dirname."/".$file) ) {
                      $this->_delete_recursive($dirname."/".$file);
                  } else {
                      @unlink ($dirname."/".$file);
                  }
              }
          } 
          closedir($dir_handle);
          @rmdir($dirname);
        } else {
            @unlink ($dirname);
        }
        return true;
    }

    // list ($loginok, $sbstatus, $sbsession) = login($_GET['username'], $_GET['pwd']);
    function login($username, $password) {
        error_reporting(E_ALL);
        $headers = array(
                          'Referer'=> $_SERVER['HTTP_REFERER'],
                          'Accept'=> $_SERVER['HTTP_ACCEPT'],
                          'User-Agent'=> $_SERVER['HTTP_ACCEPT'],
                          'Host'=> $_SERVER['HTTP_HOST']
                     );
    
        $ch = curl_init();
        curl_setopt ( $ch , CURLOPT_HTTPHEADER, $headers );
        curl_setopt ( $ch , CURLOPT_USERAGENT, $_SERVER['HTTP_USER_AGENT'] );
    
        $url = 'http://' . $_SERVER['HTTP_HOST'] . '/cgi-bin/sblogin/login.cgi';
        $fields = array(
                              'uname'=>urlencode($username),
                              'pword'=>urlencode($password),
                              'remote_addr'=> $_SERVER['REMOTE_ADDR'],
                              'accept'=> urlencode($_SERVER['HTTP_ACCEPT']),
                              'mode'=> 'script'
                       );
    
        $fields_string = '';
        foreach($fields as $key=>$value) { $fields_string .= $key.'='.$value.'&'; }
        rtrim($fields_string,'&');
    
        $ch = curl_init();
    
        curl_setopt($ch,CURLOPT_URL,$url);
        curl_setopt($ch,CURLOPT_RETURNTRANSFER,1);
        curl_setopt($ch,CURLOPT_POST,count($fields));
        curl_setopt($ch,CURLOPT_POSTFIELDS,$fields_string);
    
        $result = curl_exec($ch);
        // echo $result;
        curl_close($ch);
    
        if ($result) {
            foreach (split("\n", $result) as $line){
                if ( preg_match('/^sbstatus: (.*)/', $line, $matches) ) {
                   $sbstatus = $matches[1];
                }
                if ( preg_match('/^sbsession: (.*)/', $line, $matches) ) {
                   $sbsession = $matches[1];
                }
            }
            $host = $this->base_host();
            setcookie('sbsession', $sbsession, 0, "/", ".$host");
            setcookie('sbuser', $username, 0, "/", ".$host");
            return array( preg_match('/^good/', $sbstatus) , $sbstatus, $sbsession );
        } else {
            return;
        }
    }


    function get_sbuser_session() {
        if ( empty($_SERVER['REMOTE_USER']) ) {
            if ( isset($_SESSION['PHP_AUTH_USER']) && ($_SESSION['PHP_AUTH_USER'] != '') ) {
                $_SERVER['PHP_AUTH_USER'] = $_SESSION['PHP_AUTH_USER'];
                $_SERVER['REMOTE_USER']   = $_SESSION['PHP_AUTH_USER'];
                $_SESSION['REMOTE_USER']  = $_SESSION['PHP_AUTH_USER'];
            } else {
                session_start();
                $_SESSION['REMOTE_USER']   = $this->lookup_sbuser();
                $_SESSION['PHP_AUTH_USER'] = $_SESSION['REMOTE_USER'];
                $_SERVER['REMOTE_USER']    = $_SESSION['REMOTE_USER'];
                $_SERVER['PHP_AUTH_USER']  = $_SESSION['REMOTE_USER'];
            }
        }
        return $_SERVER['REMOTE_USER'];
    }

    function lookup_sbuser($session) {
    
        if ( isset($_SESSION['REMOTE_USER']) && ($_SESSION['REMOTE_USER'] != '') && !(isset($session)) ) {
            $_SERVER['REMOTE_USER'] = $_SESSION['REMOTE_USER'];
        }
        if ( isset($_SERVER['REMOTE_USER']) && !(isset($session)) ) {
            return $_SERVER['REMOTE_USER'];
        }
    
        $sbsession = isset($session) ? $session : $this-> get_sbsession();
        if ( empty($sbsession) ) {
            return NULL;
        }
    
    
        if (file_exists($_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin')) {
            $sblogname = $_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin/.htpasslog';
        } else {
            $sblogname = $_SERVER['DOCUMENT_ROOT'] . '/../cgi-bin/sblogin/.htpasslog';
        }
    
        $sb_rec_len = 81;
        $sblog = fopen($sblogname, 'r');
        if ($sblog===false) {
            return false;
        }
        if ( filesize($sblogname) >  10000 * $sb_rec_len) {
            fseek($sblog, -10000 * $sb_rec_len, SEEK_END);
        }
        do {
            $line = fgets($sblog, 4096);
            $fields = explode(":", $line);
            if( isset($fields[6]) && strcasecmp( $fields[6],$sbsession)==0) {
                $sbuser = trim($fields[0],'.');
            }
        } while ( (!feof($sblog)) && empty($sbuser) );
    
        fclose($sblog);
        if ( ! empty($sbuser) ) {
            $_SERVER['REMOTE_USER'] = $sbuser;
            if ( (session_id() == '') and !(headers_sent()) ) {
                session_start();
            }
            $_SESSION['REMOTE_USER'] = $sbuser;
            return $sbuser;
        }
    }

    function get_sbsession() {
        if ( isset($_SERVER['sbsession']) ) {
            $sbsession = $_SERVER['sbsession'];
        }
        if ( preg_match('/sbsession=(sb[0-9a-z]*)/', $_SERVER['HTTP_COOKIE'], $result) ) {
            $sbsession = $result[1];
        }
        if ( preg_match('/(^sb[0-9a-z]*)\./', $_SERVER['HTTP_HOST'], $result) ) {
            $sbsession = $result[1];
            $sbsession = $result[1];
        }
        if (! isset($_ENV['sbsession']) ) {
            $_ENV['sbsession'] = getenv('sbsession');
        }
        if ( ! empty($_ENV['sbsession']) ) {
            $sbsession = $_ENV['sbsession'];
        } else {
            global $HTTP_ENV_VARS;
            if ( ! empty($HTTP_ENV_VARS['sbsession']) ) {
                $sbsession = $HTTP_ENV_VARS['sbsession'];
            }
        }
     
        $host = $this->base_host();
        if ( empty($sbsession) ) {
            return NULL;
        } elseif (
                file_exists($_SERVER['DOCUMENT_ROOT'] . "/cgi-bin/sblogin/.htcookie/$sbsession.$host") ||
                file_exists($_SERVER['DOCUMENT_ROOT'] . "/../cgi-bin/sblogin/.htcookie/$sbsession.$host")
               ) {
            return $sbsession;
        } else {
            return NULL;
        }
    }
     
    function sb_isadmin() {
        $sbsession = $this->get_sbsession();
        $host = $this->base_host();
        if (
               file_exists($_SERVER['DOCUMENT_ROOT'] . "/cgi-bin/sblogin/.htcookie/$sbsession.$host/admin") ||
               file_exists($_SERVER['DOCUMENT_ROOT'] . "/../cgi-bin/sblogin/.htcookie/$sbsession.$host/admin")
           ) {
            return $sbsession;
        } else {
            return NULL;
        }
    }

    function _get_sblogin_dir() {
        if (file_exists($_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin')) {
            return $_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin';
        } else {
            return $_SERVER['DOCUMENT_ROOT'] . '/../cgi-bin/sblogin';
        }
    }

}


?>
