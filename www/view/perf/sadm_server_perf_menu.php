<?php
# ================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_perf_menu.php
#   Version  :  1.0
#   Date     :  23 January 2018
#   Requires :  php
#   Synopsis :  Present Options to Generate Performance Graphics for Server(s)#   
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
#   2018_01_23 JDuplessis
#       V 1.0 Initial Version
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # </head>Heading & SideBar


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "1.0" ;                                                        # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$URL_VIEW_RCH  = '/view/rch/sadm_view_rchfile.php';                     # View RCH File Content URL
$URL_VIEW_LOG  = '/view/log/sadm_view_logfile.php';                     # View LOG File Content URL

#display_std_heading("NotHome","Performance","","",$SVER);           # Display Content Heading
echo "<H2>Performance Graph for Unix servers</H2><br>\n" ; 


# ==================================================================================================
#				First Option - Display Same graph for all group of server selected
# ==================================================================================================

?>
<form action='/view/perf/sadm_server_perf_adhoc_all.php' method='POST'>
<?php print "<strong>Option for a group of servers</strong> <br><br>Display "; ?>
<select name='wtype'>
  <option value="cpu">CPU usage</option>
  <option value="runqueue">Run Queue</option>
  <option value="diskio">Disk I/O</option>
  <option value="memory">Memory usage</option>
  <option value="paging_activity">Paging Activity</option>
  <option value="paging_space_usage">Paging space usage</option>
  <option value="network_eth0">Network first interface</option>
  <option value="network_eth1">Network second interface</option>
  <option value="network_eth2">Network third interface</option>
</select>
<?php print " of "; ?>
<select  name='wperiod'>
  <option value="day">Yesterday</option>
  <option value="week">Last 7 days</option>
  <option value="month">Last 30 days</option>
  <option value="year">Last 365 days</option>
</select>
<?php echo "  for "; ?>
<select name='wservers'>
  <option value="all_servers">All servers</option>
  <option value="all_linux">All Linux servers</option>
  <option value="all_aix">All Aix servers</option>
  <option value="all_linux_prod">All Linux Production servers</option>
  <option value="all_aix_prod">All Aix Production servers</option>
  <option value="all_linux_dev">All Linux Development servers</option>
  <option value="all_aix_dev">All Aix Development servers</option>
</select>
<?php
  echo "<input type='submit' value='Generate graph' />";
  echo "<br><br>";
?>
</form>
<hr><br>




<!-- ===============================================================================================
				Second Option - Display AdHoc Graph for selected time period 
================================================================================================= -->
<form name=gph_adoc action='/view/perf/sadm_server_perf_adhoc.php' method='POST'>


<!-- Accept the server name ==================================================================== -->
<?php
    echo "<strong>Option for one server</strong> <BR><BR>";
    echo "Display graphics for server ";
    echo "<select name='server_name'>\n";
    $sql = "SELECT * FROM `server` where srv_active='1' order by srv_name";
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceeding line
        $err_msg1 = "Server (" . $wkey . ") not found.\n";              # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        exit;                                                           # Exit - Should not occurs
    }
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        echo "<option value=$row[srv_name]>$row[srv_name]</option>\n";
    }
  echo "</select>\n";
  echo " from date ";
?>

<!-- Accept the starting date ================================================================== -->
    <input type="text" name="sdate" size="10" />
    <script language="JavaScript">
    	new tcal ({ 
    		'formname': 'gph_adoc',
    		'controlname': 'sdate'
    	});
    </script>


<!-- Accept the ending date ==================================================================== -->
    <?php echo " to " ; ?>
    <input type="text" name="edate" size="10" />
    <script language="JavaScript">
        new tcal ({ 
            'formname': 'gph_adoc',
            'controlname': 'edate'
        });
    </script>

<!-- Accept the starting time ================================================================== -->
    <?php echo " between " ; ?>
    <select name=stime >
        <option value="00:00">00:00</option>
        <option value="00:30">00:30</option>
        <option value="01:00">01:00</option>
        <option value="01:30">01:30</option>
        <option value="02:00">02:00</option>
        <option value="02:30">02:30</option>
        <option value="03:00">03:00</option>
        <option value="03:30">03:30</option>
        <option value="04:00">04:00</option>
        <option value="04:30">04:30</option>
        <option value="05:00">05:00</option>
        <option value="05:30">05:30</option>
        <option value="06:00">06:00</option>
        <option value="06:30">06:30</option>
        <option value="07:00">07:00</option>
        <option value="07:30">07:30</option>
        <option value="08:00">08:00</option>
        <option value="08:30">08:30</option>
        <option value="09:00">09:00</option>
        <option value="09:30">09:30</option>
        <option value="10:00">10:00</option>
        <option value="10:30">10:30</option>
        <option value="11:00">11:00</option>
        <option value="11:30">11:30</option>
        <option value="12:00">12:00</option>
        <option value="12:30">12:30</option>
        <option value="13:00">13:00</option>
        <option value="13:30">13:30</option>
        <option value="14:00">14:00</option>
        <option value="14:30">14:30</option>
        <option value="15:00">15:00</option>
        <option value="15:30">15:30</option>
        <option value="16:00">16:00</option>
        <option value="16:30">16:30</option>
        <option value="17:00">17:00</option>
        <option value="17:30">17:30</option>
        <option value="18:00">18:00</option>
        <option value="18:30">18:30</option>
        <option value="19:00">19:00</option>
        <option value="19:30">19:30</option>
        <option value="20:00">20:00</option>
        <option value="20:30">20:30</option>
        <option value="21:00">21:00</option>
        <option value="21:30">21:30</option>
        <option value="22:00">22:00</option>
        <option value="22:30">22:30</option>
        <option value="23:00">23:00</option>
        <option value="23:30">23:30</option>
    </select>

<!-- Accept the ending time ================================================================== -->
    <?php echo " and " ; ?>
    <select name=etime >
        <option value="00:00">00:00</option>
        <option value="00:30">00:30</option>
        <option value="01:00">01:00</option>
        <option value="01:30">01:30</option>
        <option value="02:00">02:00</option>
        <option value="02:30">02:30</option>
        <option value="03:00">03:00</option>
        <option value="03:30">03:30</option>
        <option value="04:00">04:00</option>
        <option value="04:30">04:30</option>
        <option value="05:00">05:00</option>
        <option value="05:30">05:30</option>
        <option value="06:00">06:00</option>
        <option value="06:30">06:30</option>
        <option value="07:00">07:00</option>
        <option value="07:30">07:30</option>
        <option value="08:00">08:00</option>
        <option value="08:30">08:30</option>
        <option value="09:00">09:00</option>
        <option value="09:30">09:30</option>
        <option value="10:00">10:00</option>
        <option value="10:30">10:30</option>
        <option value="11:00">11:00</option>
        <option value="11:30">11:30</option>
        <option value="12:00">12:00</option>
        <option value="12:30">12:30</option>
        <option value="13:00">13:00</option>
        <option value="13:30">13:30</option>
        <option value="14:00">14:00</option>
        <option value="14:30">14:30</option>
        <option value="15:00">15:00</option>
        <option value="15:30">15:30</option>
        <option value="16:00">16:00</option>
        <option value="16:30">16:30</option>
        <option value="17:00">17:00</option>
        <option value="17:30">17:30</option>
        <option value="18:00">18:00</option>
        <option value="18:30">18:30</option>
        <option value="19:00">19:00</option>
        <option value="19:30">19:30</option>
        <option value="20:00">20:00</option>
        <option value="20:30">20:30</option>
        <option value="21:00">21:00</option>
        <option value="21:30">21:30</option>
        <option value="22:00">22:00</option>
        <option value="22:30">22:30</option>
        <option value="23:00">23:00</option>
        <option value="23:30">23:30</option>
    </select>


<!-- Submit button ============================================================================= -->
    <?php
    echo '<input type="submit" value="Generate graph" />';
    echo "<br><br>";
    ?>
    </form>
    <hr><br>

<?php 

    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>