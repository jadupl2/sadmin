<?php
#!/usr/bin/env  php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadmPageSideBar.php
#   Version     :  1.8
#   Date        :  21 June 2016
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Use to display the SADM Side Bar at the left of every page.
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
#
# ChangeLog
# 2017_10_06 web v1.0  SideBar - Initial version
# 2018_02_07 web v2.1  SideBar - Added Performance Link in SideBar
# 2018_07_09 web v2.2  SideBar - Change SideBar Layout
# 2018_07_21 web v2.3  SideBar - If an RCH is malformed (Less than 8 fields) it is ignored 
# 2018_09_16 web v2.4  SideBar - Add Alert Group in RCH Array
# 2018_09_22 web v2.5  SideBar - Failed Script counter was wrong
# 2019_01_05 web v2.6  SideBar - Add SideBar link to view all servers CPU performance on one page.
# 2019_06_07 web v2.7  SideBar - Updated to deal with the new format of the RCH file.
# 2019_07-15 web v2.8  SideBar - Add 'Backup Status Page' & Fix RCH files.
# 2019_08-26 web v2.9  SideBar - Add 'Rear Backup Status Page' 
# 2019_08-30 web v2.10 SideBar - Side Bar re-arrange order.
# 2019_09-23 web v2.11 SideBar - Change 'Status' for ' Job' in Sidebar.
# 2019_12_01 web v2.12 SideBar - Shorten label name of sidebar.
# 2022_06_02 web v2.14 SideBar - Change some syntax due to the new PHP v8 on RHEL9
# 2022_07_13 web v2.15 SideBar - Show alert when final 'rch' summary file couldn't be opened.
# 2022_07_18 web v2.16 SideBar - Fix problem, sidebar wouldn't displayed correctly.
# 2022_09_12 web v3.0 SideBar - Move 'Server Attribute' section before 'Server Info'.
# 2023_09_12 web v3.1 SideBar - Side Bar modification & enhancement
# 2023_09_21 web v3.2 SideBar - Remove some debugging information.
# 2023_10_17 web v3.3 SideBar - PHP Code Optimization.
# ==================================================================================================
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');  # <head>CSS,JavaScript</Head>
#require      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
#require      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
#require      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');  # <head>CSS,JavaScript</Head>
#echo "\n<body>";
echo "\n\n<div class='SideBar'>";



#===================================================================================================
#                                      GLOBAL Variables
#===================================================================================================
#
$DEBUG = False;                                                         # Debug Activated True/False
$SVER  = "3.3";                                                         # Current version number
$URL_SERVER    = '/view/srv/sadm_view_servers.php';                     # Show Servers List URL
$URL_OSUPDATE  = "/view/sys/sadm_view_schedule.php";                    # View O/S Update Status URL 
$URL_BACKUP    = "/view/sys/sadm_view_backup.php";                      # View Backup Status URL 
$URL_MONITOR   = "/view/sys/sadm_view_sysmon.php";                      # View System Monitor URL 
$URL_EDIT_CAT  = '/crud/cat/sadm_category_main.php';                    # Maintenance Cat. Page URL
$URL_EDIT_GRP  = '/crud/grp/sadm_group_main.php';                       # Maintenance Grp. Page URL
$URL_EDIT_SRV  = '/crud/srv/sadm_server_main.php';                      # Maintenance Srv. Page URL
$URL_RCH_SUMM  = '/view/rch/sadm_view_rch_summary.php';                 # Return Code History View
#$URL_NETWORK  = '/view/sys/sadm_subnet.php';                           # Network Scan Result URL
$URL_NETWORK   = '/view/net/sadm_view_subnet.php';                      # Network Scan Result URL
$URL_PERF      = '/view/perf/sadm_server_perf_menu.php';                # Performance Graph Menu URL
$URL_PERF_DAY  = '/view/perf/sadm_server_perf_adhoc_all.php';           # Yesterday Servers CPU Perf
$URL_VIEW_REAR = "/view/sys/sadm_view_rear.php";                        # Rear Back Status Page
$sadm_array    = array() ;                                              # Create an empty array



// ================================================================================================
//                   Build Array Used by SideBar for Scripts Status 
// ================================================================================================
function build_sidebar_scripts_info()
{
    $count = 0;                                                         # Working Counter
    $script_array = array();                                            # Define an Empty Array
    $DEBUG = False; 

    # Define RCH_ROOT where all systems rch files exist and if it doesn't exist show error msg.
    $RCH_ROOT = $_SERVER['DOCUMENT_ROOT'] . "/dat";                     # $SADMIN/www/dat
    if ($DEBUG) { echo "<br>Opening $RCH_ROOT directory "; }            # Debug Display RCH Root Dir
    if (! is_dir($RCH_ROOT)) {                                          # /opt/sadmin/www/dat!=exist
        $msg="\nThe directory $RCH_ROOT doesn't exist !\nCorrect the situation & retry operation\n";
        sadm_alert ("$msg");                                            # Display Alert Box with msg
        ?><script type="text/javascript">history.go(-1);</script><?php
        return $script_array;
    }

    # Create file that will contains the last line of all *.rch.
    $tmp_rch = tempnam($_SERVER['DOCUMENT_ROOT'] . "/tmp/", 'ref_rch_file_'); 
    chmod ("$tmp_rch",0664);
    if ($DEBUG) { echo "<br>Tmp filename : " . $tmp_rch ; }             # Show unique filename
    $CMD = "find " .$RCH_ROOT. " -name '*.rch' -type f -exec tail -1 {} \\; > $tmp_rch" ;
    if ($DEBUG) { echo "<br>\nCommand executed is : " . $CMD . "\n"; }  # Show command constructed
    $last_line = system ("$CMD",$RCODE);                                # Execute find command

    # Open list of rch file and put it in $rch_lines.
    $fh = fopen($tmp_rch,"r");
    if (! $fh) {
        $errStr = "Failed to open temporary rch work file '{$tmp_rch}'.";
        sadm_alert ("$errStr"); 
        unlink($tmp_rch);                                               # Delete Temp File
        return $script_array;
    }
    $rch_lines = explode("\n", fread($fh, filesize($tmp_rch)));
    fclose($fh);
    if ($DEBUG) { echo "<br>rch_lines size : " . count($rch_lines) ; }  # Show Nb of rch line in tmp

    foreach($rch_lines as $rch_line) {
        $rch_array  = explode(" ",$rch_line);                           # rch last line in array
        $num_tags   = count($rch_array);                                # Nb Elements on rch line
        if (($num_tags != 10) or ($num_tags == 0)) { continue ; }       # Skip invalid format file
        $outline = $rch_array[0] .",". $rch_array[1] .",". $rch_array[2] .",". $rch_array[3] ;
        $outline = $outline      .",". $rch_array[4] .",". $rch_array[5] .",". $rch_array[6] ;
        $outline = $outline      .",". $rch_array[7] .",". $rch_array[8] .",". trim($rch_array[9]) ;
        $outline = $outline      .",". $rch_array[0] ."_". $rch_array[6] ."\n";
        $count+=1;
        $akey = $rch_array[1] ."_". $rch_array[2] ."_". $rch_array[0] ."_". $rch_array[6]; # Date+Time+FileName
        if (array_key_exists("$akey",$script_array)) {                  # If Key already exist
           $script_array[$akey] = $outline . "_" . $count ;             # Store line with count
        }else{                                                          # If Key doesn't exist
           $script_array[$akey] = $outline ;                            # Store line in Array
        }
    }

    krsort($script_array);                                              # Reverse Sort Array on Keys
    unlink($tmp_rch);                                                   # Delete Temp File
    #if ($DEBUG) { echo "<br>script_array : " .count($script_array); }  # Show Nb of rch line in tmp
    #if ($DEBUG) {foreach($script_array as $key=>$value) { echo "<br>Key,value $key,$value";}}
    $DEBUG = False ; 
    return $script_array;
}




# ==================================================================================================
# This function read the server table and collect info to build the SideBar (Except Scripts Status)
# The function return an array with the information needed to display the SideBar info
# ==================================================================================================
function build_sadm_array_from_db() {
    global $con, $sadm_array ;                                          # Global Database Conn. Obj.

    # Loop Through Retrieved Data and Display each Row
    $sql = "SELECT * FROM server ;";                                    # Construct SQL Statement
    
    # Execute the Row Update SQL
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute Update Row SQL
        $err_line = (__LINE__ -1) ;                                     # Error on proceeding line
        $err_msg1 = "Error on select server\nError (";                  # Advise User Message 
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        exit;
    }

    # Reset All Counters
    $count=0;                                                           # Server counter Reset
    $sadm_array = array() ;                                             # Create an empty array

    # Read All Server Table
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Server Counter

        # Process O/S Type
        $akey = "srv_ostype," . $row['srv_ostype'];                     # Array Key For O/S Type
        if (array_key_exists($akey,$sadm_array)) {                      # If O/S Type Already There
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;               # Add 1 to Counter
        }else{                                                          # ostype not in array
            $sadm_array[$akey] = 1 ;                                    # Set initital counter to 1
        }

        # Process O/S Name
        $akey = "srv_osname," . $row['srv_osname'];                     # Array Key For O/S Name
        if (array_key_exists($akey,$sadm_array)) {                      # If O/S Name Already There
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;               # Add 1 to O/S Name Counter
        }else{                                                          # If O/S Name Not Found
            $sadm_array[$akey] = 1 ;                                    # Set Initial Counter to 1
        }

        # Count Number of Active Servers
        if ($row['srv_active'] == TRUE) {                               # If server is active
            $akey = "srv_active," ;                                     # Set Array key 
            if (array_key_exists($akey,$sadm_array)) {                  # If Key already exist
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;           # Add 1 to counter
            }else{                                                      # If key not in array
                $sadm_array[$akey] = 1 ;                                # Set initial counter to 1
            }
        }

        # Count Number of Inactive Servers
        if ($row['srv_active']  == FALSE) {                             # If server is inactive
            $akey = "srv_inactive," ;                                   # Set Array Key 
            if (array_key_exists($akey,$sadm_array)) {                  # If Key already in Array
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;           # Add 1 to srv_active value
            }else{                                                      # If Key not in Array
                $sadm_array[$akey] = 1 ;                                # Set initial counter to 1
            }
        }

        # Count Number of Physical and Virtual Servers
        if ($row['srv_vm'] == TRUE) {                                   # If server is a Virtual Srv
            $akey = "srv_vm," ;                                         # Set Array Key
            if (array_key_exists($akey,$sadm_array)) {                  # If Key already in Array
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;           # Add 1 to srv_vm Value
            }else{                                                      # If key not in array
                $sadm_array[$akey] = 1 ;                                # Set Initial Value to 1
            }
        }else{
            $akey = "srv_physical," ;                                   # Set Array Key for Physical
            if (array_key_exists($akey,$sadm_array)) {                  # If Key Already in Array
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;           # Add 1 to srv_physical
            }else{                                                      # If key not in Array
                $sadm_array[$akey] = 1 ;                                # Set Initial Value to 1
            }
        }

        # Count Number of Physical and Virtual Servers
        if ($row['srv_sporadic']  == TRUE) {                            # If Server is Sporadic Srv.
            $akey = "srv_sporadic," ;                                   # Set Array key 
            if (array_key_exists($akey,$sadm_array)) {                  # If Key Already in Array
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;           # Add 1 to srv_sporadic
            }else{                                                      # If Key not Found in Array
                $sadm_array[$akey] = 1 ;                                # Set Initial Value to 1
            }
        }

    }

    # Array is loaded Now - Activate Debug below to print the Array
    ksort($sadm_array);                                                 # Sort Array Based on Keys
    $DEBUG=False;                                                       # Put True to view Array

    # Under Debug - Display The Array Used to build the SideBar
    if ($DEBUG) {                                                       # If Debug is activated
        foreach($sadm_array as $key=>$value) {                          # For each item in Array
            echo "<br>Key is $key and value is $value";                 # Print Array Key and Value
        }
    }
    return $sadm_array;                                                 # Return Array to Caller
}


# ==================================================================================================
# Show O/S Distribution
# ==================================================================================================
function show_os_distribution() {
    global $sadm_array, $URL_SERVER;                                    # Global Database Conn. Obj.

    $SERVER_COUNT=0;                                                    # Total Servers Reset
    echo "\n<div class='SideBarTitle'>O/S Distribution</div>";          # SideBar Section Title
    foreach($sadm_array as $key=>$value) {                                
        list($kpart1,$kpart2) = explode(",",$key);                      # Split Array Key and Value 
        if ($kpart1 == "srv_osname") {                                  # Here Process O/s Name Only
            echo "\n<div class='SideBarItem'>";                         # SideBar Item Div Class
            echo "<a href='" . $URL_SERVER . "?selection=os";           # View server O/S URL           
            echo "&value=" . $kpart2 ."'>";                             # Add O/S to UTL Selection
            echo $value . " " ;                                         # Display O/S Name on Page
            if ($kpart2 == "") {                                        # If O/S as no Name
                echo "Unknown";                                         # Print Unknown
            }else{                                                      # Else
                echo ucfirst($kpart2);                                  # Print O/S Name
            }
            echo "</a></div>";                                           # End of HREF and Div
            $SERVER_COUNT = $SERVER_COUNT + $value;                      # Add Value to Total OS Name
        }
    }
    # Print Total Servers 
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_SERVER . "?selection=all_servers'";         # View server O/S URL           
    echo ">Total " .$SERVER_COUNT. " systems</a></div>";                 # Display Server Count
    echo "\n<hr/>"; 
}



# Show Systems attributes
# ==================================================================================================
function show_server_attribute() {
    global $sadm_array, $URL_SERVER;                                    # Global Database Conn. Obj.

    echo "\n<div class='SideBarTitle'>Systems Attribute</div>";         # SideBar Section Title

	# DISPLAY NUMBER OF ACTIVE SERVER
    $kpart2 = $sadm_array["srv_active,"];                               # Array Key for Act. Server
    if ( $kpart2 != 0 ) {                                             # If Nb. Active server is 0
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_active'>";     # View Active server URL
        echo "$kpart2 Active(s)</a></div>";                           # Print Nb. of Active Server
    }else{
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "0 Active</div>";                                          # Print Nb. of Active Server
    }

    # DISPLAY NUMBER OF INACTIVE SERVERS
    $kpart2 = $sadm_array["srv_inactive,"];                             # Array Key for Inact. Srv.
    if ( $kpart2 != 0 ) {                                             # If no Inactive server
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_inactive'>";   # View Inactive server URL
        echo "$kpart2 Inactive(s)</a></div>";                         # Print Nb. Inactive Server
    }else{
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "0 Inactive</div>";                                        # Print Nb. Inactive Server
    }

    # DISPLAY NUMBER OF VIRTUAL SERVERS
    $kpart2 = $sadm_array["srv_vm,"];                                   # Array Key for Virtual Srv.
    if ( $kpart2 != 0 ) {                                             # If no Virtual Server
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_vm'>";         # View Virtual server URL
        echo "$kpart2 Virtual(s)</a></div>";                          # Print Nb. of Virtual Srv. 
    }else{
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "0 Virtual</div>";                                         # Print Nb. of Virtual Srv. 
    }

    # DISPLAY NUMBER OF PHYSICAL SERVERS
    $kpart2 = $sadm_array["srv_physical,"];                             # Array Key for Physical Srv
    if ( $kpart2 != 0 ) {                                             # If No Physical Server
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_physical'>";   # View Physical server URL
        echo "$kpart2 Physical(s)</a></div>";                         # Print Nb. of Physical Srv.
    }else{
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "0 Physical</div>";                                        # Print Nb. of Physical Srv.
    }

    # DISPLAY NUMBER OF SPORADIC SERVERS
    $kpart2 = $sadm_array["srv_sporadic,"];                             # Array Key for Sporadic Srv
    if ( $kpart2 != 0 ) {                                             # If no sporadic servers
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_sporadic'>";   # View Sporadic server URL
        echo "$kpart2 Sporadic(s)</a></div>";                         # Print Nb. of Sporadic Srv.
    }else{
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "0 Sporadic</div>";                                        # Print Nb. of Sporadic Srv.
    }
    echo "\n<hr/>";                                                     # Print Horizontal Line
}




# Show scripts status
# ==================================================================================================
function show_scripts_status() {
    global $sadm_array, $URL_RCH_SUMM ;

    echo "\n<div class='SideBarTitle'>Scripts Status</div>";            # SideBar Section Title
	$script_array = build_sidebar_scripts_info();                       # Build $script_array
    $TOTAL_FAILED=0; $TOTAL_SUCCESS=0; $TOTAL_RUNNING=0;                # Initialize Total to Zero

    # Loop through Script Array to count Different Return Code
    foreach($script_array as $key=>$value) {
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$calert,$ctype,$ccode,$cfile) = explode(",", $value);
        if ($ccode == 0) { $TOTAL_SUCCESS += 1; }
        if ($ccode == 1) { $TOTAL_FAILED  += 1; }
        if ($ccode == 2) { $TOTAL_RUNNING += 1; }
    }

    # Display Total Number of Succeeded Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=success'>";                # URL To View O/S Upd. Page
    echo "$TOTAL_SUCCESS Success</a></div>";                                # Display Total Succeeded

    # Display Total Number of Failed Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=failed'>";                 # URL To View O/S Upd. Page
    echo "$TOTAL_FAILED Failed</a></div>";                              # Display Total Script Fail

    # Display Total Number of Running Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=running'>";                # URL To View O/S Upd. Page
    echo "$TOTAL_RUNNING Running</a></div>";                            # Display Total Running Scr.

    # Display Total number of Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=all'>";                    # URL To View O/S Upd. Page
    echo "Total " . count($script_array) . " scripts</a></div>";        # Display Script Total Count
    echo "\n<hr/>";                                                     # Print Horizontal Line
}



# Show server information.
# ==================================================================================================
function show_server_info() {
    global  $sadm_array, $URL_RCH_SUMM, $URL_OSUPDATE, $URL_BACKUP, $URL_VIEW_REAR, $URL_MONITOR, 
            $URL_PERF_DAY, $URL_PERF ;


    echo "\n<div class='SideBarTitle'>Server Info</div>";               # SideBar Section Title

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_OSUPDATE . "'>O/S Update</a></div>";        # URL To View O/S Upd. Page

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_BACKUP . "'>Daily Backup</a></div>";        # View Backup Status Page

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_VIEW_REAR . "'>ReaR Backup</a></div>";      # URL View Rear Backup Page

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_MONITOR . "'>System Monitor</a></div>";     # URL to System Monitor Page

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    #echo "\n\n<form action='/view/perf/sadm_server_perf_adhoc_all.php' method='POST'>";
    echo "\n\n<form action='$URL_PERF_DAY' method='POST'>";
    echo '<input type="hidden" name="wtype" value="cpu">';
    echo '<input type="hidden" name="wperiod" value="yesterday">';
    echo '<input type="hidden" name="wservers" value="all_servers">';
    echo '<input type="hidden" name="wcat" value="all_cat">';
    echo '<a href="#" onclick="this.parentNode.submit();">Performance Graph</a>';
    echo "</form></div>";
    
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_PERF    . "'>Adhoc Perf. Graph</a></div>";        # URL to System Monitor Page
    echo "\n<hr/>";                                                     # Print Horizontal Line
}


# ==================================================================================================
# Show IP utilization
# ==================================================================================================
function show_ip_usage() {
    global  $sadm_array, $URL_NETWORK ;

    echo "\n<div class='SideBarTitle'>IP Utilization</div>";            # SideBar Section Title

    if (SADM_NETWORK1 != "") {
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_NETWORK . "?net=" . SADM_NETWORK1 ;     # URL To Network 1 Page
        echo "&option=all'>" . SADM_NETWORK1 . "</a></div>";            # URL To Network 1 Page
    }
    if (SADM_NETWORK2 != "") {
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_NETWORK . "?net=" . SADM_NETWORK2 ;     # URL To Network 2 Page
        echo "&option=all'>" . SADM_NETWORK2 . "</a></div>";            # URL To Network 2 Page
    }
    if (SADM_NETWORK3 != "") {
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_NETWORK . "?net=" . SADM_NETWORK3 ;     # URL To Network 3 Page
        echo "&option=all'>" . SADM_NETWORK3 . "</a></div>";            # URL To Network 3 Page
    }
    if (SADM_NETWORK4 != "") {
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_NETWORK . "?net=" . SADM_NETWORK4 ;     # URL To Network 4 Page
        echo "&option=all'>" . SADM_NETWORK4 . "</a></div>";            # URL To Network 4 Page
    }
    if (SADM_NETWORK5 != "") {
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_NETWORK . "?net=" . SADM_NETWORK5 ;     # URL To Network 5 Page
        echo "&option=all'>" . SADM_NETWORK5 . "</a></div>";            # URL To Network 5 Page
    }
    echo "\n<hr/>";                                                     # Print Horizontal Line
}




# Show CRUD Operation
# ==================================================================================================
function show_crud_operation() {
    global $URL_EDIT_SRV, $URL_EDIT_CAT, $URL_EDIT_GRP ;
    echo "\n<div class='SideBarTitle'>CRUD Operation</div>";
    echo "\n<div class='SideBarItem'><a href='" . $URL_EDIT_SRV . "'>Server</a></div>  ";
    echo "\n<div class='SideBarItem'><a href='" . $URL_EDIT_CAT . "'>Category</a></div>";
    echo "\n<div class='SideBarItem'><a href='" . $URL_EDIT_GRP . "'>Group</a></div>   ";
    echo "\n<hr/>";
}




# Start of SADM SideBar
# ==================================================================================================
    $sadm_array = build_sadm_array_from_db();                                 
    show_os_distribution();
    show_server_attribute();
    show_scripts_status(); 
    show_server_info();
    show_ip_usage();
    show_crud_operation();
    echo "\n</div> <!-- End of SideBar  -->\n\n\n"                      # End of Left Column Div

?> 