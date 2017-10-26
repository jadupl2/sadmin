<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_category_main.php
*   Version     :  1.8
*   Date        :  13 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Web Page used to present list of category that can be edited/deleted.
*                  Option a the top of the list is used to create a new category
*
*   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
*
*   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
*   of the GNU General Public License as published by the Free Software Foundation; either
*   version 2 of the License, or (at your option) any later version.
*
*   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*   See the GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License along with this program.
*   If not, see <http://www.gnu.org/licenses/>.
* ==================================================================================================
*/
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmHead.php');
?>
<script>
    $(document).ready(function() {
        $('#sadmTable').DataTable( {
            "bJQueryUI": true,
            "paging":   true,
            "ordering": true,
            "info":     true
        } );
    } );
</script>
                



<?php
#            "lengthMenu": [[10, 25, 50, -1], [10, 25, 50, "All"]],
#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False;                                       # Activate (TRUE) or Deactivate (FALSE) Debug
$sadmdb= "";






#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function display_heading($prv_page, $line_title) {

    # Display Right Section Page Heading
    echo "\n<div>";
        # Page Title
        echo "\n<div style='float: left;'>${line_title}</div>" ;
        # Today's Date
        echo "\n<div style='float: right;'>" . date('l jS \of F Y, h:i:s A') . "</div>";
        echo "\n<div style='clear: both;'> </div>";
        
        # Back to Previous Page or Home Page Link 
        if ($prv_page != "home") {
            echo "\n<div style='float: left;'><a href='javascript:history.go(-1)'>Previous Page</a></div>";
         }else{
            echo "\n<div style='float: left;'><a href='/index.php'>Home Page</a></div>"; 
         }
        # Creation Button
        echo "\n<div style='float: right;'>";
        echo "\n<a href='/crud/sadm_category_create.php'>";
        echo "\n<button type='button'>Create Category</button></a>";
        echo "\n</div>\n";
        echo "\n<div style='clear: both;'> </div>";
        echo "\n</div>";
    echo "\n<br>";
    
    # Table creation
    echo "<div id='CatTable'>";
    echo '<table id="sadmTable" class="display cell-border compact row-border nowrap">';   
    
    # Table Heading
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th dt-right>Category</th>";                                # Right Align Header & Body
    echo "\n<th dt-head-center>Description</th>";                       # Center Header Only
    echo "\n<th dt-center>Nb. Server using it</th>";                    # Center Header & Body
    echo "\n<th>Default Category</th>";
    echo "\n<th dt-center>Status</th>";                                 # Center Header & Body
    echo "\n<th>Update</th>";
    echo "\n<th>Delete</th>";
    echo "\n</tr>";
    echo "\n</thead>\n";

    # Table Footer
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th>Category</th>";
    echo "\n<th>Description</th>";
    echo "\n<th>Nb. Server using it</th>";
    echo "\n<th>Default Category</th>";
    echo "\n<th>Status</th>";
    echo "\n<th>Update</th>";
    echo "\n<th>Delete</th>";
    echo "\n</tr>";
    echo "\n</tfoot>\n";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($sadmdb, $count, $row) {
    echo "\n<tr>";
    echo "\n<td>"  . $row['cat_code'] . "</td>";                        # Display Category Code
    echo "\n<td dt-nowrap>"  . $row['cat_desc'] . "</td>";                        # Display Description

    # Display count of servers using the category
    $sql = "SELECT COUNT(*) as count FROM sadm_srv WHERE srv_cat='" . $row['cat_code'] . "' ;";
    $cresult = $sadmdb->query($sql);                                    # Execute the Query
    $crow = $cresult->fetchArray();                                     # Fetch Result
    $count = $crow['count'];                                            # Get Nb Row Returned
    echo "\n<td style='text-align: center'>" ;                          # Start of Cell
    if ($count > 0) {                                                   # If at least one server
        echo "\n<a href=/sadmin/sadm_view_servers.php?selection=cat&value="; # Display Server Using
        echo $row['cat_code'] . ">" . strval($count) . "</a></td>";     # Display Count Using Cat
    }else{                                                              # If Cat is not use at all
        echo $count . "</td>";                                          # Display Count without link
    }

    # Is it the default category ?
    if ($row['cat_default'] == 't') {                                   # If Category if the default
        echo "\n<td style='text-align: center'><b>Yes</b></td>";        # Indicate by a Bold Yes
    }else{                                                              # If not the Default Cat.
        echo "\n<td style='text-align: center'>No</td>";                # Display No in cell
    }

    # Category Status (Active or Inactive)
    if ($row['cat_status'] == 't') {                                    # Is Category Active
        echo "\n<td style='text-align: center'>Active</td>";            # If so display Active
    }else{                                                              # If not Activate
        echo "\n<td style='text-align: center'>Inactive</td>";          # Display Inactive in Cell
    }

    # Update Button
    echo "\n<td style='text-align: center'>";
    echo "\n<a href=/crud/sadm_category_update.php?sel=" . $row['cat_code'] .">";
    echo "\n<button type='button'>Update</button></a>";
    echo "\n</td>";

    # Delete Button
    echo "\n<td style='text-align: center'>";
    if ($row['cat_default'] != 't') {
        echo "\n<a href=/crud/sadm_category_delete.php?sel=" . $row['cat_code'] .">";
        echo "\n<button type='button'>Delete</button></a>";
    }else{
        echo "<img src='/images/nodelete.png' style='width:24px;height:24px;'>\n";
    }
    echo "\n</td>";
    echo "\n</tr>\n";
}






/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/
    echo "<body>";
    echo "<div id='sadmWrapper'>";
    require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeading.php');
    echo "<div id='sadmPageContents'>";
    require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');

    $sadmdb = new SQLite3(SADM_DB_FILE);
    if(!$sadmdb) {
        echo $sadmdb->lastErrorMsg();
        exit("Unable to open Database (SADM_DB_FILE)");
    }

    echo "<div id='sadmRightColumn'>";
    display_heading("home","Category Maintenance");                     # Display Page Heading

    # Loop Through Retreived Data and Display each Row
    echo "\n<tbody>\n";                                                 # Start of Table Body
    $sql = "SELECT * FROM sadm_cat ";                                   # Construct SQL Statement
    $result = $sadmdb->query($sql) or die('Select Category failed');    # Select All rows in table
    $count=0;                                                           # Reset Line Counter
    while ($row = $result->fetchArray()) {
        $count+=1;                                                      # Incr Line Counter
        display_data($sadmdb, $count, $row);                            # Display Next Server
        #print_r ($row) ;
        #var_dump ($row) ;
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of CatTable         -->" ;
    echo "</div> <!-- End of sadmRightColumn  -->" ;
    
    echo "</div> <!-- End of sadmPageContents  -->" ;
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageFooter.php')  ;    # SADM Std EndOfPage Footer
    echo "</div> <!-- End of sadmWrapper  -->" ;
?>
