<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis
*   Title       :  sadm_view_server_info.php
*   Version     :  1.5
*   Date        :  9 Dec 2016
*   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
*   Description :  This page allow to view the servers farm information 
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');

#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = FALSE;                                       # Activate (TRUE) or Deactivate (FALSE) Debug

# ==================================================================================================
#                      DISPLAY SERVER DATA USED IN THE DATA INPUT FORM
#
#  wrow  = Array containing table row keys/values
#  mode  = "[D]isplay" Only show row content - Can't modify any information
#        = "[C]reate"  Display default values and user can modify all fields, except the row key
#        = "[U]pdate"  Display row content and user can modify all fields, except the row key
# ==================================================================================================
function display_server_data ($wrow) {

    # Server Data DIV
    echo "\n\n<div class='server_data'>                           <!-- Start of Data Scr DIV -->";

    # DATA LEFT SIDE DIV
    echo "\n\n<div class='server_leftside'>                       <!-- Start Data LeftSide  -->";
    display_left_side ($wrow);
    echo "\n\n</div>                                              <!-- End of LeftSide Data -->";

    # DATA RIGHT SIDE DIV
    echo "\n\n<div class='server_rightside'>                      <!-- Start RightSide Data  -->";
    display_right_side ($wrow);
    echo "\n\n</div>                                              <!-- End of RightSide Data -->";

    echo "\n</div>                                              <!-- End of Data Scr DIV -->";
    echo "\n<br>                                                <!-- Blank Line Before Footer -->";
}




# ==================================================================================================
#                               DISPLAY LEFT SIDE OF SERVER DATA 
#                           wrow  = Array containing table row keys/values
# ==================================================================================================
function display_left_side ($wrow) {

    # Server Name and Domain
    echo "\n\n<div class='server_left_label'>Name</div>";
    echo "\n<div class='server_left_data'>" . $wrow['srv_name'] . "." . $wrow['srv_domain'] . "</div>";
 
     # Server Description
    echo "\n\n<div class='server_left_label'>Desc.</div>";
    echo "\n<div class='server_left_data'>" . $wrow['srv_desc'] . "</div>";
 
    # Server O/S Type 
    echo "\n\n<div class='server_left_label'>O/S Type</div>";
    echo "\n<div class='server_left_data'>" . $wrow['srv_ostype'] . "</div>";
 
     # Server Description
    echo "\n\n<div class='server_left_label'>O/S Name/Version.</div>";
    echo "\n<div class='server_left_data'>" . $wrow['srv_osname'] . " " . $wrow['srv_osversion'] . "</div>";

}






# ==================================================================================================
#                                 DISPLAY RIGHT SIDE OF SERVER DATA 
#                           wrow  = Array containing table row keys/values
# ==================================================================================================
function display_right_side ($wrow) {

    # Creation Date -------------------------------------------------------------------------------
    echo "\n\n<div class='server_right_label'>Creation date ... </div>";
    echo "\n<div class='server_right_data'>" . $wrow['srv_creation_date'] . "</div>";

    # Last Update Date -----------------------------------------------------------------------------
    echo "\n\n<div class='server_right_label'>Last update date ... </div>";
    #echo "\n<div class='server_right_data'>" . $wrow['srv_last_update'] . "</div>";
    if (empty($wrow['srv_last_update'])) { echo "No Update yet" ; }else{ echo $wrow['srv_last_update']; }
    echo "</div>";

    # Last Edit Date -----------------------------------------------------------------------------
    echo "\n\n<div class='server_right_label'>Last edit date ... </div>";
    echo "\n<div class='server_right_data'>" . $wrow['srv_last_edit_date'] . "</div>";

    # Server Tag -----------------------------------------------------------------------------------
    echo "\n\n<div class='server_right_label'>Server tag ... </div>";
    echo "\n<div class='server_right_data'>" . $wrow['srv_tag'] ."</div>";

}





/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/

    # Get the first Parameter (Should be the server name)
    if (isset($_GET['host']) ) {                                        # Get Parameter Expected
        $HOSTNAME = $_GET['host'];                                      # Parameter is Server Name
        if ($DEBUG) {echo "<br>Parameter received is $HOSTNAME\n";}     # Display Parameter Recv.

        # Construct SQL to Read the row
        $query = "SELECT * FROM sadm.server WHERE srv_name = '" . $HOSTNAME ."';";
        if ($DEBUG) { echo "<br>Select statement is $query\n"; }        # Display SQL Query 
        
         # Execute the SQL to Read the Server Row
         $result = pg_query($connection,$query) ;                       # Perform the SQL select
         $NUMROW = pg_num_rows($result) ;                               # Get Nb of rows returned
         if ((!$result) or ($NUMROW == 0))  {                           # If Server not found
            $err_msg = "<br>Server " . $HOSTNAME . " not found in DB";  # Construct msg to user
            $err_msg = $err_msg . pg_last_error() ;                     # Add Postgresql Error Msg
            if ($DEBUG) {                                               # In Debug Insert SQL in Msg
                $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query ;
            }
            echo $err_msg . "<br>" ;                                    # Print Error Message

            # Give chance to user to see Error Message - Wait for user to press "Go Back" Button 
            echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
            echo "<a href='javascript:history.go(-1)'>";            
            echo "<button type='button' class='btn btn-sm btn-primary'>Go Back</button></a>";
            echo "</form>";
            exit;
         }else{
            if ($DEBUG) {                                               # Debug Print Nb Rows
               echo "<br>Number of row(s) returned is ..." . strval(pg_num_rows($result)) . "... " ;
               echo "<br>Result is ..." . $result . "... " ;
            }
            $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;         # Get Data into row Array
         }
     }else{
         $err_msg = "No Parameter Received - Please Advise Administrator" ;
         # Give chance to user to see Error Message - Wait for user to press "Go Back" Button 
         echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
         echo "<a href='javascript:history.go(-1)'>";            
         echo "<button type='button' class='btn btn-sm btn-primary'>Go Back</button></a>";
         echo "</form>";
         exit ;
     }

    sadm_page_heading ("Information about server " . $row['srv_name']); # Display Page Title
    display_server_data ($row);                                         # Display Server Data
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
