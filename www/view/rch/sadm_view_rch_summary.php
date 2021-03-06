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
#   If not, see <http://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#   2018_05_06 JDuplessis
#       2.1 Change to use sadm_view_file instead of sadm_view_log 
# 2018_07_21  v2.2 Screen disposition adjustments
# 2018_09_16  v2.3 Added Alert group Display 
# 2019_06_07 Update: v2.4 Add Alarm type to page (Deal with new format).
# 2019_09_20 Update v2.5 Show History (RCH) content using same uniform way.
#@2020_12_13 Update v2.6 Add link in the heading to view the Daily Scripts Report, if HTML exist.
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
$DEBUG              = False ;                                           # Debug Activated True/False
$SVER               = "2.6" ;                                           # Current version number
$CREATE_BUTTON      = False ;                                           # Yes Display Create Button
$URL_HOST_INFO      = '/view/srv/sadm_view_server_info.php';            # Display Host Info URL
$URL_VIEW_RCH       = '/view/rch/sadm_view_rchfile.php';                # View RCH File Content URL
$URL_VIEW_FILE      = '/view/log/sadm_view_file.php';                   # View File Content URL
$URL_REAR_REPORT    = "/view/daily_rear_report.html";                   # Rear Daily Report Page
$URL_BACKUP_REPORT  = "/view/daily_backup_report.html";                 # Backup Daily Report Page
$URL_STORIX_REPORT  = "/view/daily_storix_report.html";                 # Storix Daily Report Page
$URL_SCRIPTS_REPORT = "/view/daily_scripts_report.html";                # Scripts Daily Report Page


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
    echo "<th class='dt-head-center'>Alert Group</th>\n";
    echo "<th class='dt-head-center'>Alert Type</th>\n";
    echo "<th class='dt-head-left'>Status</th>\n"; 
    echo "<th class='text-center'>View Log / History</th>\n";
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
    echo "<th class='dt-head-center'>Alert Group</th>\n";
    echo "<th class='dt-head-center'>Alert Type</th>\n";
    echo "<th class='dt-head-left'>Status</th>\n"; 
    echo "<th class='text-center'>View Log / History</th>\n";
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
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$calert,$ctype,$ccode,$cfile) = 
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
            echo "<a href='" . $URL_HOST_INFO . "?sel=" . $cserver . 
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

            echo "\n<td class='dt-center'>" . $calert  . "</td>";       # Alert Group Name & Type
            #echo "\n<td class='dt-center'>" . $calert  . "/" . $ctype . "</td>";       # Alert Group Name & Type
          
            # DISPLAY THE ALERT GROUP TYPE (0=None 1=AlertOnErr 2=AlertOnOK 3=Always)
            echo "\n<td class='dt-center'>";
            switch ($ctype) {
                case 0:  
                    echo "0 (No alert)</td>";
                    break;
                case 1:  
                    echo "1 (Alert on error)</td>";
                    break;
                case 2:  
                    echo "2 (Alert on Success)</td>";
                    break;
                case 3:  
                    echo "3 (Always alert)</td>";
                    break;
                default: 
                    echo "<font color='red'>Wront type " .$ctype. "</font></td>";
                    break;;
            }
          
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
            
            
            # DISPLAY LINKS TO ACCESS THE LOG FILE -------------------------------------------------
            echo "\n<td class='dt-center'>" ;
            list($fname,$fext) = explode ('.',$cfile);                  # Isolate Script Name
            $LOGFILE = $fname . ".log";                                 # Add .log to Script Name
            $log_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/log/" . trim($LOGFILE) ;
            if (file_exists($log_name)) {
                echo "<a href='" . $URL_VIEW_FILE . "?filename=" . 
                $log_name .  "' data-toggle='tooltip' title='View script log file.'>Log</a>&nbsp;&nbsp;&nbsp";
            }else{
                echo "No Log";                                          # If No log exist for script
            }
 
            # DISPLAY LINKS TO ACCESS HISTORY FILE (RCH) -------------------------------------------
            $rch_name  = SADM_WWW_DAT_DIR . "/" . $row['srv_name'] . "/rch/" . trim($cfile) ;
            if (file_exists($rch_name)) {
                echo "<a href='" . $URL_VIEW_RCH . "?host=". $cserver ."&filename=". $cfile . 
                   "' data-toggle='tooltip' title='View History (rch) file.'>History</a>";
            }else{
                echo "No File";                                         # If no RCH Exist
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
        case 'all'      :   $HDESC="Status of all Scripts";             # View All Scripts
                            break;                                       
        case 'failed'   :   $HDESC="List of script(s) that failed";     # View Only Failed Scripts
                            break;                                       
        case 'running'  :   $HDESC="List of running script(s)";         # View Only Running Scripts
                            break;                                       
        case 'success'  :   $HDESC="Scripts that ran successfully";     # View Only Succeed Scripts
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
    $title1="$HDESC";
    $title2="";
    if (file_exists(SADM_WWW_DIR . "/view/daily_scripts_report.html")) {
        $title2="<a href='" . $URL_SCRIPTS_REPORT . "'>View the Daily Scripts Report</a>"; 
    }       
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Content Heading
    setup_table();                                                      # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body
    display_script_array($con,$SELECTION,$script_array);                # Go Display Script Array
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
