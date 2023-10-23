<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_category_main.php
#   Version     :  1.0
#   Date        :  13 June 2016
#   Requires    :  php, mysql
#   Description :  Web Page used to present list of category that can be edited/deleted.
#                  Option a the top of the list is used to create a new category
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
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
# 2019_08_29 Update: v2.1 Use new page heading function.
# ==================================================================================================
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');# <head>CSS,JavaScript</Head>

# DataTable Initialisation Function
?>
<script>
    $(document).ready(function() {
        $('#sadmTable').DataTable( {
            "lengthMenu": [[25, 50, -1], [25, 50, "All"]],
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
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.1" ;                                                        # Current version number
$URL_CREATE = '/crud/cat/sadm_category_create.php';                     # Create Page URL
$URL_UPDATE = '/crud/cat/sadm_category_update.php';                     # Update Page URL
$URL_DELETE = '/crud/cat/sadm_category_delete.php';                     # Delete Page URL
$URL_MAIN   = '/crud/cat/sadm_category_main.php';                       # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$URL_SERVER = '/view/srv/sadm_view_servers.php';                        # View Servers List
$CREATE_BUTTON = True ;                                                 # Yes Display Create Button




#===================================================================================================
# DISPLAY TWO FIRST HEADING LINES OF PAGE AND SETUP TABLE HEADING AND FOOTER
#===================================================================================================
function setup_table() {

    # TABLE CREATION
    echo "\n<div id='SimpleTable'>";                                    # Width Given to Table
    echo "\n<table id='sadmTable' class='display' cell-border compact row-border nowrap width='90%'>";
    
    # PAGE TABLE HEADING
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th dt-head-left>Category</th>";                            # Left Align Header & Body
    echo "\n<th dt-head-center>Description</th>";                       # Center Header Only
    echo "\n<th dt-center>Nb. Server using it</th>";                    # Center Header & Body
    echo "\n<th>Default Category</th>";                                 # Identify Default Category
    echo "\n<th dt-center>Status</th>";                                 # Center Header & Body
    echo "\n<th>Update</th>";                                           # Update Button Placement
    echo "\n<th>Delete</th>";                                           # Delete or X button Column
    echo "\n</tr>";
    echo "\n</thead>\n";

    # PAGE TABLE FOOTER
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th dt-head-left>Category</th>";                            # Left Align Header & Body
    echo "\n<th dt-head-center>Description</th>";                       # Center Header Only
    echo "\n<th dt-center>Nb. Server using it</th>";                    # Center Header & Body
    echo "\n<th>Default Category</th>";                                 # Identify Default Category
    echo "\n<th dt-center>Status</th>";                                 # Center Header & Body
    echo "\n<th>Update</th>";                                           # Update Button Placement
    echo "\n<th>Delete</th>";                                           # Delete or X button Column
    echo "\n</tr>";
    echo "\n</tfoot>\n";
}



#===================================================================================================
#                               DISPLAY ROW DATE RECEIVED ON ONE LINE        
#===================================================================================================
function display_data($con,$row) {
    global $URL_UPDATE, $URL_DELETE, $URL_SERVER;

    echo "\n<tr>";
    echo "\n<td>"  . $row['cat_code'] . "</td>";                        # Display Category Code
    echo "\n<td dt-nowrap>"  . $row['cat_desc'] . "</td>";              # Display Description
    
    # DISPLAY THE NUMBER OF SERVERS USING THAT CATEGORY
    $sql = "SELECT * FROM server WHERE srv_cat='" . $row['cat_code'] . "' ;";
    $count = 0 ;                                                        # Reset Category counter
    if ($cresult = mysqli_query($con,$sql)) {                           # Read Server with this Cat.
        $count = mysqli_num_rows($cresult);                             # Nb. of Row with Category
        mysqli_free_result($cresult);                                   # Clear Result Set
    }
    echo "\n<td style='text-align: center'>" ;                          # Start of Cell
    if ($count > 0) {                                                   # If at least one server
        echo "\n<a href=" . $URL_SERVER . "?selection=cat&value=";      # Display Server Using
        echo $row['cat_code'] . ">" . strval($count) . "</a></td>";     # Display Count Using Cat
    }else{                                                              # If Cat is not use at all
        echo $count . "</td>";                                          # Display Count without link
    }

    # IS IT THE DEFAULT CATEGORY ?
    if ($row['cat_default'] == TRUE) {                                  # If Category if the default
        echo "\n<td style='text-align: center'><b>Yes</b></td>";        # Indicate by a Bold Yes
    }else{                                                              # If not the Default Cat.
        echo "\n<td style='text-align: center'>No</td>";                # Display No in cell
    }

    # CATEGORY STATUS (ACTIVE OR INACTIVE)
    if ($row['cat_active'] == TRUE ) {                                  # Is Category Active
        echo "\n<td style='text-align: center'>Active</td>";            # If so display Active
    }else{                                                              # If not Activate
        echo "\n<td style='text-align: center'>Inactive</td>";          # Display Inactive in Cell
    }

    # DISPLAY THE UPDATE BUTTON
    echo "\n<td style='text-align: center'>";                           # Align Button in Center row
    echo "\n<a href='" . $URL_UPDATE . '?sel=' . $row['cat_code'] . "'>";
    echo "\n<button type='button'>Update</button></a>";                 # Display Update Button
    echo "\n</td>";

    # DISPLAY DELETE BUTTON (IF NOT THE DEFAULT CATEGORY)
    echo "\n<td style='text-align: center'>";                           # Align Button in Center row
    if ($row['cat_default'] != TRUE) {                                  # If not Default Category
        echo "\n<a href='" . $URL_DELETE . "?sel=" . $row['cat_code'] ."'>";
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

    # DISPLAY PAGE HEADING
    $title1="Category Maintenance";                                     # Heading 1 Line
    $title2="[C]reate [R]ead [U]pdate [D]elete";                        # Heading 2 Line
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading

    # DISPLAY THE CREATE BUTTON
    echo "\n<div style='text-align: right ;width: 99%;'>";
    echo "\n<a href='" . $URL_CREATE . "'>";
    echo "\n<button type='button'>Create</button></a>";                 # Display Add Button
    echo "\n</div>";

    setup_table();                                                      # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body
    
    # LOOP THROUGH RETREIVED DATA AND DISPLAY EACH ROW
    $sql = "SELECT * FROM server_category ";                            # Construct SQL Statement
    if ($result = mysqli_query($con,$sql)) {                            # If Results to Display
        while ($row = mysqli_fetch_assoc($result)) {                    # Gather Result from Query
            display_data($con,$row);                                    # Display Row Data
        }
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of CatTable          -->" ;                   # End Of CatTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
