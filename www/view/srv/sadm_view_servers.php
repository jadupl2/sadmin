<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Email       :  sadmlinux@gmail.com
#   Title       :  sadm_server_main.php
#   Version     :  1.0
#   Date        :  13 June 2016
#   Requires    :  php, mysql
#   Description :  Web Page used to present list of  Server that can be edited/deleted.
#                  Option a the top of the list is used to create a new  group
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
#  Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
# 2018_08_10 web v2.1 Remove Alert field on page - Not yet ready for release
# 2018_12_15 web v2.2 Show Server memory, number of CPU and cpu Speed on home page.
# 2019_01_06 web v2.3 Add link to see Performance Graph of yesterday.
# 2019_01_14 web v2.4 See Server Model and Serial No. when mouse over server name.
# 2019_08_04 web v2.5 Added O/S distribution logo instead of name on page
# 2019_08_18 web v2.6 Change page heading and some text fields.
# 2019_09_23 web v2.7 Add Distribution logo and Version for each servers.
# 2019_10_13 web v2.8 Add System Architecture to page.
# 2020_01_13 web v2.9 Minor Appearance page change (Nb.Cpu and page width).
# 2020_12_29 web v3.0 Main server page - Display the first 50 systems instead of 25.
#@2025_01_31 web v3.1 Combine Category & Group & insert the last uptime for each systems.
#@2025_03_04 web v3.2 Change page layour (Add uptime, disk space, cpu,... )
#@2025_04_27 web v3.3 Display VM Hostname where applicable.
#@2025_05_19 web v3.4 Emnlarge uptime column to accmodate offline date/time. 
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
            "lengthMenu": [[50, 100, -1], [50, 100, "All"]],
            "bJQueryUI" : true,
            "paging"    : true,
            "ordering"  : true,
            "info"      : true
        } );
    } );
</script>


<style>
.content-table {
    border-collapse: collapse ;
    margin: 25px 0; 
    font-size: 0.9em;
    min-width: 400px;
    width: 100%;
    border-radius: 5px 5px 0 0 ; 
    overflow: hidden;
    box-shadow: 0 0 20px rgba(0,0,0.15);
}

.content-table thead tr {
    background-color: #009879;
    color: #ffffff;
    text-align: left;
    font-weight: bold;
}

.content-table th,
.content-table td {
// Vertical | Horizontal    padding: 12px 15px;
    padding: 5px 5px;
}

.content-table tbody tr {
    border-bottom: 1px solid #dddddd;
}

.content-table tbody tr:nthof-type(even) {
    background-color: #f3f3f3;
}

.content-table tbody tr.active-row {
    font-weight : bold;
    color: #009879;
}
</style>

<?php


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG          = False ;                                               # Debug Activated True/False
$WVER           = "3.4" ;                                              # Current version number
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
    
    # Table Creation
    #echo "\n<div id='MyTable'>\n"; 
    echo "\n<table class='content-table' border=0>\n" ; 

    # Page Table Heading
    echo "\n<thead>";
    echo "\n<tr align=left bgcolor='grey'>";
    echo "\n<th width=10 align=center>No</th>";
    echo "\n<th width=110 align=left>Name&nbsp;/&nbsp;Arch&nbsp;/&nbsp;Desc.</th>"; 
    echo "\n<th width=120 align=center>Uptime</th>";     
    echo "\n<th align=center>O/S</th>";   
    echo "\n<th width=5 align=center>Ver.</th>";   
    echo "\n<th align=center>Group / Category</th>";
    echo "\n<th align=center>Memory</th>";        
    echo "\n<th align=center>CPU</th>";           
    echo "\n<th align=center>Disk Space</th>";           
    echo "\n<th align=center>Status</th>";        
    echo "\n<th align=center>Sporadic</th>";      
    echo "\n<th align=center>VM Host</th>";            
    echo "\n<th align=center>Perf</th>";          
    echo "\n</tr>";
    echo "\n</thead>\n";
    
    # Page Table Footer
    echo "\n<tfoot>";
    echo "\n<tr align=left bgcolor='grey'>";
    echo "\n<th width=10>No</th>";
    echo "\n<th width=110 align=left>Name&nbsp;/&nbsp;Arch&nbsp;/&nbsp;Desc.</th>"; 
    echo "\n<th width=120 align=center>Uptime</th>";     
    echo "\n<th align=center>O/S</th>";   
    echo "\n<th width=5 align=center>Ver.</th>";   
    echo "\n<th align=center>Group / Category</th>";
    echo "\n<th align=center>Memory</th>";        
    echo "\n<th align=center>CPU</th>";           
    echo "\n<th align=center>Disk Space</th>";           
    echo "\n<th align=center>Status</th>";        
    echo "\n<th align=center>Sporadic</th>";      
    echo "\n<th align=center>VM Host</th>";            
    echo "\n<th align=center>Perf</th>";          
    echo "\n</tr>";
    echo "\n</tfoot>\n";
}



#===================================================================================================
# Display of one row of data received.
#===================================================================================================
function display_data($count,$con,$row) {

    global $URL_UPDATE, $URL_DELETE, $URL_HOST_INFO, $URL_SERVER, $URL_PERF ;
    echo "\n<tr align=left bgcolor='lightgrey'>\n"; 
    
    # Line counter
    echo "\n<td>$count</td>\n";                                     

    # System Name / Architecture / Description
    echo "\n<td>" ;
    echo "<a href='" .$URL_HOST_INFO. "?sel=" .$row['srv_name']. "' data-toggle='tooltip' title='";
    echo "Note: " . $row['srv_note']. "\n" ; 
    echo "Model: ". ucfirst(strtolower($row['srv_model'])) ."\nIP: ". $row['srv_ip'] . "'>\n" ;
    echo $row['srv_name']. "</a>&nbsp;&nbsp;" .$row['srv_arch'] ;
    echo "\n<br>" . $row['srv_desc'] ;
    echo "\n</td>";   

    # Display System Uptime
    $wordList = explode (" ", $row['srv_uptime']) ;
    if ( strtoupper($wordList[0]) == "OFF" ) { 
        echo "\n<td align=center>Offline since\n" . $wordList[1] ."&nbsp;". $wordList[2] . "</td>";
    }else{
        echo "\n<td align=center> " . $row['srv_uptime'] . "</td>";   
    }


    # Display Operating System Logo
    echo "<td align=center>";
    $WOS = sadm_clean_data($row['srv_osname']);
    list($ipath, $iurl, $ititle) = sadm_return_logo ($WOS) ;            # Get Distribution Logo
    echo "<a href='". $iurl . "' ";
    echo "title='" . $ititle . "'>";
    echo "<img src='" . $ipath . "' ";
    echo "style='width:32px;height:32px;'>"; 
    echo "</a></td>";

    # Display O/S Version
    echo "<td width=5 align=center>" . $row['srv_osversion'] . "</td>";

    # Display System Group & Category
    echo "\n<td align=center>"; 
    echo "\n<a href='" . $URL_SERVER . "?selection=group&value=" .$row['srv_group']. "'>" .$row['srv_group']. "</a>";
    echo "&nbsp;/&nbsp;";
    echo "\n<a href='" . $URL_SERVER . "?selection=cat&value="   .$row['srv_cat'].   "'>" .$row['srv_cat']. "</a>";
    echo "\n</td>";

    # Display System Memory
    echo "\n<td align=center>";
    $MEMORY_SIZE = $row['srv_memory'] ;
    if ( $MEMORY_SIZE <  1000 ) { 
        $MEMORY_SIZE = round($row['srv_memory']) ;
        $MEMORY_UNIT = "MB" ; 
    } 
    if ( $MEMORY_SIZE >= 1000 ) { 
        $MEMORY_SIZE = round($row['srv_memory'] / 1024) ;
        if ( $MEMORY_SIZE == 7  ) { $MEMORY_SIZE=8  ; } ;
        if ( $MEMORY_SIZE == 31 ) { $MEMORY_SIZE=32 ; } ;
        if ( $MEMORY_SIZE == 23 ) { $MEMORY_SIZE=24 ; } ; 
        $MEMORY_UNIT = "GB" ;
    }
        echo "$MEMORY_SIZE $MEMORY_UNIT" ;
    echo "\n</td>" ;

    
    # Display Nb. of CPU and Speed
    echo "\n<td align=center>";
    $CPU_NUM   = $row['srv_nb_cpu'] ;
    $CPU_SPEED = $row['srv_cpu_speed'] ;  
    if ( $CPU_SPEED <  1000 ) { 
        $CPU_SPEED = round($row['srv_cpu_speed']) ;
        $CPU_UNIT = "MHz" ; 
    }else{
        $CPU_SPEED = round($row['srv_cpu_speed'] / 1000) ;
        $CPU_SPEED = $row['srv_cpu_speed'] / 1000 ;
        $CPU_UNIT = "GHz" ;
    }
    $CPU_NUM = $CPU_NUM * $row['srv_core_per_socket'] ;    
    $CPU_NUM = $CPU_NUM * $row['srv_thread_per_core'] ;
    $etooltip="CPU : " .$row['srv_nb_cpu']. " -  Core per socket : " .$row['srv_core_per_socket']. " - Thread per core : " .$row['srv_thread_per_core'] ;
    echo "<span data-toggle='tooltip' title='" . $etooltip . "'>"; 
    echo $CPU_NUM ."&nbsp;X&nbsp;" . $CPU_SPEED . "&nbsp;" . $CPU_UNIT ;
    echo "\n</span></td>" ;


    # Display Disk space available
    $DISK_SPACE = 0 ; 
    if ( ! empty($row['srv_disks_info'])) {                             # If Some disk(s) on system
        $DISK_ARRAY  = explode(",",$row['srv_disks_info']);             # Put disks list in array
        if (count($DISK_ARRAY) > 0) {                                   # If Array is not empty
           for ($i = 0; $i < count($DISK_ARRAY); ++$i) {                # Process one disk at a time
               list($DISK_DEV,$DISK_SIZE) = explode("|", $DISK_ARRAY[$i] ); # Split disk name & size
               $DISK_SPACE += $DISK_SIZE ;                              # Add GB to total disk space
           }
           if ( $DISK_SPACE > 1024 ) {                                  # If more than 1024 MB
                $DISK_SPACE = ($DISK_SPACE /1024) ;                     # Convert from MB to GB
                $DISK_UNIT = "GB";                                      # Unit is going to be GB now
           }
           if ( $DISK_SPACE > 1024 ) {                                  # If more than 1024 GB    
                $DISK_SPACE = ($DISK_SPACE /1024) ;                     # Convert from GB to TB
                $DISK_UNIT = "TB";                                      # Unit is going to be TB now
           }
           $etooltip="Disk(s) : " . $row['srv_disks_info']  ;
           #str_replace("|", " ",$etooltip);
           echo "\n<td align=center>"; 
           echo "<span data-toggle='tooltip' title='" . str_replace("|", " ",$etooltip) . "'>"; 
           echo number_format((float)$DISK_SPACE, 1, '.', '') ." ". $DISK_UNIT . "</span></td>";
        }
    }else{
        echo "\n<td align=center>No Info</td>";
    }

    # Display if server is Active or Inactive
    if ($row['srv_active'] == TRUE ) {                                  # Is Server Active
        echo "\n<td align=center>";
        echo "<a href='" .$URL_SERVER. "?selection=all_active'>Active</a></td>";
    }else{                                                              # If not Activate
        echo "\n<td align=center>";
        echo "<a href='" .$URL_SERVER. "?selection=all_inactive'>Inactive</a></td>";
    }

    # Display if server is Sporadically online or not
    if ($row['srv_sporadic'] == TRUE ) {                                # Is Server Sporadic
        echo "\n<td align=center>";
        echo "<a href='" .$URL_SERVER. "?selection=all_sporadic'>Yes</a></td>";
    }else{                                                              # If not Sporadic
        echo "\n<td align=center>";
        echo "<a href='" .$URL_SERVER. "?selection=all_non_sporadic'>No</a></td>";
    }

    # Display if it is a physical or a virtual server - If a virtual machine display VM hostname.
    echo "\n<td align=center>";
    if ($row['srv_vm'] == TRUE ) {                                      # Is VM Server 
        echo "  <a href='" . $URL_SERVER . "?selection=vmhost&value=" .$row['srv_vm_host'].  "'>" .$row['srv_vm_host']. "</a>";
    }else{                                                              # If not Sporadic
        echo "<a href='" . $URL_SERVER . "?selection=all_physical'>N/A</a>";
    }
    echo "\n</td>";   

    # Show Performance Graph
    echo "\n<td align=center>";
    if ($row['srv_graph'] == TRUE ) {                                   # If Show Perf. Active 
        $RRD_FILE = SADM_WWW_RRD_DIR ."/".$row['srv_name']."/".$row['srv_name'].".rrd"; # Host RRD File
        if (file_exists($RRD_FILE)) {
            echo "<a href='" .$URL_PERF. "?host=" .$row['srv_name']. "'>Graph</a>";
        } else { echo "No Data"; }
    } else { echo "\nNot Actv."; }                                                           
    echo "\n</td>";   
    
    echo "\n</tr>\n";                                                 # End of Table Line
}



# P R O G R A M    S T A R T     H E R E 
# ==================================================================================================
#
    # 1st parameter contains type of query that need to be done (all_servers,os,...)   
    if (isset($_GET['selection']) && !empty($_GET['selection'])) { 
        $SELECTION = $_GET['selection'];                                # If Rcv. Save in selection
    }else{
        $SELECTION = 'all_servers';                                     # No Param.= "all_servers"
    }
    if ($DEBUG) { echo "<br>1st Parameter Received is " . $SELECTION; } # Under Debug Display Param.
    

    # 2nd Parameters is sometime used to specify the type of server received as 1st parameter.
    # Example: https://sadmin/sadmin/sadm_view_servers.php?selection=os&value=centos
    if (isset($_GET['value']) && !empty($_GET['value']) ) {
        $VALUE = $_GET['value'];                                        # Save 2nd Parameter Value
    }else{
        $VALUE = NULL;
    }
    if ($DEBUG) { echo "<br>2nd Parameter Received is " . $VALUE; }     # Under Debug Show 2nd Parm.
 

    # Validate the view option received, Set Page Heading and retrieve selected data from database
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
        case 'vmhost'           : 
            $sql = "SELECT * FROM server where srv_vm_host = '" . $VALUE . "' and srv_vm = '1' order by srv_name;";
            $TITLE = "Virtual machines on '" . $VALUE .  "'";
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
            $sql = 'SELECT * FROM server where srv_vm = True  order by srv_name;';
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
    if ( ! $result=mysqli_query($con,$sql)) {             # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceding line
        $err_msg1 = "Server (" . $wkey . ") not found.\n";              # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;   # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;         # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);      # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 .$err_msg3. $err_msg4);  # Display Msg. Box for User
        exit;                                                           # Exit - Should not occurs
    }

    # SHOW PAGE HEADING    
    #display_lib_heading("NotHome","$TITLE",TITLE2: " "$WVER); 
    display_lib_heading("NotHome","$TITLE"," " ,"$WVER"); 
    setup_table();                                                      # Create Table & Heading

    # LOOP THROUGH RETRIEVED DATA AND DISPLAY EACH ROW
    echo "\n<tbody>\n";                                                 # Start of Table Body
    $count = 0 ;                                                        # Init server counter to 0
    while ($row = mysqli_fetch_assoc($result)) {                # Gather Result from Query
        display_data(++$count,$con,$row);              # Display Row Data
    }
    echo "\n</table>\n";                                                # End of tbody,table
    echo "\n</tbody>" ;
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                         # Close MySQL & HTML Footer
?>
