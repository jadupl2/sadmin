<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_category_create.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
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
# ChangeLog
#   2017_03_09 - Jacques Duplessis
#       V1.9 Add lot of comments in code and enhance code performance 
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
#
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHead.php');  # <head>CSS,JavaScript</Head>
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/cat/sadm_category_common.php');
echo "<body>";                                                          # Begin HTML body Section
echo "<div id='sadmWrapper'>";                                          # Whole Page Wrapper Div
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeading.php');    # Top Universal Page Heading
echo "<div id='sadmPageContents'>";                                     # Lower Part of Page
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');    # Display SideBar on Left               
echo "<div id='sadmRightColumn'>";                                      # Beginning Content Page




#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.0" ;                                                        # Current version number
$URL_MAIN   = '/crud/cat/sadm_category_main.php';                       # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button




# ==================================================================================================
#              THIS IS THE SECOND EXECUTION OF PAGE AFTER THE DELETE BUTTON IS PRESS
# ==================================================================================================
    
    # Form is submitted - Process the Insertion of the row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_code']); }
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
     
        # Construct SQL to Insert row
        $sql = "INSERT INTO sadm.category ";                            # Construct SQL Statement
        $sql = $sql . "(cat_code, cat_desc, cat_status) VALUES ('";
        $sql = $sql . $_POST['scr_code']    . "','" ;
        $sql = $sql . $_POST['scr_desc']    . "','" ;
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
            sadm_alert ("Category '".$_POST['scr_code']."' created."); # Msg. Box for User
        }
        pg_free_result($row);                                           # Frees memory and data 

        # Back to Category List Page
        ?> <script> location.replace("/crud/cat/sadm_category_main.php"); </script><?php
        exit;
    }
    
 
# ==================================================================================================
#              THIS IS INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
# ==================================================================================================
    
    # START OF FORM - DISPLAY FORM READY TO UPDATE DATA
    display_page_heading("home","Create Category",$CREATE_BUTTON);      # Display Content Heading
     $title = "Create a Category" ;                                      # Page Heading Title
    sadm_page_heading ("$title");                                       # Display Page Heading  

    # Start of Form - Display Form Ready to Accept Data
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_cat_form ( $row , "Create");                                # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";
    
    # Display Buttons (Create/Cancel) at the bottom of the form
    echo "<center>";
    echo "<button type='submit' class='btn btn-sm btn-primary'> Create </button>   ";
    echo "<a href='/crud/cat/sadm_category_main.php'>";
    echo "<button type='button' class='btn btn-sm btn-primary'> Cancel </button></a>";
    echo "</center>";
    
    # End of Form
    echo "</form>"; 


    mysqli_free_result($result);                                        # Free result set 
    mysqli_close($con);                                                 # Close Database Connection
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of CatTable          -->" ;                   # End Of CatTable Div
    echo "</div> <!-- End of sadmRightColumn   -->" ;                   # End of Left Content Page       
    echo "</div> <!-- End of sadmPageContents  -->" ;                   # End of Content Page
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageFooter.php')  ;    # SADM Std EndOfPage Footer
    echo "</div> <!-- End of sadmWrapper       -->" ;                   # End of Real Full Page
?>
