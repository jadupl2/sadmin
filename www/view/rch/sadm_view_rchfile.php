<?php
#
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_view_rchfile.php
#   Version  :  1.5
#   Date     :  22 March 2016
#   Requires :  php
#   Synopsis :  Present a summary of all rch files received from all servers.
#   
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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


// =================================================================================================
//           D I S P L A Y    R C H   (WFILE)   F O R    T H E   S E L E C T E D   H O S T
//  For the received host ($WHOST) 
//  Host Description is also received (WDESC)
//  The Sorted and Purge RCH File Name (WFILE) file to display 
//  The RCH File Name (WNAME)
// =================================================================================================
function display_rch_file ($WHOST,$WDESC,$WFILE,$WNAME)
{
    sadm_page_heading ("Result of $WNAME");
    echo "<center>\n";
    echo '<table id="sadmTable" class="display compact" cellspacing="0" width="100%">';
    echo '<style>';
    echo 'th { font-size: 13px; }';
    echo 'td { font-size: 13px; }';
    echo '</style>';
    echo "<thead>\n";
    echo "<tr>\n" ;
    echo "<th>No.</th>";
    echo "<th>Start Date</th>";
    echo "<th>Start Time</th>";
    echo "<th>End Date</th>";
    echo "<th>End Time</th>";
    echo "<th>Elapse Time</th>";
    echo "<th>Status</th>";
    echo "</tr>\n";
    echo "</thead>\n";

    echo "<tfoot>\n";
    echo "<tr>\n" ;
    echo "<th>No.</th>";
    echo "<th>Start Date</th>";
    echo "<th>Start Time</th>";
    echo "<th>End Date</th>";
    echo "<th>End Time</th>";
    echo "<th>Elapse Time</th>";
    echo "<th>Status</th>";
    echo "</tr>\n";
    echo "</tfoot>\n";
    echo "<tbody>\n";
    
    $FREE_COLOR="#00FF00" ;
    $count=0; $ddate = 0 ; 

    $fh = fopen($WFILE, "r") or exit("Unable to open file" . $WFILE);
    while(!feof($fh)) {
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$ccode) = explode(" ",fgets($fh));
        if ($cserver == $WHOST) {
            $count+=1;
            echo "<tr>\n";
            $BGCOLOR = "lavender";
            if ($count % 2 == 0) { $BGCOLOR="#FFF8C6" ; }else{ $BGCOLOR="#FAAFBE" ;}
            echo "<td>" . $count   . "</td>\n";
            echo "<td>" . $cdate1  . "</td>\n";
            echo "<td>" . $ctime1  . "</td>\n";
            echo "<td>" . $cdate2  . "</td>\n";
            echo "<td>" . $ctime2  . "</td>\n";
            echo "<td>" . $celapse . "</td>\n";
            switch ($ccode) {
                case 0:     echo "<td>Success</td>\n";
                            break;
                case 1:     echo "<td>Failed</td>\n";
                            break;
                case 2:     echo "<td>Running</td>\n";
                            break;
                default:    echo "<td>" . $ccode . "</td>\n";
                            break;
            }                    
            echo "</tr>\n";
        }
    }
    fclose($fh);
    echo "</tbody></table></center><br><br>\n";
    return ;
}

 
 
 

# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    echo "<div id='sadmRightColumn'>";                                  # Beginning Content Page

// Get the first Parameter (HostName of the rch file to view)
    if (isset($_GET['host']) ) { 
        $HOSTNAME = $_GET['host'];
        if ($DEBUG)  { echo "<br>HOSTNAME Received is $HOSTNAME"; } 
        $query = "SELECT * FROM sadm.server where srv_name = '$HOSTNAME' ;";
        $result = pg_query($query) or die('Query failed: ' . pg_last_error());
        $row = pg_fetch_array($result, null, PGSQL_ASSOC);
        if ($row = FALSE) {
            echo "<br>Host $HOSTNAME is not a valid host<br>";
            exit;
        }else{
            $HOSTDESC   = $row['srv_desc'];
        }
    }

// Get the second paramater (Name of RCH file to view)
    $RCV_FILENAME = $_GET['filename'];
    if ($DEBUG)  { echo "<br>FILENAME Received is $RCV_FILENAME "; } 
    $DIR = $_SERVER['DOCUMENT_ROOT'] . "/dat/" . $HOSTNAME . "/rch/";
    if ($DEBUG)  { echo "<br>Directory of the RCH file is $DIR"; }

// If the RCH Directory does not exist then abort after adivising user
    if (! is_dir($DIR))  {
        echo "<br>The Web RCH Directory " . $DIR . " does not exist.\n";
        echo "<br>Correct the situation and retry request\n";
         echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
        exit ;
    }

// If the RCH File does not exist then abort after adivising user
    if ($DEBUG)  { echo "<br>FILENAME Received is $RCV_FILENAME "; } 
    $RCHFILE = $DIR . $RCV_FILENAME ;
    if ($DEBUG)  { echo "<br>Name of the RCH file is $RCHFILE"; }
    if (! file_exists($RCHFILE))  {
        echo "<br>The Web RCH file " . $RCHFILE . " does not exist.\n";
        echo "<br>Correct the situation and retry request\n";
         echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
        exit ;
    }
    
    
    $tmpfile    = tempnam ('/tmp/', 'rchfiles-');
    $csv_sorted = tempnam ('/tmp/', 'rchfiles_sorted_');

    $cmd="grep -v '\.\.\.\.' $RCHFILE | sort -t, -rk 1,1 -k 2,2n > $csv_sorted";
    if ($DEBUG) { echo "<br>CMD = $cmd"; }
    $last_line = system($cmd, $retval);
    if ($DEBUG) { echo "<br><pre>cmd=$cmd lastline=$last_line retval=$retval</pre>"; }
    unlink($tmpfile);

    echo "\n<tbody>\n";                                                 # Start of Table Body
    display_rch_file ($HOSTNAME, $HOSTDESC, $csv_sorted, $RCV_FILENAME);
    if ($DEBUG) { echo "<br>Final File " . $csv_sorted ; }
    unlink($csv_sorted);
    
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div

    # COMMON FOOTING
    echo "</div> <!-- End of sadmRightColumn   -->" ;                   # End of Left Content Page       
    echo "</div> <!-- End of sadmPageContents  -->" ;                   # End of Content Page
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageFooter.php')  ;    # SADM Std EndOfPage Footer
    echo "</div> <!-- End of sadmWrapper       -->" ;                   # End of Real Full Page
?>

