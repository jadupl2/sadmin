<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_sched_vmexport.php
#   Version     :  1.0
#   Date        :  27 September
#   Requires    :  php - MySQL
#   Description :  Web Page used to edit a server.
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
# 2024_09_27 vmexport v1.0 Initial development.
#@2024_09_27 vmexport v1.2 Maintain schedule of VirtualBox VM export web interface.
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
.vmexport_form {
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
.vmexport_label {
    float           :   left;
    width           :   48%;
    /* background-color:   Yellow; */
    font-weight     :   normal; 
    margin-right: 12px;   

}
/* Attribute for column Input at the right of the screen in the form */
.vmexport_input {
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
$SVER  = "1.2" ;                                                        # Current version number
$URL_MAIN   = '/crud/srv/sadm_server_menu.php?sel=';                    # Maintenance Menu Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Don't Show Create Button





// ================================================================================================
//                      DISPLAY SERVER SCHEDULE FOR VM EXPORT
// con   = Connector Object to Database 
// wrow  = Array containing table row keys/values
// mode  = "[D]" = Display - Only show row content - Can't modify any information
//       = "[U]" = Update  - Display row content & user can modify all fields,except row key
// ================================================================================================
function display_vmschedule($con, $wrow, $mode) {
    $mode = strtoupper(mb_substr($mode, 0, 1)); 
    #$DEBUG = True ;
    #if ($DEBUG) { echo "Mode is $mode" ; } 
    
    # Want to schedule an export of the virtual machine.
    echo "\n\n<div class='vmexport_form'>\n";                           # Start server Form Div
    echo "\n\n<div class='vmexport_label'>Activate VM export schedule</div>\n";
    echo "\n\n<div class='vmexport_input'>\n";

    switch ($mode) {
        # Display Only no modification.
        case 'D':   if ($wrow['srv_export_sched'] == True) {
                        echo "\n<input type='radio' name='scr_export_sched' value='1' ";
                        echo "onclick='javascript: return false;' checked> Yes  ";
                        echo "\n<input type='radio' name='scr_export_sched' value='0' ";
                        echo "onclick='javascript: return false;'> No";
                    }else{
                        if ($DEBUG) { echo "False" ;} 
                        echo "\n<input type='radio' name='scr_export_sched' value='1' ";
                        echo "onclick='javascript: return false;'> Yes  ";
                        echo "\n<input type='radio' name='scr_export_sched' value='0' ";
                        echo "onclick='javascript: return false;' checked > No ";
                    }
                    break;
        # Display and permit modification
        default   : if ($wrow['srv_export_sched'] == True) {
                        echo "\n<input type='radio' name='scr_export_sched' value='1' checked > Yes ";
                        echo "\n<input type='radio' name='scr_export_sched' value='0'> No  ";
                    }else{
                        echo "\n<input type='radio' name='scr_export_sched' value='1'> Yes  ";
                        echo "\n<input type='radio' name='scr_export_sched' value='0' checked > <b>No</b>";
                    }
                    break;
    }
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Move Down one line Now
    
    
    # VMHost name
    echo "\n\n<div class='vmexport_label'>VM Host Name</div>";
    echo "\n<div class='vmexport_input'>";
    if ($mode == 'U') {                                                # Update mode Allow Input
        echo "<input type='text' name='scr_vm_host' size='16' ";        # Set Name for field & Size
        echo " maxlength='15' placeholder='Host of virtual machine' ";  # Set Default & Max Len
        echo " required value='" . sadm_clean_data($wrow['srv_vm_host']);  # Field is required
        echo "' >";                                                     # End of Input 
    }else{
       echo "<input type='text' name='scr_vm_host' readonly size='15' ";   # Set Name Field & Size
       echo "value='" .sadm_clean_data($wrow['srv_vm_host']). "'>"; # Show Current  Value
    }
    echo "</div>";                                                      # << End of srv_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # Open Virtualization Format (0.9, 1.0, 2.0)
    echo "\n\n<div class='vmexport_label'>Open Virtualization Format</div>";
    echo "\n<div class='vmexport_input'>";
    if ($wrow['srv_export_ova'] == 0.9) {
        echo "\n<input type='radio' name='scr_export_ova' value='0.9' checked>0.9 ";
    }else{
        echo "\n<input type='radio' name='scr_export_ova' value='0.9'>0.9 ";
    }
    if ($wrow['srv_export_ova'] == 1.0) {
        echo "\n<input type='radio' name='scr_export_ova' value='1.0' checked>1.0 ";
    }else{
        echo "\n<input type='radio' name='scr_export_ova' value='1.0'>1.0 ";
    }
    if ($wrow['srv_export_ova'] == 2.0) {
        echo "\n<input type='radio' name='scr_export_ova' value='2.0' checked>2.0 ";
    }else{
        echo "\n<input type='radio' name='scr_export_ova' value='2.0'>2.0 ";
    }
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # ----------------------------------------------------------------------------------------------
    # VM Export MONTHS - Specify what month the export need to run - Default is All months
    # srv_export_mth Char Array will contain 'Y' if month is chosen and 'N' if not.
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='vmexport_label'>Month(s) to run the VM export</div>";
    $mth_name = array('Each Month','January','February','March','April','May','June','July','August',
                'September','October','November','December');
    echo "\n<div class='vmexport_input'>";
    echo "<select name='scr_export_mth[]' multiple='multiple' size=6>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 13; $i = $i + 1) {
                        echo "\n<option value='$i' ";
                        if ($i ==0) { echo "selected" ; }
                        echo "/>" . $mth_name[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 13; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_export_mth'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $mth_name[$i] . "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # ----------------------------------------------------------------------------------------------
    # DATE NUMBER in the month (dom) to do the export
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='vmexport_label'>Date(s) to run the export</div>";
    echo "\n<div class='vmexport_input'>";
    echo "\n<select name='scr_export_dom[]' multiple='multiple' size=5>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i' selected/>" . sprintf("%02d",$i) . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 32; $i = $i + 1) {
                        echo "\n<option value='$i'" ;
                        if (substr($wrow['srv_export_dom'],$i,1) == "Y") {echo " selected";}
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
    # Day in the week (dow) to run the export 
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='vmexport_label'>Day(s) to run the export</div>";
    echo "\n<div class='vmexport_input'>";
    $days = array('Daily','Sun','Mon','Tue','Wed','Thu','Fri','Sat');

    echo "\n<select name='scr_export_dow[]' multiple='multiple' size=8>";
    switch ($mode) {
        case 'C' :  for ($i = 0; $i < 8; $i = $i + 1) {
                        echo "\n<option value='$i' ";
                        if ($i == 7) { echo " selected"; }
                        echo "/>" . $days[$i] . "</option>";
                    }
                    break ;
        default  :  for ($i = 0; $i < 8; $i = $i + 1) {
                        echo "\n<option value='$i' " ;
                        if (substr($wrow['srv_export_dow'],$i,1) == "Y") {echo " selected";}
                        if ($mode == 'D') { echo " disabled" ; }
                        echo "/>" . $days[$i];
                        if ($i == 0) { echo "  (Run daily all week)" ;} 
                        echo "</option>";
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # ----------------------------------------------------------------------------------------------
    # Hour to perform the export 
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='vmexport_label'>Time(s) to run the export</div>";
    echo "\n<div class='vmexport_input'>";
    echo " Hour ";
    echo "\n<select name='scr_export_hrs' size=1>";
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
                        if ($wrow['srv_export_hrs'] == $i) {echo " selected";}
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
    echo "\n<select name='scr_export_min' size=1>";
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
                        if ($wrow['srv_export_min'] == $i) {echo " selected";}
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

        # Construct SQL to update database row
        $sql = "UPDATE server SET ";

        # Schedule a VM export.
        $sql = $sql ." srv_export_sched  = '" .sadm_clean_data($_POST['scr_export_sched']). "', ";
        $sql = $sql ." srv_vm_host = '" .sadm_clean_data($_POST['scr_vm_host']). "', ";
        $sql = $sql ." srv_export_ova = '" .sadm_clean_data($_POST['scr_export_ova']). "', ";

        # Month that export can run, Store as a string of 13 characters. 
        # If the first character is a "Y", the it mean that it can run any months.
        # The next 12 char indicate the twelve months ("Y" (Selected) or 'N' (Not Selected)).
        $wmonth=$_POST['scr_export_mth'];                               # Save Chosen Month Array
        if (empty($wmonth)) { $wmonth = "YNNNNNNNNNNNN"; }              # If Array Empty,set default
        $wstr=str_repeat('N',13);                        # Default "N" in all 13 Char
        if (in_array('0',$wmonth)) {                  # If Choose Every Months
            $wstr= "YNNNNNNNNNNNN";                                     # Any mth[0]=Y other mth=N
        }else{                                                          # If Choose Specific Months
            foreach ($wmonth as $p) {                                   # Foreach Month Nb. Selected
                # Replace N to Y for Sel Mth
                $wstr=substr_replace($wstr,'Y',intval($p),1);
            }                                                           # End of ForEach
        }                                                               # End of If
        $pmonth = trim($wstr);                                  # Remove Begin/End Space
        $sql = $sql . "srv_export_mth = '"  . $pmonth  ."', ";          # Insert in SQL Statement


        # Date in the month that the VM can run
        $wdom=$_POST['scr_export_dom'];                                 # Save Choosen Date Array
        if (empty($wdom)) { $wdom="YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN";}  # If Empty Array Set Default
        $wstr=str_repeat('N',32);                        # Default all 32 Char.
        if (in_array('0',$wdom)) {                    # If Choose Every Date
            $wstr="YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN";                   # Set String Accordingly
        }else{                                                          # If Choose Specific Date
            foreach ($wdom as $p) {                                     # For Each Date Selected
                $wstr=substr_replace($wstr,'Y',intval($p),1);
            }                                                           # End of ForEach
        }                                                               # End of If
        $pdom = trim($wstr) ;                                   # Remove Begin/End Space
        $sql = $sql . "srv_export_dom = '"    . $wstr  ."', ";          # Insert in SQL Statement


        # Day of the Week we want to run the VM export (0=All Day 1=Sun 2=Mon)
        $wdow=$_POST['scr_export_dow'];                                 # Save Chosen Day Choose
        #if (empty($wdow)) { for ($i = 0; $i < 8; $i = $i + 1) { $wdow[$i] = $i; } }
        if (empty($wdow)) { $wdow="YNNNNNNN" ;}                         # If Empty Array Set Default
        $wstr=str_repeat('N',8);                         # Default All Week Day to No
        if (in_array('0',$wdow)) {                    # If Choose Every DayOf Week
            $wstr="YNNNNNNN" ;                                          # Set String Accordingly
        }else{                                                          # If Choose specific Days
            foreach ($wdow as $p) {                                     # For Each Day Selected
                $wstr=substr_replace($wstr,'Y',intval($p),1);
            }                                                           # End of ForEach
        }                                                               # End of If
        if ((substr($pdom,0,1) != "Y") and ($wstr != "YNNNNNNN")) {
            $err_msg = "When specific date(s) are specified for the export,\n";
            $err_msg = "$err_msg the day of the week field is change to 'All' (Can't have both)";
            sadm_alert ($err_msg) ;                                # Display Error Msg. Box
            $wstr = "YNNNNNNN" ;                                        # If Specific Date Entered
        }
        $pdow = trim($wstr) ;                                   # Remove Begin/End Space
        $sql = $sql . "srv_export_dow = '"  . $wstr  ."', ";            # Insert in SQL Statement


        # Hour, Minute to perform the export
        $sql = $sql . "srv_export_hrs = '" .sadm_clean_data($_POST['scr_export_hrs']). "', ";
        $sql = $sql . "srv_export_min = '" .sadm_clean_data($_POST['scr_export_min']). "', ";

        # Update Last Edit Date 
        $sql = $sql . "srv_date_edit = '" .date("Y-m-d H:i:s"). "'  ";

        $sql = $sql . "WHERE srv_name     = '" . $_POST['server_key'] ."'; ";
        if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }
        
        # Execute the Row Update SQL ---------------------------------------------------------------
        if ( ! $result=mysqli_query($con,$sql)) {         # Execute Update Row SQL
            $err_line = (__LINE__ -1) ;                                 # Error on preceding line
            $err_msg1 = "Row wasn't updated\nError (";                  # Advise User Message 
            $err_msg2 = strval(mysqli_errno($con)) . ") " ; # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;     # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);  # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
        }else{                                                          # Update done with success
            $err_msg = "Server '" . $_POST['server_key'] . "' updated"; # Advise user of success Msg
            if ($DEBUG) { 
                $err_msg = $err_msg ."\nUpdate SQL Command = ". $sql ;  # Include SQL Stat. in Mess.
                sadm_alert ($err_msg) ;                            # Msg. Error Box for User
            }
        }
        
        # Back to Server List Page
        echo "<script>location.replace('" . $_POST['BACKURL'] . "');</script>"; 
        #?> <script> location.replace("/view/sys/sadm_view_schedule.php"); </script><?php
        exit;
    }

 
# ==================================================================================================
#               INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
# ==================================================================================================

    # CHECK IF THE KEY (serverName) RECEIVED EXIST IN THE DATABASE AND RETRIEVE THE ROW DATA
    if ($DEBUG) { echo "<br>Post isn't Submitted"; }                    # Display Debug Information    
    if ((isset($_GET['sel'])) and ($_GET['sel'] != ""))  {              # If Key Rcv and not Blank   
        $wkey = $_GET['sel'];                                           # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>Key received is '" . $wkey ."'"; }      # Under Debug Show Key Rcv.
        $sql = "SELECT * FROM server WHERE srv_name = '" . $wkey . "'"; # Read server column
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.   
        if ( ! $result=mysqli_query($con,$sql)) {         # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Server (" . $wkey . ") not found.\n";          # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)). ") "; # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;     # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);  # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. for User
            exit;                                                       # Exit - Should not occurs
        }else{                                                          # If row was found
            $row = mysqli_fetch_assoc($result);                 # Read the Associated row
        }
    }else{                                                              # If No Key Rcv or Blank
        $err_msg = "No Key Received - Please Advise" ;                  # Construct Error Msg.
        sadm_alert ($err_msg) ;                                    # Display Error Msg. Box
        ?>
        <script>location.replace("/view/sys/sadm_list_vmexport.php");</script>
        <?php                                                           # Back to VM Export ListPage
        exit ; 
    }

    # 2nd parameters reference the URL where this page was called.
    if ((isset($_GET['back'])) and ($_GET['back'] != ""))  {            # If Value Rcv and not Blank
        $BACKURL = $_GET['back'];                                       # Save Key Rcv to Work Key
        if ($DEBUG) { echo "<br>2nd Parameter received : " .$BACKURL ;} # Under Debug Show 2nd Parm.
    }else{
       $BACKURL = "/view/sys/sadm_list_vmexport.php" ;                  # Where to go back after 
    }


    # DISPLAY PAGE HEADING
    $wserver = $row['srv_name'] . "." . $row['srv_domain'];
    $title1  = "Export schedule for '" .$wserver. "'";                   # Heading 1 Line
    
    
    # Take O/S Update Server Data and return next update to a one line text and date of next update.
    if ($DEBUG) {
        echo "<br>\$row['srv_export_dom'] = '". $row['srv_export_dom'] . "'" ;
        echo "<br>\$row['srv_export_mth'] = '". $row['srv_export_mth'] . "'" ;
        echo "<br>\$row['srv_export_dow'] = '". $row['srv_export_dow'] . "'" ;
        echo "<br>\$row['srv_export_hrs'] = '". $row['srv_export_hrs'] . "'" ;
        echo "<br>\$row['srv_export_min'] = '". $row['srv_export_min'] . "'" ;
    } 
    list ($title2, $DATE_SCHED) = SCHEDULE_TO_TEXT(
            $row['srv_export_dom'], 
            $row['srv_export_mth'],
            $row['srv_export_dow'], 
            $row['srv_export_hrs'], 
            $row['srv_export_min']
        );
    #echo "-2- title2 = " .$title2 . "DATE_SCHED = " . $DATE_SCHED;
    display_lib_heading("NotHome","$title1","$title2",$SVER);

    # Start of the Form - Show O/S Schedule Data for current server
    echo "\n\n<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_vmschedule($con,$row,"U");            # Display Form Default Value
    
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
    std_page_footer($con)                                         # Close MySQL & HTML Footer
?>
