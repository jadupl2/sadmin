<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_rear.php
#   Version     :  1.0
#   Date        :  6 August 2019
#   Description :  List active servers and associated with a ReaR backup schedule (if any).
#   
#   Copyright (C) 2019 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# 2019_08_26 New: v1.0 Initial version of ReaR backup Status Page
# 2019_08_26 New: v1.1 First Release of Rear Backup Status Page.
# 2019_09_20 Update: v1.2 Show History (RCH) content using same uniform way.
#@2019_10_15 Update: v1.3 Add Architecture, O/S Name, O/S Version to page
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
            "lengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
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
$DEBUG           = False ;                                              # Debug Activated True/False
$WVER            = "1.3" ;                                              # Current version number
$URL_CREATE      = '/crud/srv/sadm_server_create.php';                  # Create Page URL
$URL_UPDATE      = '/crud/srv/sadm_server_update.php';                  # Update Page URL
$URL_DELETE      = '/crud/srv/sadm_server_delete.php';                  # Delete Page URL
$URL_MAIN        = '/crud/srv/sadm_server_main.php';                    # Maintenance Main Page URL
$URL_HOME        = '/index.php';                                        # Site Main Page
$URL_SERVER      = '/view/srv/sadm_view_servers.php';                   # View Servers List
$URL_OSUPDATE    = '/crud/srv/sadm_server_osupdate.php';                # O/S Schedule Update URL
$URL_BACKUP      = '/crud/srv/sadm_server_rear_backup.php';             # Rear Schedule Update URL
$URL_VIEW_FILE   = '/view/log/sadm_view_file.php';                      # View File Content URL
$URL_VIEW_RCH    = '/view/rch/sadm_view_rchfile.php';                   # View RCH File Content URL
$URL_HOST_INFO   = '/view/srv/sadm_view_server_info.php';               # Display Host Info URL
$URL_VIEW_BACKUP = "/view/sys/sadm_view_rear.php";                      # Rear Back Status Page
$CREATE_BUTTON   = False ;                                              # Yes Display Create Button
$BACKUP_RCH      = 'sadm_rear_backup.rch';                              # Rear BackupRCH Suffix name
$BACKUP_LOG      = 'sadm_rear_backup.log';                              # Rear BackupLog Suffix name


#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function setup_table() {

    # Table creation
    echo "<div id='SimpleTable'>"; 
    echo '<table id="sadmTable" class="display" row-border width="100%">';   

    # Table Heading
    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th>Server</th>\n";
    echo "<th class='dt-head-left'>Description</th>\n";
    echo "<th class='dt-head-left'>Arch</th>\n";
    echo "<th class='dt-head-left'>O/S Name</th>\n";
    echo "<th class='dt-head-left'>O/S Version</th>\n";
    echo "<th class='text-center'>Next Rear Backup</th>\n";
    echo "<th class='text-center'>Last Rear Backup</th>\n";
    echo "<th class='dt-head-left'>Rear Backup Occurrence</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>Log / History</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th>Server</th>\n";
    echo "<th class='dt-head-left'>Description</th>\n";
    echo "<th class='dt-head-left'>Arch</th>\n";
    echo "<th class='dt-head-left'>O/S Name</th>\n";
    echo "<th class='dt-head-left'>O/S Version</th>\n";
    echo "<th class='text-center'>Next Rear Backup</th>\n";
    echo "<th class='text-center'>Last Rear Backup</th>\n";
    echo "<th class='dt-head-left'>Rear Backup Occurrence</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Status</th>\n";
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
            $URL_VIEW_BACKUP, $BACKUP_RCH, $BACKUP_LOG; 
    
    if (($row['srv_arch'] != "x86_64") and ($row['srv_arch'] != "i686")) {
        return;
    }
    echo "<tr>\n";  
    
    # Server Name
    echo "<td class='dt-center'>";
    echo "<a href='" . $URL_BACKUP . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP ."'";
    echo " title='" .$row['srv_osname']. "-" .$row['srv_osversion']." server, ip address is " ;
    echo $row['srv_ip']  . ", click to edit schedule\'>";
    echo $row['srv_name']  . "</a></td>\n";

    # Server Description
    echo "<td class='dt-body-left'>" . nl2br( $row['srv_desc']) . "</td>\n";  
    
    # Server Architecture  
    echo "<td class='dt-body-left'>" . ucfirst( $row['srv_arch']) . "</td>\n";  
    
    # Server O/S Name 
    echo "<td class='dt-body-center'>" . ucfirst( $row['srv_osname']) . "</td>\n";  
    
    # Server O/S Version
    echo "<td class='dt-body-center'>" . nl2br( $row['srv_osversion']) . "</td>\n";  

    # Next Rear Backup Date
    echo "<td class='dt-center'>";
    if ($row['srv_img_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_img_dom'], $row['srv_img_month'],
            $row['srv_img_dow'], $row['srv_img_hour'], $row['srv_img_minute']);
        echo $UPD_DATE_TIME ;
    }else{
        echo "Not activated";
    }
    echo "</td>\n";  


    # Last Rear Backup Date 
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


    # Rear Backup Occurrence
    echo "<td class='dt-body-left'>";
    if ($row['srv_img_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_img_dom'], $row['srv_img_month'],
            $row['srv_img_dow'], $row['srv_img_hour'], $row['srv_img_minute']);
        echo $STR_SCHEDULE ;
    }else{
        echo " ";
    }
    echo "</td>\n"; 


    # Backup elapse time
    if (! file_exists($rch_file))  {                                    # If RCH File Not Found
        echo "\n<td class='dt-center'>  </td>";
    }else{
        echo "<td class='dt-center'>" . nl2br($celapse) . "</td>\n";  
    }


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


    # Display link to view Rear Backup log and rch file
    echo "<td class='dt-center'>";
    $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . $row['srv_name'] . "_" . $BACKUP_LOG;
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View Backup Log'>[log]</a>&nbsp;&nbsp;&nbsp;";
    }else{
        echo " N/A ";
    }

    $rch_name = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . $row['srv_name'] . "_" . $BACKUP_RCH;
    $rch_www_name  = $row['srv_name'] . "_$BACKUP_RCH";
    if (file_exists($rch_name)) {
        echo "<a href='" . $URL_VIEW_RCH . "?host=" . $row['srv_name'] . "&filename=" . $rch_www_name . "'" ;
        echo " title='View Backup History (rch) file'>[rch]</a>";
    }else{
        echo "N/A";
    }
    echo "</td>\n";  
    echo "</tr>\n"; 
}



# ==================================================================================================
#                                      PHP MAIN START HERE
# ==================================================================================================

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
    $title1="ReaR Backup Schedule Status";                              # Page Title 1
    $title2="ReaR only available on x86_64 and i686 architecture";                                                         # Page Title 2
    display_lib_heading("NotHome","$title1","$title2",$WVER);           # Display Heading
    setup_table();                                                      # Create Table & Heading
    
    # Loop Through Retrieved Data and Display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
