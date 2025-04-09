<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_rear.php
#   Version     :  1.0
#   Date        :  6 August 2019
#   Description :  List active servers and associated with a ReaR backup schedule (if any).
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
# 2019_08_26 web v1.0 ReaR backup status page - Initial version of ReaR backup Status Page
# 2019_08_26 web v1.1 ReaR backup status page - First Release of Rear Backup Status Page.
# 2019_09_20 web v1.2 ReaR backup status page - Show History (RCH) content using same uniform way.
# 2019_10_15 web v1.3 ReaR backup status page - Add Architecture, O/S Name, O/S Version to page
# 2020_01_13 web v1.4 ReaR backup status page - Change column disposition and show ReaR version no. of systems.
# 2020_01_14 web v1.5 ReaR backup status page - Don't show MacOS System on page (Not supported by ReaR).
# 2020_03_05 web v1.6 ReaR backup status page - When mouse over server name (Show more information).
# 2020_07_29 web v1.7 ReaR backup status page - Remove system description to allow more space on each line.
# 2020_13_13 web v1.8 ReaR backup status page - Add link in heading to view ReaR Daily Report.
# 2022_09_12 web v1.9 ReaR backup status page - Show if schedule is activated or not.
# 2022_09_12 web v2.0 ReaR backup status page - Show link to error log (if it exist.).
# 2022_09_12 web v2.1 ReaR backup status page - Display the first 50 systems instead of 25.
# 2022_09_20 web v2.2 ReaR backup status page - Move ReaR supported architecture msg to heading.
# 2023_02_16 web v2.3 ReaR backup status page - Revamp of the ReaR backup status page.
# 2023_04_22 web v2.4 ReaR backup status page - Alert are now shown in a tinted background for emphasis.
# 2023_04_23 web v2.5 ReaR backup status page - Now include size of backup & new layout.
# 2023_04_27 web v2.6 ReaR backup status page - Combine 'Last Backup Date' & 'Duration'.
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
$WVER               = "2.6" ;                                           # Current version number
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

    echo "\n\n<div id='SimpleTable'>"; 
    
    #echo '<table id="sadmTable" class="display" row-border width="100%">';   
    #echo '<table id="sadmTable" row-border width="100%">';   
    #echo "\n<table class='content-table' width='100%' border=1>\n" ; 

    echo "\n<table class='content-table'>\n" ;

    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th align='center' width=20>No</th>";
    echo "\n<th align='left'>System</th>";
    echo "\n<th align='center'>Last Backup</th>";
    echo "\n<th align='center'>Duration</th>";
    echo "\n<th align='center'>Status</th>";
    echo "\n<th align='center'>Log & Hist.</th>";
    echo "\n<th align='center'>Rear<br>Schedule</th>";
    echo "\n<th align='center'>Sporadic</th>";
    echo "\n<th align='center'>ReaR</th>";
    echo "\n<th align='center'>Next Backup</th>";
    echo "\n<th align='center'>Occurrence</th>";
    echo "\n<th align='center'>Current Size</th>";
    echo "\n<th align='center'>Prev. Size</th>";
    echo "\n</tr>"; 
    echo "\n</thead>\n";

    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th align='center' width=20>No</th>";
    echo "\n<th align='left'>System</th>";
    echo "\n<th align='center'>Last Backup</th>";
    echo "\n<th align='center'>Duration</th>";
    echo "\n<th align='center'>Status</th>";
    echo "\n<th align='center'>Log & Hist.</th>";
    echo "\n<th align='center'>Rear<br>Schedule</th>";
    echo "\n<th align='center'>Sporadic</th>";
    echo "\n<th align='center'>ReaR</th>";
    echo "\n<th align='center'>Next Backup</th>";
    echo "\n<th align='center'>Occurrence</th>";
    echo "\n<th align='center'>Current Size</th>";
    echo "\n<th align='center'>Prev. Size</th>";
    echo "\n</tr>"; 
    echo "\n</tfoot>\n";

    echo "\n<tbody>\n";
}




# Display main page data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    
    global  $URL_HOST_INFO, $URL_VIEW_FILE, $URL_BACKUP, $URL_VIEW_RCH, $URL_UPDATE,
            $URL_VIEW_BACKUP, $BACKUP_RCH, $BACKUP_LOG, $BACKUP_ELOG ;

    # ReaR Not Supported on MacOS and ARM system (Raspberry Pi), return to caller
    if ((($row['srv_arch']   != "x86_64") and ($row['srv_arch'] != "i686")) 
        or ($row['srv_ostype'] == "darwin")) {
        return ; 
    } 

    # Set the Logs, ErrorLog and rch full path name
    $log_name  = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_LOG;
    $elog_name = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_ELOG ;
    $rch_name  = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/rch/". $row['srv_name'] ."_". $BACKUP_RCH;

    # Start of row
    echo "\n<tr>\n";  

    # Line Counter
    echo "\n<td align='center'>" . $count . "</td>";  

    # Show System name
    echo "<td>";
    echo "<a href='" . $URL_UPDATE . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP . "'";
    echo " title='Click to view system info, $WOS $WVER system - " . $row['srv_note'] . "'>";
    echo $row['srv_name']  . "</a>&nbsp;&nbsp;"; 
    $WOS   = sadm_clean_data($row['srv_osname']);
    echo "<br>" . $row['srv_desc'];
    echo "</td>\n";


    # Last Rear Backup Date/Time & Check if overdue.
    if (! file_exists($rch_name))  {                                    # No RCH Found,No backup yet
        echo "<td align='center'>No backup yet";  
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
            echo "<td align='center' style='color:red' bgcolor='#DAF7A6'><b>";
            echo "<span data-toggle='tooltip' title='"  . $tooltip . "'>";
            echo "$cdate1" . '&nbsp;' . substr($ctime1,0,5) ;
            echo "</span>"; 
        }else{
            $tooltip = "Backup is " .$backup_age. " days old, will have a tinted background, if greater than " .SADM_REAR_BACKUP_INTERVAL. " days.";
            echo "<td align='center'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "$cdate1" . '&nbsp;' . substr($ctime1,0,5) ; 
            echo "</span>"; 
        }
    }
    echo "</font></td>\n";  

# Backup duration time
    echo "<td align='center'>";
    if (! file_exists($rch_name))  {                                    # If RCH File Not Found
        echo "&nbsp;</td>";
    }else{
        #echo "<td class='dt-center'>" . nl2br($celapse) . "</td>\n";  
        echo nl2br($celapse) . "</td>\n";  
    }

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
            echo "\n<td align='center'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "Success</span>\n";
            break;
        case 1:
            $tooltip = 'ReaR backup terminated with error.';
            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "Failed</span></b>\n";
            break;
        case 2:
            $tooltip = 'ReaR backup is actually running.';
            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip'  title='" . $tooltip . "'>";
            echo "Running</span>";
            break;
        default:
            $tooltip = "Unknown status - code: " . $ccode;
            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>";
            echo "Unknown</span>";
            break;
    }
    echo "</td>\n";



# Display link to view Rear Main Backup log
echo "<td align='center'>";
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
       echo "\n<td align='center'>Yes</td>";
   }else{
       echo "\n<td align='center'>No</td>";
   }

# Show ReaR Server Version
    echo "<td align='center'>" . nl2br( $row['srv_rear_ver']) . "</td>\n";  

# Next Rear Backup Date
    echo "\n<td align='center'>";
    if ($row['srv_img_backup'] == True ) { 
        list ($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_img_dom'], $row['srv_img_month'],
            $row['srv_img_dow'], $row['srv_img_hour'], $row['srv_img_minute']);
        echo $UPD_DATE_TIME ;
    }else{
        echo "Unknown";
    }
    echo "</td>\n";  

# Rear Backup Occurrence
    echo "\n<td align='center'>\n";
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
    echo "</tr>\n"; 
}




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

    # Show ReaR Report
    #if (file_exists(SADM_WWW_DIR . "/view/daily_rear_report.html")) {
    #    $title2="<a href='" . $URL_REAR_REPORT . "'>View the ReaR Daily Report</a>"; 
    #}     
    
    $title1="ReaR Backup Status";                                       # Page Title 1
    $title2=" "; 
    display_lib_heading("NotHome","$title1","$title2",$WVER);           # Display Heading
    
    # Loop Through Retrieved Data and Display each Row
    setup_table();                                                      # Create HTML Table/Heading
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table

    echo "<center>"; 
    echo "MacOS & ARM systems aren't shown on this page because they aren't supported by "; 
    echo "<a href='https://relax-and-recover.org'>ReaR.</a>"; 
    echo "</center>";
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
