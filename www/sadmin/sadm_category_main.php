<?php 
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_category_main.php
*   Version  :  1.5
*   Date     :  2 May 2016
*   Requires :  php
*
*   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
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
    echo "<center><br>";
    echo "<a href='/sadmin/sadm_category_create.php'>";
    echo '<button type="button" class="btn btn-default btn-sm">';
    echo '<span class="glyphicon glyphicon-plus"></span> Create Category</button></a>';
    echo "</center>\n";  
    
    echo "<center>\n";                                                  # Table Centered on Page
    echo "<div id='sadmMainBodyPage'>\n";
  
    # Set Font Size for Table Cell and Table Heading
    echo "<style>\n";
    echo "td { font-size: 12px; }\n";
    echo "th { font-size: 13px; }\n";
    echo "</style>\n";
    #echo '<table id="example" class="row-border compact nowrap" cellspacing="0" width="80%">';
    #echo '<table id="example" class="display compact nowrap" border="0" cellpadding="0" cellspacing="0" width="90%">';
    echo '<table border="1" cellpadding="0" cellspacing="0" width="60%">';

    # Server Table Heading
    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th>Code</th>\n";
    echo "<th>Description</th>\n";
    echo "<th>Status</th>\n";
    echo "<th colspan=2 align='center'>Operation</th>\n";
    #echo "<th>Delete Category</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Server Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th>Code</th>\n";
    echo "<th>Description</th>\n";
    echo "<th>Status</th>\n";
    echo "<th colspan=2 align='center'>Operation</th>\n";
    #echo "<th>Delete Category</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";

    # Start of Table Body
    echo "<tbody>\n";
}



#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {

    echo "<tr>\n";  
    echo "<td>" . $row['cat_code'] . "</td>\n";
    echo "<td>" . $row['cat_desc'] . "</td>\n";
    #echo "<td>" . $row['cat_status'] . "</td>\n";
    if ($row['cat_status'] == 't') { echo "<td>Active</td>\n"; }else{ echo "<td>Inactive</td>\n";}
    
    echo "<td><a href=/sadmin/sadm_category_edit.php?sel=" . $row['cat_code'] .">";
    echo '<button type="button" class="btn btn-default btn-sm">';
    #echo '<span class="glyphicon glyphicon-pencil"></span> Edit</button></a></td>';
    echo '<span class="glyphicon glyphicon-pencil"></span></button></a>';
    echo "</td>\n";
    
    echo "<td><a href=/sadmin/sadm_category_delete.php?sel=" . $row['cat_code'] .">";
    echo '<button type="button" class="btn btn-default btn-sm">';
    #echo '<span class="glyphicon glyphicon-trash"></span> Delete</button></a></td>';
    echo '<span class="glyphicon glyphicon-trash"></span></button></a>';
    echo "</td>\n";
    
    echo "</tr>\n"; 
}
    



 

/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/
 
    $query = 'SELECT * FROM sadm.category order by cat_code;';
    $result = pg_query($query) or die('Query failed: ' . pg_last_error());


# Display Page Heading
    $TITLE = "Category Maintenance";
    display_heading("$TITLE");                                          # Display Page Heading
  
    
# Loop Through Retreived Data and Display each Row
    $count=0;                                                           # Reset Line Counter
    while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "</tbody></table></div></center><br><br>\n";                   # End of tbody,table,div
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>



