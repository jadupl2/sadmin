<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
#
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_servers.php
#   Version     :  1.5
#   Date        :  14 April 2016
#   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
#   Description :  This page allow to view the servers farm information in various ways
#                  depending on parameters received.
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
# 2.0 February 2017 - Jacques DUplessis
#       Added options for editing server from that page
#       Added O/S Icons
#       Added VM or Physical Server
#   
# ==================================================================================================

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
    echo "<center>\n";                                                  # Table Centered on Page
  
    # Set Font Size for Table Cell and Table Heading
    echo "<style>\n";
    echo "td { font-size: 12px; }\n";
    echo "th { font-size: 13px; }\n";
    echo "</style>\n";
    echo '<table id="sadmTable" class="display compact nowrap" width="100%">';

    # Table Heading
    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th class='text-center'>No</th>\n";
    echo "<th>Server</th>\n";
    echo "<th class='text-center'>O/S</th>\n";
    echo "<th>Description</th>\n";
    echo "<th class='text-center'>Active</th>\n";
    echo "<th class='text-center'>VM</th>\n";
    echo "<th class='text-center'>Version</th>\n";
    echo "<th class='text-center'>Memory</th>\n";
    echo "<th class='text-center'>CPU Speed</th>\n";
    echo "<th class='text-center'>Disk Space</th>\n";
    echo "<th class='text-center'>Report</th>\n";
    echo "<th class='text-center'>Update</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th class='text-center'>No</th>\n";
    echo "<th>Server</th>\n";
    echo "<th class='text-center'>O/S</th>\n";
    echo "<th>Description</th>\n";
    echo "<th class='text-center'>Active</th>\n";
    echo "<th class='text-center'>VM</th>\n";
    echo "<th class='text-center'>Version</th>\n";
    echo "<th class='text-center'>Memory</th>\n";
    echo "<th class='text-center'>CPU Speed</th>\n";
    echo "<th class='text-center'>Disk Space</th>\n";
    echo "<th class='text-center'>Report</th>\n";
    echo "<th class='text-center'>Update</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";
 
    echo "<tbody>\n";                                                   # Start of Table Body
}




#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {

    echo "<tr>\n";  
    echo "<td class='dt-center'>" . $count . "</td>\n";  

    # Server Name
    echo "<td>";
    echo "<a href='/sadmin/sadm_view_server_info.php?host=" . nl2br($row['srv_name']) ;
    echo "' title='Server ip address is " . $row['srv_ip'] ."'>" ;
    echo $row['srv_name']  . "</a></td>\n";

    
    # Display Operating System Logo
    $WOS   = $row['srv_osname'];
    switch (strtoupper($WOS)) {
            case 'REDHAT' :
                echo "<td class='dt-center'>";
                echo "<a href='http://www.redhat.com' ";
                echo "title='Server $whost is a RedHat server - Visit redhat.com'>";
                echo "<img src='/images/redhat.png' ";
                echo "style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'FEDORA' :
                echo "<td class='dt-center'>";
                echo "<a href='https://getfedora.org' ";
                echo "title='Server $whost is a Fedora server - Visit getfedora.org'>";
                echo "<img src='/images/fedora.png' ";
                echo "style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'CENTOS' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.centos.org' ";
                echo "title='Server $whost is a CentOS server - Visit centos.org'>";
                echo "<img src='/images/centos.png' ";
                echo "style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'UBUNTU' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.ubuntu.com/' ";
                echo "title='Server $whost is a Ubuntu server - Visit ubuntu.com'>";
                echo "<img src='/images/ubuntu.png' ";
                echo "style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'DEBIAN' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.debian.org/' ";
                echo "title='Server $whost is a Debian server - Visit debian.org'>";
                echo "<img src='/images/debian.png' ";
                echo "style='width:32px;height:32px;'></a<</td>\n";
                break;
            case 'RASPBIAN' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.raspbian.org/' ";
                echo "title='Server $whost is a Raspbian server - Visit raspian.org'>";
                echo "<img src='/images/raspbian.png' ";
                echo "style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'SUSE' :
                echo "<td class='dt-center'>";
                echo "<a href='https://www.opensuse.org/' ";
                echo "title='Server $whost is a OpenSUSE server - Visit opensuse.org'>";
                echo "<img src='/images/suse.png' ";
                echo "style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'AIX' :
                echo "<td class='dt-center'>";
                echo "<a href='http://www-03.ibm.com/systems/power/software/aix/' ";
                echo "title='Server $whost is an AIX server - Visit Aix Home Page'>";
                echo "<img src='/images/aix.png' ";
                echo "style='width:32px;height:32px;'></a></td>\n";
                break;
            default:
                echo "<td class='dt-center'>";
                echo "<img src='/images/os_unknown.jpg' ";
                echo "style='width:32px;height:32px;'></td>\n";
                break;
    }

    # Description of Server
    echo "<td>" . nl2br( $row['srv_desc'])  . "</td>\n";
    
    # Server Status (Active/Inactive)
    if ($row['srv_active']   == 't' ) { 
        echo "<td class='dt-center'>Yes</td>\n"; 
    }else{ 
        echo "<td class='dt-center'>No</td>\n";
    }

    # Server is a VM ? (Yes/No)
    if ($row['srv_vm']   == 't' ) { 
        echo "<td class='dt-center'>Yes</td>\n"; 
    }else{ 
        echo "<td class='dt-center'>No</td>\n";
    }

    # Operating System Version
    echo "<td class='dt-center'>" . nl2br( $row['srv_osversion'])   . "</td>\n";  

    # Server Memory
    echo "<td class='dt-center'>" . nl2br( $row['srv_memory'])      . " MB</td>\n";  
    
    # Server Number and Speed of Cpu
    echo "<td class='dt-center'>" . nl2br( $row['srv_nb_cpu']) . " X ";
    echo nl2br( $row['srv_cpu_speed']) . " MHz</td>\n";
    
    # Disk Space and Number of Disk(s)
    $DiskArray = explode(",", $row['srv_disks_info']);
    $DiskNumber = sizeof($DiskArray);
    $TotalSpace  = 0 ;
    for ($i = 0; $i < count($DiskArray); ++$i) {
        list($DiskName,$DiskSize) = explode("|", $DiskArray[$i] );
        $TotalSpace = $TotalSpace + $DiskSize ;
    }
    $TotalGBSpace = floor(($TotalSpace / 1024));
    echo "<td class='dt-center'>";
    echo "<a href='/dat/" . $row['srv_name'] . "/dr/" . $row['srv_name'] . "_pvs.txt' " ;
    #echo " data-toggle='tooltip' title='View " . $row['srv_name'] ;
    echo " title='View " . $row['srv_name'] ;
    echo " Disks Details'>" . $TotalGBSpace . " GB (" . $DiskNumber . " Disks)</a></td>\n";
    
    # Display Icon to View Server Configuration
    echo "<td class='dt-center'>";
    echo "<a href='/dat/" . $row['srv_name'] . "/dr/" . $row['srv_name'] . ".html' " ;
    echo " title='View " . ucwords($row['srv_name']) . " Configuration'>";
    echo "<img src='/images/cfg2html.png' style='width:32px;height:32px;'></a></td>\n";

    # Display Icon to Edit Server Static information
    echo "<td class='dt-center'>";
    echo "<a href='/crud/sadm_server_update.php?sel=" . $row['srv_name'] . "'";
    echo " title='Edit " . ucwords($row['srv_name']) . " Static Information'>";
    echo "<img src='/images/update.png'   style='width:32px;height:32px;'></a></td>\n";

    echo "</tr>\n"; 
}
    





/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/


# The "selection" (1st) parameter contains type of query that need to be done (all_servers,os,...)   
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
            $query = 'SELECT * FROM sadm.server order by srv_name;';
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "List of all Servers";
            break;
        case 'host'         : 
            $query = "SELECT * FROM sadm.server where srv_name = '". $VALUE . "';";
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "Info about " . ucwords($VALUE) . " Server";
            break;
        case 'os'           : 
            $query = "SELECT * FROM sadm.server where srv_osname = '". $VALUE . "' order by srv_name;";
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "List of " . ucwords($VALUE) . " Servers";
            break;
        case 'all_active'   : 
            $query = 'SELECT * FROM sadm.server where srv_active = True order by srv_name;';
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "List of Active Servers";
            break;
        case 'all_inactive' : 
            $query = 'SELECT * FROM sadm.server where srv_active = False order by srv_name;';
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "List of Inactive Servers";
            break;
        case 'all_vm'       : 
            $query = 'SELECT * FROM sadm.server where srv_vm = True order by srv_name;';
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "List of Virtual Servers";
            break;
        case 'all_physical' : 
            $query = 'SELECT * FROM sadm.server where srv_vm = False order by srv_name;';
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "List of Physical Servers";
            break;
        case 'all_sporadic' : 
            $query = 'SELECT * FROM sadm.server where srv_sporadic = True order by srv_name;';
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $TITLE = "List of Sporadic Servers";
            break;
        default             : 
            echo "<br>The sort order received (" . $SELECTION . ") is invalid<br>";
            echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
    }
    

# Display Page Heading
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
