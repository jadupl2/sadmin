<?php 
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_category_main.php
*   Version  :  1.5
*   Date     :  2 May 2016
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


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False;                                       # Activate (TRUE) or Deactivate (FALSE) Debug
 

/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/

    if (isset($_GET['id']) ) { 
        $id = $_GET['id'];
        if (isset($_POST['submitted'])) {
            mysql_query("DELETE FROM `servers` WHERE `server_name` = '$id' ") ; 
            echo (mysql_affected_rows()) ? "Row deleted.<br /> " : "Nothing deleted.<br /> ";
            // alert ("Row Deleted");
            $CMD  = "touch /tmp/update_host_file.activate" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            header("location:config_server_edit_list.php");
        }
        $row = mysql_fetch_array ( mysql_query("SELECT * FROM `servers` WHERE `server_name` = '$id' ")); 
    }
?> 

    <form action='' method='POST'>
    <?php display_record( $row , "Delete Unix - Server information"); ?>    
    
    <p><input type='submit' value='Delete' /><input type='hidden' value='1' name='submitted' /> 
    </form>
    <a href='/cfg/config_server_edit_list.php'><button name="cancel" value="0" type="button">Cancel</button></a>

    <?php require ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer ?>
