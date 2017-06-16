<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_group_main.php
*   Version     :  1.8
*   Date        :  13 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Web Page used to present list of group that can be edited/deleted.
*                  Option a the top of the list is used to create a new group
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False;                                       # Activate (TRUE) or Deactivate (FALSE) Debug



#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function display_heading($line_title) {

    # Display Page Title
    sadm_page_heading ("$line_title");
    
    # Set Font Size for Table Cell and Table Heading
    echo "<style>\n";
    echo "td { font-size: 11px; }\n";
    echo "th { font-size: 11px; }\n";
    echo "</style>\n";
    
    # Row Creation Button 
    echo "\n<div style='text-align:right'>";
    echo "\n<a href='/crud/sadm_group_create.php'>"; 
    echo "\n<button type='button' class='btn btn-info btn-xs'>";
    echo "\n<span class='glyphicon glyphicon-plus'></span> Create</button></a>";
    echo "\n</div>\n"; 

    # Table creation
    echo "\n<br><center>";                                             
    #echo "\n<table id='sadmTable' class='display compact nowrap'>";
    echo "<table id='sadmTable' class='display compact nowrap' width='55%'>";
        
    # Table Heading
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th class='dt-left'>Code</th>";
    echo "\n<th class='dt-left'>Description</th>";
    echo "\n<th class='dt-center'>Nb. Server using it</th>";
    echo "\n<th class='dt-center'>Default Group</th>";
    echo "\n<th class='dt-center'>Status</th>";
    echo "\n<th class='dt-center'>Update</th>";
    echo "\n<th class='dt-center'>Delete</th>";
    echo "\n</tr>"; 
    echo "\n</thead>\n";

    # Server Table Footer
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th class='dt-left'>Code</th>";
    echo "\n<th class='dt-left'>Description</th>";
    echo "\n<th class='dt-center'>Nb. Server using it</th>";
    echo "\n<th class='dt-center'>Default Group</th>";
    echo "\n<th class='dt-center'>Status</th>";
    echo "\n<th class='dt-center'>Update</th>";
    echo "\n<th class='dt-center'>Delete</th>";
    echo "\n</tr>"; 
    echo "\n</tfoot>\n";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    echo "\n<tr>";  
    
    # Display Code, Description
    echo "\n<td class='dt-left'>"  . $row['grp_code'] . "</td>";        # Display Group Code
    echo "\n<td class='dt-left'>"  . $row['grp_desc'] . "</td>";        # Display Description

    # Display count of servers using the group
    $sql = "SELECT srv_name, srv_group FROM sadm.server ";              # Construct SQL Statement
    $sql = $sql . "WHERE srv_group = '" . $row['grp_code'] . "'; ";     # Isolate to current Group
    $srow = pg_query($sql) ;                                            # Perform the SQL Query
    $count = pg_num_rows($srow);                                        # Get nb. of rows returned
    echo "\n<td class='dt-center'>" ;                                   # Start of Cell
    if ($count > 0) {                                                   # If at least one server
        echo "\n<a href=/sadmin/sadm_view_servers.php?selection=group&value="; # Display Server Using 
        echo $row['grp_code'] . ">" . $count . "</a></td>";             # Display Count Using Group
    }else{                                                              # If Group is not use at all
        echo $count . "</td>";                                          # Display Count without link
    }

    # Is it the default Group ?
    if ($row['grp_default'] == 't') {                                   # If Group if the default
        echo "\n<td class='dt-center'><b>Yes</b></td>";                 # Indicate by a Bold Yes
    }else{                                                              # If not the Default Group   
        echo "\n<td class='dt-center'>No</td>";                         # Display No in cell
    }

    # Group Status (Active or Inactive)                      
    if ($row['grp_status'] == 't') {                                    # Is Group Active
        echo "\n<td class='dt-center'>Active</td>";                     # If so display Active
    }else{                                                              # If not Activate
        echo "\n<td class='dt-center'>Inactive</td>";                   # Display Inactive in Cell
    }

    # Update Button
    echo "\n<td style='text-align: center'>";
    echo "\n<a href=/crud/sadm_group_update.php?sel=" . $row['grp_code'] .">";
    echo "\n<button type='button' class='btn btn-info btn-xs'>";
    echo "\n<span class='glyphicon glyphicon-pencil'></span> Update</button></a>";
    echo "\n</td>";
    
    # Delete Button
    echo "\n<td style='text-align: center'>"; 
    if ($row['grp_default'] != 't') { 
        echo "\n<a href=/crud/sadm_group_delete.php?sel=" . $row['grp_code'] .">";
        echo "\n<button type='button' class='btn btn-info btn-xs'>";
        echo "\n<span class='glyphicon glyphicon-trash'></span> Delete</button></a>";
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
 
    $query = 'SELECT * FROM sadm.group order by grp_code;';
    $result = pg_query($query) or die('Query failed: ' . pg_last_error());
    display_heading("Group Maintenance");                               # Display Page Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body  
    
    # Loop Through Retreived Data and Display each Row
    $count=0;                                                           # Reset Line Counter
    while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>



