<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadmPageSideBar.php
*   Version     :  1.8
*   Date        :  21 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Use to display the SADM Side Bar at the left of every page.
*
*   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
*
*   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
*   of the GNU General Public License as published by the Free Software Foundation; either
*   version 2 of the License, or (at your option) any later version.
*
*   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*   See the GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License along with this program.
*   If not, see <http://www.gnu.org/licenses/>.
* ==================================================================================================
*/
# ChangeLog
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#
# ==================================================================================================
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHead.php');  # <head>CSS,JavaScript</Head>
echo "<body>";

echo "<div id='sadmLeftColumn'>";


// ================================================================================================
//                   Build Side Bar Based on SideBar Type Desired (server/ip/script)
// ================================================================================================
function SideBar_OS_Summary() {
    global $con;

    # Loop Through Retreived Data and Display each Row
    $sql = "SELECT * FROM server ;";                                  # Construct SQL Statement
    
    # Execute the Row Update SQL
    if ( ! $result=mysqli_query($con,$sql)) {                       # Execute Update Row SQL
        $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
        $err_msg1 = "Error on select server\nError (";              # Advise User Message 
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
        exit;
    }

    # Reset All Counters
    $count=0;
    $sadm_array = array() ;

    # Read All Server Table
    while ($row = mysqli_fetch_assoc($result)) {                             # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter

        # Process OS Type
        $akey = "srv_ostype," . $row['srv_ostype'];
        if (array_key_exists($akey,$sadm_array)) {
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
        }else{
            $sadm_array[$akey] = 1 ;
        }

        # Process OS Name
        $akey = "srv_osname," . $row['srv_osname'];
        if (array_key_exists($akey,$sadm_array)) {
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
        }else{
            $sadm_array[$akey] = 1 ;
        }

        # Count Number of Active Servers
        if ($row['srv_active']  == TRUE) {
            $akey = "srv_active," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

        # Count Number of Inactive Servers
        if ($row['srv_active']  == FALSE) {
            $akey = "srv_inactive," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

        # Count Number of Physical and Virtual Servers
        if ($row['srv_vm'] == TRUE) {
            $akey = "srv_vm," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }else{
            $akey = "srv_physical," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

        # Count Number of Physical and Virtual Servers
        if ($row['srv_sporadic']  == TRUE) {
            $akey = "srv_sporadic," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

    }
    ksort($sadm_array);                                                 # Sort Array Based on Keys
    $DEBUG=False;
    # Under Debug - Display The Array Used to build the SideBar
    if ($DEBUG) {
        foreach($sadm_array as $key=>$value) { 
            echo "<br>Key is $key and value is $value";
        }
    }
    return $sadm_array;
}



#
#        <div><a href="/index.php">Home & News</a></div>
#        <hr/>
#        <div><a href="/www/features.php">Feature List</a></div>        
#        <div><a href="/www/screenshots.php">Screenshots</a></div>        
#        <div><a href="/www/download.php">Download Latest Version</a></div>        
#        <div><a href="/www/archive.php">Release Archive</a></div>
#        <hr/>
#        <div><a href="/www/quickstart.php">Quick Start</a></div>
#        <div><a href="/doc/index.php">Documentation</a></div>
#        <div><a href="/doc/faq.php">FAQ</a></div>
#    <br />    
#



# ---------------------------   O/S REPARTITION SIDEBAR     ------------------------------------
	$sadm_array = SideBar_OS_Summary();
    $SERVER_COUNT=0;
    #echo "<br>";
    echo "<strong>O/S Repartition</strong>\n";
    #echo "<ul>\n";
    foreach($sadm_array as $key=>$value)
    {
        list($kpart1,$kpart2) = explode(",",$key);
        if ($kpart1 == "srv_osname") {
           #echo "<li class='text-capitalize'>";
           echo "<div><a href='/sadmin/sadm_view_servers.php?selection=os";
           echo "&value=" . $kpart2 ."'>";
           echo $value . " " ;
           if ($kpart2 == "") {
               echo "Unknown";
              }else{
                echo $kpart2;
              }
           #echo "</a></li>\n";
           echo "</a></div>\n";
           $SERVER_COUNT = $SERVER_COUNT + $value;
        }
    }
    # All Servers Link
    echo "<div><a href='/sadmin/sadm_view_servers.php?selection=all_servers'";
	echo ">All (" . $SERVER_COUNT . ") Servers</a></div>\n";
    echo "<hr/>";
?>
    </div> <!-- End of sadmLeftColumn  -->
