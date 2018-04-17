<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_subnet.php
#   Version  :  1.5
#   Date     :  14 April 2016
#   Requires :  php
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# Changelog
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#   2018_04_14 JDuplessis
#       V2.1  Page Redesign & Change Name/Format of input file (Inlude Mac Address, Manufacturer)
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # </head><body>,SideBar

# DataTable Initialisation Function
?>
<script>
    $(document).ready(function() {
        $('#sadmTable').DataTable( {
            "lengthMenu": [[255, 300, -1], [255, 300, "All"]],
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
$DEBUG           = False ;                                              # Debug Activated True/False
$SVER            = "2.1" ;                                              # Current version number
$URL_HOST_INFO   = '/view/srv/sadm_view_server_info.php';               # Display Host Info URL
$CREATE_FILE_PGM = "sadm_subnet_lookup.py";                             # Script to create in file



# ==================================================================================================
# DISPLAY CONTENT OF THE SELECTED SUBNET FILE
#
#  wfile    = Name of the network file to process
#  woption  = [all]   Display either free, used, or ghost entries 
#             [free]  Display only free IPs     (no respond to ping and NO DNS entry)
#             [iwn]   Inactive With Name        (no respond to ping and have DNS entry)
#             [awn]   Active Without Name       (respond to ping and have NO DNS entry)
#             [used]  Display only the used IPs (respond to ping and have DNS entry)
# ==================================================================================================
function show_subnet($wsubnet,$woption) {

    show_heading();                                                     # Print Data Page Heading
    list($ipaddress,$cidr) = explode('/',$SUBNET);                      # Separate Network & Netmask
    $netmask = cidr2netmask($cidr);                                     # Convert CIDR to Netmask
    list ($wnet, $wfirstip, $wlastip, $wbroadcast) = netinfo($ipaddress,$netmask);

    
    $SUBNET = '192.168.1.0/24'; // max. 30 ips
    $IPARRAY = getEachIpInRange ($SUBNET);
    foreach ($IPARRAY as $wip) {
        echo "<br>" . $wip;

        # Perform the SQL Requested ANd Display Data
        $sql = 'SELECT * FROM server_network order by net_ip_wzero;';
        $result=mysqli_query($con,$sql) ;                             # Execute SQL Select
        if (!$result) {
            echo 'Could not run query: ' . mysql_error();
            continue;
        }
        $row = mysql_fetch_row($result);                                    # Gather Result from Query

            if (($wactive == "0")  and ($wname == "")) { $wstate = "Free IP" ; } 
        if (($wactive == "1")  and ($wname != "")) { $wstate = "Used IP" ; }
        if (($wactive == "1")  and ($wname == "")) { $wstate = "Active, No Hostname" ; }
        if (($wactive == "0")  and ($wname != "")) { $wstate = "Inactive Hostname" ; }
        echo "\n<tr>";
        echo "\n<td class='dt-center'>" . $row['net_ip_wzero']         ."</td>";
        echo "\n<td class='dt-center'>" . $wstate      ."</td>";
        if ($wactive == 0) {
            echo "\n<td class='dt-center'>No</td>";
        }else{
            echo "\n<td class='dt-center'>Yes</td>";
        }
        echo "\n<td class='dt-center'>" . $wname       ."</td>";
        echo "\n<td class='dt-center'>" . $wmac        ."</td>";
        echo "\n<td class='dt-center'>" . $wmanu       ."</td>";
        echo "\n</tr>";
    }
    
    echo "\n</tbody>\n</table></center><br>";
    echo "\n<BR>                                             <!-- Blank Line -->\n";
}

# ==================================================================================================
# PRINT IP STATUS PAGE HEADING 
# ==================================================================================================
function show_heading() {

    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    echo '<table id="sadmTable" class="cell-border" compact row-border wrap width="70%">';   
    
    # TABLE HEADING
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th class='dt-head-center'>IP Address</th>";
    echo "\n<th class='dt-head-center'>IP State</th>";
    echo "\n<th class='dt-head-center'>Active</th>";
    echo "\n<th class='dt-head-center'>Last Active</th>";
    echo "\n<th class='dt-head-center'>DNS Hostname</th>";
    echo "\n<th class='dt-head-center'>Mac Address</th>";
    echo "\n<th class='dt-head-center'>Manufacturer</th>";
    echo "\n<th class='dt-head-center'>Last Update</th>";
    echo "\n</tr>";
    echo "\n</thead>";

    # TABLE FOOTER
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th class='dt-head-center'>IP Address</th>";
    echo "\n<th class='dt-head-center'>IP State</th>";
    echo "\n<th class='dt-head-center'>Active</th>";
    echo "\n<th class='dt-head-center'>Last Active</th>";
    echo "\n<th class='dt-head-center'>DNS Hostname</th>";
    echo "\n<th class='dt-head-center'>Mac Address</th>";
    echo "\n<th class='dt-head-center'>Manufacturer</th>";
    echo "\n<th class='dt-head-center'>Last Update</th>";
    echo "\n</tr>";
    echo "\n</tfoot>";

    echo "\n\n<tbody>";
}

# ==================================================================================================
# PROGRAM START HERE - SHOW STATUS PAGE OF ALL IP INCLUDED IN SUBNET RECEIVED
# ==================================================================================================

    # GET FIRST PARAMETER -------------------------------------------------------------------------- 
    if (! isset($_GET['net']) ) {                                       # Does Variable Net Defined?
       echo "<br>No Subnet paramater received\n";                       # Show what is wrong
       echo "<br><a href='javascript:history.go(-1)'>";                 # Link to previous page
       echo "Go back to adjust request</a>\n";                          # Description of link
       exit ;
    }    
    $SUBNET = $_GET['net'];                                             # Save Network Received 
    if ($DEBUG)  { echo "<br>Subnet Received is '$SUBNET'"; }           # Under Debug show Network
    
    # GET THE SECOND PARAMETER ---------------------------------------------------------------------
    if (! isset($_GET['option']) ) {                                    # Does Variable option exist
       echo "<br>The option paramater not received\n";                  # Show what is wrong
       echo "<br><a href='javascript:history.go(-1)'>";                 # Link to previous page
       echo "Go back to adjust request</a>\n";                          # Description of link
       exit ;
    }    
    $OPTION= $_GET['option'];                                           # Save Option Received
    if ($DEBUG)  { echo "<br>Page option is '$OPTION' <br>"; }          # Under Debug Show Option 

    # VALIDATE SECOND PARAMETER - THE DISPLAY OPTION -----------------------------------------------
    #  option   = [all]   Display all ip regardless of their status 
    #             [free]  Display only free IPs     (no respond to ping and NO DNS entry)
    #             [iwn]   Inactive With Name        (no respond to ping and have DNS entry)
    #             [awn]   Active Without Name       (respond to ping and have NO DNS entry)
    #             [used]  Display only the used IPs (respond to ping and have DNS entry)
    if (($OPTION != "all") and ($OPTION!="free") and ($OPTION!="used") 
        and ($OPTION!="iwn") and ($OPTION!="awn")) {
        echo "<br>Invalid display option received '" . $OPTION . "'";   # Inform user option Invalid
        echo "<br><br>\nCorrect the situation and retry request\n";     # Need to be corrected
        echo "<br><br><a href='javascript:history.go(-1)'>";            # Link to previous page
        echo "Go back to adjust request</a>\n";                         # Description of link
        exit ;
    }
       
    # DISPLAY STANDARD PAGE HEADING ----------------------------------------------------------------
    display_std_heading("NotHome",ucfirst($iptype) . " Subnet ${SUBNET}","",""," - $SVER");
    show_subnet ($SUBNET,$OPTION);                                      # Display Subnet Status Page
    
    # END OF PAGE FOOTER ---------------------------------------------------------------------------
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
