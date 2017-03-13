<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_div_sidebar.php
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
echo "\n\n\n<!-- ============================================================================= -->";
echo "\n<div id='sadmSideBar'>\n"; 

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
		   echo "&value=" . $kpart2 ."'>$value $kpart2 server(s)</a></li>\n";
           $SERVER_COUNT = $SERVER_COUNT + $value;
        }
    }
    # All Servers Link 
    echo "<li><a href='/sadmin/sadm_view_servers.php?selection=all_servers'";
	echo ">All (" . $SERVER_COUNT . ") Servers</a></li>\n";
    echo "</ul>\n";
  


	# ------------------------  SERVERS ATTRIBUTES SIDEBAR -----------------------------------------
    echo "<br>";
    echo "<strong>Servers Attributes</strong>\n";
    echo "<ul>\n";

    # Number of Active Servers
    $kpart2 = $sadm_array["srv_active,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_active'>";
    if ( ${kpart2} == 0 ) {
        echo "No active servers</a></li>\n";
    }else{
        echo "${kpart2} active servers</a></li>\n";
    }    

    # Number of Inactive Servers
    $kpart2 = $sadm_array["srv_inactive,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_inactive'>";
    if ( ${kpart2} == 0 ) {
        echo "No inactive server</a></li>\n";
    }else{
        echo "${kpart2} inactive servers</a></li>\n";
    }
    
    # Number of Virtual Servers
    $kpart2 = $sadm_array["srv_vm,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_vm'>";
    if ( ${kpart2} == 0 ) {
        echo "No virtual servers</a></li>\n";
    }else{
        echo "${kpart2} virtual(s) server(s)</a></li>\n";
    }

    # Number of physical Servers
    $kpart2 = $sadm_array["srv_physical,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_physical'>";
    if ( ${kpart2} == 0 ) {
        echo "No physical server</a></li>\n";
    }else{
        echo "${kpart2} physical(s) server(s)</a></li>\n";
    }

    # Number of Sporadic Servers
    $kpart2 = $sadm_array["srv_sporadic,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_sporadic'>";
    if ( ${kpart2} == 0 ) {
        echo "No sporadic server</a></li>\n";
    }else{
        echo "${kpart2} sporadic(s) server(s)</a></li>\n";
    }

    echo "</ul>\n";
	
	
	# ---------------------------   SCRIPTS STATUS SIDEBAR      ------------------------------------
    echo "<br>\n";                                                      # Insert White Line
    echo "<strong>Scripts Status</strong>\n";                           # Display Section Title
	$script_array = build_sidebar_scripts_info();                       # Build $script_array
    $TOTAL_SCRIPTS=count($script_array);                                # Get Nb. Scripts in Array
    $TOTAL_FAILED=0; $TOTAL_SUCCESS=0; $TOTAL_RUNNING=0;                # Initialize Total to Zero
    
    # Loop through Script Array to count Different Return Code 
    foreach($script_array as $key=>$value) { 
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$ccode,$cfile) 
            = explode(",", $value);
        if ($ccode == 0) { $TOTAL_SUCCESS += 1; }
        if ($ccode == 1) { $TOTAL_FAILED  += 1; }
        if ($ccode == 2) { $TOTAL_RUNNING += 1; }
    } 
    
    # Display Total number of Scripts
    echo "<ul>\n";
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=all'>";
	echo "All (" . $TOTAL_SCRIPTS . ") Scripts</a></li>\n";
    
    # Display Total Number of Failed Scripts
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=failed'>";
    if ( $TOTAL_FAILED == 0 ) {
        echo "No Failed Script</a></li>\n";
    }else{
        echo "$TOTAL_FAILED Failed Script(s)</a></li>\n";
    }

    # Display Total Number of Running Scripts
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=running'>";
    if ( $TOTAL_RUNNING == 0 ) {
        echo "No Running Script</a></li>\n";
    }else{
        echo "$TOTAL_RUNNING Running Script(s)</a></li>\n";
    }

    # Display Total Number of Succeeded Scripts
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=success'>";
    if ( $TOTAL_SUCCESS == 0 ) {
        echo "No Script Succeeded</a></li>\n";
    }else{
        echo "$TOTAL_SUCCESS Success Script(s)</a></li>\n";
    }
    echo "</ul>\n";
	

	
	# ---------------------------   SERVERS STATUS SIDEBAR      ------------------------------------
    echo "<br>\n";                                                      # Insert White Line
    echo "<strong>Server Status</strong>\n";                            # Display Section Title
    echo "<ul>\n";
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_schedule.php'>";
    echo "Update O/S Schedule";
	echo "</a></li>\n";
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_sysmon.php'>";
    echo "Monitoring Alert(s)";
	echo "</a></li>\n";
	echo "</ul>\n";
	

	
	# ----------------------------------   EDIT SIDEBAR   ------------------------------------------
    echo "<br>\n";                                                      # Insert White Line
    echo "<strong>Edit Section</strong>\n";                             # Display Section Title
    echo "<ul>\n";
    echo "<li class='text-capitalize'><a href='/crud/sadm_server_main.php'>";
    echo "Edit Servers";
	echo "</a></li>\n";
    echo "<li class='text-capitalize'><a href='/crud/sadm_category_main.php'>";
    echo "Edit Category";
	echo "</a></li>\n";
    echo "<li class='text-capitalize'><a href='/crud/sadm_group_main.php'>";
    echo "Edit Group";
	echo "</a></li>\n";
	echo "</ul>\n";
    echo "<br>\n";                                                      # Insert White Line
	

echo "\n</div>                             <!-- End of Div sadmSideBar -->\n";  
echo "\n<!-- ================================================================================= -->";
?>
