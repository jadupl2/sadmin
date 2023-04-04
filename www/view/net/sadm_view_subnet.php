<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_view_subnet.php
#   Version  :  1.0
#   Date     :  14 April 2018
#   Requires :  php
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# Changelog
#   Version 1.0 - Initial Version October 2017 
#   2018_04_14 JDuplessis
#       V1.1  First Working Version
# 2018_04_19 v1.2  Release Version 
# 2018_09_21 v1.3  Compact Page Layout  
# 2019_03_30 nolog: v1.4  Small heading change
# 2019_04_07 Update: v1.5 Show Card Manufacturer when available.
# 2019_04_25 Update: v1.6 Remove Manufacturer since arp-scan is not used anymore (more portable).
# 2019_04_27 Update: v1.7 Show Full Date & Time for Ping Date and Changed Date.
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # </head><body>,SideBar

# DataTable Initialization Function
?>
<script>
    $(document).ready(function() {
        $('#sadmTable').DataTable( {
            "lengthMenu": [[255, 300, -1], [255, 300, "All"]],
            "bJQueryUI" : true,
            "paging"    : true,
            "ordering"  : true,
            "info"      : true,
            'buttons'   : [ 'pdf', 'print' ]
        } );
    } );
</script>
<?php



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG           = False ;                                               # Debug Activated True/False
$SVER            = "1.7" ;                                              # Current version number
$URL_HOST_INFO   = '/view/srv/sadm_view_server_info.php';               # Display Host Info URL
$CREATE_FILE_PGM = "sadm_subnet_lookup.py";                             # Script to create in file
$URL_IPVIEW      = '/view/net/sadm_view_subnet.php';                    # Display Subnet Network URL



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
function show_subnet($wsubnet,$woption,$con) {
    global $URL_IPVIEW; 

    list($ipaddress,$cidr) = explode('/',$wsubnet);                     # Separate Network & Netmask
    $netmask = cidr2mask($cidr);                                        # Convert CIDR to Netmask
    list ($wnet, $wfirstip, $wlastip, $wbroadcast) = netinfo($ipaddress,$netmask);
    #echo "\n<h1><center>Information about subnet " . $wsubnet . "</h1></center>";
    echo "\n<center>Network:" . $wnet . " - Netmask:" . $netmask . " - First IP:" . $wfirstip ;
    echo " - Last IP:" . $wlastip . " - Broadcast:" . $wbroadcast . "</center><br>";

    echo '<center>';
    echo "\n<a href='" .$URL_IPVIEW. "?net=" .$wsubnet. "&option=all'>All IP</a> - ";
    echo "\n<a href='" .$URL_IPVIEW. "?net=" .$wsubnet. "&option=free'>Free IP</a> - ";
    echo "\n<a href='" .$URL_IPVIEW. "?net=" .$wsubnet. "&option=used'>Used IP</a> - ";
    echo "\n<a href='" .$URL_IPVIEW. "?net=" .$wsubnet. "&option=awn'>IP Pingable without Hostname</a> - ";
    echo "\n<a href='" .$URL_IPVIEW. "?net=" .$wsubnet. "&option=iwn'>IP Not Pingable with Hostname</a>";
    echo '</center><br>';

    show_heading();                                                     # Print Data Page Heading
    $IPARRAY = getEachIpInRange ($wsubnet);                             # Create Array of Usable IP
    $linecount = 0;                                                     # Line Counter
    
    foreach ($IPARRAY as $wip) {                                        # For each usable IP
        # Read IP information in Database ----------------------------------------------------------
        $sql = "SELECT * FROM server_network where net_ip = '" . $wip . "' ;";
        $result=mysqli_query($con,$sql) ;                               # Execute SQL Select
        if (!$result) { continue ; }                                    # IP not in DB. Then Next IP

        $row = mysqli_fetch_assoc($result);                             # Read Current Processing IP
        # Select to show or not based on the option requested --------------------------------------
        #  option   = [all]   Display all ip regardless of their status 
        #             [free]  Display only free IPs     (no respond to ping and NO DNS entry)
        #             [iwn]   Inactive With Name        (no respond to ping and have DNS entry)
        #             [awn]   Active Without Name       (respond to ping and have NO DNS entry)
        #             [used]  Display only the used IPs (respond to ping and have DNS entry)

        # Set the State according to Ping result and if got a hostname.
        if (($row['net_ping'] == "0")  and ($row['net_hostname'] == "")) { $wstate="free" ; } 
        if (($row['net_ping'] == "1")  and ($row['net_hostname'] != "")) { $wstate="used" ; }
        if (($row['net_ping'] == "1")  and ($row['net_hostname'] == "")) { $wstate="awn";}
        if (($row['net_ping'] == "0")  and ($row['net_hostname'] != "")) { $wstate="iwn";}
        
        # Display IP Information -------------------------------------------------------------------
        if  (($woption == "all") or 
            (($woption == "iwn")  and ($wstate == "iwn")) or 
            (($woption == "awn")  and ($wstate == "awn")) or
            (($woption == "free") and ($wstate == "free")) or       
            (($woption == "used") and ($wstate == "used")))          
            { 
            ++$linecount;                                                   # Increase Line Counter
            echo "\n<tr>";
            #echo "\n<td class='dt-center'>" .$linecount. "</td>";           # Show LineCounter
            echo "\n<td class='dt-center'>" .$row['net_ip_wzero']. "</td>"; # Show Current IP With 
            if ($row['net_ping'] == 0) {                                    # If IP Not Pingable
                echo "\n<td class='dt-center'>No</td>";                     # Display No
            }else{                                                          # If IP Pingable
                echo "\n<td class='dt-center'>Yes</td>";                    # Display Yes
            }
            echo "\n<td class='dt-center'>" .$row['net_hostname']."</td>";  # Show DNS Name of IP
            #echo "\n<td class='dt-center'>" .ucfirst($wstate). "</td>";     # Show State IP/HostName
            if ($row['net_date_ping'] == "0000-00-00 00:00:00") {           # If No Date Last Ping
                echo "\n<td class='dt-center'>None</td>";                   # Show None to User
            }else{                                                          # If Ping Worked Once
                echo "\n<td class='dt-center'>";                            # Show most recent Date
                #echo substr ($row['net_date_ping'],0,10) ."</td>";          # that The Ping Worked
                echo $row['net_date_ping']  ."</td>";          # that The Ping Worked
            }
            if ($row['net_mac'] == "None") {
                echo "\n<td class='dt-center'>" . " "  ."</td>";     # Show Mac Address Card
            }else{
                echo "\n<td class='dt-center'>" . $row['net_mac'] ."</td>";     # Show Mac Address Card
            } 
            #echo "\n<td class='dt-center'>" . $row['net_man'] ."</td>";     # Show Card Manufacturer
            echo "\n<td class='dt-center'>";                                # Show Last Change Date
            #echo substr ($row['net_date_update'],0,10) ."</td>";            # Of Mac,Host or Ping
            echo $row['net_date_update']  ."</td>";          # that The Ping Worked
            echo "\n</tr>";
            }
    }
}



# ==================================================================================================
# PRINT IP STATUS PAGE HEADING 
# ==================================================================================================
function show_heading() {

    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    #echo '<table id="sadmTable" class="display" cellspacing="0" style="width:80%">';   
    echo '<table id="sadmTable" class="cell-border" class="hover" compact row-border wrap width="100%">';   
    #echo '<table id="sadmTable" class="display"      compact row-border wrap width="85%">';    
    
    # TABLE HEADING
    echo "\n<thead>";
    echo "\n<tr>";
    #echo "\n<th class='dt-head-center'>No</th>";
    echo "\n<th class='dt-head-center'>IP address</th>";
    echo "\n<th class='dt-head-center'>Ping</th>";
    echo "\n<th class='dt-head-center'>Hostname</th>";
    #echo "\n<th class='dt-head-center'>State</th>";
    echo "\n<th class='dt-head-center'>Last ping</th>";
    echo "\n<th class='dt-head-center'>Mac address</th>";
    #echo "\n<th class='dt-head-center'>Manufacturer</th>";
    echo "\n<th class='dt-head-center'>Mac or Hostname change</th>";
    echo "\n</tr>";
    echo "\n</thead>";

    # TABLE FOOTER
    echo "\n<tfoot>";
    echo "\n<tr>";
    #echo "\n<th class='dt-head-center'>No</th>";
    echo "\n<th class='dt-head-center'>IP address</th>";
    echo "\n<th class='dt-head-center'>Ping</th>";
    echo "\n<th class='dt-head-center'>Hostname</th>";
    #echo "\n<th class='dt-head-center'>State</th>";
    echo "\n<th class='dt-head-center'>Last ping</th>";
    echo "\n<th class='dt-head-center'>Mac address</th>";
    #echo "\n<th class='dt-head-center'>Manufacturer</th>";
    echo "\n<th class='dt-head-center'>Mac/Hostname change</th>";
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
    $title1="Information about " . " subnet $SUBNET";
    $title2="";
    display_lib_heading("NotHome","$title1","$title2",$SVER); 

    # SHOW LIST OF IP STATUS -----------------------------------------------------------------------
    show_subnet ($SUBNET,$OPTION,$con);                                 # Display Subnet Status Page
    
    # END OF PAGE FOOTER ---------------------------------------------------------------------------
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
