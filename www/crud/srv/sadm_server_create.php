<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_server_create.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to create a new server server.
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2017_03_09 web v1.9 CRUD_client - Add lot of comment and enhance code performance 
# 2017_11_15 web v2.0 CRUD_client - Modify to used to new web interface and MySQL Database.
# 2018_02_03 web v2.1 CRUD_client - Added Server Graph Display Option
# 2019_08_29 web v2.2 CRUD_client - New page heading, using the library heading function.
# 2022_09_24 web v2.3 CRUD_client - Add SSH port to communicate with client.
# 2022_09_24 web v2.4 CRUD_client - When ing a  client, create client dir. in $SADMIN/www/dat.
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
$SVER  = "2.4" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button



# ==================================================================================================
# SECOND EXECUTION OF PAGE AFTER THE CREATE BUTTON IS PRESS
# ==================================================================================================
    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Submitted for " . $_POST['scr_code'];}  # Debug Info Start Submit
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }    # Fill in Post Array 

        # Construct SQL to Insert row
        $sql = "INSERT INTO server ";                                   # Construct SQL Statement
        $sql = $sql . "(srv_name, srv_domain, srv_desc, srv_tag, srv_note, srv_active, ";
        $sql = $sql . " srv_sporadic, srv_monitor, srv_alert_group, srv_graph, srv_cat, srv_group,";
        $sql = $sql . "  srv_ostype, srv_ssh_port, srv_date_creation) VALUES ('";
        $sql = $sql . $_POST['scr_name']        . "','" ;
        $sql = $sql . $_POST['scr_domain']      . "','" ;
        $sql = $sql . $_POST['scr_desc']        . "','" ;
        $sql = $sql . $_POST['scr_tag']         . "','" ;
        $sql = $sql . $_POST['scr_note']        . "','" ;
        $sql = $sql . $_POST['scr_active']      . "','" ;
        $sql = $sql . $_POST['scr_sporadic']    . "','" ;
        $sql = $sql . $_POST['scr_monitor']     . "','" ;
        $sql = $sql . $_POST['scr_alert_group'] . "','" ;
        $sql = $sql . $_POST['scr_graph']       . "','" ;
        $sql = $sql . $_POST['scr_cat']         . "','" ;
        $sql = $sql . $_POST['scr_group']       . "','" ;
        $sql = $sql . $_POST['scr_ostype']      . "','" ;
        $sql = $sql . $_POST['scr_ssh_port']    . "','" ;
        $sql = $sql . date( "Y-m-d H:i:s")      . "')"  ;
        if ($DEBUG) { echo "<br>SQL Command = $sql"; }                  # In Debug display SQL Stat.

        # Execute the Row Insert SQL
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Row wasn't inserted \nError (";                # Advise User Message 
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
        }
        # Make system data directory
        $client_dir = SADM_WWW_DAT_DIR . "/" . $_POST['scr_name'];
        mkdir($client_dir);

        # Back to Group List Page
        ?> <script> location.replace("/crud/srv/sadm_server_main.php"); </script><?php
        exit;
    }
    
 
# ==================================================================================================
#              THIS IS INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
# ==================================================================================================
    
    # START OF FORM - DISPLAY FORM READY TO ACCEPT DATA
    display_lib_heading("NotHome","Create SADMIN Client","",$SVER);       # Display Content Heading

    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_srv_form ($con,$row,"Create");                              # Display Form Default Value
    echo "<input type='hidden' value='1' name='submitted' />";          # Set submitted var. to 1
    
    # Display Buttons (Create/Cancel) at the bottom of the form
    echo "\n\n<div class='two_buttons'>";

    echo "\n<div class='first_button'><button type='submit'> Create </button></div>\n";
    echo "\n<div class='second_button'><a href='" . $URL_MAIN . "'>";
    echo "\n     <button type='button'> Cancel </button></a>\n</div>";

    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";
    
    echo "\n</form>";                                                     
    echo "\n<br>";                                                      # Blank Line After Button
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
