<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_backup.php
#   Version     :  1.0
#   Date        :  6 July 2019
#   Description :  List active servers and associated backup schedule status (if any).
#   
#   Copyright (C) 2019 Jacques Duplessis <duplessis.jacques@gmail.com>
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
#@2019_07_06 New: v1.0 Initial version of backup Status Page
#
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar

# DataTable Initialisation Function
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
$DEBUG         = False ;                                                # Debug Activated True/False
$WVER          = "1.0" ;                                                # Current version number
$URL_CREATE    = '/crud/srv/sadm_server_create.php';                    # Create Page URL
$URL_UPDATE    = '/crud/srv/sadm_server_update.php';                    # Update Page URL
$URL_DELETE    = '/crud/srv/sadm_server_delete.php';                    # Delete Page URL
$URL_MAIN      = '/crud/srv/sadm_server_main.php';                      # Maintenance Main Page URL
$URL_HOME      = '/index.php';                                          # Site Main Page
$URL_SERVER    = '/view/srv/sadm_view_servers.php';                     # View Servers List
$URL_OSUPDATE  = '/crud/srv/sadm_server_osupdate.php';                  # O/S Schedule Update URL
$URL_BACKUP    = '/crud/srv/sadm_server_backup.php';                    # Backup Schedule Update URL
$URL_VIEW_FILE = '/view/log/sadm_view_file.php';                        # View File Content URL
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$BACKUP_RCH    = 'sadm_backup.rch';                                     # Backup RCH Suffix name
$BACKUP_LOG    = 'sadm_backup.log';                                     # Backup LOG Suffix name


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
    echo "<th class='dt-head-left'>Backup Occurrence</th>\n";
    echo "<th class='text-center'>Next Backup</th>\n";
    echo "<th class='text-center'>Last Backup</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>View log/rch</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th>Server</th>\n";
    echo "<th class='dt-head-left'>Description</th>\n";
    echo "<th class='dt-head-left'>Backup Occurrence</th>\n";
    echo "<th class='text-center'>Next Backup</th>\n";
    echo "<th class='text-center'>Last Backup</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>View log/rch</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";
 
    echo "<tbody>\n";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    global $URL_HOST_INFO, $URL_VIEW_FILE, $URL_BACKUP, $BACKUP_RCH, $BACKUP_LOG; 
    
    echo "<tr>\n";  
    
    # Server Name
    $WOS  = $row['srv_osname'];
    $WVER = $row['srv_osversion'];
    echo "<td class='dt-center'>";
    echo "<a href='" . $URL_BACKUP . "?sel=" . $row['srv_name'] ;
    echo "' title='$WOS $WVER server, ip address is " .$row['srv_ip']. ", click to edit schedule'>";
    echo $row['srv_name']  . "</a></td>\n";
    
    # Server Description
    #echo "<td class='dt-center'>" . nl2br( $row['srv_desc']) . "</td>\n";  
    echo "<td class='dt-body-left'>" . nl2br( $row['srv_desc']) . "</td>\n";  


    # Occurrence of the O/S Backup
    echo "<td class='dt-body-left'>";
    if ($row['srv_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_backup_dom'], $row['srv_backup_month'],
            $row['srv_backup_dow'], $row['srv_backup_hour'], $row['srv_backup_minute']);
        echo $STR_SCHEDULE ;
    }else{
        echo "Not scheduled";
    }
    echo "</td>\n";  


    # Next Backup Date
    echo "<td class='dt-center'>";
    if ($row['srv_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_backup_dom'], $row['srv_backup_month'],
            $row['srv_backup_dow'], $row['srv_backup_hour'], $row['srv_backup_minute']);
        echo $UPD_DATE_TIME ;
    }else{
        echo "Not activated";
    }
    echo "</td>\n";  


    # Last O/S Backup Date 
    echo "<td class='dt-center'>" ;
    $rch_dir  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" ;   # Set the RCH Directory Path
    $rch_file = $rch_dir . $row['srv_name'] . "_" . $BACKUP_RCH;           # Set Full PathName of RCH
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



    # Display link to view o/s update log and rch file
    echo "<td class='dt-center'>";
    $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . $row['srv_name'] . "_" . $BACKUP_LOG;
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View Backup Log'>log</a>&nbsp;&nbsp;&nbsp;";
    }else{
        echo " N/A ";
    }
    $rch_name = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . $row['srv_name'] . "_" . $BACKUP_RCH;
    if (file_exists($rch_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $rch_name . "'" ;
        echo " title='View Backup rch file'>rch</a>";
    }else{
        echo " N/A ";
    }
    echo "</td>\n";  

    // # Automatic Backup (Yes/No)
    // if ($row['srv_update_auto']   == True ) { 
    //     echo "<td class='dt-center'>Yes</td>\n"; 
    // }else{ 
    //     echo "<td class='dt-center'><B>Manual update</b></td>\n";
    // }

    // # Reboot after Backup (Yes/No)
    // if ($row['srv_update_reboot']   == True ) { 
    //     echo "<td class='dt-center'>Yes</td>\n"; 
    // }else{ 
    //     echo "<td class='dt-center'>No</td>\n";
    // }

    echo "</tr>\n"; 
}



# ==================================================================================================
#                                      PHP MAIN START HERE
# ==================================================================================================

    $sql = "SELECT * FROM server where srv_active = True order by srv_name;";
    $TITLE = "O/S Backup Status";
    
    $result=mysqli_query($con,$sql) ;     
    if (!$result)   {                                               # If Server not found
        $err_msg = "<br>Server " . $HOSTNAME . " not found in the database.";  
        $err_msg = $err_msg . mysqli_error($con) ;                  # Add MySQL Error Msg
        sadm_fatal_error($err_msg);                                 # Display Error & Go Back
        exit();            
    }

    $NUMROW = mysqli_num_rows($result);                             # Get Nb of rows returned
    if ($NUMROW == 0)  {                                            # If Server not found
        $err_msg = "<br>Server " . $HOSTNAME . " not found in Database"; # Construct msg to user
        $err_msg = $err_msg . mysqli_error($con) ;                  # Add MySQL Error Msg
        if ($DEBUG) {                                               # In Debug Insert SQL in Msg
            $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query ;
        }
        sadm_fatal_error($err_msg);                                 # Display Error & Go Back
        exit();  
    }
    
    # Display Page Heading
    display_std_heading($BACK_URL,$TITLE,"","",$WVER) ;
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
