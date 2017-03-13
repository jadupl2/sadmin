<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_group_create.php
#   Version     :  1.9
#   Date        :  13 Mars 2017
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Web Page used to create/update/Delete Server Group.
#
#   Copyright (C) 2017 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
#
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                       # Activate (TRUE) or Deactivate (FALSE) Debug


// ================================================================================================
//                      DISPLAY GROUP DATA USED IN THE DATA INPUT FORM
//
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_grp_form ( $wrow , $mode) {

    echo "<div class='_grp_form'>";                                      # Start Group Form Div

    # Group Code
    echo "<div class='grp_code'>";                                      # >Start Div For Group Code
    echo "<div class='grp_label'>Group Code</div>";                                                  # <End of Div For Code Label
    echo "<div class='grp_input'>"; 
    if ($mode == 'Create') {
       echo "<input type='text' name='scr_code' size='11' maxlength='11' placeholder='Group Code'
             required value='" . sadm_clean_data($wrow['grp_code']). "' >\n";
    }else{
       echo "<input type='text' name='scr_code' readonly size='11' placeholder='Group Code'
             value='" . sadm_clean_data($wrow['grp_code']). "' >\n";   
    }
    echo "</div>";  # << End of grp_input
    echo "</div>";  # << End of grp_code
    
    
    # Group Description    
    echo "<div class='grp_desc'>";
    echo "<div class='grp_label'>Group Description</div>"; 
    echo "<div class='grp_input'>"; 
    if ($mode == 'Display') {
       echo "<input type='text' name='scr_desc' readonly placeholder='Enter Group Desc.'
             maxlength='25' size='27' value='" . sadm_clean_data($wrow['grp_desc']). "'/>\n";
    }else{
       echo "<input type='text' name='scr_desc' required placeholder='Enter Group Desc.'
             maxlength='25' size='27' value='" . sadm_clean_data($wrow['grp_desc']). "'/>\n";
    }
    echo "</div>";      # << End of grp_input
    echo "</div>";      # << End of grp_desc

 
    
    # Group Status
    echo "<div class='grp_status'>";
    echo "<div class='grp_label'>Group Status</div>"; 
    echo "<div class='grp_input'>"; 
    if ($mode == 'Create') { $wrow['grp_status'] = True ; } 
    if ($mode == 'Display') {
       if ($wrow['grp_status'] == 't') {
          echo "<input type='radio' name='scr_status' value='1' onclick='javascript: return false;' checked> Active  \n";
          echo "<input type='radio' name='scr_status' value='0' onclick='javascript: return false;'> Inactive\n";
       }else{
          echo "<input type='radio' name='scr_status' value='1' onclick='javascript: return false;'> Active  \n";
          echo "<input type='radio' name='scr_status' value='0' onclick='javascript: return false;' checked > Inactive\n";
       }
    }else{
       if ($wrow['grp_status'] == 't') {
          echo "<input type='radio' name='scr_status' value='1' checked > Active  \n";
          echo "<input type='radio' name='scr_status' value='0'> Inactive\n";
       }else{
          echo "<input type='radio' name='scr_status' value='1'> Active\n";
          echo "<input type='radio' name='scr_status' value='0' checked > Inactive\n";
       }
    }
    echo "</div>";      # << End of grp_input
    echo "</div>";      # << End of grp_status   

   
    # Default Group (Yes/No)
    echo "<div class='grp_default'>";
    echo "<div class='grp_label'>Default Group</div>"; 
    echo "<div class='grp_input'>"; 
    if ($mode == 'Create') { $wrow['grp_default'] = False ; } 
    if ($mode == 'Display') {
        if ($wrow['grp_default'] == 't') {
           echo "<input type='radio' name='scr_default' value='1' onclick='javascript: return false;' checked>Yes \n";
           echo "<input type='radio' name='scr_default' value='0' onclick='javascript: return false;'> No\n";
        }else{
           echo "<input type='radio' name='scr_default' value='1' onclick='javascript: return false;'> Yes  \n";
           echo "<input type='radio' name='scr_default' value='0' onclick='javascript: return false;' checked > No\n";
        }
    }else{
        if ($wrow['grp_default'] == 't') {
           echo "<input type='radio' name='scr_default' value='1' checked> Yes \n";
           echo "<input type='radio' name='scr_default' value='0'> No\n";
        }else{
           echo "<input type='radio' name='scr_default' value='1'> Yes \n";
           echo "<input type='radio' name='scr_default' value='0' checked > No\n";
        }
    }
    echo "</div>";      # << End of grp_input
    echo "</div>";      # << End of grp_default


    echo "</div>";      # << End of grp_form
    echo "<br>";
}


