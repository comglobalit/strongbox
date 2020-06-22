<?php

/*** Customize this page by adding colors,  headers, and footers in customization.php ***/

$framed = (empty($_REQUEST['framed']) ? false : true);

include('customization.php');

?>
<!DOCTYPE html>
<html>
<head>
    <title>Welcome!</title>
    <script type="text/javascript" src="/sblogin/jquery-1.7.1.min.js"></script>
    <script type="text/javascript" src="/sblogin/formfiller.js"></script>
    <script type="text/javascript" src="/sblogin/cookies.js"></script>
    <script type="text/javascript" src="/sblogin/login.js"></script>


    <link rel="stylesheet" href="/sblogin/strongbox.css" type="text/css" media="screen and (min-device-width: 650px)" />
    <link rel="stylesheet" href="/sblogin/handheld.css"  type="text/css" media="only screen and (max-device-width: 649px)" />
    <link rel="stylesheet" href="/sblogin/handheld.css"  type="text/css" media="handheld" />
    <!--[if IE]>
        <link rel="stylesheet" href="/sblogin/strongbox.css" media="screen" type="text/css" />
    <![endif]-->
    <!-- tell iPhone not to shrink mobile website -->
    <meta name="viewport" content="width=320, initial-scale=1.0, maximum-scale=1.0, user-scalable=0;" />

    <style type="text/css">
        <?php echo $css ?>
    </style>

    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
    <meta HTTP-EQUIV="Pragma" CONTENT="no-cache" >
    <meta http-equiv="expires" content="0" >
    <meta http-equiv="cache-control" content="no-cache" >
    <meta http-equiv="refresh" content="600" > 
</head>

<body>

<?php if (! empty($header) ) {
    if (is_readable( $header) ) {
        include($header);
    } else {
        echo $header;
    }
} ?>

<center>


<?php if (! empty($logoimage) ) {
    echo "<img src='$logoimage' id='logoimage'>";
} ?>

<br>

<?php if (! empty($welcometext) ) { 
    if ( is_readable($welcometext) ) {
        include($welcometext);
    } else {
        echo $welcometext;
    }
} ?>


  <form action="/cgi-bin/sblogin/login.cgi" method="POST" name="login" id="login" target="_top">
  <input type="hidden" name="goodpage" value="<?php echo htmlspecialchars(isset($_SERVER['PATH_INFO']) ? $_SERVER['PATH_INFO'] . '?' . $_SERVER['QUERY_STRING'] : '' ) ?>" >
  <input type="hidden" name="referer" value="<?php echo htmlspecialchars(isset($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : '') ?>" >

  <div id="divCapsLock" style="display: none;">
      Your CAPS LOCK may be on.<br />
      Passwords must be entered with the correct UPPER and lower case.
  </div>

  <!--
  <p id="testcookies" name="testcookies">
      You MUST <a href="enablecookies.html">enable cookies</a> to login to this site now!
  </p>
  -->

      <B>Username: <input type="text" name="uname" id="uname" size="12"></B><br />
      <B>&nbsp;Password: <input type="password" name="pword" id="pword" size="12"><br />

<?php
if(function_exists("virtual")) {
        // works only when php is an apache module
        virtual("/cgi-bin/sblogin/turingpi.cgi");
        echo "<!-- used virtual -->";
} elseif (function_exists("curl_init")) {
        // needs curls, is not always available
        $curl = curl_init();
	// Force cURL connection through a specific IP
        // curl_setopt ($curl, CURLOPT_PROXY, "x.x.x.x:80");
        curl_setopt ($curl, CURLOPT_URL, "http://" . $_SERVER['HTTP_HOST'] . "/cgi-bin/sblogin/turingpi.cgi");
        curl_setopt($curl, CURLOPT_HTTPHEADER, array("X-Forwarded-For: " . $_SERVER['REMOTE_ADDR']));
        curl_exec ($curl);
        curl_close ($curl);
        echo "<!-- used curl -->";
} else {
        // does not work if allow_url_fopen is not enabled
	// please do NOT enable this fuction unless you know
	// what are you doing, or know PHP's security risks
        //echo file_get_contents("http://" . $_SERVER['HTTP_HOST'] . "/cgi-bin/sblogin/turingpi.cgi");
	echo "Please install PHP cURL Library, or use Text Captcha";
}
?><br />

     <b>Save my password:</b> <input name="savepassword" type=checkbox CHECKED><br />
      <input type="submit" name="submit1" id="submit1" class="submit1" value="Log In">
</form>

<br><br>
<?php if ($framed === false ) {  ?>
<p>
 IP address and access time recorded for security purposes.<br>
 Unauthorized access attempts will be emailed to your service
 provider for immediate suspension and cancellation.
</p>
<br><br>
<?php } ?>

<?php if (! empty($footer) ) {
    if ( is_readable($footer) ) {
        include($footer);
    } else {
        echo $footer;
    }
} ?>

</center>

<?php if ($framed === false) {  ?>
<br /><br />
<small>Protected by <a target="_new" href="https://www.comglobalit.com/en/strongbox/?utm_source=strongbox&utm_medium=sblogin&utm_campaign=strongbox&utm_content=login">Strongbox</a></small>
<?php } ?>

<!--
Use the this 1X1 pixel version of the Turing image if you remove 
the visible one from the page.  Calling the Turing image is necesary
even if it's not visible.
<img src="/cgi-bin/sblogin/turingimage.cgi" height="1" width="1" name="turingimage" id="turingimage"><br>
-->

</body>

</html>


