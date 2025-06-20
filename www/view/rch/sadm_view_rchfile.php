<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_view_rchfile.php
#   Version  :  1.5
#   Date     :  22 March 2016
#   Requires :  php
#   Synopsis :  Present a summary of all rch files received from all servers.
#   
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   Version 2.0 - November 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#   2018_02_01 J.Duplessis
#       V2.1 Correct Bug - Not showing last line of RCH when it was a running state (dot Date/Time)
# 2018_07_21 web v2.2 Make screen more compact
# 2018_09_16 web v2.3 Added Alert Group Display on Page
# 2019_06_07 web v2.4 Add Alarm type to page (Deal with new format).
# 2020_01_14 web v2.5 Add link to allow to view script log on the page.
# 2020_01_19 web v2.6 Remove line counter and some other cosmetics changes.
# 2020_01_21 web v2.7 Display rch date in date reverse order (Recent at the top)
# 2020_04_05 web v2.8 Fix link problem to show the script log.
# 2020_04_17 web v2.9 Running script are now shown on the page.
# 2021_08_06 web v2.10 Remove repetitive link to log.
# 2021_08_29 web v2.11 Result Code History viewer, show effective alert group instead of 'default.'
# 2021_00_05 web v2.13 RCH file viewer; Make rch line more compact.
#@2025_06_13 web v2.14 Enhance overall page look and add more information.
#
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
            "lengthMenu": [[25, 50, 100, -1], [25, 50, ,100, "All"]],
            "bJQueryUI" : true,
            "paging"    : true,
            "order"     : [[ 0, "desc" ]],
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
    padding-top: 4px;
    padding-bottom: 4px;
    padding-left: 6px;
    padding-right: 6px;
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


# Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.13" ;                                                       # Current version number







# Setup Table Header And Footer
# ==================================================================================================
function display_heading() {
    
    echo "<div id='MyTable'>\n"; 
    echo "<table class='content-table' border=1>\n" ; 
    
    echo "\n<thead>\n";
    echo "\n  <tr align=center bgcolor='grey'>";
    echo "\n        <th align='center' width=12>No</th>";
    echo "\n        <th align='center' width=110>Start Date & Time</th>";
    echo "\n        <th align='center' width=110>End Date & Time</th>";
    echo "\n        <th align='center' width=60>Duration"; 
    echo "\n        <th align='center'>Alert Group</th>";
    echo "\n        <th align='center'>Notification Type</th>";
    echo "\n        <th align='center'>Status</th>";
    echo "\n  </tr>";
    echo "\n</thead>\n";

    echo "\n<tfoot>";
    echo "\n  <tr align=center bgcolor='grey'>";
    echo "\n        <th align='center' width=12>No</th>";
    echo "\n        <th align='center' width=110>Start Date & Time</th>";
    echo "\n        <th align='center' width=110>End Date & Time</th>";
    echo "\n        <th align='center' width=60>Duration"; 
    echo "\n        <th align='center'>Alert Group</th>";
    echo "\n        <th align='center'>Notification Type</th>";
    echo "\n        <th align='center'>Status</th>";
    echo "\n  </tr>";
    echo "\n</tfoot>\n\n";
}





# Display RCH file for the RCH File
# Parameters received : 
#      1- $GET_HOSTNAME System Host Name 
#      2- The RCH File Name (WNAME)
#      3- The Sorted and Purge RCH File Name (WFILE) file to display 
# =================================================================================================
function display_rch_file ($GET_HOSTNAME, $GET_RCHFILE, $SORTED_RCHFILE)
{
    if ($DEBUG) {                                                       # Show parameters received
        echo "<br>GET_HOSTNAME   = " . $GET_HOSTNAME ;    
        echo "<br>GET_RCHFILE    = " . $GET_RCHFILE ;    
        echo "<br>SORTED_RCHFILE = " . $SORDTED_RCHFILE ; 
    } 
    
    
    # Open sorted RCH file and read it line by line.
    # Template RCH line format is ($rch_array): 
    # $whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$walert,$gtype,$wcode
    #    0      1       2       3       4       5       6         7       8      9  
    $fh = fopen($SORTED_RCHFILE, "r") or exit ("Unable to open file : " . $SORTED_RCHFILE); 
        
    $count = 0 ;                                                        # Reset Line Counter 
    while (($wline   = fgets($fh)) !== false) {                         # While Still Line to read
        $rch_array   = explode(" ",$wline);                             # Split rch line into array
        $now         = time();                                          # Get Current epoch time
        $your_date   = strtotime(str_replace(".", "-",$rch_array[1]));  # RCH Date in epoch time
        $datedif     = $now - $your_date;                               # Sec. diff. now & RCH date
        $rchline_age = round($datediff / (60 * 60 * 24));               # Convert sec. in Days 

        $count+=1;
        echo "\n<tr align=left bgcolor='lightgrey'>\n";
        echo "\n<td align='center'>$count</td>";  
        $BGCOLOR = "lavender";
        if ($count % 2 == 0) { $BGCOLOR="#FFF8C6" ; }else{ $BGCOLOR="#FAAFBE" ;}
        echo "\n<td align='center'>" . $rch_array[1] . "  ". $rch_array[2] . "</td>";
        echo "\n<td align='center'>" . $rch_array[3] . "  ". $rch_array[4] . "</td>";
        echo "\n<td align='center'>" . $rch_array[5] . "</td>";
        
        # Show Notification Group with Tooltip
        echo "\n<td width=180 align='left'>";
        list($calert, $alert_group_type, $stooltip) = get_alert_group_data ($rch_array[7]) ;
        echo "<span data-toggle='tooltip' title='" . $stooltip . "'>"; 
        echo $calert . "</span>(" . $alert_group_type . ")</td>";             


        # Show Alert type
        switch ($rch_array[8]) {                                           
            case 0 :                                                # 0=Don't send any Alert
                $alert_type_msg="No notification (code 0)" ;        # No Alert even if failed.
                $etooltip="'SADM_ALERT' set to 0 in script " . $cname ;
                break;
            case 1 :                                                # 1=Send Alert on Error
                $alert_type_msg="Notification only on error (code 1)"; 
                $etooltip="'SADM_ALERT' set to 1 in script " .$cname; # Tooltips  
                break;
            case 2 :                                                # 2=Send Alert on Success
                $alert_type_msg="Notification only on success (code 2)"; 
                $etooltip="'SADM_ALERT' set to 2 in script " . $cname ;
                break;
            case 3 :                                                # 3=Always Send Alert
                $alert_type_msg="Always send notification (code 3)";
                $etooltip="'SADM_ALERT' set to 3 in script " . $cname ;
                break;
            default:
                $alert_type_msg="Notification invalid type (code $rch_array[8]).";  
                $etooltip="SADM_ALERT is set to ($rch_array[8]) in script " . $cname ;
                break;
        }    

        echo "\n<td width=200 align=left'>";
        echo "<span data-toggle='tooltip' title='" .$etooltip. "'>" .$alert_type_msg. "</span>"; 
        echo "</td>"; 
   

        # Display The Result Code 
        switch ($ccode) {
            case 0:     echo "\n<td width=100 align='center'>Success</td>";
                        break;
            case 1:     echo "\n<td width=100 align='center'>Failed</td>";
                        break;
            case 2:     echo "\n<td width=100 align='center'>Running</td>";
                        break;
            default:    echo "\n<td width=100 align='center'>" . $ccode . "</td>";
                        break;
        }    

        echo "\n</tr>\n";
    }

    fclose($fh);
    return ;
}

 
 
 

# Program Start Here
# ==================================================================================================

    # Get First Parameter (Hostname) and validate that it exist in the SADMIN database.
    if (isset($_GET['host']) ) {                                        # If Hostname is Receive/Set
        $GET_HOSTNAME = $_GET['host'];                                  # Get GET_HOSTNAME Value
        if ($DEBUG)  { echo "<br>1st parameter : " . $GET_HOSTNAME; }   # In Debug display RCH Name
        
        # SQL to See if the hostname received is valid.
        $sql = "SELECT * FROM server where srv_name = '$GET_GET_HOSTNAME' ;";   # Check if in DB 
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error with SQL 
            $err_msg1 = "System (" . $GET_HOSTNAME . "\nAt line "  ;    # Insert Err Msg and Line No 
            $err_msg2 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_fatal_error($err_msg1.$err_msg2);                      # Display Msg. Box for User
        }
        $row = mysqli_fetch_assoc($result);                             # Get Column Row Array 
        if ($row = false) {                                             # If No row Array
            $msg = "Host '$GET_HOSTNAME' is not a valid host name.";    # Error Message to user
            sadm_fatal_error($msg);                                     # Display Error & Go Back
        }
    }


    # (2nd parameter) 
    # Validate that global RCH directory exist (directory where the RCH file reside).
    $GET_RCHFILE = $_GET['filename'];                                   # Extract Filename of RCH
    if ($DEBUG)  { echo "<br>2nd parameter : " .$GET_RCHFILE; }         # In Debug display RCH Name
    $DIR = $_SERVER['DOCUMENT_ROOT'] . "/dat/" .$GET_HOSTNAME ."/rch/"; # RCH Host Directory Name
    if (! is_dir($DIR))  {                                              # If RCH Dir.do not exist
        $msg = "The global RCH directory '" . $DIR . "' does not exist.\n"; 
        $msg = $msg . "No RCH file to display.";                        # Needed to proceed
        sadm_fatal_error($msg);                                         # MsgBox to user
    }


    # If The Rch File Does Not Exist, then advise user and abort page display  .
    $RCHFILE = $DIR . $GET_RCHFILE ;                                    # Construct Full Path to RCH
    if ($DEBUG)  { echo "<br>Full path to rch file : $RCHFILE"; }       # Debug print full path RCH
    if (! file_exists($RCHFILE))  {                                     # If RCH File Not Found
        $msg = "The requested RCH file '" . $RCHFILE . "' was not found.\n";   # Message to user
        $msg = $msg . "No RCH file to display.";                        # Needed to proceed
        sadm_fatal_error($msg);                                         # MsgBox to user
    }
    
        
    # Sort the RCH file, with recent date/time first.
    $SORTED_RCHFILE = tempnam ('/tmp/', 'rchfiles_sorted_');            # Create Tmp file Sorted
    if ($DEBUG) { echo "<br>SORTED_RCHFILE : " . $SORTED_RCHFILE ; } 
    $cmd="sort -t, -rk 1,1 -k 2,2n $RCHFILE > $SORTED_RCHFILE";         # CMD to Sort by date & time
    $rchline = system($cmd, $retval);                                   # Execute Sort Command     
    if ($DEBUG) { echo "<br>cmd=$cmd rchline=$rchline retval=$retval"; }

    
    # Display Standard page Heading
    display_lib_heading ("NotHome","[R]esult [C]ode [H]istory Viewer",$RCHFILE,$SVER);      
    display_heading();                                                  # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body

    
    # Display the requested RCH file.
    display_rch_file ($GET_HOSTNAME, $GET_RCHFILE, $SORTED_RCHFILE);    # Go Display RCH File
    #unlink($SORTED_RCHFILE);                                           # Delete Tmp file Sorted
    
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>

