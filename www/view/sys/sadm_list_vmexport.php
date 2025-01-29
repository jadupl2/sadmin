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
# ==================================================================================================
#
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
    padding: 12px 15px;
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


#===================================================================================================
#                                       Local Variables
#===================================================================================================
$DEBUG              = False ;                                           # Debug Activated True/False
$WVER               = "1.3" ;                                           # Current version number
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

    #echo "<div id='SimpleTable'>\n"; 
    echo "<div id='MyTable'>\n"; 
    echo "<table class='content-table'>\n" ; 
    
    #    echo "<table bgcolor='black' width='1100' border=1>\n" ; 
    #echo "<table id='sadmTable' row-border width='100%'>\n";   
    #echo '<table id="sadmTable" class="display" row-border width="100%">';   
    #echo "<table row-border width='100%'>\n";   

    echo "\n<thead>\n";
    echo "  <tr align=left bgcolor='grey'>\n";
    echo "      <th width=12>No</th>\n";
    echo "      <th width=60>VmName</th>\n";
    echo "      <th width=60>Guest Version</th>\n";
    echo "      <th width=60>HostName</th>\n";
    echo "      <th width=150>Date & Duration</th>\n";
    echo "      <th width=50>Status</th>\n";
    echo "      <th width=60>Log & Hist.</th>\n";
    echo "      <th width=70>Export<br>Schedule</th>\n";
    echo "      <th width=120>Next Export</th>\n";
    echo "      <th width=240>Occurrence</th>\n";
    echo "      <th width=50>Export Size</th>\n";
    echo "      <th width=50>Prev. Size</th>\n";
    echo "  </tr>\n"; 
    echo "</thead>\n";

    echo "\n<tfoot>\n";
    echo "  <tr align=left bgcolor='lightgrey'>\n";
    echo "      <th width=12>No</th>\n";
    echo "      <th width=60>VmName</th>\n";
    echo "      <th width=60>Guest Version</th>\n";
    echo "      <th width=60>HostName</th>\n";
    echo "      <th width=150>Date & Duration</th>\n";
    echo "      <th width=50>Status</th>\n";
    echo "      <th width=60>Log & Hist.</th>\n";
    echo "      <th width=70>Export<br>Schedule</th>\n";
    echo "      <th width=120>Next Export</th>\n";
    echo "      <th width=240>Occurrence</th>\n";
    echo "      <th width=50>Export Size</th>\n";
    echo "      <th width=50>Prev. Size</th>\n";
    echo "  </tr>\n"; 
    echo "</tfoot>\n\n";
    echo "<tbody>\n";
}




# Display Virtual Box Export Status Page
#===================================================================================================
function display_data($count, $row) {
    global  $URL_VIEW_FILE, $URL_VIEW_RCH, $URL_UPDATE, $URL_SERVER_INFO, 
            $URL_VIEW_VBEXPORT, $EXPORT_SCRIPT ,$URL_EXPORT_SCHED;


    # Set the Logs, ErrorLog and rch full path name
    $log_dir   = SADM_WWW_DAT_DIR ."/". $row['srv_vm_host'] ."/log/";
    $rch_dir   = SADM_WWW_DAT_DIR ."/". $row['srv_vm_host'] ."/rch/";
    $log_name  = $log_dir . $row['srv_vm_host'] . $EXPORT_SCRIPT . $row['srv_name'] . ".log";
    $elog_name = $log_dir . $row['srv_vm_host'] . $EXPORT_SCRIPT . $row['srv_name'] . ".elog";
    $rch_name  = $rch_dir . $row['srv_vm_host'] . $EXPORT_SCRIPT . $row['srv_name'] . ".rch";


    # Export counter
    echo "\n<tr align=left bgcolor='lightgrey'>\n";  
    echo "<td>$count</td>\n";  


    # Virtual machine name
    echo "<td>";
    echo "<a href='" .$URL_SERVER_INFO. "?sel=" .$row['srv_name']. "&back=" .$URL_VIEW_VBEXPORT. "'";
    if ($row['srv_desc']   != "") { $sysinfo = $row['srv_desc'] ; }else{ $sysinfo=""; };
    if ($row['srv_note']   != "") { $sysinfo = $sysinfo .', '.  $row['srv_note']    ; };
    if ($row['srv_osname'] != "") { $sysinfo = $sysinfo .', '.  ucwords(strtolower($row['srv_osname'])) ; };
    if ($row['srv_osversion'] != "") { $sysinfo = $sysinfo . "&nbsp;" . $row['srv_osversion']  ; };
    echo " title='" . $sysinfo . "'>" . $row['srv_name'] ."</a></td>\n";


    # Show Virtual Machine Type (VB=VirtualBox VW=VMWare KVM=Kernel Virt,...) & Guest version 
    echo "<td>";
    echo "<a href='" .$URL_SERVER_INFO. "?sel=" .$row['srv_name']. "&back=" .$URL_VIEW_VBEXPORT. "'";
    echo " title='" . $sysinfo . "'>VBOX</a>&nbsp;&nbsp;" . $row['srv_vm_version'] . "</td>\n";  
    

    # System Hosting the Virtual machine.
    echo "<td>";
    echo "<a href='" . $URL_SERVER_INFO ."?sel=". $row['srv_vm_host'] ."&back=". $URL_VIEW_VBEXPORT ."'";
    echo " title='Click to view system info, system'>" . $row['srv_vm_host']  . "</a></td>\n";


    # Show Last export Date/Time & duration.
    # Check age of export and highlight if days between export exceed interval.
    if (! file_exists($rch_name))  {                          # No RCH Found,No backup yet
        echo "<td align=left>No export yet</td>";  
    }else{
        $file = file("$rch_name");                            # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                     # Extract Last line of RCH
        $rch_array = explode(" ",$lastline);
        $now = time();                                                  # Current epoch time
        $your_date = strtotime(str_replace(".", "-",$rch_array[1])); 
        $datediff  = $now - $your_date;                                 # Diff. between now & export
        $backup_age = round($datediff / (60 * 60 * 24));           # Days since last export 
        if ($backup_age > SADM_VM_EXPORT_INTERVAL) {                    # exportAge>accepted interval
            $tooltip = "Export is " .$backup_age. " days old, greater than the threshold of " .SADM_VM_EXPORT_INTERVAL. " days.";
            echo "<td align=left style='color:red' bgcolor='#DAF7A6'><b>";
            echo "<span data-toggle='tooltip' title='"  . $tooltip . "'>";
        }else{
            $tooltip = "Export is " .$backup_age. " days old, cell will be highlighted if export is older than " .SADM_VM_EXPORT_INTERVAL. " days.";
            echo "<td align=left><span data-toggle='tooltip' title='" . $tooltip . "'>";
        }
        echo "$rch_array[1] " . $rch_array[5];
        echo "</span></td>"; 
    }
    echo "\n";  


    # Status of Last Backup (Check export last line, the last field in the '.rch' history file.
    if (file_exists($rch_name)) {
        $file = file("$rch_name");                            # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                     # Extract Last line of RCH
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$calert,$ctype,$ccode) = explode(" ", $lastline);
    } else {
        $ccode = 9;                                                     # No rch, export never ran
    }
    switch ($ccode) {
        case 0:
            $tooltip = 'Export completed with success.';
            echo "<td align=left><span data-toggle='tooltip' title='" .$tooltip. "'>Success</span>";
            break;
        case 1:
            $tooltip = 'Export terminated with error.';
            echo "<td align=left style='color:red' bgcolor='#DAF7A6'><b>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>Failed</span>";
            break;
        case 2:
            $tooltip = 'Export is actually running.';
            echo "<td align=left style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip'  title='" . $tooltip . "'>Running</span>";
            break;
        default:
            $tooltip = "Not available, not run yet.";
            echo "<td align=left><span data-toggle='tooltip' title='" . $tooltip . "'>N/A</span>";
            break;
    }
    echo "</td>\n";


    # Display link to view export log
    echo "<td>";
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'" ;
        echo " title='View export Log'>[log]</a>&nbsp;";
    }else{
        echo "\n<span data-toggle='tooltip' title='" . $tooltip . "'>[N/A]&nbsp;</span>";
    }


    # Display link to view export error log (If exist)
    if ((file_exists($elog_name)) and (filesize($elog_name) != 0)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $elog_name . "'" ;
        echo " title='View export error Log'>[elog]</a>&nbsp;";
    }


    # Display link to view export history (rch) file
    #$rch_www_name  = $row['srv_name'] . "_$BACKUP_RCH";
    $rch_www_name = $row['srv_vm_host'] . $EXPORT_SCRIPT . $row['srv_name'] . ".rch";
    if (file_exists($rch_name)) {
        echo "<a href='" .$URL_VIEW_RCH. "?host=" .$row['srv_vm_host']. "&filename=" .$rch_www_name. "'";
        echo " title='View export history (rch) file'>[rch]</a>";
    }else{
        echo "[N/A]";
    }
    echo "</td>\n";


    # Schedule Update Button
    # Zero and an empty string are considered to be false. 
    # Any other numerical value or string is true. 
    #$ipath = '/images/UpdateButton.png';
    if ($row['srv_export_sched'] == True ) {                            # If Export Schedule Active
        $tooltip = 'Schedule is active, click to edit export schedule.';
        echo "<td align=left style='color: green'<b>Y</b> ";
    }else{                                                              # If Schedule not Activate
        $tooltip = 'Schedule is inactive, click to activate export schedule.';
        echo "<td align=left style='color:red' bgcolor='#DAF7A6'><b>N</b> ";
    }
    echo "<a href='" .$URL_EXPORT_SCHED. "?sel=" . $row['srv_name'];
    echo "&back=" .$URL_VIEW_VBEXPORT. "'>";
    echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
    echo "<button type='button'>Update</button></a></span></td>\n";


    # Show if it's a sporadic system or not.
    #if ($row['srv_sporadic'] == TRUE ) {
    #    echo "\n<td class='dt-center'>Yes</td>";
    #}else{
    #    echo "\n<td class='dt-center'>No</td>";
    #}


    # Next export date
    echo "<td>";
    if ($row['srv_export_sched'] == True) { 
        #echo $row['srv_export_dom'] ." _ ". $row['srv_export_mth']." _ ". $row['srv_export_dow']  ." _ ". 
        #     $row['srv_export_hrs'] ." _ ". $row['srv_export_min'];
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
    if (($num_export_size == 0 || $num_previous_size == 0) && (SADM_VM_EXPORT_DIF != 0)) {
        echo "<td align=left style='color:red' bgcolor='#DAF7A6'>" .$export_size;
    }else{
        #echo "PCT = (($num_export_size - $num_previous_size) / $num_previous_size) * 100";
        $PCT = (($num_export_size - $num_previous_size) / $num_previous_size) * 100;
        if (number_format($PCT,1) == 0.0) {
            echo "<td align=left>" . $export_size ; 
        }else{
            if (number_format($PCT,0) > SADM_VM_EXPORT_DIF) {
                echo "<td align=left style='color:red' bgcolor='#DAF7A6'><b>" .$export_size. "&nbsp;(+" .number_format($PCT,1). "%)</b>"; 
            }else{
                if (number_format($PCT,0) < (SADM_VM_EXPORT_DIF * -1)) {
                    echo "<td align=left style='color:red' bgcolor='#DAF7A6'><b>" . $export_size . "&nbsp;("  .number_format($PCT,1). "%)</b>";
                }else{
                    if ($PCT < 0) {
                        echo "<td align=left>" . $export_size . "&nbsp;("  .number_format($PCT,1). "%)"; 
                    }else{ 
                        echo "<td align=left>" . $export_size . "&nbsp;(+" .number_format($PCT,1). "%)"; 
                    }
                }
            }
        }
    }
    echo "</td>\n"; 

# Show Previous Backup Size
    if (($num_export_size == 0 || $num_previous_size == 0) && (SADM_VM_EXPORT_DIF != 0)) {
        echo "<td align=left style='color:red' bgcolor='#DAF7A6'><b>" .$previous_size. "</b></td>\n";
    }else{
        echo "<td align=left>" . $previous_size . "</td>\n";
    }

}




# PAGE START HERE
# ==================================================================================================

    # Get all active virtual systems from the SADMIN Database
    # $sql = "SELECT * FROM server where srv_vm = True and srv_active = True order by srv_name;";
    $sql = "SELECT * FROM server where srv_vm = 1 order by srv_name;";
    $result=mysqli_query($con,$sql) ;     
    $NUMROW = mysqli_num_rows($result);                         # Get Nb of rows returned
    if ($NUMROW == 0)  {                                                # If No Server found
        $err_msg = "<br>No active server or no virtual system found in database"; # Msg to user
        $err_msg = $err_msg . mysqli_error($con) ;               # Add MySQL Error  to Msg
        if ($DEBUG) {                                                   # In Debug Insert SQL in Msg
            $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query ;
        }
        sadm_fatal_error($err_msg);                                # Display Error & Go Back
        exit();  
    }

    # Show Virtual system schedule status page heading
    display_lib_heading("NotHome","Virtual Box Export Status"," ",$WVER);
    setup_table();                                                      # Create HTML Table/Heading
    
    # Loop Through Retrieved Data and Display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table

    echo "<center>Only virtual machine are shown on this page.</center>";
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                         # Close MySQL & HTML Footer
?>
