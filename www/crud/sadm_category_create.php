<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_category_create.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Web Page used to create a new server category.
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# ==================================================================================================
#
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                       # Activate (TRUE) or Deactivate (FALSE) Debug





# ==================================================================================================
#                                      PROGRAM START HERE
# ==================================================================================================
 

    # Form is submitted - Process the Insertion of the row
    if (isset($_POST['submitted'])) {
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_code']); }
        
        # Construct SQL to Insert row
        $sql1 = "INSERT INTO sadm.category ";
        $sql2 = "(cat_code, cat_desc, cat_status) VALUES ";
        $sql3 = "('" .  $_POST['scr_code'] . "','" ;
        $sql4 = $_POST['scr_desc']         . "','" ;
        $sql5 = $_POST['scr_status']       . "')"  ;
        $sql  = $sql1 . $sql2 . $sql3 . $sql4 . $sql5 ;
        if ($DEBUG) { echo "<br>Execute SQL Command = $sql"; }

        # Execute the Row Insertion SQL
        $row = pg_query($sql) ;
        if (!$row){
            $err_msg = "ERROR : Row was not inserted\n";
            $err_msg = $err_msg . pg_last_error() . "\n";
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $sql ; }
            sadm_alert ($err_msg) ;
        }else{
            sadm_alert ("Category code '" . sadm_clean_data($_POST['scr_code']) . "' inserted.");
        }

        # frees the memory and data associated with the specified PostgreSQL query result
        pg_free_result($row);

        # Back to Category List Page
        ?> <script> location.replace("/crud/sadm_category_main.php"); </script><?php
        exit;
    }
    
    
    # Display initial page for Insertion 
    $title = "Create a Category" ;                                      # Page Heading Title
    sadm_page_heading ("$title");                                       # Display Page Heading  

    # Start of Form - Display Form Ready to Accept Data
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_cat_form ( $row , "Create");                                # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";
    
    # Display Buttons at the bottom of the form
    echo "<center>";
    echo "<button type='submit' class='btn btn-sm btn-primary'>Create</button>   ";
    echo "<a href='/crud/sadm_category_main.php'>";
    echo "<button type='button' class='btn btn-sm btn-primary'>Cancel</button></a>";
    echo "</center>";
    
    # End of Form
    echo "</form>"; 
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
