<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_update.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to edit a server.
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
#   2018_02_03 - Jacques Duplessis
#       V2.1 Added Server Graph Display Option
#@2019_08_17 Update: v2.2 Use new heading function, return to caller screen when exiting.
# ==================================================================================================
#
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>

?>
 <style media="screen" type="text/css">
.deux_boutons   { width : 70%;   margin: 1% auto;   } 
.premier_bouton { width : 20%;  float : left;   margin-left : 25%;  text-align : right ; }
.second_bouton  { width : 20%;  float : right;  margin-right: 25%;  text-align : left  ; }
</style>
<?php

require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar
require_once ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.2" ;                                                        # Current version number
#$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_MAIN   = '/crud/srv/sadm_server_menu.php?sel=';                    # Maintenance Menu Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button



# ==================================================================================================
# SECOND EXECUTION OF PAGE AFTER THE UPDATE BUTTON IS PRESS
# ==================================================================================================
    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Submitted for " . $_POST['scr_name'];}  # Debug Info Start Submit
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }    # Fill in Post Array 

        # Construct SQL to Update row
        $sql = "UPDATE server SET ";
        $sql = $sql . "srv_name = '"            . sadm_clean_data($_POST['scr_name'])       ."', ";
        $sql = $sql . "srv_domain = '"          . sadm_clean_data($_POST['scr_domain'])     ."', ";
        $sql = $sql . "srv_desc = '"            . sadm_clean_data($_POST['scr_desc'])       ."', ";
        $sql = $sql . "srv_tag = '"             . sadm_clean_data($_POST['scr_tag'])        ."', ";
        $sql = $sql . "srv_sadmin_dir = '"      . sadm_clean_data($_POST['scr_sadmin_dir']) ."', ";
        $sql = $sql . "srv_note = '"            . sadm_clean_data($_POST['scr_note'])       ."', ";
        $sql = $sql . "srv_active = '"          . sadm_clean_data($_POST['scr_active'])     ."', ";
        $sql = $sql . "srv_sporadic = '"        . sadm_clean_data($_POST['scr_sporadic'])   ."', ";
        $sql = $sql . "srv_monitor = '"         . sadm_clean_data($_POST['scr_monitor'])    ."', ";
        $sql = $sql . "srv_alert_group = '"     . sadm_clean_data($_POST['scr_alert_group'])       ."', ";
        $sql = $sql . "srv_graph = '"           . sadm_clean_data($_POST['scr_graph'])      ."', ";
        $sql = $sql . "srv_cat = '"             . sadm_clean_data($_POST['scr_cat'])        ."', ";
        $sql = $sql . "srv_group = '"           . sadm_clean_data($_POST['scr_group'])      ."', ";
        $sql = $sql . "srv_ostype = '"          . sadm_clean_data($_POST['scr_ostype'])     ."', ";
        $sql = $sql . "srv_date_edit = '"       . date( "Y-m-d H:i:s")                      ."'  ";
        $sql = $sql . "WHERE srv_name = '" . sadm_clean_data($_POST['scr_name'])       ."'; ";
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
            #$err_msg = "Server '" . $_POST['scr_name'] . "' updated"; # Advise user of success Msg
            #sadm_alert ($err_msg) ;                                     # Msg. Error Box for User
        }
                
        # Back to Calling Page
        echo "<script>location.replace('" . $_POST['BACKURL'] . "');</script>";  # Backup to Caller URL
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
        $sql = "SELECT * FROM server WHERE srv_name = '" . $wkey . "'";  
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.   
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Server (" . $wkey . ") not found.\n";           # Row was not found Msg.
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
        exit ;
    }

    # 2nd parameters reference the URL where this page was called.
    if ($DEBUG) { echo "<br>2nd Parameter Received is " . $back; }      # Under Debug Show 2nd Parm.
    if ((isset($_GET['back'])) and ($_GET['back'] != ""))  {            # If Value Rcv and not Blank
        $BACKURL = $_GET['back'] ."?sel=" . $wkey ;                     # Save 2nd Parameter Value
    }else{
        $BACKURL = $URL_MAIN . $wkey;                                   # Where to go back after 
    }

    # DISPLAY PAGE HEADING
    $title1="System Maintenance";                                       # Heading 1 Line
    $title2="Update '" . $row['srv_name'] . "." . $row['srv_domain'] . "' static information";
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading

    echo "\n\n<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_srv_form($con,$row,"Update");                               # Display Form Default Value
    echo "\n<input type='hidden' value='1' name='submitted' />";        # hidden use On Nxt Page Exe
    echo "\n<input type='hidden' value='".$BACKURL."' name='BACKURL'  />"; # Save Caller URL
    
    # DISPLAY BUTTONS (UPDATE/CANCEL) AT THE BOTTOM OF THE FORM
    echo "\n\n<div class='deux_boutons'>";
    echo "\n<div class='premier_bouton'><button type='submit'> Update </button></div>";
    echo "\n<div class='second_bouton'><a href='" . $BACKURL . "'><button type='button'> Cancel ";
    echo "</button></a>\n</div>";
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";
    
    echo "\n</form>";                                                     
    echo "\n<br>";                                                      # Blank Line After Button
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
