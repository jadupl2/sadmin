<?php
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_view_rchfile.php
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
* ==================================================================================================
*/
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php')  ;
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
include           ($_SERVER['DOCUMENT_ROOT'].'/sadmin/sadm_menu.php')  ;
#init_set('error_reporting',E_ALL & ~E_NOTICE);

/*
* ==================================================================================================
*                                       Local Variables 
* ==================================================================================================
*/
# Activate or not Debug (Debug will display debugging info on the page)
$DEBUG = FALSE ;															# TRUE or FALSE

 

// =================================================================================================
//           D I S P L A Y    R C H   (WFILE)   F O R    T H E   S E L E C T E D   H O S T
//  For the received host ($WHOST) 
//  Host Description is also received (WDESC)
//  The Sorted and Purge RCH File Name (WFILE) file to display 
//  The RCH File Name (WNAME)
// =================================================================================================
function display_rch_file ($WHOST,$WDESC,$WFILE,$WNAME)
{
	echo "<strong><font face='Verdana' size=3>Result of $WNAME</strong></font><br>";
	echo date('l jS \of F Y, h:i:s A');
    
    echo "<table align=center border=0 cellspacing=1>\n";    
   	$HDR_BGCOLOR = '#462066';
	$FNT_COLOR   = '#FFFFFF';
	$ATTR_BEFORE = "bgcolor=$HDR_BGCOLOR><font color=$FNT_COLOR><strong>";
	$ATTR_AFTER  = "</font></strong>";

    echo "<tr>\n" ;
    echo "<td width=50 align=center           ${ATTR_BEFORE}         ${ATTR_AFTER}</td>";
    echo "<td width=200 align=center colspan=2 ${ATTR_BEFORE}Start    ${ATTR_AFTER}</td>";
    echo "<td width=200 align=center colspan=2 ${ATTR_BEFORE}End    ${ATTR_AFTER}</td>";
    echo "<td align=center           ${ATTR_BEFORE}Elapse   ${ATTR_AFTER}</td>";
    echo "<td align=center           ${ATTR_BEFORE}Job      ${ATTR_AFTER}</td>";
    echo "</tr>\n";
    echo "<td align=center            ${ATTR_BEFORE}No.     ${ATTR_AFTER}</td>";
    echo "<td width=100 align='center' ${ATTR_BEFORE}Date    ${ATTR_AFTER}</td>";
    echo "<td width=100 align='center' ${ATTR_BEFORE}Time    ${ATTR_AFTER}</td>";
    echo "<td width=100 align='center' ${ATTR_BEFORE}Date    ${ATTR_AFTER}</td>";
    echo "<td width=100 align='center' ${ATTR_BEFORE}Time    ${ATTR_AFTER}</td>";
    echo "<td width=100 align='center' ${ATTR_BEFORE}Time    ${ATTR_AFTER}</td>";
    echo "<td width=100 align='center' ${ATTR_BEFORE}Status  ${ATTR_AFTER}</td>";
    echo "</tr>";
	
    $FREE_COLOR="#00FF00" ;
    $count=0; $ddate = 0 ; 

    $fh = fopen($WFILE, "r") or exit("Unable to open file" . $WFILE);
    while(!feof($fh)) {
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapse,$cname,$ccode) = explode(" ",fgets($fh));
        if ($cserver == $WHOST) {
            $count+=1;
            echo "<tr>";
            $BGCOLOR = "lavender";
            if ($count % 2 == 0) { $BGCOLOR="#FFF8C6" ; }else{ $BGCOLOR="#FAAFBE" ;}
            echo "<td align='center' bgcolor=$BGCOLOR>" . $count   . "</td>\n";
            echo "<td align='center' bgcolor=$BGCOLOR>" . $cdate1  . "</td>\n";
            echo "<td align='center' bgcolor=$BGCOLOR>" . $ctime1  . "</td>\n";
            echo "<td align='center' bgcolor=$BGCOLOR>" . $cdate2  . "</td>\n";
            echo "<td align='center' bgcolor=$BGCOLOR>" . $ctime2  . "</td>\n";
            echo "<td align='center' bgcolor=$BGCOLOR>" . $celapse . "</td>\n";
            switch ($ccode) {
                case 0:     echo "<td align='center' bgcolor=$BGCOLOR>Success</td>\n";
                            break;
                case 1:     echo "<td align='center' bgcolor='red'>Failed</td>\n";
                            break;
                case 2:     echo "<td align='center' bgcolor=$BGCOLOR>Running</td>\n";
                            break;
                default:    echo "<td align='center' bgcolor=$BGCOLOR>" . $ccode . "</td>\n";
                            break;
            }                    
            echo "</tr>\n";
        }
    }
	fclose($fh);
    echo "</table>\n";
    return ;
}

 
 
 

/*
* ==================================================================================================
*                              			 PROGRAM START HERE
* ==================================================================================================
*/

// Get the first Parameter (HostName of the rch file to view)
	if (isset($_GET['host']) ) { 
	    $HOSTNAME = $_GET['host'];
        if ($DEBUG)  { echo "<br>HOSTNAME Received is $HOSTNAME"; } 
		$query = "SELECT * FROM sadm.server where srv_name = '$HOSTNAME' ;";
        $result = pg_query($query) or die('Query failed: ' . pg_last_error());
        $row = pg_fetch_array($result, null, PGSQL_ASSOC);
	    if ($row = FALSE) {
	        echo "<br>Host $HOSTNAME is not a valid host<br.";
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
    display_rch_file ($HOSTNAME, $HOSTDESC, $csv_sorted, $RCV_FILENAME);
    if ($DEBUG) { echo "<br>Final File " . $csv_sorted ; }
    unlink($csv_sorted);
	
require       ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;
?>

