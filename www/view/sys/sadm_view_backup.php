<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_backup.php
#   Version     :  1.0
#   Date        :  6 July 2019
#   Description :  List active servers and associated backup schedule status (if any).
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
# 2019_07_06 web v1.0 Backup status page - Initial version of backup Status Page
# 2019_08_14 web v1.1 Backup status page - Allow to return to this page when backup sched is updated
# 2019_09_20 web v1.3 Backup status page - Show History (RCH) content using same uniform way.
# 2019_12_01 web v1.4 Backup status page - Change Layout to align with daily backup schedule.
# 2020_12_13 web v1.5 Backup status page - Added link in Heading to view the Daily Backup Report
# 2022_09_11 web v1.6 Backup status page - Now show if schedule is activated or not.
# 2022_09_12 web v1.7 Backup status page - Will show link to error log (if it exist).
# 2022_09_12 web v1.8 Backup status page - Display the first 50 systems instead of 25.
#@2022_11_12 web v1.9 Backup status page - Now shows backup size of last & proceeding backup size.
#@2022_11_12 web v2.0 Backup status page - Show NFS server name & backup directory on backup page.
#@2022_11_12 web v2.1 Backup status page - Added column to show if system is online sporadically.
#@2022_11_20 web v2.2 Backup status page - Backup error log link wasn't appearing when it should.
#@2023_01_05 web v2.3 Backup status page - Yellow alert if backup size is contrasting with previous.
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
$WVER               = "2.3" ;                                           # Current version number
$URL_CREATE         = '/crud/srv/sadm_server_create.php';               # Create Page URL
$URL_UPDATE         = '/crud/srv/sadm_server_update.php';               # Update Page URL
$URL_DELETE         = '/crud/srv/sadm_server_delete.php';               # Delete Page URL
$URL_MAIN           = '/crud/srv/sadm_server_main.php';                 # Maintenance Main Page URL
$URL_HOME           = '/index.php';                                     # Site Main Page
$URL_SERVER         = '/view/srv/sadm_view_servers.php';                # View Servers List
$URL_OSUPDATE       = '/crud/srv/sadm_server_osupdate.php';             # O/S Schedule Update URL
$URL_BACKUP         = '/crud/srv/sadm_server_backup.php';               # Backup Schedule Update URL
$URL_VIEW_FILE      = '/view/log/sadm_view_file.php';                   # View File Content URL
$URL_VIEW_RCH       = '/view/rch/sadm_view_rchfile.php';                # View RCH File Content URL
$URL_HOST_INFO      = '/view/srv/sadm_view_server_info.php';            # Display Host Info URL
$URL_VIEW_BACKUP    = "/view/sys/sadm_view_backup.php";                 # CRUD Server Menu URL
$URL_REAR_REPORT    = "/view/daily_rear_report.html";                   # Rear Daily Report Page
$URL_BACKUP_REPORT  = "/view/daily_backup_report.html";                 # Backup Daily Report Page
$URL_STORIX_REPORT  = "/view/daily_storix_report.html";                 # Storix Daily Report Page
$URL_SCRIPTS_REPORT = "/view/daily_scripts_report.html";                # Scripts Daily Report Page
$CREATE_BUTTON      = False ;                                           # Yes Display Create Button
#
$BACKUP_RCH         = 'sadm_backup.rch';                                # Backup RCH 
$BACKUP_LOG         = 'sadm_backup.log';                                # Backup LOG 
$BACKUP_ELOG        = 'sadm_backup_e.log';                              # Backup Error LOG 


#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function setup_table() {

    echo "<div id='SimpleTable'>"; 
    #echo '<table class="display" row-border width="100%">';   
    echo '<table id="sadmTable" class="display" width="100%">';   
    echo "<thead>\n";

    echo "<tr>\n";
    echo "<th align='left'>System</th>\n";
    echo "<th class='dt-head-left'>Description</th>\n";
    echo "<th class='dt-head-center'>Schedule</th>\n";
    echo "<th class='dt-head-center'>Sporadic</th>\n";
    echo "<th class='dt-head-center'>Time</th>\n";
    echo "<th class='text-center'>Last Backup</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>Log/History</th>\n";
    echo "<th align='center'>Backup Size</th>\n";
    echo "<th class='text-center'>Prev. Size</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th align='left'>System</th>\n";
    echo "<th class='dt-head-left'>Description</th>\n";
    echo "<th class='dt-head-center'>Schedule</th>\n";
    echo "<th class='dt-head-center'>Sporadic</th>\n";
    echo "<th class='dt-head-center'>Time</th>\n";
    echo "<th class='text-center'>Last Backup</th>\n";
    echo "<th class='text-center'>Duration</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>Log/History</th>\n";
    echo "<th align='center'>Backup Size</th>\n";
    echo "<th class='text-center'>Prev. Size</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";
    echo "</tfoot>\n";

    echo "<tbody>\n";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    
    global  $URL_HOST_INFO, $URL_VIEW_FILE, $URL_VIEW_RCH, $URL_BACKUP, 
            $URL_VIEW_BACKUP, $BACKUP_RCH, $BACKUP_LOG, $BACKUP_ELOG ;

    $WOS  = $row['srv_osname'];                                         # Save OS Name
    $WVER = $row['srv_osversion'];                                      # Save OS Version
    
    # Server Name
    echo "<tr>\n";  
    #echo "<td class='dt-center'>";
    echo "<td>";
    echo "<a href='" . $URL_HOST_INFO . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP ;
    echo "' title='Click to view system info, $WOS $WVER system, ip address is " .$row['srv_ip']. "'>";
    echo $row['srv_name']  . "</a></td>\n";
    
    # Server Description
    echo "<td class='dt-body-left'>" . $row['srv_desc'] . "</td>";  

    # Schedule Active or Inactive.
    if ($row['srv_backup'] == TRUE ) {                                  # Is Server Active
        echo "\n<td class='dt-center'>";
        echo "<a href='" .$URL_BACKUP. "?sel=" .$row['srv_name']. "&back=" .$URL_VIEW_BACKUP ;
        echo "' title='Click to edit backup schedule of " .$row['srv_name']. " system.'>";
        echo "<img src='/images/sadm_edit_0.png' style='width:20px;height:20px;'> Active";
    }else{                                                              # If not Activate
        echo "\n<td class='dt-center' bgcolor='Yellow'>";
        echo "<a href='" .$URL_BACKUP. "?sel=" .$row['srv_name']. "&back=" .$URL_VIEW_BACKUP ;
        echo "' title='Click to edit backup schedule of " .$row['srv_name']. " system.'>";
        echo "<img src='/images/sadm_edit_0.png' style='width:20px;height:20px;'> <b>Inactive</b>";
    }
    echo "</a></td>";

    # Sporadic Server or not.
    if ($row['srv_sporadic'] == TRUE ) {                                # Is Server Active
        echo "\n<td class='dt-center'><b>Yes</b></a></td>";
    }else{                                                              # If not Activate
        echo "\n<td class='dt-center'>No</a></td>";
    }

    # Time of the O/S Backup
    echo "\n<td class='dt-body-center'>";
    if ($row['srv_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_backup_dom'], $row['srv_backup_month'],
            $row['srv_backup_dow'], $row['srv_backup_hour'], $row['srv_backup_minute']);
        #echo $STR_SCHEDULE ;
        echo sprintf("%02d",$row['srv_backup_hour']) .":". sprintf("%02d",$row['srv_backup_minute']); 
    }else{
        echo "<b>Deactivated</b>";
    }
    echo "</td>\n";  

    # Last Backup Date 
    $rch_dir  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" ;   # Set the RCH Directory Path
    $rch_file = $rch_dir . $row['srv_name'] . "_" . $BACKUP_RCH;        # Set Full PathName of RCH
    if (! file_exists($rch_file))  {                                    # If RCH File doesn't exist
        echo "<td class='dt-center' bgcolor='Yellow'><b>Not run</b></td>\n";
    }else{
        $file = file("$rch_file");                                      # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH

        # Split the last line of the rch file.
        # Example: centos9 2019.07.05 04:05:02 2019.07.05 04:21:31 00:16:29 sadm_backup default 1 0
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$calert,$ctype,$ccode) = explode(" ",$lastline);
        #echo "$cdate1" . ' ' . substr($ctime1,0,5) ;
        if (date("Y.m.d") != $cdate1)  {
            echo "<td class='dt-center' bgcolor='Yellow'><b>$cdate1</b></td>\n";
        }else{
            echo "<td class='dt-center'>$cdate1</td>\n" ;
        }
    }

    # Backup duration time
    if (! file_exists($rch_file))  {                                    # If RCH File Not Found
        echo "\n<td class='dt-center' bgcolor='Yellow'><b>No data</b></td>";
    }else{
        echo "<td class='dt-center'>" .$celapse . "</td>";  
    }

    # Last Backup Status
    if (! file_exists($rch_file))  {                                    # If RCH File Not Found
        echo "\n<td class='dt-center' bgcolor='yellow'><b>No data</b></td>";
    }else{
        switch ($ccode) {
            case 0:     echo "\n<td class='dt-center'>Success</td>\n";
                        break;
            case 1:     echo "\n<td class='dt-center' bgcolor='yellow'>Failed</td>\n";
                        break;
            case 2:     echo "\n<td class='dt-center' bgcolor='yellow'>Running</td>\n";
                        break;
            default:    echo "\n<td class='dt-center' bgcolor='yellow'>" . $ccode . "</td>\n";
                        break;
        }   
    }

    # Display link to view backup log
    $log_name  = SADM_WWW_DAT_DIR . "/" .$row['srv_name']. "/log/" . $row['srv_name'] . "_" . $BACKUP_LOG;
    if (file_exists($log_name)) {
        echo "<td class='dt-center'>";
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View Backup Log'>[log]</a>&nbsp;&nbsp;";
    }else{
        echo "<td class='dt-center' bgcolor='yellow'><b>No data</b>";
    }

    # Display link to view backup error log (If exist)
    $elog_name = SADM_WWW_DAT_DIR  ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_ELOG ;
    if ( (file_exists($elog_name)) and (filesize($elog_name) != 0) ) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $elog_name . "'" ;
        echo " title='View Error Log'>[elog]</a>&nbsp;&nbsp;";
    }else{
        echo "&nbsp;";
    }

    # Display link to view rch history file
    $rch_name = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . $row['srv_name'] . "_" . $BACKUP_RCH;
    $rch_www_name  = $row['srv_name'] . "_$BACKUP_RCH";
    if (file_exists($rch_name)) {
        echo "<a href='" . $URL_VIEW_RCH . "?host=" . $row['srv_name'] . "&filename=" . $rch_www_name . "'" ;
        echo " title='View Backup History (rch) file'>[rch]</a>";
    }
    echo "</td>\n"; 
    
    # Calculate Current Backup Size. 
    $backup_size = 0 ; 
    if (file_exists($log_name)) {
        $pattern = "/current backup size/i"; 
        if (preg_grep($pattern, file($log_name))) {
            $bstring     = implode (" ", preg_grep($pattern, file($log_name)));
            $barray      = explode (" ", $bstring) ;
            $backup_size = $barray[count($barray)-1];
            # remove all non-numeric characters from backup size
            $num_backup_size = preg_replace("/[^0-9]/", "", $backup_size );
        }
    }

    # Calculate Previous Backup Size. 
    $previous_size = 0 ; 
    if (file_exists($log_name)) {
        $pattern = "/previous backup size/i";
        if (preg_grep($pattern, file($log_name))) {
            $bstring       = implode (" ", preg_grep($pattern, file($log_name)));
            $barray        = explode (" ", $bstring) ;
            $previous_size = $barray[count($barray)-1];
            # remove all non-numeric characters from backup size
            $num_previous_size = preg_replace("/[^0-9]/", "", $previous_size );
        }
    }

    # Show Backup Size
    if (($num_backup_size == 0 || $num_previous_size == 0) && (SADM_BACKUP_DIF != 0)) {
        echo "<td align='center' bgcolor='yellow'><b>" . $backup_size . "</b></td>\n";  
    }else{
        $PCT = (($num_backup_size - $num_previous_size) / $num_previous_size) * 100;
        if (number_format($PCT,1) != 0.0) {
            if ((number_format($PCT,0) >= SADM_BACKUP_DIF) || (number_format($PCT,0) <= (SADM_BACKUP_DIF * -1))) {
                echo "<td align='center' bgcolor='yellow'><b>" . $backup_size . "&nbsp;" . number_format($PCT,1) . "%</b></td>\n"; 
            }else{
                echo "<td align='center'>" . $backup_size . "&nbsp;" . number_format($PCT,1) . "%</td>\n"; 
            }
        }else{
            echo "<td align='center'>" . $backup_size . "</td>\n"; 
        }
    }

    # Show Previous Backup Size
    if (($num_backup_size == 0 || $num_previous_size == 0) && (SADM_BACKUP_DIF != 0)) {
        echo "<td align='center' bgcolor='yellow'><b>" . $previous_size . "</b></td>\n";  
    }else{
        echo "<td align='center'>" . $previous_size . "</td>\n";
    }

    echo "</tr>\n"; 
}


#===================================================================================================
# Add legend at the bottom of the page
#===================================================================================================
function backup_legend() {
    echo  "\n<hr>\n<center><b>\n";
    echo "If backup status isn't 'Success' it will have a yellow background.<br>\n";
    echo "If the current backup size is zero or " . SADM_BACKUP_DIF . "% bigger or smaller than the previous backup, it will have a yellow background.<br>\n";
    echo "If the previous backup size is zero or " . SADM_BACKUP_DIF . "% bigger or smaller than the current backup, it will have a yellow background.<br>\n";
    echo "The " . SADM_BACKUP_DIF . "% can be change by modifying the 'SADM_BACKUP_DIF' variable in \$SADMIN/cfg/sadmin.cfg.<br>\n";
    echo "If the backup schedule column is not 'Active', it will appear with a yellow background .<br>\n";
    echo "If the date of the last backup is not today, it will have a yellow background (Backup are done daily).<br>\n";
    echo  "</center><br><br>\n";        
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
    
    # DISPLAY SCREEN HEADING    
    $title1="Daily Backup Status";
    $title2="";
    if (file_exists(SADM_WWW_DIR . "/view/daily_backup_report.html")) {
       $title2="<a href='" . $URL_BACKUP_REPORT . "'>View the Backup Daily Report</a>"; 
    } 
    $title2="Backup are recorded on '" . SADM_BACKUP_NFS_SERVER . "' in '" ;
    $title2="$title2" . SADM_BACKUP_NFS_MOUNT_POINT . "' directory." ;
    display_lib_heading("NotHome","$title1","$title2",$WVER);           # Display Content Heading

    setup_table();                                                      # Create Table & Heading
    
    # Loop Through Retrieved Data and Display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    backup_legend();
    std_page_footer($con);                                              # Close MySQL & HTML Footer
?>
