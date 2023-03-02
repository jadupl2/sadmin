<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_group_common.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to create a new server group.
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
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
# 2019_01_22 update: v2.1 New Design & New Dark Theme.
# 2020_01_07 update: v2.2 Change web page for a lighter look.
# ==================================================================================================
 

#===================================================================================================
#                                      GLOBAL Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.2" ;                                                        # Current version number
$URL_CREATE = '/crud/grp/sadm_group_create.php';                        # Create Page URL
$URL_UPDATE = '/crud/grp/sadm_group_update.php';                        # Update Page URL
$URL_DELETE = '/crud/grp/sadm_group_delete.php';                        # Delete Page URL
$URL_MAIN   = '/crud/grp/sadm_group_main.php';                          # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page


// ================================================================================================
//                      DISPLAY group DATA USED IN THE DATA INPUT FORM
//
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_grp_form ($wrow,$mode) {
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase
    echo "\n<div class='simple_form'>";                                 # Start Group Form Div

    # GROUP CODE
    echo "\n<div class='simple_label'>Group Code</div>";                # Display Name of Column
    echo "\n<div class='simple_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') {                                           # If Create Allow Input
        echo "\n<input type='text' name='scr_code' size='11' ";         # Set Name for field & Size
        echo " maxlength='11' placeholder='Grp. Code' ";                # Set Default & Max Len
        #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
        echo " required value='" . sadm_clean_data($wrow['grp_code']);  # Field is required
        echo "' >";                                                     # End of Input 
    }else{
       echo "\n<input type='text' name='scr_code' readonly size='11' "; # Set Name for Field & Size
       #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
       echo " value='" . sadm_clean_data($wrow['grp_code']). "' >";     # Show Current  Value
    }
    echo "\n</div>";                                                    # << End of grp_input
    echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    
    
    # GROUP DESCRIPTION    
    echo "\n<div class='simple_label'>Group Description</div>";         # Display Name of Column
    echo "\n<div class='simple_input'>";                                # Class for Column Input
    if ($smode == 'DISPLAY') {                                          # If Only Display no input
       echo "\n<input type='text' name='scr_desc' readonly ";           # Set Name and Read Only
       echo " maxlength='25' size='27' ";                               # Set Max. Length
       #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
       echo " value='" . sadm_clean_data($wrow['grp_desc']). "'/>";     # Show Current Value
    }else{
       echo "\n<input type='text' name='scr_desc' required ";           # Set Name & Col. is require
       echo " placeholder='Enter Group Desc.'";                         # Set Default
       echo " maxlength='25' size='27' ";                               # Set Max. Length
       #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
       echo " value='" . sadm_clean_data($wrow['grp_desc']). "'/>";     # Show Current Value
    }
    echo "\n</div>";                                                    # << End of simple_input
    echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    
    
    # GROUP ACTIVE ?
    echo "\n<div class='simple_label'>Group Status</div>";              # Display Name of Column
    echo "\n<div class='simple_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') { $wrow['grp_active'] = True ; }            # Default Value = Active
    if ($smode == 'DISPLAY') {                                          # Only Display / No Change
       if ($wrow['grp_active'] == 1) {                                  # If Group is Active
          echo "\n<input type='radio' name='scr_active' value='1' ";    # 1=Active in scr_active
          echo "onclick='javascript: return false;' checked> Active";   # And select Active Option
          echo "\n<input type='radio' name='scr_active' value='0' ";    # 0=Inactive to scr_active
          echo "onclick='javascript: return false;'> Inactive";         # Show Inactive Unselected
       }else{                                               
          echo "\n<input type='radio' name='scr_active' value='1' ";    # If Group is Inactive
          echo "onclick='javascript: return false;'> Active  ";         # 0=Inactive to scr_active
          echo "\n<input type='radio' name='scr_active' value='0' ";    # 1=Active in scr_active
          echo "onclick='javascript: return false;' checked >Inactive"; # select Inactive Option
       }
    }else{                                                              # In Create/Update Mode
       if ($wrow['grp_active'] == 1) {                                  # Create/Upd Mode & Grp Act.
          echo "\n<input type='radio' name='scr_active' value='1' ";    # If Col is active Set to 1
          echo " checked > Active  ";                                   # Checked Field on screen
          echo "\n<input type='radio' name='scr_active' value='0'>";    # Inactive set to 0
          echo " Inactive ";                                            # Uncheck Inactive
       }else{                                                           # If Grp is not Active
          echo "\n<input type='radio' name='scr_active' value='1'>";    # If Group is Inactive
          echo " Active";                                               # Display Uncheck Active
          echo "\n<input type='radio' name='scr_active' value='0' ";    # Check Inactive on Form 
          echo " checked > Inactive";                                   # Checked Field on screen
       }
    }
    echo "\n</div>";      # << End of simple_input
    echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    
   
    # DEFAULT GROUP (YES/NO)
    echo "<div class='simple_label'>Default Group</div>";               # Display Name of Column
    echo "<div class='simple_input'>";                                  # Class for Column Input
    if ($smode == 'CREATE') { $wrow['grp_default'] = False ; }          # Creation  Default Value
    if ($smode == 'DISPLAY') {
        if ($wrow['grp_default'] == '1') {
           echo "<input type='radio' name='scr_default' value='1' ";
           echo " onclick='javascript: return false;' checked>Yes \n";
           echo "<input type='radio' name='scr_default' value='0' ";
           echo " onclick='javascript: return false;'> No\n";
        }else{
           echo "<input type='radio' name='scr_default' value='1' ";
           echo " onclick='javascript: return false;'> Yes  \n";
           echo "<input type='radio' name='scr_default' value='0' ";
           echo " onclick='javascript: return false;' checked > No\n";
        }
    }else{
        if ($wrow['grp_default'] == '1') {
           echo "<input type='radio' name='scr_default' value='1' ";
           echo " checked> Yes \n";
           echo "<input type='radio' name='scr_default' value='0'> ";
           echo "No\n";
        }else{
           echo "<input type='radio' name='scr_default' value='1'>";
           echo " Yes \n";
           echo "<input type='radio' name='scr_default' value='0' ";
           echo " checked > No\n";
        }
    }
    echo "</div>";                                                      # << End of simple_input
    echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    
   # LAST UPDATE DATE 
    // echo "<div class='simple_label'>Last Update Date</div>";            # Display Name of Column
    // echo "<div class='simple_input'>";                                  # Class for Column Input
    // echo sadm_clean_data($wrow['grp_date']);                            # Display Last Update Date
    // echo "</div>";                                                      # << End of simple_input
    // echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    
    echo "<br></div><br>";                                              # << End of simple_form
}
