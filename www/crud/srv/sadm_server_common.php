<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_common.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - MySQL
#   Description :  Web Page used to create a new server server.
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
$URL_CREATE = '/crud/srv/sadm_server_create.php';                       # Create Page URL
$URL_UPDATE = '/crud/srv/sadm_server_update.php';                       # Update Page URL
$URL_DELETE = '/crud/srv/sadm_server_delete.php';                       # Delete Page URL
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
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
    echo "</div>"; 
        
    # RIGHT OF SECOND LINE - Display Create Button at the far right
    if ($CREATE_BUTTON) {
        echo "\n<div style='float: right;'>";                           # Div Position Create Button
        echo "\n<a href='" . $URL_CREATE . "'>";                        # URL when Button Press
        echo "\n<button type='button'>Create Server</button></a>";      # Create Create Button
        echo "\n</div>\n";                                              # End of Button Div
    }
    echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
}



// ================================================================================================
//                      DISPLAY SERVER DATA USED IN THE DATA INPUT FORM
//
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content    and user can modify all fields, except the row key
// ================================================================================================
function display_srv_form ($con,$wrow,$mode) {
    $smode = strtoupper($mode);                                         # Make Sure Mode is Upcase
    echo "\n\n<div class='double_form'>\n";                             # Start server Form Div
    
    # Server Name
    echo "\n<div class='double_label'>Server Name</div>";               # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') {                                           # If Create Allow Input
        echo "<input type='text' name='scr_name' size='16' ";           # Set Name for field & Size
        echo " maxlength='15' placeholder='Server Name' ";              # Set Default & Max Len
        echo " required value='" . sadm_clean_data($wrow['srv_name']);  # Field is required
        echo "' >";                                                     # End of Input 
    }else{
       echo "<input type='text' name='scr_name' readonly size='15' ";   # Set Name for Field & Size
       echo " value='" . sadm_clean_data($wrow['srv_name']). "' >";     # Show Current  Value
    }
    echo "</div>";                                                      # << End of srv_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # Server Domain  
    echo "\n<div class='double_label'>Server Domain</div>";             # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') { $wrow['srv_domain'] = SADM_DOMAIN ; }     # Default Value = Active
    if ($smode == 'DISPLAY') {                                          # If Only Display no input
       echo "<input type='text' name='scr_domain' readonly ";           # Set Name and Read Only
       echo " maxlength='30' size='30' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_domain']). "'/>";   # Show Current Value
    }else{
       echo "<input type='text' name='scr_domain' required ";           # Set Name & Col. is require
       echo " placeholder='" . SADM_DOMAIN . "'";                       # Set Default Domain
       echo " maxlength='30' size='30' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_domain']). "'/>";   # Show Domain Current Value
    }
    echo "</div>";                                                      # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # Server Description    
    echo "\n<div class='double_label'>Description</div>";               # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'DISPLAY') {                                          # If Only Display no input
       echo "<input type='text' name='scr_desc' readonly ";             # Set Name and Read Only
       echo " maxlength='30' size='30' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_desc']). "'/>";     # Show Current Value
    }else{
       echo "<input type='text' name='scr_desc' required ";             # Set Name & Col. is require
       echo " placeholder='Enter server Desc.'";                        # Set Default
       echo " maxlength='30' size='30' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_desc']). "'/>";     # Show Current Value
    }
    echo "</div>";                                                      # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # O/S Type
    echo "\n<div class='double_label'>Server O/S Type</div>";
    echo "\n<div class='double_input'>";
    switch ($smode) {
        case 'CREATE' : echo "\n<select name='scr_ostype' size=1>";
                        echo "\n<option value='linux' selected>linux</option>";
                        echo "\n<option value='aix'>aix</option>";
                        break ;
        default       : if ($smode == "UPDATE") {
                            echo "\n<select name='scr_ostype' size=1>";
                        }else{
                            echo "\n<select name='scr_ostype' size=1 disabled>";
                        }
                        if ($wrow['srv_ostype'] == 'linux') {
                            echo "\n<option value='linux' selected>linux</option>";
                            echo "\n<option value='aix'>aix</option>";
                        }else{
                            echo "\n<option value='linux'>linux</option>";
                            echo "\n<option value='aix' selected>aix</option>";
                        }
                        break;
    }
    echo "\n</select>";
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # Server Note
    echo "\n<div class='double_label'>Server Note</div>";               # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'DISPLAY') {                                          # If Only Display no input
       echo "<input type='text' name='scr_note' readonly ";             # Set Name and Read Only
       echo " maxlength='30' size='30' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_note']). "'/>";     # Show Current Value
    }else{
       echo "<input type='text' name='scr_note' ";                      # Set Name & Col. is require
       echo " placeholder='Enter server note' ";                        # Set Default
       echo " maxlength='30' size='30' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_note']). "'/>";     # Show Current Value
    }
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    

    # Server Category
    echo "\n<div class='double_label'>Server Category</div>";           # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    switch ($smode) {
        case 'DISPLAY' :                                                # In Display/Delete Mode
                echo "\n<input type='text' name='scr_cat' readonly ";   # Input Box is ReadOnly
                echo "maxlength='10' size='12' ";                       # Input Size & Box Size
                echo "value='" . sadm_clean_data($wrow['srv_cat']). "'/>";
                break ;                                                 # End of Display/Delete Mode
        case 'CREATE' : 
                echo "\n<select name='scr_cat' size=1>";                # Combo Box 1 Item Display
                $sqlc = 'SELECT * FROM server_category order by cat_code;';
                if ($cresult = mysqli_query($con,$sqlc)) {              # If Results to Display
                    while ($crow = mysqli_fetch_assoc($cresult)) {      # Gather Result from Query
                        if ($crow['cat_default'] == True) {             # If it is the default
                            echo "\n<option selected>" ;                # Make it the Selected Item
                        }else{                                          # If not The Default
                            echo "\n<option>";                          # Just make part of list
                        }
                        echo sadm_clean_data($crow['cat_code']) . "</option>"; # Display Item
                    }
                }
                echo "\n</select>";                                     # End of Select Combo Box
                break ;                                                 # End of Display/Delete Mode
        case 'UPDATE' : 
                echo "\n<select name='scr_cat' size=1>";                # Size of Select Box
                $sqlc = 'SELECT * FROM server_category order by cat_code;';
                if ($cresult = mysqli_query($con,$sqlc)) {              # If Results to Display
                    while ($crow = mysqli_fetch_assoc($cresult)) {      # Gather Result from Query
                        if (($crow['cat_code']) == ($wrow['srv_cat'])){ # If Default Value=Selected
                            echo "\n<option selected>" . sadm_clean_data($crow['cat_code'])."</option>";
                        }else{                                          # If not default Value
                            echo "\n<option>" . sadm_clean_data($crow['cat_code']) . "</option>";
                        }
                    }
                }
                echo "\n</select>";                                     # End of Select Combo Box
                break ;                                                 # End of Display/Delete Mode
    }
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # Server Group
    echo "\n<div class='double_label'>Server Group</div>";              # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    switch ($smode) {
        case 'DISPLAY' :                                                # In Display/Delete Mode
                echo "\n<input type='text' name='scr_group' readonly "; # Input Box is ReadOnly
                echo "maxlength='10' size='12' ";                       # Input Size & Box Size
                echo "value='" . sadm_clean_data($wrow['srv_group']). "'/>";
                break ;                                                 # End of Display/Delete Mode
        case 'CREATE' : 
                echo "\n<select name='scr_group' size=1>";              # Combo Box 1 Item Display
                $sqlc = 'SELECT * FROM server_group order by grp_code;';
                if ($cresult = mysqli_query($con,$sqlc)) {              # If Results to Display
                    while ($crow = mysqli_fetch_assoc($cresult)) {      # Gather Result from Query
                        if ($crow['grp_default'] == True) {             # If it is the default
                            echo "\n<option selected>" ;                # Make it the Selected Item
                        }else{                                          # If not The Default
                            echo "\n<option>";                          # Just make part of list
                        }
                        echo sadm_clean_data($crow['grp_code']) . "</option>"; # Display Item
                    }
                }
                echo "\n</select>";                                     # End of Select Combo Box
                break ;                                                 # End of Display/Delete Mode
        case 'UPDATE' : 
                echo "\n<select name='scr_group' size=1>";              # Size of Select Box
                $sqlc = 'SELECT * FROM server_group order by grp_code;';
                if ($cresult = mysqli_query($con,$sqlc)) {              # If Results to Display
                    while ($crow = mysqli_fetch_assoc($cresult)) {      # Gather Result from Query
                        if (($crow['grp_code']) == ($wrow['srv_group'])){ # If Default Value=Selected
                            echo "\n<option selected>" . sadm_clean_data($crow['grp_code'])."</option>";
                        }else{                                          # If not default Value
                            echo "\n<option>" . sadm_clean_data($crow['grp_code']) . "</option>";
                        }
                    }
                }
                echo "\n</select>";                                     # End of Select Combo Box
                break ;                                                 # End of Display/Delete Mode
    }
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # Server Active ?
    echo "\n<div class='double_label'>Server Status</div>";             # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') { $wrow['srv_active'] = True ; }            # Default Value = Active
    if ($smode == 'DISPLAY') {                                          # Only Display / No Change
       if ($wrow['srv_active'] == 1) {                                  # If server is Active
          echo "\n<input type='radio' name='scr_active' value='1' ";    # 1=Active in scr_active
          echo "onclick='javascript: return false;' checked> Active";   # And select Active Option
          echo "\n<input type='radio' name='scr_active' value='0' ";    # 0=Inactive to scr_active
          echo "onclick='javascript: return false;'> Inactive";         # Show Inactive Unselected
       }else{                                               
          echo "\n<input type='radio' name='scr_active' value='1' ";    # If server is Inactive
          echo "onclick='javascript: return false;'> Active  ";         # 0=Inactive to scr_active
          echo "\n<input type='radio' name='scr_active' value='0' ";    # 1=Active in scr_active
          echo "onclick='javascript: return false;' checked >Inactive"; # select Inactive Option
       }
    }else{                                                              # In Create/Update Mode
       if ($wrow['srv_active'] == 1) {                                  # Create/Upd Mode & Grp Act.
          echo "\n<input type='radio' name='scr_active' value='1' ";    # If Col is active Set to 1
          echo " checked > Active  ";                                   # Checked Field on screen
          echo "\n<input type='radio' name='scr_active' value='0'>";    # Inactive set to 0
          echo " Inactive ";                                            # Uncheck Inactive
       }else{                                                           # If Grp is not Active
          echo "\n<input type='radio' name='scr_active' value='1'>";    # If server is Inactive
          echo " Active";                                               # Display Uncheck Active
          echo "\n<input type='radio' name='scr_active' value='0' ";    # Check Inactive on Form 
          echo " checked > Inactive";                                   # Checked Field on screen
       }
    }
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # Server Tag
    echo "\n<div class='double_label'>Server Tag</div>";                # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'DISPLAY') {                                          # If Only Display no input
       echo "\n<input type='text' name='scr_tag' readonly ";            # Set Name and Read Only
       echo " maxlength='15' size='17' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_tag']). "'/>";      # Show Current Value
    }else{
       echo "\n<input type='text' name='scr_tag' ";                     # Set Name & Col. is require
       echo " placeholder='Enter server tag' ";                         # Set Default
       echo " maxlength='15' size='17' ";                               # Set Max. Length
       echo " value='" . sadm_clean_data($wrow['srv_tag']). "'/>";      # Show Current Value
    }
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # Server Sporadic ?
    echo "\n<div class='double_label'>Sporadically Online</div>";       # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') { $wrow['srv_sporadic'] = False ; }         # Default Value = Active
    if ($smode == 'DISPLAY') {                                          # Only Display / No Change
       if ($wrow['srv_sporadic'] == 1) {                                # If server is Sporadic
          echo "\n<input type='radio' name='scr_sporadic' value='1' ";  # 1=Sporadic in scr_sporadic
          echo "onclick='javascript: return false;' checked> Yes";      # And select Sporadic Yes 
          echo "\n<input type='radio' name='scr_sporadic' value='0' ";  # 0=No to scr_sporadic
          echo "onclick='javascript: return false;'> No";               # Show No Unselected
       }else{                                               
          echo "\n<input type='radio' name='scr_sporadic' value='1' ";  # If server is Inactive
          echo "onclick='javascript: return false;'> Yes  ";            # 0=Inactive to scr_sporadic
          echo "\n<input type='radio' name='scr_sporadic' value='0' ";  # 1=Active in scr_sporadic
          echo "onclick='javascript: return false;' checked >No";       # select No Option
       }
    }else{                                                              # In Create/Update Mode
       if ($wrow['srv_sporadic'] == 1) {                                # Create/Upd Mode
          echo "\n<input type='radio' name='scr_sporadic' value='1' ";  # If Col is Yes Set to 1
          echo " checked > Yes  ";                                      # Checked Field on screen
          echo "\n<input type='radio' name='scr_sporadic' value='0'>";  # Inactive set to 0
          echo " No ";                                                  # Uncheck No
       }else{                                                           # 
          echo "\n<input type='radio' name='scr_sporadic' value='1'>";  # If server is Yes
          echo " Yes";                                                  # Display Uncheck Yes
          echo "\n<input type='radio' name='scr_sporadic' value='0' ";  # Check No on Form 
          echo " checked > No";                                         # Checked Field on screen
       }
    }
    echo "\n</div>\n";                                                  # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    
    # Monitor Server ?
    echo "\n<div class='double_label'>Monitor Server</div>";            # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    if ($smode == 'CREATE') { $wrow['srv_monitor'] = True ; }           # Default Value = Active
    if ($smode == 'DISPLAY') {                                          # Only Display / No Change
       if ($wrow['src_monitor'] == 1) {                                 # If server is Monitored
          echo "\n<input type='radio' name='scr_monitor' value='1' ";   # 1=Monitored in scr_monitor
          echo "onclick='javascript: return false;' checked> Yes";      # And select Monitored Yes 
          echo "\n<input type='radio' name='scr_monitor' value='0' ";   # 0=No to scr_monitor
          echo "onclick='javascript: return false;'> No";               # Show No Unselected
       }else{                                               
          echo "\n<input type='radio' name='scr_monitor' value='1' ";   # If server is Inactive
          echo "onclick='javascript: return false;'> Yes  ";            # 0=Inactive to scr_monitor
          echo "\n<input type='radio' name='scr_monitor' value='0' ";   # 1=Active in scr_monitor
          echo "onclick='javascript: return false;' checked >No";       # select No Option
       }
    }else{                                                              # In Create/Update Mode
       if ($wrow['srv_monitor'] == 1) {                                 # Create/Upd Mode
          echo "\n<input type='radio' name='scr_monitor' value='1' ";   # If Col is Yes Set to 1
          echo " checked > Yes  ";                                      # Checked Field on screen
          echo "\n<input type='radio' name='scr_monitor' value='0'>";   # Inactive set to 0
          echo " No ";                                                  # Uncheck No
       }else{                                                           # 
          echo "\n<input type='radio' name='scr_monitor' value='1'>";   # If server is Yes
          echo " Yes";                                                  # Display Uncheck Yes
          echo "\n<input type='radio' name='scr_monitor' value='0' ";   # Check No on Form 
          echo " checked > No";                                         # Checked Field on screen
       }
    }
    echo "\n</div>\n";                                                  # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    
    echo "\n<hr/>";


    # DISPLAY CREATION DATE 
    echo "\n<div class='double_label'>Creation Date</div>";             # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    echo sadm_clean_data($wrow['srv_date_creation']);                   # Display Last Edit Date
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now


    # LAST EDIT DATE 
    echo "\n<div class='double_label'>Last Edit Date</div>";            # Display Name of Column
    echo "\n<div class='double_input'>";                                # Class for Column Input
    echo sadm_clean_data($wrow['srv_date_edit']);                       # Display Last Edit Date
    echo "\n</div>";                                                    # << End of double_input
    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
  
    echo "\n</div>";                                                    # << End of double_form
    echo "\n<br>\n\n";                                                  # Blank Lines
}
