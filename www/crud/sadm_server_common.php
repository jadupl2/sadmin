<?php
#
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_common.php
#   Version  :  2.0
#   Date     :  9 July 2016
#   Requires :  php
#   Synopsis :  This file is the place to store all common functions for sadm_server_*.php pages.
#               The sadm_server_*.php pages are used to create/update/delete server in Database.
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
# --------------------------------------------------------------------------------------------------
# Revision/History :
#
# ==================================================================================================
#
#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = True ;                                                         # Activate Debug True/False

# ==================================================================================================
#                      Update the crontab based on the $paction parameter
#
#   pname    The hostname of the server to include/modify/delete in crontab
#   paction  [C] for create entry  [U] for Updating the crontab   [D] Delete crontab entry
#   pmonth   12 Characters (either a Y or a N) each representing a month (YYYYYYYYYYYY)
#            Default is that entry could run every month, no restriction based on month
#   pdom     31 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#            Default all at Y - Entry could run any day of the month 
#            So entry will run Once a week on the day specify in pdow 
#   pdow     7 Characters (either a Y or a N) each representing a week day () Starting with Sunday
#            Default at Saturday
#   phour    Hour when the update should begin (00-23) - Default 1am
#   pmin     Minute when the update will begin (00-50) - Default 5min
#
# Default will cause new entry to run every week on Saturday at 1:05 am.
# ==================================================================================================
function update_crontab ($pscript, $paction = "U", $pmonth = "YYYYYYYYYYYY", 
                         $pdom = "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY", $pdow = "NNNNNNY", 
                         $phour = "01", $pmin ="05") 
{
    # Begin constructing our crontab line ($cline) based on parameters received
    $cline = sprintf ("%02d %02d ",$pmin,$phour);                       # Hour & Min. of Execution

    # Construct Date of the month (1-31) to run and add it to crontab line ($cline)
    if ($pdom == str_repeat("Y",31)) {                                  # If it's to run every Date
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Date 
        $cdom = "";                                                     # Clear Work Variable
        for ($i = 0; $i < 31; $i = $i + 1) {                            # Check for Y or N in DOM
            if (substr($pdom,$i,1) == "Y") {                            # If Yes to run that Date
                if (strlen($cdom) == 0) {                               # And first date to add
                    $cdom = sprintf("%02d",$i+1);                       # Add Date number 
                }else{                                                  # If not 1st month in list
                    $cdom = $cdom . "," . sprintf("%02d",$i+1);         # More Date add , before
                }
            }    
        }
        $cline = $cline . $cdom . " " ;                                 # Add DOM in Crontab Line
    }
    
    # Construct the month(s) (1-12) to run and add it to crontab line ($cline)
    if ($pmonth == str_repeat("Y",12)) {                                # If it's to run every Month
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Months
        $cmonth = "";                                                   # Clear Work Variable
        for ($i = 0; $i < 12; $i = $i + 1) {                            # Check for Y or N in Month
            if (substr($pmonth,$i,1) == "Y") {                          # If Yes to run that month
                if (strlen($cmonth) == 0) {                             # And first month to add
                    $cmonth = sprintf("%02d",$i+1);                     # Add month number 
                }else{                                                  # If not 1st month in list
                    $cmonth = $cmonth . "," . sprintf("%02d",$i+1);     # More Mth add , before Mth
                }
            }    
        }
        $cline = $cline . $cmonth . " " ;                               # Add Month in Crontab Line
    }
    
    # Construct the day of the week (0-6) to run and add it to crontab line ($cline)
    if ($pdow == str_repeat("Y",7)) {                                   # If it's to run every Day
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Day
        $cdow = "";                                                     # Clear Work Variable
        for ($i = 0; $i < 7; $i = $i + 1) {                             # Check for Y or N in Week
            if (substr($pdow,$i,1) == "Y") {                            # If Yes to run that Day
                if (strlen($cdow) == 0) {                               # And first add day of week
                    $cdow = sprintf("%02d",$i);                         # Add Day number 
                }else{                                                  # If not 1st Day in list
                    $cdow = $cdow . "," . sprintf("%02d",$i);           # More Day add , before Day
                }
            }    
        }
        $cline = $cline . $cdow . " " ;                                 # Add Month in Crontab Line
    }
    
    # Add User, script name and script parameter to crontab line
    $cline = $cline . "root " . $pscript . " >/dev/null 2>&1\n";        # Add user & cmd on $cline
    if ($DEBUG) { echo "\n<br>Assemble crontab line : " . $cline ; }    # Debug Show crontab line
   
    # Opening what will become the new crontab file
    $newtab = fopen(SADM_WWW_TMP_FILE1,"w");                            # Create new Crontab File
    if (! $newtab) {                                                    # If Create didn't work
        sadm_fatal_error ("Can't create file " . SADM_WWW_TMP_FILE1) ;  # Show Err & Back Prev. Page
    } 
    # Write Crontab File Header
    $wline = "# Please don't edit manually, SADMIN generated file ". date("Y-m-d H:i:s") ."\n"; 
    fwrite($newtab,$wline);                                             # Write SADM Cron Header
    fwrite($newtab,"# \n");                                             # Write Comment Line

    # Open existing crontab File - If don't exist create empty one
    if (!file_exists(SADM_CRON_FILE)) {                                 # SADM crontab doesn't exist
        touch(SADM_CRON_FILE);                                          # Create empty crontab file
        chmod(SADM_CRON_FILE,0640);                                     # Set Permission on crontab
        #chown(SADM_CRON_FILE,'root');                                   # Set Crontab Owner
        #chgrp(SADM_CRON_FILE,'root');                                   # Set Crontab Group Owner
    }

    # Load actual crontab in array and process each line in array
    $alines = file(SADM_CRON_FILE);                                     # Load Crontab in Array
    $UPD_DONE = False;                                                  # AutoUpdate was Off now ON?
    foreach ($alines as $line_num => $line) {                           # Process each line in Array
        if ($DEBUG) { echo "\n<br>Before Processing Ligne #{$line_num} : " . $line ; }        
        if (strpos(trim($line), '#') === 0) continue;                   # Next line if comment
        $line = trim($line);                                            # Trim Crontab Line
        $wpos = strpos($line,$pscript);                                 # Get Pos. of script on line
        if ($wpos == false) {                                           # If Script is not on line
            fwrite($newtab,${line}."\n");                               # Write line to new crontab
        }else{                                                          # If script to Upd or Del
            continue;                                                   # Line Match then skip it
        }    
    }
    if ($paction == 'C') { fwrite($newtab,$cline); }                    # Add new line to crontab 
    if ($paction == "U") { fwrite($newtab,$cline); }                    # Add Update line to crontab 
    fclose($newtab);                                                    # Close sadm new crontab
    if (! copy(SADM_WWW_TMP_FILE1,SADM_CRON_FILE)) {                    # Copy new over existing 
        sadm_fatal_error ("Error copying " . SADM_WWW_TMP_FILE1 . " to " . SADM_CRON_FILE . " ");
    }
    unlink(SADM_WWW_TMP_FILE1);                                         # Delete Crontab tmp file
}


# ==================================================================================================
#                      DISPLAY SERVER DATA USED IN THE DATA INPUT FORM
#
#  wrow  = Array containing table row keys/values
#  mode  = "[D]isplay" Only show row content - Can't modify any information
#        = "[C]reate"  Display default values and user can modify all fields, except the row key
#        = "[U]pdate"  Display row content and user can modify all fields, except the row key
# ==================================================================================================
function display_server_form ( $wrow , $mode) {

    # FORM DIV
    echo "\n\n<div class='server_form'>\n                         <!-- Start of Form DIV -->\n";

    # FORM LEFT SIDE DIV
    echo "\n<div class='form_leftside'>                           <!-- Start LeftSide Form  -->\n";
    display_left_side ( $wrow , $mode);
    echo "\n</div>\n                                              <!-- End of LeftSide Form -->\n";

    # FORM RIGHT SIDE DIV
    echo "\n<div class='form_rightside'>                          <!-- Start RightSide Form  -->\n";
    display_right_side ( $wrow , $mode);
    echo "\n</div>\n                                              <!-- End of RightSide Form -->\n";

    echo "\n</div>\n                                              <!-- End of Form DIV -->\n";
    echo "\n<BR>                                                  <!-- Blank Before Button -->\n";
}




# ==================================================================================================
#                      DISPLAY LEFT SIDE OF SERVER DATA USED IN THE DATA INPUT FORM
#
#  wrow  = Array containing table row keys/values
#  mode  = "[D]isplay" Only show row content - Can't modify any information
#        = "[C]reate"  Display default values and user can modify all fields, except the row key
#        = "[U]pdate"  Display row content and user can modify all fields, except the row key
# ==================================================================================================
function display_left_side ( $wrow , $mode) {


    # ----------------------------------------------------------------------------------------------
    # Server Name
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Name</div>";
    echo "\n<div class='server_input1'>";
    switch ($mode) {
        case 'C' : echo "\n<input type='text' name='scr_name' size='16' maxlength='15' ";
                   echo "placeholder='Hostname' required ";
                   echo "value='" . sadm_clean_data($wrow['srv_name']). "' >";
                   break;
        default  : echo "\n<input type='text' name='scr_name' readonly size='16' ";
                   echo "placeholder='Hostname'";
                   echo "value='" . sadm_clean_data($wrow['srv_name']). "' >";
                   break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server Description
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Description</div>";
    echo "\n<div class='server_input1'>";
    switch ($mode) {
        case 'D' : echo "\n<input type='text' name='scr_desc' readonly ";
                   echo "placeholder='Server Desc.' maxlength='35' size='30' ";
                   echo "value='" . sadm_clean_data($wrow['srv_desc']). "'/>";
                   break ;
        default  : echo "\n<input type='text' name='scr_desc' required ";
                   echo "placeholder='Server Desc.' maxlength='35' size='30' ";
                   echo "value='" . sadm_clean_data($wrow['srv_desc']). "'/>";
                   break ;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server O/S Type (linux or aix)
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>O/S Type</div>";
    echo "\n<div class='server_input1'>";
    switch ($mode) {
        case 'C' :  echo "\n<select name='scr_ostype' size=1>";
                    echo "\n<option value='linux' selected>Linux</option>";
                    echo "\n<option value='aix'>Aix</option>";
                    break ;
        default  :  if ($mode == "U") {
                        echo "\n<select name='scr_ostype' size=1>";
                    }else{
                        echo "\n<select name='scr_ostype' size=1 disabled>";
                    }
                    if ($wrow['srv_ostype'] == 'linux') {
                        echo "\n<option value='linux' selected>Linux</option>";
                        echo "\n<option value='aix'>Aix</option>";
                    }else{
                        echo "\n<option value='linux'>Linux</option>";
                        echo "\n<option value='aix' selected>Aix</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server Category
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Category</div>";
    echo "\n<div class='server_input1'>";
    switch ($mode) {
        case 'D' : echo "\n<input type='text' name='scr_cat' readonly ";
                   echo "placeholder='Development' maxlength='15' size='16' ";
                   echo "value='" . sadm_clean_data($wrow['srv_cat']). "'/>";
                   break ;
        case 'C' : echo "\n<select name='scr_cat' size=1>";
                   $sqlcat = 'SELECT * FROM sadm.category order by cat_code;';
                   $rescat = pg_query($sqlcat) or die('Cat. Query failed: '. pg_last_error());
                   while ($crow = pg_fetch_array($rescat, null, PGSQL_ASSOC)) {
                      if ($crow['cat_default'] == 't') {
                        echo "\n<option selected>" ;
                     }else{
                        echo "\n<option>";
                     }
                     echo sadm_clean_data($crow['cat_code']) . "</option>";
                   }
                   echo "\n</select>";
                   pg_free_result($rescat);
                   break ;
        case 'U' : echo "\n<select name='scr_cat' size=1>";
                   $sqlcat = 'SELECT * FROM sadm.category order by cat_code;';
                   $rescat = pg_query($sqlcat) or die('Cat. Query failed: '. pg_last_error());
                   while ($crow = pg_fetch_array($rescat, null, PGSQL_ASSOC)) {
                     if (($crow['cat_code']) == ($wrow['srv_cat'])) {
                        echo "\n<option selected>" . sadm_clean_data($crow['cat_code'])."</option>";
                     }else{
                        echo "\n<option>" . sadm_clean_data($crow['cat_code']) . "</option>";
                     }
                   }
                   echo "\n</select>";
                   pg_free_result($rescat);
                   break ;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server Domain
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Domain</div>";
    echo "\n<div class='server_input1'>";
    switch ($mode) {
        case 'D' : echo "\n<input type='text' name='scr_domain' readonly ";
                   echo "placeholder='Server Domain Name' maxlength='25' size='26' ";
                   echo "value='" . sadm_clean_data($wrow['srv_domain']). "'/>";
                   break;
        default  : echo "\n<input type='text' name='scr_domain' required ";
                   echo "placeholder='Server Domain Name' maxlength='25' size='26' ";
                   echo "value='" . sadm_clean_data($wrow['srv_domain']). "'/>";
                   break ;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server Notes
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Notes</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'C') { $wrow['srv_notes'] = "" ; }               # Set Default Value to Space
    switch ($mode) {
        case 'D' : echo "\n<input type='text' name='scr_notes' readonly maxlength='30' size='30' ";
                   echo "value='" . sadm_clean_data($wrow['srv_notes']). "'>";
                   break;
        default  : echo "\n<input type='text' name='scr_notes' maxlength='30' size='30' ";
                   echo "value='" . sadm_clean_data($wrow['srv_notes']). "'>";
                   break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server Sporadically Online ? (True or False) Like a Laptop - Report Warning instead of Error
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Sporadic Server</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'C') { $wrow['srv_sporadic'] = false ; }               # Set Default Value to False
    switch ($mode) {
        case 'D' : if ($wrow['srv_sporadic'] == 't') {
                       echo "\n<input type='radio' name='scr_sporadic' value='1' ";
                       echo "onclick='javascript: return false;' checked> Yes";
                       echo "\n<input type='radio' name='scr_sporadic' value='0' ";
                       echo "onclick='javascript: return false;'> No";
                   }else{
                       echo "\n<input type='radio' name='scr_sporadic' value='1' ";
                       echo "onclick='javascript: return false;'> Yes  ";
                       echo "\n<input type='radio' name='scr_sporadic' value='0' ";
                       echo "onclick='javascript: return false;' checked > No";
                   }
                   break ;
        default  : if ($wrow['srv_sporadic'] == 't') {
                       echo "\n<input type='radio' name='scr_sporadic' value='1' checked > Yes ";
                       echo "\n<input type='radio' name='scr_sporadic' value='0'> No";
                   }else{
                       echo "\n<input type='radio' name='scr_sporadic' value='1'> Yes";
                       echo "\n<input type='radio' name='scr_sporadic' value='0' checked > No";
                   }
                   break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server Status
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Status</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'C') { $wrow['srv_active'] = True ; }                  # Default value to Active
    switch ($mode) {
        case 'D' : if ($wrow['srv_active'] == 't') {
                      echo "\n<input type='radio' name='scr_active' value='1' ";
                      echo "onclick='javascript: return false;' checked> Active  ";
                      echo "\n<input type='radio' name='scr_active' value='0' ";
                      echo "onclick='javascript: return false;'> Inactive";
                   }else{
                      echo "\n<input type='radio' name='scr_active' value='1' ";
                      echo "onclick='javascript: return false;'> Active  ";
                      echo "\n<input type='radio' name='scr_active' value='0' ";
                      echo "onclick='javascript: return false;' checked > Inactive";
                   }
                   break;
        default  : if ($wrow['srv_active'] == 't') {
                      echo "\n<input type='radio' name='scr_active' value='1' checked > Active  ";
                      echo "\n<input type='radio' name='scr_active' value='0'> Inactive";
                   }else{
                      echo "\n<input type='radio' name='scr_active' value='1'> Active";
                      echo "\n<input type='radio' name='scr_active' value='0' checked > Inactive";
                   }
                   break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Server TAG
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Tag</div>";
    echo "\n<div class='server_input1'>";
    switch ($mode) {
        case 'D' : echo "\n<input type='text' name='scr_tag' readonly maxlength='15' size='15' ";
                   echo "value='" . sadm_clean_data($wrow['srv_tag']). "'/>";
                   break;
        default  : echo "\n<input type='text' name='scr_tag' maxlength='15' size='15' ";
                   echo "value='" . sadm_clean_data($wrow['srv_tag']). "'/>";
                   break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Indicate the Day of the week that we want to take the ReaR Backup (Done during night time)
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>ReaR Backup Day</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'D') {
        switch ($wrow['srv_backup']) {
            case 0: $scr_backup=0 ; $scr_backup_desc="No backup" ; break;
            case 1: $scr_backup=1 ; $scr_backup_desc="Monday"    ; break;
            case 2: $scr_backup=2 ; $scr_backup_desc="Tuesday"   ; break;
            case 3: $scr_backup=3 ; $scr_backup_desc="Wednesday" ; break;
            case 4: $scr_backup=4 ; $scr_backup_desc="Thursday"  ; break;
            case 5: $scr_backup=5 ; $scr_backup_desc="Friday"    ; break;
            case 6: $scr_backup=6 ; $scr_backup_desc="Saturday"  ; break;
            case 7: $scr_backup=7 ; $scr_backup_desc="Sunday"    ; break;
        }
        echo "\n<input type='text' name='scr_backup_desc' readonly placeholder=" . $scr_backup_desc .
             " maxlength='15' size='16' value='" . sadm_clean_data($scr_backup_desc). "'/>\n";
    }
    if ($mode == 'C') {
       echo "\n<select name='scr_backup' size=1>";
       echo "\n<option value='3' selected>Wednesday</option>";
       echo "\n<option value='1'>Monday</option>";
       echo "\n<option value='2'>Tuesday</option>";
       echo "\n<option value='3'>Wednesday</option>";
       echo "\n<option value='4'>Thursday</option>";
       echo "\n<option value='5'>Friday</option>";
       echo "\n<option value='6'>Saturday</option>";
       echo "\n<option value='7'>Sunday</option>";
       echo "\n</select>";
    }
    if ($mode == 'U') {
       echo "\n<select name='scr_backup' size=1>";
       for ($x = 0; $x <= 7; $x++) {
           switch ($x) {
                case 0: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='0' selected>No backup</option>";
                        }else{
                           echo "\n<option value='0'>No backup</option>";
                        }
                        break;
                case 1: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='1' selected>Monday</option>";
                        }else{
                           echo "\n<option value='1'>Monday</option>";
                        }
                        break;
                case 2: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='2' selected>Tuesday</option>";
                        }else{
                           echo "\n<option value='2'>Tuesday</option>";
                        }
                        break;
                case 3: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='3' selected>Wednesday</option>";
                        }else{
                           echo "\n<option value='3'>Wednesday</option>";
                        }
                        break;
                case 4: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='4' selected>Thursday</option>";
                        }else{
                           echo "\n<option value='4'>Thursday</option>";
                        }
                        break;
                case 5: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='5' selected>Friday</option>";
                        }else{
                           echo "\n<option value='5'>Friday</option>";
                        }
                        break;
                case 6: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='6' selected>Saturday</option>";
                        }else{
                           echo "\n<option value='6'>Saturday</option>";
                        }
                        break;
                case 7: if ($x == $wrow['srv_backup']) {
                           echo "\n<option value='7' selected>Sunday</option>";
                        }else{
                           echo "\n<option value='7'>Sunday</option>";
                        }
                        break;
           }
       }
       echo "\n</select>";
    }
    echo "\n</div>";                                                      # << End of server_input
    


    # ----------------------------------------------------------------------------------------------
    # Monitor SSH Connectivity to Server ?
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Monitor SSH Connectivity</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'C') { $wrow['srv_monitor'] = True ; }                 # Set Default Value to True
    switch ($mode) {
        case 'D' : if ($wrow['srv_monitor'] == 't') {
                       echo "\n<input type='radio' name='scr_monitor' value='1' ";
                       echo "onclick='javascript: return false;' checked> Enable  ";
                       echo "\n<input type='radio' name='scr_monitor' value='0' ";
                       echo "onclick='javascript: return false;'> Disable";
                   }else{
                       echo "\n<input type='radio' name='scr_monitor' value='1' ";
                       echo "onclick='javascript: return false;'> Enable  ";
                       echo "\n<input type='radio' name='scr_monitor' value='0' ";
                       echo "onclick='javascript: return false;' checked > Disable";
                   }
                   break ;
        default  : if ($wrow['srv_monitor'] == 't') {
                       echo "\n<input type='radio' name='scr_monitor' value='1' checked > Enable ";
                       echo "\n<input type='radio' name='scr_monitor' value='0'> Disable";
                   }else{
                       echo "\n<input type='radio' name='scr_monitor' value='1'> Enable";
                       echo "\n<input type='radio' name='scr_monitor' value='0' checked > Disable";
                   }
                   break;
    }
    echo "\n</div>";

    
    # ----------------------------------------------------------------------------------------------
    # Maintenance Mode ON or OFF Monitor SSH Connectivity to Server ?
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Maintenance Mode</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'C') { $wrow['srv_maintenance'] = False ; }               # Default Mode is OFF
    switch ($mode) {
        case 'D' : if ($wrow['srv_maintenance'] == 't') {
                      echo "\n<input type='radio' name='scr_maintenance' value='1' ";
                      echo "onclick='javascript: return false;' checked> On  ";
                      echo "\n<input type='radio' name='scr_maintenance' value='0' ";
                      echo "onclick='javascript: return false;'> Off";
                   }else{
                      echo "\n<input type='radio' name='scr_maintenance' value='1' ";
                      echo "onclick='javascript: return false;'> On  ";
                      echo "\n<input type='radio' name='scr_maintenance' value='0' ";
                      echo "onclick='javascript: return false;' checked > Off";
                   }
                   break;
        default  : if ($wrow['srv_maintenance'] == 't') {
                      echo "\n<input type='radio' name='scr_maintenance' value='1' checked > On  ";
                      echo "\n<input type='radio' name='scr_maintenance' value='0'> Off";
                   }else{
                      echo "\n<input type='radio' name='scr_maintenance' value='1'> On";
                      echo "\n<input type='radio' name='scr_maintenance' value='0' checked > Off";
                   }
                   break;
    }
    echo "\n</div>";

}






# ==================================================================================================
#                      DISPLAY RIGHT SIDE OF SERVER DATA USED IN THE DATA INPUT FORM
#
#  wrow  = Array containing table row keys/values
#  mode  = "[D]isplay" Only show row content - Can't modify any information
#        = "[C]reate"  Display default values and user can modify all fields, except the row key
#        = "[U]pdate"  Display row content and user can modify all fields, except the row key
# ==================================================================================================
function display_right_side ( $wrow , $mode) {


    # ----------------------------------------------------------------------------------------------
    # Update the O/S Automatically (Yes/No) ?
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Update O/S</div>";
    echo "\n<div class='server_input2'>";
    if ($mode == 'C') { $wrow['srv_update_auto'] = True ; }             # Default Regularly
    switch ($mode) {
        case 'D' : if ($wrow['srv_update_auto'] == 't') {
                        echo "\n<input type='radio' name='scr_update_auto' value='1' ";
                        echo "onclick='javascript: return false;' checked> Enable  ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0' ";
                        echo "onclick='javascript: return false;'> Disable";
                    }else{
                        echo "\n<input type='radio' name='scr_update_auto' value='1' ";
                        echo "onclick='javascript: return false;'> Enable  ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0' ";
                        echo "onclick='javascript: return false;' checked > Disable ";
                    }
                    break;
        default   : if ($wrow['srv_update_auto'] == 't') {
                        echo "\n<input type='radio' name='scr_update_auto' value='1' checked > Enable ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0'> Disable  ";
                    }else{
                        echo "\n<input type='radio' name='scr_update_auto' value='1'> Enable  ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0' checked > Disable";
                    }
                    break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Reboot after O/S Update (Yes/No) ?
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Reboot after O/S update</div>";
    echo "\n<div class='server_input2'>";
    if ($mode == 'C') { $wrow['srv_update_reboot'] = False ; }        # Default Value to No Reboot
    switch ($mode) {
        case 'D' :  if ($wrow['srv_update_reboot'] == 't') {
                        echo "\n<input type='radio' name='scr_update_reboot' value='1' ";
                        echo "onclick='javascript: return false;' checked> Enable";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0' ";
                        echo "onclick='javascript: return false;'> Disable";
                    }else{
                        echo "\n<input type='radio' name='scr_update_reboot' value='1' ";
                        echo "onclick='javascript: return false;'> Enable";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0' ";
                        echo "onclick='javascript: return false;' checked > Disable";
                    }
                    break;
        default  :  if ($wrow['srv_update_reboot'] == 't') {
                        echo "\n<input type='radio' name='scr_update_reboot' value='1' checked> Enable";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0'> Disable";
                    }else{
                        echo "\n<input type='radio' name='scr_update_reboot' value='1'> Enable";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0' checked> Disable";
                    }
                    break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # O/S Update Months - Specify what month the Update need to run - Default is All months
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Months to Update O/S</div>";
    echo "\n<div class='server_input2'>";
    $months = array('January','February','March','April','May','June','July ','August','September',
                    'October','November','December',);
    echo "\n<select name='scr_update_month[]' multiple='multiple' size=3>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 12; $i = $i + 1) {
                        echo "\n<option value='$i' selected/>" . $months[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 12; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_update_month'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $months[$i] . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    #echo "mth = " . $wrow['srv_update_month'];
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Date in the month (dom) to Update O/S 
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Date in month to update O/S</div>";
    echo "\n<div class='server_input2'>";
    echo "\n<select name='scr_update_dom[]' multiple='multiple' size=3>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 31; $i = $i + 1) {
                        echo "\n<option value='$i' selected/>" . sprintf("%02d",$i) . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 31; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_update_dom'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i+1) . "</option>";
                    }     
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Day in the week (dow) to update the O/S
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Day in the week to update O/S</div>";
    echo "\n<div class='server_input2'>";
    $days = array('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
    echo "\n<select name='scr_update_dow[]' multiple='multiple' size=3>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 7; $i = $i + 1) {
                        echo "\n<option value='$i' ";
                        if ($i == 6) { echo " selected"; }
                        echo "/>" . $days[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 7; $i = $i + 1) {
                        echo "\n<option value='$i' " ;
                        if (substr($wrow['srv_update_dow'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $days[$i] . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Hour to update the O/S
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Time to Update the O/S</div>";
    echo "\n<div class='server_input2'>";
    echo "\n<select name='scr_update_hour' size=3>";
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
                        if ($wrow['srv_update_hour'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo " Hour ";
    echo "\n<select name='scr_update_minute' size=3>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 60; $i = $i + 1) {
                        if ($i == 5) { 
                            echo "\n<option value='$i' selected>" . sprintf("%02d",$i) . "</option>";
                        }else{
                            echo "\n<option value='$i'>" . sprintf("%02d",$i) . "</option>";
                        }
                    }
                    break ;
        default  :  for ($i = 0; $i < 60; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if ($wrow['srv_update_minute'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo " Min ";
    echo "\n</div>";

    # Space Lines    -------------------------------------------------------------------------------
    echo "\n<br>\n";
   
    # Last Edit Date -------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Last Edit Date & Time</div>";
    echo "\n<div class='server_input2'>";
    echo "\n<input type='text' name='scr_last_edit_date' readonly maxlength='20' size='20' ";
    echo "value='" . sadm_clean_data($wrow['srv_last_edit_date']). "'/>";
    echo "</div>\n";

}
?>
