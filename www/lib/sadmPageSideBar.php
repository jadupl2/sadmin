<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadmPageSideBar.php
#   Version     :  1.8
#   Date        :  21 June 2016
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Use to display the SADM Side Bar at the left of every page.
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# ChangeLog
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
# 2018_02_07 V2.1 Added Performance Link in SideBar
# 2018_07_09 v2.2 Change SideBar Layout
# 2018_07_21 v2.3 If an RCH is malformed (Less than 8 fields) it is ignored 
# 2018_09_16 v2.4 Add Alert Group in RCH Array
# 2018_09_22 v2.5 Failed Script counter was wrong
# 2019_01_05 Improvement: v2.6 Add SideBar link to view all servers CPU performance on one page.
#@2019_06_07 Update: v2.7 Updated to deal with the new format of the RCH file.
#@2019_07-15 Update: v2.8 Add 'Backup Status Page' & Fix RCH files with only one line not reported.
# ==================================================================================================
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');  # <head>CSS,JavaScript</Head>
#echo "\n<body>";
echo "\n\n<div class='SideBar'>";



#===================================================================================================
#                                      GLOBAL Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.8" ;                                                        # Current version number
$URL_SERVER   = '/view/srv/sadm_view_servers.php';                      # Show Servers List URL
$URL_OSUPDATE = "/view/sys/sadm_view_schedule.php";                     # View O/S Update Status URL 
$URL_BACKUP   = "/view/sys/sadm_view_backup.php";                       # View Backup Status URL 
$URL_MONITOR  = "/view/sys/sadm_view_sysmon.php";                       # View System Monitor URL 
$URL_EDIT_CAT = '/crud/cat/sadm_category_main.php';                     # Maintenance Cat. Page URL
$URL_EDIT_GRP = '/crud/grp/sadm_group_main.php';                        # Maintenance Grp. Page URL
$URL_EDIT_SRV = '/crud/srv/sadm_server_main.php';                       # Maintenance Srv. Page URL
$URL_RCH_SUMM = '/view/rch/sadm_view_rch_summary.php';                  # Return Code History View
#$URL_NETWORK  = '/view/sys/sadm_subnet.php';                            # Network Scan Result URL
$URL_NETWORK  = '/view/net/sadm_view_subnet.php';                       # Network Scan Result URL
$URL_PERF     = '/view/perf/sadm_server_perf_menu.php';                 # Performance Graph Menu URL
$URL_PERF_DAY = '/view/perf/sadm_server_perf_adhoc_all.php';            # Yesterday Servers CPU Perf



// ================================================================================================
//                   Build Array Used by SideBar for Scripts Status 
// ================================================================================================
function build_sidebar_scripts_info() {
    
    $DEBUG = False;                                                     # Activate/Deactivate Debug
    
    # Reset All Counters
    $count=0;                                                           # Working Counter
    $script_array = array() ;
    
    # Form the base directory name where all the servers 'rch' files are located
    $RCH_ROOT = $_SERVER['DOCUMENT_ROOT'] . "/dat/";                    # $SADMIN/www/dat
    if ($DEBUG) { echo "<br>Opening $RCH_ROOT directory "; }            # Debug Display RCH Root Dir
    
    # Make sure that the DATA Root directory is a directory
    if (! is_dir($RCH_ROOT)) {
        $msg="The $RCH_ROOT directory doesn't exist !\nCorrect the situation and retry operation";
        alert ("$msg");
        ?><script type="text/javascript">history.go(-1);</script><?php
        exit;
    }
    
    # Create unique filename that will contains all servers *.rch filename
    $tmprch = tempnam ('tmp/', 'ref_rch_file-');                        # Create unique file name
    if ($DEBUG) { echo "<br>Temp file of rch filename : " . $tmprch;}   # Show unique filename
    $CMD="find $RCH_ROOT -name '*.rch'  > $tmprch";                     # Construct find command
    if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }          # Show command constructed
    $a = exec ( $CMD , $FILE_LIST, $RCODE);                             # Execute find command
    if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }  # Display Return Code
    
    # Open input file containing the name of all rch filenames
    $input_fh  = fopen("$tmprch","r") or die ("can't open ref-rch file - " . $tmprch);
    
    # Loop through filename list in the file
    while(! feof($input_fh)) {
        $wfile = trim(fgets($input_fh));                                # Read rch filename line
        if ($DEBUG) { echo "\n<br><br>Processing file : " . $wfile ;}   # Debug Show rch filename
        if ($wfile != "") {                                             # If filename not blank
            $line_array = file($wfile);                                 # Reads entire file in array
            if ($DEBUG) { echo "\n>Number of line in $wfile is ". count($line_array);} 
            $last_index = count($line_array) - 1;                       # Array Index of Last Line
            if ($DEBUG) { echo "\n<br>line_array[last_index]=" . $line_array[$last_index];}
            if ($line_array[$last_index] != "") {                   # If None Blank Last Line
                $tag = explode(" ",$line_array[$last_index]);       # Split Line space delimited
                $num_tags = count($tag);                            # Nb Elements on lines
                if ($num_tags == 10) {
                   list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$calert,$ctype,$ccode) = explode(" ",$line_array[$last_index], 10);
                   $outline = $cserver .",". $cdate1 .",". $ctime1 .",". $cdate2 .",". $ctime2 .",". $celapsed .",". $cname .",". $calert .",". $ctype . "," . trim($ccode) .",". basename($wfile) ."\n";
                   if ($DEBUG) { echo "<br>Output line is " . $outline ; } # Print Output Line
                   $count+=1;
                   # Key is "StartDate + StartTime + FileName"
                   $akey = $cdate1 ."_". $ctime1 ."_". basename($wfile);
                   if ($DEBUG) {  echo "<br>AKey is " . $akey ;  }      # Print Array Key
                   if (array_key_exists("$akey",$script_array)) {
                      $script_array[$akey] = $outline . "_" . $count ;
                   }else{
                      $script_array[$akey] = $outline ;
                   }
                }
            }
        }
    }

    fclose($input_fh);                                                  # Close Input Filename List
    krsort($script_array);                                              # Reverse Sort Array on Keys
    unlink($tmprch);                                                    # Delete Temp File
    # Under Debug - Display The Array Used to build the SideBar
    if ($DEBUG) {foreach($script_array as $key=>$value) { echo "<br>Key is $key and value is $value";}}
    return $script_array;
    }



# ==================================================================================================
# This function read the server tabe and collect info to build the SideBar (Except Scripts Status)
# The function return an array with the information needed to display the SideBar info
# ==================================================================================================
function SideBar_OS_Summary() {
    global $con;                                                        # Global Database Conn. Obj.

    # Loop Through Retreived Data and Display each Row
    $sql = "SELECT * FROM server ;";                                    # Construct SQL Statement
    
    # Execute the Row Update SQL
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute Update Row SQL
        $err_line = (__LINE__ -1) ;                                     # Error on preceeding line
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
# Start of SADM SideBar
# ==================================================================================================
#
    $sadm_array = SideBar_OS_Summary();                                 # Build sadm_array Used 

    # PRINT SERVER O/S DISTRIBUTION 
    $SERVER_COUNT=0;                                                    # Total Servers Reset
    echo "\n<div class='SideBarTitle'>O/S Distribution</div>";          # SideBar Section Title
    foreach($sadm_array as $key=>$value)                                
    {
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
    echo ">All (" . $SERVER_COUNT . ") Servers</a></div>";              # Display Server Count
    echo "\n<hr/>";                                                     # Print Horizontal Line
    

    # SERVER ATTRIBUTE HEADER
    echo "\n<div class='SideBarTitle'>Server Attribute</div>";          # SideBar Section Title

	# DISPLAY NUMBER OF ACTIVE SERVER
    $kpart2 = $sadm_array["srv_active,"];                               # Array Key for Act. Server
    if ( ${kpart2} != 0 ) {                                             # If Nb. Active server is 0
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_active'>";     # View Active server URL
        echo "${kpart2} Active(s)</a></div>";                           # Print Nb. of Active Server
    }

    # DISPLAY NUMBER OF INACTIVE SERVERS
    $kpart2 = $sadm_array["srv_inactive,"];                             # Array Key for Inact. Srv.
    if ( ${kpart2} != 0 ) {                                             # If no Inactive server
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_inactive'>";   # View Inactive server URL
        echo "${kpart2} Inactive(s)</a></div>";                         # Print Nb. Inactive Server
    }

    # DISPLAY NUMBER OF VIRTUAL SERVERS
    $kpart2 = $sadm_array["srv_vm,"];                                   # Array Key for Virtual Srv.
    if ( ${kpart2} != 0 ) {                                             # If no Virtual Server
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_vm'>";         # View Virtual server URL
        echo "${kpart2} Virtual(s)</a></div>";                          # Print Nb. of Virtual Srv. 
    }

    # DISPLAY NUMBER OF PHYSICAL SERVERS
    $kpart2 = $sadm_array["srv_physical,"];                             # Array Key for Physical Srv
    if ( ${kpart2} != 0 ) {                                             # If No Physical Server
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_physical'>";   # View Physical server URL
        echo "${kpart2} Physical(s)</a></div>";                         # Print Nb. of Physical Srv.
    }

    # DISPLAY NUMBER OF SPORADIC SERVERS
    $kpart2 = $sadm_array["srv_sporadic,"];                             # Array Key for Sporadic Srv
    if ( ${kpart2} != 0 ) {                                             # If no sporadic servers
        echo "\n<div class='SideBarItem'>";                             # SideBar Item Div Class
        echo "<a href='" . $URL_SERVER . "?selection=all_sporadic'>";   # View Sporadic server URL
        echo "${kpart2} Sporadic(s)</a></div>";                         # Print Nb. of Sporadic Srv.
    }
    echo "\n<hr/>";                                                     # Print Horizontal Line
    

	# ---------------------------   SERVERS STATUS SIDEBAR      ------------------------------------
    echo "\n<div class='SideBarTitle'>Server Info</div>";               # SideBar Section Title

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_OSUPDATE . "'>OS Update Status</a></div>";   # URL To View O/S Upd. Page

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_BACKUP . "'>Backup Status</a></div>";   # URL To View O/S Upd. Page

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_MONITOR . "'>SysMon Status</a></div>";      # URL to System Monitor Page

    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    #echo "\n\n<form action='/view/perf/sadm_server_perf_adhoc_all.php' method='POST'>";
    echo "\n\n<form action='$URL_PERF_DAY' method='POST'>";
    echo '<input type="hidden" name="wtype" value="cpu">';
    echo '<input type="hidden" name="wperiod" value="yesterday">';
    echo '<input type="hidden" name="wservers" value="all_servers">';
    echo '<input type="hidden" name="wcat" value="all_cat">';
    echo '<a href="#" onclick="this.parentNode.submit();">Perf. All Servers</a>';
    echo "</form></div>";
    
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_PERF    . "'>Adhoc Perf. Graph</a></div>";        # URL to System Monitor Page
    echo "\n<hr/>";                                                     # Print Horizontal Line
    
    

	# ----------------------------------   Network SIDEBAR   ---------------------------------------
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

	# ---------------------------   SCRIPTS STATUS SIDEBAR      ------------------------------------
    echo "\n<div class='SideBarTitle'>Scripts Status</div>";             # SideBar Section Title
	$script_array = build_sidebar_scripts_info();                       # Build $script_array
    $TOTAL_SCRIPTS=count($script_array);                                # Get Nb. Scripts in Array
    $TOTAL_FAILED=0; $TOTAL_SUCCESS=0; $TOTAL_RUNNING=0;                # Initialize Total to Zero

    # Loop through Script Array to count Different Return Code
    foreach($script_array as $key=>$value) {
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$calert,$ctype,$ccode,$cfile) = explode(",", $value);
        if ($ccode == 0) { $TOTAL_SUCCESS += 1; }
        if ($ccode == 1) { $TOTAL_FAILED  += 1; }
        if ($ccode == 2) { $TOTAL_RUNNING += 1; }
    }

    # Display Total number of Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=all'>";                    # URL To View O/S Upd. Page
	echo "All (" . $TOTAL_SCRIPTS . ") Scripts</a></div>";              # Display Script Total Count

    # Display Total Number of Succeeded Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=success'>";                # URL To View O/S Upd. Page
    if ( $TOTAL_SUCCESS == 0 ) {                                        # If None Succeeded
        echo "No Script Succeeded</a></div>";                           # Advise user
    }else{                                                              # If Some Scripts succeeded
        echo "$TOTAL_SUCCESS Success</a></div>";                        # Display Total Succeeded
    }

    # Display Total Number of Failed Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=failed'>";                 # URL To View O/S Upd. Page
    if ( $TOTAL_FAILED == 0 ) {                                         # If None Succeeded
        echo "None Failed</a></div>";                                   # No Scripts Failed
    }else{
        echo "$TOTAL_FAILED Failed</a></div>";                          # Display Total Script Fail
    }

    # Display Total Number of Running Scripts
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_RCH_SUMM . "?sel=running'>";                # URL To View O/S Upd. Page
    if ( $TOTAL_RUNNING == 0 ) {                                        # If No Script is running
        echo "None Running</a></div>";                                  # Display None Running
    }else{
        echo "$TOTAL_RUNNING Running</a></div>";                        # Display Total Running Scr.
    }
    echo "\n<hr/>";                                                     # Print Horizontal Line
    

	# ----------------------------------   EDIT SIDEBAR   ------------------------------------------
    echo "\n<div class='SideBarTitle'>CRUD Operations</div>";           # SideBar Section Title
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_EDIT_SRV . "'>Server</a></div>";       # URL To Start Edit Server
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_EDIT_CAT . "'>Category</a></div>";     # URL To Start Edit Cat.
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_EDIT_GRP . "'>Group</a></div>";        # URL To Start Edit Group
    echo "\n<hr/>";                                                     # Print Horizontal Line
    

    
    echo "\n</div> <!-- End of SideBar  -->\n\n\n"                      # End of Left Column Div
?>
    