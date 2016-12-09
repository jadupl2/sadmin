<?php
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_view_logfile.php
*   Version  :  1.5
*   Date     :  2 April 2016
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');
#init_set('error_reporting',E_ALL & ~E_NOTICE);

/*
* ==================================================================================================
*                                       Local Variables 
* ==================================================================================================
*/
# Activate or not Debug (Debug will display debugging info on the page)
$DEBUG = false ;                                                            # TRUE or FALSE

 

// =================================================================================================
//           D I S P L A Y    L O G   (WFILE)   F O R    T H E   S E L E C T E D   H O S T
//  For the received host ($WHOST) 
//  Host Description is also received (WDESC)
//  The LOG File Name (WNAME) file to display 
// =================================================================================================
function display_log_file ($WHOST,$WDESC,$WNAME)
{
    $TITRE="Content of log " . basename($WNAME);
    sadm_page_heading ("$TITRE");
    echo "<br><center><table id='table_rch'>\n";    

    #echo "<tr>\n" ;
    #echo "<th colspan=2>" . $TITRE . "</th>";
    #echo "</tr>\n";
    
    $count=0; $ddate = 0 ; 

    $fh = fopen($WNAME, "r") or exit("Unable to open file : " . $WNAME);
    while(!feof($fh)) {
        $wline = fgets($fh);
        if (strlen($wline) > 0) {
            $count+=1;
            echo "<tr>";
            $BGCOLOR = "#ffffcc";
            #if ($count % 2 == 0) { $BGCOLOR="#FFF8C6" ; }else{ $BGCOLOR="#FAAFBE" ;}
            echo "<td width=40>" . $count   . "</td>\n";
            echo "<td>" . $wline  . "</td>\n";
            echo "</tr>\n";
        }
    }
    fclose($fh);
    echo "</table>\n";
    return ;
}

 
 
 

/*
* ==================================================================================================
*                                           PROGRAM START HERE
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
            echo "<br>Host $HOSTNAME is not a valid host<br>";
            exit;
        }else{
            $HOSTDESC   = $row['srv_desc'];
        }
    }

// Get the second paramater (Name of LOG file to view)
    $LOG_FILENAME = $_GET['filename'];
    if ($DEBUG)  { echo "<br>FILENAME Received is $LOG_FILENAME "; } 
    $DIR = $_SERVER['DOCUMENT_ROOT'] . "/dat/" . $HOSTNAME . "/log/";
    if ($DEBUG)  { echo "<br>Directory of the log file is $DIR"; }

// If the LOG Directory does not exist then abort after adivising user
    $WDIR = SADM_WWW_DAT_DIR . "/" . $HOSTNAME . "/log";
    if (! is_dir($WDIR))  {
        echo "<br>The Web LOG Directory " . $WDIR . " does not exist.\n";
        echo "<br>Correct the situation and retry request\n";
         echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
        exit ;
    }

// If the LOG File does not exist then abort after adivising user
    if ($DEBUG)  { echo "<br>FILENAME Received is $LOG_FILENAME "; } 
    $LOGFILE = $WDIR . "/" . $LOG_FILENAME ;
    if ($DEBUG)  { echo "<br>Name of the LOG file is $LOGFILE"; }
    if (! file_exists($LOGFILE))  {
        echo "<br>The Web LOG file " . $LOGFILE . " does not exist.\n";
        echo "<br>Correct the situation and retry request\n";
         echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
        exit ;
    }
    
    display_log_file ($HOSTNAME, $HOSTDESC, $LOGFILE);

include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ; 
?>

