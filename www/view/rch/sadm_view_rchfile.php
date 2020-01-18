<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_view_rchfile.php
#   Version  :  1.5
#   Date     :  22 March 2016
#   Requires :  php
#   Synopsis :  Present a summary of all rch files received from all servers.
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
#   Version 2.0 - November 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#   2018_02_01 J.Duplessis
#       V2.1 Correct Bug - Not showing last line of RCH when it was a running state (dot Date/Time)
# 2018_07_21  v2.2 Make screen more compact
#@2018_09_16  v2.3 Added Alert Group Display on Page
#@2019_06_07 Update: v2.4 Add Alarm type to page (Deal with new format).
#@2020_01_14 Update: v2.5 Add link to allow to view script log on the page.
#@2020_01_19 Update: v2.6 Remove line counter and some other cosmetics changes.
#
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
            "lengthMenu": [[25, 50, 100, -1], [25, 50, ,100, "All"]],
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
$SVER  = "2.6" ;                                                        # Current version number
$URL_VIEW_FILE = '/view/log/sadm_view_file.php';                        # View File Content URL


# ==================================================================================================
# SETUP TABLE HEADER AND FOOTER
# ==================================================================================================
function setup_table() {
    
    # TABLE CREATION
    echo "\n<div id='SimpleTable'>";                                      # Width Given to Table
    echo "\n<table id='sadmTable' class='display' cell-border compact row-border wrap width='90%'>";
    
    # PAGE TABLE HEADING 
    echo "\n<thead>";
    echo "\n<tr>" ;
    #echo "\n<th>No.</th>";
    echo "\n<th class='dt-head-center'>Start Date</th>";
    echo "\n<th class='dt-center'>Start Time</th>";
    echo "\n<th>End Date</th>";
    echo "\n<th>End Time</th>";
    echo "\n<th>Elapse Time</th>";
    echo "\n<th>Alert Group</th>";
    echo "\n<th>Alert Type</th>";
    echo "\n<th>Status</th>";
    echo "\n<th>Log</th>";
    echo "\n</tr>";
    echo "\n</thead>\n";

    # PAGE TABLE FOOTER 
    echo "\n<tfoot>";
    echo "\n<tr>" ;
    #echo "\n<th>No.</th>";
    echo "\n<th class='dt-head-center'>Start Date</th>";
    echo "\n<th class='dt-center'>Start Time</th>";
    echo "\n<th>End Date</th>";
    echo "\n<th>End Time</th>";
    echo "\n<th>Elapse Time</th>";
    echo "\n<th>Alert Group</th>";
    echo "\n<th>Alert Type</th>";
    echo "\n<th>Status</th>";
    echo "\n<th>Log</th>";
    echo "\n</tr>";
    echo "\n</tfoot>\n\n";
}


// =================================================================================================
//           D I S P L A Y    R C H   (WFILE)   F O R    T H E   S E L E C T E D   H O S T
//  1- For the received host ($WHOST) 
//  2- Host Description is also received (WDESC)
//  3- The Sorted and Purge RCH File Name (WFILE) file to display 
//  4- The RCH File Name (WNAME)
// =================================================================================================
function display_rch_file ($WHOST,$WDESC,$WFILE,$WNAME) {
    global $URL_VIEW_FILE ;
    $count=0; $ddate = 0 ;                                              # Reset Counter & Var.

    $fh = fopen($WFILE, "r") or exit("Unable to open file" . $WFILE);   # Open RCH  Requested file
    while (($wline = fgets($fh)) !== false) {                           # If Still Line to read
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$calert,$ctype,$ccode) = explode(" ",$wline);
        if ($cserver == $WHOST) {
            $count+=1;
            echo "\n<tr>";
            $BGCOLOR = "lavender";
            if ($count % 2 == 0) { $BGCOLOR="#FFF8C6" ; }else{ $BGCOLOR="#FAAFBE" ;}
            #echo "\n<td class='dt-center'>" . $count   . "</td>";
            echo "\n<td class='dt-center'>" . $cdate1  . "</td>";
            echo "\n<td class='dt-center'>" . $ctime1  . "</td>";
            echo "\n<td class='dt-center'>" . $cdate2  . "</td>";
            echo "\n<td class='dt-center'>" . $ctime2  . "</td>";
            echo "\n<td class='dt-center'>" . $celapse . "</td>";
            echo "\n<td class='dt-center'>" . $calert  . "</td>";

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

            # DISPLAY THE RESULT CODE 
            switch ($ccode) {
                case 0:     echo "\n<td class='dt-center'>Success</td>";
                            break;
                case 1:     echo "\n<td class='dt-center'>Failed</td>";
                            break;
                case 2:     echo "\n<td class='dt-center'>Running</td>";
                            break;
                default:    echo "\n<td class='dt-center'>" . $ccode . "</td>";
                            break;
            }       
            
            # Display Log Link
            echo "\n<td class='dt-center'>" ;
            $x = basename($WNAME, '.rch');                              # Remove RCH file extension
            $LOGFILE = $x . ".log";                                     # Add .log to Script Name
            $log_name  = SADM_LOG_DIR . "/" . $LOGFILE ;
            if (file_exists($log_name)) {
                echo "<a href='" . $URL_VIEW_FILE . "?filename=" . 
                $log_name .  "' data-toggle='tooltip' title='View script log file.'>[log]</a>&nbsp;&nbsp;&nbsp";
            }else{
                echo "No Log";                                          # If No log exist for script
            }
            echo "</td>";

            echo "\n</tr>\n";
        }
    }
    fclose($fh);
    return ;
}

 
 
 

# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    # GET THE FIRST PARAMETER (HOSTNAME OF THE RCH FILE TO VIEW) & VALIDATE IT ---------------------
    if (isset($_GET['host']) ) { 
        $HOSTNAME = $_GET['host'];
        if ($DEBUG)  { echo "<br>HOSTNAME Received is $HOSTNAME"; } 
        $sql = "SELECT * FROM server where srv_name = '$HOSTNAME' ;";
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Category (" . $wkey . ") not found.\n";        # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_fatal_error($err_msg1.$err_msg2.$err_msg3.$err_msg4);  # Display Msg. Box for User
        }else{                                                          # If row was found
            $row = mysqli_fetch_assoc($result);                         # Read the Associated row
        }
        $row = mysqli_fetch_assoc($result);                             # Get Column Row Array 
        if ($row = FALSE) {                                             # If Now row Array
            $msg = "Host $HOSTNAME is not a valid host";                 # Error Message to user
            sadm_fatal_error($msg);                                     # Display Error & Go Back
        }else{
            $HOSTDESC   = $row['srv_desc'];                             # Save Host Description
        }
    }

    # GET THE SECOND PARAMETER (NAME OF RCH FILE TO VIEW) ------------------------------------------
    $RCV_FILENAME = $_GET['filename'];                                  # Extract Filename of RCH
    if ($DEBUG)  { echo "<br>FILENAME Received is $RCV_FILENAME "; }    # If Debug display RCH Name
    $DIR = $_SERVER['DOCUMENT_ROOT'] . "/dat/" . $HOSTNAME . "/rch/";   # RCH Host Directory Name
    if ($DEBUG)  { echo "<br>Directory of the RCH file is $DIR"; }      # Debug display Dir. of RCH

    # IF THE RCH DIRECTORY DOES NOT EXIST THEN ABORT AFTER ADIVISING USER --------------------------
    if (! is_dir($DIR))  {                                              # If RCH Dir.do not exist
        $msg = "The Web RCH Directory " . $DIR . " does not exist.\n";  # Display Dir. name
        $msg = $msg . "Correct the situation and retry request";        # Needed to proceed
        sadm_fatal_error($msg);                                         # MsgBox to user
    }

    # IF THE RCH FILE DOES NOT EXIST THEN ABORT AFTER ADIVISING USER -------------------------------
    if ($DEBUG)  { echo "<br>FILENAME Received is $RCV_FILENAME "; }    # Debug display Rcv Filename
    $RCHFILE = $DIR . $RCV_FILENAME ;                                   # Construct Full Path to RCH
    if ($DEBUG)  { echo "<br>Name of the RCH file is $RCHFILE"; }       # Debug print full path RCH
    if (! file_exists($RCHFILE))  {                                     # If RCH File Not Found
        $msg = "The Web RCH file " . $RCHFILE . " does not exist.\n";   # Message to user
        $msg = $msg . "Correct the situation and retry request";        # Needed to proceed
        sadm_fatal_error($msg);                                         # MsgBox to user
    }
    
    
    $tmpfile    = tempnam ('/tmp/', 'rchfiles-');                       # Create Tmp File Unsorted
    $csv_sorted = tempnam ('/tmp/', 'rchfiles_sorted_');                # Create Tmp file Sorted

    # Eliminate line with dotted date & time and Create Sorted RCH file
    $cmd="grep -v '\.\.\.\.' $RCHFILE | sort -t, -rk 1,1 -k 2,2n > $tmpfile";
    if ($DEBUG) { echo "<br>CMD = $cmd"; }
    $last_line = system($cmd, $retval);
    if ($DEBUG) { echo "<br><pre>cmd=$cmd lastline=$last_line retval=$retval</pre>"; }

    # Always want the last line of rch file (Maybe a line with dot (running) and we want that one)
    $cmd="tail -1 $RCHFILE >> $tmpfile";
    if ($DEBUG) { echo "<br>CMD = $cmd"; }
    $last_line = system($cmd, $retval);
    if ($DEBUG) { echo "<br><pre>cmd=$cmd lastline=$last_line retval=$retval</pre>"; }

    # Sort Resulting file - Eliminate the last line inserted if it was already in the file
    $cmd="cat $tmpfile | sort -t, -rk 1,1 -k 2,2n | uniq > $csv_sorted";
    if ($DEBUG) { echo "<br>CMD = $cmd"; }
    $last_line = system($cmd, $retval);
    if ($DEBUG) { echo "<br><pre>cmd=$cmd lastline=$last_line retval=$retval</pre>"; }
    unlink($tmpfile);

    display_lib_heading("NotHome","[R]esult [C]ode [H]istory file viewer",$RCHFILE,$SVER);      
    setup_table();                                                      # Create Table & Heading
    echo "\n<tbody>\n";                                                 # Start of Table Body
    display_rch_file ($HOSTNAME, $HOSTDESC, $csv_sorted, $RCV_FILENAME);# Go Display RCH File
    if ($DEBUG) { echo "<br>Final File " . $csv_sorted ; }              # Name of filename sorted
    unlink($csv_sorted);                                                # Delete Tmp file Sorted
    
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>

