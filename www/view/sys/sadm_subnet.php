<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_subnet.php
#   Version  :  1.5
#   Date     :  14 April 2016
#   Requires :  php
#
#
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
# ChangeLog
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');       # <head>CSS,JavaScript</Head>
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
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.0" ;                                                        # Current version number
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL




# ==================================================================================================
#                      DISPLAY CONTENT OF THE SELECTED SUBNET FILE
#
#  wfile    = Name of the subnet file to process
#  woption  = [all]   Display either free, used, or ghost entries 
#             [free]  Display only free IPs     (no respond to ping and NO DNS entry)
#             [iwn]   Inactive With Name        (no respond to ping and have DNS entry)
#             [awn]   Active Without Name       (respond to ping and have NO DNS entry)
#             [used]  Display only the used IPs (respond to ping and have DNS entry)
# --------------------------------------------------------------------------------------------------
# File Content Examples
# 192.168.1.6, No,                      # [FREE]
# 192.168.1.7, Yes, watson.maison.ca    # [USED] [ACTIVE WITH NAME] 
# 192.168.1.8, Yes,                     # [AWN] [ACTIVE WITHOUT NAME]
# 192.168.1.9, No, imacw.maison.ca      # [IWN] [INACTIVE WITH NAME] [GHOST]
# ==================================================================================================
function print_subnet($wfile,$woption,$wsubnet) {

    # SUBNET DIV START
    #echo "\n\n<div class='subnet_container'>                 <!-- Start Subnet Container DIV -->\n";
    
    # Print Heading and Start Body Section
    print_ip_heading ("$woption",$wsubnet);
    
    # Load the IP File into $lines Array.
    $lines = file($wfile);

    // Loop through our array, show HTML source as HTML source; and line numbers too.
    foreach ($lines as $line_num => $line) {
        #echo "Line #<b>{$line_num}</b> : " . htmlspecialchars($line) . "<br />\n";
        list($wip, $wstatus, $wname) = explode(",", htmlspecialchars($line));
        $wname  = trim($wname);
        $wstatus= trim($wstatus);
        echo "\n<tr>";
        echo "\n<td class='dt-center'>" . $wip     . "</td>";
        echo "\n<td class='dt-center'>" . $wstatus . "</td>";
        echo "\n<td class='dt-center'>" . $wname   . "</td>";
        if (($wstatus == "No")  and ($wname == "")) { $wtype = "free" ; } 
        if (($wstatus == "Yes") and ($wname != "")) { $wtype = "used" ; }
        if (($wstatus == "Yes") and ($wname == "")) { $wtype = "Actine, No Hostname" ; }
        if (($wstatus == "No")  and ($wname != "")) { $wtype = "Inactive, With Hostname" ; }
        echo "\n<td>" . $wtype   . "</td>";
        echo "\n</tr>";
    }
    echo "\n</tbody>\n</table></center><br>";
   
    # SUBNET DIV END
#    echo "\n\n</div'>                                        <!-- End Subnet Container DIV -->\n";
    echo "\n<BR>                                             <!-- Blank Line -->\n";
}


# ==================================================================================================
#                             PRINT IP HEADING FUNCTION
# ==================================================================================================
#
function print_ip_heading($iptype,$wsubnet) {

    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    echo '<table id="sadmTable" class="display" compact row-border wrap width="80%">';   

    echo "\n<thead>";
    echo "\n<tr>";
    echo "\n<th width=150 halign='center'>IP Address</th>";
    echo "\n<th width=150>Ping Response</th>";
    echo "\n<th width=250>DNS Hostname</th>";
    echo "\n<th width=220>IP Status</th>";
    echo "\n</tr>";
    echo "\n</thead>";

    echo "\n<tfoot>";
    echo "\n<tr>";
    echo "\n<th width=150 halign='center'>IP Address</th>";
    echo "\n<th width=150>Ping Response</th>";
    echo "\n<th width=250>DNS Hostname</th>";
    echo "\n<th width=220>IP Status</th>";
    echo "\n</tr>";
    echo "\n</tfoot>";

    echo "\n\n<tbody>";
}



# ==================================================================================================
#                                      PROGRAM START HERE
# ==================================================================================================
#
    # Get the first parameter - Subnet file to use
    if (! isset($_GET['net']) ) { 
       echo "<br>No Subnet received\n<br>Correct the situation and retry request\n";
       echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
       exit ;
    }    
    $SUBNET = $_GET['net'];
    if ($DEBUG)  { echo "<br>Subnet Received is $SUBNET "; }
    
    # Get the second paramater ([all] IPs, [free] IPs, [used] IPs, [ghost] IPS)
    if (! isset($_GET['option']) ) { 
       echo "<br>Second parameter not received\n<br>Correct the situation and retry request\n";
       echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
       exit ;
    }    
    $OPTION= $_GET['option'];
    if ($DEBUG)  { echo "<br>Subnet page option is $OPTION "; }
    
    # Verify if subnet file exist    
    list($network,$mask) = explode('/',$SUBNET);
    $subnet_file =  SADM_WWW_NET_DIR . "/subnet_" . $network . ".txt";
    if (! file_exists($subnet_file))  {
       echo "<br>The subnet file " . $subnet_file . " does not exist.\n";
       echo "<br>Correct the situation and retry request\n";
       echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
       exit ;
    }

    # Validate the display option received
    if (($OPTION != "all") and ($OPTION!="free") and ($OPTION!="used")
        and ($OPTION!="awn") and ($OPTION!="iwn")) {
           echo "<br>The Display Option Received " . $OPTION . " is not valid.\n";
           echo "<br>Correct the situation and retry request\n";
           echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
           exit ;
    }
    
    # Display Content Heading
     display_std_heading("NotHome",ucfirst ($iptype) . " IP of Subnet ${SUBNET}","",""," - $SVER");
    # Print the Subnet File
    print_subnet ("$subnet_file","$OPTION",$SUBNET);

    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
