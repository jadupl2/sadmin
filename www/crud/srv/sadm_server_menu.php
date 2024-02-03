<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis  
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_server_update.php
#   Version     :  1.8
#   Date        :  9 December 2017
#   Requires    :  php - MySQL
#   Description :  Web Page Menu used to edit a server.
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
#   2017_12_09 - Jacques Duplessis
#       V1.0 Initial version - Server Edit Menu to Split Server Table Edition Add lot of comments in code and enhance code performance 
# 2019_01_11 Update: v1.2 Add menu item for updating backup schedule,
# 2019_07_25 Update: v1.3 Minor modification to page layout.
# 2019_08_18 Update: v1.4 Add ReaR Backup in menu.
# 2020_01_04 Update: v1.5 Change Server C.R.U.D. Menu
# 2020_07_12 Update: v1.6 Add 'Delete System' as a menu item and change item labelling.
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head> CSS, JavaScript



?>
<style media="screen" type="text/css">

/* Menu Frame */
.menu {
    background-color:   #3b3b3b;
    color           :   #f9f4be;   
    font-family     :   Verdana, Geneva, sans-serif;
    font-size       :   1.0em;
    width           :   50%;
    margin          :   0px 0px 0px 0px;
    text-align      :   Center;
    border          :   10px solid #000000;   border-width : 1px;     border-style : solid;   
    border-color    :   #000000;             border-radius: 10px;
    line-height     :   1.7;    
}

 /* unvisited link */
 a:link {
  color: white;
}

/* visited link */
a:visited {
  color: green;
}

/* mouse over link */
a:hover {
  color: hotpink;
}

/* selected link */
a:active {
  color: blue;
} 


/* Attribute for Column Name at the left of the form */
.menu_item {
    font-size       :   14px;
    background-color:   #3b3b3b;
    /* margin-left     :   40px; */
    margin-left     :   auto;
    margin-right     :   auto;
    color           :    white;
    margin-bottom   :   5px;
    font-weight     :   bold;    
    width           :   70%;
    /* a:link { color: #ffffff; }
    a:visited { color: #ffffff; }
    a:hover { color: #ffffff; }
    a:active { color: #ffffff; }  */
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
$SVER           = "1.6" ;                                               # Current version number
$URL_MAIN       = '/crud/srv/sadm_server_main.php';                     # Maintenance Main Page URL
$URL_UPDATE     = '/crud/srv/sadm_server_update.php';                   # Update System Page URL
$URL_DELETE     = '/crud/srv/sadm_server_delete.php';                   # Delete System Page URL
$URL_OSUPDATE   = '/crud/srv/sadm_server_osupdate.php';                 # O/S Update Page URL
$URL_BACKUP     = '/crud/srv/sadm_server_backup.php';                   # Daily Backup Upd. Page URL
$URL_REAR       = '/crud/srv/sadm_server_rear_backup.php';              # ReaR backup schedule page
$URL_HOME       = '/index.php';                                         # Site Main Page
$CREATE_BUTTON  = False ;                                               # Don't Show Create Button
$URL_MENU       = "/crud/srv/sadm_server_menu.php";                     # CRUD Server Menu URL


// ================================================================================================
//                      DISPLAY SERVER UPDATE MENU 
// ================================================================================================
function display_menu($wkey) {
    global $URL_UPDATE, $URL_OSUPDATE, $URL_BACKUP, $URL_MAIN, $URL_MENU, $URL_DELETE, $URL_REAR;
    echo "\n<br><br><center>";
    echo "\n\n<div class='menu'>\n";                                    # Start Menu
    echo "\n<br>";

    echo "\n<div class='menu_item'>\n";                                 # Start Menu Item
    echo "\n<p>";
    echo "\n<a href='" . $URL_UPDATE . "?sel=" . $wkey . "&back=" . $URL_MENU ; 
    echo "'>Modify system static information</a></p>";
    echo "\n<p>";
    echo "\n<a href='" . $URL_DELETE . "?sel=" . $wkey . "&back=" . $URL_MENU ; 
    echo "'>Remove system from SADMIN</a></p>";
    echo "\n<p>";
    echo "\n<a href='" . $URL_OSUPDATE . "?sel=" . $wkey . "&back=" . $URL_MENU ;
    echo "'>Modify O/S update schedule</a></p>";
    echo "\n<p>";
    echo "\n<a href='" . $URL_BACKUP . "?sel=" . $wkey . "&back=" . $URL_MENU ;
    echo "'>Modify Backup schedule</a></p>";
    echo "\n<p>";
    echo "\n<a href='" . $URL_REAR . "?sel=" . $wkey . "&back=" . $URL_MENU ;
    echo "'>Modify ReaR backup schedule</a></p>";
    echo "\n<br>";
    echo "\n<p>\n<a href='" . $URL_MAIN . "'>Back to system list</a></p>";
    echo "\n</div>";                                                    # << End of menu_item
    echo "\n<br>";
    echo "\n</center>";
    echo "\n</div>\n<br>\n\n";                                          # End of Menu Div.
}


# ==================================================================================================
# Page Process Start Here
# ==================================================================================================


    if (isset($_GET['sel']) && !empty($_GET['sel'])) {                  # If Key Rcv and not Blank   
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>Key received is '" . $wkey ."'"; }      # Under Debug Show Key Rcv.
        $sql = "SELECT * FROM server WHERE srv_name = '" . $wkey . "';";  
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.   

        # Run query, put data in $result
        $result = mysqli_query($con, $sql);                             # Run query 

        if (mysqli_num_rows($result) < 1) {                             # If Server Name not found
            $err_line = (__LINE__ -1) ;                                 # Error on preceding line
            $err_msg1 = "System '" . $wkey . "' not found in database.\n"; # Row was not found Msg.
            $err_msg2 = "Error no." . strval(mysqli_errno($con)) ;      # Insert Err No. in Message
            $err_msg3 = "\nAt line " . $err_line . " in " . basename(__FILE__); # Insert Error Line#
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 );            # Display Msg. Box for User
            exit;                                                       # Exit - Should not occurs
        }else{                                                          # If row was found
            $row = mysqli_fetch_assoc($result);                         # Read the Associated row
            #mysqli_free_result($result);                               # Free result set
        }
    }else{                                                              # If No Key Rcv or Blank
        $err_msg = "No Key Received - Please Advise" ;                  # Construct Error Msg.
        sadm_alert ($err_msg) ;                                         # Display Error Msg. Box
        echo "<script>location.replace(" .$URL_MAIN. ");</script>";
        exit ; 
    }

    # DISPLAY SCREEN HEADING    
    $title1="Update System Information Menu";
    $title2="'" . $row['srv_name'] . "." . $row['srv_domain'] . "'";
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading
    #
    # Show Menu 
    display_menu($wkey);                                                # Display Form Default Value
    #
    echo "\n<br>";                                                      # Blank Line After Button
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
