<?php 
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_category_edit.php
*   Version  :  1.5
*   Date     :  20 May 2016
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
$DEBUG = True;                                       # Activate (TRUE) or Deactivate (FALSE) Debug

        
// ================================================================================================
//                      Display Category Data used in the data input form
// ================================================================================================
function display_record( $wrow , $title) {
    sadm_page_heading ("$title");                                       # Display Page Title
    

    echo "<br><center>\n";
    #echo '<table frame="border" border="1" cellspacing="0" width="90%" >';
    echo "<table id='table_rch'>\n";

    $BGCOLOR="blue" ; $FNT_COLOR="#FFFFFF";
    $BGCOLOR="lavender";
    
    // Table Key - Category Code 
    echo "<tr>\n";
    echo "<td bgcolor=#4CAF50  align=left><b>Category Code : " . $wrow['cat_code'] ;
    echo "</td>\n";
    echo "</tr>\n";
    echo "</table>\n";
    echo "<br>\n";

    echo '<table frame="border" border="1" cellspacing="0" width="90%" >';

    // Category Description  
    echo "<tr><td  bgcolor=$BGCOLOR><b>Category Description</b></td>";
    echo "<td bgcolor=$BGCOLOR><input type='text' name='scr_desc' size=30 value='" .
        $wrow['cat_desc'] . "' /></td>";

 
    // Category Status
    echo "<tr>\n";
    echo "<td bgcolor=$BGCOLOR><b>Category Status</b></td>";
    if ($wrow['cat_status'] == 't') {
       echo "<td  bgcolor=$BGCOLOR>";
       echo '<input type="radio" name="scr_status" value="1" checked >Active';
       echo '<input type="radio" name="scr_status" value="0">Inactive</td>';
    }else{
       echo "<td  bgcolor=$BGCOLOR>";
       echo '<input type="radio" name="scr_status" value="1">Active';
       echo '<input type="radio" name="scr_status" value="0" checked >Inactive</td>';
    }
    echo "</tr>\n";
    echo "</table>\n";
}
    

/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/

    if (isset($_GET['sel']) ) { 
        $wkey = $_GET['sel'];
        if ($DEBUG) { echo "<br>Category received is " . $wkey; }       # Under Debug Show Cat Rcv. 
        if (isset($_POST['submitted'])) {
            if ($DEBUG) { echo "<br>Post Submitted for " . $scr_code; } # Under Debug Show Cat Code
            #foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
            #$var = $_POST;
            #$firephp->log($var, 'Post');
            if ($DEBUG) { echo "<br>scr_desc = $_POST['scr_desc']"; }     
            $sql = "UPDATE sadm.category SET cat_code = '" . $wkey . "',
                cat_desc           =  '" . $_POST['scr_desc'] . "',
                cat_status         =  '" . $_POST['scr_status'] ."',
                WHERE cat_code = '" . $wkey . "';"; 
            if ($DEBUG) { echo "<br>Update SQL = $sql"; }     
            $row = pg_query($query) or die('Query failed: ' . pg_last_error());
            header("location:/sadmin/sadm_category_main.php");
            exit;
        }else{
            if ($DEBUG) { echo "<br>Post is not Submitted - Read Category " . $wkey; } 
            $query = "SELECT * FROM sadm.category WHERE cat_code = '" . $wkey ."';";
            if ($DEBUG) { echo "<br>SQL = $query"; } 
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            if (!$result) {
                echo "An error while running SQL Query occurred.\n";
                exit;
            }else{
                $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;
                display_record( $row , "Edit Category Information");
            }   
        }
    }else{
         echo "<br>No Selection Received - Please Advice" ;
         exit ;
    }
?>

    <form action='' method='POST'>
        <p><input type='submit' value='Save' />
        <input type='hidden' value='1' name='submitted' /> 
    </form>
    <a href="/sadmin/sadm_category_main.php"><button name="cancel" value="0" type="button">Cancel</button></a>

<?php
     include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>

