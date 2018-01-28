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
//                       Transform date (DD/MM/YYY) into MYSQL format
// ================================================================================================
function create_standard_graphic( $WHOST_NAME, $WHOST_DESC , $WTYPE)
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


    switch ($WTYPE) {
        case "cpu":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX LINE2:total#000000:\"% CPU total\" ";
            $CMD4       = "DEF:user=$RRD_FILE:cpu_user:MAX AREA:user#336699:\"% CPU User\" ";
            $CMD5       = "DEF:sys=$RRD_FILE:cpu_sys:MAX AREA:sys#CC3333:\"% CPU Sys\" ";
            $CMD6       = "DEF:wait=$RRD_FILE:cpu_wait:MAX AREA:wait#99CC96:\"% CPU wait\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4" . " $CMD5 " .  " $CMD6";
            $outline    = exec ("$CMD", $array_out, $retval);
 
            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX LINE2:total#000000:\"% CPU total\" ";
            $CMD4       = "DEF:user=$RRD_FILE:cpu_user:MAX AREA:user#336699:\"% CPU User\" ";
            $CMD5       = "DEF:sys=$RRD_FILE:cpu_sys:MAX AREA:sys#CC3333:\"% CPU Sys\" ";
            $CMD6       = "DEF:wait=$RRD_FILE:cpu_wait:MAX AREA:wait#99CC96:\"% CPU wait\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4" . " $CMD5 " .  " $CMD6";
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX LINE2:total#000000:\"% CPU total\" ";
            $CMD4       = "DEF:user=$RRD_FILE:cpu_user:MAX AREA:user#336699:\"% CPU User\" ";
            $CMD5       = "DEF:sys=$RRD_FILE:cpu_sys:MAX AREA:sys#CC3333:\"% CPU Sys\" ";
            $CMD6       = "DEF:wait=$RRD_FILE:cpu_wait:MAX AREA:wait#99CC96:\"% CPU wait\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4" . " $CMD5 " .  " $CMD6";
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX LINE2:total#000000:\"% CPU total\" ";
            $CMD4       = "DEF:user=$RRD_FILE:cpu_user:MAX AREA:user#336699:\"% CPU User\" ";
            $CMD5       = "DEF:sys=$RRD_FILE:cpu_sys:MAX AREA:sys#CC3333:\"% CPU Sys\" ";
            $CMD6       = "DEF:wait=$RRD_FILE:cpu_wait:MAX AREA:wait#99CC96:\"% CPU wait\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4" . " $CMD5 " .  " $CMD6";
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;


        case "memory":
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory in MB\" --height 250 --width 950 " ;
            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            // echo "<br>CMD = $CMD";
            // echo "<br>outline = $outline";
            // echo "<br>array_out = $array_out";
            // echo "<br>retval = $retval" ;

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory in MB\" --height 125 --width 250 ";
            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory in MB\" --height 125 --width 250 ";
            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory in MB\" --height 125 --width 250 ";
            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;

        case "memory_usage":
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png ";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days " ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\" ";
            $CMD2       = "--vertical-label \"Memory Usage Pct\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 " ;
            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
            $CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
            $CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
            $CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            // echo "<br>CMD = $CMD";
            // echo "<br>outline = $outline";
            // echo "<br>array_out = $array_out";
            // echo "<br>retval = $retval" ;

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory Usage Pct\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
            $CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
            $CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
            $CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory Usage Pct\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
            $CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
            $CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
            $CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory Usage Pct\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
            $CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
            $CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
            $CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;

        case "runqueue":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 250 --width 950";
            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
            $CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
            $CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
            $CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
            $CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            //echo "<br>outline = $outline";
            //echo "<br>array_out = $array_out";
            //echo "<br>retval = $retval" ;
        break;

           
        case "diskio":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png ";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days " ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\" ";
            $CMD2       = "--vertical-label \"MB/Second\" --height 250 --width 950 ";
            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#DC143C:\"Disk Read per second\" ";
            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
            // $CMD4       = "LINE2:read#000000:\"DISKS Read MB/Sec\"  LINE2:write#0000FF:\"Disks Write MB/Sec\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            // echo "<br>outline = $outline";
            // echo "<br>array_out = $array_out";
            // echo "<br>retval = $retval" ;

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 125 --width 250";
            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#CC9A57:\"Disk Read per second\" ";
            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4"  ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 125 --width 250";
            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#CC9A57:\"Disk Read per second\" ";
            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 125 --width 250";
            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#CC9A57:\"Disk Read per second\" ";
            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . "$CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;


        case "paging_activity":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 250 --width 950";
            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            
            
            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 125 --width 250";
            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD4" .  " $CMD3" ;
           $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 125 --width 250";
            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD4" .  " $CMD3" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 125 --width 250";
            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD4" .  " $CMD3" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "paging_space_usage":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png ";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days " ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\" ";
            $CMD2       = "--vertical-label \"Paging Space in MB\" --height 250 --width 950 " ;
            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Paging Space in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Paging Space in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Paging Space in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;

        case "network_eth0":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950  ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;

        case "network_eth1":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;


        case "network_eth2":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950  ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 ";
            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
            $outline    = exec ("$CMD", $array_out, $retval);
            break;
    }
}


// ================================================================================================
//                       Display Graphic Page 
// ================================================================================================
function display_graph ( $WHOST_NAME, $WHOST_DESC , $WTYPE)
{
    $IMGDIR     = "/images/perf" ;
    $FONTCOLOR = "White"; 
    echo "<table width=750 align=center border=1 cellspacing=0>\n";
    echo "  <tr>\n" ;
//    echo "   <td width=750 align=center colspan=3 bgcolor='aqua'><font color=$FONTCOLOR><bold>" . strtoupper($WTYPE) . " usage $WHOST_NAME - $WHOST_DESC</td>\n";
    echo "   <td width=750 align=center colspan=3 bgcolor='153450'><font color=$FONTCOLOR>" . strtoupper($WTYPE) . " usage $WHOST_NAME - $WHOST_DESC</font></bold></td>\n";
    echo "  </tr>\n";
    
    echo "  <tr align=left>\n";
    echo "   <td colspan=3 align=center><img src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_day.png></td>\n";
    echo "  </tr>\n" ; 
    echo "  <tr align=center>\n";
    echo "   <td><A HREF='/unix/server_perf_week_aix.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE'><img  src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_week.png alt=\"Click to see larger view of last week   \"></a></td>\n";
    echo "   <td><A HREF='/unix/server_perf_month_aix.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE'><img src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_month.png alt=\"Click to see a detailed view of last month  \"></a></td>\n";
    echo "   <td><A HREF='/unix/server_perf_2year_aix.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE'><img src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_year.png  alt=\"Click to view last 2 years\"></a></td>\n";
    echo "  </tr><br>\n" ; 
    echo "</table><br><br>";
    return ;
}
	
 
if (isset($_GET['host']) ) { 
    $HOSTNAME = $_GET['host'];
    $row = mysql_fetch_array ( mysql_query("SELECT * FROM `servers` WHERE `server_name` = '$HOSTNAME' "));
    $HOSTDESC   = $row['server_desc'];
    echo "<center><strong><H1>Performance Graph - server $HOSTNAME - $HOSTDESC</strong></H1></center><br>";
    
    create_standard_graphic ($HOSTNAME, $HOSTDESC, "cpu");
    display_graph ($HOSTNAME, $HOSTDESC, "cpu");

    // create_standard_graphic ($HOSTNAME, $HOSTDESC, "cpu_wait");
    // display_graph ($HOSTNAME, $HOSTDESC, "cpu_wait");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "runqueue");
    display_graph ($HOSTNAME, $HOSTDESC, "runqueue");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "diskio");
    display_graph ($HOSTNAME, $HOSTDESC, "diskio");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "memory");
    display_graph ($HOSTNAME, $HOSTDESC, "memory");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "memory_usage");
    display_graph ($HOSTNAME, $HOSTDESC, "memory_usage");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "paging_activity");
    display_graph ($HOSTNAME, $HOSTDESC, "paging_activity");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "paging_space_usage");
    display_graph ($HOSTNAME, $HOSTDESC, "paging_space_usage");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_eth0");
    display_graph ($HOSTNAME, $HOSTDESC, "network_eth0");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_eth1");
    display_graph ($HOSTNAME, $HOSTDESC, "network_eth1");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_eth2");
    display_graph ($HOSTNAME, $HOSTDESC, "network_eth2");
}
    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
