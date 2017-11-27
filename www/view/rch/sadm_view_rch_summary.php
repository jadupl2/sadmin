<?php
# ================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_view_rch_summary.php
#   Version  :  1.5
#   Date     :  22 March 2016
#   Requires :  php
#   Synopsis :  Present a summary of all rch files received from all servers.
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHead.php');  # <head>CSS,JavaScript</Head>
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');
# DataTable Initialisation Function
?>
<script>
    $(document).ready(function() {
        $('#sadmTable').DataTable( {
            "lengthMenu": [[10, 25, 50, -1], [10, 25, 50, "All"]],
            "bJQueryUI" : true,
            "paging"    : true,
            "ordering"  : true,
            "info"      : true
        } );
    } );
</script>
<?php
    echo "<body>";
    echo "<div id='sadmWrapper'>";                                      # Whole Page Wrapper Div
    require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeading.php');# Top Universal Page Heading
    echo "<div id='sadmPageContents'>";                                 # Lower Part of Page
    require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');# Display SideBar on Left               



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.0" ;                                                        # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL


# ==================================================================================================
# DISPLAY RESULT CODE HISTORY FILE RESULTS HEADING FUNCTION
# ==================================================================================================
function setup_table() {
    echo "\n<br>\n";
    
    # TABLE CREATION
    echo "<div id='SimpleTable'>";                                      # Width Given to Table
    echo '<table id="sadmTable" class="display" cell-border compact row-border wrap width="98%">';   
    
    # PAGE TABLE HEADING 
    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th class='dt-head-left'>Server</th>\n";
    echo "<th class='dt-left'>Script Name</th>\n";
    echo "<th class='dt-center'>Start Date</th>\n";
    echo "<th class='dt-center'>Start Time</th>\n";
    echo "<th class='dt-head-center'>End Time</th>\n";
    echo "<th class='dt-center'>Elapse</th>\n";
    echo "<th class='dt-center'>Status</th>\n"; 
    echo "<th class='dt-center'>History</th>\n"; 
    echo "<th class='dt-center'>Log</th>\n"; 
    echo "</tr>\n";
    echo "</thead>\n";

    # PAGE TABLE FOOTER
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th class='dt-head-left'>Server</th>\n";
    echo "<th class='dt-left'>Script Name</th>\n";
    echo "<th class='dt-center'>Start Date</th>\n";
    echo "<th class='dt-center'>Start Time</th>\n";
    echo "<th class='dt-head-center'>End Time</th>\n";
    echo "<th class='dt-center'>Elapse</th>\n";
    echo "<th class='dt-center'>Status</th>\n"; 
    echo "<th class='dt-center'>History</th>\n"; 
    echo "<th class='dt-center'>Log</th>\n"; 
    echo "</tr>\n";
    echo "</tfoot>\n";

}


# ==================================================================================================
# DISPLAY THE SCRIPT ARRAY FUNCTION
#  1st Parameter is the Page Heading Title
#  2nd Parameter is the Script Array 
# ==================================================================================================
function display_script_array($con,$PAGE_TYPE, $script_array)
{
    global $DEBUG; 
    
    # Loop through the script array 
    foreach($script_array as $key=>$value) { 
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$ccode,$cfile) = 
            explode(",", $value);                                       # Split Script RCH Data
            
        # If Page Type Selected match the Return Code of RCH file or All Script selected, Display it
        if ((($PAGE_TYPE == "failed")  and ($ccode == 1)) or 
            (($PAGE_TYPE == "running") and ($ccode == 2)) or 
            (($PAGE_TYPE == "success") and ($ccode == 0)) or 
             ($PAGE_TYPE == "all")) {

            # Get Server Description from Database (Use as a tooltip over the servane name)
            $sql = "SELECT * FROM server where srv_name = '$cserver' ;";
            $result=mysqli_query($con,$sql);                            # Execute SQL Select
            $row = mysqli_fetch_assoc($result);
            if ($row) { $wdesc   = $row['srv_desc']; } else { $wdesc   = "Unknown"; }

            echo "<tr>\n";
            echo "<td class='dt-left'>" ;
            echo "<a href='" . $URL_HOST_INFO . "?host=" . $cserver . 
                 "' data-toggle='tooltip' title='" . $wdesc . "'>" . $cserver . "</a></td>\n";
                 
            # Display Script Name, Start Date, Start Time, End Time and Elapse Script Time
            echo "<td>"  . $cname . "</td>\n";                          # Server Name Cell
            echo "<td class='dt-center'>" . $cdate1  . "</td>\n";       # Start Date Cell
            echo "<td class='dt-center'>" . $ctime1  . "</td>\n";       # Start Time Cell
            if ($ccode == 2) {
                echo "<td class='dt-center'>............</td>\n";       # Running - No End date Yet
                echo "<td class='dt-center'>............</td>\n";       # Running - No Elapse time
            }else{
                echo "<td class='dt-center'>" . $ctime2   . "</td>\n";  # Script Ending Time
                echo "<td>" . $celapsed . "</td>\n";                    # Script Elapse Time
            }
            
            # Display The Script Status based on Return Code 
            switch ($ccode) {
                case 0:  echo "<td><font color='black'>Success</font></td>\n";
                         break;
                case 1:  echo "<td><font color='red'>Failed</font></td>\n";
                         break;
                case 2:  echo "<td><font color='green'>Running</font></td>\n";
                         break;
                default: echo "<td><font color='red'>Code " . $ccode . "</font></td>\n";
                         break;;
            }
            
            # Display Links to Access History File (RCH) and the Log file 
            list($fname,$fext) = explode ('.',$cfile);                  # Isolate Script Name
            $LOGFILE = $fname . ".log";                                 # Add .log to Script Name

            echo "<td class='dt-center'>" ;
            $rch_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . trim($cfile) ;
            if (file_exists($rch_name)) {
                echo "<a href='/sadmin/sadm_view_rchfile.php?host=". $cserver ."&filename=". $cfile . 
                    "' data-toggle='tooltip' title='View Result Code History File'>View History</a>";
            }else{
                echo "N/A";    
            }
            echo "</td>\n" ;

            echo "<td class='dt-center'>" ;
            $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . trim($LOGFILE) ;
            if (file_exists($log_name)) {
                echo "<a href='/sadmin/sadm_view_logfile.php?host=". $cserver . "&filename=" . 
                 $LOGFILE .  "' data-toggle='tooltip' title='View Script Log File'>View Log</a>";
            }else{
                echo "N/A";    
            }
            echo "</td>\n" ;
            echo "</tr>\n";
        }
    }    
    echo "</tbody></table></center><br><br>\n";
}





# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    echo "<div id='sadmRightColumn'>";                                  # Beginning Content Page

    # If we did not received any parameter, then default to displaying all scripts status
    if (isset($_GET['sel']) ) {                                         # If Param Type recv.
        $SELECTION = $_GET['sel'];                                      # Get Page Type Received
    }else{                                                              # If No Param received
        $SELECTION = 'all';                                             # Def. Display All Scripts
    }
    if ($DEBUG) { echo "<br>Selection is " . $SELECTION; }              # Under Debug Show Page Type
    if ($DEBUG) { echo "<br>SADM_WWW_RCH_DIR = " . SADM_WWW_RCH_DIR; }  # Under Debug Show RCH Dir.


    # Validate the page type received - If not supported, Back to Prev page
    switch ($SELECTION) {
        case 'all'      :  break;
        case 'failed'   :  break;
        case 'running'  :  break;
        case 'success'  :  break;
        default         :  $msg="Invalid Page Type Received (" . $SELECTION . ")";
                           alert ("$msg");
                           ?><script type="text/javascript">history.go(-1);</script><?php
                           exit ;
    }

    # Read Last Line of all *.rch and fill the Script Array with results
	$script_array = build_sidebar_scripts_info();                       # Build Scripts Array
    if ($DEBUG) {
        $xcount = 0 ;                                                   # Init Line Counter
        echo "<BR><BR>Array Nb. of elements: " . count($script_array);  # Nb. Of Items in Array
        foreach($script_array as $key=>$value) { 
            $xcount += 1;                                               # Increase Line Counter
            echo "<br>$xcount - KEY IS $key AND VALUE IS $value";       # Display Array Key & Value
        }
    }

   # Set and Display Web Page Header
    $HDESC = "";
    if ($SELECTION== "all")      { $HDESC="All Scripts"; }
    if ($SELECTION== "running")  { $HDESC="Running Scripts"; }
    if ($SELECTION== "failed")   { $HDESC="Failed Scripts"; }
    if ($SELECTION== "success")  { $HDESC="Success Scripts"; }
    if ($HDESC == "") {
        echo "<br>Heading Display Type (" . $SELECTION. ") " . $HDESC . "is invalid<br>";
        echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
        exit(1);
    }

   
    # Display the script array 
    display_page_heading("NotHome","$HDESC",$CREATE_BUTTON);            # Display Content Heading
    echo "\n<hr/>";                                                     # Print Horizontal Line
    setup_table();                                                      # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body
    display_script_array($con,$SELECTION,$script_array);                     # Go Display Script Array
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div

    # COMMON FOOTING
    echo "</div> <!-- End of sadmRightColumn   -->" ;                   # End of Left Content Page       
    echo "</div> <!-- End of sadmPageContents  -->" ;                   # End of Content Page
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageFooter.php')  ;    # SADM Std EndOfPage Footer
    echo "</div> <!-- End of sadmWrapper       -->" ;                   # End of Real Full Page
?>
