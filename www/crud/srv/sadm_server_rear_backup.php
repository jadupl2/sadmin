<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_server_backup.php
#   Version     :  1.0
#   Date        :  18 August 2019
#   Requires    :  php - MySQL
#   Description :  Web Page used to edit a server rear schedule.
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
#   If not, see <http://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
# 2019_08_18 New: v1.0 Initial Beta version - Allow to define ReaR Backup schedule.
# 2019_08_19 Update: v1.1 Initial working version.
# 2020_01_13 Update: v1.2 Enhance Web Page Appearance and color. 
# 2020_04_16 Update: v1.3 Small page adjustments.
# 2021_04_19 Update: v1.4 Change "Exclude" to "Include/Exclude" Label on file config
# ==================================================================================================
#
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
?>
  <style media="screen" type="text/css">
.rear_page {
    background-color:   #006456;
    color           :   #f9f4be;   
    font-family     :   Verdana, Geneva, sans-serif;
    font-size       :   0.9em;
    width           :   90%;
    margin          :   0 auto;
    text-align      :   left;
    border          :   2px solid #000000;   border-width : 1px;     border-style : solid;   
    border-color    :   #000000;             border-radius: 10px;
    line-height     :   1.7;    
}
.rear_left_side   { float : left; width : 48%; margin : 10px 0px 10px 0px;    }
.left_label       { float : left; width : 40%; text-align: right; padding-right: 2%; font-weight : normal; }
.left_input       {               width : 80ß%; margin-bottom : 5px;  margin-left : 20%; padding-left: 0px;
                            border-width: 0px;  border-style : solid;  border-color : #000000;
                      
}

.rear_right_side  { width : 51%;  float : right;  margin-left : 5px ;     }
.right_label        { float : left; width : 82%;    font-weight : normal; }
.right_input        { margin-bottom : 4px;  margin-right : 10px;    
                      float : left;  width : 72% ; padding-left : 5px;  padding-right : 15px;  padding-top : 5px;
                      border-width: 0px;  border-style : solid;  border-color : #000000;
}                      
.rear_policy {
    background-color:   #006456;
    color           :   #fbfbfb;   
    font-family     :   Verdana, Geneva, sans-serif;
    width           :   90%;
    padding-left    :   10px;
    padding-top     :   10px;
    margin          :   0 auto;
    text-align      :   left;
    border          :   2px solid #000000;   border-width : 1px;     border-style : solid;   
    border-color    :   #000000;             border-radius: 10px;
    line-height     :   1.7;    
}
.rear_retension {
    background-color:   #006456;
    color           :   #fbfbfb;   
    font-family     :   Verdana, Geneva, sans-serif;
    width           :   98%;
    margin          :   0 auto;
    text-align      :   left;
    /* border          :   2px solid #000000;   border-width : 1px;     border-style : solid;   
    border-color    :   #000000;             border-radius: 10px; */
    line-height     :   1.7;    
}
.deux_boutons   { width : 70%;   margin: 1% auto;   } 
.premier_bouton { width : 20%;  float : left;   margin-left : 25%;  text-align : right ; }
.second_bouton  { width : 20%;  float : right;  margin-right: 25%;  text-align : left  ; }
</style>

<?php
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    #</Head><body>Heading/SideBar
require_once ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "1.4" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_menu.php?sel=';                    # Maintenance Menu Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button
$BEHASH = "" ;                                                          # Sha1 of Loaded Backup Excl





#===================================================================================================
# Load and Show Backup Exclude List in textarea on page
#===================================================================================================
#
function Read_RearExclude($wrow) {
    
    $SADM_BACKUP_CFG_DIR   = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] . "/cfg";
    $SADM_REAR_EXCLUDE     = $SADM_BACKUP_CFG_DIR . "/rear_exclude.txt"; # Actual Rear Exclude List
    $SADM_REAR_EXCLUDE_TMP = $SADM_BACKUP_CFG_DIR . "/rear_exclude.tmp"; # Temp Rear Exclude List
    
    # Make Sure the SADMIN cfg directory exist.
    if (! is_dir($SADM_BACKUP_CFG_DIR)) { mkdir($SADM_BACKUP_CFG_DIR, 0777, true); }
    
    # If the ReaR Exclude list doesn't exist, create one by using the ReaR exclude list template.
    if (! file_exists($SADM_REAR_EXCLUDE)) {
        if (! copy(SADM_REAR_EXCLUDE_INIT,$SADM_REAR_EXCLUDE)) {
            echo "Error copying " . SADM_REAR_EXCLUDE_INIT . " to " . $SADM_REAR_EXCLUDE ;
        }
    }
    
    # If modified version already exist (rear_exclude.tmp) then show it & Calculate File sha1sum
    if (file_exists($SADM_REAR_EXCLUDE_TMP)) {                          # If Modified version exist
        echo file_get_contents($SADM_REAR_EXCLUDE_TMP);                 # Display Modified Version
        $fileHash = sha1_file($SADM_REAR_EXCLUDE_TMP);                  # Calc. Sha1 check Sum
    }else{                                                              # If No Modified version
        echo file_get_contents($SADM_REAR_EXCLUDE);                     # Display Actual Backup List
        $fileHash = sha1_file($SADM_REAR_EXCLUDE);                      # Calc. Sha1 check Sum
    }
    return $fileHash;                                                   # Return sha1 of loaded file
}




#===================================================================================================
# Loaded file Hash Versus now - Write modified version in backup_exclude.tmp or delete it if untouch
#===================================================================================================
function Write_RearExclude($server_name, $oldFileHash) {
    
    $SADM_REAR_EXCLUDE = SADM_WWW_DAT_DIR . "/" . $server_name . "/cfg/rear_exclude.tmp";
    $newFileHash = sha1($_POST["rearexclude"]);                         # Calc. Edited File Hash

    # Check new sha1 versus old one, if changed create the rear exclude list, if not remove file.
    if ($newFileHash != $oldFileHash) {                                 # Sha1 Before & After Diff.
        $fp = fopen($SADM_REAR_EXCLUDE, "w");                           # Create backup_exclude.tmp
        $data = $_POST["rearexclude"];                                  # Put TextArea in data
        fwrite($fp, $data);                                             # Write data to disk
        fclose($fp);                                                    # Close backup_exclude.tmp
    }else{
        if (file_exists($SADM_REAR_EXCLUDE)) {                          # If Modified version exist
            unlink($SADM_REAR_EXCLUDE);                                 # Not Modified = Delete it
        }
    }
}


// ================================================================================================
//                          Display Server ReaR Backup Schedule
// con   = Connector Object to Database
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_rear_schedule($con,$wrow,$mode) {
    global $BEHASH ;
     
    # Server ReaR Schedule Page Info Div
    echo "\n\n<div class='rear_page'>\n                     <!-- Start rear_page Div -->";
    
    # REAR BACKUP LEFT SIDE DIV
    echo "\n\n<div class='rear_left_side'>                  <!-- Start rear_left_side Div -->";
    display_left_side ($con,$wrow,$mode);
    echo "\n\n</div>                                        <!-- End of rear_left_side Div -->";
    
    # REAR BACKUP RIGHT SIDE DIV
    echo "\n\n<div class='rear_right_side'>                 <!-- Start rear_right_side Div -->";
    display_right_side ($con,$wrow,$mode);
    echo "\n\n</div>                                        <!-- End of rear_right_side Div -->";
    
    echo "\n<div style='clear: both;'> </div>\n";                       
    echo "\n</div>                                          <!-- End of rear_page Div -->";
    echo "\n<br>";
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
    $smode = strtoupper($mode);                                         # Change Mode to Uppercase
    
    # WANT TO SCHEDULE A REAR BACKUP REGULARLY (Yes/No) ?
    echo "\n\n<div class='left_label'>Activate ReaR Backup</div>";
    echo "\n<div class='left_input'>";
    if ($mode == 'C') { $wrow['srv_img_backup'] = False ; }                 # Default 
    switch ($mode) {
        case 'D' : if ($wrow['srv_img_backup'] == True) {
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
        default   : if ($wrow['srv_img_backup'] == True) {
                        echo "\n<input type='radio' name='scr_backup' value='1' checked > Yes ";
                        echo "\n<input type='radio' name='scr_backup' value='0'> No  ";
                    }else{
                    echo "\n<input type='radio' name='scr_backup' value='1'> Yes  ";
                    echo "\n<input type='radio' name='scr_backup' value='0' checked > <b>No</b>";
                    }
                    break;
    }
    echo "\n</div>";

    # Specify what month the Backup need to run - Default is All months
    # srv_img_month = 13 Char Array - Contain 'Y' if month is chosen for Backup and 'N' if not.
    # If 1st Char is "Y" then this means that backup can run in any of the 12 months.
    # If 1st Char is "N" then each of the following 12 months specify the month backup can run (Y).
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Month to run Backup</div>";
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
                        if (substr($wrow['srv_img_month'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $mth_name[$i] . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";


    # Date Number in the month (dom) to run the Backup
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Date of Backup</div>";
    echo "\n<div class='left_input'>";
    echo "\n<select name='scr_backup_dom[]' multiple='multiple' size=5>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i' selected/>" . sprintf("%02d",$i) . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_img_dom'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">";
                        if ($i == 0) { echo " Any date of the month" ;}
                        if ($i == 1) { echo " Run on 1st of the month" ;}
                        if ($i == 2) { echo " Run on 2nd of the month" ;}
                        if ($i == 3) { echo " Run on 3rd of the month" ;}
                        if ($i >= 4) { echo " Run on " . $i . "th of the month" ;}
                        echo "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";


    # Day in the week (dow) to run the Backup
    # srv_img_dow = 8 Char Array - Contain 'Y' if the day is chosen for Backup and 'N' if not.
    # If 1st Char is "Y" then this means that backup will run every day in the week.
    # If 1st Char is "N" then each of the following 7 days specify the day the backup run (Y).
    # 2nd to 8th Char. represent a day in the week.
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Day to run Backup</div>";
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
                        if (substr($wrow['srv_img_dow'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $days[$i];
                        if ($i == 0) { echo "  (Every day of the week)" ;}
                        echo "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Hour to Run the Backup
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='left_label'>Time of Backup</div>";
    echo "\n<div class='left_input'>";
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
                        if ($wrow['srv_img_hour'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo " Hrs ";


    # ----------------------------------------------------------------------------------------------
    # Minute to run the backup
    # ----------------------------------------------------------------------------------------------
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
                        if ($wrow['srv_img_minute'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
        }
    echo "\n</select>";
    echo " Min ";
    echo "\n</div>";
}





// ================================================================================================
// SHOW REAR BACKUP POLICIES AS DEFINED IN $SADMIN/cfg/sadmin.cfg 
// ================================================================================================
function show_rear_policy() {

    echo "\n\n<div class='rear_policy'>\n                       <!-- Start rear_policy Div -->";
    echo "<strong>   ReaR backup policies for all systems (as defined in '\$SADMIN/cfg/sadmin.cfg')</strong>";
    
    # Backup destination
    echo "\n<div class='rear_retension'>\n                    <!-- Start rear_retension Div -->";
    echo "NFS backup server is '" . SADM_REAR_NFS_SERVER ;
    echo "' and destination directory is '". SADM_REAR_NFS_MOUNT_POINT ."'";

    # ReaR Backup policy
    echo "\n<br>&nbsp;&nbsp;&nbsp;  - ";
    echo "Rear backup will always keep a copy of the last " .SADM_REAR_BACKUP_TO_KEEP. " backup.";
    
    # Script used to run the Rear backup
    echo "\n<br>&nbsp;&nbsp;&nbsp;  - ";
    echo "To create a Rear backup, the script " . SADM_BIN_DIR . "/sadm_rear_backup.sh will be run.";
    echo "\n</div>                                          <!-- End of rear_retension Div -->";

    # End Of Backup Policy
    echo "\n<br></div>                                          <!-- End of rear_policy Div -->";
} 



// ================================================================================================
//                      DISPLAY REAR SERVER SCHEDULE MODIFICATION
// con   = Connector Object to Database
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_right_side($con,$wrow,$mode) {
    global $BEHASH ;
    
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase
    
    # Files and Directories to Exclude from Backup
    echo "\n\n<div class='right_label'>ReaR variables use to include/exclude data from backup</div>";
    echo "\n<div class='right_input'>";
    echo "  <textarea rows='24' cols='60' name='rearexclude' form='backup'>";
    $BEHASH = Read_RearExclude($wrow);
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
    $sql = $sql . "srv_img_backup = '"   . sadm_clean_data($_POST['scr_backup'])   ."', ";
    
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
    $sql = $sql . "srv_img_month = '"  . $pmonth  ."', ";        # Insert in SQL Statement
    
    
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
        $sql = $sql . "srv_img_dom = '"    . $wstr  ."', ";          # Insert in SQL Statement
    
    
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
    $sql = $sql . "srv_img_dow = '"  . $wstr  ."', ";            # Insert in SQL Statement
    
    
    # Hour, Minute to perform the Backup -------------------------------------------------------
    $sql = $sql . "srv_img_hour   = '" . sadm_clean_data($_POST['scr_backup_hour'])   ."', ";
    $sql = $sql . "srv_img_minute = '" . sadm_clean_data($_POST['scr_backup_minute']) ."', ";
    
    # Update Server Last Edit Date -------------------------------------------------------------
    $sql = $sql . "srv_date_edit     = '" . date("Y-m-d H:i:s")                          ."'  ";
    
    $sql = $sql . "WHERE srv_name     = '" . $_POST['server_key'] ."'; ";
    if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }
    
    # Execute the Row Update SQL ---------------------------------------------------------------
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute Update Row SQL
        $err_line = (__LINE__ -1) ;                                     # Error on preceding line
        $err_msg1 = "Row wasn't updated\nError (";                      # Advise User Message
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        }else{                                                          # Update done with success
            $err_msg = "Server '" .$_POST['scr_name']. "' updated";     # Advise user of success Msg
            if ($DEBUG) {
                $err_msg = $err_msg ."\nUpdate SQL Command = ". $sql ;  # Include SQL Stat. in Mess.
                sadm_alert ($err_msg) ;                                 # Msg. Error Box for User
                }
        }
        
        # Write Back the Backup List and Backup Exclude file.
        Write_RearExclude($_POST['server_key'],$_POST['behash']);       # Write Back Exclude List
        
        # Back to Calling Page
        echo "<script>location.replace('" .$_POST['BACKURL']. "');</script>"; 
        exit;
    }
    
    
    
    
    # ==================================================================================================
    #               INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
    # ==================================================================================================
    
    # 1st parameter contains the server name 
    if ($DEBUG) { echo "<br>1st Parameter Received is " . $SELECTION; } # Under Debug Display Param.
    if ((isset($_GET['sel'])) and ($_GET['sel'] != ""))  {              # If Key Rcv and not Blank
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>Key received is '" . $wkey ."'"; }      # Under Debug Show Key Rcv.
    }else{                                                              # If No Key Rcv or Blank
        $err_msg = "No Key Received - Please Advise" ;                  # Construct Error Msg.
        sadm_alert ($err_msg) ;                                         # Display Error Msg. Box
        exit ;
    }

    # 2nd parameters reference the URL where this page was called.
    if ($DEBUG) { echo "<br>2nd Parameter Received is " . $back; }      # Under Debug Show 2nd Parm.
    if ((isset($_GET['back'])) and ($_GET['back'] != ""))  {            # If Value Rcv and not Blank
       $BACKURL = $_GET['back'] ."?sel=" . $wkey ;                      # Save 2nd Parameter Value
    }else{
       $BACKURL = $URL_MAIN . $wkey;                                    # Where to go back after 
    }

    # CHECK IF THE SERVER KEY RECEIVED EXIST IN THE DATABASE AND RETRIEVE THE ROW DATA
    $sql = "SELECT * FROM server WHERE srv_name = '" . $wkey . "'";
    if ($DEBUG) { echo "<br>SQL = $sql"; }                              # In Debug Display SQL Stat.
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceeding line
        $err_msg1 = "Server (" . $wkey . ") not found.\n";              # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        echo "<script>location.replace('" . $BACKURL . "');</script>";  # Backup to Caller URL
        exit;                                                           # Exit - Should not occurs
    }else{                                                              # If row was found
        $row = mysqli_fetch_assoc($result);                             # Read the Associated row
    }
    
    # DISPLAY SCREEN HEADING    
    $title1="ReaR backup schedule of '" . $row['srv_name'] . "." . $row['srv_domain'] . "'";
    if ($row['srv_img_backup'] == True) {
        list ($title2, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_img_dom'], 
            $row['srv_img_month'],$row['srv_img_dow'], 
            $row['srv_img_hour'], $row['srv_img_minute']);
    }else{
        $title2="ReaR backup isn't activated";
    }
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading
    
    # START OF FORM - DISPLAY FORM READY TO UPDATE DATA
    echo "\n\n<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' id='backup' method='POST'>";
    display_rear_schedule($con,$row,"Update");                        # Display Form Default Value
        
    # Set the Submitted Flag On - We are done with the Form Data
    echo "\n<input type='hidden' value='1' name='submitted' />";        # hidden use On Nxt Page Exe
    echo "\n<input type='hidden' value='".$row['srv_name']  ."' name='server_key' />"; # save srvkey
    echo "\n<input type='hidden' value='".$row['srv_ostype']."' name='server_os'  />"; # save O/S
    echo "\n<input type='hidden' value='".$BACKURL."' name='BACKURL'  />"; # Save Caller URL
    echo "\n<input type='hidden' value='".$BEHASH."' name='behash' />"; # ---[B]ackup [E]xclude Hash
    
    # DISPLAY BUTTONS (UPDATE/CANCEL) AT THE BOTTOM OF THE FORM
    echo "\n\n<div class='deux_boutons'>";
    echo "\n<div class='premier_bouton'><button type='submit'> Update </button></div>";
    echo "\n<div class='second_bouton'><a href='" . $BACKURL . "'><button type='button'> Cancel ";
    echo "</button></a>\n</div>";
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";
    
    echo "\n</form>";                                                   # End of Form
    echo "\n<br>";                                                      # Blank Line After Button
    show_rear_policy();
    echo "\n<br>";                                                      # Blank Line After Button
    std_page_footer($con)                                               # Close MySQL & HTML Footer
    ?>