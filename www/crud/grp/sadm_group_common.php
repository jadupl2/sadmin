<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_group_common.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to create a new server group.
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
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
#
# ==================================================================================================
 

#===================================================================================================
#                                      GLOBAL Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.0" ;                                                        # Current version number
$URL_CREATE = '/crud/grp/sadm_group_create.php';                        # Create Page URL
$URL_UPDATE = '/crud/grp/sadm_group_update.php';                        # Update Page URL
$URL_DELETE = '/crud/grp/sadm_group_delete.php';                        # Delete Page URL
$URL_MAIN   = '/crud/grp/sadm_group_main.php';                          # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page


#===================================================================================================
# DISPLAY TWO FIRST HEADING LINES OF PAGE 
#===================================================================================================
function display_page_heading($prv_page, $title,$CREATE_BUTTON) {
    global $URL_CREATE, $URL_HOME, $SVER;

    # DISPLAY FIRST TWO HEADING LINES OF PAGE
    # FIRST LINE - Display Title & Version No. at the left & Current Date/Time at the right
    echo "\n<div style='float: left;'>${title} " . "$SVER" . "</div>" ; # Display Title & Version No
    echo "\n<div style='float: right;'>" . date('l jS \of F Y, h:i:s A') . "</div>";  
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    
    # LEFT OF SECOND LINE - Display Link to Previous Page or Home Page at the left 
    echo "\n<div style='float: left;'>";                                # Align Left Link Go Back
    if (strtoupper($prv_page) != "HOME") {                              # Parameter Recv. = home
        echo "<a href='javascript:history.go(-1)'>Previous Page</a>";   # URL Go Back Previous Page
    }else{
        echo "<a href='" . $URL_HOME . "'>Home Page</a>";               # URL to Go Back Home Page
    }
    echo "\n</div>"; 
        
    # RIGHT OF SECOND LINE - Display Create Button at the far right
    if ($CREATE_BUTTON) {
        echo "\n<div style='float: right;'>";                           # Div Position Create Button
        echo "\n<a href='" . $URL_CREATE . "'>";                        # URL when Button Press
        echo "\n<button type='button'>Create group</button></a>";    # Create Create Button
        echo "\n</div>\n";                                              # End of Button Div
    }
    echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    echo "\n<br>";
}



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
        echo " required value='" . sadm_clean_data($wrow['grp_code']);  # Field is required
        echo "' >";                                                     # End of Input 
    }else{
       echo "\n<input type='text' name='scr_code' readonly size='11' "; # Set Name for Field & Size
       echo " value='" . sadm_clean_data($wrow['grp_code']). "' >";     # Show Current  Value
    }
    echo "\n</div>";                                                    # << End of grp_input
    
    
    # GROUP DESCRIPTION    
    echo "\n<div class='simple_label'>Group Description</div>";         # Display Name of Column
    echo "\n<div class='simple_input'>";                                # Class for Column Input
    if ($smode == 'DISPLAY') {                                          # If Only Display no input
       echo "\n<input type='text' name='scr_desc' readonly ";           # Set Name and Read Only
       echo " maxlength='25' size='27' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['grp_desc']). "'/>";     # Show Current Value
    }else{
       echo "\n<input type='text' name='scr_desc' required ";           # Set Name & Col. is require
       echo " placeholder='Enter Group Desc.'";                         # Set Default
       echo " maxlength='25' size='27' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['grp_desc']). "'/>";     # Show Current Value
    }
    echo "\n</div>";                                                    # << End of simple_input

    
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

   # LAST UPDATE DATE 
    echo "<div class='simple_label'>Last Update Date</div>";            # Display Name of Column
    echo "<div class='simple_input'>";                                  # Class for Column Input
    echo sadm_clean_data($wrow['grp_date']);                            # Display Last Update Date
    echo "</div>";                                                      # << End of simple_input

    echo "<br></div><br>";                                              # << End of simple_form
}
