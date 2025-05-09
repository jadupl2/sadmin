<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_schedule.php
#   Version     :  1.5
#   Date        :  18 February 2017
#   Requires    :  secure.php.net, mariadb, DataTables.net
#   Description :  This page allow to view the servers O/S Update schedule and results.
#   
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
# ==================================================================================================
# February 2017 - Jacques DUplessis
# 2016_02_02 web v1.0  O/S update status page - Added options to edit server from that page, 
# 2017_12_12 web v2.0  O/S update status page - Adapted for MySQL and various look enhancement
# 2018_05_06 web v2.1  O/S update status page - Use Standard view file web page instead of custom 
# 2018_06_06 web v2.2  O/S update status page - Correct problem with link to view the update log 
# 2018_07_01 web v2.3  O/S update status page - Show Only Linux Server on this page (No Aix)
# 2018_07_09 web v2.4  O/S update status page - Last Update time remove seconds & Change layout
# 2018_07_09 web v2.5  O/S update status page - Change Layout of line (More Compact)
# 2019_04_04 web v2.6  O/S update status page - Show Calculated Next O/S Update Date & upd occurrence
# 2019_04_17 web v2.7  O/S update status page - Minor code cleanup and show "Manual, no schedule" 
# 2019_05_04 web v2.8  O/S update status page - Added link to view rch file content for each server.
# 2019_07_12 web v2.9  O/S update status page - Don't show MacOS and Aix status (Not applicable).
# 2019_09_20 web v2.10 O/S update status page - Show History (RCH) content using same uniform way.
# 2019_09_23 web v2.11 O/S update status page - When initiating Schedule change from here, 
# 2019_12_29 web v2.12 O/S update status page - Bottom titles was different that the heading.
# 2019_12_29 web v2.13 O/S update status page - Heading modified and now on two rows.
# 2022_09_12 web v2.14 O/S update status page - Will show link to error log (if it exist).
# 2022_09_12 web v2.15 O/S update status page - Display the first 50 systems instead of 25.
# 2023_05_01 web v2.16 O/S update status page - Enhance functionality and bug fix.
# 2023_05_06 web v2.17 O/S update status page - Enhance functionality and bug 
#@2024_11_24 web v2.18 O/S update status page - Fix bug when displaying schedule status
#@2025_05_07 web v2.19 O/S update status page - Enhance Look of the page.
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


<style>
.content-table {
    border-collapse: collapse ;
    margin: 25px 0; 
    font-size: 0.9em;
    min-width: 400px;
    width: 100%;
    border-radius: 5px 5px 0 0 ; 
    overflow: hidden;
    box-shadow: 0 0 20px rgba(0,0,0.15);
}

.content-table thead tr {
    background-color: #009879;
    color: #ffffff;
    text-align: left;
    font-weight: bold;
}

.content-table th,
.content-table td {
    padding-top:    4px;
    padding-bottom: 4px;
    padding-left:   4px;
    padding-right:  4px;
}

.content-table tbody tr {
    border-bottom: 1px solid #dddddd;
}

.content-table tbody tr:nthof-type(even) {
    background-color: #f3f3f3;
}

.content-table tbody tr.active-row {
    font-weight : bold;
    color: #009879;
}
</style>


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
$WVER          = "2.19" ;                                               # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button




# Display SADMIN Main Page Header
#===================================================================================================
function table_heading_and_footer() {

    # Table creation
    echo "\n<table class='content-table' border=0>\n" ;   

    # Table Heading
    echo "\n\n<thead>";
    echo "\n<tr>";
    echo "\n<th width=10  align='center'>No</td>";    
    echo "\n<th width=120 align='left'>System</td>";
    echo "\n<th width=85  align='center'>Last Update</th>";
    echo "\n<th width=85  align='center'>Status</th>";
    echo "\n<th width=95  align='center'>Cat. / Group</th>";
    echo "\n<th width=40  align='center'>O/S</th>";  
    echo "\n<th width=40  align='center'>Version</th>";
    echo "\n<th width=95  align='center'>Next Update</th>";
    echo "\n<th width=120 align='center'>Occurrence</th>";
    echo "\n<th width=40  align='center'>Log / Hist.</th>";
    echo "\n<th width=30  align='center'>Reboot</th>";
    echo "\n</tr>"; 
    echo "\n</thead>\n";

    # Table Footer
    echo "\n\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th width=10  align='center'>No</td>";    
    echo "\n<th width=120 align='left'>System</td>";
    echo "\n<th width=85  align='center'>Last Update</th>";
    echo "\n<th width=85  align='center'>Status</th>";
    echo "\n<th width=95  align='center'>Cat. / Group</th>";
    echo "\n<th width=40  align='center'>O/S</th>";  
    echo "\n<th width=40  align='center'>Version</th>";
    echo "\n<th width=95  align='center'>Next Update</th>";
    echo "\n<th width=120 align='center'>Occurrence</th>";
    echo "\n<th width=40  align='center'>Log / Hist.</th>";
    echo "\n<th width=30  align='center'>Reboot</th>";
    echo "\n</tr>"; 
    echo "\n</tfoot>\n";
    echo "\n<tbody>";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    #global  $URL_HOST_INFO, $URL_VIEW_FILE, $URL_VIEW_RCH, $URL_OSUPDATE, 
    #$UPDATE_SCRIPT, $URL_VIEW_SCHED; 
    
    $URL_HOST_INFO  = '/view/srv/sadm_view_server_info.php';            # Display Host Info URL
    $URL_VIEW_FILE  = '/view/log/sadm_view_file.php';                   # View File Content URL
    $URL_VIEW_RCH   = '/view/rch/sadm_view_rchfile.php';                # View RCH File Content URL
    $URL_OSUPDATE   = '/crud/srv/sadm_server_osupdate.php';             # Update Page URL
    $URL_HOST_INFO  = '/view/srv/sadm_view_server_info.php';            # Display Host Info URL
    $UPDATE_SCRIPT  = "sadm_osupdate.sh";                               # O/S Update Script Name
    $URL_VIEW_SCHED = '/view/sys/sadm_view_schedule.php';               # View O/S Update Schedule
    $OSUPDATE_RCH   = 'sadm_osupdate.rch';                              # O/S Update script rch name
    $WSYSTEM        = $row['srv_name'];                                 # Current System Name
    $rch_name = SADM_WWW_DAT_DIR  ."/".  $row['srv_name'] ."/rch/". $row['srv_name'] ."_". $OSUPDATE_RCH;
    $WOS            = $row['srv_osname'];                               # O/S Name
    $WVER           = $row['srv_osversion'];                            # O/S Version Number
    $OSUPDATE_DAYS  = 31; 

    # Line counter
    echo "\n<tr>";  
    echo "\n<td align='center'>" . $count . "</td>"; 
        
    # System Name
    echo "\n<td align='left'>";
    echo "<a href='" . $URL_HOST_INFO . "?sel=" . $WSYSTEM . "&back=" . $URL_VIEW_SCHED ;
    echo "' title='$WOS $WVER system, click to view system info.'>";
    echo $WSYSTEM  ."<br></a>" . $row['srv_desc'];
    echo "</td>";


    # Last O/S Update Date & Time.
    if (file_exists($rch_name)) {
        $file = file("$rch_name");                                   # Load RCH File
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH
        # $whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$walert,$gtype,$wcode
        #    0      1       2       3       4       5       6        7       8      9
        #$rch_array  = explode(" ",$rch_line); 
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$calert,$ctype,$ccode) = explode(" ",$lastline);

        $WLAST_UPDATE = "$cdate1 $ctime1";
    }else{
        if (substr($row['srv_date_osupdate'],0,16) == "0000-00-00 00:00") {
            $WLAST_UPDATE = "None";  
            echo "<td align='center'>";
            $tooltip = "There is no O/S update that was perform yet.";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "None yet</span></td>";
        }else{
            #$WLAST_UPDATE = substr($row['srv_date_osupdate'],0,16) ;
            $cdate1 = substr($row['srv_date_osupdate'],0 ,10) ;
            $ctime1 = substr($row['srv_date_osupdate'],11,16) ;
            $WLAST_UPDATE = "$cdate1 $ctime1";
        }
    }

    if ($WLAST_UPDATE != "None") {
        $now = time();                                                      # Actual Epoch time
        $your_date = strtotime(str_replace(".", "-",$cdate1));
        $datediff  = $now - $your_date;
        $osupdate_age = round($datediff / (60 * 60 * 24));             # Days since last O/S Update
        if ($osupdate_age > $OSUPDATE_DAYS) {                               # If was more than threshold
            $tooltip = "Last O/S update was done " .$osupdate_age. " days ago, threshold at " .$OSUPDATE_DAYS. " days.";
            echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><b>";
            echo "<span data-toggle='tooltip' title='"  . $tooltip . "'>";
            echo "$cdate1" . '&nbsp;' . substr($ctime1,0,5) ;
            echo "</font></span></td>"; 
        }else{
            $tooltip = "Last O/S update was done " .$osupdate_age. " days ago, threshold at " .$OSUPDATE_DAYS. " days.";
            echo "<td align='center'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "$cdate1" . '&nbsp;' . substr($ctime1,0,5) ; 
            echo "</span></td>"; 
        }
    }

    
    # Last Update Status
    if (file_exists($rch_name)) {
        $file = file("$rch_name");                                   # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH
        list($cserver, $cdate1, $ctime1, $cdate2, $ctime2, $celapse, $cname, $calert, $ctype, $ccode) = explode(" ", $lastline);
    } else {
        $ccode = 9;                                                     # No Log, Backup never ran
    }
    switch ( $ccode ) {
        case 0  : echo "<td align='center'>Success"; 
                  break ;
        case 1  : echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><b>Failed</b>"; 
                  break ;
        case 2  : echo "<td align='center' style='bgcolor='#DAF7A6'><b>Running</b>"; 
                  break ;
        default : echo "<td align='center' style='bgcolor='#DAF7A6'>None yet"; 
                  break ;
    }
    echo "</td>\n";  

    
    # Server Category
    echo "<td align='center'>" ;
    echo nl2br( $row['srv_cat']) . " / " . nl2br( $row['srv_group']) . "</td>\n";  

    # Display Operating System Logo
    $WOS   = sadm_clean_data($row['srv_osname']);
    sadm_show_logo($WOS);                                  
    
    
    # Display O/S Version
    echo "\n<td align='center'>" . $row['srv_osversion'] . "</td>";


    # Next Update Date
    if ($row['srv_update_auto']   == True ) { 
        echo "<td align='center'>";
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_update_dom'], $row['srv_update_month'],
            $row['srv_update_dow'], $row['srv_update_hour'], $row['srv_update_minute']);
        echo $UPD_DATE_TIME ;
    }else{
        echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><B><I>Manual update</I></B>";
    }
    echo "</td>\n";  

    
    # O/S Update Occurrence
    $ipath = '/images/UpdateButton.png';
    if ($row['srv_update_auto'] == True) {                              # Is Server Active
        $tooltip = 'Schedule is active, click to modify schedule.';
    } else {                                                            # If not Activate
        $tooltip = 'Schedule is inactive, click to modify schedule.';
    }
    if ($row['srv_update_auto']   == True ) { 
        echo "\n<td align='center'>";
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_update_dom'], $row['srv_update_month'],
        $row['srv_update_dow'], $row['srv_update_hour'], $row['srv_update_minute']);
        echo $STR_SCHEDULE ;
    }else{
        echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><B><I>No Schedule</I></B>";
    }
    echo "<br>";
    if ($row['srv_update_auto'] == True) {                              # Is Server Active
        $tooltip = 'Schedule is active, click to edit the schedule.';
#        echo "\nY ";
        echo "\n ";
    } else {                                                            # If not Activate
        $tooltip = 'Schedule is inactive, click to edit the schedule.';
        echo "\n<b><font color='red'> </font></b>";
    }
    echo "<a href='" . $URL_OSUPDATE ."?sel=". $row['srv_name'] ."&back=". $URL_VIEW_SCHED . "'>";
    echo "\n<span data-toggle='tooltip' title='" . $tooltip . "'>";
    echo "\n<button type='button'>Modify Schedule</button>";  
    echo "</a></span>";
    echo "</td>\n";  

    
    # Display link to view o/s update log file (If exist)
    echo "<td align='center'>";
    $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . $row['srv_name'] . "_sadm_osupdate.log";
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View Update Log'>[log]</a>&nbsp;";
    }else{
        echo "&nbsp;";
    }

    # Display link to view o/s update error log file (If exist)
    $ELOGFILE = $row['srv_name']  . "_" . $UPDATE_SCRIPT . "_e.log";
    $elog_name = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . trim($ELOGFILE) ;
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

    # Reboot after Update (Yes/No)
    if ($row['srv_update_reboot']   == True ) { 
        echo "<td align='center'>Yes</td>\n"; 
    }else{ 
        echo "<td align='center'>No</td>\n";
    }

    echo "</tr>\n"; 
}




# PAGE START HERE
# ==================================================================================================

# The "selection" (1st) parameter contains type of query that need to do (all_servers,os,...)   
    if (isset($_GET['selection']) && !empty($_GET['selection'])) { 
        $SELECTION = $_GET['selection'];                                # If Rcv. Save in selection
    }else{
        $SELECTION = 'all_servers';                                     # No Param.= "all_servers"
    }
    if ($DEBUG) { echo "<br>1st Parameter Received is '" . $SELECTION . "'"; } # Under Debug Display Param.

    
    # The 2nd Parameters is sometime used to specify the type of server received as 1st parameter.
    # Example: https://sadmin/sadmin/sadm_view_servers.php?selection=host&value=gandalf
    if (isset($_GET['value']) && !empty($_GET['value'])) {              # If Second Value Specified
        $VALUE = $_GET['value'];                                        # Save 2nd Parameter Value
        if ($DEBUG) { echo "<br>2nd Parameter received is " . $VALUE; } # Under Debug Show 2nd Parm.
    }

    # Validate the view option received, Set Page Heading and Retrieve Selected Data from Database
    switch ($SELECTION) {
        case 'all_servers'  : 
            $sql = "SELECT * FROM server where srv_active = True and srv_ostype = 'linux' order by srv_name;";
            $TITLE = "Operating System Update Status";
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

    # If SQL statement returned an error
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceding line
        $err_msg1 = "Server (" . $wkey . ") not found.\n";              # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        exit;                                                           # Exit - Should not occurs
    }
    
# DIsplay Page Heading
    display_lib_heading("NotHome","$TITLE"," ",$WVER);                  # Display Content Heading

# Setup table header and footer
    table_heading_and_footer();                                         # Create Table & Heading
    
# Loop Through SQL result data and display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    #echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
