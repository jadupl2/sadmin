<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_backup.php
#   Version     :  1.0
#   Date        :  6 July 2019
#   Description :  List active servers and associated backup schedule status (if any).
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
# 2019_07_06 web v1.0 Backup status page - Initial version of backup Status Page
# 2019_08_14 web v1.1 Backup status page - Allow to return to this page when backup sched is updated
# 2019_09_20 web v1.3 Backup status page - Show History (RCH) content using same uniform way.
# 2019_12_01 web v1.4 Backup status page - Change Layout to align with daily backup schedule.
# 2020_12_13 web v1.5 Backup status page - Added link in Heading to view the Daily Backup Report
# 2022_09_11 web v1.6 Backup status page - Now show if schedule is activated or not.
# 2022_09_12 web v1.7 Backup status page - Will show link to error log (if it exist).
# 2022_09_12 web v1.8 Backup status page - Display the first 50 systems instead of 25.
# 2022_11_12 web v1.9 Backup status page - Now show current and previous backup size.
# 2022_11_12 web v2.0 Backup status page - Show NFS server name & backup directory.
# 2022_11_12 web v2.1 Backup status page - Added column to identify system sporadically offline.
# 2022_11_20 web v2.2 Backup status page - Error log link now only appear when error occurred.
# 2023_01_05 web v2.3 Backup status page - Yellow alert if backup size is contrasting with previous.
# 2023_03_23 web v2.4 Backup status page - Lot of changes to this page, have a look.
# 2025_04_22 web v2.5 Backup status page - Alert are now shown in a tinted background for emphasis.
# 2025_04_28 web v2.6 Backup status page - Refresh disposition.
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once($_SERVER['DOCUMENT_ROOT'] . '/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once($_SERVER['DOCUMENT_ROOT'] . '/lib/sadmLib.php');            # Load PHP sadmin Library
require_once($_SERVER['DOCUMENT_ROOT'] . '/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once($_SERVER['DOCUMENT_ROOT'] . '/lib/sadmPageWrapper.php');    # Heading & SideBar

# DataTable Initialization Function
?>

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

<script>
    $(document).ready(function() {
        $('#sadmTable').DataTable({
            "lengthMenu": [
                [50, 100, -1],
                [50, 100, "All"]
            ],
            "bJQueryUI": true,
            "paging": true,
            "ordering": true,
            "info": true
        });
    });
</script>
<?php



# Local Variables
#===================================================================================================
$DEBUG              = False;                                           # Debug Activated True/False
$WVER               = "2.6";                                           # Current version number
$URL_CREATE         = '/crud/srv/sadm_server_create.php';               # Create Page URL
$URL_UPDATE         = '/crud/srv/sadm_server_update.php';               # Update Page URL
$URL_DELETE         = '/crud/srv/sadm_server_delete.php';               # Delete Page URL
$URL_MAIN           = '/crud/srv/sadm_server_main.php';                 # Maintenance Main Page URL
$URL_HOME           = '/index.php';                                     # Site Main Page
$URL_SERVER         = '/view/srv/sadm_view_servers.php';                # View Servers List
$URL_SERVER_UPDATE  = '/crud/srv/sadm_server_update.php';               # Servers Update page
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
$CREATE_BUTTON      = False;                                           # Yes Display Create Button
#
$BACKUP_RCH         = 'sadm_backup.rch';                                # Backup RCH 
$BACKUP_LOG         = 'sadm_backup.log';                                # Backup LOG 
$BACKUP_ELOG        = 'sadm_backup_e.log';                              # Backup Error LOG 




# Display SADMIN Main Page Header
#===================================================================================================
function setup_table()
{

    #echo "<div id='SimpleTable'>";
    #echo '<table id="sadmTable" row-border width="100%">';
    #echo "<div id='SimpleTable'>\n"; 
    #echo "\n<div id='MyTable'>"; 

    echo "\n<table class='content-table' width='100%' border=1>\n" ; 
    
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th align='center' width=15>No</th>";
    echo "\n<th align='left'>System</th>";
    echo "\n<th align='center'>Start Backup</th>";
    echo "\n<th align='center'>End Backup</th>";
    echo "\n<th align='center'>Duration</th>";
    echo "\n<th align='center'>Status</th>";
    echo "\n<th align='center'>Log/Hist</th>";
    echo "\n<th align='center'>Schedule</th>";
    echo "\n<th align='center'>Sporadic</th>";
    echo "\n<th align='center'>Backup<br>Size in GB</th>";
    echo "\n<th align='center'>Previous<br>Size in GB</th>";
    echo "\n<th align='center'>Host Total<br>Size in GB</th>";
    echo "\n</tr>";
    echo "\n</thead>\n";

    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th align='center' width=15>No</th>";
    echo "\n<th align='left'>System</th>";
    echo "\n<th align='center'>Start Backup</th>";
    echo "\n<th align='center'>End Backup</th>";
    echo "\n<th align='center'>Duration</th>";
    echo "\n<th align='center'>Status</th>";
    echo "\n<th align='center'>Log/Hist</th>";
    echo "\n<th align='center'>Schedule</th>";
    echo "\n<th align='center'>Sporadic</th>";
    echo "\n<th align='center'>Backup<br>Size in GB</th>";
    echo "\n<th align='center'>Previous<br>Size in GB</th>";
    echo "\n<th align='center'>Host Total<br>Size in GB</th>";
    echo "\n</tr>";
    echo "\n</tfoot>\n";

    echo "\n<tbody>\n";
}




# Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row)
{

    global  $URL_HOST_INFO, $URL_VIEW_FILE, $URL_VIEW_RCH, $URL_BACKUP, $URL_SERVER_UPDATE,
            $URL_VIEW_BACKUP, $BACKUP_RCH, $BACKUP_LOG, $BACKUP_ELOG;

    $WOS  = $row['srv_osname'];                                         # Save OS Name
    $WVER = $row['srv_osversion'];                                      # Save OS Version

    $log_name  = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_LOG;
    $elog_name = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/log/". $row['srv_name'] ."_". $BACKUP_ELOG;
    $rch_name  = SADM_WWW_DAT_DIR ."/". $row['srv_name'] ."/rch/". $row['srv_name'] ."_". $BACKUP_RCH;

    # Start of the row
    echo "\n<tr>";


    # Line Counter
    echo "\n<td align='center'>" . $count . "</td>";  


    # Show System Hostname
    echo "\n<td>";
    echo "<a href='" . $URL_HOST_INFO . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP ;
    echo "' title='Click to view system info, $WOS $WVER system - " . $row['srv_note'] . "'>";
    echo $row['srv_name']  . "</a><br>" . $row['srv_desc'] ;
    echo "</td>";


    # Start Backup Date and Time.
    if (!file_exists($rch_name)) {                                      # If RCH File doesn't exist
        echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>No data</b></td>";
    } else {
        $file = file("$rch_name");                                      # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH
        $rch_array  = explode(" ", $lastline);                          # Load Lines in rch_array
        $now        = time();                                           # Get current Epoch Time
        $your_date  = strtotime(str_replace(".", "-", $rch_array[1]));  # Event Start Date in epoch
        $datediff   = $now - $your_date;                                # Event Elapse time in seconds 
        $backup_age = round($datediff / (60 * 60 * 24));                # Event Elapse in Nb. Days
        if ($backup_age > SADM_BACKUP_INTERVAL) {                       # Event  Date older than threshold  
            $tooltip = "Backup is " .$backup_age. " days old, exceeding the treshold of " .SADM_BACKUP_INTERVAL. " days.";
            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip' title='" .$tooltip. "'><b>" .$rch_array[1]. "</b></span>";
        } else {
            $tooltip = "Backup is " .$backup_age. " days old, threshold at " .SADM_BACKUP_INTERVAL. " days.";
            if (date("Y.m.d") != $rch_array[1]) {
                echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>";
            } else {
                echo "\n<td align='center'>" ;
            }
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>" .$rch_array[1]. "</span>";
            #echo "<span data-toggle='tooltip' title='" . $tooltip . "'>" .$barray[1]. "</span>";
        }
        #echo "</td>";
    }
    echo "&nbsp;" ; 
    # Time of the last Backup
    if ($row['srv_backup'] == True) {                                   # If Backup Activated
        #echo "\n<td align='center'>";
        list($STR_SCHEDULE, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT(
            $row['srv_backup_dom'],
            $row['srv_backup_month'],
            $row['srv_backup_dow'],
            $row['srv_backup_hour'],
            $row['srv_backup_minute']
        );
        echo sprintf(" %02d", $row['srv_backup_hour']) . ":" . sprintf("%02d", $row['srv_backup_minute']);
    }else{
        if (!file_exists($rch_name)) {                                      # If RCH File doesn't exist
#            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>No data</b>";
            echo " style='color:red' bgcolor='#DAF7A6'><b>No data</b>";
        }else{
            echo "<style='color:red' bgcolor='#DAF7A6'><b>Deactivated</b>";
        } 
    }
    echo "</td>";


    # End Backup Date and Time.
    # RCH Line Example: 
    #   - $whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$walert,$gtype,$wcode    
    if (!file_exists($rch_name)) {                                      # If RCH File doesn't exist
        echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>No data</b></td>";
    }else{ 
        $file = file("$rch_name");                                      # Load RCH File in Memory
        $lastline = $file[count($file) - 1];                            # Extract Last line of RCH
        $rch_array  = explode(" ", $lastline);                          # Load Lines in rch_array
        echo "\n<td align='center'>" . $rch_array[3] . "&nbsp" . substr($rch_array[4],0,5)  ;  
    }
    echo "</td>";

    # Backup duration time
    if (!file_exists($rch_name)) {                                    # If RCH File Not Found
        echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>No data</b></td>";
    } else {
        echo "\n<td align='center'>" . $rch_array[5] . "</td>";
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
            $tooltip = 'Backup completed with success.';
            echo "\n<td align='center'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'>Success</span></td>";
            break;
        case 1:
            $tooltip = 'Backup terminated with error.';
            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'><b>Failed</span></b></td>";
            break;
        case 2:
            $tooltip = 'Backup is actually running.';
            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip' title='" . $tooltip . "'><b>Running</b></span></td>";
            break;
        default:
            $tooltip = "Unknown status - code: " . $ccode;
            echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>";
            echo "<span data-toggle='tooltip' title='" .$tooltip. "'><b>No data</b></span></td>";
            break;
    }


    # Show [log] to view backup log
    if (file_exists($log_name)) {
        echo "\n<td align='center'  style='color:blue' >";
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name . "'";
        echo " title='View Backup Log'>[log]</a>&nbsp;";
    } else {
        echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>No data</b>";
    }

    # Show [elog] to view backup error log (If exist)
    if ((file_exists($elog_name)) and (filesize($elog_name) != 0)) {
        echo "\n<a href='" . $URL_VIEW_FILE . "?&filename=" . $elog_name . "'";
        echo " title='View error log'>[elog]</a>&nbsp;";
    } else {
        echo "&nbsp;";
    }

    # Show [his] (rch) history file.
    $rch_www_name  = $row['srv_name'] . "_$BACKUP_RCH";
    if (file_exists($rch_name)) {
        echo "\n<a href='" . $URL_VIEW_RCH . "?host=" . $row['srv_name'] . "&filename=" . $rch_www_name . "'";
        echo " title='View backup history (rch) file'>[hist]</a>";
    }
    echo "</td>" ;


    # Schedule Update Button
    $ipath = '/images/UpdateButton.png';
    if ($row['srv_backup'] == TRUE) {                                  # Is Server Active
        $tooltip = 'Schedule is active, click to edit backup configuration.';
        echo "\n<td style='color: green' align='center'><b>Y ";
    } else {                                                              # If not Activate
        $tooltip = 'Schedule is inactive, click to edit backup configuration.';
        echo "\n<td style='color: red' align='center'><b>N ";
    }
    echo "<a href='" . $URL_BACKUP . "?sel=" . $row['srv_name'] . "&back=" . $URL_VIEW_BACKUP . "'>";
    echo "\n<span data-toggle='tooltip' title='" . $tooltip . "'>";
    echo "\n<button type='button'>Update</button>";             # Display Delete Button
    echo "</a></span></b></td>";


    # Is server sporadically offline (Can be offline like laptop).
    if ($row['srv_sporadic'] == TRUE) {                                # Is Server Active
        $tooltip = "System can be running or offline (Do not alert the sysadmin).";
        echo "\n<td align='center'><span data-toggle='tooltip' title='" . $tooltip . "'>";
        echo "<b>Yes</b></span></td>";
    } else {                                                              # If not Activate
        $tooltip = 'System should be up and running, otherwise alert the sysadmin.';
        echo "\n<td align='center'><span data-toggle='tooltip' title='" . $tooltip . "'>";
        echo "No</span></td>";
    }

    # Calculate Current Backup Size. 
    $backup_size = $num_backup_size = 0; $backup_unit = "";
    if (file_exists($log_name)) {
        $pattern = "/current backup size/i";                            # String to search in log
        if (preg_grep($pattern, file($log_name))) {                     # String appear in the log
            $barray      = preg_grep($pattern, file($log_name));        # backup size line in array
            # line example: 2023.03.09 01:15:15 Daily previous backup size = 4.2M
            $bstring     = implode(" ",$barray);                        # Turn array into a string
            $pos_colon   = strpos($bstring,"=");                        # Get the '=' position
            $backup_size = trim(substr($bstring,$pos_colon +1));      # Extract the backup size 
            $backup_unit = strtoupper(substr($backup_size,-1));       # Unit Size of backup M,G,T
            $num_backup_size = trim(substr($backup_size,0,strlen($backup_size) -1) ); # Extract the Total size 
            switch ($backup_unit) {
                case "K":   $num_backup_size = ($num_backup_size / 1024 / 1024); # Convert KB to GB
                            break;
                case "M":   $num_backup_size = ($num_backup_size / 1024); # Convert MB to GB
                            break;
                case "G":   break;                                      # Leave as it is for GB
                case "T":   $num_backup_size = ($num_backup_size * 1024); # Convert TB to GB
                            break;
                default:    $backup_unit="?";
                            break;
            } 
        } 
    }


    # Calculate Previous Backup Size. 
    $previous_size = $num_previous_size = 0; $previous_unit = "";
    if (file_exists($log_name)) {
        $pattern = "/previous backup size/i";
        if (preg_grep($pattern, file($log_name))) {
            # line example: 2023.03.09 01:15:15 Daily previous backup size = 4.2M
            $barray      = preg_grep($pattern, file($log_name));        # backup size line in array
            $bstring     = implode(" ",$barray);                        # Turn array into a string
            $pos_colon   = strpos($bstring,"=");                        # Get the '=' position
            $previous_size = trim(substr($bstring,$pos_colon +1));      # Extract the backup size 
            $previous_unit = strtoupper(substr($previous_size,-1));       # Unit Size of backup M,G,T
            $num_previous_size = trim(substr($previous_size,0,strlen($previous_size) -1) ); # Extract the Total size 
            switch ($previous_unit) {
                case "K":   $num_previous_size = ($num_previous_size / 1024 / 1024); # Convert KB to GB
                            break;
                case "M":   $num_previous_size = ($num_previous_size / 1024); # Convert MB to GB
                            break;
                case "G":   break;                                      # Leave as it is for GB
                case "T":   $num_previous_size = ($num_previous_size * 1024); # Convert TB to GB
                            break;
                default:    $previous_unit="?";
                            break;
            } 
        }
    }


    # Show current backup Size in GB
    if (($num_backup_size == 0 || $num_previous_size == 0) && (SADM_BACKUP_DIF != 0)) {
        echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>" ;
        echo "<b>" . number_format($num_backup_size,2) . "</b></td>";
    } else {
        $PCT = (($num_backup_size - $num_previous_size) / $num_previous_size) * 100;
        #echo "$PCT = (($num_backup_size - $num_previous_size) / $num_previous_size) * 100";
        if (number_format($PCT, 1) != 0.0) {
            if (number_format($PCT, 0) >= SADM_BACKUP_DIF) {
                echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>" ;
                echo number_format($num_backup_size,2) . "&nbsp;(+" ;
                echo number_format($PCT, 1) . "%)</b></td>";
            }elseif (number_format($PCT, 0) <= (SADM_BACKUP_DIF * -1)) {
                echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'><b>" ; 
                echo number_format($num_backup_size,2) . "&nbsp;(" ;
                echo number_format($PCT, 1) . "%)</b></td>";
            }else{    
                echo "\n<td align='center'>" . number_format($num_backup_size,2) . "</td>";
            }
        }else{
            echo "\n<td align='center'>" . number_format($num_backup_size,2) . "</td>";
        }
    }

    # Show Previous Backup Size
    if (($num_backup_size == 0 || $num_previous_size == 0) && (SADM_BACKUP_DIF != 0)) {
        echo "\n<td align='center' style='color:red' bgcolor='#DAF7A6'>" ;
        echo "<b>" . number_format($num_previous_size,2) . "</b></td>";
    } else {
        echo "\n<td align='center'>" . number_format($num_previous_size,2) . "</td>";
    }


    # Show total backup space occupied by this host in GB.
    $num_total_size = 0; 
    if (file_exists($log_name)) {
        $pattern = "/Total backup size/i";
        if (preg_grep($pattern, file($log_name))) {
            # line example: 2023.04.01 01:50:34 Total backup size = 126G
            $barray         = preg_grep($pattern, file($log_name));     # backup size line in array
            $bstring        = implode(" ",$barray);                     # Turn array into a string
            $pos_colon      = strpos($bstring,"=");                     # Get the '=' position
            $total_size     = trim(substr($bstring,$pos_colon +1));     # Extract the Total size 
            $total_unit     = strtoupper(substr($total_size,-1));       # Unit Size of backup M,G,T
            $num_total_size = trim(substr($total_size,0,strlen($total_size) -1) ); # Extract the Total size 
            switch ($total_unit) {
                case "K":   $num_total_size = ($num_total_size / 1024 / 1024); # Convert KB to GB
                            break;
                case "M":   $num_total_size = ($num_total_size / 1024); # Convert MB to GB
                            break;
                case "G":   break;                                      # Leave as it is for GB
                case "T":   $num_total_size = ($num_total_size * 1024); # Convert TB to GB
                            break;
                default:    $total_unit="?";
                            break;
            } 
        }
    }
    echo "\n<td align='center'>" . number_format($num_total_size,2) . "</td>";

    echo "\n</tr>\n\n";
}




# Add legend at the bottom of the page
#===================================================================================================
function backup_legend()
{
    echo  "\n<hr>\n<center><b>\n";
    echo "If backup status isn't a 'Success' it will have a different background color.<br>\n";
    echo "If the current backup size is zero or " . SADM_BACKUP_DIF . "% bigger or smaller than the previous backup, it will be in red.<br>\n";
    echo "If the previous backup size is zero or " . SADM_BACKUP_DIF . "% bigger or smaller than the current backup, it will be in red.<br>\n";
    echo "You can change the " . SADM_BACKUP_DIF . "% by modifying the variable 'SADM_BACKUP_DIF' in \$SADMIN/cfg/sadmin.cfg.<br>\n";
    echo "If the date of the last backup is not today, it will have the last backup date in red.<br>\n";
    echo  "</center><br><br>\n";
}




# PHP MAIN START HERE
# ==================================================================================================
    $sql = "SELECT * FROM server where srv_active = True order by srv_name;";
    $TITLE = "O/S Backup Status";

    $result = mysqli_query($con, $sql);
    if (!$result) {                                                     # If Server not found
        $err_msg = "<br>Server " . $HOSTNAME . " not found in the database.";
        $err_msg = $err_msg . mysqli_error($con);                       # Add MySQL Error Msg
        sadm_fatal_error($err_msg);                                     # Display Error & Go Back
        exit();
    }

    $NUMROW = mysqli_num_rows($result);                                 # Get Nb of rows returned
    if ($NUMROW == 0) {                                                 # If Server not found
        $err_msg = "<br>Server " . $HOSTNAME . " not found in Database";# Construct msg to user
        $err_msg = $err_msg . mysqli_error($con);                       # Add MySQL Error Msg
        if ($DEBUG) {                                                   # In Debug Insert SQL in Msg
            $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query;
        }
        sadm_fatal_error($err_msg);                                     # Display Error & Go Back
        exit();
    }

# Display Screen Heading    
    $title1 = "Daily Backup Status";
    $title2 = "";
    if (file_exists(SADM_WWW_DIR . "/view/daily_backup_report.html")) {
        $title2 = "<a href='" . $URL_BACKUP_REPORT . "'>View the Backup Daily Report</a>";
    }
    $title2 = "Backup are recorded on '" . SADM_BACKUP_NFS_SERVER . "' in '";
    $title2 = "$title2" . SADM_BACKUP_NFS_MOUNT_POINT . "' directory.";
    display_lib_heading("NotHome", "$title1", "$title2", $WVER);        # Display Content Heading

    setup_table();                                                      # Create Table & Heading

# Loop Through Retrieved Data and Display each Row
    $count = 0;
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count += 1;                                                    # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</table>\n</tbody>";                                        # End of tbody,table

   #echo "</div> <!-- End of SimpleTable          -->";                 # End Of SimpleTable Div
    backup_legend();
    std_page_footer($con);                                              # Close MySQL & HTML Footer
?>
