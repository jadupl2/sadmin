<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_sysmon.php
#   Version     :  1.5
#   Date        :  4 February 2017
#   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
#   Description :  This page allow to view the servers alerts information in various ways
#                  depending on parameters received.
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
# ChangeLog
# 2017_10_27 web v1.9 Replace PostGres Database with MySQL 
# 2017_11_03 web v2.0 Changed for ease of maintenance and can concentrate on other things
# 2018_02_12 web v2.1 Added Some Debugging Information
# 2018_05_06 web v2.2 Use Standard view file web page instead of custom view log page
# 2018_08_14 web v2.3 Added Alert Group associated with event
# 2018_09_30 web v2.4 Enhance Performance, New Page Layout and Fix issue with rch new format.
# 2019_06_07 web v2.5 Add Alarm type to page (Deal with new format).
# 2019_08_04 web v2.6 Add Distribution Logo and modify status icons.
# 2019_09_25 web v2.7 Page has become starting page and change page Title.
# 2019_10_01 web v2.8 Page Added links to log, rch and script documentation.
# 2019_10_15 web v2.9 Add Architecture, O/S Name, O/S Version to page
# 2019_11_26 web v2.10 Fix problem with temp files (Change from $SADMIN/tmp to $SADMIN/www/tmp)
# 2019_11_27 web v2.11 Fix 'open append failed', when no *.rpt exist or are all empty.
# 2020_01_11 web v2.12 Remove Arch,Category and OS Version to make space on Line.
# 2020_01_13 web v2.13 Bug fix, displaying empty error line.
# 2020_03_03 web v2.14 Server Description displayed when mouse over server name.
# 2020_05_13 web v2.15 Customize message when nothing to report.
# 2020_05_13 web v2.16 server name link was not displayed properly.
# 2020_09_23 web v2.17 Add Home button in the page heading.
# 2021_07_24 web v2.18 System monitor page - Each alert now show effective group name (not 'default').
# 2021_08_06 web v2.19 System monitor page - Alert type now show description and tooltip.
# 2021_08_07 web v2.20 System monitor page - Warning, Error, Info now have separate section.
# 2021_08_17 web v2.21 System monitor page - Use the refresh interval from SADMIN configuration file. 
# 2021_08_18 web v2.22 System monitor page - Section heading are spread on two lines.
# 2021_08_29 web v2.23 System monitor page - Show alert group member(s) as tooltip.
# 2021_09_14 web v2.24 System monitor page - New section that list recent scripts execution.
# 2021_09_15 web v2.25 System monitor page - Recent scripts section won't show if SADM_MONITOR_RECENT_COUNT=0
# 2021_09_30 web v2.26 System monitor page - Show recent activities even when no alert to report
# 2022_02_16 web v2.27 System monitor page - Monitor tmp file was not deleted after use.
# 2022_02_17 nolog v2.28 System Monitor page - Added a test to delete only when tmp file exist
# 2022_05_26 nolog v2.29 System Monitor page - Fix intermittent problem creating tmp alert file.
# 2022_05_26 nolog v2.30 System Monitor page - Fix intermittent problem creating tmp alert file.
# 2022_05_26 web v2.31 System monitor page - Rewrote some part of the code for new version of php
# 2022_07_21 web v2.32 System monitor page - Fix problem with recent scripts section
# 2022_09_08 web v2.33 System monitor page - Add current date/time and look enhancement.
# 2022_09_11 web v2.34 System monitor page - Modify to have a more pleasing look
# 2023_01_06 web v2.35 System monitor page - O/S update starter now show hostname being updated.
# 2023_04_10 web v2.36 System monitor page - Bug fix when no rch and rpt files were present.
# 2023_10_17 web v2.37 System monitor page - Minor adjustments.
#@2025_01_24 web v2.38 Will now show when a system is lock.
#@2025_03_27 web v2.39 Enhance the appearance of the page.
#@2025_06_10 web v2.40 If an invalid status code is encountered, it will be displayed as Unknown.
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar
?>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Ubuntu:wght@300&display=swap" rel="stylesheet"> 

<!--  Refresh Page every ${SADM_MONITOR_UPDATE_INTERVAL} Seconds -->
<meta http-equiv="refresh" content="<?php echo SADM_MONITOR_UPDATE_INTERVAL ?>;'">

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

.content-table th {
// Vertical | Horizontal    padding: 12px 15px;
    padding: 5px 5px;
}

.content-table td {
// Vertical | Horizontal    padding: 12px 15px;
    padding: 5px 5px;
    color: #000000;

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
# Local Variables
#---------------------------------------------------------------------------------------------------
#
$DEBUG         = False ;                                                # Debug Activated True/False
$SVER          = "2.40" ;                                               # Current version number
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$URL_CREATE    = '/crud/srv/sadm_server_create.php';                    # Create Page URL
$URL_UPDATE    = '/crud/srv/sadm_server_update.php';                    # Update Page URL
$URL_DELETE    = '/crud/srv/sadm_server_delete.php';                    # Delete Page URL
$URL_MAIN      = '/crud/srv/sadm_server_main.php';                      # Maintenance Main Page URL
$URL_MAIN      = '/crud/srv/sadm_server_main.php';                      # Maintenance Main Page URL
$URL_CURRENT   = '/view/sys/sadm_view_sysmon.php';                      # This page Current URL
$URL_VIEW_FILE = '/view/log/sadm_view_file.php';                        # View File Content URL
$URL_VIEW_RCH  = '/view/rch/sadm_view_rchfile.php';                     # View RCH File Content URL
$URL_DOC_DIR   = '/doc/pdf/scripts/';                                   # URL Location of pdf 
$URL_WEB       = "https://sadmin.ca/";                                  # Main Site URL 
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$tmp_file1     = tempnam (SADM_WWW_TMP_DIR . "/", 'sysmon_tmp1_');
$tmp_file2     = tempnam (SADM_WWW_TMP_DIR . "/", 'sysmon_tmp2_');
$array_sysmon  = [];                                                    # Create Empty Array
$alert_file    = SADM_WWW_TMP_DIR . "/sysmon_alert_file_" . getmypid(); # File Being Built/Displayed




# function create_alert_file() {
#
# Description: 
#   Create one output file ($alert_file) that contain a list of scripts errors & monitoring alerts.
#   The alert file created will have the same format as the rpt file.
#
#   1-Create alert file containing all *.rpt found in $SADMIN/www/dat directories.
#   2-Add the last line of all *.rch from active systems in $SADMIN/www/dat,
#     Only add lines, that contain a 1 or a 2 (Failed=1 or Running=2) in the last column.
#
# Parameter(s):  None
#
# Return value(s): None
#   If an error occurs, the script will abort with an error message.
#---------------------------------------------------------------------------------------------------
#
function create_alert_file() {
    global $DEBUG, $tmp_file1, $tmp_file2, $alert_file ;
    #$DEBUG = True;
 
    # Make sure we begin with an empty alert file ($alert_file).
    if (file_exists($alert_file)) { unlink($alert_file); }              # Delete Alert file if exist
    touch($alert_file);                                                 # Create empty file
    chmod($alert_file,0666);                                            # Set Permission on file
    chown($alert_file,SADM_WWW_USER) ;                                  # chown on new alert file
    chgrp($alert_file,SADM_WWW_GROUP) ;                                 # chgrp on new alert file 


    # Create a list of all *.rpt file name and output it to $alert_file.
    # - Example of rpt format line below : 
    # Warning;holmes;2021.07.24;10:15;linux;FILESYSTEM;Filesystem /opt at 82% >= 80%;default;default
    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rpt' -exec cat {} \; >> $alert_file";
    $a = exec ( $CMD , $FILE_LIST, $RCODE);  # Execute the find command
    
    if ($DEBUG) {                                                       # Debug then,show cmd result
        echo "\n<br>Command executed is : " . $CMD ;                    # Show Cmd that we execute
        echo "\n<br>Return code of command is : " . $RCODE ;            # Command return code
        if (filesize($alert_file) == 0) { echo "\n<br>File $alert_file is empty" ; }
        echo "\n<br>Content of resulting file - $alert_file :";         # Alert file heading
        $orig = file_get_contents($alert_file);                         # Read Alert file content
        $a = htmlentities($orig);                                       # Char. to HTML entities
        echo '<code><pre>';                                             # Code to be displayed
        echo $a;                                                        # Show Alert file
        echo '</pre></code>';                                           # End of code display
    }


    # Get last line of ALL *.rch that terminate with error(1) or is actually running(2).
    #   - Example Of a rch Line Below :
    #   - ubuntu2104 2021.07.05 05:11:23 2021.07.05 05:11:32 00:00:09 sadm_backup default 1 2
    $CMD_PART1="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rch' -exec tail -1 {} \;" ;
    $CMD_PART2=" | grep -E '1$|2$' > $tmp_file2 ";                      # Lines ending with 1 or 2
    $CMD="$CMD_PART1 $CMD_PART2";                                       # Combine 2 long commands
    $a = exec ( $CMD , $FILE_LIST, $RCODE);                             # Execute the find cmd

    if ($DEBUG) {                                                       # Debug then,show cmd result
        echo "\n<br>Command executed is : " . $CMD ;                    # Show Cmd that we execute
        echo "\n<br>Return code of command is : " . $RCODE ;            # Command return code
        if (filesize($tmp_file2) == 0) { echo "\n<br>File $tmp_file2 is empty" ; }
        echo "\n<br>Content of resulting file - $tmp_file2 :";          # Alert file heading
        $orig = file_get_contents($tmp_file2);                          # Read Alert file content
        $a = htmlentities($orig);                                       # Char. to HTML entities
        echo '<code><pre>';                                             # Code to be displayed
        echo $a;                                                        # Show Alert file
        echo '</pre></code>';                                           # End of code display
    }

    # Open the alert file, ready to be converted from RCH to RPT Format.
    if ($DEBUG) {
        if ( file_exists($alert_file) )   { echo "\n<br>File $alert_file exist."; }
        if ( ! file_exists($alert_file) ) { echo "\n<br>File $alert_file don't exist."; }
        if ( filesize($alert_file) == 0)  { echo "\n<br>File $alert_file but is empty." ; }
    }   
    if ( ! file_exists($alert_file) ) {
        $afile = fopen("$alert_file",'w')  or die("Can't open in write mode file "  . $alert_file);
    }else{
        $afile = fopen("$alert_file","a+") or die("can't open in append mode file " . $alert_file);
    }


    # Convert the global RCH file just created ($tmp_file2) to a RPT format kind of lines 
    # raspi4 2018.09.29 23:25:00 2018.09.29 23:25:17 00:00:17 sadm_client_housekeeping default 1 1
    #   1        2         3         4        5        6               7                  8    9 10
    # To this type of lines (RPT) :
    # Error;raspi2;2018.09.29;23:25;SADM;SCRIPT;sadm_client_housekeeping;sadm/1;sadm/1;
    #   1    2       3        4      5       6             7                     8     9
    $lines = file($tmp_file2);                                          # Load RCH Line into Array
    foreach ($lines as $line_num => $line) {                            # Process Each line in array
        if ($DEBUG) { echo "\n<br><br>RCH Before conversion :<br>" .$line ; }
        # $whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$walert,$gtype,$wcode
        #    0      1       2       3       4       5       6        7       8      9
        $line_array = explode(" ",$line);                               # Split line in an array
        $rdate = trim($line_array[3]);                                  # Event Date = Finish Date
        $rtime = substr(trim($line_array[4]),0,-3);                     # Event Time = Finish Time
        switch (trim($line_array[9])) {                                 # Based on Script Exit Code
            case 0:     $rtype = "Success" ;                            # Script Exit Code 0=Success
                        break;
            case 1:     $rtype = "Error" ;                              # Script Exit Code 1 = Error
                        break;
            case 2:     $rtype = "Running" ;                            # Script Exit Code 2=Running
                        $rdate = trim($line_array[1]);                  # Event Date is Start Date
                        $rtime = substr(trim($line_array[2]),0,-3);     # Event Time is Start Time
                        break;
            default:    $rtype = "Unknown" . $wcode ;                   # Unknown Script Exit Code 
                        break;
        }
        $rhost      = trim($line_array[0]);                             # Host Name
        $rmod       = "SADM";                                           # Event Module name = SADM
        $rsubmod    = "SCRIPT";                                         # Event Sub-Module = SCRIPT
        $ragroup    = "$line_array[7]";                                 # Alert Group 
        $ratype     = "$line_array[8]";                                 # Alert Type
        $ralert     = "$line_array[7]/$line_array[8]";                  # Alert Group & Alert Type
        $rdesc      = "$line_array[6]";                                 # Script Name 
        $LINE="$rtype;$rhost;$rdate;$rtime;$rmod;$rsubmod;$rdesc;$ralert;$ralert\n";
        if ($DEBUG) { echo "\n<br>RCH After conversion :<br>" .$LINE ; }
        fwrite($afile,$LINE);                                           # Write reformatted line
    }
    fclose($afile);                                                     # Close the ALert File
    if ($DEBUG) {                                                       # Show Final Alert File
        $orig = file_get_contents($alert_file);                         # Load Alert File
        $a = htmlentities($orig);                                       # Filter out Special Char.
        echo "\n\n<br><br>End of Alert file creation<code><pre>" .$a. '</pre></code>'; 
    }

    if (file_exists($tmp_file1)) { unlink($tmp_file1); }                # Delete Work File 1
    if (file_exists($tmp_file2)) { unlink($tmp_file2); }                # Delete Work File 2
    #$DEBUG = False;
    #echo "<br>end of create alert"; 
}




# function sysmon_page_heading($HEAD_TYPE)
# 
# Description :
#   Display System Monitor Status Heading
#
# Input Parameters : 
#   Heading type : 
#       "E" for "Error"
#       "W" for "Warning"
#       "I" for "Info" 
#       "R" for ¨Running"
# 
# Return value(s): None
#---------------------------------------------------------------------------------------------------
function sysmon_page_heading()
{

    if ($DEBUG) { echo "Entering sysmon_heading"; }
    #echo "\n<br><h3><strong>Notification(s)</strong></h3>\n" ;
    echo "\n<h3><strong>Notification(s)</strong></h3>\n" ;
    
     # Table creation
    echo "\n<table class='content-table'>\n" ; 

    echo "\n\n<thead>";    
    echo "\n<tr>";    
    echo "\n<th align=center>Status</th>";
    echo "\n<th align=center>System</th>";
    echo "\n<th align=center>O/S</th>";
    echo "\n<th align=center>Cat.</th>";
    echo "\n<th align=left>Alert Description</th>";
    echo "\n<th align=center>Date/Time</th>";
    echo "\n<th align=center>Module</th>";
    echo "\n<th align=center>Alert Group Name</th>";
    echo "\n<th align=center>Alert Type</th>";
    echo "\n</tr>";
    echo "\n</thead>\n";    

    echo "\n<tfoot>";    
    echo "\n<tr>";    
    echo "\n<th align=center>Status</th>";
    echo "\n<th align=center>System</th>";
    echo "\n<th align=center>O/S</th>";
    echo "\n<th align=center>Cat.</th>";
    echo "\n<th align=left>Alert Description</th>";
    echo "\n<th align=center>Date/Time</th>";
    echo "\n<th align=center>Module</th>";
    echo "\n<th align=center>Alert Group Name</th>";
    echo "\n<th align=center>Alert Type</th>";
    echo "\n</tr>";
    echo "\n</tfoot>\n";       
}




# function display_line($line,$BGCOLOR,$con) 
#
# Description: Display one section at a time (Warning, Error, Running, Info, and Unknown)
#
# Input Parameters :
#   1- String containing line to be displayed.
#
# Returned value(s): 
#---------------------------------------------------------------------------------------------------
function display_line($line,$con) 
{
    global $DEBUG, $URL_HOST_INFO, $URL_VIEW_FILE, $URL_WEB, $URL_VIEW_RCH, $URL_DOC_DIR;

    # Split the line
    # Running;holmes;2019.09.30;10:39;SADM;SCRIPT;sadm_fetch_clients;default/1;default/1 
    list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$warngrp,$errgrp)=explode(";",$line);

    if ($DEBUG) { 
        echo "\n<br>IN DISPLAY_LINE";
        echo "\n<br>wstatus     = $wstatus";
        echo "\n<br>whost       = $whost";
        echo "\n<br>wdate       = $wdate";
        echo "\n<br>wtime       = $wtime";
        echo "\n<br>wmod        = $wmod";
        echo "\n<br>wsubmod     = $wsubmod";
        echo "\n<br>wdesc       = $wdesc";
        echo "\n<br>warngrp     = $warngrp";
        echo "\n<br>errgrp      = $errgrp\n";
    }

    # Show Status Icons 
    echo "\n<tr>";                                                      # Start of line
    switch (strtoupper($wstatus)) {                             # Depend on Uppercase Status
        case 'ERROR' :                                                  # If an Error Line
            echo "\n<td align='center' style='vertical-align:middle'>"; 
            echo "<span data-toggle='tooltip' title='Error Reported'>";
            echo "<img src='/images/sadm_error.png' style='width:96px;height:40px;'>";
            echo "</span></td>"; 
            $alert_group=$errgrp;                                       # Set Event Alert Group
            break;
        case 'WARNING' :
            echo "\n<td align='center' align='left'>"; 
            echo "<span data-toggle='tooltip' title='Warning Reported'>";
            echo "<img src='/images/sadm_warning.png' ";                # Show Warning Icon
            echo "style='width:96px;height:40px;'>";                    # Status Standard Image Size
            echo "</span></td>"; 
            $alert_group=$warngrp;                                      # Set Event Alert Group
            break;
        case 'RUNNING' :                                                # Running Status = Script
            echo "\n<td align='center' align='left'>"; 
            echo "<span data-toggle='tooltip' title='Script currently running'>";
            echo "<img src='/images/sadm_running.png' ";                # Show Running Icon
            echo "style='width:96px;height:40px;'>";                    # Status Standard Image Size
            echo "</span></td>"; 
            $alert_group=$errgrp;                                       # Script group 
            break;
        case 'INFO' :                                                   # Information from MOnitor
            echo "\n<td align='center' align='left'>"; 
            echo "<span data-toggle='tooltip' title='System Information'>";
            echo "<img src='/images/sadm_info.png' ";                   # Show Running Icon
            echo "style='width:96px;height:40px;'>";                     # Status Standard Image Size
            echo "</span></td>"; 
            $alert_group=$warngrp;                                      # Set Event Alert Group 
            break;
        default:
            echo "\n<td align='left'>"; 
            echo "<span data-toggle='tooltip' title='Unknown $wstatus'>";
            echo "<img src='/images/question_mark.jpg' ";               # Show Question Mark
            echo "style='width:96px;height:40px;'></span>$wstatus</td>";
            $alert_group="default";                                     # Set Event Alert Group
            break;
    }

    # Get Server Description, O/S and O/S version.
    $sql ="SELECT * FROM server where srv_name = '". $whost . "';";     # Construct select 
    if ( ! $result=mysqli_query($con,$sql)) {             # Execute SQL Select
        $WDESC = "Server not in Database";                              # Server not found descr.
        $WOS   = "Unknown";                                             # O/S name is unknown
        $WVER  = "Unknown";                                             # O/S Version is unknown
        $WCAT  = "Unknown";                                             # Server Category is unknown
    }else{
        $row = mysqli_fetch_assoc($result);                             # Fetch server info
        $WDESC = $row['srv_desc'];                                      # Save Server Description
        $WOS   = $row['srv_osname'];                                    # Save Server O/S Name
        $WVER  = $row['srv_osversion'];                                 # Save Server O/S Version
        $WCAT  = $row['srv_cat'];                                       # Save Server Category
        mysqli_free_result($result);                                    # Free result set 
    }

    #----- System Name -----
    echo "\n<td align='center'>";
    echo "<a href='" . $URL_HOST_INFO . "?sel=" . nl2br($whost) ;
    echo "' title='$WDESC at " . $row['srv_ip'] . "'>" ;
    echo nl2br($whost) . "</a></td>\n";

    #----- Operating System Logo -----
    $WOS   = sadm_clean_data($row['srv_osname']);                       # Set Server O/S Name
    list($ipath, $iurl, $ititle) = sadm_return_logo($WOS) ;
    echo "<td align='center' bgcolor=$BGCOLOR>";
    echo "<a href='". $iurl . "' title='" . $ititle . "'>";
    echo "<img src='" . $ipath . "' style='width:32px;height:32px;'></a></td>\n";

    #----- Category Name -----
    echo "<td align='center'>"  . $WCAT . "</td>\n";
    
    #----- Event Description -----
    echo "<td>";                                       # Start of Cell
    echo "&nbsp;\n" . $wdesc ;                                          # Desc. coming from rpt file

    # If it's a script and the usual log file exist, produce a link to view the log.
    $wlog =  $whost . "_" . $wdesc . ".log";                            # Construct Script log Name
    $log_name = SADM_WWW_DAT_DIR . "/" .$whost. "/log/" .trim($wlog);   # Full Path to Script Log
    if (($wsubmod == "SCRIPT") and (file_exists($log_name)) and (filesize($log_name) != 0)) {
        echo "&nbsp;\n<a href='" . $URL_VIEW_FILE ;
        echo "?filename=" . $log_name . "' title='View script log - " .$wlog. "'>[log]</a>";
    }

    # If it's a script and the error log file exist, produce a link to view the error log.
    $welog =  $whost . "_" . $wdesc . "_e.log";                         # Construct Error log Name
    $elog_name = SADM_WWW_DAT_DIR . "/" .$whost. "/log/" .trim($welog); # Full Path to Error Log
    if ( ($wsubmod == "SCRIPT") and (file_exists($elog_name)) and (filesize($elog_name) != 0) ) {
        echo "&nbsp;\n<a href='" . $URL_VIEW_FILE ;
        echo "?filename=" . $elog_name . "' title='View script error log - " .$welog. "'>[elog]</a>";
    }

    # If it's a script and the rch file exist, produce a link to view the log.
    $wrch =  $whost . "_" . $wdesc . ".rch";                            # Construct Script rch Name
    $rch_name = SADM_WWW_DAT_DIR . "/" .$whost. "/rch/" .trim($wrch);   # Full Path to Script rch  
    if (($wsubmod == "SCRIPT") and (file_exists($rch_name)) and (filesize($rch_name) != 0)) {
        echo "&nbsp;\n<a href='" . $URL_VIEW_RCH ;
        echo "?host=" .$whost. "&filename=" .$wrch. "' title='View script history file - ";
        echo $wrch . "'>[rch]</a>";                                   # Create link to view rch
    }

    # Produce Link to documentation (if script/module exist in $SADMIN/www/doc/pgm2doc.cfg file
    if ($wsubmod == "SCRIPT") {                                     # Module is a Script ?
        $doc_link = getdocurl("$wdesc") ;                           # Get Script Name Link
        if ( $doc_link != "" ) {                                    # We have a valid link ?
            echo "&nbsp;\n<a href='" . $URL_WEB . $doc_link ;
            echo "' title='View script documentation of '" . $wdesc . ">[doc]</a>";
        }
    }else{
        $doc_link = getdocurl("$wsubmod") ;                         # Get Module link to Doc
        if ( $doc_link != "" ) {                                    # We have a valid link
            echo str_repeat('&nbsp;', 2) . "\n<a href='" . $URL_WEB . $doc_link ;
            echo "' title='View module documentation'>[doc]</a>";
        }
    }       
    echo "</td>";

    # Event Date and Time
    echo "\n<td align='center'>" . $wdate . " " . $wtime . "</td>";

    # Event Module Name (All lowercase, except first character).
    echo "\n<td align='center'>" . ucwords(strtolower($wsubmod)) . "</td>";

    # Event Alert Group Name
    $pieces = explode("/", $alert_group);
    #$str=preg_replace('/\s+/', '', $str);
    if ($DEBUG) { echo "pieces[0]=..$pieces[0].. pieces[1]=..$pieces[1].."; }               
    $alert_group = preg_replace('/\s+/', '', $pieces[0]);           # Isolate Alert Grp Name
    $org_alert_group = $alert_group;                                # Save Original AlertGrpName
    $alert_type  = preg_replace('/\s+/', '', $pieces[1]);           # Isolate Alert Type
    if ( $alert_type == "" ) { $alert_type=1 ; }                    # Default Alert Type
    if ($DEBUG) { echo "1) alert_group=..$alert_group.. alert_type=..$alert_type.."; }               

    list($alert_group, $alert_group_type, $stooltip) = get_alert_group_data ($alert_group) ;
    echo "\n<td align='center'>" ;
    echo "<span data-toggle='tooltip' title='" . $stooltip . "'>"; 
    echo $alert_group . "</span>(" . $alert_group_type . ")</td>"; 


    # Show Alert type Meaning
    switch ($alert_type) {                                              # 0=No 1=Err 2=Success 3=All
        case 0 :                                                        # 0=Don't send any Alert
            $alert_type_msg="No alert(0)" ;                             # Mess to show on page
            if (strtoupper($wstatus) == "WARNING") { 
                $etooltip="Column 'J' is blank in \$SADMIN/cfg/". $whost . ".smon.";
            }else{
                $etooltip="Column 'K' is blank in \$SADMIN/cfg/". $whost . ".smon.";
            }
            if (strtolower($wsubmod) == "SCRIPT") { 
                $etooltip="SADM_ALERT is to 0 in script " . $wdesc ;
            }
            break;
        case 1 :                                                        # 1=Send Alert on Error
            if (strtoupper($wstatus) == "ERROR") {
                $alert_type_msg="Alert on error(1)" ;                   # Mess to show on page
                $etooltip="Error alert group (Col. K) is " . $org_alert_group . " in \$SADMIN/cfg/". $whost . ".smon.";
            }else{
                if (strtoupper($wstatus) == "RUNNING") {
                    $alert_type_msg="Alert on error(1)" ;               # Mess to show on page
                    $etooltip="Error alert group (Col. K) is " . $org_alert_group . " in \$SADMIN/cfg/". $whost . ".smon.";
                }else{
                    $alert_type_msg="Alert on warning(1)" ;             # Mess to show on page
                    $etooltip="Warning alert group (Col. J) is " . $org_alert_group . " in \$SADMIN/cfg/". $whost . ".smon.";
                }
            }   
            if (strtoupper($wsubmod) == "SCRIPT") { 
                $etooltip="SADM_ALERT set to 1 in script " . $wdesc ;
            }
            break;
        case 2 :                                                        # 2=Send Alert on Success
            $alert_type_msg="Alert on success(2)" ;                     # Mess to show on page
            $etooltip="SADM_ALERT set to 2 in script " ;
            break;
        case 3 :                                                        # 3=Always Send Alert
            $alert_type_msg="Always alert(3)" ;                         # Mess to show on page
            $etooltip="SADM_ALERT set to 3 in script " ;
            break;
        default:
            $alert_type_msg="Unknown code($alert_type)" ;               # Invalid Alert Group Type
            $etooltip="Unknown code($alert_type) " ;
            break;
    }        
    echo "\n<td align='center'>" ;
    echo "<span data-toggle='tooltip' title='" . $etooltip . "'>"; 
    echo $alert_type_msg . "</span></td>"; 
    echo "\n</tr>";
}




# function show_activity($con,$alert_file) 
# 
# Description : 
#   Show the last $SADM_MONITOR_HISTORY_SIZE most recent scripts execution.
#   The $SADM_MONITOR_HISTORY_SIZE variable is defined in $SADMIN/cfg/sadmin.cfg.
# 
# Parameters : 
#   $con           = Connector to SADMIN Database.
#   $alert_file    = File previously built from rpt and rch file that need to be displayed.
#                    SADM_WWW_TMP_DIR . "/sysmon_alert_file_" . getmypid();
#---------------------------------------------------------------------------------------------------
function show_activity($con,$alert_file) {
    global $DEBUG, $tmp_file1, $tmp_file2, $URL_HOST_INFO, $URL_VIEW_RCH, $URL_WEB, $URL_VIEW_FILE ;
    $DEBUG = False ;

    $wdate=date('Y.m.d');                                               # 2025.03.31
    $today=date("jS F, Y");                                             # Example: '4th April, 2025'
    if ($DEBUG) { 
        echo "<br>\nSADM_MONITOR_RECENT_COUNT : " . SADM_MONITOR_RECENT_COUNT . "\n<br>" ; 
        echo "<br>\nCurrent date              : " . $wdate . "\n<br>"; 
        echo "<br>\nToday Date                : " . $today . "\n<br>"; 
    }

    # Header of the Section
    $HEADS=" Most recent scripts execution" ;
    echo "\n<br><h3><strong>". SADM_MONITOR_RECENT_COUNT . "$HEADS</strong></h3>" ;

    # Get the last 10 ($SADM_MONITOR_RECENT_COUNT) most recent scripts execution in $tmp_file2.
    $CMD_PART1="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rch' -exec tail -1 {} \;" ;
    $CMD_PART2=" |sort -t' ' -k4,4r -k5,5r  >$tmp_file2";
    $CMD="$CMD_PART1 $CMD_PART2";                                       # Combine 2 long commands
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }        # Show Cmd that we execute
    $a = exec ( $CMD , $FILE_LIST, $RCODE);                             # Execute the find command
    if ($DEBUG) {                                                       # Debug then,show cmd result
        echo "\n<br>Return code of command is : " . $RCODE ;            # Command return code
        echo "\n<br>Content of resulting file :";                       # Alert file heading
        $orig = file_get_contents($tmp_file2);                          # Read Alert file content
        $a = htmlentities($orig);                                       # Char. to HTML entities
        echo '<code><pre>';                                             # Code to be displayed
        echo $a;                                                        # Show Alert file
        echo '</pre></code>';                                           # End of code display
    }
    
    
    echo "\n<table class='content-table'>\n" ;                          # Start of table creation

    echo "\n\n<thead>";
    echo "\n<tr>";
    echo "\n<b>";
    echo "\n<th width=25 align='center'>No</td>";    
    echo "\n<th width=90 align='left'>System</td>";
    echo "\n<th align='left'>Script Name</td>";
    echo "\n<th align='center'>Start Date/Time</td>";
    echo "\n<th align='center'>End Time</td>";
    echo "\n<th align='center'>Elapse</td>";
    echo "\n<th align='center'>Alert Group</td>";
    echo "\n<th align='center'>Alert Type</td>";
    echo "\n<th align='center'>Status</td>"; 
    echo "\n</b>";
    echo "\n</tr>";
    echo "\n</thead>";

    echo "\n\n<tfoot>";
    echo "\n<tr>";
    echo "\n<b>";
    echo "\n<th width=25 align='center'>No</td>";    
    echo "\n<th width=90 align='left'>System</td>";
    echo "\n<th align='left'>Script Name</td>";
    echo "\n<th align='center'>Start Date/Time</td>";
    echo "\n<th align='center'>End Time</td>";
    echo "\n<th align='center'>Elapse</td>";
    echo "\n<th align='center'>Alert Group</td>";
    echo "\n<th align='center'>Alert Type</td>";
    echo "\n<th align='center'>Status</td>"; 
    echo "\n</b>";
    echo "\n</tr>";
    echo "\n</tfoot>";


    $lcount = 0;                                                        # Recent line counter
    $lines = file($tmp_file2);                                          # Load RCH Line into Array
    foreach ($lines as $line_num => $line) {                            # Process Each line in array
        if ($DEBUG) { echo "\n<br>Processing rch line: <code><pre>" .$line. '</pre></code>'; }

        # Split Script RCH Data Line
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$calert,$ctype,$ccode) = explode(" ",$line);

        # Check if script is in the exclude list (sadmin.cfg), if yes then skip this entry
        if ($DEBUG) { 
            echo "\n<br><code><pre>"; 
            echo "SADM_MONITOR_RECENT_EXCLUDE = " . SADM_MONITOR_RECENT_EXCLUDE ;
            echo "</pre></code>\n"; 
        }
        $script_exclude = explode(",",SADM_MONITOR_RECENT_EXCLUDE);
        $sfound=False; 
        foreach ($script_exclude as $script) {
            #echo "\n\n<br>COMPARE ..$script.. with ..$cname..\n"; 
            if (trim($script) == trim($cname)) { 
                $sfound=True;
                #echo "\nYES FOUND $sfound\n" ;
                break ; 
            }
            #else{echo "\nNOTFOUND\n" ; }
        }
        if ($sfound) { continue ; }                                     # In exclude list Skip it

        ++$lcount;                                                      # Increase Counter;
        if ( $lcount > SADM_MONITOR_RECENT_COUNT) { break ; }           # Reach Nb. Desired end loop

        # Get server description from database (use as a tooltip over the server name) --------
        $sql = "SELECT * FROM server where srv_name = '$cserver' ";     # Select Statement Read Srv
        $result=mysqli_query($con,$sql);                                # Execute SQL Select
        $row = mysqli_fetch_assoc($result);                             # Get Column Row Array 
        if ($row) {$wdesc = $row['srv_desc']; } else { $wdesc = "Unknown";} #Get Srv Desc.

        # Alternate color at each line.
        if ($lcount % 2 == 0) {                                         # If even lines count
            #echo "\n<tr style='background-color:#cccccc ; line-height:150% ; color:black'>\n";
            echo "\n<tr style='background-color:#fbfbfb ; line-height:150% ; color:black'>\n";
        }else{
            #echo "\n<tr style='background-color:#ffffff ; line-height:150% ; color:black'>\n";
            echo "\n<tr style='background-color:#f1f1f1 ; line-height:150% ; color:black'>\n";
        }
    
        # Line counter
        echo "\n<td align='center'>". $lcount . "</td>";                # Line counter
        
        # System Name
        echo "\n<td align='left'><a href='" . $URL_HOST_INFO . "?sel=" . $cserver ;
        echo "' data-toggle='tooltip' title='" . $wdesc . "'>" . $cserver . "</a></td>";

        # Name of the script
        echo "\n<td align='left'> &nbsp;" . $cname ;                        # Server Name Cell
        
        # Link to log if it exist on disk.
        $LOGFILE = trim("${cserver}_${cname}.log");                        # Add .log to Script Name
        $log_name = SADM_WWW_DAT_DIR . "/" . $cserver . "/log/" . $LOGFILE ;
        if (file_exists($log_name) and (filesize($log_name) != 0) ){
            echo "\n<a href='" . $URL_VIEW_FILE . "?filename=" . 
            $log_name . "' data-toggle='tooltip' title='View script log file'>[log]</a>";
        }else{
            echo "&nbsp;";                                              # If No log exist for script
        }
        
        # Link to Error log, if it exist on disk.
        $ELOGFILE = trim("${LOGFILE}_e.log");                           # Add _e.log to Script Name
        $elog_name = SADM_WWW_DAT_DIR . "/" . $cserver . "/log/" . $ELOGFILE ;
        if ((file_exists($elog_name)) and (filesize($elog_name) != 0))  {
            echo "\n<a href='" . $URL_VIEW_FILE . "?filename=" ;
            echo "$elog_name ' data-toggle='tooltip' title='View script errorlog file'>[elog]</a>";
        }else{
            echo "&nbsp;";                                              # If No log exist for script
        }
        
        # Link to rch, if it exist.
        $RCHFILE = trim("${cserver}_${cname}.rch");                     # Add .rch to Script Name
        $rch_name  = SADM_WWW_DAT_DIR . "/" . $cserver . "/rch/" . $RCHFILE ;
        if ((file_exists($rch_name)) and (filesize($rch_name) != 0)) {
            echo "\n<a href='" . $URL_VIEW_RCH . "?host=". $cserver ."&filename=". $RCHFILE ;
            echo "' data-toggle='tooltip' title='View History (rch) file'>[rch]</a>";
        }else{
            echo "&nbsp;";                                      # If no RCH Exist
        }

        # Link to doc
        $doc_link = getdocurl("$cname") ;                               # Get Script Name Link
        if ( $doc_link != "" ) {                                        # We have a valid link ?
            echo "\n<a href='" . $URL_WEB . $doc_link ;
            echo "' title='View script documentation'>[doc]</a>";
        }
        echo "</td>" ;
        
        
        # Start date & start time
        echo "\n<td align='center'>" . $cdate1  . "&nbsp;" . $ctime1 . "</td>"; 
        

        # End Time
        if ($ccode == 2) {
            echo "\n<td align='center'>............</td>";              # Running - No End time Yet
        }else{
            echo "\n<td align='center'>" . $ctime2 . "</td>";  
        }


        # End date, End time and Elapse time.
        if ($ccode == 2) {
            echo "\n<td align='center''>............</td>";             # Running - No End date Yet
        }else{
            echo "\n<td align='center'>" . $celapsed . "</td>";         # Script Elapse Time
        }
                

        # Alert Group 
        list($calert, $alert_group_type, $stooltip) = get_alert_group_data ($calert) ;
        echo "\n<td align='center'>";
        echo "<span data-toggle='tooltip' title='" . $stooltip . "'>"; 
        echo $calert . "</span>(" . $alert_group_type . ")</td>"; 

        # Alert group type (0=none, 1=alert onerror, 2=alert on ok, 3=always)
        # Show Alert type Meaning
        switch ($ctype) {                                           # 0=No 1=Err 2=Success 3=All
            case 0 :                                                # 0=Don't send any Alert
                $alert_type_msg="No alert(0)" ;                     # Mess to show on page
                $etooltip="SADM_ALERT is set to 0 in script " . $cname ;
                break;
            case 1 :                                                # 1=Send Alert on Error
                $alert_type_msg="Alert on error(1)" ;               # Mess to show on page
                $etooltip="SADM_ALERT is set to 1 in script " . $cname ;
                break;
            case 2 :                                                # 2=Send Alert on Success
                $alert_type_msg="Alert on success(2)" ;             # Mess to show on page
                $etooltip="SADM_ALERT is set to 2 in script " . $cname ;
                break;
            case 3 :                                                # 3=Always Send Alert
                $alert_type_msg="Always alert(3)" ;                 # Mess to show on page
                $etooltip="SADM_ALERT is set to 3 in script " . $cname ;
                break;
            default:
                $alert_type_msg="Unknown code($ctype)" ;            # Invalid Alert Group Type
                $etooltip="SADM_ALERT set to ($ctype) in script " . $cname ;
                break;
        }        
        echo "\n<td align='center'>";
        echo "<span data-toggle='tooltip' title='" . $etooltip . "'>"; 
        echo $alert_type_msg . "</span></td>"; 


        # Script status after execution
        echo "\n<td align='center'><strong>";
        switch ($ccode) {
            case 0:  
                echo "\n<font color='black'>Success</font></strong></td>";
                break;
            case 1:  
                echo "\n<font color='red'>Failed</font></strong></td>";
                break;
            case 2:  
                echo "\n<font color='green'>Running</font></strong></td>";
                break;
            default: 
                echo "\n<font color='red'>Code " .$ccode. "</font></td>";
                break;;
        }
        echo "\n</tr>\n";                                               # Write reformatted line
        if (file_exists($tmp_file1)) { unlink($tmp_file1); }            # Delete Work File 1
        if (file_exists($tmp_file2)) { unlink($tmp_file2); }            # Delete Work File 2
    }
}






# Display Alert section : Running(Green), Warning(Yellow), Error(Red) and Info(Blue) section.
#---------------------------------------------------------------------------------------------------
function display_alert_table($con,$alert_file) {

    global $DEBUG, $URL_HOST_INFO, $URL_VIEW_FILE, $URL_WEB, $URL_VIEW_RCH, $URL_DOC_DIR;

    echo "\n<tbody style: font-family: 'Arial', sans-serif;>";          # Body definition        
    $array_sysmon = file($alert_file);                                  # Put Alert file in Array
    natsort($array_sysmon);                                             # Sort Array 
    if ($DEBUG) {echo "\nIn 'display_alert_table':\n<br>" ;var_dump ($array_sysmon); echo "\n<br>";}

    # If nothing to report
    if (sizeof($array_sysmon) == 0) {                                   # Array Empty everything OK
        echo "<center><strong>No error or warning to report at the moment.</strong></center>" ;
        if (file_exists($alert_file)) { unlink($alert_file); }          # Delete Work Alert File
        if (SADM_MONITOR_RECENT_COUNT != 0) {                           # User want view last script
            show_activity($con,$alert_file);                            # lastest script that ran
        }
        echo "\n</table>\n" ;                                           # End of table
        echo "\n</tbody>\n";                                            # End of tbody
        return 0;                                                       # Return to Caller 
    }

    # Display page heading
    sysmon_page_heading();                                                # Show Notificationn Heading
    
    # Loop through sysmon array
    if ($DEBUG) {echo "\nIn 'DisplayAlertTable':\n<br>" ;var_dump ($array_sysmon); echo "\n<br>";}
    foreach ($array_sysmon as $line_num => $line) {
        if ($DEBUG) { 
            echo "\n<br>Processing Line #{$line_num} : ." .htmlspecialchars($line). ".<br />\n"; 
            echo "<br>Length of line #{$line_num} is ". strlen($line) . ".<br>\n"; 
        }
        if (strlen($line) > 4095) { continue ; }                        # Empty Line Exceeding 4095

        # Line Example: 
        # $whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$walert,$gtype,$wcode
        #    0      1       2       3       4       5       6        7       8      9
        #$line_array = explode(";",$line);
        display_line($line,$con);
    }

    echo "\n</table>\n" ;

    echo "\n</tbody>\n";                                            # End of tbody
}





# Display Main Page Data from the row received in parameter
#---------------------------------------------------------------------------------------------------
function display_data($con,$alert_file) {
    global $DEBUG, $URL_HOST_INFO, $URL_VIEW_FILE, $URL_WEB, $URL_VIEW_RCH, $URL_DOC_DIR;
    #$DEBUG = True ;

    echo "\n<tbody style: font-family: 'Arial', sans-serif;>\n";        # Start of Table Body

    $array_sysmon = array();                                            # Create an empty Array
    $array_sysmon = file($alert_file);                                  # Load Alert file in Array
    natsort($array_sysmon);                                             # Natural Sort Array 
    if ($DEBUG) { 
        echo "\nNb Lines in " .$alert_file. " is " .count(file($alert_file)). "\n<br>";
        echo "\nEntering 'display_data':\n<br>"; var_dump ($array_sysmon); echo "\n<br>"; 
        echo "\nSize of array is " . sizeof($array_sysmon) . "<br>" ; 
    }  

    # Show any alerts, Scripts Error,Warning or Running.
    if (sizeof($array_sysmon) < 1) {                                    # Array is empty 
        echo "<h3><center><strong><font color='#124f44'>" ;
        echo "***Nothing to report at the moment***"; 
        echo "</font></strong></center></h3>";
    }else{
        display_alert_table($con,$alert_file);                        # Show Error,Warning,Running
    }

    # Show History of recent scripts activity
    if (SADM_MONITOR_RECENT_COUNT > 0) { show_activity($con,$alert_file); }

    # CleanUp and return to caller
    echo "\n</table>\n" ;
    echo "\n</tbody>\n";                                                # End of tbody
    if (file_exists($alert_file)) { unlink($alert_file); }              # Delete Work Alert File
    return ;
}


#---------------------------------------------------------------------------------------------------
# Main Page Logic start here 
#---------------------------------------------------------------------------------------------------

    # Page header
    $title1="Systems Monitor Status";                                   # Page Title
    $title2 = date("Y-m-d H:i:s");
    display_lib_heading("HOME","$title1","Last update $title2",$SVER);

    create_alert_file();                                                # Cr. AlertFile from RPT/RCH
    display_data($con,$alert_file);                                     # Show AlertFile Array
    
    # Page footer
    echo "\n\n<center>Page is refresh every " . SADM_MONITOR_UPDATE_INTERVAL . " seconds.</center>";
    std_page_footer($con) ;                                              # Close MySQL & HTML Footer
?>
