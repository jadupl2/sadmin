<?php
# ================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_perf.php
#   Version  :  1.0
#   Date     :  25 January 2018
#   Requires :  php
#   Synopsis :  Present Performance Graphics for Server received 
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
#   2018_01_25 JDuplessis
#       V 1.0 Initial Version
#       V 1.1 WIP Initial Version
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # </head>Heading & SideBar


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG  = True ;                                                       # Debug Activated True/False
$SVER   = "1.1" ;                                                       # Current version number
$IMGDIR = "/tmp/perf" ;


// ================================================================================================
//                       Create 2 Years Graph for the server received in parameter
// ================================================================================================
function create_standard_graphic( $WHOST_NAME, $WHOST_DESC , $WTYPE, $WPERIOD)
{
    $RRD_DIR   = "/sysinfo/www/rrd/perf" ;
    $RRDTOOL    = "/usr/bin/rrdtool";
    $WEBDIR     = "/sysinfo/www";
    $PNGDIR     = "$WEBDIR/images/perf" ;  
    $IMGDIR     = "/images/perf" ;  
    $TODAY      = date("d.m.Y");
    $YESTERDAY  = mktime(0, 0, 0, date("m") , date("d")-1,   date("Y"));
    $YESTERDAY  = date ("d.m.Y",$YESTERDAY);
    $YESTERDAY2 = mktime(0, 0, 0, date("m") , date("d")-2,   date("Y"));
    $YESTERDAY2 = date ("d.m.Y",$YESTERDAY2);
    $LASTWEEK   = mktime(0, 0, 0, date("m") , date("d")-7,   date("Y"));
    $LASTWEEK   = date ("d.m.Y",$LASTWEEK);
    $LASTMONTH  = mktime(0, 0, 0, date("m") , date("d")-31,  date("Y"));
    $LASTMONTH  = date ("d.m.Y",$LASTMONTH);
    $LASTYEAR   = mktime(0, 0, 0, date("m") , date("d")-365, date("Y"));
    $LASTYEAR   = date ("d.m.Y",$LASTYEAR);
    $LAST2YEAR  = mktime(0, 0, 0, date("m") , date("d")-730, date("Y"));
    $LAST2YEAR  = date ("d.m.Y",$LAST2YEAR);
    $HRS_START  = "00:00" ;
    $HRS_END    = "23:59" ;  
    $RRD_FILE   = "$RRD_DIR/${WHOST_NAME}/$WHOST_NAME.rrd";
	
    switch ($WPERIOD) {
	case "day"  :
            $START      = "$HRS_START $YESTERDAY" ;
            $END        = "$HRS_END   $YESTERDAY";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " - " . $YESTERDAY ;
            break;
	case "week" :
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last $WPERIOD" ;
            break;
	case "month"  :
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last $WPERIOD" ;
            break;
	case "year" :
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last $WPERIOD" ;
            break;
	
    }

    switch ($WTYPE) {
        case "cpu":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:user=$RRD_FILE:cpu_busy:MAX LINE2:user#0000FF:\"% CPU time busy\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3";
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "memory":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
            $CMD4       = "LINE2:memused#000000:\"Memory used by Processes\" LINE2:memfree#FF0000:\"Free Memory\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "runqueue":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
            $CMD3       = "DEF:runque=$RRD_FILE:proc_rque:MAX LINE2:runque#0000FF:\"Number of tasks waiting for CPU resources\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "diskio":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 125 --width 250";
            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX ";
            $CMD4       = "LINE2:read#000000:\"DISKS Read MB/Sec\"  LINE2:write#0000FF:\"Disks Write MB/Sec\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "paging_activity":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 125 --width 250";
            $CMD3       = "DEF:pgsec=$RRD_FILE:swap_in_out_sec:MAX LINE2:pgsec#000000:\"Swap pages IN + OUT per second\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "paging_space_usage":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:swapused=$RRD_FILE:swap_used_pct:MAX LINE2:swapused#000000:\"% Swap Space Used\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "network_eth0":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth0_kbytesout:MAX ";
            $CMD4       = "LINE2:kbin#000000:\"KB Received\" LINE2:kbout#0000FF:\"KB Transmitted\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "network_eth1":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth1_kbytesout:MAX ";
            $CMD4       = "LINE2:kbin#000000:\"KB Received\" LINE2:kbout#0000FF:\"KB Transmitted\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;
    }
}


// ================================================================================================
//                    Display server graphic type selected for the period selected 
// ================================================================================================
function display_graph ( $WHOST_NAME, $WHOST_DESC, $WTYPE, $WPERIOD, $WCOUNT)
{
    $IMGDIR     = "/images/perf" ;
    $GFILENAME = $_SERVER['DOCUMENT_ROOT'] . "${IMGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}.png";
//    if (file_exists($GFILENAME)) {
       echo "   <td><a href=/unix/server_performance.php?host=$WHOST_NAME><img src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png alt=\"Click here to view performance graph for $WHOST_NAME\"></a></td>\n";
//    } else {
//       echo "   <td align=center height=125 width=250>No Graph for ${WHOST_NAME}</td>\n";
//    }
    if ( ($WCOUNT % 3) == 0 ) {
	echo "</tr><tr>\n" ;
    }
    return ;
}
	

 
if (isset($_GET['wtype']) ) { 
    $WTYPE = $_GET['wtype'];
    switch ($WTYPE) {
	case "cpu"  :
            break;
	case "memory" :
            break;
	case "cpu_wait"  :
            break;
	case "runqueue" :
            break;
	case "diskio"  :
            break;
	case "paging_activity" :
            break;
	case "paging_space_usage"  :
            break;
	case "network_eth0" :
            break;
	case "network_eth1" :
            break;
	default:
	    echo "The WTYPE received is invalid ($WTYPE)" ;
	    exit ;
    }

    $WPERIOD = $_GET['wperiod'];
    switch ($WPERIOD) {
	case "day"  :
            break;
	case "week" :
            break;
	case "month"  :
            break;
	case "year" :
            break;
	case "2years" :
            break;
	default:
	    echo "The WPERIOD received is invalid ($WPERIOD)" ;
	    exit ;
    }
	
	
    $WOS = $_GET['wos'];
    switch ($WOS) {
	case "all_linux"  :
            $result = mysql_query("SELECT * FROM `servers` where server_os='LINUX' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
            break;
	case "all_aix" :
            $result = mysql_query("SELECT * FROM `servers` where server_os='Aix' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
            break;
	case "all_servers"  :
            $result = mysql_query("SELECT * FROM `servers` where (server_os='Linux' or server_os='Aix') and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
            break;
	default:
	    echo "The WOS received is invalid ($WOS)" ;
	    exit ;
    }
    $COUNT=0;
    echo "<center><strong><H1>Performance Graph for $WOS servers ($WTYPE/$WPERIOD)</strong></H1></center><br>";

    echo "<table width=750 align=center border=2 cellspacing=1>\n";
    echo "  <tr>\n" ;
    while ($row = mysql_fetch_array($result)){
          $COUNT+=1;
          $HOSTNAME = $row['server_name'] ;
		  $HOSTDESC = $row['server_desc'] ;
          create_standard_graphic ($HOSTNAME, $HOSTDESC, $WTYPE, $WPERIOD);
          display_graph ($HOSTNAME, $HOSTDESC, $WTYPE , $WPERIOD, $COUNT);
    }
    echo "  </tr>\n" ; 
    echo "</table><br><br>";
} 
    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
