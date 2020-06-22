<?php include_once("header.php"); ?>
<h1>Active Sessions</h1>
<a href="/sblogin/report/">Back to Main Page</a>

<?php

require_once('../strongbox.class.php');
if ( empty($strongbox) ) { $strongbox = new strongbox; }
#$_SERVER['REMOTE_USER'] = $strongbox->get_sbuser_session();

$host = $strongbox->base_host();#= preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']);


    if ( file_exists($_SERVER['DOCUMENT_ROOT'] . "/cgi-bin/sblogin/.htcookie/")) {
	$sessionfiles = $_SERVER['DOCUMENT_ROOT'] . "/cgi-bin/sblogin/.htcookie/";
    } else if ( file_exists($_SERVER['DOCUMENT_ROOT'] . "/../cgi-bin/sblogin/.htcookie/") ) {
	$sessionfiles = $_SERVER['DOCUMENT_ROOT'] . "/../cgi-bin/sblogin/.htcookie/";
    } else {
        die("cannot find sessionfiles dir");
    }

if ($handle = opendir($sessionfiles)) {

    echo "<table><tr><th>Username</th><th colspan=2>Session ID <small><a href=\"http://www.bettercgi.com/cgi-bin/wiki/wiki.pl/Newtons\" title=\"Learn more...\" class=\"help\">?</small></th><th>IP</th><th>Date/Time</th></tr>";
    $sessions=0;
    while (false !== ($entry = readdir($handle))) {
	if(is_dir("$sessionfiles/$entry") && preg_match("/^(sb[0-9a-z]*)\.$host/",$entry) ) {
		$sessions++;
		$ips = glob("$sessionfiles/$entry/*.*.*.*");
		$ip = basename($ips[0]);
		$session = preg_replace("/^(sb[0-9a-z]*)\.$host/",'\\1',$entry);
		$user = $strongbox->lookup_sbuser($session);
		
		if(function_exists("date_default_timezone_set")) {
			date_default_timezone_set('UTC');
		}
		#if(function_exists("date_default_timezone_set") and function_exists("date_default_timezone_get"))
		#	@date_default_timezone_set(@date_default_timezone_get());
		$age   = @date ("r",filemtime( "$sessionfiles/$entry" ) );
		$epoch = @date ("U",filemtime( "$sessionfiles/$entry" ) );
        	echo "	<tr>
				<td><a href=\"/cgi-bin/sblogin/report/byuser.cgi?user=$user\" title=\"Click to see user details\">$user</a></td>
				<td>$session</td>
				<td><small><a href=\"/sblogin/report/sbsession_kill.php?user=$session\">kill session</a></small></td>
				<td><a href=\"/cgi-bin/sblogin/report/byip.cgi?ip=$ip\">$ip</a></td>
				<td>	<span id=\"date-$epoch-$sessions\" title=\"$age\">$age</span>
					<script type=\"text/javascript\">convert_to_local(document.getElementById(\"date-$epoch-$sessions\"),$epoch); </script></td>
			</tr>\n";
	}
    }
    echo "</table>";

    closedir($handle);
}

?>
<br>
<a href="/sblogin/report/">Back to Main Page</a>
<?php include_once("bottom.php"); ?>
