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
#   2018_02_06 JDuplessis
#       V 1.1 Add Default Start/End Date for Adhoc graph 
#   2018_05_06 JDuplessis
#       V 1.2 Remove unnecessary variable
#@2019_01_17 Change: v1.3 Date Input now use HTML 5 Format 
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
$SVER  = "1.3" ;                                                        # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$URL_VIEW_RCH  = '/view/rch/sadm_view_rchfile.php';                     # View RCH File Content URL

#display_std_heading("NotHome","Performance","","",$SVER);           # Display Content Heading
echo "<H2>Performance Graph for Unix servers</H2><br>\n" ; 
?>


<script type="text/javascript">
  function checkForm(form)
  {
    var sdate = document.forms["gph_adoc"]["sdate"].value;
    var edate = document.forms["gph_adoc"]["edate"].value;
    // #document.write(sdate);
    if (sdate > edate) {
        alert ("Start date is greater than end date ?");
        return false;
    }
    return true;
  }
</script>


<?php
# ==================================================================================================
# FIRST OPTION - DISPLAY SAME GRAPH FOR THE GROUP OF SERVER SELECTED
# ==================================================================================================
?>
    <form action='/view/perf/sadm_server_perf_adhoc_all.php' method='POST'>
    <?php print "<strong>Option for a group of servers</strong> <br><br>"; ?>

    <?php print "Display "; ?>
    <select name='wtype'>
        <option value="cpu">CPU usage</option>
        <option value="runqueue">Run Queue</option>
        <option value="memory">Memory usage</option>
        <option value="diskio">Disk I/O</option>
        <option value="page_inout">Paging Activity</option>
        <option value="swap_space">Swap Space usage</option>
        <option value="neta">Network 1st interface</option>
        <option value="netb">Network 2nd interface</option>
        <option value="netc">Network 3rd interface</option>
        <option value="netd">Network 4th interface</option>
        <option value="memdist">Aix Memory Distribution</option>
    </select>
    
    <?php print " of "; ?>
    <select  name='wperiod'>
        <option value="yesterday">Yesterday</option>
        <option value="last2days">Last 2 Days</option>
        <option value="week">Last 7 days</option>
        <option value="month">Last 31 days</option>
        <option value="year">Last 365 days</option>
        <option value="last2years">Last 2 years</option>
    </select>

    <?php echo "  for "; ?>
    <select name='wservers'>
        <option value="all_servers">All servers</option>
        <option value="all_linux">All Linux servers</option>
        <option value="all_aix">All Aix servers</option>
    </select>

    <?php echo "  having category "; ?>
    <select name='wcat'>
        <option value="all_cat">All Categories</option>
<?php
        $sql = "SELECT * FROM server_category ";                            # Construct SQL Statement
        if ($result = mysqli_query($con,$sql)) {                            # If Results to Display
            while ($row = mysqli_fetch_assoc($result)) {                    # Gather Result from Query
                echo "<option value=" . $row['cat_code'] . ">" ;
                echo $row['cat_code'] ." - ". $row['cat_desc'] ."</option>"; 
            }
        }
        echo "\n</select>";  

    echo "<input type='submit' value='Generate graph' />";
    echo "<br><br>";
?>

</form>
<hr><br>




<!-- ===============================================================================================
				Second Option - Display AdHoc Graph for selected time period 
================================================================================================= -->
<form name=gph_adoc action='/view/perf/sadm_server_perf_adhoc.php' onsubmit="return checkForm();" method='POST'>


<!-- Accept the server name ==================================================================== -->
<?php
    # Accept the server name from list of server ---------------------------------------------------
    echo "<strong>Option for one server</strong> <BR><BR>";
    echo "Display graphics for server ";
    echo "<select name='server_name'>\n";
    $sql = "SELECT * FROM `server` where srv_active='1' and srv_graph='1' order by srv_name";
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

    # Accept the starting date =====================================================================
    $SDMIN = mktime(0, 0, 0, date("m"), date("d"), date("Y")-2);        # Today -2 Years (EpochTime)
    $SDMIN = date ("Y-m-d",$SDMIN);                                     # Start MinDate Epoch to YMD
    $SDMAX = mktime(0, 0, 0, date("m"), date("d")-1, date("Y"));        # Yesterday in EpochTime
    $SDMAX = date ("Y-m-d",$SDMAX);                                     # Maximum Ending Date 
    $YESTERDAY2 = mktime(0, 0, 0, date("m"), date("d")-2,   date("Y")); # Yesterday in Epoch Time
    $YESTERDAY2 = date ("Y-m-d",$YESTERDAY2);                           # Max Date Epoch to Y-M-D
    if ($DEBUG) { echo "\nStart Date Min: $SDMIN - Date Max: $SDMAX - Default: $YESTERDAY2" ; } 
    echo "<input type='date' name='sdate' value='$YESTERDAY2' required min='$SDMIN' max='$SDMAX'/>";

    # Accept the ending date =======================================================================
    echo " to " ; 
    $EDMIN = mktime(0, 0, 0, date("m"), date("d"), date("Y")-2);        # Today -2 Years (EpochTime)
    $EDMIN = date ("Y-m-d",$EDMIN);                                     # Minimum Starting Date
    $EDMAX = mktime(0, 0, 0, date("m"), date("d"), date("Y"));          # Today in EpochTime
    $EDMAX = date ("Y-m-d",$EDMAX);                                     # Maximum Ending Date YMD
    $YESTERDAY  = mktime(0, 0, 0, date("m"), date("d")-1, date("Y"));     # Return Yesterday EpochTime 
    $YESTERDAY  = date ("Y-m-d",$YESTERDAY);                            # Yesterday Date YYYY-MM_DD    
    if ($DEBUG) { echo "\nEnd Date Min: $EDMIN - Date Max: $EDMAX - Default: $YESTERDAY" ; } 
    echo "<input type='date' name='edate' value='$YESTERDAY' required min='$EDMIN' max='$EDMAX' />";

    # Accept the starting time =====================================================================
    echo " between " ; 
    ?>
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
        <option value="23:30">23:59</option>
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
    </select>


<!-- Submit button ============================================================================= -->
<?php
    echo "\n<input type='submit' value='Generate graph' />";
    echo "\n<br><br>";
    echo "\n</form>";
    echo "\n<hr><br>";

    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>