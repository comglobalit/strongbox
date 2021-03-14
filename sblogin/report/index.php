<!DOCTYPE html>
<html>
   <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></meta>

      <title>StrongBox Reports &amp; Admin Interface</title>
      <script type="text/javascript" src="/sblogin/cookies.js"></script>
      <script type="text/javascript" src="/sblogin/report/filldates.js"></script>
      <script type="text/javascript" src="/sblogin/report/showfields.js"></script>
      <link rel="STYLESHEET" type="text/css" href="/sblogin/report.css"></link>                                                                                   


   </head>


   <body onload="filldates()">

      <div name=logout_link id=logout_link>
        <h3><a href="/sblogin/report/logout.php">Logout</a></h3>
      </div>

      <h1>Strongbox Admin Area</h1>

      <div id="manual" class="section">
         <a href="#manual" onclick="showTag('div', 'manual_body'); return false;">Help &amp; FAQs</a>
         <div id="manual_body" style="display: none;">

            <form action="https://github.com/comglobalit/strongbox/search" target="_blank">

              <legend>Top FAQs</legend>
		<ul>
		  <li><a href="https://github.com/comglobalit/strongbox/wiki/Helping-Customers-Who-Have-Trouble-Logging-In" target="_blank">How should I help members with login problems?</a>
		  </li>
                  <li><a href="/sblogin/codes.html" target="_blank">What do the report status codes mean?</a>
                  </li>
                  <li><a href="https://github.com/comglobalit/strongbox/wiki/Strongbox-Notification-Emails" target="_blank">How can I change where notification emails are sent?</a>
                  </li>
                  <li><a href="https://github.com/comglobalit/strongbox/wiki/Strongbox-Admin-Users" target="_blank">How do I update my Admin username/password?</a>
                  </li>
                  <li><a href="https://github.com/comglobalit/strongbox/wiki/Moving-Strongbox-to-a-New-Server" target="_blank">What is required to move my site to a new server?</a>
                  </li>
		</ul>

              <a target="_blank" href="https://github.com/comglobalit/strongbox/wiki/">Online Documentation</a><br />
              <input name="s">
              <input type="submit" value="Search">
            </form>
         </div>
      </div>

      <div id="reports" class="section">
         <a href="#reports" onclick="showTag('div', 'reports_body'); return false;">Reports</a>
         <div id="reports_body" style="display: none;">
           
 
            <form action="../../cgi-bin/sblogin/report/byuser.cgi" method="get">
               <fieldset>
                  <legend>Detail log for user</legend>
                  <label id="byuser_username">
                     username:
                     <input name="user"></input>
                  </label>

                  <input class="submit" type="submit" name="submit" value=
                  "Show Logins"></input>
               </fieldset>
            </form>


            <form action="../../cgi-bin/sblogin/report/byip.cgi" method="get">
               <fieldset>
                  <legend>Detail log for IP address</legend>
                  <label id="byip_ip">
                     IP:
                     <input name="ip"></input>
                  </label>

                  <input class="submit" type="submit" name="submit" value=
                  "Show Logins"></input>
               </fieldset>
            </form>


           <form action="../../cgi-bin/sblogin/report/report.cgi"
            method="get" name="activity_report">
               <fieldset>
                  <legend>Site activity report</legend>
                  <label>
                     Show top
                     <input name="show_top" value="20" size="3" />
                     users/ips/errors
                  </label>


                  <fieldset class="date">
                     <legend>from</legend>
                     <label>
                        <select name="begin_month">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                        </select>month
                     </label>

                     <label>
                        <select name="begin_day">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                           <option value="13">13</option>
                           <option value="14">14</option>
                           <option value="15">15</option>
                           <option value="16">16</option>
                           <option value="17">17</option>
                           <option value="18">18</option>
                           <option value="19">19</option>
                           <option value="20">20</option>
                           <option value="21">21</option>
                           <option value="22">22</option>
                           <option value="23">23</option>
                           <option value="24">24</option>
                           <option value="25">25</option>
                           <option value="26">26</option>
                           <option value="27">27</option>
                           <option value="28">28</option>
                           <option value="29">29</option>
                           <option value="30">30</option>
                           <option value="31">31</option>
                        </select>day
                     </label>

                     <label>
                        <select name="begin_year">
                           <option value="2010">2010</option>
                           <option value="2011">2011</option>
                           <option value="2012">2012</option>
                           <option value="2013">2013</option>
                           <option value="2014">2014</option>
                           <option value="2015">2015</option>
                           <option value="2016">2016</option>
                           <option value="2017">2017</option>
                           <option value="2018">2018</option>
                           <option value="2019">2019</option>
                           <option value="2020">2020</option>
                           <option value="2021">2021</option>
                           <option value="2022">2022</option>
                           <option value="2023">2023</option>
                           <option value="2024">2024</option>
                           <option value="2025">2025</option>
                           <option value="2026">2026</option>
                           <option value="2027">2027</option>
                           <option value="2028">2028</option>
                           <option value="2029">2029</option>
                           <option value="2030">2030</option>

                        </select>year
                     </label>
                  </fieldset>

                  <fieldset class="date">
                     <legend>to</legend>
                     <label>
                        <select name="end_month">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                        </select>month
                     </label>

                     <label>
                        <select name="end_day">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                           <option value="13">13</option>
                           <option value="14">14</option>
                           <option value="15">15</option>
                           <option value="16">16</option>
                           <option value="17">17</option>
                           <option value="18">18</option>
                           <option value="19">19</option>
                           <option value="20">20</option>
                           <option value="21">21</option>
                           <option value="22">22</option>
                           <option value="23">23</option>
                           <option value="24">24</option>
                           <option value="25">25</option>
                           <option value="26">26</option>
                           <option value="27">27</option>
                           <option value="28">28</option>
                           <option value="29">29</option>
                           <option value="30">30</option>
                           <option value="31">31</option>
                        </select>day
                     </label>

                     <label>
                        <select name="end_year">
                           <option value="2011">2011</option>
                           <option value="2012">2012</option>
                           <option value="2013">2013</option>
                           <option value="2014">2014</option>
                           <option value="2015">2015</option>
                           <option value="2016">2016</option>
                           <option value="2017">2017</option>
                           <option value="2018">2018</option>
                           <option value="2019">2019</option>
                           <option value="2020">2020</option>
                           <option value="2021">2021</option>
                           <option value="2022">2022</option>
                           <option value="2023">2023</option>
                           <option value="2024">2024</option>
                           <option value="2025">2025</option>
                           <option value="2026">2026</option>
                           <option value="2027">2027</option>
                           <option value="2028">2028</option>
                           <option value="2029">2029</option>
                           <option value="2030">2030</option>

                        </select>year
                     </label>
                  </fieldset>
                  <label>
                      <input name="goodonly" type="checkbox" value="1" />
                      Successful logins only
                  </label>
                  <input class="submit" type="submit" value="Show Activity" />
               </fieldset>
            </form>


            <form action="../../cgi-bin/sblogin/report/disabled.cgi"
            method="get" name="disabled">
               <fieldset>
                  <legend>Usernames with denied logins</legend>
                  <fieldset id="show_codes">
                     <legend>Show</legend>
                     <label>
                        <input name="show_codes" type="checkbox" value="badpuser" />
                        bad username
                     </label>
                     <label>
                           <input name="show_codes" type="checkbox" value="badpword" />
                           bad password
                     </label>
                     <label>
                        <input name="show_codes" type="checkbox" value="dis_uniq" checked="checked" />
                        disabled (permanent)
                     </label>
                     <label>
                        <input name="show_codes" type="checkbox" value="badchars" />
                        bad characters
                     </label>
                      <label>
                      <input name="show_codes" type="checkbox" value="uniqsubs" checked="checked" />
                           suspended (too many subnets)
                     </label>

                     <label>
                        <input name="show_codes" type="checkbox" value="totllgns" checked="checked" />
                        suspended (too many logins)
                     </label>
                     <label>
                        <input name="show_codes" type="checkbox" value="uniqcnty" checked="checked" />
                        suspended (too many countries)
                     </label>
                     <label>
                        <input name="show_codes" type="checkbox" value="uniqisps" checked="checked" />
                        suspended (too many ISPs)
                     </label>
                     <label>
                        <input name="show_codes" type="checkbox" value="attempts" checked="checked" />
                        IPs suspended (brute force)
                     </label>
	  </fieldset>

                  <fieldset class="date">
                     <legend>Since</legend>
                     <label>
                        <select name="begin_month">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                        </select>month
                     </label>

                     <label>
                        <select name="begin_day">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                           <option value="13">13</option>
                           <option value="14">14</option>
                           <option value="15">15</option>
                           <option value="16">16</option>
                           <option value="17">17</option>
                           <option value="18">18</option>
                           <option value="19">19</option>
                           <option value="20">20</option>
                           <option value="21">21</option>
                           <option value="22">22</option>
                           <option value="23">23</option>
                           <option value="24">24</option>
                           <option value="25">25</option>
                           <option value="26">26</option>
                           <option value="27">27</option>
                           <option value="28">28</option>
                           <option value="29">29</option>
                           <option value="30">30</option>
                           <option value="31">31</option>
                        </select>day
                     </label>

                     <label>
                        <select name="begin_year">
                           <option value="2014">2014</option>
                           <option value="2015">2015</option>
                           <option value="2016">2016</option>
                           <option value="2017">2017</option>
                           <option value="2018">2018</option>
                           <option value="2019">2019</option>
                           <option value="2020">2020</option>
                           <option value="2021">2021</option>
                           <option value="2022">2022</option>
                           <option value="2023">2023</option>
                           <option value="2024">2024</option>
                           <option value="2025">2025</option>
                           <option value="2026">2026</option>
                           <option value="2027">2027</option>
                           <option value="2028">2028</option>
                           <option value="2029">2029</option>
                           <option value="2030">2030</option>

                        </select>year
                     </label>
                  </fieldset>

                  <input class="submit" type="submit" value="Show Usernames" />
               </fieldset>
            </form>

            <form action="../../cgi-bin/sblogin/report/rawlog.cgi"
            method="get" name="raw_log">
               <fieldset>
                  <legend>Raw Log (long report)</legend>
                     <fieldset class="date">
                     <legend>from</legend>
                     <label>
                        <select name="begin_month">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                        </select>month
                     </label>

                     <label>
                        <select name="begin_day">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                           <option value="13">13</option>
                           <option value="14">14</option>
                           <option value="15">15</option>
                           <option value="16">16</option>
                           <option value="17">17</option>
                           <option value="18">18</option>
                           <option value="19">19</option>
                           <option value="20">20</option>
                           <option value="21">21</option>
                           <option value="22">22</option>
                           <option value="23">23</option>
                           <option value="24">24</option>
                           <option value="25">25</option>
                           <option value="26">26</option>
                           <option value="27">27</option>
                           <option value="28">28</option>
                           <option value="29">29</option>
                           <option value="30">30</option>
                           <option value="31">31</option>
                        </select>day
                     </label>

                     <label>
                        <select name="begin_year">
                           <option value="2011">2011</option>
                           <option value="2012">2012</option>
                           <option value="2013">2013</option>
                           <option value="2014">2014</option>
                           <option value="2015">2015</option>
                           <option value="2016">2016</option>
                           <option value="2017">2017</option>
                           <option value="2018">2018</option>
                           <option value="2019">2019</option>
                           <option value="2020">2020</option>
                           <option value="2021">2021</option>
                           <option value="2022">2022</option>
                           <option value="2023">2023</option>
                           <option value="2024">2024</option>
                           <option value="2025">2025</option>
                           <option value="2026">2026</option>
                           <option value="2027">2027</option>
                           <option value="2028">2028</option>
                           <option value="2029">2029</option>
                           <option value="2030">2030</option>

                        </select>year
                     </label>
                  </fieldset>

                  <fieldset class="date">
                     <legend>to</legend>
                     <label>
                        <select name="end_month">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                        </select>month
                     </label>

                     <label>
                        <select name="end_day">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                           <option value="13">13</option>
                           <option value="14">14</option>
                           <option value="15">15</option>
                           <option value="16">16</option>
                           <option value="17">17</option>
                           <option value="18">18</option>
                           <option value="19">19</option>
                           <option value="20">20</option>
                           <option value="21">21</option>
                           <option value="22">22</option>
                           <option value="23">23</option>
                           <option value="24">24</option>
                           <option value="25">25</option>
                           <option value="26">26</option>
                           <option value="27">27</option>
                           <option value="28">28</option>
                           <option value="29">29</option>
                           <option value="30">30</option>
                           <option value="31">31</option>
                        </select>day
                     </label>

                     <label>
                        <select name="end_year">
                           <option value="2011">2011</option>
                           <option value="2012">2012</option>
                           <option value="2013">2013</option>
                           <option value="2014">2014</option>
                           <option value="2015">2015</option>
                           <option value="2016">2016</option>
                           <option value="2017">2017</option>
                           <option value="2018">2018</option>
                           <option value="2019">2019</option>
                           <option value="2020">2020</option>
                           <option value="2021">2021</option>
                           <option value="2022">2022</option>
                           <option value="2023">2023</option>
                           <option value="2024">2024</option>
                           <option value="2025">2025</option>
                           <option value="2026">2026</option>
                           <option value="2027">2027</option>
                           <option value="2028">2028</option>
                           <option value="2029">2029</option>
                           <option value="2030">2030</option>

                        </select>year
                     </label>
                  </fieldset>
                  <label>
                      <input name="goodonly" type="checkbox" value="1" />
                      Successful logins only
                  </label>
                  <input class="submit" type="submit" value="Show Activity" />
               </fieldset>
            </form>


         </div>
      </div>

      <div id="session" class="section">
         <a href="#session" onclick="showTag('div', 'session_body'); return false;">Session Management</a>
         <div id="session_body" style="display: none;">
            <form action="sbsession_list.php" method="GET">
               <fieldset>
                  <legend>List Active Sessions</legend>
                  <input class="submit" type="submit" name="submit" value="List" />
               </fieldset>
            </form>

            <form action="/sblogin/report/sbsession_kill.php" method="post">
               <fieldset>
                  <legend>
                     Kill User's Session
                  </legend>

                  <label>
                     username
                     <input name="user"></input>
                  </label>
                  <input class="submit" type="submit" name="submit" value="Kill Session" />
               </fieldset>
            </form>
         </div>
      </div>

      <div id="usermanage" class="section">
         <a href="#usermanage" onclick=
         "showTag('div', 'usermanage_body'); return false;">
            Member Management
         </a>

         <div id="usermanage_body" style="display: none;">

            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post">
               <fieldset>
                  <legend>List Users</legend>
                  <input type="hidden" name="action" value="list"></input>
                  <input class="submit" type="submit" name="submit" value="List" />
               </fieldset>
            </form>


            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post"
            name="adduser">
               <fieldset>
                  <legend>Add a username
                          <br>(<small>WARNING, modifications not always possible (server permissions) or advisable (users should be managed by your CC processor), local changes may be overwritten </small>)
                  </legend>
                  <label>
                     username:

                     <input name="uname"></input>
                  </label>

                  <label>
                     password:

                     <input name="pword"></input>
                  </label>

                  <fieldset class="date">
                     <legend>expiration date <small>(for password files only, custom SQL integration not always possible)</small></legend>
                     <label>
                        <select name="exp_month">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                        </select>month
                     </label>

                     <label>
                        <select name="exp_day">
                           <option value="01">01</option>
                           <option value="02">02</option>
                           <option value="03">03</option>
                           <option value="04">04</option>
                           <option value="05">05</option>
                           <option value="06">06</option>
                           <option value="07">07</option>
                           <option value="08">08</option>
                           <option value="09">09</option>
                           <option value="10">10</option>
                           <option value="11">11</option>
                           <option value="12">12</option>
                           <option value="13">13</option>
                           <option value="14">14</option>
                           <option value="15">15</option>
                           <option value="16">16</option>
                           <option value="17">17</option>
                           <option value="18">18</option>
                           <option value="19">19</option>
                           <option value="20">20</option>
                           <option value="21">21</option>
                           <option value="22">22</option>
                           <option value="23">23</option>
                           <option value="24">24</option>
                           <option value="25">25</option>
                           <option value="26">26</option>
                           <option value="27">27</option>
                           <option value="28">28</option>
                           <option value="29">29</option>
                           <option value="30">30</option>
                           <option value="31">31</option>
                        </select>day
                     </label>

                     <label>
                        <select name="exp_year">
                           <option value="2018">2018</option>
                           <option value="2019">2019</option>
                           <option value="2020">2020</option>
                           <option value="2021">2021</option>
                           <option value="2022">2022</option>
                           <option value="2023">2023</option>
                           <option value="2024">2024</option>
                           <option value="2025">2025</option>
                           <option value="2026">2026</option>
                           <option value="2027">2027</option>
                           <option value="2028">2028</option>
                           <option value="2029">2029</option>
                           <option value="2030">2030</option>

                        </select>year
                     </label>

		    <label>
			<input type="checkbox" name="neverexpire" checked="checked" />
			Never expire
		    </label>

                  </fieldset>
		    
                  <input type="hidden" name="action" value="add"></input>
                  <input class="submit" type="submit" name="submit" value="Add" />
               </fieldset>
            </form>


            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post">
               <fieldset>
                  <legend>Change a password</legend>
                  <label>
                     username:
                     <input name="uname"></input>
                  </label>

                  <label>
                     new password:

                     <input name="pword"></input>
                  </label>
                  <input type="hidden" name="action" value="changepw"></input>
                  <input class="submit" type="submit" name="submit" value="Change" />
               </fieldset>
            </form>


            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post">
               <fieldset>
                  <legend>
                     Re-enable a suspended user <br>
                     (&amp; change password, if desired)
                  </legend>

                  <label>
                     username:
                     <input name="uname"></input>
                  </label>

                  <label>
                     new password (blank for no change):
                     <input name="pword"></input>
                  </label>
                  <input type="hidden" name="action" value="reenable"></input>
                  <input class="submit" type="submit" name="submit" value="Reenable User" />
               </fieldset>
            </form>


            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post">
               <fieldset>
                  <legend>
                     Suspend an IP
                  </legend>

                  <label>
                     IP:
                     <input name="ip" value="1.2.3.4" onFocus="this.value=''"></input>
                  </label>
                  <input type="hidden" name="action" value="disableip"></input>
                  <input class="submit" type="submit" name="submit" value="Disable IP" />
               </fieldset>
            </form>


            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post">
               <fieldset>
                  <legend>
                     Re-enable a suspended IP range
                  </legend>

                  <label>
                     IP:
                     <input name="ip" value="064.038.194" onFocus="this.value=''"></input>
                  </label>
                  <input type="hidden" name="action" value="reenableip"></input>
                  <input class="submit" type="submit" name="submit" value="Reenable IP" />
               </fieldset>
            </form>



            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post">
               <fieldset>
                  <legend>Remove expired users
                     <br><small>(usually does not work on SQL databases, only password files. Does not affect data on CC processors like CCBill)</small>
                  </legend>
                  <input type="hidden" name="action" value="removeexpired"></input>
                  <input class="submit" type="submit" name="submit" value="Remove" />
               </fieldset>
            </form>

            <form action="../../cgi-bin/sblogin/report/usermanage.cgi" method="post">
               <fieldset>
                  <legend>Delete a user</legend>
                  <label>
                     username:
                     <input name="uname"></input>
                  </label>

                  <small>
                     <strong>Local change. Billing must be cancelled via your processor, they may re-add the user.</strong>
                  </small>
                  <input type="hidden" name="action" value="remove"></input>
                  <input class="submit" type="submit" name="submit" value="Remove" />
               </fieldset>
            </form>
            
         </div>
      </div>

<?php $host = preg_replace ( '/^sb[0-9a-z]*\./' , '', $_SERVER['HTTP_HOST']); ?>
      <p id="copyright">
        <a href="https://github.com/comglobalit/strongbox" target="_blank">Strongbox</a> 
      </p>
  </body>
</html>

