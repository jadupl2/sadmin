<?php 
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_server_input_key.php
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
include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php')  ;
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
include           ($_SERVER['DOCUMENT_ROOT'].'/sadmin/sadm_menu.php')  ;
?>
 


<!-- Accept the server name ==================================================================== -->
	<h1>Edit Server Table Form</h1>
	<form name=key_name action='/sadmin/sadm_server_check_key.php' method='POST'>
<?php
	echo "Enter Server Name ";
	echo "<select name='server_name'>\n";
	$query = "SELECT * FROM sadm.server where srv_active = True order by srv_name ;";
	$result = pg_query($query) or die('Query failed: ' . pg_last_error());
	while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
	    echo "<option value=$row[srv_name]>$row[srv_name]</option>\n";
	}
	echo "</select><br>\n";
    echo "<br>Description";
    echo '<input type="text" name="fdesc" value="">';
    
    echo "<br>Quantity (between 1 and 5):";
    echo '<input type="number" name="quantity" min="1" max="5">';

    echo "<br>Sporadic System";
    echo '<input type="radio" name="Sporadic" value="no" checked>No';
    echo '<input type="radio" name="Sporadic" value="yes">Yes';
    #echo '<input type="radio" name="gender" value="female"> Female<br>';
    #echo '<input type="radio" name="gender" value="other"> Other';
    echo "<br>E-Mail";
    echo '<input type="email" name="email">';
    
	echo "<br><input type='button' onclick='alert(\"Hello World\")' value='Click Me!'>";
    echo '<br><input type="submit" value="Proceed" />';
	echo "<br><br>";
?>
	</form>

