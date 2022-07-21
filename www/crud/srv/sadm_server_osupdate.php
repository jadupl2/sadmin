<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_server_update.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to edit a server.
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
#   2017_03_09 - Jacques Duplessis
#       V1.8 Add lot of comments in code and enhance code performance 
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
#   2017_12_31 - Jacques Duplessis
#       V2.1 Update O/S Update Page now update the SADM_USER crontab 
#   2018_07_22  v2.2 After updating a server browser will go back on page ready to edit another one.
# 2019_01_11 Change: v2.3 Cancel button now bring you to update menu.
# 2019_01_21 Change: v2.4 Added Dark Theme
# 2019_01_21 Change: v2.5 Show on one line next o/s update amd show server domain.
# 2019_04_04 Update: v2.6 If a Date is used to schedule O/S Update then the day specify is not used.
# 2019_05_04 Update: v2.7 When specific date(s) specified for update, day of week change to 'All'.
# 2019_08_17 Update: v2.8 Use new heading function, New parameter (URL) to get back to caller page.
# 2020_01_12 Update: v2.9 Enhance appearance and color of form. 
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
.osupdate_form {
    font-family     :   Verdana, Geneva, sans-serif;
    background-color:   #006456;
    color           :    white;    
    width           :   55%;
    margin-top      :   1%;
    margin-left     :   auto;
    margin-right    :   auto;
    border          :   2px solid #000000;
    font-size       :   12px;
    text-align      :   right;
    padding         :   1%;
    border-width    :   1px;
    border-style    :   solid;
    border-color    :   #000000;
    border-radius   :   10px;
    line-height     :   1.7;    
}
/* Attribute for Column Name at the left of the form */
.osupdate_label {
    float           :   left;
    width           :   48%;
    /* background-color:   Yellow; */
    font-weight     :   normal; 
    margin-right: 12px;   

}
/* Attribute for column Input at the right of the screen in the form */
.osupdate_input {
/*    background-color:    #454c5e;*/
    color           :   white;
    float           :   left;
    margin-bottom   :   8px;
    margin-left     :   5px;
    text-align      :   left;
    width           :   40%;
    border-width    :   0px;
    border-style    :   solid;
    border-color    :   #000000;
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
$SVER  = "2.9" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_menu.php?sel=';                    # Maintenance Menu Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button


// ================================================================================================
//                      DISPLAY SERVER SCHEDULE FOR OS UPDATE MODIFICATION 
// con   = Connector Object to Database 
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_osschedule($con,$wrow,$mode) {
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase
    echo "\n\n<div class='osupdate_form'>\n";                             # Start server Form Div

    
    # UPDATE THE O/S MANUALLY OR SCHEDULED (AUTOMATICALLY) ? ---------------------------------------
    echo "\n\n<div class='osupdate_label'>Activate O/S Update Schedule</div>";
    echo "\n<div class='osupdate_input'>";
    if ($mode == 'C') { $wrow['srv_update_auto'] = False ; }             # Default Regularly
    switch ($mode) {
        case 'D' : if ($wrow['srv_update_auto'] == True) {
                        echo "\n<input type='radio' name='scr_update_auto' value='1' ";
                        echo "onclick='javascript: return false;' checked> Yes  ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0' ";
                        echo "onclick='javascript: return false;'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_update_auto' value='1' ";
                        echo "onclick='javascript: return false;'> Yes  ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0' ";
                        echo "onclick='javascript: return false;' checked > No ";
                    }
                    break;
        default   : if ($wrow['srv_update_auto'] == True) {
                        echo "\n<input type='radio' name='scr_update_auto' value='1' checked > Yes ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0'> No  ";
                    }else{
                        echo "\n<input type='radio' name='scr_update_auto' value='1'> Yes  ";
                        echo "\n<input type='radio' name='scr_update_auto' value='0' checked > <b>No</b>";
                    }
                    break;
    }
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # REBOOT AFTER O/S UPDATE (YES/NO) ? -----------------------------------------------------------
    echo "\n\n<div class='osupdate_label'>Reboot after O/S update</div>";
    echo "\n<div class='osupdate_input'>";
    if ($mode == 'C') { $wrow['srv_update_reboot'] = False ; }          # Default Value to No Reboot
    switch ($mode) {
        case 'D' :  if ($wrow['srv_update_reboot'] == True) {
                        echo "\n<input type='radio' name='scr_update_reboot' value='1' ";
                        echo "onclick='javascript: return false;' checked> Yes";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0' ";
                        echo "onclick='javascript: return false;'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_update_reboot' value='1' ";
                        echo "onclick='javascript: return false;'> Yes";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0' ";
                        echo "onclick='javascript: return false;' checked > No";
                    }
                    break;
        default  :  if ($wrow['srv_update_reboot'] == True) {
                        echo "\n<input type='radio' name='scr_update_reboot' value='1' checked>Yes";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_update_reboot' value='1'> Yes";
                        echo "\n<input type='radio' name='scr_update_reboot' value='0' checked> No";
                    }
                    break;
    }
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # ----------------------------------------------------------------------------------------------
    # O/S UPDATE MONTHS - Specify what month the Update need to run - Default is All months
    # srv_update_month Char Array will contain 'Y' if month is choosen and 'N' if not.
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='osupdate_label'>Month(s) to run the O/S Update</div>";
    $mth_name = array('Any Months','January','February','March','April','May','June','July','August',
                'September','October','November','December');
    echo "\n<div class='osupdate_input'>";
    echo "<select name='scr_update_month[]' multiple='multiple' size=6>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 13; $i = $i + 1) {
                        echo "\n<option value='$i' ";
                        if ($i ==0) { echo "selected" ; }
                        echo "/>" . $mth_name[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 13; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_update_month'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $mth_name[$i] . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # ----------------------------------------------------------------------------------------------
    # DATE NUMBER in the month (dom) to Update O/S 
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='osupdate_label'>Date to perform the update</div>";
    echo "\n<div class='osupdate_input'>";
    echo "\n<select name='scr_update_dom[]' multiple='multiple' size=5>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i' selected/>" . sprintf("%02d",$i) . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_update_dom'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" ;
                        if ($i == 0) { echo " Any date of the month" ;}
                        if ($i == 1) { echo " 1st of the month" ;}
                        if ($i == 2) { echo " 2nd of the month" ;}
                        if ($i == 3) { echo " 3rd of the month" ;}
                        if ($i >= 4) { echo " " . $i . "th of the month" ;}
                        echo "</option>";
                    }     
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # ----------------------------------------------------------------------------------------------
    # Day in the week (dow) to update the O/S
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='osupdate_label'>Day of the update O/S</div>";
    echo "\n<div class='osupdate_input'>";
    $days = array('All','Sun','Mon','Tue','Wed','Thu','Fri','Sat');

    echo "\n<select name='scr_update_dow[]' multiple='multiple' size=8>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 8; $i = $i + 1) {
                        echo "\n<option value='$i' ";
                        if ($i == 7) { echo " selected"; }
                        echo "/>" . $days[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 8; $i = $i + 1) {
                        echo "\n<option value='$i' " ;
                        if (substr($wrow['srv_update_dow'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $days[$i];
                        if ($i == 0) { echo "  (Run any day of the week)" ;} 
                        echo "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # ----------------------------------------------------------------------------------------------
    # Hour to update the O/S
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='osupdate_label'>Time to Update the O/S</div>";
    echo "\n<div class='osupdate_input'>";
    echo " Hour ";
    echo "\n<select name='scr_update_hour' size=1>";
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


    # ----------------------------------------------------------------------------------------------
    # Minute to update the O/S
    # ----------------------------------------------------------------------------------------------
    echo " Min ";
    echo "\n<select name='scr_update_minute' size=1>";
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
                        if ($wrow['srv_update_minute'] == $i) {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo ">" . sprintf("%02d",$i) . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
  
    echo "\n</div>";                                                    # << End of O/S Update Form
    echo "\n<br>\n\n";                                                  # Blank Lines
}



# ==================================================================================================
#                   SECOND EXECUTION OF PAGE AFTER THE UPDATE BUTTON IS PRESS
# ==================================================================================================

# Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Submitted for " . $_POST['scr_name'];}  # Debug Info Start Submit
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }    # Fill in Post Array 

        # Construct SQL to Update row
        $sql = "UPDATE server SET ";

        # Automatic Update (Based on Schedule) or Manual (You Start the Update when needed)---------
        $sql = $sql . "srv_update_auto = '"   . sadm_clean_data($_POST['scr_update_auto'])   ."', ";

        # Reboot after O/S Update if any update were applied ---------------------------------------
        $sql = $sql . "srv_update_reboot = '" . sadm_clean_data($_POST['scr_update_reboot']) ."', ";


        # Month that O/S Update may run ------------------------------------------------------------
        # Store as a string of 13 characters, Each Char. can be "Y" (Selected) or 'N' (Not Selected)
        $wmonth=$_POST['scr_update_month'];                             # Save Choosen Month Array
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
        $sql = $sql . "srv_update_month = '"  . $pmonth  ."', ";        # Insert in SQL Statement


        # Date in the month that the O/S Update Can Run. -------------------------------------------
        $wdom=$_POST['scr_update_dom'];                                 # Save Choosen Date Array
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
        $sql = $sql . "srv_update_dom = '"    . $wstr  ."', ";          # Insert in SQL Statement


        # Day of the Week we want to run the O/S Update (0=All Day 1=Sun 2=Mon)---------------------
        $wdow=$_POST['scr_update_dow'];                                 # Save Choosen Day Choose
        #if (empty($wdow)) { for ($i = 0; $i < 8; $i = $i + 1) { $wdow[$i] = $i; } }
        if (empty($wdow)) { $wdow="YNNNNNNN" ;}                         # If Empty Array Set Default
        $wstr=str_repeat('N',8);                                        # Default All Week Day to No
        if (in_array('0',$wdow)) {                                      # If Choose Every DayOf Week
            $wstr="YNNNNNNN" ;                                          # Set String Accordingly
        }else{                                                          # If Choose specific Days
            foreach ($wdow as $p) {                                     # For Each Day Selected
                $wstr=substr_replace($wstr,'Y',intval($p),1);           # Replace N By Y for Sel.Day
            }                                                           # End of ForEach
        }                                                               # End of If
        if ((substr($pdom,0,1) != "Y") and ($wstr != "YNNNNNNN")) {     # If a Date of Upd specified
            $err_msg = "When specific date(s) are specified for the O/S update,\n";
            $err_msg = "$err_msg the day of the week field is change to 'All' (Can't have both)";
            sadm_alert ($err_msg) ;                                     # Display Error Msg. Box
            $wstr = "YNNNNNNN" ;                                        # If Specific Date Entered
        }
        $pdow = trim($wstr) ;                                           # Remove Begin/End Space
        $sql = $sql . "srv_update_dow = '"  . $wstr  ."', ";            # Insert in SQL Statement


        # Hour, Minute to perform the O/S Update ---------------------------------------------------
        $sql = $sql . "srv_update_hour   = '" . sadm_clean_data($_POST['scr_update_hour'])   ."', ";
        $sql = $sql . "srv_update_minute = '" . sadm_clean_data($_POST['scr_update_minute']) ."', ";

        # Update Last Edit Date --------------------------------------------------------------------
        $sql = $sql . "srv_date_edit     = '" . date("Y-m-d H:i:s")                          ."'  ";

        $sql = $sql . "WHERE srv_name     = '" . $_POST['server_key'] ."'; ";
        if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }
        
        # Execute the Row Update SQL ---------------------------------------------------------------
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute Update Row SQL
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
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
        
        # CRONTAB SADMIN UPDATE ON LINUX
        #if ($DEBUG) { sadm_alert ("POST[server_os] = " . $_POST['server_os'])  ;}
        #if ($_POST['server_os'] == "linux") {
        #    if (! $_POST['scr_update_auto']) { $MODE = "D"; }else{ $MODE = "U" ; }
        #    update_crontab (SADM_UPDATE_SCRIPT . $_POST['server_key'],$MODE,$pmonth,$pdom,$pdow, 
        #        $_POST['scr_update_hour'], $_POST['scr_update_minute']) ;
        #}

        # Back to Server List Page
        echo "<script>location.replace('" . $_POST['BACKURL'] . "');</script>";  # Backup to Caller URL
        #$redirect="/crud/srv/sadm_server_menu.php?sel=" . $_POST['scr_name'];
        #header("Location: " . $redirect . " ");
        #exit();
        #?> <script> location.replace("/view/sys/sadm_view_schedule.php"); </script><?php
        exit;
    }

 
# ==================================================================================================
#               INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
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
        <script>location.replace("/view/sys/sadm_view_schedule.php");</script>
        <?php                                                           # Back 2 List Page
        exit ; 
    }

    # 2nd parameters reference the URL where this page was called.
    if ($DEBUG) { echo "<br>2nd Parameter Received is " . $back; }      # Under Debug Show 2nd Parm.
    if ((isset($_GET['back'])) and ($_GET['back'] != ""))  {            # If Value Rcv and not Blank
       $BACKURL = $_GET['back'] ."?sel=" . $wkey ;                      # Save 2nd Parameter Value
    }else{
       $BACKURL = "/crud/srv/sadm_server_main.php?sel=" .$wkey;         # Where to go back after 
    }


    # DISPLAY PAGE HEADING
    $wserver = $row['srv_name'] . "." . $row['srv_domain'];
    $title1="O/S update schedule for '" .$wserver. "'";                 # Heading 1 Line

    # Take O/S Update Server Data and return next update to a one line text and date of next update.
    list ($title2, $DATE_SCHED) = SCHEDULE_TO_TEXT($row['srv_update_dom'], $row['srv_update_month'],
            $row['srv_update_dow'], $row['srv_update_hour'], $row['srv_update_minute']);
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading

    # Start of the Form - Show O/S Schedule Data for current server
    echo "\n\n<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_osschedule($con,$row,"Update");                             # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "\n<input type='hidden' value='1' name='submitted' />";        # hidden use On Nxt Page Exe
    echo "\n<input type='hidden' value='".$BACKURL."' name='BACKURL'  />"; # Save Caller URL
    echo "\n<input type='hidden' value='".$row['srv_name']  ."' name='server_key' />"; # save srvkey
    echo "\n<input type='hidden' value='".$row['srv_ostype']."' name='server_os'  />"; # save O/S
    
    # DISPLAY BUTTONS (UPDATE/CANCEL) AT THE BOTTOM OF THE FORM
    echo "\n\n<div class='deux_boutons'>";
    echo "\n<div class='premier_bouton'><button type='submit'> Update </button></div>";
    echo "\n<div class='second_bouton'><a href='" . $BACKURL . "'><button type='button'> Cancel ";
    echo "</button></a>\n</div>";
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    echo "\n</div>\n\n";

    echo "\n</form>";                                                   # End of Form  
    echo "\n<br>";                                                      # Blank Line After Button
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
