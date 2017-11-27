<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_sysmon.php
#   Version     :  1.5
#   Date        :  4 February 2017
#   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
#   Description :  This page allow to view the servers alerts information in various ways
#                  depending on parameters received.
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
$URL_HOST_INFO = '/view/srv/sadm_view_server_info.php';                 # Display Host Info URL
$URL_CREATE = '/crud/srv/sadm_server_create.php';                       # Create Page URL
$URL_UPDATE = '/crud/srv/sadm_server_update.php';                       # Update Page URL
$URL_DELETE = '/crud/srv/sadm_server_delete.php';                       # Delete Page URL
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$CREATE_BUTTON = False ;                                                # Yes Display Create Button
$tmp_file1          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp1_');
$tmp_file2          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp2_');
$tmp_file3          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp3_');
$array_sysmon = [];                                                     # Create Empty Array
$alert_file = SADM_TMP_DIR . "/www_sysmon_file_" . getmypid() ;         # File Being Built/Displayed


#===================================================================================================
# This function create one file $alert_file that : 
#   - Create an alert file with the content of all *.rpt in $SADMIN/www/dat 
#   - Add to it the last line of all to the *.rch in $SADMIN/dat that finish 
#       with a 1(Fail) or 2(running)
#   - Then Load this alert File into an array (sysmon_array).
#===================================================================================================
function load_sysmon_array() {
    global $DEBUG, $tmp_file1, $tmp_file2, $tmp_file3, $alert_file ;

    # GET CONTENT OF EVERY RPT FILE INTO OUR WORKING ALERT FILE
    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rpt' -exec cat {} \; > $alert_file";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "\n<br>Return code of command is : " . $RCODE ; }

    # GET THE LAST LINE OF EVERY RCH FILE INTO THE TMP2 WORK FILE
    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rch' -exec tail -1 {} \; > $tmp_file2";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "\n<br>Return code of command is : " . $RCODE ; }

    # RETAIN LINES THAT TERMINATE BY A 1(ERROR) OR A 2(RUNNING) FROM TMP2 WORK FILE INTO TMP3 FILE
    $CMD="awk 'match($8,/[1-2]/) { print }' $tmp_file2 > $tmp_file3" ;
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "\n<br>Return code of command is : " . $RCODE ; }


    # CONVERT THESE RCH KIND OF LINES
    # debian7 2017.02.09 00:06:02 2017.02.09 00:06:02 00:00:00 sadm_rear_backup 1
    #   1        2         3         4        5        6          7            8
    # TO THIS TYPE OF LINE (RPT)
    # Error;nano;2017.02.08;17:00;SERVICE;PROCESS;Service syslogd not running !;sadm;sadm;
    #   1    2       3        4      5       6             7                     8     9
    $lines = file($tmp_file3);                                          # Load RCH Line into Array
    $afile = fopen("$alert_file","a") or die("can't open in append mode file " . $alert_file );

    foreach ($lines as $line_num => $line) {
        if ($DEBUG) { echo "\n<br>RCH Before conversion - Ligne #{$line_num} : " . $line ; }
        list($whost,$wdate1,$wtime1,$wdate2,$wtime2,$welapse,$wscript,$wcode) = explode(" ",$line);
        $rdate = trim($wdate2);
        $rtime = substr(trim($wtime2),0,-3);
        switch (trim($wcode)) {
            case 0:     $rtype = "Success" ;
                        break;
            case 1:     $rtype = "Error" ;
                        break;
            case 2:     $rtype = "Running" ;
                        $rdate = trim($wdate1);
                        $rtime = substr(trim($wtime1),0,-3);
                        break;
            default:    $rtype = "Unknown" ;
                        break;
        }
        $rhost      = trim($whost);
        $rmod       = "SADM";
        $rsubmod    = "SCRIPT";
        $rpage      = "sadm";
        $rmail      = "sadm";
        $rdesc      = "Script " . $wscript;
        $LINE="${rtype};${rhost};${rdate};${rtime};${rmod};${rsubmod};${rdesc};${rpage};${rmail}\n";
        if ($DEBUG) { echo "\n<br>RCH After conversion - Ligne #{$line_num} : " . $LINE ; }
        fwrite($afile,$LINE);
    }
    fclose($afile);

    if ($DEBUG) {
        echo "\n\n<br><br>Debug Information - Alert file Content";
        $lines = file($alert_file);
        foreach ($lines as $line_num => $line) {
            echo "\n<br>Ligne #<b>{$line_num}</b> : " . $line . "\n";
        }
    }

    # Delete Work Files
    unlink($tmp_file1);
    unlink($tmp_file2);
    unlink($tmp_file3);
}


#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function setup_table() {
    global $DEBUG ;

    # TABLE CREATION
    echo "\n\n<div id='SimpleTable'>";                                      # Width Given to Table
    echo "\n<table id='sadmTable' class='display' cell-border compact row-border wrap width='98%'>";
    #echo '<table id="sadmTable" class="display compact nowrap" width="100%">';

    # TABLE HEADING
    echo "\n<thead>\n";
    echo "<tr>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th>Server</th>\n";
    echo "<th>Server Description</th>\n";
    echo "<th class='text-center'>Module</th>\n";
    echo "<th>Alert Description</th>\n";
    echo "<th class='text-center'>Date / Time</th>\n";
    #echo "<th class='text-center'>Time</th>\n";
    echo "<th class='text-center'>Cat.</th>\n";
    echo "<th class='text-center'>SubModule</th>\n";
    #echo "<th class='text-center'>Alert Grp</th>\n";
    #echo "<th class='text-center'>Email Grp</th>\n";
    #echo "<th class='text-center'>Alert Grp</th>\n";
    echo "<th class='text-center'>Alert/Email Grp</th>\n";
    echo "</tr>\n";
    echo "</thead>\n";

    # TABLE FOOTER
    echo "<tfoot>\n";
    echo "<tr>\n";
    #echo "<th class='text-center'>No</th>\n";
    echo "<th class='text-center'>Status</th>\n";
    echo "<th>Server</th>\n";
    #echo "<th>O/S</th>\n";
    echo "<th>Server Description</th>\n";
    echo "<th class='text-center'>Module</th>\n";
    echo "<th>Alert Description</th>\n";
    echo "<th class='text-center'>Date / Time</th>\n";
    #echo "<th class='text-center'>Time</th>\n";
    echo "<th class='text-center'>Cat.</th>\n";
    echo "<th class='text-center'>SubModule</th>\n";
    #echo "<th class='text-center'>Alert Grp</th>\n";
    #echo "<th class='text-center'>Email Grp</th>\n";
    #echo "<th class='text-center'>Alert Grp</th>\n";
    echo "<th class='text-center'>Alert/Email Grp</th>\n";
    echo "</tr>\n";
    echo "</tfoot>\n";

    # Start of Table Body
    echo "<tbody>\n";
}


#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($con,$alert_file) {
    global $DEBUG, $URL_HOST_INFO ;

    $array_sysmon = file($alert_file);                                  # Put Alert file in Array
    rsort($array_sysmon);                                               # Sort Array in Reverse Ord.

    # DISPLAY EACH LINE IN ARRAY_SYSMON
    foreach ($array_sysmon as $line_num => $line) {
        if ($DEBUG) { 
            echo "Processing Line #<b>{$line_num}</b> : " . htmlspecialchars($line) . "<br />\n"; 
        }
        list($wstatus,$whost,$wdate,$wtime,$wmod,$wsubmod,$wdesc,$wpage,$wmail)=explode(";",$line);

        # DISPLAY ICON STATUS
        echo "<tr>\n";
        #echo "<td class='dt-center'>" . nl2br($line_num+1)  . "</td>\n";
        echo "<td class='dt-center'>";
        switch (strtoupper($wstatus)) {
            case 'SUCCESS' :
                echo "<span data-toggle='tooltip' title='Success '>";
                echo "<img src='/images/success.png' ";
                break;
            case 'ERROR' :
                echo "<span data-toggle='tooltip' title='Error Reported'>";
                echo "<img src='/images/error.png' ";
                break;
            case 'WARNING' :
                echo "<span data-toggle='tooltip' title='Warning Reported'>";
                echo "<img src='/images/warning.png' ";
                break;
            case 'RUNNING' :
                echo "<span data-toggle='tooltip' title='Running Process'>";
                echo "<img src='/images/running.png' ";
                break;
            default:
                echo "<span data-toggle='tooltip' title='Unknown Status'>";
                echo "<img src='/images/question_mark.png' ";
                break;
        }
        echo "style='width:24px;height:24px;'></span></td>\n";

        # READ SERVER TABLE TO GET THE DESCRIPTION, O/S Name and O/S Version
        $sql = "SELECT * FROM server where srv_name = '". $whost . "';";
        if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
            $WDESC = "Server not in Database";
            $WOS   = "Unknown";
            $WVER  = "Unknown";
        }else{
            $row = mysqli_fetch_assoc($result);
            if (! $row) {
                $WDESC = "Server not in Database";
                $WOS   = "Unknown";
                $WVER  = "Unknown";
            }else{
                $WDESC = $row['srv_desc'];
                $WOS   = $row['srv_osname'];
                $WVER  = $row['srv_osversion'];
                mysqli_free_result($result);                                        # Free result set 
            }
        }

        # Server Name
        echo "<td>";
        echo "<a href='" . $URL_HOST_INFO . "?host=" . nl2br($whost) ;
        echo "' title='$WOS $WVER server - ip address is " . $row['srv_ip'] . "'>" ;
        echo nl2br($whost) . "</a></td>\n";


        # Display Operating System Logo
        #switch (strtoupper($WOS)) {
        #    case 'REDHAT' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='http://www.redhat.com' ";
        #        echo "title='Server $whost is a RedHat server - Visit redhat.com'>";
        #        echo "<img src='/images/redhat.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'FEDORA' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://getfedora.org' ";
        #        echo "title='Server $whost is a Fedora server - Visit getfedora.org'>";
        #        echo "<img src='/images/fedora.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'CENTOS' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.centos.org' ";
        #        echo "title='Server $whost is a CentOS server - Visit centos.org'>";
        #        echo "<img src='/images/centos.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'UBUNTU' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.ubuntu.com/' ";
        #        echo "title='Server $whost is a Ubuntu server - Visit ubuntu.com'>";
        #        echo "<img src='/images/ubuntu.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'LINUXMINT' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://linuxmint.com/' ";
        #        echo "title='Server $whost is a LinuxMint server - Visit linuxmint.com'>";
        #        echo "<img src='/images/linuxmint.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'DEBIAN' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.debian.org/' ";
        #        echo "title='Server $whost is a Debian server - Visit debian.org'>";
        #        echo "<img src='/images/debian.png' ";
        #        #echo "style='width:24px;height:24px;'></a<</td>\n";
        #        echo "style='width:24px;height:24px;'></a<</td>\n";
        #        break;
        #    case 'RASPBIAN' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.raspbian.org/' ";
        #        echo "title='Server $whost is a Raspbian server - Visit raspian.org'>";
        #        echo "<img src='/images/raspbian.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'SUSE' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.opensuse.org/' ";
        #        echo "title='Server $whost is a OpenSUSE server - Visit opensuse.org'>";
        #        echo "<img src='/images/suse.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'AIX' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='http://www-03.ibm.com/systems/power/software/aix/' ";
        #        echo "title='Server $whost is an AIX server - Visit Aix Home Page'>";
        #        echo "<img src='/images/aix.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    default:
        #        echo "<td class='dt-center'>";
        #        echo "<img src='/images/os_unknown.jpg' ";
        #        echo "style='width:24px;height:24px;'></td>\n";
        #        break;
        #}
        echo "<td>" . $WDESC                                 . "</td>\n";
        echo "<td class='dt-left'>" . strtoupper($wmod)    . "</td>\n";

        list($wdummy,$wscript) = explode(" ",$wdesc);
        $wlog =  $whost . "_" . $wscript . ".log";
        echo "<td>";
        if ($wdummy == "Script") {
            echo "<a href='/sadmin/sadm_view_logfile.php?host=" . $whost ;
            echo "&filename=" . $wlog . "' title='View the script log - " . $wlog . "'>" . $wdesc ;
            echo "</a>";
        }else{
            echo $wdesc ;

        }
        echo "</td>\n";
        echo "<td class='dt-center'>" . $wdate . " " . $wtime                . "</td>\n";
        #echo "<td class='dt-center'>" . $wtime               . "</td>\n";

        $WCAT  = sadm_clean_data($row['srv_cat']);

        $WOS   = sadm_clean_data($row['srv_osname']);
        echo "<td class='dt-center'>" . $WCAT                . "</td>\n";
        echo "<td class='dt-center'>" . strtoupper($wsubmod) . "</td>\n";
        echo "<td class='dt-center'>" . $wpage . " / " . $wmail               . "</td>\n";
        #echo "<td class='dt-center'>" . $wmail               . "</td>\n";
    }
    echo "</tbody></table></center><br><br>\n";                         # End of tbody,table
    echo "<center>";
    echo "<b>This page will refresh automatically every minute - " . date('l jS \of F Y h:i:s A');
    echo "</br></center>";
}


#===================================================================================================
#                                      PROGRAM START HERE
#===================================================================================================
#
    echo "<div id='sadmRightColumn'>";                                  # Beginning Content Page
    display_std_heading("NotHome","System Monitor",$SVER);
    echo "\n<tbody>\n";                                                 # Start of Table Body
    load_sysmon_array();                                                # Load RPT and RCH File
    setup_table();                                                      # Create Table & Heading
    display_data($con,$alert_file);                                     # Display SysMOn Array
    @unlink($tmp_file1);                                                # Delete Work Files 1
    @unlink($tmp_file2);                                                # Delete Work Files 2
    @unlink($tmp_file3);                                                # Delete Work Files 3
    @unlink($alert_file);                                               # Delete Work Alert File
    echo "\n</tbody>\n</table>\n";                                      # End of tbody,table
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div

    # COMMON FOOTING
    mysqli_close($con);                                                 # Close Database Connection
    echo "</div> <!-- End of sadmRightColumn   -->" ;                   # End of Left Content Page       
    echo "</div> <!-- End of sadmPageContents  -->" ;                   # End of Content Page
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageFooter.php')  ;    # SADM Std EndOfPage Footer
    echo "</div> <!-- End of sadmWrapper       -->" ;                   # End of Real Full Page
?>
