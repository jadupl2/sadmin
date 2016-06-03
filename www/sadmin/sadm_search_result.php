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
    $query = "SELECT * FROM sadm.server WHERE lower(srv_name) LIKE lower('%$searchq%') OR lower(srv_desc) LIKE lower('%$searchq%');";
    $result = pg_query($query) or die('Query failed: ' . pg_last_error());
    $count  = pg_num_rows($result);
    if ($count == 0){
        $output = 'There was no search results !';
    }else{
        echo "<br><center><table id='table_rch'>\n";    
        echo "<tr>\n" ;
        echo "<th>Cnt</th>";
        echo "<th>Server Name</th>";
        echo "<th>Description</th>";
        echo "<th colspan=3>Action</th>";
        echo "</tr>\n";
        while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
            $fname = $row['srv_name'] ;
            $fdesc  = $row['srv_desc'] ;
            $count+=1;
            echo "<tr>\n" ;
            echo "<td>" . $count            . "</td>\n";
            echo "<td>" . $row['srv_name']  . "</td>\n";
            echo "<td>" . $row['srv_desc']  . "</td>\n";
            echo "<td>" . $cdate2  . "</td>\n";
            echo "<td>" . $ctime2  . "</td>\n";
            echo '<td><a href="#" class="myButton"><button type="button" class="btn btn-info">Edit Server</button></a></td>';
            echo '<td><a href="#" class="myButton"><button type="button" class="btn btn-info">Delete Server</button></a></td>';
            echo '<td><a href="#" class="myButton"><button type="button" class="btn btn-info">Query Server</button></a></td>';
            echo "</tr>\n";
        }  
        echo "</table>";
                
    }
}

	include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ; 
?>

