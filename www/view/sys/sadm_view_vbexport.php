<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_vbexport.php
#   Version     :  1.0
#   Date        :  22 May 2024
#   Description :  List results of latest Virtual Box exports.
#   
#    2019 Jacques Duplessis <sadmlinux@gmail.com>
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
#
# 2024_05_22 web v1.0 Virtual Box export results page - Initial version.
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGES OF SADMIN SITE
#echo ("\n ========= DOCUMENT ROOT : $_SERVER['DOCUMENT_ROOT']\n") ; 
#echo ("\n ========= init lib = '/lib/sadmInit.php' \n"); 
#exit ("Aborted by Jacques");

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
$WVER               = "1.0" ;                                           # Current version number
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
$URL_VIEW_BACKUP    = "/view/sys/sadm_view_rear.php";                   # Rear Back Status Page
$URL_VIEW_VBEXPORT  = "/view/sys/sadm_view_vbexport.php";               # VirtualBox Export URL
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
    #echo '<table id="sadmTable" class="display" row-border width="100%">';   
#    echo "<table id='sadmTable' row-border width='100%'>\n";   
    echo "<table row-border width='100%'>\n";   

    echo "\n<thead>\n";
    echo "<tr>\n";
    echo "<th class='text-left'>No.</th>\n";
    echo "<th align=left>Guest Name</th>\n";
    echo "<th align=left>Host Name</th>\n";
    echo "<th align=left>Last Export / Duration</th>\n";
    echo "<th class='text-left'>Status</th>\n";
    echo "<th class='text-left'>VM Type Active</th>\n";
    echo "<th class='text-center'>VGuest<br>Version</th>\n";
    echo "<th class='dt-head-center'>Export<br>Schedule</th>\n";
    echo "<th class='dt-head-center'>Sporadic</th>\n";
    echo "<th class='text-center'>Next Export<br>Occurrence</th>\n";
    echo "<th align='center'>Last Export Size</th>\n";
    echo "<th class='text-center'>Previous Export Size</th>\n";
    echo "<th class='text-center'>Export Log<br>Export History</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    echo "\n<tfoot>\n";
    echo "<tr>\n";
    echo "<th class='text-left'>No.</th>\n";
    echo "<th align=left>Guest Name</th>\n";
    echo "<th align=left>Host Name</th>\n";
    echo "<th align=left>Last Export / Duration</th>\n";
    echo "<th class='text-left'>Status</th>\n";
    echo "<th class='text-left'>VM Type Active</th>\n";
    echo "<th class='text-center'>VGuest<br>Version</th>\n";
    echo "<th class='dt-head-center'>Export<br>Schedule</th>\n";
    echo "<th class='dt-head-center'>Sporadic</th>\n";
    echo "<th class='text-center'>Next Export<br>Occurrence</th>\n";
    echo "<th align='center'>Last Export Size</th>\n";
    echo "<th class='text-center'>Previous Export Size</th>\n";
    echo "<th class='text-center'>Export Log<br>Export History</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n\n";

    echo "<tbody>\n";
}




# Display main page data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    global  $URL_VIEW_FILE,   $URL_BACKUP, $URL_VIEW_RCH, $URL_UPDATE,
            $URL_VIEW_BACKUP, $BACKUP_RCH, $BACKUP_LOG,   $BACKUP_ELOG ;


# Set the Logs, ErrorLog and rch full path name
    $log_name  = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_LOG;
    $elog_name = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_ELOG;
    $rch_name  = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/rch/". $row['srv_name'] ."_". $BACKUP_RCH;

# Start of row
    echo "\n<tr>\n";  
    echo "<td><center>$count</center></td>\n";  

# Show VM Guest System name
    echo "\n<td class='dt-left'>";
    echo "<a href='" . $URL_UPDATE . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP . "'";
    echo " title='Click to view system info, $WOS $WVER system - " . $row['srv_note'] . "'>";
    echo $row['srv_name']  . "</a>&nbsp;&nbsp;"; 
    $WOS   = sadm_clean_data($row['srv_osname']);
    echo "<br>" . $row['srv_desc'];
    echo "\n</td>\n";

# Show VM Host System name
    echo "<td class='dt-left'>";
    echo "<a href='" . $URL_UPDATE . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP . "'";
    echo " title='Click to view system info, $WOS $WVER system - " . $row['srv_note'] . "'>";
    echo $row['srv_name']  . "</a>&nbsp;&nbsp;"; 
    $WOS   = sadm_clean_data($row['srv_osname']);
    echo "<br>" . $row['srv_desc'];
    echo "</td>\n";


# Show Last Execution Rear Backup Date/Time & Check if overdue.
    if (! file_exists($rch_name))  {                                    # No RCH Found,No backup yet
        echo "<td align=center>No export yet";  
    }else{
        $file = file("$rch_name");                                      # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$calert,$ctype,$ccode) = explode(" ",$lastline);
        $now = time(); 
        $your_date = strtotime(str_replace(".", "-",$cdate1));
        $datediff = $now - $your_date;
        $backup_age = round($datediff / (60 * 60 * 24));
        if ($backup_age > SADM_REAR_BACKUP_INTERVAL) { 
            $tooltip = "Backup is " .$backup_age. " days old, greater than the threshold of " .SADM_REAR_BACKUP_INTERVAL. " days.";
            echo "<td align=left style='color:red' bgcolor='#DAF7A6'><b>";
            echo "<span data-toggle='tooltip' title='"  . $tooltip . "'>";
            echo "$cdate1" . '<br>' . substr($ctime1,0,5) ;
            echo "</span>"; 
        }else{
            $tooltip = "Backup is " .$backup_age. " days old, will have a tinted background, if greater than " .SADM_REAR_BACKUP_INTERVAL. " days.";
            echo "<td align='left'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "$cdate1" . '<br>' . substr($ctime1,0,5) ; 
            echo "</span>"; 
        }
    }
    #echo "</font></td>\n";  
    echo "</b></font>\n";  

# Status of Last Backup
    if (file_exists($rch_name)) {
        $file = file("$rch_name");                                      # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH
        list($cserver, $cdate1, $ctime1, $cdate2, $ctime2, $celapse, $cname, $calert, $ctype, $ccode) = explode(" ", $lastline);
    } else {
        $ccode = 9;                                                     # No Log, Backup never ran
    }
    switch ($ccode) {
        case 0:
            $tooltip = 'ReaR backup completed with success.';
            echo "\n<td class='dt-center'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "Success</span>\n";
            break;
        case 1:
            $tooltip = 'ReaR backup terminated with error.';
            echo "\n<td class='dt-center'  style='color:red' bgcolor='#DAF7A6'><b>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "Failed</span></b>\n";
            break;
        case 2:
            $tooltip = 'ReaR backup is actually running.';
            echo "\n<td class='dt-center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip'  title='" . $tooltip . "'>";
            echo "Running</span>";
            break;
        default:
            $tooltip = "Unknown status - code: " . $ccode;
            echo "\n<td class='dt-center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "Unknown</span>";
            break;
    }
    echo "</td>\n";

# Show Virtual Machine Type (VB=VirtualBox VW=VMWare KVM=Kernel Virt,...)
    echo "<td class='dt-left'>";
    echo "<a href='" . $URL_UPDATE . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP . "'";
    echo " title='Click to view system info, $WOS $WVER system - " . $row['srv_note'] . "'>";
    #echo $row['srv_name']  . "</a>&nbsp;&nbsp;"; 
    echo "VBOX</a>&nbsp;&nbsp;"; 
    $WOS   = sadm_clean_data($row['srv_osname']);
    #echo "<br>" . $row['srv_desc'];
    echo "</td>\n";

# Show Guest Server Version
    echo "<td class='dt-body-center'>" . nl2br( $row['srv_rear_ver']) . "</td>\n";  


# Schedule Update Button
    $ipath = '/images/UpdateButton.png';
    if ($row['srv_img_backup'] == TRUE) {                                  # Is Server Active
        $tooltip = 'Schedule is active, click to edit backup configuration.';
        echo "\n<td style='color: green' class='dt-center'><b>Y ";
    } else {                                                              # If not Activate
        $tooltip = 'Schedule is inactive, click to edit backup configuration.';
        echo "\n<td class='dt-center' style='color:red' bgcolor='#DAF7A6'><b>N ";
    }
    echo "<a href='" . $URL_BACKUP . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP . "'>";
    echo "\n<span data-toggle='tooltip' title='" . $tooltip . "'>";
    echo "\n<button type='button'>Update</button>";             # Display Delete Button
    echo "</a></span></b></td>";

# Show if System is sporadic or not
   if ($row['srv_sporadic'] == TRUE ) {
       echo "\n<td class='dt-center'>Yes</td>";
   }else{
       echo "\n<td class='dt-center'>No</td>";
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
    #echo "</td>\n";  
    echo "<br>";  

# Rear Backup Occurrence
    #echo "<td class='dt-center'>";
    if ($row['srv_img_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_img_dom'], $row['srv_img_month'],
            $row['srv_img_dow'], $row['srv_img_hour'], $row['srv_img_minute']);
        echo $STR_SCHEDULE ;
    }else{
        echo " ";
    }
    echo "</td>\n"; 

# Calculate Current Backup Size. 
    $backup_size = 0 ; $num_backup_size = 0 ;
    if (file_exists($log_name)) {
        $pattern = "/Current backup size/i"; 
        if (preg_grep($pattern, file($log_name))) {
            $bstring     = implode (" ", preg_grep($pattern, file($log_name)));
            $barray      = explode (" ", $bstring) ;
            $backup_size = $barray[count($barray)-1];
            # Remove any alphanumeric character from string $previous_size
            $num_backup_size =  preg_replace('/[a-zA-Z]/','',$backup_size);

        }
    }

# Calculate Previous Backup Size. 
    $previous_size = 0 ; $num_previous_size = 0 ;
    if (file_exists($log_name)) {
        $pattern = "/Previous backup size/i";
        if (preg_grep($pattern, file($log_name))) {
            $bstring       = implode (" ", preg_grep($pattern, file($log_name)));
            $barray        = explode (" ", $bstring) ;
            $previous_size = $barray[count($barray)-1];
            # Remove any alphanumeric character from string $previous_size
            $num_previous_size = preg_replace('/[a-zA-Z]/','', $previous_size);
            #echo "num_previous size: " . $num_previous_size;
        }
    }

# Show Backup Size
    if (($num_backup_size == 0 || $num_previous_size == 0) && (SADM_REAR_BACKUP_DIF != 0)) {
            echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><b>" . $backup_size . "</b></td>\n";  
    }else{
        #echo "PCT = (($num_backup_size - $num_previous_size) / $num_previous_size) * 100";
        $PCT = (($num_backup_size - $num_previous_size) / $num_previous_size) * 100;
        if (number_format($PCT,1) == 0.0) {
            echo "<td align='center'>" . $backup_size . "</td>\n"; 
        }else{
            if (number_format($PCT,0) >= SADM_REAR_BACKUP_DIF) {
                echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><b>" . $backup_size . "&nbsp;(+" .number_format($PCT,1). "%)</b></td>\n"; 
            }else{
                if (number_format($PCT,0) <= (SADM_REAR_BACKUP_DIF * -1)) {
                    echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><b>" . $backup_size . "&nbsp;("  .number_format($PCT,1). "%)</b></td>\n";
                }else{
                    if ($PCT < 0) {
                        echo "<td align='center'>" . $backup_size . "&nbsp;("  .number_format($PCT,1). "%)</td>\n"; 
                    }else{ 
                        echo "<td align='center'>" . $backup_size . "&nbsp;(+" .number_format($PCT,1). "%)</td>\n"; 
                    }
                }
            }
        }
    }

# Show Previous Backup Size
    if (($num_backup_size == 0 || $num_previous_size == 0) && (SADM_REAR_BACKUP_DIF != 0)) {
        echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><b>" . $previous_size . "</b></td>\n";  
    }else{
        echo "<td align='center'>" . $previous_size . "</td>\n";
    }

# Display link to view Rear Main Backup log
    echo "<td class='dt-center'>";
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View Backup Log'>[log]</a>&nbsp;";
    }else{
        echo "[NoLog]&nbsp;";
    }

# Display link to view ReaR backup Error log (If exist)
    if ((file_exists($elog_name)) and (file_exists($elog_name)) and (filesize($elog_name) != 0)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $elog_name . "'" ;
        echo " title='View ReaR error Log'>[elog]</a>&nbsp;";
    }

# Display link to view Rear Backup rch file
    $rch_www_name  = $row['srv_name'] . "_$BACKUP_RCH";
    if (file_exists($rch_name)) {
        echo "<a href='" . $URL_VIEW_RCH . "?host=" . $row['srv_name'] . "&filename=" . $rch_www_name . "'" ;
        echo " title='View Backup History (rch) file'>[rch]</a>";
    }else{
        echo "&nbsp;[NoRCH]";
    }
    echo "</td>\n";

    echo "</tr>\n"; 
}




# PHP MAIN START HERE
# ==================================================================================================

# Get all active systems from the SADMIN Database
    $sql = "SELECT * FROM server where srv_vm = True order by srv_name;";
    $result=mysqli_query($con,$sql) ;     
    $NUMROW = mysqli_num_rows($result);                                 # Get Nb of rows returned
    if ($NUMROW == 0)  {                                                # If No Server found
        $err_msg = "<br>No active server found in database";            # Construct msg to user
        $err_msg = $err_msg . mysqli_error($con) ;                      # Add MySQL Error Msg
        if ($DEBUG) {                                                   # In Debug Insert SQL in Msg
            $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query ;
        }
        sadm_fatal_error($err_msg);                                     # Display Error & Go Back
        exit();  
    }

    # Show ReaR schedule page heading
    display_lib_heading("NotHome","Virtual Box Export Status"," ",$WVER);
    setup_table();                                                      # Create HTML Table/Heading
    
    # Loop Through Retrieved Data and Display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table

    echo "<center>Only active virtual machive are shown on this page.</center>";
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
