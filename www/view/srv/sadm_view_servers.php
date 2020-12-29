<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_main.php
#   Version     :  1.0
#   Date        :  13 June 2016
#   Requires    :  php, mysql
#   Description :  Web Page used to present list of  Server that can be edited/deleted.
#                  Option a the top of the list is used to create a new  group
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
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
# ChangeLog
#  Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#  2018_08_10   v2.1 Remove Alert field on page - Not yet ready for release
# 2018_12_15   v2.2 Show Server memory, number of CPU and cpu Speed on home page.
# 2019_01_06 Feature: v2.3 Add link to see Performance Graph of yesterday.
# 2019_01_14 Feature: v2.4 See Server Model and Serial No. when mouse over server name.
# 2019_08_04 Update: v2.5 Added O/S distribution logo instead of name on page
# 2019_08_18 Update: v2.6 Change page heading and some text fields.
# 2019_09_23 Update: v2.7 Add Distribution logo and Version for each servers.
# 2019_10_13 Update: v2.8 Add System Architecture to page.
#@2020_01_13 Update: v2.9 Minor Appearance page change (Nb.Cpu and page width).
#@2020_12_29 Update: v2.10 Show Architecture un-capitalize.
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar

# DataTable Initialization Function
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
$DEBUG          = False ;                                               # Debug Activated True/False
$WVER           = "2.10" ;                                              # Current version number
$URL_CREATE     = '/crud/srv/sadm_server_create.php';                   # Create Page URL
$URL_UPDATE     = '/crud/srv/sadm_server_update.php';                   # Update Page URL
$URL_DELETE     = '/crud/srv/sadm_server_delete.php';                   # Delete Page URL
$URL_MAIN       = '/crud/srv/sadm_server_main.php';                     # Maintenance Main Page URL
$URL_HOME       = '/index.php';                                         # Site Main Page
$URL_SERVER     = '/view/srv/sadm_view_servers.php';                    # View Systems List
$URL_HOST_INFO  = '/view/srv/sadm_view_server_info.php';                # Display Host Info URL
$URL_PERF       = '/view/perf/sadm_server_perf.php';                    # Systems Perf Graph
$CREATE_BUTTON  = False ;                                               # Yes Display Create Button




#===================================================================================================
# DISPLAY TWO FIRST HEADING LINES OF PAGE AND SETUP TABLE HEADING AND FOOTER
#===================================================================================================
function setup_table() {
    echo "\n<br>\n";
    
    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    echo '<table id="sadmTable" class="display" compact row-border no-wrap width="96%">';   
    
    # PAGE TABLE HEADING
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th class='dt-head-left'>Name</th>";                        # Left Align Header & Body
    echo "\n<th class='dt-head-left'>Description</th>";                 # Left Header Only
    echo "\n<th class='dt-head-left'>Arch</th>";                        # Left Header Only
    echo "\n<th class='dt-head-center'>O/S</th>";                       # Center Header Only
    echo "\n<th class='dt-head-center'>Version</th>";                   # Left Header Only
    echo "\n<th class='dt-head-left'>Cat.</th>";                        # Left Align Cat
    echo "\n<th class='dt-head-center'>Memory</th>";                    # Center Header & Body
    echo "\n<th class='dt-head-center'>CPU</th>";                       # Center Header & Body
    echo "\n<th class='dt-head-center'>Status</th>";                    # Center Header & Body
    echo "\n<th class='dt-head-center'>Sporadic</th>";                  # Center Header & Body
    echo "\n<th class='dt-head-center'>VM</th>";                        # Center Header & Body
    echo "\n<th class='dt-head-center'>Perf</th>";                      # Center Header & Body
    echo "\n</tr>";
    echo "\n</thead>\n";
    
    # PAGE TABLE FOOTER
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th class='dt-head-left'>Name</th>";                        # Left Align Header & Body
    echo "\n<th class='dt-head-left'>Description</th>";                 # Left Header Only
    echo "\n<th class='dt-head-left'>Arch</th>";                        # Left Header Only
    echo "\n<th class='dt-head-center'>O/S</th>";                       # Center Header Only
    echo "\n<th class='dt-head-center'>Version</th>";                   # Left Header Only
    echo "\n<th class='dt-head-left'>Cat.</th>";                        # Left Align Cat
    echo "\n<th class='dt-head-center'>Memory</th>";                    # Center Header & Body
    echo "\n<th class='dt-head-center'>CPU</th>";                       # Center Header & Body
    echo "\n<th class='dt-head-center'>Status</th>";                    # Center Header & Body
    echo "\n<th class='dt-head-center'>Sporadic</th>";                  # Center Header & Body
    echo "\n<th class='dt-head-center'>VM</th>";                        # Center Header & Body
    echo "\n<th class='dt-head-center'>Perf</th>";                      # Center Header & Body
    echo "\n</tr>";
    echo "\n</tfoot>\n";
}



#===================================================================================================
#                               DISPLAY ROW DATE RECEIVED ON ONE LINE        
#===================================================================================================
function display_data($count,$con,$row) {
    global $URL_UPDATE, $URL_DELETE, $URL_HOST_INFO, $URL_SERVER, $URL_PERF ;

    echo "\n<tr>";

    # Line Counter
    # echo "\n<td class='dt-left'>"    . $count   . "</td>";              # Display Line Counter

    # Server Name
    echo "\n<td class='dt-left'>" ;
    echo "<a href='" . $URL_HOST_INFO . "?sel=" . $row['srv_name'];
    echo "' data-toggle='tooltip' title='";
    if ($row['srv_model']  != "") { echo "Model "  . $row['srv_model']  . " - " ;} 
    if ($row['srv_serial'] != "") { echo "Serial " . $row['srv_serial'] . " - " ;} 
    echo "IP " . $row['srv_ip'] ."'>" .$row['srv_name']. "</a></td>";

    #echo "' data-toggle='tooltip' title='Model " . $row['srv_model'] . " - Serial ";
    #echo $row['srv_serial'] . " - IP " . $row['srv_ip'] ."'>" .$row['srv_name']. "</a></td>";

    # Display Server Desc.
    echo "\n<td class='dt-left'>"    . $row['srv_desc']   . "</td>";    # Display Description

    # Server Architecture  
    echo "<td class='dt-body-left'>" . $row['srv_arch'] . "</td>\n";  
    
    # Display Operating System Logo
    $WOS   = sadm_clean_data($row['srv_osname']);
    sadm_show_logo($WOS);                                               # Show Distribution Logo

    # Display O/S Version
    echo "\n<td class='dt-center'>" . $row['srv_osversion'] . "</td>";

    // # Display O/S Name and O/S Version
    // echo "\n<td class='dt-center'><a href='" . $URL_SERVER . "?selection=os";  
    // echo "&value=" . $row['srv_osname']  ."'>"  . $row['srv_osname'] . "</a></td>";
    
    // # Display O/S Version
    // echo "\n<td class='dt-center'><a href='" . $URL_SERVER . "?selection=osv";  
    // echo "&value=" . $row['srv_osversion']  ."'>"  . $row['srv_osversion'] . "</a></td>";

    # Display Server Category
    echo "\n<td class='dt-left'><a href='" . $URL_SERVER . "?selection=cat";
    echo "&value=" . $row['srv_cat']  ."'>"  . $row['srv_cat'] . "</a></td>";

    # Display Server Memory
    echo "\n<td class='dt-center'>" . $row['srv_memory'] ." MB </td>";

    # Display Server Number of CPU and Speed
    echo "\n<td class='dt-center'>" . $row['srv_nb_cpu'] . "X" . $row['srv_cpu_speed'] ."Mhz</td>";

    # Display Server Group
    #echo "\n<td class='dt-center'><a href='" . $URL_SERVER . "?selection=group";
    #echo "&value=" . $row['srv_group']  ."'>"  . $row['srv_group'] . "</a></td>";

    # Display if server is Active or Inactive
    if ($row['srv_active'] == TRUE ) {                                  # Is Server Active
        echo "\n<td class='dt-center'>";
        echo "<a href='" .$URL_SERVER. "?selection=all_active'>Active</a></td>";
    }else{                                                              # If not Activate
        echo "\n<td class='dt-center'>";
        echo "<a href='" .$URL_SERVER. "?selection=all_inactive'>Inactive</a></td>";
    }

    # Display if server is Sporadically online or not
    if ($row['srv_sporadic'] == TRUE ) {                                # Is Server Sporadic
        echo "\n<td class='dt-center'>";
        echo "<a href='" .$URL_SERVER. "?selection=all_sporadic'>Yes</a></td>";
    }else{                                                              # If not Sporadic
        echo "\n<td class='dt-center'>";
        echo "<a href='" .$URL_SERVER. "?selection=all_non_sporadic'>No</a></td>";
    }

    # Display if it is a physical or a virtual server
    if ($row['srv_vm'] == TRUE ) {                                      # Is VM Server 
        echo "\n<td class='dt-center'>";
        echo "<a href='" .$URL_SERVER. "?selection=all_vm'>Yes</a></td>";
    }else{                                                              # If not Sporadic
        echo "\n<td class='dt-center'>";
        echo "<a href='" .$URL_SERVER. "?selection=all_physical'>No</a></td>";
    }

    # Show Performance Graph
    if ($row['srv_graph'] == TRUE ) {                                   # If Show Perf. Active 
        $RRD_FILE = SADM_WWW_RRD_DIR ."/".$row['srv_name']."/".$row['srv_name'].".rrd"; # Host RRD File
        if (file_exists($RRD_FILE)) {
            echo "\n<td class='dt-center'>";
            echo "<a href='" .$URL_PERF. "?host=" .$row['srv_name']. "'>Graph</a></td>";
        } else { echo "\n<td class='dt-center'>No Data</td>"; }
    } else { echo "\n<td class='dt-center'>Not Act.</td>"; }                                                           
    

    # Display Memory 
    #echo "\n<td class='dt-center'>" . $row['srv_memory'] . " MB</td>"; # Display Server Alert
    

    # Display CPU And Speed
    #echo "\n<td class='dt-center'>" . $row['srv_nb_cpu'] ."x". $row['srv_cpu_speed'] . " Mhz</td>";

    echo "\n\n</tr>\n";                                                 # End of Table Line
}


# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    # 1st parameter contains type of query that need to be done (all_servers,os,...)   
    if (isset($_GET['selection']) && !empty($_GET['selection'])) { 
        $SELECTION = $_GET['selection'];                                # If Rcv. Save in selection
    }else{
        $SELECTION = 'all_servers';                                     # No Param.= "all_servers"
    }
    if ($DEBUG) { echo "<br>1st Parameter Received is " . $SELECTION; } # Under Debug Display Param.
    

    # 2nd Paramaters is sometime used to specify the type of server received as 1st parameter.
    # Example: http://sadmin/sadmin/sadm_view_servers.php?selection=os&value=centos
    #if (isset($_GET['value']) && !empty($_GET['value'])) {             # If Second Value Specified
    if (isset($_GET['value']))  {              # If Second Value Specified
        if (!empty($_GET['value'])) {
            $VALUE = $_GET['value'];                                    # Save 2nd Parameter Value
        }else{
            $VALUE = NULL;
        }
    if ($DEBUG) { echo "<br>2nd Parameter Received is " . $VALUE; }     # Under Debug Show 2nd Parm.
    }

    # Validate the view option received, Set Page Heading and Retreive Selected Data from Database
    switch ($SELECTION) {
        case 'all_servers'  : 
            $sql = 'SELECT * FROM server order by srv_name;';
            $TITLE = "List of all Systems";
            break;
        case 'host'         : 
            $sql = "SELECT * FROM server where srv_name = '". $VALUE . "';";
            $TITLE = "Info about " . ucwords($VALUE) . " Server";
            break;
        case 'cat'           : 
            $sql = "SELECT * FROM server where srv_cat = '". $VALUE . "' order by srv_name;";
            $TITLE = "Server(s) using '" . ucwords($VALUE) . "' Category";
            break;
        case 'group'           : 
            $sql = "SELECT * FROM server where srv_group = '". $VALUE . "' order by srv_name;";
            $TITLE = "Server(s) using '" . ucwords($VALUE) . "' Group";
            break;
        case 'os'           : 
            if ($VALUE == NULL) {
                $sql = "SELECT * FROM server where srv_osname is NULL order by srv_name;";
            }else{
                $sql = "SELECT * FROM server where srv_osname = '". $VALUE . "' order by srv_name;";
            }
            $TITLE = "List of " . ucwords($VALUE) . " Systems";
            break;
        case 'osv'           : 
            if ($VALUE == NULL) {
                $sql = "SELECT * FROM server where srv_osversion is NULL order by srv_name;";
            }else{
                $sql = "SELECT * FROM server where srv_osversion = '". $VALUE . "' order by srv_name;";
            }
            $TITLE = "List of " . ucwords($VALUE) . " Systems";
            break;
        case 'all_active'   : 
            $sql = 'SELECT * FROM server where srv_active = True order by srv_name;';
            $TITLE = "List of Active Systems";
            break;
        case 'all_inactive' : 
            $sql = 'SELECT * FROM server where srv_active = False order by srv_name;';
            $TITLE = "List of Inactive Systems";
            break;
        case 'all_vm'       : 
            $sql = 'SELECT * FROM server where srv_vm = True order by srv_name;';
            $TITLE = "List of Virtual Systems";
            break;
        case 'all_physical' : 
            $sql = 'SELECT * FROM server where srv_vm = False order by srv_name;';
            $TITLE = "List of Physical Systems";
            break;
            case 'all_sporadic' : 
            $sql = 'SELECT * FROM server where srv_sporadic = True order by srv_name;';
            $TITLE = "List of Sporadic Systems";
            break;
        case 'all_non_sporadic' : 
            $sql = 'SELECT * FROM server where srv_sporadic = False order by srv_name;';
            $TITLE = "List of Non Sporadic Systems";
            break;
        default             : 
            echo "<br>The sort order received (" . $SELECTION . ") is invalid<br>";
            echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
    }
    if ($DEBUG) { echo "<br>SQL is " . $sql ; }                         # Under Debug Display Param.
    
    # Perform the SQL Requested And Display Data
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceding line
        $err_msg1 = "Server (" . $wkey . ") not found.\n";              # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        exit;                                                           # Exit - Should not occurs
    }

    # SHOW PAGE HEADING    
    display_lib_heading("NotHome","$TITLE"," ",$WVER);                  # Display Content Heading
    setup_table();                                                      # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body

    # LOOP THROUGH RETREIVED DATA AND DISPLAY EACH ROW
    $count = 0 ;                                                        # Init server counter to 0
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
        display_data(++$count,$con,$row);                               # Display Row Data
    }

    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
