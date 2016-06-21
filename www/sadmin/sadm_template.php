<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_template.php
*   Version     :  2.0
*   Date        :  21 June 2016
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

}
  

/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/
 
# Check if Paramater was received
    if (! isset($_GET['net']) ) { 
       echo "<br>No Subnet received\n<br>Correct the situation and retry request\n";
       echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
       exit ;
    }    
    $SUBNET = $_GET['net'];
        
# Display Page Heading
    $TITLE = "Subnet ${SUBNET}/24";
    display_heading("$TITLE");                                          # Display Page Heading
  

    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
