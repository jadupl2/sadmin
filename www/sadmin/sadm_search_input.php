<?php 
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_search.php
*   Version  :  1.5
*   Date     :  2 April 2016
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

    sadm_page_heading ("Create or Edit Server Data");

if (isset($_POST['search'])) {
    $searchq = $_POST['search'];
    $searchq = preg_replace("#[^0-9a-z]#i","",$searchq);
    $query = "SELECT * FROM sadm.server WHERE lower(srv_name) LIKE lower('%$searchq%') OR 
              lower(srv_desc) LIKE lower('%$searchq%');";
    $result = pg_query($query) or die('Query failed: ' . pg_last_error());
    $count  = pg_num_rows($result);
    if ($count == 0){
        echo '<br><p>There was no search results !</p>';
    }else{
        echo "<br><center><table id='table_rch'>\n";    
        echo "<tr>\n" ;
        echo "<th>Cnt</th>";
        echo "<th>Server Name</th>";
        echo "<th>Description</th>";
        echo "<th colspan=3>Action</th>";
        echo "</tr>\n";
        $xcount = 0 ;
        while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
            $xcount+=1;
            echo "<tr>\n" ;
            echo "<td>" . $xcount           . "</td>\n";
            echo "<td>" . $row['srv_name']  . "</td>\n";
            echo "<td>" . $row['srv_desc']  . "</td>\n";
            echo '<td><a href="#" class="btn btn-info btn-sm">
                  <span class="glyphicon glyphicon-search"></span> Search</a></td>';
            echo '<td><a href="#" class="btn btn-info btn-sm">
                  <span class="glyphicon glyphicon-plus"></span> Add</a></td>';
            echo '<td><a href="#" class="btn btn-info btn-sm">
                  <span class="glyphicon glyphicon-pencil"></span> Edit</a></td>';
            echo '<td><a href="#" class="btn btn-info btn-sm">
                  <span class="glyphicon glyphicon-trash"></span> Delete</a></td>';
            #echo '<td><a href="#" class="myButton"><button type="button" class="btn btn-info btn-sm">Edit Server</button></a></td>';
            echo '<td><a href="#" class="myButton"><button type="button" class="btn btn-info btn-sm">Delete Server</button></a></td>';
            echo '<td><a href="#" class="myButton"><button type="button" class="btn btn-info btn-sm">Query Server</button></a></td>';
            echo "</tr>\n";
        }  
        echo "</table>";
                
    }
}

?>

	<br>
	<form name="sadm_search_result.php"  method='POST'>
		<table border=0 cellspacing=0>
			<tr>
		<td width=50> </td>
		<td width=50 align=right><input type="text" name="search" placeholder="Search for server ..." /></td>
		<td width=10> </td>
        <td><button type="submit" class="btn btn-info btn-sm ">Search Server</button></td>
		<td width=10> </td>
		<td>or</td>
		<td width=10> </td>
		<td><a href="#" class="myButton"><button type="button" class="btn btn-info btn-sm">Add Server</button></a> </td>
		</tr>
		</table>
    </form>
    
<?php 
    #print ("$output"); 
	include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ; 
?>

