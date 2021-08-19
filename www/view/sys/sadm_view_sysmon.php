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
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# ChangeLog
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#   2018_02_12 JDuplessis
#       v2.1 Added Some Debugging Information
#   2018_05_06 JDuplessis
#       2.2 Use Standard view file web page instead of custom vie log page
# 2018_08_14 v2.3 Added Alert Group associated with event
# 2018_09_30 v2.4 Enhance Performance, New Page Layout and Fix issue with rch new format.
# 2019_06_07 Update: v2.5 Add Alarm type to page (Deal with new format).
# 2019_08_04 Update: v2.6 Add Distribution Logo and modify status icons.
# 2019_09_25 Update: v2.7 Page has become starting page and change page Title.
# 2019_10_01 Update: v2.8 Page Added links to log, rch and script documentation.
# 2019_10_15 Update: v2.9 Add Architecture, O/S Name, O/S Version to page
# 2019_11_26 Fix: v2.10 Fix problem with temp files (Change from $SADMIN/tmp to $SADMIN/www/tmp)
# 2019_11_27 Fix: v2.11 Fix 'open append failed', when no *.rpt exist or are all empty.
# 2020_01_11 Update: v2.12 Remove Arch,Category and OS Version to make space on Line.
# 2020_01_13 Fix: v2.13 Bug fix, displaying empty error line.
# 2020_03_03 Update: v2.14 Server Description displayed when mouse over server name.
# 2020_05_13 Update: v2.15 Customize message when nothing to report.
# 2020_05_13 Update: v2.16 server name link was not displayed properly.
# 2020_09_23 Update: v2.17 Add Home button in the page heading.
#@2021_07_24 web v2.18 On System Monitor page, each alert now show group name (not default).
#@2021_08_06 web v2.19 On System Monitor page, notification type code now show description.
#@2021_08_07 web v2.20 New page redesign, Warning, Error, Info now have separate section.
#@2021_08_17 web v2.21 Use the refresh interval from SADMIN configuration file. 
#@2021_08_18 web v2.22 Make Bold section title
#
#Why not include last script that ran up to 2 hours ago ?
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
<?php

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

<!--  Refresh Pag every 60 Seconds -->
<meta http-equiv="refresh" content="<?php echo SADM_MONITOR_UPDATE_INTERVAL ?>;'">



<?php
# Local Variables
#---------------------------------------------------------------------------------------------------
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.22" ;                                                       # Current version number
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$URL_CREATE = '/crud/srv/sadm_server_create.php';                       # Create Page URL
$URL_UPDATE = '/crud/srv/sadm_server_update.php';                       # Update Page URL
$URL_DELETE = '/crud/srv/sadm_server_delete.php';                       # Delete Page URL
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_CURRENT= '/view/sys/sadm_view_sysmon.php';                         # This page Current URL
$URL_VIEW_FILE = '/view/log/sadm_view_file.php';                        # View File Content URL
$URL_VIEW_RCH  = '/view/rch/sadm_view_rchfile.php';                     # View RCH File Content URL
$URL_DOC_DIR   = '/doc/pdf/scripts/';                                   # URL Location of pdf 
$URL_WEB       = "https://sadmin.ca/";                                  # Main Site URL 
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$tmp_file1          = tempnam (SADM_WWW_TMP_DIR . "/", 'sysmon_tmp1_');
$tmp_file2          = tempnam (SADM_WWW_TMP_DIR . "/", 'sysmon_tmp2_');
$array_sysmon = [];                                                     # Create Empty Array
$alert_file = SADM_WWW_TMP_DIR . "/sysmon_alert_file_" . getmypid() ;   # File Being Built/Displayed



# Create one output file ($alert_file) that contain scripts errors & system monitor alerts.
# 1-Create alert file containing all *.rpt in $SADMIN/www/dat directories.
# 2-Then add last line of all to the *.rch in $SADMIN/www/dat that Failed(Code 1) or Running(Code 2)
#---------------------------------------------------------------------------------------------------
#
function create_alert_file() {
    global $DEBUG, $tmp_file1, $tmp_file2, $alert_file ;

    # Create the Alert file from all SYSTEM MONITOR REPORT FILE (*.RPT) in $SADM_WWW_DAT_DIR. 
    # Get content of all *.rpt files (Contain Error,Warning,Info reported by System Monitor)
    # EXAMPLE OF RPT LINE BELOW : 
    # Warning;holmes;2021.07.24;10:15;linux;FILESYSTEM;Filesystem /wsadmin at 82% >= 80%;default;default
    touch($alert_file);                                                 # Create empty alert file
    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rpt' -exec cat {} \; >> $alert_file";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }        # Show Cmd that we execute
    $a = exec ( $CMD , $FILE_LIST, $RCODE);                             # Execute the find command
    if ($DEBUG) {                                                       # Debug then,show cmd result
        echo "\n<br>Return code of command is : " . $RCODE ;            # Command return code
        echo "\n<br>Content of resulting file :";                       # Alert file heading
        $orig = file_get_contents($alert_file);                         # Read Alert file content
        $a = htmlentities($orig);                                       # Char. to HTML entities
        echo '<code><pre>';                                             # Code to be displayed
        echo $a;                                                        # Show Alert file
        echo '</pre></code>';                                           # End of code display
    }
    #fflush($file);                                                      # Fluch cache to disk

    # Get last line of ALL SCRIPT RESULT FILES (*.RCH) that finished with error or that are running.
    # Results will go into $tmp_file2 file.
    # EXAMPLE OF A RCH LINE BELOW :
    # ubuntu2104 2021.07.05 05:11:23 2021.07.05 05:11:32 00:00:09 sadm_backupdb default 1 0
    $CMD_PART1="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rch' -exec tail -1 {} \;" ;
    $CMD_PART2=" | awk 'match($10,/[1-2]/) { print }' > $tmp_file2 ";
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


    # Open the alert file, ready to be put in converted RCH to RPT Format.
    if ( file_exists ($alert_file) and (filesize($alert_file) > 0) ) 
    {
        if ($DEBUG) { echo "\n<br>Opening alert file in append mode"; }        
        $afile = fopen("$alert_file","a") or die("can't open in append mode file " . $alert_file );
    }else{
        if ($DEBUG) { echo "\n<br>Opening alert file in write mode"; }        
        $afile = fopen("$alert_file","w") or die("can't open in write mode file " . $alert_file );
    }


    # Convert the global RCH file just created ($tmp_file2) to a RPT format kind of lines 
    # raspi2 2018.09.29 23:25:00 2018.09.29 23:25:17 00:00:17 sadm_client_housekeeping default 1 1
    #   1        2         3         4        5        6               7                  8    9 10
    # To this type of lines (RPT)
    # Error;raspi2;2018.09.29;23:25;SADM;SCRIPT;sadm_client_housekeeping;sadm/1;sadm/1;
    #   1    2       3        4      5       6             7                     8     9
    $lines = file($tmp_file2);                                          # Load RCH Line into Array
    foreach ($lines as $line_num => $line) {                            # Process Each line in array
        if ($DEBUG) { echo "\n<br>RCH Before conversion :<code><pre>" .$line. '</pre></code>'; }
        list($whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$walert,$gtype,$wcode) = explode(" ",$line);
        $rdate = trim($wdate2);                                         # Event Date = Finish Date
        $rtime = substr(trim($wtime2),0,-3);                            # Event Time = Finish Time
        switch (trim($wcode)) {                                         # Based on Script Exit Code
            case 0:     $rtype = "Success" ;                            # Script Exit Code 0=Success
                        break;
            case 1:     $rtype = "Error" ;                              # Script Exit Code 1 = Error
                        break;
            case 2:     $rtype = "Running" ;                            # Script Exit Code 2=Running
                        $rdate = trim($wdate1);                         # Event Date is Start Date
                        $rtime = substr(trim($wtime1),0,-3);            # Event Time is Start Time
                        break;
            default:    $rtype = "Unknown" . $wcode ;                   # Unknown Script Exit Code 
                        break;
        }
        $rhost      = trim($whost);                                     # Host Name
        $rmod       = "SADM";                                           # Event Module name = SADM
        $rsubmod    = "SCRIPT";                                         # Event Sub-Module = SCRIPT
        $ragroup    = "${walert}";                                      # Alert Group 
        $ratype     = "${gtype}";                                       # Alert Type
        $ralert     = "${walert}/${gtype}";                             # Alert Group & Alert Type
        $rdesc      = $wscript ;                                        # Script Name 
        $LINE="${rtype};${rhost};${rdate};${rtime};${rmod};${rsubmod};${rdesc};${ralert};${ralert}\n";
        if ($DEBUG) { echo "\n<br>RCH After conversion :<code><pre>" .$LINE. '</pre></code>'; }
        fwrite($afile,$LINE);                                           # Write reformatted line
    }
    fclose($afile);                                                     # Close the ALert File
    if ($DEBUG) {                                                       # Show Final Alert File
        $orig = file_get_contents($alert_file);                         # Load Alert File
        $a = htmlentities($orig);                                       # Filter out Special Char.
        echo "\n\n<br><br>Final Alert file Content<code><pre>" .$a. '</pre></code>'; 
    }
    unlink($tmp_file1);                                                 # Delete Work File 1
    unlink($tmp_file2);                                                 # Delete Work File 2
}



# Display System Monitor Status Heading
# Input Parameters : 
#   1-  Heading type "E" for "Error", "W" for "Warning", "I" for "Info", "R" for ¨Running"
#---------------------------------------------------------------------------------------------------
function sysmon_page_heading($HEAD_TYPE)
{
    if (!$HEAD_TYPE) {
        echo "<br><b><font color='red'>";
        echo "Function sysmon_page_heading : Did not receive any parameter ?";
        echo "</b></font>";
        exit;
    }

    # Display Section Heading and Prefix Section with Environment
    switch (strtoupper($HEAD_TYPE)) {
        case 'E' :  echo "\n<br><H3><strong>Critical ALert</strong></H3>" ;
                    $HCOLOR = "Red";
                    break;
        case 'W' :  echo "\n<br><H3><strong>Warning Alert</strong></H3>" ;
                    $HCOLOR = "Yellow";
                    break;
        case 'R' :  echo "\n<br><H3><strong>Running Processes</strong></H3>" ;
                    $HCOLOR = "Lime";
                    break;
        case 'I' :  echo "\n<br><H3><strong>Information Section</strong></H3>" ;
                    $HCOLOR = "SkyBlue";
                    break;
        case 'X' :  echo "\n<br><H3><strong>Unknown Section</strong></H3>" ;
                    $HCOLOR = "Lavender";
                    break;
    }

    # Display Section Heading in the proper color
    echo "\n<table align=center border=0 cellspacing=0>";
    echo "\n<tr>";
    echo "\n<td colspan='1' bgcolor=$HCOLOR>&nbsp;&nbsp;</td>";
    echo "\n<td width=80  align='left'   bgcolor=$HCOLOR><b>System</b></td>";
    echo "\n<td colspan='3' bgcolor=$HCOLOR>&nbsp;&nbsp;</td>";
    echo "\n<td width=90  align='center' bgcolor=$HCOLOR><b>Event</td>";
    echo "\n<td width=90  align='center' bgcolor=$HCOLOR><b>Module</td>";
    echo "\n<td width=110 align='center' bgcolor=$HCOLOR><b>Alert</td>";
    echo "\n<td width=110 align='center' bgcolor=$HCOLOR><b>Alert Type</td>";
    echo "\n</tr>";
    echo "\n<tr>";
    echo "\n<td width=90  align='left'   bgcolor=$HCOLOR><b>&nbsp;Status</b></td>";
    echo "\n<td width=80  align='left'   bgcolor=$HCOLOR><b>Name</b></td>";
    echo "\n<td width=35  align='left'   bgcolor=$HCOLOR><b>O/S</b></td>";
    echo "\n<td width=30  align='center' bgcolor=$HCOLOR><b>Category</b></td>";
    echo "\n<td width=270 align='left'   bgcolor=$HCOLOR><b>Alert Description</b></td>";
    echo "\n<td width=90  align='center' bgcolor=$HCOLOR><b>Date/Time</td>";
    echo "\n<td width=90  align='center' bgcolor=$HCOLOR><b>Name</td>";
    echo "\n<td width=110 align='center' bgcolor=$HCOLOR><b>Group Name</td>";
    echo "\n<td width=110 align='center' bgcolor=$HCOLOR><b>Description</td>";
    echo "\n</tr>\n";
}




# Function used to display one section at a time (Warning, Error, Running, Info, and Unknow)
# Input Parameters :
#   1- String containing line to be displayed.
#---------------------------------------------------------------------------------------------------
function display_line($line,$BGCOLOR,$con) 
{
    global $DEBUG, $URL_HOST_INFO, $URL_VIEW_FILE, $URL_WEB, $URL_VIEW_RCH, $URL_DOC_DIR;

    # Split the line
    # Running;holmes;2019.09.30;10:39;SADM;SCRIPT;sadm_fetch_clients;default/1;default/1 
    list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$warngrp,$errgrp)=explode(";",$line);

    # Show Status Icons 
    echo "\n<tr>";                                                      # Start of line
    switch (strtoupper($wstatus)) {                                     # Depend on Uppercase Status
        case 'ERROR' :                                                  # If an Error Line
            echo "\n<td  bgcolor=$BGCOLOR style='vertical-align:middle'><span data-toggle='tooltip' title='Error Reported'>";
            echo "<img src='/images/sadm_error.png' ";                  # Show error Icon
            echo "style='width:96px;height:40px;'></span></td>";        # Status Standard Image Size
            $alert_group=$errgrp;                                       # Set Event Alert Group
            break;
        case 'WARNING' :
            echo "\n<td bgcolor=$BGCOLOR align='left'><span data-toggle='tooltip' title='Warning Reported'>";
            echo "<img src='/images/sadm_warning.png' ";            # Show Warning Icon
            echo "style='width:96px;height:40px;'></span></td>";    # Status Standard Image Size
            $alert_group=$warngrp;                                  # Set Event Alert Group
            break;
        case 'RUNNING' :                                            # Running Status = Script
            echo "\n<td bgcolor=$BGCOLOR align='left'><span data-toggle='tooltip' title='Script currently running'>";
            echo "<img src='/images/sadm_running.png' ";            # Show Running Icon
            echo "style='width:96px;height:40px;'></span></td>";    # Status Standard Image Size
            $alert_group=$errgrp;                                   # Script group 
            break;
        case 'INFO' :                                               # Information from MOnitor
            echo "\n<td bgcolor=$BGCOLOR align='left'><span data-toggle='tooltip' title='System Information'>";
            echo "<img src='/images/sadm_info.png' ";               # Show Running Icon
            echo "style='width:96px;height:40px;'></span></td>";    # Status Standard Image Size
            $alert_group=$errgrp;                                   # Script group 
            break;
        default:
            echo "\n<td bgcolor=$BGCOLOR align='left'><span data-toggle='tooltip' title='Unknown Status'>";
            echo "<img src='/images/question_mark.jpg' ";           # Show Question Mark
            echo "style='width:96px;height:40px;'></span> Unknown</td>";
            $alert_group="default";                                 # Set Event Alert Group
            break;
    }

    # Get Server Description, O/S and O/S version.
    $sql ="SELECT * FROM server where srv_name = '". $whost . "';"; # Construct select 
    if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
        $WDESC = "Server not in Database";                          # Server not found descr.
        $WOS   = "Unknown";                                         # O/S name is unknown
        $WVER  = "Unknown";                                         # O/S Version is unknown
        $WCAT  = "Unknown";                                         # Server Category is unknown
    }else{
        $row = mysqli_fetch_assoc($result);                         # Fetch server info
        $WDESC = $row['srv_desc'];                                  # Save Server Description
        $WOS   = $row['srv_osname'];                                # Save Server O/S Name
        $WVER  = $row['srv_osversion'];                             # Save Server O/S Version
        $WCAT  = $row['srv_cat'];                                   # Save Server Category
        mysqli_free_result($result);                                # Free result set 
    }

    #-----Server Name -----
    echo "\n<td  bgcolor=$BGCOLOR align='left'>";
    echo "<a href='" . $URL_HOST_INFO . "?sel=" . nl2br($whost) ;
    echo "' title='$WDESC at " . $row['srv_ip'] . "'>" ;
    echo nl2br($whost) . "</a></td>\n";

    #----- Display Operating System Logo -----
    $WOS   = sadm_clean_data($row['srv_osname']);                   # Set Server O/S Name
    switch (strtoupper($WOS)) {
        case 'REDHAT' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_redhat.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'FEDORA' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_fedora.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'MACOSX' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_apple.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'CENTOS' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_centos.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'UBUNTU' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_ubuntu.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'LINUXMINT' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_linuxmint.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'DEBIAN' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_debian.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'RASPBIAN' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_raspbian.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'SUSE' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_suse.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'AIX' :
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_aix.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        default:
            echo "<td bgcolor=$BGCOLOR><img src='/images/logo_linux.png' ";
            echo "style='width:24px;height:24px;'>";
            echo "${WOS}</td>\n";
            break;
    }


    #-----Server Category Name -----
    echo "\n<td  bgcolor=$BGCOLOR align='center'>"  . $WCAT . "</td>\n";
    

    #----- Show Event Description -----
    $wlog =  $whost . "_" . $wdesc . ".log";                        # Construct Script log Name
    $log_name = SADM_WWW_DAT_DIR . "/" .$whost. "/log/" .trim($wlog); # Full Path to Script Log
    $wrch =  $whost . "_" . $wdesc . ".rch";                        # Construct Script rch Name
    $rch_name = SADM_WWW_DAT_DIR . "/" .$whost. "/rch/" .trim($wrch); # Full Path to Script rch  
    echo "<td bgcolor=$BGCOLOR>";                                   # Start of Cell
    echo $wdesc ;                                                   # Desc. coming from rpt file

    # If a script produce link to log and history file if exist.
    if ($wsubmod == "SCRIPT") {                                     # Module is a Script ?
      if (file_exists($log_name)) {                                 # Log File Exist ?
           echo str_repeat('&nbsp;', 2) . "\n<a href='" . $URL_VIEW_FILE . "?";
           echo "filename=" . $log_name . "' title='View script log - ";
           echo $wlog . "'>[log]</a>";                              # Create link to view log
      }
      if (file_exists($rch_name)) {                                 # History file RCH exist ?
          echo str_repeat('&nbsp;', 2) . "\n<a href='" . $URL_VIEW_RCH . "?";
          echo "host=" .$whost . "&filename=" . $wrch . "' title='View script history file - ";
          echo $wrch . "'>[rch]</a>";                               # Create link to view rch
      }
    } 

    # Produce Link to documentation if module exist in pgm2doc cfg file
    if ($wsubmod == "SCRIPT") {                                     # Module is a Script ?
        $doc_link = getdocurl("$wdesc") ;                           # Get Script Name Link
        if ( $doc_link != "" ) {                                    # We have a valid link ?
            echo str_repeat('&nbsp;', 2) . "\n<a href='" . $URL_WEB . $doc_link ;
            echo "' title='View script documentation'>[doc]</a>";
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
    echo "\n<td bgcolor=$BGCOLOR align='center'>" . $wdate . " " . $wtime . "</td>";

    # Event Module Name (All lowercase, except first character).
    echo "\n<td bgcolor=$BGCOLOR align='center'>" . ucwords(strtolower($wsubmod)) . "</td>";

    # Show Event Alert Group
    $pieces = explode("/", $alert_group);
    $str=preg_replace('/\s+/', '', $str);
    if ($DEBUG) { echo "pieces[0]=..$pieces[0].. pieces[1]=..$pieces[1].."; }               
    $alert_group = preg_replace('/\s+/', '', $pieces[0]);           # Isolate Alert Grp Name
    $org_alert_group = $alert_group;                                # Save Original AlertGrpName
    $alert_type  = preg_replace('/\s+/', '', $pieces[1]);           # Isolate Alert Type
    if ( $alert_type == "" ) { $alert_type=1 ; }                    # Default Alert Type
    if ($DEBUG) { echo "1) alert_group=..$alert_group.. alert_type=..$alert_type.."; }               

    # If 'default' alert group is used, get the real alert group name used.
    if ($alert_group == "default") {                            # If Alert Group is default
        $CMD="grep -i \"^default\" " . SADM_ALERT_FILE . " |awk '{print$3}' |tr -d ' '";
        if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; } 
        unset($output_array);                                       # Clear output Array
        exec ( $CMD , $output_array, $RCODE);                       # Execute command
        if ($DEBUG) {                                               # If in Debug Mode
            echo "\n<br>Return code of command : " . $RCODE ;       # Command ReturnCode
            echo "\n<br>Content of output array:";                  # Show what's next
            echo '<code><pre>';                                     # Code to Show
            print_r($output_array);                                 # Show Cmd output
            echo '</pre></code>';                                   # End of code 
        }
        $alert_group=$output_array[0];                              # Alert Grp Name
        if ($DEBUG) { echo "2) alert_group=..$alert_group.. alert_type=..$alert_type.."; }               
    }

    # Get the group Alert Type (M=Mail, S=SLack, T=Texto, C=Cellular)
    #$CMD="grep -i \"^" . $org_alert_group . "\" " . SADM_ALERT_FILE . "|awk '{print$2}' |tr -d ' '";
    $CMD="grep -i \"^" . $alert_group . "\" " . SADM_ALERT_FILE . " |awk '{print$2}' |tr -d ' '";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ;}     # Cmd we execute
    unset($output_array);                                           # Clear output Array
    exec ( $CMD , $output_array, $RCODE);                           # Execute command
    if ($DEBUG) {                                                   # If in Debug Mode
        echo "\n<br>Return code of command is : " . $RCODE ;        # Command ReturnCode
        echo "\n<br>Content of output array :";                     # Show what's next
        echo '<code><pre>';                                         # Code to Show
        print_r($output_array);                                     # Show Cmd output
        echo '</pre></code>';                                       # End of code 
    }
    $alert_group_type=$output_array[0];                             # GrpType t,m,s,c
    if ($DEBUG) { echo "3) alert_group=..$alert_group.. alert_type=..$alert_type.."; }               

    # Get content (email address, cell no, slack ID, Texto member) of the alert group.
    $CMD="grep -i \"^" . $alert_group . "\" " . SADM_ALERT_FILE . " |awk '{print$3}' |tr -d ' '";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ;}     # Cmd we execute
    unset($output_array);                                           # Clear output Array
    exec ( $CMD , $output_array, $RCODE);                           # Execute command
    if ($DEBUG) {                                                   # If in Debug Mode
        echo "\n<br>Return code of command is : " . $RCODE ;        # Command ReturnCode
        echo "\n<br>Content of output array :";                     # Show what's next
        echo '<code><pre>';                                         # Code to Show
        print_r($output_array);                                     # Show Cmd output
        echo '</pre></code>';                                       # End of code 
    }
    $alert_member=$output_array[0];                                 # Alert Group Member

    # Build to tooltip for the alert group 
    switch (strtoupper($alert_group_type)) {
        case 'M' :  $stooltip="Alert send by email to " . $alert_member ;  # Alert Sent by Email
                    break;
                    ;; 
        case 'C' :  $stooltip="Alert send by SMS to " . $alert_member ;    # Alert Sent by SMS
                    break;
                    ;; 
        case 'T' :  $stooltip="Alert send by SMS to " . $alert_member ;    # Alert Sent by SMS
                    break;
                    ;; 
        case 'S' :  $stooltip="Alert send with Slack to " . $alert_member ;# Alert Sent by SMS
                    break;
                    ;; 
        default  :  $stooltip="Invalid Alert type(" . $alert_type .")";
                    break;
                    ;;
    }                    

    # Show Alert Group with Tooltip
    echo "\n<td bgcolor=$BGCOLOR align='center'>" ;
    echo "<span data-toggle='tooltip' title='" . $stooltip . "'>"; 
    echo $alert_group . "</span>(" . $alert_group_type . ")</td>"; 


    # Show Alert type Meaning
    switch ($alert_type) {                                          # 0=No 1=Err 2=Success 3=All
        case 0 :                                                    # 0=Don't send any Alert
            $alert_type_msg="No alert(0)" ;                         # Mess to show on page
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
            break;
        case 3 :                                                        # 3=Always Send Alert
            $alert_type_msg="Always alert(3)" ;                         # Mess to show on page
            break;
        default:
            $alert_type_msg="Unknown code($alert_type)" ;               # Invalid Alert Group Type
            break;
    }        
    echo "\n<td bgcolor=$BGCOLOR align='center'>" ;
    echo "<span data-toggle='tooltip' title='" . $etooltip . "'>"; 
    echo $alert_type_msg . "</span></td>"; 
    echo "\n</tr>";
}




# Display Main Page Data from the row received in parameter
#---------------------------------------------------------------------------------------------------
function display_data($con,$alert_file) {
    global $DEBUG, $URL_HOST_INFO, $URL_VIEW_FILE, $URL_WEB, $URL_VIEW_RCH, $URL_DOC_DIR;

    echo "\n<tbody style: font-family: 'Ubuntu', sans-serif;>\n";       # Start of Table Body
    $array_sysmon = file($alert_file);                                  # Put Alert file in Array
    natsort($array_sysmon);                                             # Sort Array 
    if ($DEBUG) { echo "\nFINAL ARRAY CONTENT\n<br>" ; var_dump ($array_sysmon); echo "\n<br>" ; }  
    #echo "\nFINAL ARRAY CONTENT\n<br>" ; var_dump ($array_sysmon); echo "\n<br>" ; 

    # If nothing to report
    if (sizeof($array_sysmon) == 0) {                                   # Array Empty everything OK
        echo "<tr>\n";                                                  # Start of line
        echo "\n<td class='dt-center' colspan='7'>";                    # Span the 7 columns
        echo "Nothing to report" ;                                      # Indicate everything OK
        echo "\n</td>\n</tr>\n<br>";                                    # End of table row
        echo "\n</table>\n</tbody>\n";                                  # End of tbody,table
        unlink($alert_file);                                            # Delete Work Alert File
        return;                                                         # Return to Caller 
    }
    
    # Initialize default value before entering the loop.
    $wheading = false ;                                                 # Init. Warning values
    $eheading = false ;                                                 # Init. Error values
    $rheading = false ;                                                 # Init. Running values
    $iheading = false ;                                                 # Init. Info Section values
    $xheading = false ; ;                                               # Init. Default values
    $current_section="";                                                # Last Section Processed

 

    # Loop through the array and process ERROR first 
    foreach ($array_sysmon as $line_num => $line) {
        if ($DEBUG) { 
            echo "\nProcessing Line #{$line_num} : ." .htmlspecialchars($line). ".<br />\n"; 
            echo "Length of line #{$line_num} is ". strlen($line) ; 
        }
        if (strlen($line) > 4095) { continue ; }                        # Empty Line Exceeding 4095
        # Running;holmes;2019.09.30;10:39;SADM;SCRIPT;sadm_fetch_clients;default/1;default/1 
        list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$warngrp,$errgrp)=explode(";",$line);
        if (strtoupper($wstatus) == "ERROR") {
            if (! $eheading) { sysmon_page_heading ('E') ; $eheading=True ; $wcount=0; } 
            $wcount += 1;
            if ($wcount % 2 == 0) $BGCOLOR="#fff1e6" ; else $BGCOLOR="#f0efeb" ;
            display_line($line,$BGCOLOR,$con);
        }
    }
    if ($eheading) { echo "\n</tr>\n</table>\n" ; }                     # If data Shown,End of Table


    # Loop through the array and process WARNING first 
    foreach ($array_sysmon as $line_num => $line) {
        if ($DEBUG) { 
            echo "\nProcessing Line #{$line_num} : ." .htmlspecialchars($line). ".<br />\n"; 
            echo "Length of line #{$line_num} is ". strlen($line) ; 
        }
        if (strlen($line) > 4095) { continue ; }                        # Empty Line Exceeding 4095
        # Running;holmes;2019.09.30;10:39;SADM;SCRIPT;sadm_fetch_clients;default/1;default/1 
        list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$warngrp,$errgrp)=explode(";",$line);
        if (strtoupper($wstatus) == "WARNING") {
            if (! $wheading) { sysmon_page_heading ('W') ; $wheading=True ; $wcount=0; } 
            $wcount += 1;
            if ($wcount % 2 == 0) $BGCOLOR="#fff1e6" ; else $BGCOLOR="#f0efeb" ;
            display_line($line,$BGCOLOR,$con);
        }
    }
    if ($wheading) { echo "\n</tr>\n</table>\n" ; }                     # If data Shown,End of Table


    # Loop through the array and process RUNNING first 
    foreach ($array_sysmon as $line_num => $line) {
        if ($DEBUG) { 
            echo "\nProcessing Line #{$line_num} : ." .htmlspecialchars($line). ".<br />\n"; 
            echo "Length of line #{$line_num} is ". strlen($line) ; 
        }
        if (strlen($line) > 4095) { continue ; }                        # Empty Line Exceeding 4095
        # Running;holmes;2019.09.30;10:39;SADM;SCRIPT;sadm_fetch_clients;default/1;default/1 
        list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$warngrp,$errgrp)=explode(";",$line);
        if (strtoupper($wstatus) == "RUNNING") {
            if (! $rheading) { sysmon_page_heading ('R') ; $rheading=True ; $wcount=0;} 
            $wcount += 1;
            if ($wcount % 2 == 0) $BGCOLOR="#fff1e6" ; else $BGCOLOR="#f0efeb" ;
            display_line($line,$BGCOLOR,$con);
        }
    }
    if ($rheading) { echo "\n</tr>\n</table>\n" ; }                     # If data Shown,End of Table
   


    # Loop through the array and process INFO line
    foreach ($array_sysmon as $line_num => $line) {
        if ($DEBUG) { 
            echo "\nProcessing Line #{$line_num} : ." .htmlspecialchars($line). ".<br />\n"; 
            echo "Length of line #{$line_num} is ". strlen($line) ; 
        }
        if (strlen($line) > 4095) { continue ; }                        # Empty Line Exceeding 4095
        # Running;holmes;2019.09.30;10:39;SADM;SCRIPT;sadm_fetch_clients;default/1;default/1 
        list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$warngrp,$errgrp)=explode(";",$line);
        if (strtoupper($wstatus) == "INFO") {
            if (! $iheading) { sysmon_page_heading ('I') ; $iheading=True ; $wcount=0; } 
            $wcount += 1;
            if ($wcount % 2 == 0) $BGCOLOR="#fff1e6" ; else $BGCOLOR="#f0efeb" ;
            display_line($line,$BGCOLOR,$con);
        }
    }
    if ($iheading) { echo "\n</tr>\n</table>\n" ; }                     # If data Shown,End of Table


    echo "\n</tbody>\n";                                                # End of tbody
    unlink($alert_file);                                                # Delete Work Alert File
}




# Main Page Logic start here 
#---------------------------------------------------------------------------------------------------
#
    $title1="Systems Monitor Status";                                   # Page Title
    #$title2="Page is refresh every ". SADM_MONITOR_UPDATE_INTERVAL . " seconds.";   # Be sure user knows
    display_lib_heading("HOME","$title1"," ",$SVER);                    # Display Content Heading
    create_alert_file();                                                # Create AlertFile (RPT/RCH)
    display_data($con,$alert_file);                                     # Display SysMOn Array
    
    # Page footer
    echo "\n<br><center>\n" ;
    echo "Page will refresh every " . SADM_MONITOR_UPDATE_INTERVAL . " seconds." ;
    echo "\n</center><br>\n";
    std_page_footer($con) ;                                              # Close MySQL & HTML Footer
    #Send a Refresh header.
    #header('Refresh: ' . SADM_MONITOR_UPDATE_INTERVAL);
#    header('Refresh: 5');
?>
