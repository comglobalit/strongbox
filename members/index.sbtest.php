<html>
<body>
<div id="fb-root"></div>
<script>(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/all.js#xfbml=1";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));</script>
<a href="http://www.bettercgi.com/"><img src="http://www.bettercgi.com/images/bettercgi_logo.jpg" alt="BetterCGI"></a>
<h1>Sample Index page for your members directory</h1>
<h2><?php echo $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']?></h2>
<?php

require_once( $_SERVER['DOCUMENT_ROOT'] .  '/sblogin/strongbox.class.php');
if ( empty($strongbox) ) { $strongbox = new strongbox; }


$session = $_SERVER['HTTP_HOST'] ?>
<a href="/">Main Page</a>
<br>
<?php
if (isset($_SERVER['REMOTE_USER'])) {
  echo "<ul><li><b>User:</b> " . $_SERVER['REMOTE_USER'] . '</li>
<li><b>session id:</b> ' . $strongbox->get_sbsession() . ' (Newton, <a href="https://www.bettercgi.com/cgi-bin/wiki/wiki.pl/Newtons">Learn more</a>)</li>
<li><a href="/sblogin/report/">Strongbox Admin Area</a></li>
<li><a href="https://www.bettercgi.com/cgi-bin/wiki/wiki.pl">Strongbox Online Documentation</a></li>
<li><a href="logout.php">Logout</a></li>
</ul>';
}
?>
Keep posted, follow us on Facebook:
<div class="fb-like" data-href="https://www.facebook.com/BetterCGI" data-send="true" data-width="450" data-show-faces="false" data-action="recommend"></div>
</body>
</html>
