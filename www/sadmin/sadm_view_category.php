<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_view_category.php
*   Version     :  1.8
*   Date        :  13 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Web Page used to present list of category for user with query privilege only.
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
    sadm_page_heading ("$line_title");                                  # Display Page Title
    
    echo "<table id='sadmTable' class='display compact nowrap' width='55%'>";

   # Set Font Size for Table Cell and Table Heading
    echo "<style>\n";
    echo "td { font-size: 13px; }\n";
    echo "th { font-size: 13px; }\n";
    echo "</style>\n";
    
    # Table Heading
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th class='dt-left'>Code</th>";
    echo "\n<th class='dt-left'>Description</th>";
    echo "\n<th class='dt-center'>Status</th>";
    echo "\n</tr>"; 
    echo "\n</thead>";

    # Server Table Footer
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th class='dt-left'>Code</th>";
    echo "\n<th class='dt-left'>Description</th>";
    echo "\n<th class='dt-center'>Status</th>";
    echo "\n</tr>"; 
    echo "\n</tfoot>";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    echo "\n<tr>";  
    echo "\n<td class='dt-left'>"  . $row['cat_code'] . "</td>";
    echo "\n<td class='dt-left'>"  . $row['cat_desc'] . "</td>";
    if ($row['cat_status'] == 't') { 
        echo "\n<td class='dt-center'>Active</td>"; 
    }else{ 
        echo "\n<td class='dt-center'>Inactive</td>";}
    echo "\n</tr>"; 
}
    



 

/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/
    $query = 'SELECT * FROM sadm.category order by cat_code;';
    $result = pg_query($query) or die('Query failed: ' . pg_last_error());

# Display Page Heading
    $TITLE = "Category List";
    display_heading("$TITLE");                                          # Display Page Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body
    
# Loop Through Retreived Data and Display each Row
    while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
        display_data($count, $row);                                     # Display Next Row
    }
    echo "\n</tbody>\n</table><br>\n";                                  # End of tbody,table
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>



