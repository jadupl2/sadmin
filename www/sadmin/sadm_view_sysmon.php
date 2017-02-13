<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis
*   Title       :  sadm_view_sysmon.php
*   Version     :  1.5
*   Date        :  4 February 2017
*   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
*   Description :  This page allow to view the servers alerts information in various ways
*                  depending on parameters received.
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');

#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                          # Activate Debug True/False
$tmp_file1          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp1_');
$tmp_file2          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp2_');
$tmp_file3          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp3_');
$array_sysmon = [];                                                     # Create Empty Array
$alert_file = SADM_TMP_DIR . "/www_sysmon_file_" . getmypid() ;         # File Being Built/Displayed

#===================================================================================================
#                                   Display Alert section Heading 
#===================================================================================================
function display_degug_info() {
    global $DEBUG, $tmp_file1, $tmp_file2, $tmp_file3 ;
    if ($DEBUG)  { 
        echo "\n<br>Input temp1 file name is " . $tmp_file1 ; 
        echo "\n<br>Input temp2 file name is " . $tmp_file2 ; 
        echo "\n<br>Input temp3 file name is " . $tmp_file3 ;
    }
}


#===================================================================================================
# This function create one file ______ that merge the *.rpt in /sadmin/www/dat with the *.rch in 
# /sadmin/dat that are runnign or finish with errors (doesn't have a "0" (success) in last column)
# File in then loaded into an array (sysmon_array).
#===================================================================================================
function load_sysmon_array() {
    global $DEBUG, $tmp_file1, $tmp_file2, $tmp_file3, $alert_file ;

    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rpt' -exec cat {} \; > $alert_file";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "\n<br>Return code of command is : " . $RCODE ; }

    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rch' -exec tail -1 {} \; > $tmp_file2";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "\n<br>Return code of command is : " . $RCODE ; }

    $CMD="awk 'match($8,/[1-2]/) { print }' $tmp_file2 > $tmp_file3" ;
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "\n<br>Return code of command is : " . $RCODE ; }

    # Load RCH Line into Array
    $lines = file($tmp_file3);
    # CONVERT THESE KIND OF LINES 
    #debian7 2017.02.09 00:06:02 2017.02.09 00:06:02 00:00:00 sadm_rear_backup 1
    #   1        2         3         4        5        6          7            8
    # TO THIS TYPE OF LINE
    # Error;nano;2017.02.08;17:00;SERVICE;PROCESS;Service syslogd not running !;sadm;sadm; 
    #   1    2       3        4      5       6             7                     8     9
    $afile = fopen("$alert_file","a") or die("can't open in append mode file " . $alert_file );
       
   foreach ($lines as $line_num => $line) {
        if ($DEBUG) { echo "\n<br>RCH Before conversion - Ligne #<b>{$line_num}</b> : " . htmlspecialchars($line) ; }
        list($whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$wcode) = explode(" ",htmlspecialchars($line));
        $rtype    = "";  $rhost       = "";  $rdate = ""; $rtime  = ""; 
        $rmod = "";  $rsubmod = "";  $rdesc = ""; $rqage = ""; 
        $remail   = "";
        $rdate = trim($wdate2);
        $rtime = trim($wtime2);
        switch (trim($wcode)) {
            case 0:
                $rtype = "Success" ;
                break;
            case 1:
                $rtype = "Error" ;
                break;
            case 2:
                $rtype = "Running" ;
                $rdate = trim($wdate1);
                $rtime = trim($wtime1);
                break;
            default:
                $rtype = "Unknown" ;
                break;
        }
        $rhost = trim($whost);
        $rmod = "SADM"; 
        $rsubmod = "SCRIPT";
        $rpage = "sadm";
        $rmail = "sadm";
        $rdesc = "Script " . $wscript;
        $LINE = "${rtype};${rhost};${rdate};${rtime};${rmod};${rsubmod};${rdesc};${rpage};${rmail}\n";
        if ($DEBUG) { echo "\n<br>RCH After conversion - Ligne #<b>{$line_num}</b> : " . htmlspecialchars($LINE) ; }
        fwrite($afile,$LINE);
    }
    fclose($afile);

    if ($DEBUG) { echo "\n\n<br><br>Debug Information - Alert file Content"; }
    $lines = file($alert_file);
    foreach ($lines as $line_num => $line) {
        if ($DEBUG) { echo "\n<br>Ligne #<b>{$line_num}</b> : " . htmlspecialchars($line) . "\n"; }
    }
    
    # Delete Work Files
    unlink($tmp_file1);
    unlink($tmp_file2);
    unlink($tmp_file3);
}


#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function display_heading($line_title) {
    global $DEBUG ;

    sadm_page_heading ("$line_title");                                  # Display Page Title
    echo "<center>\n";                                                  # Table Centered on Page
  
    # Set Font Size for Table Cell and Table Heading
    echo "<style>\n";
    echo "td { font-size: 12px; }\n";
    echo "th { font-size: 13px; }\n";
    echo "</style>\n";
    #echo '<table id="sadmTable" class="display compact nowrap" border="0" cellpadding="0" cellspacing="0" width="100%">';
    echo '<table id="sadmTable" class="display compact nowrap" width="100%">';

    # Server Table Heading
    echo "<thead>\n";
    echo "<tr>\n";
    echo "<th>Status</th>\n";
    echo "<th>Server</th>\n";
    echo "<th> </th>\n";
    echo "<th>Server Description</th>\n";
    echo "<th>Cat.</th>\n";
    echo "<th>Date</th>\n";
    echo "<th>Time</th>\n";
    echo "<th>Module</th>\n";
    echo "<th>SubModule</th>\n";
    echo "<th>Description</th>\n";
    echo "<th>Alert Grp</th>\n";
    echo "<th>Email Grp</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Server Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    echo "<th>Status</th>\n";
    echo "<th>Server</th>\n";
    echo "<th> </th>\n";
    echo "<th>Server Description</th>\n";
    echo "<th>Cat.</th>\n";
    echo "<th>Date</th>\n";
    echo "<th>Time</th>\n";
    echo "<th>Module</th>\n";
    echo "<th>SubModule</th>\n";
    echo "<th>Description</th>\n";
    echo "<th>Alert Grp</th>\n";
    echo "<th>Email Grp</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";

    # Start of Table Body
    echo "<tbody>\n";
}


#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data() {
    global $DEBUG, $alert_file ;
    $array_sysmon = file($alert_file);                                  # Put Alert file in Array
    rsort($array_sysmon);
       
    foreach ($array_sysmon as $line_num => $line) {
        if ($DEBUG) { echo "Line #<b>{$line_num}</b> : " . htmlspecialchars($line) . "<br />\n"; }
        list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$wpage,$wmail) = explode(";",$line);
        echo "<tr>\n";  

        #echo "<td>" . nl2br($wstatus)   . "</td>\n";  
        switch (strtoupper($wstatus)) {
            case 'SUCCESS' :
                echo "<td><img src='/images/success.png' style='width:32px;height:32px;'></td>\n";
                break;
            case 'ERROR' :
                echo "<td><img src='/images/error.png' style='width:32px;height:32px;'></td>\n";
                break;
            case 'WARNING' :
                echo "<td><img src='/images/warning.png' style='width:32px;height:32px;'></td>\n";
                break;
            case 'RUNNING' :
                echo "<td><img src='/images/running.png' style='width:32px;height:32px;'></td>\n";
                break;
            default:
                echo "<td><img src='/images/question_mark.png' style='width:32px;height:32px;'></td>\n";
                break;
        }

        echo "<td><a href=/sadmin/sadm_view_server_info.php?host=" . nl2br($whost) .  ">" . nl2br($whost) . "</a></td>\n";
        $query = "SELECT * FROM sadm.server where srv_name = '". $whost . "';";
        $result = pg_query($query) or die('Query failed: ' . pg_last_error());
        $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;
        $WDESC = sadm_clean_data($row['srv_desc']);
        $WCAT  = sadm_clean_data($row['srv_cat']);

        $WOS   = sadm_clean_data($row['srv_osname']);
        switch (strtoupper($WOS)) {
            case 'REDHAT' :
                echo "<td><a href='http://www.redhat.com' title='Server $whost is a RedHat server - Visit redhat.com'><img src='/images/redhat.png' style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'FEDORA' :
                echo "<td><a href='https://getfedora.org' title='Server $whost is a Fedora server - Visit getfedora.org'><img src='/images/fedora.png' style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'CENTOS' :
                echo "<td><a href='https://www.centos.org' title='Server $whost is a CentOS server - Visit centos.org'><img src='/images/centos.png' style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'UBUNTU' :
                echo "<td><a href='https://www.ubuntu.com/' title='Server $whost is a Ubuntu server - Visit ubuntu.com'><img src='/images/ubuntu.png' style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'DEBIAN' :
                echo "<td><a href='https://www.debian.org/' title='Server $whost is a Debian server - Visit debian.org'><img src='/images/debian.png' style='width:32px;height:32px;'></a<</td>\n";
                break;
            case 'RASPBIAN' :
                echo "<td><a href='https://www.raspbian.org/' title='Server $whost is a Raspbian server - Visit raspian.org'><img src='/images/raspbian.png' style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'SUSE' :
                echo "<td><a href='https://www.opensuse.org/' title='Server $whost is a OpenSUSE server - Visit opensuse.org'><img src='/images/suse.png' style='width:32px;height:32px;'></a></td>\n";
                break;
            case 'AIX' :
                echo "<td><a href='http://www-03.ibm.com/systems/power/software/aix/' title='Server $whost is an AIX server - Visit Aix Home Page'><img src='/images/aix.png' style='width:32px;height:32px;'></a></td>\n";
                break;
            default:
                echo "<td><img src='/images/os_unknown.jpg' style='width:32px;height:32px;'></td>\n";
                break;
        }

        echo "<td>" . $WDESC    . "</td>\n";  
        echo "<td>" . $WCAT     . "</td>\n";  
        echo "<td>" . $wdate   . "</td>\n";  
        echo "<td>" . $wtime   . "</td>\n";  
        echo "<td>" . strtoupper($wmod)   . "</td>\n";  
        echo "<td>" . strtoupper($wsubmod)   . "</td>\n";  
        echo "<td>" . $wdesc   . "</td>\n";  
        echo "<td>" . $wpage   . "</td>\n";  
        echo "<td>" . $wmail   . "</td>\n";  
    }
    echo "</tbody></table></center><br><br>\n";                         # End of tbody,table
    echo "<center><br><br>";
    echo "<b>This page will refresh automatically every minute - " . date('l jS \of F Y h:i:s A');
    echo "</br></center>";
}
    

#===================================================================================================
#                                      PROGRAM START HERE
#===================================================================================================
#
    display_heading("SADM SysMon Alert");                               # Display Page Heading
    display_degug_info();                                               # Debug Information
    load_sysmon_array();                                                # Load RPT and RCH File
    display_data();                                                     # Display SysMOn Array
    @unlink($tmp_file1);                                                # Delete Work Files 1
    @unlink($tmp_file2);                                                # Delete Work Files 2
    @unlink($tmp_file3);                                                # Delete Work Files 3
    @unlink($alert_file);                                               # Delete Work Alert File
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
