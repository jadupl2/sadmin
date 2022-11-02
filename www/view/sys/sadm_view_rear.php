<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_rear.php
#   Version     :  1.0
#   Date        :  6 August 2019
#   Description :  List active servers and associated with a ReaR backup schedule (if any).
#   
#   Copyright (C) 2019 Jacques Duplessis <sadmlinux@gmail.com>
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
#
# 2019_08_26 backup v1.0 ReaR backup status page - Initial version of ReaR backup Status Page
# 2019_08_26 backup v1.1 ReaR backup status page - First Release of Rear Backup Status Page.
# 2019_09_20 backup v1.2 ReaR backup status page - Show History (RCH) content using same uniform way.
# 2019_10_15 backup v1.3 ReaR backup status page - Add Architecture, O/S Name, O/S Version to page
# 2020_01_13 backup v1.4 ReaR backup status page - Change column disposition and show ReaR version no. of systems.
# 2020_01_14 backup v1.5 ReaR backup status page - Don't show MacOS System on page (Not supported by ReaR).
# 2020_03_05 backup v1.6 ReaR backup status page - When mouse over server name (Show more information).
# 2020_07_29 backup v1.7 ReaR backup status page - Remove system description to allow more space on each line.
# 2020_13_13 backup v1.8 ReaR backup status page - Add link in heading to view ReaR Daily Report.
#@2022_09_12 backup v1.9 ReaR backup status page - Show if schedule is activated or not.
#@2022_09_12 backup v2.0 ReaR backup status page - Show link to error log (if it exist.).
#@2022_09_12 backup v2.1 ReaR backup status page - Display the first 50 systems instead of 25.
#@2022_09_20 backup v2.2 ReaR backup status page - Move ReaR supported architecture msg to heading.
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
            "bJQueryUI" : true,
            "paging"    : true,
            "ordering"  : true,
            "info"      : true
        } );
    } );
</script>
<?php


#===================================================================================================
#                                       Local Variables
#===================================================================================================
$DEBUG              = False ;                                           # Debug Activated True/False
$WVER               = "2.2" ;                                           # Current version number
$URL_CREATE         = '/crud/srv/sadm_server_create.php';               # Create Page URL
$URL_UPDATE         = '/crud/srv/sadm_server_update.php';               # Update Page URL
$URL_DELETE         = '/crud/srv/sadm_server_delete.php';               # Delete Page URL
$URL_MAIN           = '/crud/srv/sadm_server_main.php';                 # Maintenance Main Page URL
$URL_HOME           = '/index.php';                                     # Site Main Page
$URL_SERVER         = '/view/srv/sadm_view_servers.php';                # View Servers List
$URL_OSUPDATE       = '/crud/srv/sadm_server_osupdate.php';             # O/S Schedule Update URL
$URL_BACKUP         = '/crud/srv/sadm_server_rear_backup.php';          # Rear Schedule Update URL
$URL_VIEW_FILE      = '/view/log/sadm_view_file.php';                   # View File Content URL
$URL_VIEW_RCH       = '/view/rch/sadm_view_rchfile.php';                # View RCH File Content URL
$URL_HOST_INFO      = '/view/srv/sadm_view_server_info.php';            # Display Host Info URL
$URL_VIEW_BACKUP    = "/view/sys/sadm_view_rear.php";                   # Rear Back Status Page
$URL_REAR_REPORT    = "/view/daily_rear_report.html";                   # Rear Daily Report Page
$URL_BACKUP_REPORT  = "/view/daily_backup_report.html";                 # Backup Daily Report Page
$URL_STORIX_REPORT  = "/view/daily_storix_report.html";                 # Storix Daily Report Page
$URL_SCRIPTS_REPORT = "/view/daily_scripts_report.html";                # Scripts Daily Report Page
$CREATE_BUTTON      = False ;                                           # Yes Display Create Button
#
$BACKUP_RCH         = 'sadm_rear_backup.rch';                           # Rear Backup RCH 
$BACKUP_LOG         = 'sadm_rear_backup.log';                           # Rear Backup Log 
$BACKUP_ELOG        = 'sadm_rear_backup_e.log';                         # Rear Backup Error LOG 


#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function setup_table() {

    echo "<div id='SimpleTable'>"; 
    echo '<table id="sadmTable" class="display" row-border width="100%">';   

    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th>Server</th>\n";
    echo "<th class='dt-head-left'>Description</th>\n";
    echo "<th class='text-center'>O/S</th>\n";
    echo "<th class='dt-head-center'>Sched. Active</th>\n";
    echo "<th class='text-center'>ReaR Ver.</th>\n";
    echo "<th class='text-center'>Last Execution</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Next Backup</th>\n";
    echo "<th class='text-center'>Backup Occurrence</th>\n";
    echo "<th class='text-center'>Log / History</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th>Server</th>\n";
    echo "<th class='dt-head-left'>Description</th>\n";
    echo "<th class='text-center'>O/S</th>\n";
    echo "<th class='dt-head-center'>Sched. Active</th>\n";
    echo "<th class='text-center'>ReaR Ver.</th>\n";
    echo "<th class='text-center'>Last Execution</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Next Backup</th>\n";
    echo "<th class='text-center'>Backup Occurrence</th>\n";
    echo "<th class='text-center'>Log / History</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";
    echo "<tbody>\n";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    global  $URL_HOST_INFO, $URL_VIEW_FILE, $URL_BACKUP, $URL_VIEW_RCH, 
            $URL_VIEW_BACKUP, $BACKUP_RCH, $BACKUP_LOG, $BACKUP_ELOG ;
    
    # ReaR Not Supported on MacOS and ARM system (Raspberry Pi)
    if (($row['srv_arch'] != "x86_64") and ($row['srv_arch'] != "i686")) { return ; } 
    if ($row['srv_ostype'] == "darwin") { return ; }
    
    # Server Name
    echo "<tr>\n";  
    echo "<td class='dt-center'>";
    echo "<a href='" . $URL_BACKUP . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP ."'";
    echo " title='" .$row['srv_osname']. "-" .$row['srv_osversion']." - " ;
    echo $row['srv_ip']  . ", Click to edit the schedule.'>";
    echo $row['srv_name']  . "</a></td>\n";

    # Server Description
    echo "<td class='dt-body-left'>" . nl2br( $row['srv_desc']) . "</td>\n";  
    
    # Display Operating System Logo
    $WOS   = sadm_clean_data($row['srv_osname']);
    sadm_show_logo($WOS);                                               # Show Distribution Logo
    
    # Schedule Active or not.
    if ($row['srv_img_backup'] == TRUE ) {                              # If Schedule is activated
        echo "\n<td class='dt-center'>";
        #echo "<a href='" .$URL_SERVER. "?selection=all_active'>Active</a></td>";
        echo "<a href='" .$URL_SERVER. "?selection=all_active'>Yes</a></td>";
    }else{                                                              # If not Activate
        echo "\n<td class='dt-center'>";
        #echo "<a href='" .$URL_SERVER. "?selection=all_inactive'>Inactive</a></td>";
        echo "<a href='" .$URL_SERVER. "?selection=all_inactive'>No</a></td>";
    }

    # ReaR Server Version
    echo "<td class='dt-body-center'>" . nl2br( $row['srv_rear_ver']) . "</td>\n";  

    # Last Execution Rear Backup date & time
    echo "<td class='dt-center'>" ;
    $rch_dir  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" ;   # Set the RCH Directory Path
    $rch_file = $rch_dir . $row['srv_name'] . "_" . $BACKUP_RCH;        # Set Full PathName of RCH
    if (! file_exists($rch_file))  {                                    # If RCH File Not Found
        echo " ";  
    }else{
        $file = file("$rch_file");                                      # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH

        # Split the last line of the backup rch file.
        # Example: centos6 2019.07.05 04:05:02 2019.07.05 04:21:31 00:16:29 sadm_backup default 1 0
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$calert,$ctype,$ccode) = explode(" ",$lastline);
        echo "$cdate1" . ' ' . substr($ctime1,0,5) ;
    }
    echo "</td>\n";  

    # Last Backup Status
    if (! file_exists($rch_file))  {                                    # If RCH File Not Found
        echo "\n<td class='dt-center'>  </td>";
    }else{
        switch ($ccode) {
            case 0:     echo "\n<td class='dt-center'>Success</td>";
                        break;
            case 1:     echo "\n<td class='dt-center'>Failed</td>";
                        break;
            case 2:     echo "\n<td class='dt-center'>Running</td>";
                        break;
            default:    echo "\n<td class='dt-center'>" . $ccode . "</td>";
                        break;
        }   
    }

    # Backup execution time
    if (! file_exists($rch_file))  {                                    # If RCH File Not Found
        echo "\n<td class='dt-center'>&nbsp;</td>";
    }else{
        echo "<td class='dt-center'>" . nl2br($celapse) . "</td>\n";  
    }

    # Next Rear Backup Date
    echo "<td class='dt-center'>";
    if ($row['srv_img_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_img_dom'], $row['srv_img_month'],
            $row['srv_img_dow'], $row['srv_img_hour'], $row['srv_img_minute']);
        echo $UPD_DATE_TIME ;
    }else{
        echo "Unknown";
    }
    echo "</td>\n";  

    # Rear Backup Occurrence
    echo "<td class='dt-center'>";
    if ($row['srv_img_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_img_dom'], $row['srv_img_month'],
            $row['srv_img_dow'], $row['srv_img_hour'], $row['srv_img_minute']);
        echo $STR_SCHEDULE ;
    }else{
        echo " ";
    }
    echo "</td>\n"; 

    # Display link to view Rear Backup log
    echo "<td class='dt-center'>";
    $log_name  = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_LOG;
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View Backup Log'>[log]</a>&nbsp;";
    }else{
        echo "[NoLog]&nbsp;";
    }

    # Display link to view ReaR backup error log (If exist)
    $elog_name = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_ELOG ;
    if ((file_exists($elog_name)) and (file_exists($elog_name)) and (filesize($elog_name) != 0)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $elog_name . "'" ;
        echo " title='View ReaR error Log'>[elog]</a>&nbsp;";
    }

    # Display link to view Rear Backup rch file
    $rch_name = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . $row['srv_name'] . "_" . $BACKUP_RCH;
    $rch_www_name  = $row['srv_name'] . "_$BACKUP_RCH";
    if (file_exists($rch_name)) {
        echo "<a href='" . $URL_VIEW_RCH . "?host=" . $row['srv_name'] . "&filename=" . $rch_www_name . "'" ;
        echo " title='View Backup History (rch) file'>[rch]</a>";
    }else{
        echo "&nbsp;[NoRCH]";
    }
    echo "</td>\n</tr>\n"; 
}



# ==================================================================================================
# PHP MAIN START HERE
# ==================================================================================================

    # Get all active systems from the SADMIN Database
    $sql = "SELECT * FROM server where srv_active = True order by srv_name;";
    $result=mysqli_query($con,$sql) ;     
    $NUMROW = mysqli_num_rows($result);                                 # Get Nb of rows returned
    if ($NUMROW == 0)  {                                                # If No Server found
        $err_msg = "<br>No active server found in Database";            # Construct msg to user
        $err_msg = $err_msg . mysqli_error($con) ;                      # Add MySQL Error Msg
        if ($DEBUG) {                                                   # In Debug Insert SQL in Msg
            $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query ;
        }
        sadm_fatal_error($err_msg);                                     # Display Error & Go Back
        exit();  
    }

    # Show ReaR schedule page heading
    $title1="ReaR Backup Status";                                       # Page Title 1
    $title2="MacOS and ARM systems aren't shown on this page because they are not supported by ReaR";
    if (file_exists(SADM_WWW_DIR . "/view/daily_rear_report.html")) {
        $title2="<a href='" . $URL_REAR_REPORT . "'>View the ReaR Daily Report</a>"; 
    }     
    display_lib_heading("NotHome","$title1","$title2",$WVER);           # Display Heading
    setup_table();                                                      # Create HTML Table/Heading
    
    # Loop Through Retrieved Data and Display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table

    echo "<center>MacOS and ARM systems aren't shown on this page because they are not supported by ReaR.</center>.";
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
