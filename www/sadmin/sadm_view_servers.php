<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_view_servers.php
*   Version  :  1.5
*   Date     :  14 April 2016
*   Requires :  php
*
*   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');

// =================================================================================================
//                                  Display SADMIN Main Page Header
// =================================================================================================
function display_main_page_header($line_title) {

	sadm_page_heading ("Server list by $line_title");
    
 	$HDR_BGCOLOR="#5EA2A5";
	$FNT_COLOR="#FFFFFF";
	$HDR_COLOR="bgcolor=$HDR_BGCOLOR><font color=$FNT_COLOR";

	echo "<center>\n";
	echo "<table border=0 cellspacing=0>\n";
	echo "<tr>\n";
	echo "<td width=10 align=center $HDR_COLOR><b></b></td>\n";
	echo "<td widht=10 align=center $HDR_COLOR><b>Server</b></td>\n";
	echo "<td width=100  colspan=3 align=center $HDR_COLOR><b>Operating System</b></td>\n";
	echo "<td width=10  align=center $HDR_COLOR><b>Server</b></td>\n";
	echo "<td width=200  align=center $HDR_COLOR><b></b></td>\n";
	echo "<td width=10  align=center $HDR_COLOR><b>Last</b></td>\n";
	echo "<td width=10  align=center $HDR_COLOR><b>Memory</b></td>\n";
	echo "<td width=100  align=center $HDR_COLOR><b>Nb Cpu</b></td>\n";
	echo "<td width=10  align=center $HDR_COLOR><b></b></td>\n";
	echo "</tr>\n"; 

	echo "\n<tr>\n";
	echo "<td align=center $HDR_COLOR><b>Cnt</b></td>\n";
	echo "<td align=center $HDR_COLOR><b>Name</b></td>\n";
	echo "<td align=center $HDR_COLOR><b>Type</td>\n";
	echo "<td align=center $HDR_COLOR><b>Name</td>\n";
	echo "<td align=center $HDR_COLOR><b>Version</td>\n";
	echo "<td align=center $HDR_COLOR><b>Type</b></td>\n";
	echo "<td align=center $HDR_COLOR><b>Description</b></td>\n";
	echo "<td align=center $HDR_COLOR><b>Update</b></td>\n";
	echo "<td align=center $HDR_COLOR><b>in MB</b></td>\n";
	echo "<td align=center $HDR_COLOR><b>Speed Mhz</b></td>\n";
	echo "<td align=center $HDR_COLOR><b>Disks Info</b></td>\n";
	echo "</tr>\n"; 
}




// ================================================================================================
//                      Display Main Page Data from the row received in parameter
// ================================================================================================
function display_main_page_data($count, $row) {
    echo "\n\n<tr>\n";  
	    if ($count % 2 == 0) 
	        $BGCOLOR="#E4F0EC" ;
	    else
	        $BGCOLOR="#F0DFD5" ;

	    echo "<td align='center'    bgcolor=$BGCOLOR>" . $count . "</td>\n";
        echo "<td align='center'    bgcolor=$BGCOLOR>" .
			"<a href=/sadmin/sadm_view_server.php?host=" . nl2br($row['srv_name']) . ">" . 
            "<div class='tooltip'> <span class='tooltiptext'>".nl2br( $row['srv_desc']).
            "</span>" . nl2br($row['srv_name']) . "</div></a></td>\n";
	    echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_ostype']) . "</td>\n";  
        echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_osname']) . "</td>\n";  
		echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_osversion']) . "</td>\n";  
		echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_type']) . "</td>\n";  
	    echo "<td align='left'      bgcolor=$BGCOLOR>" . nl2br( $row['srv_desc']) . "</td>\n";  
#	    echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_ip']) . "</td>\n";  
	    echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_last_update']) . "</td>\n";  
	    #if ($row['srv_sporadic'] == 't' )
	    #   echo "<td align='center'    bgcolor=$BGCOLOR>Yes</td>\n";  
	    #else
	    #   echo "<td align='center'    bgcolor=$BGCOLOR>No</td>\n";  
	    echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_memory']) . "</td>\n";  
	    echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_nb_cpu']) . "X" .
			nl2br( $row['srv_cpu_speed']) . "</td>\n";
	    echo "<td align='center'    bgcolor=$BGCOLOR>" . nl2br( $row['srv_disks_info']) . "</td>\n";  
	echo "</tr>\n"; 
}
	





/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/


// We should receive the sort order desired, if not then default to display by server name
	if (isset($_GET['selection']) ) { 
		$SELECTION = $_GET['selection'];
	}else{
		$SELECTION = 'server';
	}
	if ($DEBUG) { echo "<br>Page Selection is " . $SELECTION; }


//  Validate the sort order received 
	switch ($SELECTION) {
		case 'server'       : $query = 'SELECT * FROM sadm.server where srv_active = True order by srv_name;';
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		case 'ostype'       : $query = 'SELECT * FROM sadm.server where srv_active = True order by srv_ostype;';
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		case 'osname'       : $query = 'SELECT * FROM sadm.server where srv_active = True order by srv_osname;';
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		case 'inactive'     : $query = 'SELECT * FROM sadm.server where srv_active = False order by srv_osname;';
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		case 'osversion'    : $query = 'SELECT * FROM sadm.server where srv_active = True order by srv_osversion;';
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		case 'server_type'  : $query = 'SELECT * FROM sadm.server where srv_active = True order by srv_type;';
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		case 'linux'        : $query = "SELECT * FROM sadm.server where srv_active = True and srv_ostype = 'linux' order by srv_type;";
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		case 'aix'          : $query = "SELECT * FROM sadm.server where srv_active = True and srv_ostype = 'aix' order by srv_type;";
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              break;
		default             : echo "<br>The sort order received (" . $SELECTION . ") is invalid<br>";
                              echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>";
                              exit ;
	}
    
 
    display_main_page_header("$SELECTION");
    #$query = 'SELECT * FROM sadm.server where srv_active = True order by srv_name;';
    #$result = pg_query($query) or die('Query failed: ' . pg_last_error());
    $count=0;
    while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
        $count+=1;
        display_main_page_data($count, $row);
    }
    display_row_footer();

include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ; 
?>
