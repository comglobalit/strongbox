<?php

$framed = (empty($_REQUEST['framed']) ? false : true);
/* Customize this page by adding colors,  headers, and footers in customization.php */
include('./customization.php');

?>


<html>
<head>
	<title>Bad login</title>
        <script type="text/javascript">
            var showlogin = 1;
            function blockback() {
                if (showlogin == 1) {
                    location.replace(document.referrer);
                }
            }
        </script>

    <style type="text/css">
        <?php echo $css ?>
    </style>

</head>
<body onUnLoad="blockback()">
<?php if (! empty($header) ) {
    if (is_readable( $header) ) {
        include($header);
    } else {
        echo $header;
    }
} ?>


<center>

<?php if (! $framed) {  ?>
<br />
    <?php if (! empty($logoimage) ) { 
       echo "<img src='$logoimage' id='logoimage'>";
   }
} 
?>

<br><br>
<h3>Invalid login credentials provided.</h3>
You may have just made a typing error, so please double-check the <br />
spelling of your username and password, including upper/lower case.<br />
If necessary, please try copying and pasting your username and password from <br />
the email you received when joining the site into the fields on the login form.<br /><br />

Click <a href="javascript:location.replace(document.referrer)" onClick="showlogin=0; return true;"><strong>here</strong></a> to try again.<br><br>
If you are unable to access, contact 
<a href="#cust_service_link#" onClick="showlogin=0; return true;">customer support</a>.<br /><br />

<p style="font-size:<?php echo htmlspecialchars(isset($_SERVER['QUERY_STRING']) ? $_SERVER['QUERY_STRING'] : 1 ) ?>em;" id="dontkeeptrying">
Do not keep trying over and over, our <a target="_new" href="http://www.bettercgi.com/strongbox/" onClick="showlogin=0; return true;">Strongbox</a>&trade; security system,<br />
which prevents password abuse, may block you.
</p>

<?php if (! $framed) {  ?>
    <br />
    <p id="warningtext">
    If you are <u><i><b>NOT</b> </i></u>an authorized user, <br />
    be aware that your IP address and the time have been recorded.<br />
    Repeated attempts to gain unauthorized access will be provided to your ISP<br />
    or other service provider and to the appropriate law enforcement agencies.
    </p>
    <br><br><br>
    
    
    <br />
    <?php if (! empty($footer) ) {
        if ( is_readable($footer) ) {
            include($footer);
        } else {
            echo $footer;
        }
    } 
} ?>

</center>
</body>
</html>
