<?php
# External Authentication Script for Strongbox

$wordpress_location = dirname(__FILE__) . "/../";

$uname = isset($argv[1]) ? $argv[1] : '';
$pass  = isset($argv[2]) ? $argv[2] : '';

define('WP_USE_THEMES', false);
require_once( $wordpress_location . "/wp-load.php");

$userdata = get_user_by('login', $uname);

# http://codex.wordpress.org/Function_Reference/wp_check_password
$result = wp_check_password($pass, $userdata->user_pass, $userdata->ID);
if ( $result ) {
    echo "1";
} else {
    echo "0";
}
