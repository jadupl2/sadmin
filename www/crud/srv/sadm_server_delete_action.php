<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_delete_action.php
#   Version     :  1.0
#   Date        :  16 January 2019
#   Requires    :  php - MySQL
#   Description :  Page used to confirm, archive server data & finally delete server from Database.
#
#   Copyright (C) 2019 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
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
#@2019_01_15 New: sadm_server_delete.php v2.1 Create server data archive before deleting it.
#@2019_08_17 Update: v1.1 New Heading and return to Maintenance Server List
#
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar
require_once ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "1.1" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button



# ==================================================================================================
# SECOND EXECUTION OF PAGE AFTER THE FINAL DELETE CONFIRMATION IS DONE (DELETE SERVER DATA)
# ==================================================================================================
    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Submitted for ".$_POST['server_name'];} # Debug Info Start Submit
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }    # Fill in Post Array 

        if ($_POST['confirm'] == 'Yes') {                               # If User click button Yes
            $sql = "DELETE FROM server ";                               # Construct SQL Statement 
            $sql = $sql . "WHERE srv_name = '".$_POST['server_name']. "';"; # Construct SQL Statement 
            if ($DEBUG) { echo "<br>Delete SQL Command = $sql"; }       # In Debug display SQL Stat.

            # Execute the Row Update SQL & Catch Error
            if ( ! $result=mysqli_query($con,$sql)) {                   # Execute Update Row SQL
                $err_line = (__LINE__ -1) ;                             # Error on preceeding line
                $err_msg1 = "Row wasn't deleted\nError (";              # Advise User Message 
                $err_msg2 = strval(mysqli_errno($con)) . ") " ;         # Insert Err No. in Message
                $err_msg3 = mysqli_error($con) . "\nAt line "  ;        # Insert Err Msg and Line No 
                $err_msg4 = $err_line . " in " . basename(__FILE__);    # Insert Filename in Mess.
                sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Show Msg. Box for Usr
                echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List.
            }
            
            # If Archive don't already exist and Server Data Directory exist then create Archive
            $server_dir = SADM_WWW_DAT_DIR."/".$_POST['server_name'];
            $server_tgz = $_POST['archive'];

            if (file_exists($server_dir)) {                             # Data Dir. Exist for server
                if (! file_exists($server_tgz)) {                       # No Archive already exist ?
                    $CMD = "cd " . $server_dir . " ; tar -cvzf " .$server_tgz. " .";
                    exec($CMD,$output,$rc);
                    if ($rc <> 0) {
                        sadm_alert("Error ".$rc." while creating archive.");
                    }
                }
                $CMD = "rm -fr " . $server_dir ;
                exec($CMD,$output,$rc);
                if ($rc <> 0) { 
                    sadm_alert("Error ".$rc." while removing server data directory.");
                }
            }
        }

        # Back to the List Page
        #sadm_alert ("Last Stop");
        echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List.
        exit;
    }
    
 

#===================================================================================================
# INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING SERVER
#===================================================================================================
    if ($DEBUG) { echo "<br>Post isn't Submitted<br>"; }                # Display Debug Information    

    # CHECK IF THE KEY RECEIVED EXIST IN THE DATABASE AND RETRIEVE THE ROW DATA
    if ((isset($_GET['sel'])) and ($_GET['sel'] != ""))  {              # If Key Rcv and not Blank   
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>Key received is '" . $wkey ."'"; }      # Under Debug Show Key Rcv.
        $sql = "SELECT * FROM server WHERE srv_name='" . $wkey . "';";  # Form SQL Statement
        if ($DEBUG) { echo "<br>SQL = $sql<br>"; }                      # In Debug Display SQL Stat.   
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
    
    # DISPLAY PAGE HEADING
    $title1="System Deletion";                                          # Heading 1 Line
    $title2="Last confirmation before deleting '" . $row['srv_name'] . "." . $row['srv_domain'] ;
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading

    # Start of Form
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
     
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1'   name='submitted' />";        # hidden use On Nxt Page Exe
    echo "<input type='hidden' value=$wkey name='server_name' />";      # Save Server Name (Key)
    $archive_name = SADM_WWW_DAT_DIR . "/" . $wkey . '.tgz';            # Archive File Name
    echo "<input type='hidden' value=$archive_name name='archive' />";  # Archive tgz File Name
    
    # Ask for Final Confirmation
    echo "<center>";
    echo "<br>Are you sure you want to delete '" .$wkey. "' server from SADMIN ?<br>";

    # Display 'Yes' Button 
    echo "<br>\n\n<div class='two_buttons'>";
    echo "\n<div class='first_button'>";
    echo '  <input type="submit" name="confirm" value="Yes">';
    echo "</div>";
    # Display 'No' Button 
    echo "\n<div class='second_button'>";
    echo '  <input type="submit" name="confirm" value="No">';
    echo "</div>";
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";

    # Display Note to user
    echo "<br><br>";
    if (file_exists(SADM_WWW_DAT_DIR . "/" . $wkey )) {
        if (! file_exists($archive_name)) {                             # No Archive already exist ?
            echo "Note: An archive of server data will be created in '" .SADM_WWW_DAT_DIR. "' directory";
            echo "<br>      The name of the archive will be '" .$wkey. ".tgz'";
        }else{
            echo "<br>An archive already exist for that server and it won't be overwritten.";
        }
    }
    echo "</center>";
     
    # End of Form
    echo "</form>";
    echo "\n<br>"; 
    std_page_footer($con);                                               # Close MySQL & HTML Footer
 ?>   
