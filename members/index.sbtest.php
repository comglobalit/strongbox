<html>
<body>
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
<li><b>session id:</b> ' . $strongbox->get_sbsession() . ' (Newton, <a href="https://github.com/comglobalit/strongbox/wiki/Strongbox-Newtons:-in-URL-session-IDs-and-wildcard-domain">Learn more</a>)</li>
<li><a href="/sblogin/report/">Strongbox Admin Area</a></li>
<li><a href="https://github.com/comglobalit/strongbox/wiki">Strongbox Online Documentation</a></li>
<li><a href="logout.php">Logout</a></li>
</ul>';
}
?>
</body>
</html>
