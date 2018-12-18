<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_group_update.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to edit a group.
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
#       V1.8 Add lot of comments in code and enhance code performance 
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
#
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar
require_once ($_SERVER['DOCUMENT_ROOT'].'/crud/grp/sadm_group_common.php');



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.0" ;                                                        # Current version number
$URL_MAIN   = '/crud/grp/sadm_group_main.php';                          # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button



# ==================================================================================================
# SECOND EXECUTION OF PAGE AFTER THE UPDATE BUTTON IS PRESS
# ==================================================================================================
    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Submitted for " . $_POST['scr_code'];}  # Debug Info Start Submit
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }    # Fill in Post Array 

        # Is User want to set current Group to be the Default Group
        # Check if there is already a default group (Can't have two)
        if ($_POST['scr_default']) {
            $sql="SELECT grp_code, grp_default FROM server_group ";     # Construct SQL Statement
            $sql=$sql . "WHERE grp_default = '" . $_POST['scr_default'] . "'; ";
            if ($DEBUG) {                                               # If Under Debug
                echo "<br>Checking if Group Default already exist."; # Display what were doing
                echo "\nSQL Command = $sql";                            # Display SQL to Check Def.
            }
            $result = mysqli_query($con,$sql);                          # Exec SQL search default
            $count = mysqli_num_rows($result);                          # Count Cat that are Default
            $row = mysqli_fetch_assoc($result);                         # Read Cat. That is default 
            if (($count > 0) and ($row['grp_code'] != $_POST['scr_code'])) {  # Already a default ?
                $err_msg1  = "Only one group can be the default.\n"; # Create User Err. Message
                $err_msg2a = "Current Default Group is '" ;          # Display the Curremt
                $err_msg2b =  $row['grp_code'] . "' \n";                # Default Group 
                $err_msg3a = "Remove default from '". $row['grp_code']; # Advise User what to do
                $err_msg3b = "' group first.";                       # Del. Default from this one
                $err_msg   = $err_msg1 . $err_msg2a . $err_msg2b . $err_msg3a . $err_msg3b;
                sadm_alert($err_msg);                                   # Display Abort Delete Msg.
                mysqli_free_result($result);                            # Clear Result Set
                ?> <script>location.replace("/crud/grp/sadm_group_main.php");</script><?php 
                exit;            
            }
        }

        # Construct SQL to Update row
        $sql = "UPDATE server_group SET ";
        $sql = $sql . "grp_code = '"        . sadm_clean_data($_POST['scr_code'])       ."', ";
        $sql = $sql . "grp_desc = '"        . sadm_clean_data($_POST['scr_desc'])       ."', ";
        $sql = $sql . "grp_default = '"     . sadm_clean_data($_POST['scr_default'])    ."', ";
        $sql = $sql . "grp_active = '"      . sadm_clean_data($_POST['scr_active'])     ."', ";
        $sql = $sql . "grp_date = '"        . date( "Y-m-d H:i:s")                      ."'  ";
        $sql = $sql . "WHERE grp_code = '"  . sadm_clean_data($_POST['scr_code'])       ."'; ";
        if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }

        # Execute the Row Update SQL
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute Update Row SQL
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Row wasn't updated\nError (";                  # Advise User Message 
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
        }else{                                                          # Update done with success
            #$err_msg = "Group '" . $_POST['scr_code'] . "' updated"; # Advise user of success Msg
            #sadm_alert ($err_msg) ;                                     # Msg. Error Box for User
        }
        
        # Back to Group List Page
        ?> <script> location.replace("/crud/grp/sadm_group_main.php"); </script><?php
        exit;
    }

 
# ==================================================================================================
# INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
# ==================================================================================================


    # CHECK IF THE KEY RECEIVED EXIST IN THE DATABASE AND RETRIEVE THE ROW DATA
    if ($DEBUG) { echo "<br>Post isn't Submitted"; }                    # Display Debug Information    
    if ((isset($_GET['sel'])) and ($_GET['sel'] != ""))  {              # If Key Rcv and not Blank   
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>Key received is '" . $wkey ."'"; }      # Under Debug Show Key Rcv.
        $sql = "SELECT * FROM server_group WHERE grp_code = '" . $wkey . "'";  
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.   
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Group (" . $wkey . ") not found.\n";           # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
            exit;                                                       # Exit - Should not occurs
        }else{                                                          # If row was found
            $row = mysqli_fetch_assoc($result);                         # Read the Associated row
        }
    }else{                                                              # If No Key Rcv or Blank
        $err_msg = "No Key Received - Please Advise" ;                  # Construct Error Msg.
        sadm_alert ($err_msg) ;                                         # Display Error Msg. Box
        ?>
        <script>location.replace("/crud/grp/sadm_group_main.php");</script>
        <?php                                                           # Back 2 List Page
        #echo "<script>location.replace('" . URL_MAIN . "');</script>";
        exit ; 
    }


    # START OF FORM - DISPLAY FORM READY TO UPDATE DATA
    display_std_heading("NotHome","Group","","",$SVER);       # Display Content Heading
    
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_grp_form($row,"Update");                                    # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";          # hidden use On Nxt Page Exe
    
    # Display Buttons (Update/Cancel) at the bottom of the form
    echo "\n\n<div class='two_buttons'>";
    echo "\n<div class='first_button'><button type='submit'> Update </button></div>";
    echo "\n<div class='second_button'><a href='" . $URL_MAIN . "'><button type='button'> Cancel ";
    echo "</button></a>\n</div>";
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";
    
    echo "</form>";                                                      
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
