<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_category_edit.php
*   Version     :  1.8
*   Date        :  13 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Web Page used to edit a category.
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

    
    # THIS SECTION IS EXECUTED WHEN THE UPDATE BUTTON IS PRESS
    # ----------------------------------------------------------------------------------------------
    
    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_code']); }
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
         
        # Construct SQL to Update row
        $sql1 = "UPDATE sadm.category SET ";
        $sql2 = "cat_code = '" . sadm_clean_data($_POST['scr_code'])   ."', ";
        $sql3 = "cat_desc = '" . sadm_clean_data($_POST['scr_desc'])   ."', ";
        $sql4 = "cat_status = '" . sadm_clean_data($_POST['scr_status']) ."'  ";
        $sql5 = "WHERE cat_code = '" . sadm_clean_data($_POST['scr_code'])   ."'; ";
        $sql  = $sql1 . $sql2 . $sql3 . $sql4 . $sql5 ;
        if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }

        # Execute the Row Update SQL
        $row = pg_query($sql) ;
        if (!$row){
            $err_msg = "ERROR : Row was not updated\n";
            $err_msg = $err_msg . pg_last_error() . "\n";
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $sql ; }
            sadm_alert ($err_msg) ;
        }else{
            sadm_alert ("Category code '" . sadm_clean_data($_POST['scr_code']) . "' updated.");
        }

        # frees the memory and data associated with the specified PostgreSQL query result
        pg_free_result($row);

        # Back to Category List Page
        ?> <script> location.replace("/crud/sadm_category_main.php"); </script><?php
        exit;
    }

        
    # INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
    # ----------------------------------------------------------------------------------------------

    # Check if the Key Received, exist in the Database and retrieve the row Data    
    if (isset($_GET['sel']) ) {
        $wkey = $_GET['sel'];
        if ($DEBUG) { echo "<br>Post is not Submitted - Read Key " . $wkey; }

        # Construct SQL to Read the row
        $query = "SELECT * FROM sadm.category WHERE cat_code = '" . $wkey ."';";
        if ($DEBUG) { echo "<br>SQL = $query"; }
        
         # Execute the SQL to Read the Row
         $result = pg_query($query) ;
        if (!$result) {
            $err_msg = "ERROR : Row was not found in Database\n";
            $err_msg = $err_msg . pg_last_error() . "\n";
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $query ; }
            sadm_alert ($err_msg) ;  
            exit;
        }else{
           $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;
        }
    }else{
        $err_msg = "No Key Received - Please Advice" ;
        sadm_alert ($err_msg) ;
        exit ;
    }
    
    # Display initial page for Row Update 
    $title = "Update a Category" ;                                      # Page Heading Title
    sadm_page_heading ("$title");                                       # Display Page Heading  

    # Start of Form - Display Form Ready to Update Data
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_cat_form( $row , "Update");                                 # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";
    
    # Display Buttons at the bottom of the form
    echo "<center>";
    echo "<button type='submit' class='btn btn-sm btn-primary'>Update </button>   ";
    echo "<a href='/crud/sadm_category_main.php'>";
    echo "<button type='button' class='btn btn-sm btn-primary'> Cancel</button></a>";
    echo "</center>";
    
    # End of Form
    echo "</form>"; 
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
