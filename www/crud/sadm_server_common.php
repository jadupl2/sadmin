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
                     if (($crow['cat_code']) == ($wrow['srv_cat'])) {
                        echo "\n<option selected>" . sadm_clean_data($crow['cat_code'])."</option>";
                     }else{
                        echo "\n<option>" . sadm_clean_data($crow['cat_code']) . "</option>";
                     }
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
    # Server Backup ? (Run the backup script on the server)
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Run Backup Script</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'C') { $wrow['srv_backup'] = False ; }                # Set Default Value to False
    switch ($mode) {
        case 'D' : if ($wrow['srv_backup'] == 't') {
                       echo "\n<input type='radio' name='scr_backup' value='1' ";
                       echo "onclick='javascript: return false;' checked> Yes  ";
                       echo "\n<input type='radio' name='scr_backup' value='0' ";
                       echo "onclick='javascript: return false;'> No";
                   }else{
                       echo "\n<input type='radio' name='scr_backup' value='1' ";
                       echo "onclick='javascript: return false;'> Yes  ";
                       echo "\n<input type='radio' name='scr_backup' value='0' ";
                       echo "onclick='javascript: return false;' checked > No";
                   }
                   break ;
        default  : if ($wrow['srv_backup'] == 't') {
                       echo "\n<input type='radio' name='scr_backup' value='1' checked > Yes ";
                       echo "\n<input type='radio' name='scr_backup' value='0'> No";
                   }else{
                       echo "\n<input type='radio' name='scr_backup' value='1'> Yes";
                       echo "\n<input type='radio' name='scr_backup' value='0' checked > No";
                   }
                   break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Monitor the Server ?
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label1'>Monitor</div>";
    echo "\n<div class='server_input1'>";
    if ($mode == 'C') { $wrow['srv_monitor'] = True ; }                 # Set Default Value to True
    switch ($mode) {
        case 'D' : if ($wrow['srv_monitor'] == 't') {
                       echo "\n<input type='radio' name='scr_monitor' value='1' ";
                       echo "onclick='javascript: return false;' checked> Yes  ";
                       echo "\n<input type='radio' name='scr_monitor' value='0' ";
                       echo "onclick='javascript: return false;'> No";
                   }else{
                       echo "\n<input type='radio' name='scr_monitor' value='1' ";
                       echo "onclick='javascript: return false;'> Yes  ";
                       echo "\n<input type='radio' name='scr_monitor' value='0' ";
                       echo "onclick='javascript: return false;' checked > No";
                   }
                   break ;
        default  : if ($wrow['srv_monitor'] == 't') {
                       echo "\n<input type='radio' name='scr_monitor' value='1' checked > Yes ";
                       echo "\n<input type='radio' name='scr_monitor' value='0'> No";
                   }else{
                       echo "\n<input type='radio' name='scr_monitor' value='1'> Yes";
                       echo "\n<input type='radio' name='scr_monitor' value='0' checked > No";
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
    echo "\n\n<div class='server_label2'>Perform O/S update automatically</div>";
    echo "\n<div class='server_input2'>";
    if ($mode == 'C') { $wrow['srv_osupdate'] = True ; }                # Default Value to No
    switch ($mode) {
        case 'D' : if ($wrow['srv_osupdate'] == 't') {
                        echo "\n<input type='radio' name='scr_osupdate' value='1' ";
                        echo "onclick='javascript: return false;' checked> Yes  ";
                        echo "\n<input type='radio' name='scr_osupdate' value='0' ";
                        echo "onclick='javascript: return false;'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_osupdate' value='1' ";
                        echo "onclick='javascript: return false;'> Yes  ";
                        echo "\n<input type='radio' name='scr_osupdate' value='0' ";
                        echo "onclick='javascript: return false;' checked > No ";
                    }
                    break;
        default   : if ($wrow['srv_osupdate'] == 't') {
                        echo "\n<input type='radio' name='scr_osupdate' value='1' checked > Yes ";
                        echo "\n<input type='radio' name='scr_osupdate' value='0'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_osupdate' value='1'> Yes";
                        echo "\n<input type='radio' name='scr_osupdate' value='0' checked > No";
                    }
                    break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # Reboot after O/S Update (Yes/No) ?
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Reboot after O/S update</div>";
    echo "\n<div class='server_input2'>";
    if ($mode == 'C') { $wrow['srv_osupdate_reboot'] = False ; }        # Default Value to No Reboot
    switch ($mode) {
        case 'D' :  if ($wrow['srv_osupdate_reboot'] == 't') {
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='1' ";
                        echo "onclick='javascript: return false;' checked> Yes";
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='0' ";
                        echo "onclick='javascript: return false;'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='1' ";
                        echo "onclick='javascript: return false;'> Yes";
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='0' ";
                        echo "onclick='javascript: return false;' checked > No";
                    }
                    break;
        default  :  if ($wrow['srv_osupdate_reboot'] == 't') {
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='1' checked> Yes";
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='0'> No";
                    }else{
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='1'> Yes";
                        echo "\n<input type='radio' name='scr_osupdate_reboot' value='0' checked> No";
                    }
                    break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # O/S Update Every X Month (1 to 12)
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Update O/S frequency</div>";
    echo "\n<div class='server_input2'>";
    switch ($mode) {
        case 'C' :  echo "\n<select name='scr_osupdate_period' size=1>";
                    for ($mth = 1; $mth < 13; $mth = $mth + 1) {
                        if ($mth == 1) {
                            echo "\n<option value='" . $mth . "' selected>Every Month</option>";
                        }else{
                            echo "\n<option value='" . $mth . "'>Every " . $mth . " Month</option>";
                        }
                    }
                    echo "\n</select>";
                    break ;
        default  :  if ($mode == "U") {
                        echo "\n<select name='scr_osupdate_period' size=1>";
                    }else{
                        echo "\n<select name='scr_osupdate_period' size=1 disabled>";
                    }
                    for ($mth = 1; $mth < 13; $mth = $mth + 1) {
                        if ($mth == $wrow['srv_osupdate_period']) {
                            echo "\n<option value='" . $mth . "' selected>Every " . $mth . " Month</option>";
                        }else{
                            echo "\n<option value='" . $mth . "'>Every " . $mth . " Month</option>";
                        }
                    }
                    break;
    }
    echo "\n</select>";
    echo "\n</div>";

    
    
    # ----------------------------------------------------------------------------------------------
    # O/S Update Starting Month
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Month of first O/S update</div>";
    echo "\n<div class='server_input2'>";
    switch ($mode) {
        case 'C' :  echo "\n<select name='scr_osupdate_start_month' size=1>";
                    echo "\n<option value='1' selected>January</option>";
                    echo "\n<option value='2'>February</option>";
                    echo "\n<option value='3'>March</option>";
                    echo "\n<option value='4'>April</option>";
                    echo "\n<option value='5'>May</option>";
                    echo "\n<option value='6'>June</option>";
                    echo "\n<option value='7'>July</option>";
                    echo "\n<option value='8'>August</option>";
                    echo "\n<option value='9'>September</option>";
                    echo "\n<option value='10'>October</option>";
                    echo "\n<option value='11'>November</option>";
                    echo "\n<option value='12'>December</option>";
                    echo "\n</select>";
                    break ;
        default  :  if ($mode == "U") {
                        echo "\n<select name='scr_osupdate_start_month' size=1>";
                    }else{
                        echo "\n<select name='scr_osupdate_start_month' size=1 disabled>";
                    }
                    if ($mode == 'U') {
                       for ($x = 1; $x <= 12; $x++) {
                            switch ($x) {
                                case 1: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='1' selected>January</option>";
                                        }else{
                                            echo "\n<option value='1'>January</option>";
                                        }
                                        break;
                                case 2: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='2' selected>February</option>";
                                        }else{
                                            echo "\n<option value='2'>February</option>";
                                        }
                                        break;
                                case 3: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='3' selected>March</option>";
                                        }else{
                                            echo "\n<option value='3'>March</option>";
                                        }
                                        break;
                                case 4: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='4' selected>April</option>";
                                        }else{
                                            echo "\n<option value='4'>April</option>";
                                        }
                                        break;
                                case 5: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='5' selected>May</option>";
                                        }else{
                                            echo "\n<option value='5'>May</option>";
                                        }
                                        break;
                                case 6: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='6' selected>June</option>";
                                        }else{
                                            echo "\n<option value='6'>June</option>";
                                        }
                                        break;
                                case 7: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='7' selected>July</option>";
                                        }else{
                                            echo "\n<option value='7'>July</option>";
                                        }
                                        break;
                                case 8: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='8' selected>August</option>";
                                        }else{
                                            echo "\n<option value='8'>August</option>";
                                        }
                                        break;
                                case 9: if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='9' selected>September</option>";
                                        }else{
                                            echo "\n<option value='9'>September</option>";
                                        }
                                        break;
                                case 10:if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='10' selected>October</option>";
                                        }else{
                                            echo "\n<option value='10'>October</option>";
                                        }
                                        break;
                                case 11:if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='11' selected>November</option>";
                                        }else{
                                            echo "\n<option value='11'>November</option>";
                                        }
                                        break;
                                case 12:if ($x == $srv_osupdate_start_month) {
                                            echo "\n<option value='12' selected>December</option>";
                                        }else{
                                            echo "\n<option value='12'>December</option>";
                                        }
                                        break;
                            }
                       }
                    }
                    echo "\n</select>";
    }
    echo "\n</div>";



    # ----------------------------------------------------------------------------------------------
    # O/S Update Week (1,2,3,4) Can be multiple Choice
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Update O/S in week</div>";
    echo "\n<div class='server_input2'>";
    switch ($mode) {
        case 'C'  : echo "<input type='checkbox' name='scr_osupdate_week1' value=True checked />1st  ";
                    echo "<input type='checkbox' name='scr_osupdate_week2' value=True />2nd  ";
                    echo "<input type='checkbox' name='scr_osupdate_week3' value=True/>3rd  ";
                    echo "<input type='checkbox' name='scr_osupdate_week4' value=True />4th  ";
                    break;
        default   : echo "\n<input type='checkbox' name='scr_osupdate_week1' value=True ";
                    if ($wmode == "D") { echo " disabled " ; }
                    if ($wrow['srv_osupdate_week1'] == 't') {echo "checked /> 1st  ";}else{echo "/> 1st  ";}
                    #
                    echo "\n<input type='checkbox' name='scr_osupdate_week2' value=True ";
                    if ($wmode == "D") { echo " disabled " ; }
                    if ($wrow['srv_osupdate_week2'] == 't') {echo "checked /> 2nd  ";}else{echo "/> 2nd  ";}
                    #
                    echo "\n<input type='checkbox' name='scr_osupdate_week3' value=True ";
                    if ($wmode == "D") { echo " disabled " ; }
                    if ($wrow['srv_osupdate_week3'] == 't') {echo "checked /> 3rd  ";}else{echo "/> 3rd  ";}
                    #
                    echo "\n<input type='checkbox' name='scr_osupdate_week4' value=True ";
                    if ($wmode == "D") { echo " disabled " ; }
                    if ($wrow['srv_osupdate_week4'] == 't') {echo "checked /> 4th  ";}else{echo "/> 4th  ";}
                    #
                    break;
    }
    echo "\n</div>";


    # ----------------------------------------------------------------------------------------------
    # O/S Update Day
    # ----------------------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>";
    echo "Update O/S on day";
    echo "</div>";
    echo "\n<div class='server_input2'>";
    if ($mode == 'D') {
       echo "\n<input type='text' name='scr_osupdate_day' readonly placeholder='Development'
            maxlength='15' size='16' value='" . sadm_clean_data($wrow['srv_osupdate_day']). "'/>\n";
    }
    if ($mode == 'C') {
       echo "\n<select name='scr_osupdate_day' size=1>";
       echo "\n<option value='0' selected>Sunday</option>";
       echo "\n<option value='1'>Monday</option>";
       echo "\n<option value='2'>Tuesday</option>";
       echo "\n<option value='3'>Wednesday</option>";
       echo "\n<option value='4'>Thursday</option>";
       echo "\n<option value='5'>Friday</option>";
       echo "\n<option value='6'>Saturday</option>";
       echo "\n</select>";
    }
    if ($mode == 'U') {
       echo "\n<select name='scr_osupdate_day' size=1>";
       for ($x = 0; $x <= 6; $x++) {
           switch ($x) {
                case 0: if ($x == $srv_osupdate_day) {
                           echo "\n<option value='0' selected>Sunday</option>";
                        }else{
                           echo "\n<option value='0'>Sunday</option>";
                        }
                        break;
                case 1: if ($x == $srv_osupdate_day) {
                           echo "\n<option value='1' selected>Monday</option>";
                        }else{
                           echo "\n<option value='1'>Monday</option>";
                        }
                        break;
                case 2: if ($x == $srv_osupdate_day) {
                           echo "\n<option value='2' selected>Tuesday</option>";
                        }else{
                           echo "\n<option value='2'>Tuesday</option>";
                        }
                        break;
                case 3: if ($x == $srv_osupdate_day) {
                           echo "\n<option value='3' selected>Wednesday</option>";
                        }else{
                           echo "\n<option value='3'>Wednesday</option>";
                        }
                        break;
                case 4: if ($x == $srv_osupdate_day) {
                           echo "\n<option value='4' selected>Thursday</option>";
                        }else{
                           echo "\n<option value='4'>Thursday</option>";
                        }
                        break;
                case 5: if ($x == $srv_osupdate_day) {
                           echo "\n<option value='5' selected>Friday</option>";
                        }else{
                           echo "\n<option value='5'>Friday</option>";
                        }
                        break;
                case 6: if ($x == $srv_osupdate_day) {
                           echo "\n<option value='6' selected>Saturday</option>";
                        }else{
                           echo "\n<option value='6'>Saturday</option>";
                        }
                        break;
           }
       }
       echo "\n</select>";
    }
    echo "\n</div>";                                                      # << End of server_input


    # O/S Update Calculated Date -------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Calculated next O/S update date</div>";
    echo "\n<div class='server_input2'>";
    switch ($mode) {
        case 'D' : echo "\n<input type='text' name='scr_osupdate_date' readonly maxlength='10' size='11' ";
                   echo "value='" . sadm_clean_data($wrow['srv_osupdate_date']). "'/>";
                   break;
        default  : echo "\n<input type='text' name='scr_osupdate_date' maxlength='10' size='11' ";
                   echo "value='" . sadm_clean_data($wrow['srv_osupdate_date']). "'/>";
                   break;
    }
    echo "</div>\n";


    # Space Lines    -------------------------------------------------------------------------------
    echo "\n<br><br><br><br><br>\n";


    
    # Last Edit Date -------------------------------------------------------------------------------
    echo "\n\n<div class='server_label2'>Last Edit Date & Time</div>";
    echo "\n<div class='server_input2'>";
    echo "\n<input type='text' name='scr_osupdate_date' readonly maxlength='20' size='20' ";
    echo "value='" . sadm_clean_data($wrow['srv_last_edit_date']). "'/>";
    echo "</div>\n";


    # O/S Update Effective Start Date -------------------------------------------------------------
    #if ($mode == 'U') {
    #    echo "\n\n<div class='server_label2'>O/S Update Start Month</div>";
    #    echo "\n<div class='server_input2'>";
    #    echo "\n<div class='input-append date form_date'>";
    #    echo "<input size='16' name='scr_next_update_date' type='text' " ;
    #    echo "value='" . sadm_clean_data($wrow['srv_next_update_date']). "' readonly>";
    #    echo "<span class='add-on'><i class='icon-th'></i></span>";
    #    #echo '<span class="add-on"><i data-time-icon="icon-time" data-date-icon="icon-calendar"></i></span>';
    #    echo "\n</div>";
    #    #    format: "format: "yyyy/mm/dd" ;
    #        ?>
    <!--
         <script type="text/javascript">
         $(".form_date").datepicker( { pickTime: false } );
        </script>
     -->
    <?php
    #    echo "</div>\n";
    #}

   #Display srv_os_lastupdate,srv_last_edit_date, srv_last_update, srv_creation_date

}


