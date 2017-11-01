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



// ================================================================================================
//                   Build Side Bar Based on SideBar Type Desired (server/ip/script)
// ================================================================================================
function SideBar_OS_Summary() {


    # Loop Through Retreived Data and Display each Row
    $query = "SELECT * FROM sadm.server ;";                             # Construct SQL Statement
    $result = $sadmdb->query($query) or die('Select Server failed');    # Select All rows in table

    # Reset All Counters
    $count=0;
    $sadm_array = array() ;

    # Read All Server Table
    while ($row = $result->fetchArray()) {                              # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter

        # Process Server Type
        $akey = "srv_type," . $row['srv_type'];
        if (array_key_exists($akey,$sadm_array)) {
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
        }else{
            $sadm_array[$akey] = 1 ;
        }

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

        # Process OS Version
        $akey = "srv_osversion," . $row['srv_osversion'];
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
    #$DEBUG=True;
    # Under Debug - Display The Array Used to build the SideBar
    if ($DEBUG) {
        foreach($sadm_array as $key=>$value) { 
            echo "<br>Key is $key and value is $value";
        }
    }
    return $sadm_array;
}



?>
<div id="sadmLeftColumn">
        <div><a href="/index.php">Home & News</a></div>
        <hr/>
        <div><a href="/www/features.php">Feature List</a></div>        
        <div><a href="/www/screenshots.php">Screenshots</a></div>        
        <div><a href="/www/download.php">Download Latest Version</a></div>        
        <div><a href="/www/archive.php">Release Archive</a></div>
        <hr/>
        <div><a href="/www/quickstart.php">Quick Start</a></div>
        <div><a href="/doc/index.php">Documentation</a></div>
        <div><a href="/doc/faq.php">FAQ</a></div>
    <br />    
<?php



# ---------------------------   O/S REPARTITION SIDEBAR     ------------------------------------
	#$sadm_array = build_sidebar_servers_info($sidebar_array);
	$sadm_array = build_sidebar_servers_info();
    $SERVER_COUNT=0;
    echo "<br>";
    echo "<strong>O/S Repartition</strong>\n";
    echo "<ul>\n";
    foreach($sadm_array as $key=>$value)
    {
        list($kpart1,$kpart2) = explode(",",$key);
        if ($kpart1 == "srv_osname") {
           echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=os";
           #echo "&value=" . $kpart2 ."'>$value $kpart2 server(s)</a></li>\n";
           echo "&value=" . $kpart2 ."'>$value $kpart2</a></li>\n";
           $SERVER_COUNT = $SERVER_COUNT + $value;
        }
    }
    # All Servers Link
    echo "<li><a href='/sadmin/sadm_view_servers.php?selection=all_servers'";
	echo ">All (" . $SERVER_COUNT . ") Servers</a></li>\n";
    echo "</ul>\n";


?>
    </div> <!-- End of sadmLeftColumn  -->
