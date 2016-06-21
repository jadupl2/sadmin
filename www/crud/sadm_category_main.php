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

    # Display Page Title
    sadm_page_heading ("$line_title");                                  # Display Page Title

      
      
    #echo "<center><br>";
    #echo "<a href='/sadmin/sadm_category_create.php'>";
    #echo '<button type="button" class="btn btn-default btn-sm">';
    #echo '<span class="glyphicon glyphicon-plus"></span> Create Category</button></a>';
    #echo "</center>\n";  
    
    echo "<br><center>\n";                                              # Table Centered on Page
  
    #echo "<a href='/sadmin/sadm_category_create.php'>Create Category</a>";
    #echo '<table border="1" cellpadding="0" cellspacing="0" width="60%">';
    echo "<table class='sadm' id='cat_list' align='center'> \n";
    echo "<tr>\n";
    echo "<td class='sadm' id='td_right'  colspan=5><a href='/crud/sadm_category_create.php'>Create a Category</a></td>";
    echo "</tr>\n"; 

    # Table Heading
    echo "<tr>\n";
    echo "<th class='sadm' id='th_center'>Code</th>\n";
    echo "<th class='sadm' id='th_center'>Description</th>\n";
    echo "<th class='sadm' id='th_center'>Status</th>\n";
    echo "<th class='sadm' id='th_center' colspan=2>Operation</th>\n";
    echo "</tr>\n"; 

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
    
    echo "<td><a href=/crud/sadm_category_edit.php?sel=" . $row['cat_code'] .">";
    echo '<button type="button" class="btn btn-default btn-sm">';
    echo '<span class="glyphicon glyphicon-pencil"></span> Update</button></a></td>';
    #echo '<span class="glyphicon glyphicon-pencil"></span></button></a>';
    echo "</td>\n";
    
    echo "<td><a href=/crud/sadm_category_delete.php?sel=" . $row['cat_code'] .">";
    echo '<button type="button" class="btn btn-default btn-sm">';
    echo '<span class="glyphicon glyphicon-trash"></span> Delete</button></a></td>';
    #echo '<span class="glyphicon glyphicon-trash"></span></button></a>';
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
    echo "</tbody></table></center><br><br>\n";                         # End of tbody,table
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>



