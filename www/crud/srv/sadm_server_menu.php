<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis  
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_update.php
#   Version     :  1.8
#   Date        :  9 December 2017
#   Requires    :  php - MySQL
#   Description :  Web Page Menu used to edit a server.
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
#   2017_12_09 - Jacques Duplessis
#       V1.0 Initial version - Server Edit Menu to Split Server Table Edition Add lot of comments in code and enhance code performance 
# 2019_01_11 Feature: v1.2 Add menu item for updating backup schedule,
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head> CSS, JavaScript
?>
<style media="screen" type="text/css">
.menu {
    font-family     :   Verdana, Geneva, sans-serif;
    background-color:   #fff5c3;
    color           :   black;
    width           :   30%;
    margin-top      :   1%;
    margin-left     :   auto;
    margin-right    :   auto;
    border          :   2px solid #000000;
    font-size       :   14px;
    text-align      :   left;
    padding         :   1%,1%,1%,1%;
    border-width    :   1px;
    border-style    :   solid;
    border-color    :   #000000;
    border-radius   :   10px;
    line-height     :   1.7;    
}
/* Attribute for Column Name at the left of the form */
.menu_item {
    font-size       :   14px;
    margin-left     :   20px;
    margin-bottom   :   20px;
    /* background-color:   Yellow; */
    font-weight     :   bold;    

}
</style>
<?php
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # </head> Heading & SideBar
require_once ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG          = False ;                                               # Debug Activated True/False
$SVER           = "1.2" ;                                               # Current version number
$URL_MAIN       = '/crud/srv/sadm_server_main.php';                     # Maintenance Main Page URL
$URL_UPDATE     = '/crud/srv/sadm_server_update.php';                   # Update Page URL
$URL_OSUPDATE   = '/crud/srv/sadm_server_osupdate.php';                 # O/S Update Page URL
$URL_BACKUP     = '/crud/srv/sadm_server_backup.php';                   # O/S Update Page URL
$URL_HOME       = '/index.php';                                         # Site Main Page
$CREATE_BUTTON  = False ;                                               # Don't Show Create Button


// ================================================================================================
//                      DISPLAY SERVER UPDATE MENU 
// ================================================================================================
function display_menu($wkey) {
    global $URL_UPDATE, $URL_OSUPDATE, $URL_BACKUP;

    echo "\n\n<div class='menu'>\n";                             # Start simple_menu
    
    echo "\n<div class='menu_item'>\n";                             # Start simple_menu
    echo "\n<p>";
    echo "\n<a href='" . $URL_UPDATE . "?sel=" . $wkey ; 
    echo "'>- Edit Static information</a></p>";
    echo "\n<p>";
    echo "\n<a href='" . $URL_OSUPDATE . "?sel=" . $wkey ;
    echo "'>- Edit O/S Update Schedule</a></p>";
    echo "\n<p>";
    echo "\n<a href='" . $URL_BACKUP . "?sel=" . $wkey ;
    echo "'>- Edit Backup Schedule</a></p>";
    #echo "\n<br>";
    echo "\n</div>";                                                    # << End of menu_item

    echo "\n</div>";                                                    # << End of menu
    echo "\n<br>\n\n";                                                  # Blank Lines
}


# ==================================================================================================
# Page Process Start Here
# ==================================================================================================

    display_std_heading("Home","Update Server Menu","","",$SVER);       # Display Content Heading

    if ((isset($_GET['sel'])) and ($_GET['sel'] != ""))  {              # If Key Rcv and not Blank   
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>Key received is '" . $wkey ."'"; }      # Under Debug Show Key Rcv.
        $sql = "SELECT * FROM server WHERE srv_name = '" . $wkey . "'";  
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.   
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Server (" . $wkey . ") not found.\n";          # Row was not found Msg.
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
        <script>location.replace("/crud/srv/sadm_server_main.php");</script>
        <?php                                                           # Back 2 List Page
        #echo "<script>location.replace('" . URL_MAIN . "');</script>";
        exit ; 
    }
    $title="Update Information for " . $wkey . " server";
    echo "<center><strong>" . $title . "</strong></center>";
    display_menu($wkey);                                                # Display Form Default Value
    echo "\n<br>";                                                      # Blank Line After Button
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
