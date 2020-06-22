#!/usr/bin/perl


# Date: 2006-03-17

# Copyright Ray Morris 2005
# All rights reserved.

print qq|Content-type: text/html

	<html>
	<body onLoad="document.contform.submit()">
		<a id="continuelink" href="http:/$ENV{'PATH_INFO'}?$ENV{'QUERY_STRING'}">Continue</a>
                <form name="contform" id="contform" method="GET" action="http:/$ENV{'PATH_INFO'}?$ENV{'QUERY_STRING'}">
                </form>
	</body>
	</html>

|;


