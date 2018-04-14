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
#                      DISPLAY CONTENT OF THE SELECTED SUBNET FILE
#
#  wfile    = Name of the network file to process
#  woption  = [all]   Display either free, used, or ghost entries 
#             [free]  Display only free IPs     (no respond to ping and NO DNS entry)
#             [iwn]   Inactive With Name        (no respond to ping and have DNS entry)
#             [awn]   Active Without Name       (respond to ping and have NO DNS entry)
#             [used]  Display only the used IPs (respond to ping and have DNS entry)
# --------------------------------------------------------------------------------------------------
# File Content Examples
# 192.168.001.003,mycroftw.maison.ca,a0:99:9b:08:f5:11, Apple Inc.,Y,192.168.1.3
# 192.168.001.004,raspi0.maison.ca,b8:27:eb:9e:77:81, Raspberry Pi Foundation,Y,192.168.1.4
# 192.168.001.005,gandhi.maison.ca,,,Y,192.168.1.5
#
# ==================================================================================================
function print_subnet($wfile,$woption,$wsubnet) {

    print_ip_heading ("$woption",$wsubnet);                             # Print Data Page Heading
    $lines = file($wfile);                                              # Read Network File in Array

    # LOOP THROUGH NETWORK ARRAY AND DISPLAY DATA
    foreach ($lines as $line_num => $line) {
        if ($DEBUG) { echo "Line #<b>{$line_num}</b> : " . htmlspecialchars($line) . "<br />\n";}
        list($wip, $wname, $wmac, $wmanu, $wactive) = explode(",", htmlspecialchars($line));
        $wname  = trim($wname);
        if (($wactive == "N") and ($wname == "")) { $wstate = "Free IP" ; } 
        if (($wactive == "Y") and ($wname != "")) { $wstate = "Used IP" ; }
        if (($wactive == "Y") and ($wname == "")) { $wstate = "Active, No Hostname" ; }
        if (($wactive == "N") and ($wname != "")) { $wstate = "Inactive Hostname" ; }
        echo "\n<tr>";
        echo "\n<td class='dt-center'>" . $wip         ."</td>";
        echo "\n<td class='dt-center'>" . $wstate      ."</td>";
        echo "\n<td class='dt-center'>" . $wactive     ."</td>";
        echo "\n<td class='dt-center'>" . $wname       ."</td>";
        echo "\n<td class='dt-center'>" . $wmac        ."</td>";
        echo "\n<td class='dt-center'>" . $wmanu       ."</td>";
        echo "\n</tr>";
    }
    echo "\n</tbody>\n</table></center><br>";
    echo "\n<BR>                                             <!-- Blank Line -->\n";
}


# ==================================================================================================
#                             PRINT IP HEADING FUNCTION
# ==================================================================================================
#
function print_ip_heading($iptype,$wsubnet) {

    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    echo '<table id="sadmTable" class="cell-border" compact row-border wrap width="70%">';   
    
    # TABLE HEADING
    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th class='dt-head-center'>IP Address</th>";
    echo "\n<th class='dt-head-center'>IP State</th>";
    echo "\n<th class='dt-head-center'>Active</th>";
    echo "\n<th class='dt-head-center'>DNS Hostname</th>";
    echo "\n<th class='dt-head-center'>Mac Address</th>";
    echo "\n<th class='dt-head-center'>Manufacturer</th>";
    echo "\n</tr>";
    echo "\n</thead>";

    # TABLE FOOTER
    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th class='dt-head-center'>IP Address</th>";
    echo "\n<th class='dt-head-center'>IP State</th>";
    echo "\n<th class='dt-head-center'>Active</th>";
    echo "\n<th class='dt-head-center'>DNS Hostname</th>";
    echo "\n<th class='dt-head-center'>Mac Address</th>";
    echo "\n<th class='dt-head-center'>Manufacturer</th>";
    echo "\n</tr>";
    echo "\n</tfoot>";

    echo "\n\n<tbody>";
}



# ==================================================================================================
#                                      PROGRAM START HERE
# ==================================================================================================

    # VALIDATE IF THE 'NET' PARAMETER IS RECEIVED - IF RECEIVED SAVE SUBNET ------------------------ 
    if (! isset($_GET['net']) ) {                                       # Does Variable Net Defined?
       echo "<br>No Subnet paramater received\n";                       # Show what is wrong
       echo "<br><a href='javascript:history.go(-1)'>";                 # Link to previous page
       echo "Go back to adjust request</a>\n";                          # Description of link
       exit ;
    }    
    $SUBNET = $_GET['net'];                                             # Save Network Received 
    if ($DEBUG)  { echo "<br>Subnet Received is '$SUBNET'"; }           # Under Debug show Network
    
    
    # GET THE SECOND PARAMATER ([ALL] IPS, [FREE] IPS, [USED] IPS, [GHOST] IPS) --------------------
    if (! isset($_GET['option']) ) {                                    # Does Variable option exist
       echo "<br>The option paramater not received\n";                  # Show what is wrong
       echo "<br><a href='javascript:history.go(-1)'>";                 # Link to previous page
       echo "Go back to adjust request</a>\n";                          # Description of link
       exit ;
    }    
    $OPTION= $_GET['option'];                                           # Save Option Received
    if ($DEBUG)  { echo "<br>Page option is '$OPTION' <br>"; }          # Under Debug Show Option 
    
    
    # VERIFY IF NETWORK FILE EXIST -----------------------------------------------------------------
    list($network,$mask) = explode('/',$SUBNET);                        # Separate Network & Netmask
    #list($net1,$net2,$net3,$net4) = explode('.',$network);             # Split Network in 4 Digits
    $netfile = SADM_WWW_NET_DIR. "/network_" .$network. "_" .$mask. ".txt";
    if (! file_exists($netfile))  {                                     # Does Network file exist ?
       echo "<br>Network file '" .$netfile. "' doesn't exist.\n<br>";   # Inform User 
       echo "<br>You may have to run '" .SADM_BIN_DIR. "/" . $CREATE_FILE_PGM . "' to create it.\n";
       echo "<br><br><a href='javascript:history.go(-1)'>";             # Link to previous page
       echo "Go back to adjust request</a>\n";                          # Description of link
       exit ;
    }
    if ($DEBUG)  { echo "\n<br>Subnet File used : $netfile "; }         # On Debug show input file


    # VALIDATE THE DISPLAY OPTION RECEIVED ---------------------------------------------------------
    if (($OPTION != "all") and ($OPTION!="free") and ($OPTION!="used")) {
        echo "<br>Invalid display option received '" . $OPTION . "'";   # Inform user option Invalid
        echo "<br><br>\nCorrect the situation and retry request\n";     # Need to be corrected
        echo "<br><br><a href='javascript:history.go(-1)'>";            # Link to previous page
        echo "Go back to adjust request</a>\n";                         # Description of link
        exit ;
    }
    
    # DISPLAY STANDARD PAGE HEADING ----------------------------------------------------------------
    display_std_heading("NotHome",ucfirst($iptype) . " Subnet ${SUBNET}","",""," - $SVER");

    # PRINT THE NETWORK FILE------------------------------------------------------------------------
    print_subnet ("$netfile","$OPTION",$SUBNET);                        # Go Print Network file

    # END OF PAGE FOOTER ---------------------------------------------------------------------------
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
