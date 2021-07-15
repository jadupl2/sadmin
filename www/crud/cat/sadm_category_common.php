<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_category_common.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to create a new server category.
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
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
# 2019_01_22 update: v2.1 New Design & New Dark Mode.
# 2020_01_09 update: v2.2 Web page have now a new lighter look.
# ==================================================================================================
 

#===================================================================================================
#                                      GLOBAL Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.2" ;                                                        # Current version number
$URL_CREATE = '/crud/cat/sadm_category_create.php';                     # Create Page URL
$URL_UPDATE = '/crud/cat/sadm_category_update.php';                     # Update Page URL
$URL_DELETE = '/crud/cat/sadm_category_delete.php';                     # Delete Page URL
$URL_MAIN   = '/crud/cat/sadm_category_main.php';                       # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page


// ================================================================================================
//                      DISPLAY CATEGORY DATA USED IN THE DATA INPUT FORM
//
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_cat_form ($wrow,$mode) {
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase
    echo "\n\n<div class='simple_form'>";                               # Start Category Form Div

    # CATEGORY CODE
    echo "\n<div class='simple_label'>Category Code</div>";             # Display Name of Column
    echo "\n<div class='simple_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') {                                           # If Create Allow Input
        echo "\n<input type='text' name='scr_code' size='11' ";         # Set Name for field & Size
        echo " maxlength='11' placeholder='Cat. Code' ";                # Set Default & Max Len
        #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
        echo " required value='" . sadm_clean_data($wrow['cat_code']);  # Field is required
        echo "' >";                                                     # End of Input 
    }else{
       echo "\n<input type='text' name='scr_code' readonly size='11' "; # Set Name for Field & Size
       #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
       echo " maxlength='11'";
       echo " value='" . sadm_clean_data($wrow['cat_code']). "' >";     # Show Current  Value
    }
    echo "\n</div>";                                                    # << End of simple_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # CATEGORY DESCRIPTION    
    echo "\n<div class='simple_label'>Category Description</div>";      # Display Name of Column
    echo "\n<div class='simple_input'>";                                # Class for Column Input
    if ($smode == 'DISPLAY') {                                          # If Only Display no input
       echo "\n<input type='text' name='scr_desc' readonly ";           # Set Name and Read Only
       echo " maxlength='25' size='27' ";                               # Set Max. Length
       #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
       echo " value='" . sadm_clean_data($wrow['cat_desc']). "'/>";     # Show Current Value
    }else{
       echo "\n<input type='text' name='scr_desc' required ";           # Set Name & Col. is require
       echo " placeholder='Enter Category Desc.'";                      # Set Default
       echo " maxlength='25' size='27' ";                               # Set Max. Length
       #echo "style='background-color:#454c5e; border: solid 1px #454c5e; color:#ffffff; '";
       echo " value='" . sadm_clean_data($wrow['cat_desc']). "'/>";     # Show Current Value
    }
    echo "\n</div>";                                                    # << End of simple_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # CATEGORY ACTIVE ?
    echo "\n<div class='simple_label'>Category Status</div>";           # Display Name of Column
    echo "\n<div class='simple_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') { $wrow['cat_active'] = True ; }            # Default Value = Active
    if ($smode == 'DISPLAY') {                                          # Only Display / No Change
       if ($wrow['cat_active'] == 1) {                                  # If Category is Active
          echo "\n<input type='radio' name='scr_active' value='1' ";    # 1=Active in scr_active
          echo "onclick='javascript: return false;' checked> Active";   # And select Active Option
          echo "\n<input type='radio' name='scr_active' value='0' ";    # 0=Inactive to scr_active
          echo "onclick='javascript: return false;'> Inactive";         # Show Inactive Unselected
       }else{                                               
          echo "\n<input type='radio' name='scr_active' value='1' ";    # If Category is Inactive
          echo "onclick='javascript: return false;'> Active  ";         # 0=Inactive to scr_active
          echo "\n<input type='radio' name='scr_active' value='0' ";    # 1=Active in scr_active
          echo "onclick='javascript: return false;' checked >Inactive"; # select Inactive Option
       }
    }else{                                                              # In Create/Update Mode
       if ($wrow['cat_active'] == 1) {                                  # Create/Upd Mode & Cat Act.
          echo "\n<input type='radio' name='scr_active' value='1' ";    # If Col is active Set to 1
          echo " checked > Active  ";                                   # Checked Field on screen
          echo "\n<input type='radio' name='scr_active' value='0'>";    # Inactive set to 0
          echo " Inactive ";                                            # Uncheck Inactive
       }else{                                                           # If Cat is not Active
          echo "\n<input type='radio' name='scr_active' value='1'>";    # If Category is Inactive
          echo " Active";                                               # Display Uncheck Active
          echo "\n<input type='radio' name='scr_active' value='0' ";    # Check Inactive on Form 
          echo " checked > Inactive";                                   # Checked Field on screen
       }
    }
    echo "\n</div>";                                                    # << End of simple_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
   
    # DEFAULT CATEGORY (YES/NO)
    echo "<div class='simple_label'>Default Category</div>";            # Display Name of Column
    echo "<div class='simple_input'>";                                  # Class for Column Input
    if ($smode == 'CREATE') { $wrow['cat_default'] = False ; }          # Creation  Default Value
    if ($smode == 'DISPLAY') {
        if ($wrow['cat_default'] == '1') {
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
        if ($wrow['cat_default'] == '1') {
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
    echo "\n</div>";                                                    # << End of simple_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
   # LAST UPDATE DATE 
    // echo "<div class='simple_label'>Last Update Date</div>";            # Display Name of Column
    // echo "<div class='simple_input'>";                                  # Class for Column Input
    // echo sadm_clean_data($wrow['cat_date']);                            # Display Last Update Date
    // echo "</div>";                                                      # << End of simple_input
    // echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    echo "<br></div><br>";                                              # << End of simple_form
}
