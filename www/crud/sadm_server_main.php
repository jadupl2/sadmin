<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_server_main.php
*   Version     :  1.8
*   Date        :  28 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Web Page used to present list of server that can be edited/deleted.
*                  Option a the top of the list is used to create a new server
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
    echo "\n<a href='/crud/sadm_server_create.php'>"; 
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
    echo "\n<th class='dt-left'>Server</th>";
    echo "\n<th class='dt-left'>O/S</th>";
    echo "\n<th class='dt-left'>Description</th>";
    echo "\n<th class='dt-center'>Category</th>";
    echo "\n<th class='dt-center'>Group</th>";
    echo "\n<th class='dt-center'>Status</th>";
    echo "\n<th class='dt-center'>Sporadic</th>";
    echo "\n<th class='dt-center'>Update</th>";
    echo "\n<th class='dt-center'>Delete</th>";    
    echo "\n</tr>"; 
    echo "\n</thead>\n";

    # Server Table Footer
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th class='dt-left'>Server</th>";
    echo "\n<th class='dt-left'>O/S</th>";
    echo "\n<th class='dt-left'>Description</th>";
    echo "\n<th class='dt-center'>Category</th>";
    echo "\n<th class='dt-center'>Group</th>";
    echo "\n<th class='dt-center'>Status</th>";
    echo "\n<th class='dt-center'>Sporadic</th>";
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
    
    # Display Code, Description and Status
    echo "\n<td class='dt-left'>"   . $row['srv_name']  . "</td>";

    # Display Operating System Logo
    $WOS   = $row['srv_osname'];
    switch (strtoupper($WOS)) {
            case 'REDHAT' :
                echo "<td class='dt-center'>";
                echo "<a href='http://www.redhat.com' ";
                echo "title='Server $whost is a RedHat server - Visit redhat.com'>";
                echo "<img src='/images/redhat.png' ";
                echo "style='width:24px;height:24px;'></a></td>\n";
                break;
            case 'FEDORA' :
                echo "<td class='dt-center'>";
                echo "<a href='https://getfedora.org' ";
                echo "title='Server $whost is a Fedora server - Visit getfedora.org'>";
                echo "<img src='/images/fedora.png' ";
                echo "style='width:24px;height:24px;'></a></td>\n";
                break;
            case 'CENTOS' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.centos.org' ";
                echo "title='Server $whost is a CentOS server - Visit centos.org'>";
                echo "<img src='/images/centos.png' ";
                echo "style='width:24px;height:24px;'></a></td>\n";
                break;
            case 'UBUNTU' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.ubuntu.com/' ";
                echo "title='Server $whost is a Ubuntu server - Visit ubuntu.com'>";
                echo "<img src='/images/ubuntu.png' ";
                echo "style='width:24px;height:24px;'></a></td>\n";
                break;
            case 'DEBIAN' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.debian.org/' ";
                echo "title='Server $whost is a Debian server - Visit debian.org'>";
                echo "<img src='/images/debian.png' ";
                echo "style='width:24px;height:24px;'></a<</td>\n";
                break;
            case 'RASPBIAN' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.raspbian.org/' ";
                echo "title='Server $whost is a Raspbian server - Visit raspian.org'>";
                echo "<img src='/images/raspbian.png' ";
                echo "style='width:24px;height:24px;'></a></td>\n";
                break;
            case 'SUSE' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.opensuse.org/' ";
                echo "title='Server $whost is a OpenSUSE server - Visit opensuse.org'>";
                echo "<img src='/images/suse.png' ";
                echo "style='width:24px;height:24px;'></a></td>\n";
                break;
            case 'AIX' :
                echo "<td class='dt-center'>";
                echo "<a href='http://www-03.ibm.com/systems/power/software/aix/' ";
                echo "title='Server $whost is an AIX server - Visit Aix Home Page'>";
                echo "<img src='/images/aix.png' ";
                echo "style='width:24px;height:24px;'></a></td>\n";
                break;
            default:
                echo "<td class='dt-center'>";
                echo "<img src='/images/os_unknown.jpg' ";
                echo "style='width:24px;height:24px;'></td>\n";
                break;
    }

    echo "\n<td class='dt-left'>"   . $row['srv_desc']  . "</td>";
    echo "\n<td class='dt-center'>" . $row['srv_cat']   . "</td>";
    echo "\n<td class='dt-center'>" . $row['srv_group'] . "</td>";
    if ($row['srv_active'] == 't') { 
        echo "\n<td class='dt-center'>Active</td>"; 
    }else{ 
        echo "\n<td class='dt-center'>Inactive</td>";
    }
    if ($row['srv_sporadic'] == 't') { 
        echo "\n<td class='dt-center'>Yes</td>"; 
    }else{ 
        echo "\n<td class='dt-center'>No</td>";
    }
    
    # Update Button
    echo "\n<td style='text-align: center'>";
    echo "\n<a href=/crud/sadm_server_update.php?sel=" . $row['srv_name'] .">";
    echo "\n<button type='button' class='btn btn-info btn-xs'>";
    echo "\n<span class='glyphicon glyphicon-pencil'></span> Update</button></a>";
    echo "\n</td>";
    
    # Delete Button
    echo "\n<td style='text-align: center'>"; 
    echo "\n<a href=/crud/sadm_server_delete.php?sel=" . $row['srv_name'] .">";
    echo "\n<button type='button' class='btn btn-info btn-xs'>";
    echo "\n<span class='glyphicon glyphicon-trash'></span> Delete</button></a>";
    echo "\n</td>";
    
    echo "\n</tr>\n"; 
}
    



 

/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/
 
    $query = 'SELECT * FROM sadm.server order by srv_name;';
    $result = pg_query($query) or die('Query failed: ' . pg_last_error());


# Display Page Heading
    $TITLE = "Server Maintenance";
    display_heading("$TITLE");                                          # Display Page Heading
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



