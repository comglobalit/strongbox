<?php
/*** Customize the log in and decline pages by adding colors,  headers, and footers here ***/

if (! $framed) { 
    $logoimage   = '/sblogin/secured.png';
}

$css = <<<CSS
    body   { background-color: white; color: black; }
    form   { background-color: #B0B0D0; color: black; }
    a:link { color:blue; }
    #submit1 { background-color: #568294; color: white; }

CSS;

# These can be filled in with either text or file names.
// $welcometext = '<h2>Welcome to ' . $_SERVER['SERVER_NAME'];
$welcometext = '';
$header      = '';

if (! $framed) { 
    $footer      = '[ <a href="/">Home</a> ]';
}
?>
