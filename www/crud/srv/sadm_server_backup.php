<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_backup.php
#   Version     :  1.8
#   Date        :  7 Jan 2019
#   Requires    :  php - MySQL
#   Description :  Web Page used to edit a server backup schedule.
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
#@2019_01_01 V1.1  Added: Each server backup schedule, can now be changed using the web interface.
#@2019_01_12 V1.2  Feature: Client Backup List and Exclude list can be modified with Web Interface.
#
# ==================================================================================================
#
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
?>
<style media="screen" type="text/css">
.backup_page {
    font-family     :   Verdana, Geneva, sans-serif;
    font-size       :   0.9em;
    width           :   98%;
    /* height          :   800px; */
    text-align      :   left;
    color           :   black;
    background-color:   #fff5c3;
    /* margin-left     :   15px;
    margin-right    :   auto; */
    border          :   2px solid #000000;
    border-width    :   1px;
    border-style    :   solid;
    border-color    :   #000000;
    border-radius   :   10px;
    line-height     :   1.7;    
}
.backup_left_side   { width : 47%;  float : left;   margin : 10px 0px 10px 10px;    }
.backup_right_side  { width : 47%;  float : right;  margin : 5px 30px 10px 0px;     }

/* Attribute for Column Name at the left of the form */
.left_label {
    float           :   left;
    width           :   45%;
    /* background-color:   Yellow;  */
    font-weight     :   bold;    

}
/* Attribute for Column Name at the right of the form */
.right_label {
    float           :   left;
    width           :   85%;
    /* background-color:   green;  */
    font-weight     :   bold;    

}
/* Attribute for column Input at the right of the screen in the form */
.left_input {
    margin-bottom   :   4px;
    margin-left     :   40%;
    background-color:    #D3E397;
    width           :   60%;
    border-width    :   1px;
    border-style    :   solid;
    border-color    :   #000000;
}
/* Attribute for column Input at the right of the screen in the form */
.right_input {
    float           :   left;
    margin-bottom   :   4px;
    margin-right    :   14px;
    /* margin-left     :   40%; */
    padding-left    :   5px;
    padding-right    :   5px;
    padding-top    :   5px;
    background-color:    #D3E397;
    /* width           :   60%; */
    border-width    :   1px;
    border-style    :   solid;
    border-color    :   #000000;
}
.deux_boutons   { width : 96%;  margin-top  : 10px;     } 
.premier_bouton { width : 19%;  float : left;   margin-left : 30%;  text-align : right ; }
.second_bouton  { width : 19%;  float : right;  margin-right: 30%;  text-align : left  ; }
</style>

<?php
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    #</Head><body>Heading/SideBar
require_once ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "1.2" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_menu.php?sel=';                    # Maintenance Menu Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button


function Read_BackupList($wrow) {
    $SADM_BACKUP_CFG_DIR  = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] . "/cfg";
    $SADM_BACKUP_LIST     = $SADM_BACKUP_CFG_DIR . "/backup_list.txt";  # Actual Backup List Name
    $SADM_BACKUP_LIST_TMP = $SADM_BACKUP_CFG_DIR . "/backup_list.tmp";  # Modified Backup List Name
    if (! is_dir($SADM_BACKUP_CFG_DIR)) {                               # www/dat/SERVER/cfg ! exist
        mkdir($SADM_BACKUP_CFG_DIR, 0777, true);                        # Create the cfg directory
    }
    if (! file_exists($SADM_BACKUP_LIST)) {                             # If Backup List don't exist
        if (! copy(SADM_BACKUP_LIST_INIT,$SADM_BACKUP_LIST)) {          # Use the template then
            echo "Error copying " . SADM_BACKUP_LIST_INIT . " to " . $SADM_BACKUP_LIST ;
        }
    }
    if (file_exists($SADM_BACKUP_LIST_TMP)) {                           # If Modified version exist
        echo file_get_contents($SADM_BACKUP_LIST_TMP);                  # Display Modified Version
    }else{                                                              # If No Modified version
        echo file_get_contents($SADM_BACKUP_LIST);                      # Display Actual Backup List
    }
    #chmod($SADM_BACKUP_LIST ,0666);                                 
    #echo "BACKUPLIST = $SADM_BACKUP_LIST";
    #$fp = fopen($SADM_BACKUP_LIST, "r");
    #while(!feof($fp)) {
    #    $data = fgets($fp, filesize($SADM_BACKUP_LIST));
    #    echo "$data";
    #}
    #fclose($fp);
}

function Read_BackupExclude($wrow) {
    $SADM_BACKUP_CFG_DIR  = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] . "/cfg";
    $SADM_BACKUP_EXCLUDE     = $SADM_BACKUP_CFG_DIR . "/backup_exclude.txt"; # Actual Backup List 
    $SADM_BACKUP_EXCLUDE_TMP = $SADM_BACKUP_CFG_DIR . "/backup_exclude.tmp"; # Template Backup List
    if (! is_dir($SADM_BACKUP_CFG_DIR)) {                               # www/dat/SERVER/cfg ! exist
        mkdir($SADM_BACKUP_CFG_DIR, 0777, true);                        # Create the cfg directory
    }
    if (! file_exists($SADM_BACKUP_EXCLUDE)) {
        if (! copy(SADM_BACKUP_EXCLUDE_INIT,$SADM_BACKUP_EXCLUDE)) {  
            echo "Error copying " . SADM_BACKUP_EXCLUDE_INIT . " to " . $SADM_BACKUP_EXCLUDE ;
        }
    }
    if (file_exists($SADM_BACKUP_EXCLUDE_TMP)) {                        # If Modified version exist
        echo file_get_contents($SADM_BACKUP_EXCLUDE_TMP);               # Display Modified Version
    }else{                                                              # If No Modified version
        echo file_get_contents($SADM_BACKUP_EXCLUDE);                   # Display Actual Backup List
    }
    #$fileHash = sha1_file($_FILES["filename"]["tmp_name"]);
    #echo sha1($str);
    #chmod($SADM_BACKUP_EXCLUDE ,0666);                                 
    #echo file_get_contents( $SADM_BACKUP_EXCLUDE);
    #$fp = fopen($SADM_BACKUP_EXCLUDE, "r");
    #while(!feof($fp)) {
    #    $data = fgets($fp, filesize($SADM_BACKUP_EXCLUDE));
    #    echo "$data";
    #}
    #fclose($fp);
}
function Write_BackupList($server_name) {
    $SADM_BACKUP_LIST = SADM_WWW_DAT_DIR . "/" . $server_name . "/cfg/backup_list.tmp";
    $fp = fopen($SADM_BACKUP_LIST, "w");
    $data = $_POST["backuplist"];
    fwrite($fp, $data);
    fclose($fp);
}
function Write_BackupExclude($server_name) {
    $SADM_BACKUP_EXCLUDE = SADM_WWW_DAT_DIR . "/" . $server_name . "/cfg/backup_exclude.tmp";
    $fp = fopen($SADM_BACKUP_EXCLUDE, "w");
    $data = $_POST["backupexclude"];
    fwrite($fp, $data);
    fclose($fp);
}


// ================================================================================================
//                      DISPLAY SERVER SCHEDULE FOR OS UPDATE MODIFICATION 
// con   = Connector Object to Database 
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_backup_schedule($con,$wrow,$mode) {

    # Server Backup Schedule Page Info Div
    echo "\n\n<div class='backup_page'>\n                   <!-- Start backup_page Div -->";

    # BACKUP LEFT SIDE DIV
    echo "\n\n<div class='backup_left_side'>                <!-- Start backup_left_side Div -->";
    display_left_side ($con,$wrow,$mode);
    echo "\n\n</div>                                        <!-- End of backup_left_side Div -->";

    # BACKUP RIGHT SIDE DIV
    echo "\n\n<div class='backup_right_side'>               <!-- Start backup_right_side Div -->";
    display_right_side ($con,$wrow,$mode);
    echo "\n\n</div>                                        <!-- End of backup_right_side Div -->";

    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    echo "\n</div>                                          <!-- End of backup_page Div -->";
}


// ================================================================================================
//                      DISPLAY SERVER SCHEDULE FOR OS UPDATE MODIFICATION 
// con   = Connector Object to Database 
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_left_side($con,$wrow,$mode) {
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase
    
    # WANT TO SCHEDULE A BACKUP REGULARLY (Yes/No) ?
    echo "\n\n<div class='left_label'>Schedule a Backup</div>";
    echo "\n<div class='left_input'>";
    if ($mode == 'C') { $wrow['srv_backup'] = False ; }             # Default Regularly
    switch ($mode) {
        case 'D' : if ($wrow['srv_backup'] == True) {
                        echo "\n<input type='radio' name='scr_backup' value='1' ";
                        echo "onclick='javascript: return false;' checked> Yes  ";
                        echo "\n<input type='radio' name='scr_backup' value='0' ";
                        echo "onclick='javascript: return false;'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_backup' value='1' ";
                        echo "onclick='javascript: return false;'> Yes  ";
                        echo "\n<input type='radio' name='scr_backup' value='0' ";
                        echo "onclick='javascript: return false;' checked > No ";
                    }
                    break;
        default   : if ($wrow['srv_backup'] == True) {
                        echo "\n<input type='radio' name='scr_backup' value='1' checked > Yes ";
                        echo "\n<input type='radio' name='scr_backup' value='0'> No  ";
                    }else{
                        echo "\n<input type='radio' name='scr_backup' value='1'> Yes  ";
                        echo "\n<input type='radio' name='scr_backup' value='0' checked > <b>No</b>";
                    }
                    break;
    }
    echo "\n</div>";
    #echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    # Specify what month the Backup need to run - Default is All months
    # srv_backup_month = 13 Char Array - Contain 'Y' if month is chosen for Backup and 'N' if not.
    # If 1st Char is "Y" then this means that backup can run in any of the 12 months.
    # If 1st Char is "N" then each of the following 12 months specify the month backup can run (Y).
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Month(s) to run the Backup</div>";
    $mth_name = array('Any Months','January','February','March','April','May','June','July','August',
                'September','October','November','December');
    echo "\n<div class='left_input'>";
    echo "<select name='scr_backup_month[]' multiple='multiple' size=6>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 13; $i = $i + 1) {
                        echo "\n<option value='$i' ";
                        if ($i ==0) { echo "selected" ; }
                        echo "/>" . $mth_name[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 13; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_backup_month'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $mth_name[$i] . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    #echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # Date Number in the month (dom) to run the Backup 
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Date to run the Backup</div>";
    echo "\n<div class='left_input'>";
    echo "\n<select name='scr_backup_dom[]' multiple='multiple' size=5>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i' selected/>" . sprintf("%02d",$i) . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_backup_dom'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i);
                        if ($i == 0) { echo " To run on any date of the month" ;}
                        if ($i == 1) { echo " To run on 1st of the month" ;}
                        if ($i == 2) { echo " To run on 2nd of the month" ;}
                        if ($i == 3) { echo " To run on 3rd of the month" ;}
                        if ($i >= 4) { echo " To run on " . $i . "th of the month" ;}
                        echo "</option>";
                    }     
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    #echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # Day in the week (dow) to run the Backup
    # srv_backup_dow = 8 Char Array - Contain 'Y' if the day is chosen for Backup and 'N' if not.
    # If 1st Char is "Y" then this means that backup will run every day in the week.
    # If 1st Char is "N" then each of the following 7 days specify the day the backup run (Y).
    # 2nd to 8th Char. represent a day in the week.
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Day of week to run Backup</div>";
    echo "\n<div class='left_input'>";
    $days = array('All','Sun','Mon','Tue','Wed','Thu','Fri','Sat');

    echo "\n<select name='scr_backup_dow[]' multiple='multiple' size=8>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 8; $i = $i + 1) {
                        echo "\n<option value='$i' ";
                        if ($i == 7) { echo " selected"; }
                        echo "/>" . $days[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 8; $i = $i + 1) {
                        echo "\n<option value='$i' " ;
                        if (substr($wrow['srv_backup_dow'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $days[$i];
                        if ($i == 0) { echo "  (To run any day of the week)" ;} 
                        echo "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    #echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # ----------------------------------------------------------------------------------------------
    # Hour to Run the Backup
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Time to run the Backup</div>";
    echo "\n<div class='left_input'>";
    echo " Hour ";
    echo "\n<select name='scr_backup_hour' size=1>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 24; $i = $i + 1) {
                        if ($i == 1) { 
                           echo "\n<option value='$i' selected>" . sprintf("%02d",$i) . "</option>";
                        }else{
                           echo "\n<option value='$i'>" . sprintf("%02d",$i) . "</option>";
                        }
                    }
                    break ;
        default  :  for ($i = 0; $i < 24; $i = $i + 1) {
                        echo "\n<option value='$i' " ;
                        if ($wrow['srv_backup_hour'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
    }
    echo "\n</select>";


    # ----------------------------------------------------------------------------------------------
    # Minute to run the backup
    # ----------------------------------------------------------------------------------------------
    echo " Min ";
    echo "\n<select name='scr_backup_minute' size=1>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 60; $i = $i + 1) {
                        if ($i == 5) { 
                            echo "\n<option value='$i' selected>" . sprintf("%02d",$i) ."</option>";
                        }else{
                            echo "\n<option value='$i'>" . sprintf("%02d",$i) . "</option>";
                        }
                    }
                    break ;
        default  :  for ($i = 0; $i < 60; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if ($wrow['srv_backup_minute'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
}



// ================================================================================================
//                      DISPLAY SERVER SCHEDULE FOR OS UPDATE MODIFICATION 
// con   = Connector Object to Database 
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_right_side($con,$wrow,$mode) {
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase


    # Files and Directories to Backup

    echo "\n\n<div class='right_label'>Backup List (Files & Dir. to Backup)</div>";
    echo "\n<div class='right_input'>";
    echo "  <textarea rows='12' cols='50' name='backuplist' form='backup'>";
    Read_BackupList($wrow);
    echo "</textarea>";
    echo "\n</div>";


    # Files and Directories to Exclude from Backup
    echo "\n\n<div class='right_label'>Backup Exclude List (Excluded Files & Dir.)</div>";
    echo "\n<div class='right_input'>";
    echo "  <textarea rows='12' cols='50' name='backupexclude' form='backup'>";
    Read_BackupExclude($wrow);
    echo "</textarea>";
    echo "\n</div>";

}



#===================================================================================================
# SECOND EXECUTION OF PAGE AFTER THE UPDATE BUTTON IS PRESS
#===================================================================================================
    # Form is submitted - Process the Backup of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Submitted for " . $_POST['scr_name'];}  # Debug Info Start Submit
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }    # Fill in Post Array 

        # Construct SQL to Update row
        $sql = "UPDATE server SET ";

        # Run The Schedule Backup (1=Yes 0=No) 
        $sql = $sql . "srv_backup = '"   . sadm_clean_data($_POST['scr_backup'])   ."', ";

        # Month that Backup may run ----------------------------------------------------------------
        # Store as a string of 13 characters, Each Char. can be "Y" (Selected) or 'N' (Not Selected)
        $wmonth=$_POST['scr_backup_month'];                             # Save Chosen Month Array
        if (empty($wmonth)) { $wmonth = "YNNNNNNNNNNNN"; }              # If Array Empty,set default
        $wstr=str_repeat('N',13);                                       # Default "N" in all 13 Char
        if (in_array('0',$wmonth)) {                                    # If Choose Every Months
            $wstr= "YNNNNNNNNNNNN";                                     # Set String Accordingly
        }else{                                                          # If Choose Specific Months
            foreach ($wmonth as $p) {                                   # Foreach Month Nb. Selected
                $wstr=substr_replace($wstr,'Y',intval($p),1);           # Replace N to Y for Sel Mth
            }                                                           # End of ForEach
        }                                                               # End of If
        $pmonth = trim($wstr);                                          # Remove Begin/End Space
        $sql = $sql . "srv_backup_month = '"  . $pmonth  ."', ";        # Insert in SQL Statement


        # Date in the month that the Backup can Run. -----------------------------------------------
        $wdom=$_POST['scr_backup_dom'];                                 # Save Choosen Date Array
        if (empty($wdom)) { $wdom="YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN";}  # If Empty Array Set Default
        $wstr=str_repeat('N',32);                                       # Default all 32 Char.
        if (in_array('0',$wdom)) {                                      # If Choose Every Date
            $wstr="YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN";                   # Set String Accordingly
        }else{                                                          # If Choose Specific Date
            foreach ($wdom as $p) {                                     # For Each Date Selected
                $wstr=substr_replace($wstr,'Y',intval($p),1);           # Replace N by Y for Sel.Mth
            }                                                           # End of ForEach
        }                                                               # End of If
        $pdom = trim($wstr) ;                                           # Save for crontab
        $sql = $sql . "srv_backup_dom = '"    . $wstr  ."', ";          # Insert in SQL Statement


        # Day of the Week we want to run the Backup (0=All Day 1=Sun 2=Mon)-------------------------
        $wdow=$_POST['scr_backup_dow'];                                 # Save Chosen Day Choose
        if (empty($wdow)) { for ($i = 0; $i < 8; $i = $i + 1) { $wdow[$i] = $i; } }
        $wstr=str_repeat('N',8);                                        # Default All Week to No
        if (in_array('0',$wdow)) {                                      # If Choose Every DayOfWeek
            $wstr="YNNNNNNN" ;                                          # Set String Accordingly
        }else{                                                          # If Choose specific Days
            foreach ($wdow as $p) {                                     # For Each Day Selected
                $wstr=substr_replace($wstr,'Y',intval($p),1);           # Replace N By Y for Sel.Day
            }                                                           # End of ForEach
        }                                                               # End of If
        $pdow = trim($wstr) ;                                           # Remove Begin/End Space
        $sql = $sql . "srv_backup_dow = '"  . $wstr  ."', ";            # Insert in SQL Statement


        # Hour, Minute to perform the Backup -------------------------------------------------------
        $sql = $sql . "srv_backup_hour   = '" . sadm_clean_data($_POST['scr_backup_hour'])   ."', ";
        $sql = $sql . "srv_backup_minute = '" . sadm_clean_data($_POST['scr_backup_minute']) ."', ";

        # Update Server Last Edit Date -------------------------------------------------------------
        $sql = $sql . "srv_date_edit     = '" . date("Y-m-d H:i:s")                          ."'  ";

        $sql = $sql . "WHERE srv_name     = '" . $_POST['server_key'] ."'; ";
        if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }
        
        # Execute the Row Update SQL ---------------------------------------------------------------
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute Update Row SQL
            $err_line = (__LINE__ -1) ;                                 # Error on preceding line
            $err_msg1 = "Row wasn't updated\nError (";                  # Advise User Message 
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
        }else{                                                          # Update done with success
            $err_msg = "Server '" . $_POST['scr_name'] . "' updated";   # Advise user of success Msg
            if ($DEBUG) { 
                $err_msg = $err_msg ."\nUpdate SQL Command = ". $sql ;  # Include SQL Stat. in Mess.
                sadm_alert ($err_msg) ;                                 # Msg. Error Box for User
            }
        }

        # Write Back the Backup List and Backup Exclude file.
        Write_BackupList($_POST['server_key']);                         # Write Back Backup List
        Write_BackupExclude($_POST['server_key']);                      # Write Back Exclude List

        # Back to Server List Page
        ?> <script> location.replace("/crud/srv/sadm_server_main.php"); </script><?php
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
        exit ; 
    }


    # START OF FORM - DISPLAY FORM READY TO UPDATE DATA
    display_std_heading("NotHome","Backup Schedule","","",$SVER);   # Display Content Heading
    $title="Backup Schedule for server '" . $row['srv_name'] . "." . $row['srv_domain'] . "'";
    echo "<strong><h2><center>" . $title . "</center></h2></strong>";

    echo "\n\n<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' id='backup' method='POST'>"; 
    display_backup_schedule($con,$row,"Update");                             # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "\n<input type='hidden' value='1' name='submitted' />";        # hidden use On Nxt Page Exe
    echo "\n<input type='hidden' value='".$row['srv_name']  ."' name='server_key' />"; # save srvkey
    echo "\n<input type='hidden' value='".$row['srv_ostype']."' name='server_os'  />"; # save O/S
    
    # Display Buttons (Update/Cancel) at the bottom of the form
    echo "\n\n<div class='deux_boutons'>";
    echo "\n<div class='premier_bouton'><button type='submit'> Update </button></div>";
    echo "\n<div class='second_bouton'><a href='" . $URL_MAIN . $row['srv_name'] . "'><button type='button'> Cancel ";
    echo "</button></a>\n</div>";
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";
    
    echo "\n</form>";                                                   # End of Form  
    echo "\n<br>";                                                      # Blank Line After Button
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
