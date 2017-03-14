<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_category_update.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Web Page used to edit a category.
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
# 1.9 - March 2017 - Jacques Duplessis
#       Add lot of comments in code and enhance code performance 
# ==================================================================================================
#
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/sadm_category_common.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                       # Activate (TRUE) or Deactivate (FALSE) Debug



# ==================================================================================================
#              THIS IS THE SECOND EXECUTION OF PAGE AFTER THE UPDATE BUTTON IS PRESS
# ==================================================================================================

    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_code']); }
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }

        # If Default Category is True, Check if there is already a default category, Can't have two
        if ($_POST['scr_default']) {
            $sql = "SELECT cat_code, cat_default FROM sadm.category ";  # Construct SQL Statement
            $sql = $sql . "WHERE cat_default = '" . $_POST['scr_default'] . "'; ";
            if ($DEBUG) {                                               # Under Debug
                echo "<br>Checking if Category Default already exist."; # Display what were doing
                echo "\nSQL Command = $sql";                            # Display SQL to Check Def.
            }
            $result = pg_query($sql) ;                                  # Perform the SQL Query
            $count = pg_num_rows($result);                              # Get Nb Default Category
            $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;         # Read the Associated row
            if (($count > 0) and ($row['cat_code'] != $_POST['scr_code'])) {  # If Already Default Cat.
                $err_msg = "ERROR: Only one category can be the default."; 
                $err_msg = $err_msg . "\nCategory '" . $row['cat_code'] . "' is the default now.";
                $err_msg = $err_msg . "\nRemove default from '" . $row['cat_code'] . "' first.";
                sadm_alert($err_msg);                                   # Display Abort Delete Msg.
                pg_free_result($result);                                # Frees memory & date result
                ?> <script>location.replace("/crud/sadm_category_main.php");</script><?php 
                exit;            
            }
        }

        # Construct SQL to Update row
        $sql = "UPDATE sadm.category SET ";
        $sql = $sql . "cat_code = '"        . sadm_clean_data($_POST['scr_code'])       ."', ";
        $sql = $sql . "cat_desc = '"        . sadm_clean_data($_POST['scr_desc'])       ."', ";
        $sql = $sql . "cat_default = '"     . sadm_clean_data($_POST['scr_default'])    ."', ";
        $sql = $sql . "cat_status = '"      . sadm_clean_data($_POST['scr_status'])     ."'  ";
        $sql = $sql . "WHERE cat_code = '"  . sadm_clean_data($_POST['scr_code'])       ."'; ";
        if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }

        # Execute the Row Update SQL
        $row = pg_query($sql) ;                                         # Perform the SQL Query
        if (!$row){                                                     # If Update didn't work
            $err_msg = "ERROR : Row wasn't updated\n";                  # Error Message Part 1
            $err_msg = $err_msg . pg_last_error() . "\n";               # Error Message Part 2
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $sql ; }
            sadm_alert ($err_msg) ;                                     # Msg. Error Box for User
        }else{                                                          # Update done with success
            sadm_alert ("Category '".$_POST['scr_code']."' updated.");  # Advise user of success
        }
        pg_free_result($row);                                           # Frees memory and data 

        # Back to Category List Page
        ?> <script> location.replace("/crud/sadm_category_main.php"); </script><?php
        exit;
    }

 
# ==================================================================================================
#              THIS IS INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
# ==================================================================================================
    
    # Check if the Key Received exist in the Database and retrieve the row Data
    if ($DEBUG) { echo "<br>Post isn't Submitted"; }                    # Display Debug Information    
    if (isset($_GET['sel'])) {                                          # If row selection Receive
        $wkey = $_GET['sel'];                                           # Save Sel. to Work Key
        if ($DEBUG) { echo "<br>Key received is " . $wkey; }            # Under Debug Show Key Rcv.
        $query = "SELECT * FROM sadm.category WHERE cat_code = '" . $wkey . "' ;";  # Construct SQL
        if ($DEBUG) { echo "<br>SQL = $query"; }                        # In Debug display SQL Stat.   
        $result = pg_query($query);                                     # Execute SQL to Read Row
        if (!$result) {                                                 # If row wasn't found
            $err_msg = "ERROR : Category wasn't found in Database\n";   # Row was not found Msg.
            $err_msg = $err_msg . pg_last_error() . "\n";               # Add PostGres Err. Msg 
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $query ; }
            sadm_alert ($err_msg) ;                                     # Display Error Msg Box
            exit;
        }else{                                                          # If row was found
            $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;         # Read the Associated row
        }
    }else{                                                              # If no selection (Key) Recv
        $err_msg = "No Key Received - Please Advise" ;                  # Construct Error Msg.
        sadm_alert ($err_msg) ;                                         # Display Error Msg. Box
        ?><script>location.replace("/crud/sadm_category_main.php");</script><?php # Back 2 List Page
        exit ;
    }
    $title = "Update a Category" ;                                      # Page Heading Title
    sadm_page_heading ("$title");                                       # Display Page Heading  

    # Start of Form - Display Form Ready to Update Data
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_cat_form( $row , "Update");                                 # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";          # hidden use On Nxt Page Exe
    
    # Display Buttons (Update/Cancel) at the bottom of the form
    echo "<center>";                                                    # Center Button on Page
    echo "<button type='submit' class='btn btn-sm btn-primary'> Update </button>   ";
    echo "<a href='/crud/sadm_category_main.php'>";
    echo "<button type='button' class='btn btn-sm btn-primary'> Cancel </button></a>";
    echo "</center>";
    
    # End of Form
    echo "</form>";                                                     
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
