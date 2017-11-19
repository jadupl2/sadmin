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
#
# ==================================================================================================
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHead.php');  # <head>CSS,JavaScript</Head>
echo "\n<body>";
echo "\n<div id='sadmLeftColumn'>";

#===================================================================================================
#                                      GLOBAL Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.0" ;                                                        # Current version number
$URL_SERVER   = '/view/sadm_view_servers.php';                          # Show Servers List URL
$URL_OSUPDATE = "/view/sadm_view_schedule.php";                         # View O/S Update URL 
$URL_MONITOR  = "/view/sadm_view_sysmon.php";                           # View System Monitor URL 
$URL_EDIT_CAT = '/crud/cat/sadm_category_main.php';                     # Maintenance Cat. Page URL
$URL_EDIT_GRP = '/crud/grp/sadm_group_main.php';                        # Maintenance Grp. Page URL
$URL_EDIT_SRV = '/crud/srv/sadm_server_main.php';                       # Maintenance Srv. Page URL


# ==================================================================================================
#                    Build Side Bar Based on SideBar Type Desired (server/ip/script)
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
                echo $kpart2;                                           # Print O/S Name
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
    

	# SERVER ATTRIBUTE SIDEBAR
    echo "<div class='SideBarTitle'>Server Attribute</div>";            # SideBar Section Title

    $kpart2 = $sadm_array["srv_active,"];                               # Array Key for Act. Server
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_SERVER . "?selection=all_active'>";         # View Active server URL
    if ( ${kpart2} == 0 ) {                                             # If Nb. Active server is 0
        echo "No active</a></div>";                                     # Print No Active Server
    }else{                                                              # If we have Active Servers
        echo "${kpart2} Active(s)</a></div>";                           # Print Nb. of Active Server
    }

    $kpart2 = $sadm_array["srv_inactive,"];                             # Array Key for Inact. Srv.
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_SERVER . "?selection=all_inactive'>";       # View Inactive server URL
    if ( ${kpart2} == 0 ) {                                             # If no Inactive server
        echo "No inactive</a></div>";                                   # Print No Inactive Srv. 
    }else{                                                              # If we have Inactive Srv.
        echo "${kpart2} inactive(s)</a></div>";                         # Print Nb. Inactive Server
    }

    $kpart2 = $sadm_array["srv_vm,"];                                   # Array Key for Virtual Srv.
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_SERVER . "?selection=all_vm'>";             # View Virtual server URL
    if ( ${kpart2} == 0 ) {                                             # If no Virtual Server
        echo "No virtual</a></div>\n";                                  # Print No Virtual Server
    }else{                                                              # If we have Virtual Server
        echo "${kpart2} virtual(s)</a></div>";                          # Print Nb. of Virtual Srv. 
    }

    $kpart2 = $sadm_array["srv_physical,"];                             # Array Key for Physical Srv
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_SERVER . "?selection=all_physical'>";       # View Physical server URL
    if ( ${kpart2} == 0 ) {                                             # If No Physical Server
        echo "No physical server</a></div>";                            # Print No Physical Server
    }else{                                                              # If we have Physical Server
        echo "${kpart2} physical(s)</a></div>";                         # Print Nb. of Physical Srv.
    }

    $kpart2 = $sadm_array["srv_sporadic,"];                             # Array Key for Sporadic Srv
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_SERVER . "?selection=all_sporadic'>";       # View Sporadic server URL
    if ( ${kpart2} == 0 ) {                                             # If no sporadic servers
        echo "No sporadic server</a></div>";                            # Print no Sporadic Server
    }else{                                                              # If we have Sporadic Server
        echo "${kpart2} sporadic(s)</a></div>";                         # Print Nb. of Sporadic Srv.
    }
    echo "\n<hr/>";                                                     # Print Horizontal Line
    

	# ---------------------------   SERVERS STATUS SIDEBAR      ------------------------------------
    echo "\n<div class='SideBarTitle'>Server Status</div>";             # SideBar Section Title
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_OSUPDATE . "'>O/S Update</a></div>";        # URL To View O/S Upd. Page
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_MONITOR . "'>System Monitor</a></div>";     # URL to System Monitor Page
    echo "\n<hr/>";                                                     # Print Horizontal Line
    


	# ----------------------------------   EDIT SIDEBAR   ------------------------------------------
    echo "\n<div class='SideBarTitle'>Edit Section</div>";              # SideBar Section Title
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_EDIT_SRV . "'>Edit Server</a></div>";       # URL To Start Edit Server
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_EDIT_CAT . "'>Edit Category</a></div>";     # URL To Start Edit Cat.
    echo "\n<div class='SideBarItem'>";                                 # SideBar Item Div Class
    echo "<a href='" . $URL_EDIT_GRP . "'>Edit Group</a></div>";        # URL To Start Edit Group
    echo "\n<hr/>";                                                     # Print Horizontal Line
    
    echo "\n</div> <!-- End of sadmLeftColumn  -->\n\n\n"               # End of Left Column Div
?>
    