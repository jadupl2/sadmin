<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_category_create.php
*   Version     :  1.8
*   Date        :  13 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Web Page used to create a new server category.
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                       # Activate (TRUE) or Deactivate (FALSE) Debug




/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/
 
    if (isset($_POST['submitted'])) {
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_code']); }
        $sql1 = "INSERT INTO sadm.category ";
        $sql2 = "(cat_code, cat_desc, cat_status) VALUES ";
        $sql3 = "('" .  $_POST['scr_code'] . "','" ;
        $sql4 = $_POST['scr_desc']         . "','" ;
        $sql5 = $_POST['scr_status']       . "')"  ;
        $sql  = $sql1 . $sql2 . $sql3 . $sql4 . $sql5 ;
        if ($DEBUG) { echo "<br>Execute SQL Command = $sql"; }
        $row = pg_query($sql) or die('Query failed: ' . pg_last_error());
        if (!$row){
            sadm_alert ("Insert failed!!\nProblem with Command :" . $sql ."\npg_last_error()");
        }else{
            sadm_alert ("Category code '" . sadm_clean_data($_POST['scr_code']) . "' inserted.");
        }

        # frees the memory and data associated with the specified PostgreSQL query result
        pg_free_result($row);

        # Back to Category List Page
        ?> <script> location.replace("/crud/sadm_category_main.php"); </script><?php
        exit;
    }
    $title = "Create a Category" ;
    sadm_page_heading ("$title");                                       # Display Page Title  
?>
    <form action="<?php echo htmlentities($_SERVER['PHP_SELF']) ?>" method='POST'>
        <?php display_cat_record( $row , "Create"); ?>

        <center>
        <input type='hidden' value='1' name='submitted' />
        <button type="submit" class="btn btn-sm btn-primary">Create</button>
        <a href="/crud/sadm_category_main.php"><button type="button" class="btn btn-sm btn-primary">Cancel</button></a>
        </center>
    </form>
    
<?php
     include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
