<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_schedule.php
#   Version     :  1.5
#   Date        :  18 February 2017
#   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
#   Description :  This page allow to view the servers O/S Update schedule and results.
#   
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
# February 2017 - Jacques DUplessis
#       1.0 Added options for editing server from that page
#           Added O/S Icons
#           Added VM or Physical Server
# December 2017 - Jacques DUplessis
#       2.0 Adapted for MySQL and various look enhancement
# 2018_05_06    JDuplessis
#       2.1 Use Standard view file web page instead of custom vie log pageAdapted for MySQL and various look enhancement
#   
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar

# DataTable Initialisation Function
?>
<script>
    $(document).ready(function() {
        $('#sadmTable').DataTable( {
            "lengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
            "bJQueryUI" : true,
            "paging"    : true,
            "ordering"  : true,
            "info"      : true
        } );
    } );
</script>
<?php


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG         = False ;                                                # Debug Activated True/False
$WVER          = "2.1" ;                                                # Current version number
$URL_CREATE    = '/crud/srv/sadm_server_create.php';                    # Create Page URL
$URL_UPDATE    = '/crud/srv/sadm_server_update.php';                    # Update Page URL
$URL_DELETE    = '/crud/srv/sadm_server_delete.php';                    # Delete Page URL
$URL_MAIN      = '/crud/srv/sadm_server_main.php';                      # Maintenance Main Page URL
$URL_HOME      = '/index.php';                                          # Site Main Page
$URL_SERVER    = '/view/srv/sadm_view_servers.php';                     # View Servers List
$URL_OSUPDATE  = '/crud/srv/sadm_server_osupdate.php';                  # Update Page URL
$URL_VIEW_FILE = '/view/log/sadm_view_file.php';                        # View File Content URL

$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$CREATE_BUTTON = False ;                                                # Yes Display Create Button


#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function setup_table() {

    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    echo '<table id="sadmTable" class="display" compact row-border wrap width="95%">';   

    # Table Heading
    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th>Server</th>\n";
    #echo "<th>Description</th>\n";
    echo "<th>Cat.</th>\n";
    echo "<th class='text-center'>Auto Update</th>\n";
    echo "<th class='text-center'>Reboot After</th>\n";
    echo "<th class='text-center'>Month</th>\n";
    echo "<th class='text-center'>Date</th>\n";
    echo "<th class='text-center'>Day</th>\n";
    echo "<th class='text-center'>Time</th>\n";
    echo "<th class='text-center'>Last Update</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>View Log</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th>Server</th>\n";
    #echo "<th>Description</th>\n";
    echo "<th>Cat.</th>\n";
    echo "<th class='text-center'>Auto Update</th>\n";
    echo "<th class='text-center'>Reboot After</th>\n";
    echo "<th class='text-center'>Month</th>\n";
    echo "<th class='text-center'>Date</th>\n";
    echo "<th class='text-center'>Day</th>\n";
    echo "<th class='text-center'>Time</th>\n";
    echo "<th class='text-center'>Last Update</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th class='text-center'>View Log</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";
 
    echo "<tbody>\n";                                                   # Start of Table Body
}




#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {
    global $URL_HOST_INFO, $URL_VIEW_FILE, $URL_OSUPDATE ; 
    
    echo "<tr>\n";  
    #echo "<td class='dt-center'>" . $count . "</td>\n";  

    # Server Name
    $WOS  = $row['srv_osname'];
    $WVER = $row['srv_osversion'];
    echo "<td>";
    echo "<a href='" . $URL_OSUPDATE . "?sel=" . $row['srv_name'] ;
    echo "' title='$WOS $WVER server - ip address is " . $row['srv_ip'] ." - Click for more info'>" ;
    echo $row['srv_name']  . "</a></td>\n";

    # Description of Server
    #echo "<td>" . nl2br( $row['srv_desc'])  . "</td>\n";
    
    # Category de Serveur
    echo "<td class='dt-center'>" . nl2br( $row['srv_cat']) . "</td>\n";  

    # Operating System Version
    #echo "<td class='dt-center'>" . nl2br( $row['srv_osversion'])   . "</td>\n";  

    # Automatic Update (Yes/No)
    if ($row['srv_update_auto']   == True ) { 
        echo "<td class='dt-center'>Yes</td>\n"; 
    }else{ 
        echo "<td class='dt-center'><B>No</b></td>\n";
    }

    # Reboot after Update (Yes/No)
    if ($row['srv_update_reboot']   == True ) { 
        echo "<td class='dt-center'>Yes</td>\n"; 
    }else{ 
        echo "<td class='dt-center'>No</td>\n";
    }

    # Month that Update can occur
    echo "<td class='dt-center'>";
    if ($row['srv_update_auto']   == True ) { 
        $months = array('Any','Jan','Feb','Mar','Apr','May','Jun','Jul ','Aug','Sep','Oct','Nov','Dec');
        if (trim($row['srv_update_month']) == "YNNNNNNNNNNNN") {
            echo "Any" ;
        }else{
            for ($i = 1; $i < 13; $i = $i + 1) {
                if (substr($row['srv_update_month'],$i,1) == "Y") { echo $months[$i] . ","; }
            }
        }
    }else{
        echo "Manual";
    }    
    echo "</td>\n";  
    
    # Date of the month (1-31) that update can occur
    #echo "<td class='dt-center'>" . $row['srv_update_dom'] . "- ".
    # strlen(trim($row['srv_update_dom'])) .  "</td>\n";  
    echo "<td class='dt-center'>";
    if ($row['srv_update_auto']   == True ) { 
        if (trim($row['srv_update_dom']) == "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN") {
            echo "Any" ;
        }else{
            for ($i = 1; $i < 32; $i = $i + 1) {
                if (substr($row['srv_update_dom'],$i,1) == "Y") { echo $i+1 . ","; }
            }
        }
    }else{
        echo "Manual";
    }    
    echo "</td>\n";

    # Day of the week that update can occur
    echo "<td class='dt-center'>";
    if ($row['srv_update_auto']   == True ) { 
        $days = array('Any','Sun','Mon','Tue','Wed','Thu','Fri','Sat');
        if (trim($row['srv_update_dow']) == "YNNNNNNN") {
            echo "Any" ;
        }else{
            for ($i = 1; $i < 8; $i = $i + 1) {
                if (substr($row['srv_update_dow'],$i,1) == "Y") { echo $days[$i] . ","; }
            }
        }
    }else{
        echo "Manual";
    }    
    echo "</td>\n";
    
    # Hour of the Update
    echo "<td class='dt-center'>";
    if ($row['srv_update_auto']   == True ) { 
        echo sprintf("%02d",$row['srv_update_hour']) . ":";
        echo sprintf("%02d",$row['srv_update_minute']) ;
    }else{
        echo "Man";
    }    
    echo "</td>\n";  
    
    # Last O/S Update Date 
    echo "<td class='dt-center'>" . nl2br( $row['srv_date_osupdate']) . "</td>\n";  
        
    # Last Update Status
    echo "<td class='dt-center'>";
    switch ( strtoupper($row['srv_update_status']) ) {
        case 'S'  : echo "Success" ; break ;
        case 'F'  : echo "Failed"  ; break ;
        case 'R'  : echo "Running" ; break ;
        default   : echo "Unknown" ; break ;
    }
    echo "</td>\n";  
    
    # Display Icon to View Last O/S Update Log
    echo "<td class='dt-center'>";
    $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . $row['srv_name'] . "_sadm_osupdate_client.log";
    if (file_exists($log_name)) {
        echo "<a href='" . $URL_VIEW_FILE . "?&filename=" . $log_name ;
        echo " title='View Update Log'>Log</a>";
    }else{
        echo "N/A";
    }
    echo "</td>\n";  

    echo "</tr>\n"; 
}
    





# ==================================================================================================
#                                      PROGRAM START HERE
# ==================================================================================================

    # The "selection" (1st) parameter contains type of query that need to do (all_servers,os,...)   
    if (isset($_GET['selection']) && !empty($_GET['selection'])) { 
        $SELECTION = $_GET['selection'];                                # If Rcv. Save in selection
    }else{
        $SELECTION = 'all_servers';                                     # No Param.= "all_servers"
    }
    if ($DEBUG) { echo "<br>1st Parameter Received is " . $SELECTION; } # Under Debug Display Param.

    
    # The 2nd Paramaters is sometime used to specify the type of server received as 1st parameter.
    # Example: http://sadmin/sadmin/sadm_view_servers.php?selection=os&value=centos
    if (isset($_GET['value']) && !empty($_GET['value'])) {              # If Second Value Specified
        $VALUE = $_GET['value'];                                        # Save 2nd Parameter Value
        if ($DEBUG) { echo "<br>2nd Parameter Received is " . $VALUE; } # Under Debug Show 2nd Parm.
    }

    # Validate the view option received, Set Page Heading and Retreive Selected Data from Database
    switch ($SELECTION) {
        case 'all_servers'  : 
            $sql = 'SELECT * FROM server order by srv_name;';
            $TITLE = "O/S Update Schedule";
            break;
        case 'host'         : 
            $sql = "SELECT * FROM sadm.server where srv_name = '". $VALUE . "';";
            $TITLE = "O/S Update Schedule for server " . ucwords($VALUE) . " Server";
            break;
        default             : 
            echo "<br>The sort order received (" . $SELECTION . ") is invalid<br>";
            echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
    }
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceeding line
        $err_msg1 = "Server (" . $wkey . ") not found.\n";              # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        exit;                                                           # Exit - Should not occurs
    }
    
    # Display Page Heading
    display_std_heading($BACK_URL,$TITLE,"","",$WVER) ;
    setup_table();                                                      # Create Table & Heading
    
    # Loop Through Retreived Data and Display each Row
    $count=0;   
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
