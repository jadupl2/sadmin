<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_server_delete_action.php
#   Version     :  1.0
#   Date        :  16 January 2019
#   Requires    :  php - MySQL
#   Description :  Page used to confirm, archive server data & finally delete server from Database.
#
#    2019 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
# 2019_01_15 web v1.0 CRUD_client_delete - Create server data archive before deleting it.
# 2019_08_17 web v1.1 CRUD_client_delete - New heading and return to Maintenance Server List
# 2019_12_26 web v1.2 CRUD_client_delete - Deleted server now place in www/dat/archive directory.
# 2021_06_07 web v1.3 CRUD_client_delete - Fix faulty message when deleting a client after creating it.
# 2022_07_18 web v1.4 CRUD_client_delete - Fix delete permission problem & show archive file name.
# 2022_09_24 web v1.5 CRUD_client_delete - Change text in page header.
#@2026_03_12 web v1.6 CRUD_client_delete - Archive the rrd (perf.Stat.) to the archive & some fixes.
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
$SVER  = "1.6" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button



# ==================================================================================================
# SECOND EXECUTION OF PAGE AFTER THE FINAL DELETE CONFIRMATION IS DONE, ARCHIVE & DELETE SERVER DATA
# ==================================================================================================
    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Submitted for ".$_POST['server_name'];} # Debug Info Start Submit
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }    # Fill in Post Array 

        if ($_POST['confirm'] == 'No') {                               # If User click button No
            echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List.
            exit;
        }


        # Remove system from database.
        $sql = "DELETE FROM server ";                               # Construct SQL Statement 
        $sql = $sql ."WHERE srv_name = '" .$_POST['server_name']. "';"; # Construct SQL cmd 
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
            

        # Name of actual data directory for that server
        $server_dir = SADM_WWW_DAT_DIR  . "/" . $_POST['server_name']; 
        if ($DEBUG) { echo "<br>server_dir=".$server_dir ;}       
            
        # Name of actual RRD directory for that server
        $server_rrd_dir = SADM_WWW_RRD_DIR  . "/" . $_POST['server_name']; 
        if ($DEBUG) { echo "<br>server_rrd_dir=".$server_rrd_dir ;}       
            
        # Name of the archive that will be created before deleting system data
        $server_tgz = $_POST['archive']  ; 
        if ($DEBUG) { echo "<br>server_tgz= " . $server_tgz ; }             
      

        # Does Data Directory exist ($SADMIN/www/dat/$HOSTNAME) or ($SADMIN/www/rrd/$HOSTNAME)
        if (is_dir($server_dir)) {                                  # System Data Dir. Exist ? 
            $CMD = "tar -cvf " . $server_tgz ." ". $server_dir ;
            if ($DEBUG) { echo "<br>CMD=$CMD" ;}       
            exec($CMD,$output,$rc);
            if ($rc != 0) { sadm_alert("Error #".$rc." while creating archive.\n" .$CMD);}
            $CMD = "rm -fr " . $server_dir ;
            if ($DEBUG) { echo "<br>CMD=$CMD" ;}       
            exec($CMD,$output,$rc);
            if ($rc <> 0) { 
                sadm_alert("Error removing " .$server_dir. " directory.\nYou can safely remove it manually."); 
            }
        }

        if (is_dir($server_rrd_dir)) {                              # System rrd Dir. Exist ? 
            $CMD = "tar -rvf " . $server_tgz ." ". $server_rrd_dir ;
            if ($DEBUG) { echo "<br>CMD=$CMD" ;}       
            exec($CMD,$output,$rc);
            if ($rc != 0) { sadm_alert("Error #".$rc." while creating archive.\n" . $CMD); }
            $CMD = "rm -fr " . $server_rrd_dir ;
            if ($DEBUG) { echo "<br>CMD=$CMD" ;}       
            exec($CMD,$output,$rc);
            if ($rc <> 0) { 
                sadm_alert("Error removing " .$server_rrd_dir. " directory.\nYou can safely remove it manually."); 
            }
        }
        
        if (file_exists($server_tgz)) {
            sadm_alert("System removed from Database and the archive file is created.");
        } else {
            sadm_alert("The archive file could not be created ?");
        }
        
        echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List.
        exit;
    }
    
 

#===================================================================================================
# INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING SERVER
#===================================================================================================
    if ($DEBUG) { echo "<br>Post isn't Submitted"; }                    # Display Debug Information    

    # Check if the system to delete, exist in the database and retrieve the row data.
    if ((isset($_GET['sel'])) and ($_GET['sel'] != ""))  {              # If Key Rcv and not Blank   
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>System name received is '" . $wkey ."'"; }  
        $sql = "SELECT * FROM server WHERE srv_name='" . $wkey . "';";  # System exist in Database
        if ($DEBUG) { echo "<br>SQL = $sql<br>"; }                      # In Debug Display SQL Stat. 

        # Verify if system name exist in Database
        if ($result=mysqli_query($con,$sql)) {                          # Execute SQL Select
            #if($result->num_rows >= 1) {                               # Number of Row Match Key
            $row = mysqli_fetch_assoc($result);                         # Read the Associated row
            $KeyExist=True;                                             # Key Does Exist in Database
        }else{
            $KeyExist=False;                                            # Assume Key not Found in DB
            $err_line = (__LINE__ -1) ;                                 # Error on line No.
            $err_msg1 = "The system name '" . $wkey . "' not found in Database,"; 
            $err_msg2 = "\nAt line " .$err_line. " in " .basename(__FILE__) ;
            sadm_alert ($err_msg1 . $err_msg2);                         # Display Msg. Box for User
            echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List
        }
    }else{                                                              # If No Key Rcv or Blank
        $err_msg = "No system name received - Please Advise" ;          # Construct Error Msg.
        sadm_alert ($err_msg) ;                                         # Display Error Msg. Box
        echo "<script>location.replace('" . $URL_MAIN . "');</script>"; # Backup to Server List.
    }
    

    # Display Page Heading
    $title1="SADMIN client deletion confirmation";                      # Heading 1 Line
    $title2="Last confirmation before deleting '" . $row['srv_name'] . "." . $row['srv_domain'] ;
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading

    # Start of Form
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    echo "<input type='hidden' value='1'   name='submitted' />";        # hidden use On Nxt Page Exe
    echo "<input type='hidden' value=$wkey name='server_name' />";      # Save Server Name (Key)

    $archive_file_name = $wkey . "_" . date('Y_m_d_H_i') . ".tgz"; 
    $archive_name = SADM_WWW_ARC_DIR ."/". $archive_file_name ; 
    echo "<input type='hidden' value=$archive_name name='archive' />";  # Archive tgz File Name
    
    # Ask for Final Confirmation
    echo "<center>";
    echo "<br>Are you sure you want to delete '" .$wkey. "' system from SADMIN ?<br>";

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
    echo "Note: An archive of this system data will be created in '" .SADM_WWW_ARC_DIR. "/' directory.";
    echo "<br>      The name of the archive will be " . $archive_file_name ;
    echo "</center>";
     
    # End of Form
    echo "</form>";
    echo "\n<br>"; 
    std_page_footer($con);                                               # Close MySQL & HTML Footer
 ?>   
