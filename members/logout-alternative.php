<?php
#error_reporting(E_ALL);
#ini_set('display_errors', '1');
require_once('../sblogin/strongbox.class.php');

if ( empty($strongbox) ) { $strongbox = new strongbox; }
$_SERVER['REMOTE_USER'] = $strongbox->get_sbuser_session();

$killme = $strongbox->sbsession_kill($_SERVER['REMOTE_USER']);
session_destroy();

header( 'Location: http://www.famousdick.com/tour/' );
?>
