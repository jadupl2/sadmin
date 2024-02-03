<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_server_backup.php
#   Version     :  1.8
#   Date        :  7 Jan 2019
#   Requires    :  php - MySQL
#   Description :  Web Page used to edit a server backup schedule.
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2019_01_01 backup v1.1 Backup sched. page - Each server backup schedule, can be changed using web interface.
# 2019_01_12 backup v1.2 Backup sched. page - Client Backup List and Exclude list modified with Web Interface.
# 2019_01_18 backup v1.3 Backup sched. page - Hash of Backup List & Exclude list to check if were modified.
# 2019_01_22 backup v1.4 Backup sched. page - Add Dark Theme
# 2019_08_14 backup v1.5 Backup sched. page - Redesign page,show one line schedule,show backup policies.
# 2019_08_19 backup v1.6 Backup sched. page - Show 'Backup isn't activated' when no schedule define.
# 2019_12_01 backup v1.7 Backup sched. page - Backup will run daily (Del entry field for specify day of backup)
# 2019_12_02 backup v1.7 Backup sched. page - Run every day, so don't miss day/weekly/monthly and Yearly backup
# 2020_01_03 backup v1.8 Backup sched. page - Web Page disposition and input was changed.
# 2020_01_13 backup v1.9 Backup sched. page - Enhance Web Appearance and color. 
# 2020_01_18 backup v2.0 Backup sched. page - Reduce width of text-area for include/exclude list to fit on Ipad
# 2021_05_25 backup v2.1 Backup sched. page - Replace php depreciated function 'eregi_replace' warning message.
# 2022_09_28 backup v2.2 Backup sched. page - Add possibility to compress or not the backup via the web page.
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
    background-color:   #28866c;
    color           :   White;   
    font-family     :   Verdana, Geneva, sans-serif;
    font-size       :   0.9em;
    width           :   75%;
    margin          :   auto;
    text-align      :   left;
    border          :   2px solid #000000;   border-width : 1px;     border-style : solid;   
    border-color    :   #000000;             border-radius: 10px;
    line-height     :   1.7;    
}
.backup_rectangle   { width : 70%;  float : left;   margin : 10px 0px 10px 0px;    }
.left_label         { float : left; width : 38%;  padding-left : 2%; margin-left :5 px;  text-align: left; font-weight : normal; }
.left_input         { margin-bottom : 5px;  margin-left : 40%;  
                      width : 50%; border-width: 0px;  border-style : solid;  border-color : #000000;
                      padding-left: 6px;
}
.backup_policy {
    background-color:   #28866c;
    color           :   #F7FF00; 
    font-family     :   Verdana, Geneva, sans-serif;
    width           :   85%;
    margin          :   auto;
    padding-top     :   10px;
    padding-left    :   15px; 
    text-align      :   left;
    border          :   2px solid #000000;   border-width : 1px;     border-style : solid;   
    border-color    :   #000000;             border-radius: 10px;
    line-height     :   1.7;    
}
.backup_retension {
    background-color:   #28866c;
    color           :   #fbfbfb;   
    font-family     :   Verdana, Geneva, sans-serif;
    width           :   90%;
    padding-bottom  :   10px;
    /*margin          :   0 auto;*/
    margin left : 10px; 
    text-align      :   left;
    /* border          :   2px solid #000000;   border-width : 1px;     border-style : solid;   
    border-color    :   #000000;             border-radius: 10px; */
    line-height     :   1.5;    
}
.deux_boutons   { width : 100%;  margin: 0px 0px 0px 0px;  } 
.premier_bouton { width : 25%;  height : 25px ; float : left;   margin-left : 25%;  text-align : right ; }
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
$SVER  = "2.2" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_menu.php?sel=';                    # Maintenance Menu Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button
$BLHASH = "" ;                                                          # Sha1 of Loaded Backup List
$BEHASH = "" ;                                                          # Sha1 of Loaded Backup Excl



#===================================================================================================
# Load and Show Backup List
#===================================================================================================
#
function Read_BackupList($wrow) {
    $SADM_BACKUP_CFG_DIR  = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] . "/cfg";
    $SADM_BACKUP_LIST     = $SADM_BACKUP_CFG_DIR . "/backup_list.txt";  # Actual Backup List Name
    $SADM_BACKUP_LIST_TMP = $SADM_BACKUP_CFG_DIR . "/backup_list.tmp";  # Modified Backup List Name
    
    # Make Sure the SADMIN cfg directory exist.
    if (! is_dir($SADM_BACKUP_CFG_DIR)) { mkdir($SADM_BACKUP_CFG_DIR, 0777, true); }
    
    # If the Backup list doesn't exist - Create it by using the backup list template.
    if (! file_exists($SADM_BACKUP_LIST)) {                             # If Backup List don't exist
        if (! copy(SADM_BACKUP_LIST_INIT,$SADM_BACKUP_LIST)) {          # Create it using template
            echo "Error copying " . SADM_BACKUP_LIST_INIT . " to " . $SADM_BACKUP_LIST ;
            return 0;                                                   # Normally return file hash
        }
    }
    
    # If modified version already exist (backup_list.tmp) then use it.
    if (file_exists($SADM_BACKUP_LIST_TMP)) {                           # If Modified version exist
        echo file_get_contents($SADM_BACKUP_LIST_TMP);                  # Display Modified Version
        $fileHash = sha1_file($SADM_BACKUP_LIST_TMP);                   # Calc. Sha1 check Sum
    }else{                                                              # If No Modified version
        echo file_get_contents($SADM_BACKUP_LIST);                      # Display Actual Backup List
        $fileHash = sha1_file($SADM_BACKUP_LIST);                       # Calc. Sha1 check Sum
    }
    return $fileHash;                                                   # Return sha1 of loaded file
}



#===================================================================================================
# Load and Show Backup Exclude List in textarea on page
#===================================================================================================
#
function Read_BackupExclude($wrow) {
    
    $SADM_BACKUP_CFG_DIR  = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] . "/cfg";
    $SADM_BACKUP_EXCLUDE     = $SADM_BACKUP_CFG_DIR . "/backup_exclude.txt"; # Actual Backup List
    $SADM_BACKUP_EXCLUDE_TMP = $SADM_BACKUP_CFG_DIR . "/backup_exclude.tmp"; # Temp. Backup List
    
    # Make Sure the SADMIN cfg directory exist.
    if (! is_dir($SADM_BACKUP_CFG_DIR)) { mkdir($SADM_BACKUP_CFG_DIR, 0777, true); }
    
    # If the Backup list doesn't exist - Create it by using the backup list template.
    if (! file_exists($SADM_BACKUP_EXCLUDE)) {
        if (! copy(SADM_BACKUP_EXCLUDE_INIT,$SADM_BACKUP_EXCLUDE)) {
            echo "Error copying " . SADM_BACKUP_EXCLUDE_INIT . " to " . $SADM_BACKUP_EXCLUDE ;
        }
    }
    
    # If modified version already exist (backup_list.tmp) then use it.
    if (file_exists($SADM_BACKUP_EXCLUDE_TMP)) {                        # If Modified version exist
        echo file_get_contents($SADM_BACKUP_EXCLUDE_TMP);               # Display Modified Version
        $fileHash = sha1_file($SADM_BACKUP_EXCLUDE_TMP);                # Calc. Sha1 check Sum
    }else{                                                              # If No Modified version
        echo file_get_contents($SADM_BACKUP_EXCLUDE);                   # Display Actual Backup List
        $fileHash = sha1_file($SADM_BACKUP_EXCLUDE);                    # Calc. Sha1 check Sum
    }
    return $fileHash;                                                   # Return sha1 of loaded file
}



#===================================================================================================
# Loaded file Hash Versus now - Write modified version in backup_list.tmp or delete it if untouch.
#===================================================================================================
function Write_BackupList($server_name, $oldFileHash) {
    $SADM_BACKUP_LIST = SADM_WWW_DAT_DIR . "/" . $server_name . "/cfg/backup_list.tmp";
    $newFileHash = sha1($_POST["backuplist"]);                          # Calc. Edited File Hash
    if ($newFileHash != $oldFileHash) {                                 # Sha1 Before and After
        $fp = fopen($SADM_BACKUP_LIST, "w");                            # File Modified 
        #$data = $_POST["backuplist"];                                   # Put TextArea in data
        #$data = eregi_replace("\r","",$_POST["backuplist"]);
        $data = str_replace("\r", '', $_POST["backuplist"]);
        #$data = preg_replace("\r","",$data);
        fwrite($fp, $data);                                             # Write Data
        fclose($fp);                                                    # Close backup_list.tmp
    }else{
        if (file_exists($SADM_BACKUP_LIST)) {                           # If Modified version exist
            unlink($SADM_BACKUP_LIST);                                  # Not Modified then Delete it
        }
    }
}


#===================================================================================================
# Loaded file Hash Versus now - Write modified version in backup_exclude.tmp or delete it if untouch
#===================================================================================================
function Write_BackupExclude($server_name, $oldFileHash) {
    $SADM_BACKUP_EXCLUDE = SADM_WWW_DAT_DIR . "/" . $server_name . "/cfg/backup_exclude.tmp";
    $newFileHash = sha1($_POST["backupexclude"]);                       # Calc. Edited File Hash
    if ($newFileHash != $oldFileHash) {                                 # Sha1 Before and After
        $fp = fopen($SADM_BACKUP_EXCLUDE, "w");                         # Create backup_exclude.tmp
        #$data = $_POST["backupexclude"];                                # Put TextArea in data
        #$data = eregi_replace("\r","",$_POST["backupexclude"]);
        #$data = preg_replace("\r","",$_POST["backupexclude"]);
        $data = str_replace("\r", '', $_POST["backupexclude"]);
        fwrite($fp, $data);                                             # Write data to disk
        fclose($fp);                                                    # Close backup_exclude.tmp
    }else{
        if (file_exists($SADM_BACKUP_EXCLUDE)) {                        # If Modified version exist
            unlink($SADM_BACKUP_EXCLUDE);                               # Not Modified = Delete it
        }
    }
}


// ================================================================================================
//                      DISPLAY SERVER SCHEDULE FOR BACKUP
// con   = Connector Object to Database
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_backup_schedule($con,$wrow,$mode) {
    global $BLHASH, $BEHASH ;
    
    # Server Backup Schedule Page Info Div
    echo "\n\n<div class='backup_page'>\n                   <!-- Start backup_page Div -->";
    
    # BACKUP LEFT SIDE DIV
    echo "\n\n<div class='backup_rectangle'>                <!-- Start backup_rectangle Div -->";
    display_left_side ($con,$wrow,$mode);
    echo "\n\n</div>                                        <!-- End of backup_rectangle Div -->";
   
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    echo "\n</div>                                          <!-- End of backup_page Div -->";
    echo "\n<br>";
}



// ================================================================================================
//                      DISPLAY LEFT SIDE SERVER SCHEDULE FOR BACKUP
// con   = Connector Object to Database
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_left_side($con,$wrow,$mode) {
    global $BLHASH, $BEHASH ;
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase
    
    # Backup Activated or Not ? (Yes/No) (True/False)?
    echo "\n\n<div class='left_label'>Daily backup activated ?</div>";
    echo "\n<div class='left_input'>";
    if ($mode == 'C') { $wrow['srv_backup'] = False ; }             # Default 
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

    # The Hour when to run the Backup
    echo "\n\n<div class='left_label'>Daily backup time</div>";
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
                        if ($wrow['srv_backup_hour'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo " Hrs ";

    # The Minute to run the backup
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
    echo " Min ";
    echo "\n</div>";

    
    # Compress the Backup or Not.
    echo "\n\n<div class='left_label'>Compress backup</div>";
    echo "\n<div class='left_input'>";
    if ($mode == 'C') { $wrow['srv_backup_compress'] = False ; }             # Default 
    switch ($mode) {
        case 'D' : if ($wrow['srv_backup_compress'] == True) {
                        echo "\n<input type='radio' name='scr_backup_compress' value='1' ";
                        echo "onclick='javascript: return false;' checked> Yes  ";
                        echo "\n<input type='radio' name='scr_backup_compress' value='0' ";
                        echo "onclick='javascript: return false;'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_backup_compress' value='1' ";
                        echo "onclick='javascript: return false;'> Yes  ";
                        echo "\n<input type='radio' name='scr_backup_compress' value='0' ";
                        echo "onclick='javascript: return false;' checked > No ";
                    }
                    break;
        default   : if ($wrow['srv_backup_compress'] == True) {
                        echo "\n<input type='radio' name='scr_backup_compress' value='1' checked > Yes ";
                        echo "\n<input type='radio' name='scr_backup_compress' value='0'> No  ";
                    }else{
                    echo "\n<input type='radio' name='scr_backup_compress' value='1'> Yes  ";
                    echo "\n<input type='radio' name='scr_backup_compress' value='0' checked > <b>No</b>";
                    }
                    break;
    }
    echo "\n</div>";



    # Files and Directories to Backup
    echo "\n\n<div class='left_label'>Dir. & file(s) to backup</div>";
    echo "\n<div class='left_input'>";
    echo "  <textarea rows='15' cols='60' name='backuplist' form='backup'>";
    $BLHASH = Read_BackupList($wrow);
    echo "</textarea>";
    echo "\n</div>";
        
    # Files and Directories to Exclude from Backup
    echo "\n\n<div class='left_label'>Dir. & files(s) to exclude</div>";
    echo "\n<div class='left_input'>";
    echo "  <textarea rows='15' cols='60' name='backupexclude' form='backup'>";
    $BEHASH = Read_BackupExclude($wrow);
    echo "</textarea>";
    echo "\n</div>";

}





// ================================================================================================
// DISPLAY BACKUP POLICY 
// ================================================================================================
function show_backup_policy() {

    # SHOW BACKUP POLICIES AS DEFINED IN $SADMIN/cfg/sadmin.cfg
    echo "\n\n<div class='backup_policy'>\n                   <!-- Start backup_policy Div -->";
    echo "<strong>Backup policies for all systems (defined in " . SADM_CFG_FILE . ")</strong>";
    echo "\n\n<div class='backup_retension'>\n                <!-- Start backup_retension Div -->";
    
    # Backup destination
    echo "\n&nbsp;&nbsp;&nbsp;  - Backup are done on NFS server '" . SADM_BACKUP_NFS_SERVER ;
    echo "' in directory '". SADM_BACKUP_NFS_MOUNT_POINT ."'";

    # Daily Backup policy
    echo "\n<br>&nbsp;&nbsp;&nbsp;  - ";
    echo "Daily backup will always keep a copy of the last " .SADM_DAILY_BACKUP_TO_KEEP. " backup.";

    # Weekly Backup policy
    switch (SADM_WEEKLY_BACKUP_DAY) {
        case '1' :  $wday = "Monday" ;
                    break ;
        case '2' :  $wday = "Tuesday" ;
                    break ;
        case '3' :  $wday = "Wednesday" ;
                    break ;
        case '4' :  $wday = "Thursday" ;
                    break ;
        case '5' :  $wday = "Friday" ;
                    break ;
        case '6' :  $wday = "Saturday" ;
                    break ;
        case '7' :  $wday = "Sunday" ;
                    break ;
        default  :  $wday = "Invalid";
                    break;
    }
    echo "\n<br>&nbsp;&nbsp;&nbsp;  - ";
    echo "Weekly backup is done on $wday and keep a copy of the last ";
    echo SADM_WEEKLY_BACKUP_TO_KEEP . " backup.";

    # Monthly Backup Policy
    echo "\n<br>&nbsp;&nbsp;&nbsp;  - ";
    echo "Monthly backup is done on the " . SADM_MONTHLY_BACKUP_DATE . " of each month and ";
    echo "keep a copy of the last " . SADM_MONTHLY_BACKUP_TO_KEEP . " backup.";
    
    # Yearly backup policy
    $mth_name =array('Any Months','January','February','March','April','May','June','July','August',
                    'September','October','November','December');
    $wmonth = $mth_name[SADM_YEARLY_BACKUP_MONTH];
    echo "\n<br>&nbsp;&nbsp;&nbsp;  - ";
    echo "Yearly backup is done on the " . SADM_YEARLY_BACKUP_DATE . " of $wmonth and ";
    echo " keep a copy of the last " . SADM_YEARLY_BACKUP_TO_KEEP . " backup.";
    
    # End Of Backup Policy
    echo "\n</div>                                        <!-- End of backup_retension Div -->";
    echo "\n</div>                                        <!-- End of backup_policy Div -->";
    echo "\n<br>";
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
    #$wmonth=$_POST['scr_backup_month'];                             # Save Chosen Month Array
    #if (empty($wmonth)) { $wmonth = "YNNNNNNNNNNNN"; }              # If Array Empty,set default
    #$wstr=str_repeat('N',13);                                       # Default "N" in all 13 Char
    #if (in_array('0',$wmonth)) {                                    # If Choose Every Months
    #    $wstr= "YNNNNNNNNNNNN";                                     # Set String Accordingly
    #}else{                                                          # If Choose Specific Months
    #    foreach ($wmonth as $p) {                                   # Foreach Month Nb. Selected
    #        $wstr=substr_replace($wstr,'Y',intval($p),1);           # Replace N to Y for Sel Mth
    #        }                                                           # End of ForEach
    #}                                                               # End of If
    $wstr= "YNNNNNNNNNNNN";                                         # Set String Accordingly
    $pmonth = trim($wstr);                                          # Remove Begin/End Space
    $sql = $sql . "srv_backup_month = '"  . $pmonth  ."', ";        # Insert in SQL Statement
    
    
    # Date in the month that the Backup can Run. -----------------------------------------------
    #$wdom=$_POST['scr_backup_dom'];                                 # Save Choosen Date Array
    #if (empty($wdom)) { $wdom="YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN";}  # If Empty Array Set Default
    #$wstr=str_repeat('N',32);                                       # Default all 32 Char.
    #if (in_array('0',$wdom)) {                                      # If Choose Every Date
    #    $wstr="YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN";                   # Set String Accordingly
    #}else{                                                          # If Choose Specific Date
    #    foreach ($wdom as $p) {                                     # For Each Date Selected
    #        $wstr=substr_replace($wstr,'Y',intval($p),1);           # Replace N by Y for Sel.Mth
    #        }                                                           # End of ForEach
    #}                                                               # End of If
    $wstr="YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN";                       # Set String Accordingly
    $pdom = trim($wstr) ;                                           # Save for crontab
    $sql = $sql . "srv_backup_dom = '"    . $wstr  ."', ";          # Insert in SQL Statement
    
    
    # Day of the Week we want to run the Backup (0=All Day 1=Sun 2=Mon)-------------------------
    #$wdow=$_POST['scr_backup_dow'];                                 # Save Chosen Day Choose
    #if (empty($wdow)) { for ($i = 0; $i < 8; $i = $i + 1) { $wdow[$i] = $i; } }
    #$wstr=str_repeat('N',8);                                        # Default All Week to No
    #if (in_array('0',$wdow)) {                                      # If Choose Every DayOfWeek
    #    $wstr="YNNNNNNN" ;                                          # Set String Accordingly
    #}else{                                                          # If Choose specific Days
    #    foreach ($wdow as $p) {                                     # For Each Day Selected
    #        $wstr=substr_replace($wstr,'Y',intval($p),1);           # Replace N By Y for Sel.Day
    #        }                                                           # End of ForEach
    #}                                                               # End of If
    $wstr="YNNNNNNN" ;                                              # Set String Accordingly
    $pdow = trim($wstr) ;                                           # Remove Begin/End Space
    $sql = $sql . "srv_backup_dow = '"  . $wstr  ."', ";            # Insert in SQL Statement
    
    
    # Compress backup or not -------------------------------------------------------------------
    $sql = $sql . "srv_backup_compress = '" . sadm_clean_data($_POST['scr_backup_compress'])   ."', ";

    # Hour, Minute to perform the Backup -------------------------------------------------------
    $sql = $sql . "srv_backup_hour   = '" . sadm_clean_data($_POST['scr_backup_hour'])   ."', ";
    $sql = $sql . "srv_backup_minute = '" . sadm_clean_data($_POST['scr_backup_minute']) ."', ";
    
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
            $err_msg = "Server '" .$_POST['server_key']. "' updated";   # Advise user of success Msg
            if ($DEBUG) {
                $err_msg = $err_msg ."\nUpdate SQL Command = ". $sql ;  # Include SQL Stat. in Mess.
                sadm_alert ($err_msg) ;                                 # Msg. Error Box for User
                }
        }
        
        # Write Back the Backup List and Backup Exclude file.
        Write_BackupList($_POST['server_key'],$_POST['blhash']);        # Write Back Backup List
        Write_BackupExclude($_POST['server_key'],$_POST['behash']);     # Write Back Exclude List
        
        # Back to Calling Page
        echo "<script>location.replace('" . $_POST['BACKURL'] . "');</script>";  # Backup to Caller URL
        exit;
    }
    
    
    
    
    # ==================================================================================================
    # INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
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
    
    # Display Page Header   
    $title1="Daily backup for '" . $row['srv_name'] . "." . $row['srv_domain'] . "'";
    if ($row['srv_backup'] == True) {
        list ($title2, $UPD_DATE_TIME) = SCHEDULE_TO_TEXT($row['srv_backup_dom'], 
        $row['srv_backup_month'],$row['srv_backup_dow'], 
        $row['srv_backup_hour'], $row['srv_backup_minute']);
    }else{
        $title2="Backup is not activated";
    }
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading

    
    # START OF FORM - DISPLAY FORM READY TO UPDATE DATA
    echo "\n\n<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' id='backup' method='POST'>";
    display_backup_schedule($con,$row,"Update");                        # Display Form Default Value
        
    # Set the Submitted Flag On - We are done with the Form Data
    echo "\n<input type='hidden' value='1' name='submitted' />";        # hidden use On Nxt Page Exe
    echo "\n<input type='hidden' value='".$row['srv_name']  ."' name='server_key' />"; # save srvkey
    echo "\n<input type='hidden' value='".$row['srv_ostype']."' name='server_os'  />"; # save O/S
    echo "\n<input type='hidden' value='".$BACKURL."' name='BACKURL'  />"; # Save Caller URL
    echo "\n<input type='hidden' value='".$BLHASH."' name='blhash' />"; # [B]ackup [L]ist Hash
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
    echo "\n<br>";                                                      # Blank Line After Button
    show_backup_policy();
    std_page_footer($con)                                               # Close MySQL & HTML Footer
    ?>