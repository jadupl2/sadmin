<?php
/*
* ================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_view_rch_summary.php
*   Version  :  1.5
*   Date     :  22 March 2016
*   Requires :  php
*   Synopsis :  Present a summary of all rch files received from all servers.
*   
*   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
*
*   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
*   of the GNU General Public License as published by the Free Software Foundation; either
*   version 2 of the License, or (at your option) any later version.
*
*   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*   See the GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License along with this program.
*   If not, see <http://www.gnu.org/licenses/>.
* ================================================================================================
*/
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');


# ==================================================================================================
# LOCAL VARIABLES 
# ==================================================================================================
#
$DEBUG = False  ;                                                       # Activate/Deactivate Debug



# ==================================================================================================
# DISPLAY RESULT CODE HISTORY FILE RESULTS HEADING FUNCTION
# ==================================================================================================
function display_rch_heading($HTYPE)
{
    # Set and Display Web Page Header
    $HDESC = "";
    if ($HTYPE == "all")      { $HDESC="All Scripts"; }
    if ($HTYPE == "running")  { $HDESC="Running Scripts"; }
    if ($HTYPE == "failed")   { $HDESC="Failed Scripts"; }
    if ($HTYPE == "success")  { $HDESC="Success Scripts"; }
    if ($HDESC == "") {
        echo "<br>Heading Display Type (" . $HTYPE . ") " . $HDESC . "is invalid<br>";
        echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
        exit(1);
    }
    sadm_page_heading ("Result Code History File results for $HDESC");
    
    # Main Body Page Section and Table Definition 
    echo "<center>\n";
    echo '<table id="sadmTable" class="display compact" cellspacing="0" width="100%">';
    
    # Table Font Size
    echo "<style>\n";
    echo "  th { font-size: 13px; }\n";
    echo "  td { font-size: 13px; }\n";
    echo "</style>\n";
    
    # Table Header 
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

    # Table Footer
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
    
    # Table Body
    echo "<tbody>\n";
}


# ==================================================================================================
# DISPLAY THE SCRIPT ARRAY FUNCTION
#  1st Parameter is the Page Heading Title
#  2nd Parameter is the Script Array 
# ==================================================================================================
function display_script_array($PAGE_TYPE, $script_array)
{
    global $DEBUG; 
    display_rch_heading($PAGE_TYPE);                                    # Display RCH Status Heading
    
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
            $query = "SELECT * FROM sadm.server where srv_name = '$cserver' ;";
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            $row = pg_fetch_array($result, null, PGSQL_ASSOC);
            if ($row) { $wdesc   = $row['srv_desc']; } else { $wdesc   = "Unknown"; }

            echo "<tr>\n";
            echo "<td class='dt-left'>" ;
            echo "<a href='/sadmin/sadm_view_server_info.php?host=" . $cserver . 
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
            echo "<td><a href='/sadmin/sadm_view_rchfile.php?host=". $cserver ."&filename=". $cfile . 
             "' data-toggle='tooltip' title='View Script Result History File'>View History</a></td>\n" ;
            echo "<td><a href='/sadmin/sadm_view_logfile.php?host=". $cserver . "&filename=" . 
             $LOGFILE .  "' data-toggle='tooltip' title='View Script Log File'>View Log</a></td>\n";
            echo "</tr>\n";
        }
    }    
    echo "</tbody></table></center><br><br>\n";
}




#===================================================================================================
#                                     PROGRAM START HERE
#===================================================================================================
#

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

# Display the script array 
    display_script_array($SELECTION,$script_array);                     # Go Display Script Array

# Include the Standard Web SADM Footer
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;
?>
