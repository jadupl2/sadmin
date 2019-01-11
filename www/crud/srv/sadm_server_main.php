<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_main.php
#   Version     :  1.0
#   Date        :  13 June 2016
#   Requires    :  php, mysql
#   Description :  Web Page used to present list of  Server that can be edited/deleted.
#                  Option a the top of the list is used to create a new  group
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
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
# 2019_01_11 Added: v2.1 Add Model and Serial No. in bubble while on server name.
#
# ==================================================================================================
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');# <head>CSS,JavaScript</Head>
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');

# DataTable Initialisation Function
?>
<script>
    $(document).ready(function() {


        $('#sadmTable').DataTable( {
            "lengthMenu": [[25, 50, 100, -1], [25, 50, ,100, "All"]],
            "bJQueryUI" : true,
            "paging"    : true,
            "ordering"  : true,
            "info"      : true
        } );

    } );
</script>

<?php
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar

#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG         = False ;                                                # Debug Activated True/False
$SVER          = "2.1" ;                                                # Current version number
$URL_CREATE    = '/crud/srv/sadm_server_create.php';                    # Create Page URL
$URL_UPDATE    = '/crud/srv/sadm_server_update.php';                    # Update Page URL
$URL_OSUPDATE  = '/crud/srv/sadm_server_osupdate.php';                  # Update Page URL
$URL_DELETE    = '/crud/srv/sadm_server_delete.php';                    # Delete Page URL
$URL_MAIN      = '/crud/srv/sadm_server_main.php';                      # Maintenance Main Page URL
$URL_MENU      = '/crud/srv/sadm_server_menu.php';                      # Maintenance Main Menu URL
$URL_INFO      = '/view/srv/sadm_view_server_info.php';                 # Servers View Page URL
$URL_HOME      = '/index.php';                                          # Site Main Page
$CREATE_BUTTON = True ;                                                 # Yes Display Create Button




#===================================================================================================
# DISPLAY TWO FIRST HEADING LINES OF PAGE AND SETUP TABLE HEADING AND FOOTER
#===================================================================================================
function setup_table() {
    
    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    #echo '<table id="sadmTable" class="display" cell-border compact row-border wrap width="95%">';   
    #echo '<table  id="sadmTable" cell-border compact row-border wrap width="95%">';   
    echo '<table id="sadmTable" class="display" row-border wrap width="100%">';   
    
    # PAGE TABLE HEADING
    echo "\n<thead>";
    echo "\n<tr>";
    #echo "\n<th dt-head-left>Name</th>";                                # Left Align Header & Body
    echo "\n<th>Name</th>";                                # Left Align Header & Body
    echo "\n<th>O/S</th>";                                 # Left Align Header & Body
    echo "\n<th>Description</th>";                       # Center Header Only
    echo "\n<th dt-center>Cat</th>";                                    # Center Header & Body
    echo "\n<th>Group</th>";                                            # Identify Default Group
    echo "\n<th dt-center>Status</th>";                                 # Center Header & Body
    echo "\n<th dt-center>Sporadic</th>";                               # Center Header & Body
    echo "\n<th dt-center>VM</th>";                                     # Center Header & Body
    echo "\n<th>Update</th>";                                           # Update Button Placement
    echo "\n<th>Delete</th>";                                           # Delete or X button Column
    echo "\n</tr>";
    echo "\n</thead>\n";
    
    # PAGE TABLE FOOTER
    echo "\n<tfoot>";
    echo "\n<tr>";
    #echo "\n<th dt-head-left>Name</th>";                                # Left Align Header & Body
    echo "\n<th>Name</th>";                                # Left Align Header & Body
    #echo "\n<th dt-head-left>Alert</th>";                              # Left Align Header & Body
    echo "\n<th dt-head-left>O/S</th>";                                 # Left Align Header & Body
    echo "\n<th dt-head-center>Description</th>";                       # Center Header Only
    echo "\n<th dt-center>Cat</th>";                                    # Center Header & Body
    echo "\n<th>Group</th>";                                            # Identify Default Group
    echo "\n<th dt-center>Status</th>";                                 # Center Header & Body
    echo "\n<th dt-center>Sporadic</th>";                               # Center Header & Body
    echo "\n<th dt-center>VM</th>";                                     # Center Header & Body
    echo "\n<th>Update</th>";                                           # Update Button Placement
    echo "\n<th>Delete</th>";                                           # Delete or X button Column
    echo "\n</tr>";
    echo "\n</tfoot>\n";
}



#===================================================================================================
#                               DISPLAY ROW DATE RECEIVED ON ONE LINE        
#===================================================================================================
function display_data($con,$row) {
    global $URL_UPDATE, $URL_DELETE, $URL_INFO, $URL_MENU, $URL_OSUPDATE;

    echo "\n<tr>";
    
    # Server Name with Link to Server information page
    echo "\n<td dt-center><a href='" . $URL_INFO . "?host=" . $row['srv_name'];   # Display Server Name
    echo "' data-toggle='tooltip' title='" . $row['srv_desc'] . " - ";
    echo $row['srv_ip'] . " - " . $row['srv_model'] . " - " . $row['srv_serial'] ;
    echo "'>" .$row['srv_name']. "</a></td>";

    # Server O/S Name
    echo "\n<td dt-nowrap>"  . $row['srv_osname'] . "</td>";            # Display O/S Name
    
    # Server Description
    echo "\n<td dt-nowrap>"  . $row['srv_desc']   . "</td>";            # Display Description
    
    # Server Category
    echo "\n<td dt-center>"  . $row['srv_cat']    . "</td>";            # Display Category
    
    # Server Group
    echo "\n<td dt-center>"  . $row['srv_group']  . "</td>";            # Display Group

    # Server is Active ?
    if ($row['srv_active'] == TRUE ) {                                  # Is Server Active
        echo "\n<td style='text-align: center'>Active</td>";            # If so display Active
    }else{                                                              # If not Activate
        echo "\n<td style='text-align: center'>Inactive</td>";          # Display Inactive in Cell
    }

    # Sporadic Status
    if ($row['srv_sporadic'] == TRUE ) {                                # Is Server Sporadic
        echo "\n<td style='text-align: center'>Yes</td>";               # If so display Yes
    }else{                                                              # If not Sporadic
        echo "\n<td style='text-align: center'>No</td>";                # Display No in Cell
    }

    # Virtual or Physical Server
    if ($row['srv_vm'] == TRUE ) {                                      # Is VM Server 
        echo "\n<td style='text-align: center'>Yes</td>";               # If so display Yes
    }else{                                                              # If not Sporadic
        echo "\n<td style='text-align: center'>No</td>";                # Display No in Cell
    }

    # DISPLAY THE UPDATE BUTTON
    echo "\n<td style='text-align: center'>";                           # Align Button in Center row
    echo "\n<a href='" . $URL_MENU . '?sel=' . $row['srv_name'] . "'>";
    echo "\n<button type='button'>Update</button></a>";                 # Display Update Button
    echo "\n</td>";

    # DISPLAY DELETE BUTTON (IF NOT THE DEFAULT CATEGORY)
    echo "\n<td style='text-align: center'>";                           # Align Button in Center row
    if ($row['srv_default'] != TRUE) {                                  # If not Default Group
        echo "\n<a href='" . $URL_DELETE . "?sel=" . $row['srv_name'] ."'>";
        echo "\n<button type='button'>Delete</button></a>";             # Display Delete Button
    }else{
        echo "<img src='/images/nodelete.png' style='width:24px;height:24px;'>\n"; # Show X Button
    }
    echo "\n</td>\n</tr>\n";                                            # End of Table Line
}


# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    display_std_heading("Home","Server Maintenance","","",$SVER,$CREATE_BUTTON,$URL_CREATE,"Create");
    setup_table();                                                      # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body
    
    # LOOP THROUGH RETREIVED DATA AND DISPLAY EACH ROW
    $sql = "SELECT * FROM server ";                                     # Construct SQL Statement
    if ($result = mysqli_query($con,$sql)) {                            # If Results to Display
        while ($row = mysqli_fetch_assoc($result)) {                    # Gather Result from Query
            display_data($con,$row);                                    # Display Row Data
        }
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
