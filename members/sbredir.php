<html>

<!--

    This is for linking to feeds that check the referer rather 
then using any security, and require the referer to 

-->

	<?php
		if ($_SERVER{'QUERY_STRING'}) {
			if ( strstr($_SERVER{'QUERY_STRING'}, "=") ) {
				echo "<body onLoad=\"document.contform.submit()\">";
			} else {
				echo "<body>";
			}
		} else {
			echo "<body onLoad=\"document.contform.submit()\">";
		}
	?>
	 <a id="continuelink" href="http:/<?php echo($_SERVER{'PATH_INFO'} . "?" . $_SERVER{'QUERY_STRING'}) ?>">Continue</a>

                <form name="contform" id="contform" method="GET" action="http:/<?php echo($_SERVER{'PATH_INFO'} . "?". $_SERVER{'QUERY_STRING'}) ?>">
		<?php
			foreach ( $_GET as $key=>$val )
    				echo "<input type=\"hidden\" name=\"$key\" value=\"$val\">\n"; 
		?>
                </form>
	</body>
	</html>

