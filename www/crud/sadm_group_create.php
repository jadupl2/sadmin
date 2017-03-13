<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_group_create.php
#   Version     :  1.8
#   Date        :  13 March 2017
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Web Page used to create a new server Group.
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/sadm_group_common.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                       # Activate (TRUE) or Deactivate (FALSE) Debug



# ==================================================================================================
#              THIS IS THE SECOND EXECUTION OF PAGE AFTER THE DELETE BUTTON IS PRESS
# ==================================================================================================
    
    # Form is submitted - Process the Insertion of the row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_code']); }
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
     
        # Construct SQL to Insert row
        $sql = "INSERT INTO sadm.group ";                            # Construct SQL Statement
        $sql = $sql . "(grp_code, grp_desc, grp_default, grp_status) VALUES ('";
        $sql = $sql . $_POST['scr_code']    . "','" ;
        $sql = $sql . $_POST['scr_desc']    . "','" ;
        $sql = $sql . $_POST['scr_default'] . "','" ;
        $sql = $sql . $_POST['scr_status']  . "')"  ;
        if ($DEBUG) { echo "<br>SQL Command = $sql"; }                  # In Debug display SQL Stat.

        # Execute the Row Insertion SQL
        $row = pg_query($sql) ;                                         # Perform the SQL Query
        if (!$row){                                                     # If Insert didn't work
            $err_msg = "ERROR : Row wasn't inserted\n";                 # Error Message Part 1
            $err_msg = $err_msg . pg_last_error() . "\n";               # Error Message Part 2
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $sql ; }
            sadm_alert ($err_msg) ;                                     # Display Error Msg. Box
        }else{                                                          # Row was inserted
            sadm_alert ("Group '".$_POST['scr_code']."' created.");     # Msg. Box for User
        }
        pg_free_result($row);                                           # Frees memory and data 

        # Back to Group List Page
        ?> <script> location.replace("/crud/sadm_group_main.php"); </script><?php
        exit;
    }
    
 
# ==================================================================================================
#              THIS IS INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
# ==================================================================================================
    
    sadm_page_heading ("Create a Group");                               # Display Page Heading  

    # Start of Form - Display Form Ready to Accept Data
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_grp_form ($row,"Create");                                   # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";
    
    # Display Buttons (Create/Cancel) at the bottom of the form
    echo "<center>";
    echo "<button type='submit' class='btn btn-sm btn-primary'> Create </button>   ";
    echo "<a href='/crud/sadm_group_main.php'>";
    echo "<button type='button' class='btn btn-sm btn-primary'> Cancel </button></a>";
    echo "</center>";
    
    # End of Form
    echo "</form>"; 
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
