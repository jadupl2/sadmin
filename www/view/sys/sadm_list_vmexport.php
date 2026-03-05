<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_list_vmexport.php
#   Version     :  1.0
#   Date        :  27 September 2024
#   Description :  List results of latest Virtual Box exports.
#   
#   2019 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2024_10_03 web v1.1 Practically usable only occurrence and next export date display missing.
#@2024_10_31 web v1.2 Permit to view the status of Virtual Box machine export.
#@2025_01_29 web v1.3 Was not showing the right VirtualBox Guest Addition version 
#@2025_03_25 web v1.5 Change more look of the page adding some more info
#@2025_04_10 web v1.6 Modify disposition on web page.
#@2025_05_07 web v1.7 Minor adjustments to web page layout.
#@2025_07_27 web v1.8 Change Legend at the bottom of the page & enhance layout.
#@2025_09_19 web v1.9 Show only active systems and virtual machines.
#@2026_03_03 web v2.0 Add average execution time statistics..
# ==================================================================================================


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
    padding-top: 4px;
    padding-bottom: 4px;
    padding-left: 6px;
    padding-right: 6px;
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

#error_reporting(0); # Turn off
error_reporting(E_ALL); # Report all errors, warnings, and notices (recommended for development):
# Alternatively, using the integer value -1 achieves the same result error_reporting(-1); 
#error_reporting(E_ALL & ~E_NOTICE);   #  Report all errors except E_NOTICE:
#error_reporting(E_ERROR | E_WARNING | E_PARSE);  # Report only fatal errors, warnings, and parse errors:

# Display errors on screen (development):
ini_set('display_errors', 1);  

# Hide errors from the screen (production) and log them instead: 
#ini_set('display_errors', 0);
#ini_set('log_errors', 1);

#===================================================================================================
#                                       Local Variables
#===================================================================================================
$DEBUG              = False ;                                           # Debug Activated True/False
$WVER               = "2.0" ;                                           # Current version number
$URL_HOME           = '/index.php';                                     # Site Main Page

# Server Static Data Maintenance
$URL_CREATE         = '/crud/srv/sadm_server_create.php';               # Create Page URL
$URL_UPDATE         = '/crud/srv/sadm_server_update.php';               # Update Page URL
$URL_DELETE         = '/crud/srv/sadm_server_delete.php';               # Delete Page URL
$URL_MAIN           = '/crud/srv/sadm_server_main.php';                 # Maintenance Main Page URL
$URL_SERVER         = '/view/srv/sadm_view_servers.php';                # View Servers List
$URL_SERVER_INFO    = '/view/srv/sadm_view_server_info.php';            # View Servers Info page
$URL_OSUPDATE       = '/crud/srv/sadm_server_osupdate.php';             # O/S Schedule Update URL
$URL_BACKUP         = '/crud/srv/sadm_server_rear_backup.php';          # Rear Schedule Update URL

$URL_VIEW_FILE      = '/view/log/sadm_view_file.php';                   # View File Content URL
$URL_VIEW_RCH       = '/view/rch/sadm_view_rchfile.php';                # View RCH File Content URL
$URL_VIEW_BACKUP    = "/view/sys/sadm_view_rear.php";                   # Rear Back Status Page
$URL_VIEW_VBEXPORT  = "/view/sys/sadm_list_vmexport.php";               # List VBox Export Status list 

$URL_REAR_REPORT    = "/view/daily_rear_report.html";                   # Rear Daily Report Page
$URL_BACKUP_REPORT  = "/view/daily_backup_report.html";                 # Daily backup status page
$URL_SCRIPTS_REPORT = "/view/daily_scripts_report.html";                # Scripts Daily Report Page
$CREATE_BUTTON      = False ;                                           # Yes Display Create Button

$URL_EXPORT_SCHED   = "/crud/srv/sadm_sched_vmexport.php";              # Edit export schedule page
$EXPORT_SCRIPT      = "_sadm_vm_export_";





# Display Virtual system export status page header
#===================================================================================================
function setup_table() {

    echo "<div id='MyTable'>\n"; 
    echo "<table class='content-table' border=1>\n" ; 
    
    echo "\n<thead>\n";
    echo "  <tr align=center bgcolor='grey'>\n";
    echo "      <th width=12>No</th>\n";
    echo "      <th width=60>VmName</th>\n";
    echo "      <th align='center' width=60>Guest Version</th>\n";
    echo "      <th width=60>VM Host</th>\n";
    echo "      <th align='center' width=110>Last Export</th>\n";
    echo "      <th align='center' width=60>Duration</th>\n";
    echo "      <th align='center' width=50>Status</th>\n";
    echo "      <th align='center' width=60>Log & Hist.</th>\n";
    echo "      <th align='center' width=70>Schedule</th>\n";
    echo "      <th align='center' width=110>Next Export</th>\n";
    echo "      <th align='left'   width=230>Occurrence</th>\n";
    echo "      <th align='center' width=60>Export Size</th>\n";
    echo "      <th align='center' width=60>Prev. Size</th>\n";
    echo "  </tr>\n"; 
    echo "</thead>\n";

    echo "\n<tfoot>\n";
    echo "  <tr align=center bgcolor='grey'>\n";
    echo "      <th width=12>No</th>\n";
    echo "      <th width=60>VmName</th>\n";
    echo "      <th align='center' width=60>Guest Version</th>\n";
    echo "      <th width=60>VM Host</th>\n";
    echo "      <th align='center' width=110>Last Export</th>\n";
    echo "      <th align='center' width=60>Duration</th>\n";
    echo "      <th align='center' width=50>Status</th>\n";
    echo "      <th align='center' width=60>Log & Hist.</th>\n";
    echo "      <th align='center' width=70>Schedule</th>\n";
    echo "      <th align='center' width=110>Next Export</th>\n";
    echo "      <th align='left'   width=230>Occurrence</th>\n";
    echo "      <th align='center' width=60>Export Size</th>\n";
    echo "      <th align='center' width=60>Prev. Size</th>\n";
    echo "  </tr>\n"; 
    echo "</tfoot>\n\n";
    echo "<tbody>\n";
}




# Display Virtual Box Export Status Page
#===================================================================================================
function display_data($con) {
    global  $URL_VIEW_FILE, $URL_VIEW_RCH, $URL_UPDATE, $URL_SERVER_INFO, 
            $URL_VIEW_VBEXPORT, $EXPORT_SCRIPT ,$URL_EXPORT_SCHED, $DEBUG; 


    # Get all active virtual systems from the SADMIN Database
    $sql = "SELECT * FROM server where srv_vm = True and srv_active = True order by srv_name;";
    $result=mysqli_query($con,$sql) ;                                   # Execute SQL & Return obj.
    $NUMROW = mysqli_num_rows($result);                                 # Get Nb of rows returned
    if ( ($NUMROW == 0) or (! $result) )  {                             # If No Server found
        $err_msg = "<br>No active VM are found in database.";           # Msg to user
        $err_msg = $err_msg . mysqli_error($con) ;                      # Add MySQL Error to Msg
        if ($DEBUG) {                                                   # In Debug Insert SQL in Msg
            $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query ;
        }
        sadm_fatal_error($err_msg);                                     # Display Error & Go Back
        exit(1);  
    }


    # Loop Through Retrieved Data and Display each Row
    $count = 0;
    $total_seconds = 0 ;                                                # Total execution Time sec.
    $total_count   = 0 ;                                                # Nb execution finished 
    $lowest_time   = 0 ;                                                # Lowest execution time 
    $highest_time  = 0 ;                                                # Highest execution time   
         
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        
        # Set the Logs, ErrorLog and rch full path name
        $sysName = $row['srv_name']  ;                                  # Hostname of Guest 
        $sysHost = $row['srv_vm_host'] ;                                # Hostname of the VM Host
        $scriptName = pathinfo(SADM_VM_EXPORT_SCRIPT, PATHINFO_FILENAME); # Script without Extension
        $log_name  = SADM_WWW_DAT_DIR ."/". $sysHost ."/log/". $sysHost ."_". $scriptName ."_". $sysName .".log" ;
        $elog_name = SADM_WWW_DAT_DIR ."/". $sysHost ."/log/". $sysHost ."_". $scriptName ."_". $sysName .".elog";
        $rch_name  = SADM_WWW_DAT_DIR ."/". $sysHost ."/rch/". $sysHost ."_". $scriptName ."_". $sysName .".rch" ;
        if ($DEBUG) { 
            echo "\n<br>SADM_VM_EXPORT_SCRIPT  :" . SADM_VM_EXPORT_SCRIPT ; 
            echo "\n<br>scriptName             :" . $scriptName ;
            echo "\n<br>log_filename           :" . $log_name ; 
            echo "\n<br>elog_filename          :" . $elog_name ; 
            echo "\n<br>rch filename           :" . $rch_name ; 
        } 


        # Export counter
        $count+=1;                                                      # Incr Line Counter
        echo "\n<tr align=left bgcolor='lightgrey'>\n"; 
        echo "\n<td>$count</td>";  


        # Virtual machine name
        echo "\n<td>";
        echo "<a href='" .$URL_SERVER_INFO. "?sel=" .$row['srv_name']. "&back=" .$URL_VIEW_VBEXPORT. "'";
        if ($row['srv_desc']   != "")    { $sysinfo = $row['srv_desc'] ; }else{ $sysinfo=""; };
        if ($row['srv_note']   != "")    { $sysinfo = $sysinfo .', '.  $row['srv_note']    ; };
        if ($row['srv_osname'] != "")    { $sysinfo = $sysinfo .', '.  ucwords(strtolower($row['srv_osname'])) ; };
        if ($row['srv_osversion'] != "") { $sysinfo = $sysinfo . "&nbsp;" . $row['srv_osversion']  ; };
        echo " title='" . $sysinfo . "'>" . $row['srv_name'] ."</a></td>\n";


        # Show Virtual Machine Type (VB=VirtualBox VW=VMWare KVM=Kernel Virt,...) & Guest version 
        echo "<td>";
        echo "VBOX&nbsp;&nbsp;" . $row['srv_vm_version'] ;
        echo "</td>\n";  

        # System Hosting the Virtual machine.
        echo "<td>";
        echo "<a href='" . $URL_SERVER_INFO ."?sel=". $row['srv_vm_host'] ."&back=". $URL_VIEW_VBEXPORT ."'";
        echo " title='Click to view system info, system'>" . $row['srv_vm_host']  . "</a></td>\n";


        # System last export date, Get the last export date & time from the last line of the '.rch'.
        # Determine the number of days since the last export date.
        if (! file_exists($rch_name))  {                                    # If no '.rch' file.
            echo "<td align=center bgcolor='#DAF7A6'>Missing .rch</td>";  
        }else{
            $file      = file("$rch_name");                                 # Load export rch File 
            $lastline  = $file[count($file) - 1];                           # Extract Last line of RCH
            $rch_array = explode(" ",$lastline);                            # Split rch line into array
            $now       = time();                                            # Get Current epoch time
            $your_date = strtotime(str_replace(".", "-",$rch_array[1])); 
            $datediff  = $now - $your_date;                                 # Diff. between now & export
            $backup_age = round($datediff / (60 * 60 * 24));                # Days since last export 
            if ($backup_age > SADM_VM_EXPORT_INTERVAL) {                    # ExportAge>accepted interval
                $tooltip = "Export is " .$backup_age. " days old, greater than the threshold of " .SADM_VM_EXPORT_INTERVAL. " days.";
                echo "<td align=center style='color:red' bgcolor='#DAF7A6'><b>";
                echo "<span data-toggle='tooltip' title='"  . $tooltip . "'>";
            }else{
                $tooltip = "Export is " .$backup_age. " days old, cell will be highlighted if export is older than " .SADM_VM_EXPORT_INTERVAL. " days.";
                echo "<td align=center><span data-toggle='tooltip' title='" . $tooltip . "'>";
            }
            $export_time = substr($rch_array[2], 0, 5);
            echo "$rch_array[1] " . $export_time;
            echo "</span></td>"; 
        }
        echo "\n";  


        # Last export duration, check age of export and highlight if days between export exceed interval
        echo "<td align=center>";
        if (! file_exists($rch_name))  {                                # No RCH Found,No backup yet
            echo "No export yet";  
        }else{
            $file = file("$rch_name");                                  # Load RCH File in Memory
            $lastline = $file[count($file) - 1];                        # Extract Last line of RCH
            $rch_array = explode(" ",$lastline);                        # Split rch line in array
            echo $rch_array[5];                                         # Duration Time Ex: 00:10:40
        }
        echo "\n</td>";  

        # Need to give average execution time.
        if ($rch_array[5] != '........') {                              # Ignore job running
            $duration_sec = sadm_timeToSeconds($rch_array[5]) ;         # Convert time to seconds
            $total_seconds += $duration_sec ;                           # Add Duration to Total
            $total_count+=1;                                            # Terminated jobs count
            if ($lowest_time == 0 || $duration_sec <= $lowest_time) {   # If first Lowest
                $lowest_time    = $duration_sec ;
                $lowestduration = $rch_array[5] ;
            }
            if ($highest_time == 0 || $duration_sec > $highest_time) {  # If first Highest
                $highest_time    = $duration_sec ;
                $highestduration = $rch_array[5] ;
            }
        } 


        # Last export status.
        # Array $cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$calert,$ctype,$ccode
        if (file_exists($rch_name)) {
            $file = file("$rch_name");                                      # Load RCH File in Memory
            $lastline = $file[count($file) - 1];                            # Extract Last line of RCH
            $lastStatus = explode(" ", $lastline);                          # Load last line in array
            $ccode = $lastStatus[9];                                        # Status return code
        } else {
            $ccode = 9;                                                     # No rch, export never ran
        }
        switch ($ccode) {
            case 0:
                $tooltip = 'Export completed with success.';
                echo "\n<td align=center><span data-toggle='tooltip' title='" .$tooltip. "'>Success</span>";
                break;
            case 1:
                $tooltip = 'Export terminated with error.';
                echo "\n<td align=center style='color:red' bgcolor='#DAF7A6'><b>";
                echo "<span data-toggle='tooltip' title='" . $tooltip . "'>Failed</span>";
                break;
            case 2:
                $tooltip = 'Export is actually running.';
                echo "<td align=center style='color:red' bgcolor='#DAF7A6'>";
                echo "<span data-toggle='tooltip'  title='" . $tooltip . "'>Running</span>";
                break;
            default:
                $tooltip = "Not run yet.";
                echo "<td align=center><span data-toggle='tooltip' title='" . $tooltip . "'>N/A</span>";
                break;
        }
        echo "</td>\n";


        # Link to view export log
        echo "<td align='center'>";
        if (file_exists($log_name)) {
            echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
            echo " title='View export Log'>[log]</a>&nbsp;";
        }else{
            echo "\n<span data-toggle='tooltip' title='" . $tooltip . "'>[N/A]&nbsp;</span>";
        }


        # Link to view export error log (If exist)
        if ((file_exists($elog_name)) and (filesize($elog_name) != 0)) {
            echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $elog_name . "'" ;
            echo " title='View export error Log'>[elog]</a>&nbsp;";
        }


        # Link to view export history (.rch) file (If exist)
        #$rch_www_name = $row['srv_vm_host'] . $EXPORT_SCRIPT . $row['srv_name'] . ".rch" ;
        if (file_exists($rch_name)) {
            echo "<a href='" .$URL_VIEW_RCH. "?host=" .$row['srv_vm_host']. "&filename=" .$rch_name. "'";
            echo " title='View export history (rch) file'>[rch]</a>";
        }else{
            echo "[N/A]";
        }
        echo "</td>\n";


        # Schedule Update Button
        # Zero and an empty string are considered to be false (without schedule). 
        # Any other numerical value or string is true (Schedule exist). 
        if ($row['srv_export_sched'] == True ) {                            # If Export Schedule Active
            $tooltip = 'Schedule is active, click to edit export schedule.';
            echo "<td align=center style='color: green'<b>Y</b> ";
            #echo "<td align='center' style='color: green'>";
        }else{                                                              # If Schedule not Activate
            $tooltip = 'Schedule is inactive, click to activate export schedule.';
            echo "<td align='center' style='color:red' bgcolor='#DAF7A6'> ";
        }
        echo "<a href='" .$URL_EXPORT_SCHED. "?sel=" . $row['srv_name'];
        echo "&back=" .$URL_VIEW_VBEXPORT. "'>";
        echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
        echo "<button type='button'>Update</button></a></span></td>\n";


        # Next export date
        echo "<td align='center'>";
        if ($row['srv_export_sched'] == True) { 
            list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_export_dom'], 
               $row['srv_export_mth'] ,$row['srv_export_dow'],
               $row['srv_export_hrs'] ,$row['srv_export_min']);
            echo $UPD_DATE_TIME . "</td>\n";
        }else{
            echo "No Schedule</td>\n";
        }


        # Export occurrence 
        echo "<td>";
        if ($row['srv_export_sched'] == True ) { 
            list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_export_dom'], 
                $row['srv_export_mth'], $row['srv_export_dow'], 
                $row['srv_export_hrs'], $row['srv_export_min']);
            echo $STR_SCHEDULE . "</td>\n";
        }else{
            echo "No Schedule</td>\n";
        }


        # Get current export size. 
        $export_size = 0 ; $num_export_size = 0 ;
        if (file_exists($log_name)) {
            $pattern = "/Current export size/i"; 
            if (preg_grep($pattern, file($log_name))) {
                $bstring     = implode (" ", preg_grep($pattern, file($log_name)));
                $barray      = explode (" ", $bstring) ;
                $export_size = $barray[count($barray)-1];
                # Remove any alphanumeric character from string $previous_size
                $num_export_size =  preg_replace('/[a-zA-Z]/','',$export_size);
            }
        }
        #echo "num_current size: " . $num_export_size . "\n" ; 

        # Get previous export size.
        $previous_size = 0 ; $num_previous_size = 0 ;
        if (file_exists($log_name)) {
            $pattern = "/Previous export size/i";
            if (preg_grep($pattern, file($log_name))) {
                $bstring       = implode (" ", preg_grep($pattern, file($log_name)));
                $barray        = explode (" ", $bstring) ;
                $previous_size = $barray[count($barray)-1];
                # Remove any alphanumeric character from string $previous_size
                $num_previous_size = preg_replace('/[a-zA-Z]/','', $previous_size);
            }
        }
        #echo "num_previous size: " . $num_previous_size .  "\n"; 

        # Show current export size.
        $BG='#DAF7A6';                                                      # Catch eye attention color
        if (($num_export_size == 0 || $num_previous_size == 0) && (SADM_VM_EXPORT_DIF != 0)) {
            echo "<td align='center' style='color:red' bgcolor='" .$BG. "'>" .$export_size;
        }else{
            #echo "PCT = (($num_export_size - $num_previous_size) / $num_previous_size) * 100";
            $PCT = (($num_export_size - $num_previous_size) / $num_previous_size) * 100;
            if (number_format($PCT,1) == 0.0) {
                echo "<td align='center'>" . $export_size ; 
            }else{
                if (number_format($PCT,0) > SADM_VM_EXPORT_DIF) {
                    echo "<td align='center' style='color:red' bgcolor='" .$BG. "'><b>"   .$export_size. "&nbsp;(+" .number_format($PCT,1). "%)</b>"; 
                }else{
                    if (number_format($PCT,0) < (SADM_VM_EXPORT_DIF * -1)) {
                        echo "<td align='center' style='color:red'  bgcolor='" .$BG. "'>" .$export_size . "&nbsp;("  .number_format($PCT,1). "%)</b>";
                    }else{
                        echo "<td align='center'>" . $export_size . "&nbsp;("  .number_format($PCT,1). "%)"; 
                    }
                }
            }
        }
        echo "</td>\n"; 

        # Show Previous Backup Size
        if (($num_export_size == 0 || $num_previous_size == 0) && (SADM_VM_EXPORT_DIF != 0)) {
            echo "<td align='center' style='color:red' bgcolor='" .$BG. "'><b>" .$previous_size. "</b></td>\n";
        }else{
            echo "<td align='center'>" . $previous_size . "</td>\n";
        }
    }

    echo "\n<center>";
    echo "<b>Only active virtual systems are shown</br>\n";             # Sub-title 

    # Average script execution time
    $average = $total_seconds / $total_count ;                          # Total Sec. / Nb. execution
    $script_average = sadm_secondsToHHMMSS($average) ;                  # Convert Sec. to HH:MM:SS
    $script_name = pathinfo($rch_name,PATHINFO_FILENAME) ;              # Remove extension of file
    if ($DEBUG) { 
        echo "\nAverage = $average - total_seconds = $total_seconds"; 
        echo "\nTotal_count = $total_count - Script_average = $script_average";
    } 
    echo "\n<b>";
    echo "Average execution time is $script_average - ";
    if ( substr($lowestduration, 0, 3) == "00:") {
        $lowestduration= substr($lowestduration,3, strlen($lowestduration));
    }       
    if ( substr($highestduration, 0, 3) == "00:") {
        $highestduration= substr($highestduration,3, strlen($highestduration));
    }       
    echo "(lowest : $lowestduration - highest : $highestduration)";
    echo "</center></b>\n";

    echo "\n</tbody>\n</table>\n";    
}




# Add legend at the bottom of the page
#===================================================================================================
function export_legend()
{
    #echo  "\n\n<center><img src='/images/pencil2.gif'></center>\n"; 
    echo "<hr>\n<br>\n"; 
    echo "<b>Row have a colored background when :  <br>\n"; 
    echo "1- The export have failed.<br>\n";
    echo "2- The latest & previous export size differ for more than " .SADM_VM_EXPORT_DIF. "%.<br>\n";
    echo "&nbsp;&nbsp;&nbsp;&nbsp;This percentage is set in '\$SADMIN/cfg/sadmin.cfg' by the value of 'SADM_VM_EXPORT_DIF'.<br>\n";
    echo "3- If the last export is older than " .SADM_VM_EXPORT_INTERVAL. " days.<br>\n";
    echo "&nbsp;&nbsp;&nbsp;&nbsp;Set by the value of 'SADM_VM_EXPORT_INTERVAL' in '\$SADMIN/cfg/sadmin.cfg'.<br>\n";
    echo "<br>\nExport are recorded on '" . SADM_VM_EXPORT_NFS_SERVER . "' in '" .SADM_VM_EXPORT_MOUNT_POINT. "' directory.";
    echo  "</b><br>\n";
}





# PAGE START HERE
# ==================================================================================================

    # Show Virtual system schedule status page heading
    $TITLE1 = "Virtual System Export Status";                           # Main Tile
    $TITLE2 = "";                                                       # Sub-title 
    display_lib_heading("NotHome","$TITLE1","$TITLE2",$WVER);           # Display Page Title
    
    setup_table();                                                      # Show Table Heading/Footer
    display_data($con);                                                 # Display VM export status
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    export_legend();                                                    # Display Legend               
    std_page_footer($con)                                               # Close MySQL & HTML Footer

?>
