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
#   2018_05_06 JDuplessis
#       2.1 Change to use sadm_view_file instead of sadm_view_log 
# 2018_07_21  v2.2 Screen disposition adjustments
#@2018_09_16  v2.3 Added Alert group Display 
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>
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
$SVER  = "2.3" ;                                                        # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$URL_VIEW_RCH  = '/view/rch/sadm_view_rchfile.php';                     # View RCH File Content URL
$URL_VIEW_FILE = '/view/log/sadm_view_file.php';                        # View File Content URL

# ==================================================================================================
# SETUP TABLE HEADER AND FOOTER
# ==================================================================================================
function setup_table() {
    echo "\n<br>\n";
    
    # TABLE CREATION
    echo "\n<div id='SimpleTable'>";                                      # Width Given to Table
    echo "\n<table id='sadmTable' class='display' cell-border compact row-border wrap width='98%'>";
    
    # PAGE TABLE HEADING 
    echo "\n<thead>\n";
    echo "<tr>\n";
    echo "<th class='dt-head-left'>Server</th>\n";
    echo "<th class='dt-left'>Script Name</th>\n";
    echo "<th class='dt-center'>Start Date</th>\n";
    echo "<th class='dt-center'>Start Time</th>\n";
    echo "<th class='dt-head-center'>End Time</th>\n";
    echo "<th class='dt-head-left'>Elapse</th>\n";
    echo "<th class='dt-head-center'>Alert Grp</th>\n";
    echo "<th class='dt-head-left'>Status</th>\n"; 
    echo "<th class='dt-head-left'>History</th>\n"; 
    echo "<th class='dt-head-left'>Log</th>\n"; 
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
    echo "<th class='dt-head-left'>Elapse</th>\n";
    echo "<th class='dt-head-center'>Alert Grp</th>\n";
    echo "<th class='dt-head-left'>Status</th>\n"; 
    echo "<th class='dt-head-left'>History</th>\n"; 
    echo "<th class='dt-head-left'>Log</th>\n"; 
    echo "</tr>\n";
    echo "</tfoot>\n";

}


# ==================================================================================================
# DISPLAY THE SCRIPT ARRAY FUNCTION
#   1st Parameter Object connector to Database
#   2nd Parameter is the Page Type to display (All,Failed,Success,Running)
#   3rd Parameter is the Script Array 
# ==================================================================================================
function display_script_array($con,$wpage_type,$script_array) {
    global $DEBUG, $URL_HOST_INFO, $URL_VIEW_RCH, $URL_VIEW_FILE ; 
    
    # LOOP THROUGH THE SCRIPT ARRAY ----------------------------------------------------------------
    foreach($script_array as $key=>$value) { 
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$calert,$ccode,$cfile) = 
            explode(",", $value);                                       # Split Script RCH Data Line
            
        # IF PAGE TYPE SELECTED MATCH THE RETURN CODE OF RCH FILE OR ALL SCRIPT SELECTED, DISPLAY IT
        if ((($wpage_type == "failed")  and ($ccode == 1)) or 
            (($wpage_type == "running") and ($ccode == 2)) or 
            (($wpage_type == "success") and ($ccode == 0)) or 
             ($wpage_type == "all")) {

            # GET SERVER DESCRIPTION FROM DATABASE (USE AS A TOOLTIP OVER THE SERVANE NAME) --------
            $sql = "SELECT * FROM server where srv_name = '$cserver' "; # Select Statement Read Srv
            $result=mysqli_query($con,$sql);                            # Execute SQL Select
            $row = mysqli_fetch_assoc($result);                         # Get Column Row Array 
            if ($row) { $wdesc   = $row['srv_desc']; } else { $wdesc   = "Unknown"; } #Get Srv Desc.
            
            # DISPLAY SERVER NAME ------------------------------------------------------------------
            echo "\n<tr>";
            echo "\n<td class='dt-left'>" ;
            echo "<a href='" . $URL_HOST_INFO . "?host=" . $cserver . 
                 "' data-toggle='tooltip' title='" . $wdesc . "'>" . $cserver . "</a></td>";
                 
            # DISPLAY SCRIPT NAME, START DATE, START TIME, END TIME AND ELAPSE SCRIPT TIME ---------
            echo "\n<td class='dt-left'>"   . $cname   . "</td>";       # Server Name Cell
            echo "\n<td class='dt-center'>" . $cdate1  . "</td>";       # Start Date Cell
            echo "\n<td class='dt-center'>" . $ctime1  . "</td>";       # Start Time Cell
            if ($ccode == 2) {
                echo "\n<td class='dt-center'>............</td>";       # Running - No End date Yet
                echo "\n<td class='dt-center'>............</td>";       # Running - No Elapse time
            }else{
                echo "\n<td class='dt-center'>" . $ctime2   . "</td>";  # Script Ending Time
                echo "\n<td class='dt-left'>"   . $celapsed . "</td>";  # Script Elapse Time
            }

            echo "\n<td class='dt-center'>" . $calert  . "</td>";       # Alert Group

            # DISPLAY THE SCRIPT STATUS BASED ON RETURN CODE ---------------------------------------
            echo "\n<td class='dt-left'><strong>";
            switch ($ccode) {
                case 0:  
                    echo "<font color='black'>Success</font></strong></td>";
                    break;
                case 1:  
                    echo "<font color='red'>Failed</font></strong></td>";
                    break;
                case 2:  
                    echo "<font color='green'>Running</font></strong></td>";
                    break;
                default: 
                    echo "<font color='red'>Code " .$ccode. "</font></td>";
                    break;;
            }
            
            # DISPLAY LINKS TO ACCESS HISTORY FILE (RCH) -------------------------------------------
            list($fname,$fext) = explode ('.',$cfile);                  # Isolate Script Name
            $LOGFILE = $fname . ".log";                                 # Add .log to Script Name
            echo "\n<td class='dt-center'>" ;
            $rch_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . trim($cfile) ;
            if (file_exists($rch_name)) {
                echo "<a href='" . $URL_VIEW_RCH . "?host=". $cserver ."&filename=". $cfile . 
                   "' data-toggle='tooltip' title='View Result Code History File'>History</a>";
            }else{
                echo "No File";                                         # If no RCH Exist
            }
            echo "</td>" ;

            # DISPLAY LINKS TO ACCESS THE LOG FILE -------------------------------------------------
            echo "\n<td class='dt-center'>" ;
            $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . trim($LOGFILE) ;
            if (file_exists($log_name)) {
                 echo "<a href='" . $URL_VIEW_FILE . "?filename=" . 
                 $log_name .  "' data-toggle='tooltip' title='View Script Log File'>Log</a>";
            }else{
                echo "No Log";                                          # If No log exist for script
            }
            echo "</td>" ;
            echo "\n</tr>\n";
        }
    }    
}




# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    # IF WE DID NOT RECEIVED ANY PARAMETER, THEN DEFAULT TO DISPLAYING ALL SCRIPTS STATUS ----------
    if (isset($_GET['sel']) ) {                                         # If Param Type recv.
        $SELECTION = $_GET['sel'];                                      # Get Page Type Received
    }else{                                                              # If No Param received
        $SELECTION = 'all';                                             # Default to All Scripts
    }
    if ($DEBUG) { echo "<br>Selection is " . $SELECTION; }              # Display Selection Received


    # MAKE SURE THAT /WWW/DAT DIRECTORY EXIST ON WEB SERVER-----------------------------------------
    if (! SADM_WWW_DAT_DIR) {                                           # If dat Directory not exist
        $msg = "Data Directory '" .SADM_WWW_DAT_DIR. "' don't exist\n"; # Inform User
        $msg = $msg."Cannot proceed with request";                      # Can't Proceed
        sadm_fatal_error ("$msg");
    }

    # VALIDATE THE PAGE TYPE RECEIVED - IF NOT SUPPORTED, BACK TO PREV PAGE ------------------------
    switch ($SELECTION) {
        case 'all'      :   $HDESC="All Scripts";                       # View All Scripts
                            break;                                       
        case 'failed'   :   $HDESC="Failed Scripts";                    # View Only Failed Scripts
                            break;                                       
        case 'running'  :   $HDESC="Running Scripts";                   # View Only Running Scripts
                            break;                                       
        case 'success'  :   $HDESC="Success Scripts";                   # View Only Succeed Scripts
                            break;                                       
        default         :   $msg="Invalid Page Type Received \n(" . $SELECTION . ")";
                            sadm_fatal_error ("$msg");                  # Advise user Invalid Type
    }

    # READ LAST LINE OF ALL *.RCH AND FILL THE SCRIPT ARRAY WITH RESULTS ---------------------------
	$script_array = build_sidebar_scripts_info();                       # Build Scripts Array
    if ($DEBUG) {                                                       # Display Array Just Build
        $xcount = 0 ;                                                   # Init Line Counter
        echo "<BR><BR>Array Nb. of elements: " . count($script_array);  # Nb. Of Items in Array
        foreach($script_array as $key=>$value) {                        # For each Item in Array
            $xcount += 1;                                               # Increase Line Counter
            echo "<br>$xcount - KEY IS $key AND VALUE IS $value";       # Display Array Key & Value
        }
    }

    # DISPLAY HEADING AND EACH LINES REQUESTED FROM THE ARRAY JUST BUILT ---------------------------
    display_std_heading("NotHome","$HDESC","","",$SVER);                # Display Content Heading
    setup_table();                                                      # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body
    display_script_array($con,$SELECTION,$script_array);                # Go Display Script Array
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div

    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
