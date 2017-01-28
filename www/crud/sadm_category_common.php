<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_category_create.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Web Page used to create a new server category.
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
//                      DISPLAY CATEGORY DATA USED IN THE DATA INPUT FORM
//
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content and user can modify all fields, except the row key
// ================================================================================================
function display_cat_form ( $wrow , $mode) {

    echo "<div class='cat_form'>";                                      # Start Category Form Div

    echo "<div class='cat_code'>";                                      # >Start Div For Cat. Code
        echo "<div class='cat_label'>";                                 # >Start Div For Cade Label
        echo "Category Code";                                           # Label Text
        echo "</div>";                                                  # <End of Div For Code Label
        
        echo "<div class='cat_input'>"; 
        if ($mode == 'Create') {
            echo "<input type='text' name='scr_code' size='11' maxlength='10' placeholder='Cat. Code'
                required value='" . sadm_clean_data($wrow['cat_code']). "' >\n";
        }else{
            echo "<input type='text' name='scr_code' readonly size='11' placeholder='Cat. Code'
                 value='" . sadm_clean_data($wrow['cat_code']). "' >\n";   
        }
        echo "</div>";  # << End of cat_code_input
    echo "</div>";      # << End of cat_code
    
    
    // Category Description    
    echo "<div class='cat_desc'>";
        echo "<div class='cat_label'>";   
        echo "Category Description"; 
        echo "</div>"; 
        
        echo "<div class='cat_input'>"; 
        if ($mode == 'Display') {
            echo "<input type='text' name='scr_desc' readonly placeholder='Enter Category Desc.'
                maxlength='25' size='27' value='" . sadm_clean_data($wrow['cat_desc']). "'/>\n";
        }else{
            echo "<input type='text' name='scr_desc' required placeholder='Enter Category Desc.'
                maxlength='25' size='27' value='" . sadm_clean_data($wrow['cat_desc']). "'/>\n";
        }
        echo "</div>";  # << End of cat_input
    echo "</div>";      # << End of cat_desc
    
    
    // Category Status
    echo "<div class='cat_status'>";
        echo "<div class='cat_label'>";   
        echo "Category Status"; 
        echo "</div>"; 
        
        echo "<div class='cat_input'>"; 
        if ($mode == 'Create') { $wrow['cat_status'] = True ; } 
        if ($mode == 'Display') {
            if ($wrow['cat_status'] == 't') {
                echo "<input type='radio' name='scr_status' value='1' onclick='javascript: return false;' checked> Active  \n";
                echo "<input type='radio' name='scr_status' value='0' onclick='javascript: return false;'> Inactive\n";
            }else{
                echo "<input type='radio' name='scr_status' value='1' onclick='javascript: return false;'> Active  \n";
                echo "<input type='radio' name='scr_status' value='0' onclick='javascript: return false;' checked > Inactive\n";
            }
        }else{
            if ($wrow['cat_status'] == 't') {
                echo "<input type='radio' name='scr_status' value='1' checked > Active  \n";
                echo "<input type='radio' name='scr_status' value='0'> Inactive\n";
            }else{
                echo "<input type='radio' name='scr_status' value='1'> Active\n";
                echo "<input type='radio' name='scr_status' value='0' checked > Inactive\n";
            }
        }
        echo "</div>";                                                  # < End of input Div
    echo "</div>";                                                      # < End of Field Div
    
    echo "</div>";                                                      # < End of Form Div
    echo "<br>";
}


