<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_schedule.php
#   Version     :  1.5
#   Date        :  18 February 2017
#   Requires    :  secure.php.net, mariadb, DataTables.net
#   Description :  This page allow to view the servers O/S Update schedule and results.
#   
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# February 2017 - Jacques DUplessis
# 2016_02_02 web v1.0 View O/S Update Status - Added options to edit server from that page, 
# 2017_12_12 web v2.0 View O/S Update Status - Adapted for MySQL and various look enhancement
# 2018_05_06 web v2.1 View O/S Update Status - Use Standard view file web page instead of custom 
# 2018_06_06 web v2.2 View O/S Update Status - Correct problem with link to view the update log 
# 2018_07_01 web v2.3 View O/S Update Status - Show Only Linux Server on this page (No Aix)
# 2018_07_09 web v2.4 View O/S Update Status - Last Update time remove seconds & Change layout
# 2018_07_09 web v2.5 View O/S Update Status - Change Layout of line (More Compact)
# 2019_04_04 web v2.6 View O/S Update Status - Show Calculated Next O/S Update Date & upd occurrence
# 2019_04_17 web v2.7 View O/S Update Status - Minor code cleanup and show "Manual, no schedule" 
# 2019_05_04 web v2.8 View O/S Update Status - Added link to view rch file content for each server.
# 2019_07_12 web v2.9 View O/S Update Status - Don't show MacOS and Aix status (Not applicable).
# 2019_09_20 web v2.10 View O/S Update Status - Show History (RCH) content using same uniform way.
# 2019_09_23 web v2.11 View O/S Update Status - When initiating Schedule change from here, 
# 2019_12_29 web v2.12 View O/S Update Status - Bottom titles was different that the heading.
# 2019_12_29 web v2.13 View O/S Update Status - Heading modified and now on two rows.
#@2022_09_12 web v2.14 View O/S Update Status - Will show link to error log if it exist.
#@2022_09_12 web v2.15 View O/S Update Status - Display the first 50 systems instead of 25.
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar

# DataTable Initialization Function
?>
<script>
$(document).ready(function() {
   $('#sadmTable').DataTable( {
    "lengthMenu": [[50, 100, -1], [50, 100, "All"]],
    "paging"    : true
   } );
} );
</script>
<?php
#<script>
#$(document).ready(function() {
#    $('#sadmTable').DataTable( {
#        "lengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
#        "bJQueryUI" : true,
#        "paging"    : true,
#        "ordering"  : true,
#        "info"      : true
#    } );
#} );
#</script>

#===================================================================================================
#                                       Local Variables
#===================================================================================================
$DEBUG         = False ;                                                # Debug Activated True/False
$WVER          = "2.15" ;                                               # Current version number
$URL_CREATE    = '/crud/srv/sadm_server_create.php';                    # Create Page URL
$URL_UPDATE    = '/crud/srv/sadm_server_update.php';                    # Update Page URL
$URL_DELETE    = '/crud/srv/sadm_server_delete.php';                    # Delete Page URL
$URL_MAIN      = '/crud/srv/sadm_server_main.php';                      # Maintenance Main Page URL
$URL_HOME      = '/index.php';                                          # Site Main Page
$URL_SERVER    = '/view/srv/sadm_view_servers.php';                     # View Servers List
$URL_OSUPDATE  = '/crud/srv/sadm_server_osupdate.php';                  # Update Page URL
$URL_VIEW_FILE = '/view/log/sadm_view_file.php';                        # View File Content URL
$URL_VIEW_RCH  = '/view/rch/sadm_view_rchfile.php';                     # View RCH File Content URL
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$URL_VIEW_SCHED= '/view/sys/sadm_view_schedule.php';                    # View O/S Update Schedule
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$UPDATE_SCRIPT = "sadm_osupdate.sh";                                    # O/S Update Script Name


#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function setup_table() {

    # Table creation
    #echo "<div id='SimpleTable'>"; 
    echo '<table id="sadmTable" class="display compact stripe" width="90%">';   

    # Table Heading
    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th>System</th>\n";
    echo "<th class='text-center' colspan='5'>&nbsp;</th>\n";
    echo "<th class='text-center'>Update</th>\n";
    echo "<th class='text-center'>Log</th>\n";
    echo "<th class='text-center'>Schedule</th>\n";
    echo "<th class='text-center'>Reboot</th>\n";
    echo "</tr>\n"; 
    echo "<tr>\n";
    echo "<th>Name</th>\n";
    echo "<th class='dt-head-center'>O/S</th>\n";                       # Center Header Only
    echo "<th class='dt-head-center'>Version</th>\n";                   # Center Header Only
    echo "<th class='text-center'>Last Update</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>Next Update</th>\n";
    echo "<th class='text-center'>Occurrence</th>\n";
    echo "<th class='text-center'>History</th>\n";
    echo "<th class='text-center'>Active</th>\n";
    echo "<th class='text-center'>After Update</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th>System</th>\n";
    echo "<th class='text-center' colspan='5'>&nbsp;</th>\n";
    echo "<th class='text-center'>Update</th>\n";
    echo "<th class='text-center'>Log</th>\n";
    echo "<th class='text-center'>Schedule</th>\n";
    echo "<th class='text-center'>Reboot</th>\n";
    echo "</tr>\n"; 
    echo "<tr>\n";
    echo "<th>Name</th>\n";
    echo "<th class='dt-head-center'>O/S</th>\n";                       # Center Header Only
    echo "<th class='dt-head-center'>Version</th>\n";                   # Center Header Only
    echo "<th class='text-center'>Last Update</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>Next Update</th>\n";
    echo "<th class='text-center'>Occurrence</th>\n";
    echo "<th class='text-center'>History</th>\n";
    echo "<th class='text-center'>Active</th>\n";
    echo "<th class='text-center'>After Update</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";
 
    echo "<tbody>\n";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    global $URL_HOST_INFO, $URL_VIEW_FILE, $URL_VIEW_RCH, $URL_OSUPDATE, $URL_VIEW_SCHED; 
    
    echo "<tr>\n";  
    
    # Server Name
    $WOS  = $row['srv_osname'];
    $WVER = $row['srv_osversion'];
    echo "<td class='dt-center'>";
    echo "<a href='" . $URL_OSUPDATE . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_SCHED ;
    echo "' title='$WOS $WVER server, ip address is " .$row['srv_ip']. " ,Click to edit Schedule'>";
    echo $row['srv_name']  . "</a></td>\n";

    # Display Operating System Logo
    $WOS   = sadm_clean_data($row['srv_osname']);
    sadm_show_logo($WOS);                                  
    
    # Display O/S Version
    echo "\n<td class='dt-center'>" . $row['srv_osversion'] . "</td>";

    # Server Category
    #echo "<td class='dt-center'>" . nl2br( $row['srv_cat']) . "</td>\n";  

    # Last O/S Update Date 
    echo "<td class='dt-center'>" ;
    if (substr($row['srv_date_osupdate'],0,16) == "0000-00-00 00:00") {
        echo "None Yet";  
    }else{
        echo substr($row['srv_date_osupdate'],0,16) ;
    }
    echo "</td>\n";  
        
    # Last Update Status
    echo "<td class='dt-center'>";
    switch ( strtoupper($row['srv_update_status']) ) {
        case 'S'  : echo "Success"  ; break ;
        case 'F'  : echo "Failed"   ; break ;
        case 'R'  : echo "Running"  ; break ;
        default   : echo "None yet" ; break ;
    }
    echo "</td>\n";  

    # Next Update Date
    echo "<td class='dt-center'>";
    if ($row['srv_update_auto']   == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_update_dom'], $row['srv_update_month'],
            $row['srv_update_dow'], $row['srv_update_hour'], $row['srv_update_minute']);
        echo $UPD_DATE_TIME ;
    }else{
        echo "<B><I>Manual, no schedule</I></B>";
    }
    echo "</td>\n";  

    # O/S Update Occurrence
    echo "<td class='dt-center'>";
    if ($row['srv_update_auto']   == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_update_dom'], $row['srv_update_month'],
        $row['srv_update_dow'], $row['srv_update_hour'], $row['srv_update_minute']);
        echo $STR_SCHEDULE ;
    }else{
        echo "<B><I>Manual, no schedule</I></B>";
    }
    echo "</td>\n";  

    # Display link to view o/s update log file (If exist)
    echo "<td class='dt-center'>";
    $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . $row['srv_name'] . "_sadm_osupdate.log";
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View Update Log'>[log]</a>&nbsp;";
    }else{
        echo "&nbsp;";
    }

    # Display link to view o/s update error log file (If exist)
    #echo "<td class='dt-center'>";
    $ELOGFILE = trim("${cserver}_${UPDATE_SCRIPT}_e.log");              # Add _e.log to Script Name
    $elog_name = SADM_WWW_DAT_DIR . "/" . $cserver . "/log/" . $ELOGFILE ;
#    $elog_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . $row['srv_name'] . "_sadm_osupdate_e.log";
    if ((file_exists($elog_name)) and (file_exists($elog_name)) and (filesize($elog_name) != 0)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $elog_name . "'" ;
        echo " title='View Error Log'>[elog]</a>&nbsp;";
    }else{
        echo "&nbsp;";
    }

    # Display link to view o/s update rch file (If exist)
    $rch_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . $row['srv_name'] . "_sadm_osupdate.rch";
    $rch_www_name  = $row['srv_name'] . "_sadm_osupdate.rch";
    if (file_exists($rch_name))  {
        echo "<a href='" . $URL_VIEW_RCH . "?host=" . $row['srv_name'] . "&filename=" . $rch_www_name . "'" ;
        echo " title='View Update rch file'>[rch]</a>";
    }else{
        echo "&nbsp;";
    }
    echo "</td>\n";  

    # Automatic Update (Yes/No)
    if ($row['srv_update_auto']   == True ) { 
        echo "<td class='dt-center'>Yes</td>\n"; 
    }else{ 
        echo "<td class='dt-center'><B><I>Manual update</I></B></td>\n";
    }

    # Reboot after Update (Yes/No)
    if ($row['srv_update_reboot']   == True ) { 
        echo "<td class='dt-center'>Yes</td>\n"; 
    }else{ 
        echo "<td class='dt-center'>No</td>\n";
    }

    echo "</tr>\n"; 
}



# ==================================================================================================
#                                      PROGRAM START HERE
# ==================================================================================================

    # The "selection" (1st) parameter contains type of query that need to do (all_servers,os,...)   
    if (isset($_GET['selection']) && !empty($_GET['selection'])) { 
        $SELECTION = $_GET['selection'];                                # If Rcv. Save in selection
    }else{
        $SELECTION = 'all_servers';                                     # No Param.= "all_servers"
    }
    if ($DEBUG) { echo "<br>1st Parameter Received is " . $SELECTION; } # Under Debug Display Param.

    
    # The 2nd Parameters is sometime used to specify the type of server received as 1st parameter.
    # Example: http://sadmin/sadmin/sadm_view_servers.php?selection=host&value=gandalf
    if (isset($_GET['value']) && !empty($_GET['value'])) {              # If Second Value Specified
        $VALUE = $_GET['value'];                                        # Save 2nd Parameter Value
        if ($DEBUG) { echo "<br>2nd Parameter received is " . $VALUE; } # Under Debug Show 2nd Parm.
    }

    # Validate the view option received, Set Page Heading and Retreive Selected Data from Database
    switch ($SELECTION) {
        case 'all_servers'  : 
            $sql = "SELECT * FROM server where srv_active = True and srv_ostype = 'linux' order by srv_name;";
            $TITLE = "O/S Update Status";
            break;
        case 'host'         : 
            $sql = "SELECT * FROM sadm.server where srv_name = '". $VALUE . "';";
            $TITLE = "O/S Update Status for " . ucwords($VALUE) ;
            break;
        default             : 
            echo "<br>The sort order received (" . $SELECTION . ") is invalid<br>";
            echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
    }
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceding line
        $err_msg1 = "Server (" . $wkey . ") not found.\n";              # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        exit;                                                           # Exit - Should not occurs
    }
    
    # DISPLAY SCREEN HEADING    
    display_lib_heading("NotHome","$TITLE"," ",$WVER);                  # Display Content Heading
    setup_table();                                                      # Create Table & Heading
    
    # Loop Through Retrieved Data and Display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    #echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
