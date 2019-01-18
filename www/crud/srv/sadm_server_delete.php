<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_delete.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to delete a server.
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
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
# 2017_03_09 Documentation: sadm_server_delete.php v1.8 Comments code and enhance code performance.
# 2017_11_15 Improve: sadm_server_delete.php v2.0 Restructure & modify web interface & MySQL DB.
#@2019_01_15 New: sadm_server_delete.php v2.1 Option to create server data archive before delete.
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar
require_once ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');

#===================================================================================================
#                                       Local Variables
#===================================================================================================
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.1" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_DEL    = '/crud/srv/sadm_server_delete_action.php';                # Confirm Delete Server Page
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button

 
#===================================================================================================
# EXECUTION START HERE - DISPLAY FORM WITH CORRESPONDING ROW DATA
#===================================================================================================

    # CHECK IF THE KEY RECEIVED EXIST IN THE DATABASE AND RETRIEVE THE ROW DATA
    if ($DEBUG) { echo "<br>Post isn't Submitted"; }                    # Display Debug Information    
    if ((isset($_GET['sel'])) and ($_GET['sel'] != ""))  {              # If Key Rcv and not Blank   
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>Key received is '" . $wkey ."'"; }      # Under Debug Show Key Rcv.
        $sql = "SELECT * FROM server WHERE srv_name = '" . $wkey . "'"; # SQL to Read Server Rcv Row
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Show SQL Command
        $KeyExist=False;                                                # Assume Key not Found in DB
        if ($result=mysqli_query($con,$sql)) {                          # Execute SQL Select
            if($result->num_rows >= 1) {                                # Number of Row Match Key
              $row = mysqli_fetch_assoc($result);                       # Read the Associated row
              $KeyExist=True;                                           # Key Does Exist in Database
            }
        }
        if (! $KeyExist) {                                              # If Key was not found
            $err_line = (__LINE__ -1) ;                                 # Error on line No.
            $err_msg1 = "Server '" . $wkey . "' not found.";            # Row was not found Msg.
            $err_msg2 = "\nAt line " .$err_line. " in " .basename(__FILE__); # Insert Filename 
            sadm_alert ($err_msg1 . $err_msg2);                         # Display Msg. Box for User
            echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List
        }
    }else{                                                              # If No Key Rcv or Blank
        $err_msg = "No Key Received - Please Advise" ;                  # Construct Error Msg.
        sadm_alert ($err_msg) ;                                         # Display Error Msg. Box
        echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List.
    }

    # START OF FORM - DISPLAY FORM READY TO UPDATE DATA
    display_std_heading("NotHome","Delete Server","","",$SVER);         # Display Content Heading
    
    # Start of Form - Display row data and press 'Delete' or 'Cancel' Button
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_srv_form ($con,$row,"Display");                             # Display No Change Allowed
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";          # hidden use On Nxt Page Exe
 
    # Display Buttons (Delete/Cancel) at the bottom of the form
    echo "\n\n<div class='two_buttons'>";
    echo "\n <div class='first_button'>";
    echo "\n   <a href='" . $URL_DEL . "?sel=" .$wkey. "'>";
    echo "     <button type='button'> Delete </button></a>";
    echo "\n </div>";
    echo "\n <div class='second_button'>";
    echo "\n   <a href='" . $URL_MAIN . "'>";
    echo "     <button type='button'> Cancel </button></a>";
    echo "\n </div>";
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";
    
    # End of Form
    echo "</form>";
    echo "\n<br>"; 
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>