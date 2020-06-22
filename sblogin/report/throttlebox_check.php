<?php
if ( is_dir($_SERVER['DOCUMENT_ROOT'] . "/throttlebox/admin/")) {
	header("Location: /throttlebox/admin/");
} else {
	print '<a href="https://www.bettercgi.com/throttlebox/?utm_source=sbcustomer&utm_medium=sb5admin_img&utm_campaign=SB_admin_TB_link"><img src="http://bettercgi.com/images/clonebox_buynow.jpg" alt=""></a><br>You don\'t have Throttlebox installed, please visit <a href="https://www.bettercgi.com/throttlebox/?utm_source=sbcustomer&utm_medium=sb5admin_link&utm_campaign=SB_admin_TB_link">https://www.bettercgi.com/throttlebox/</a>';
}


?>
