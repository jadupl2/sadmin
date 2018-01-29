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
#       V 1.2 WIP Initial Version
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
$DEBUG  = False  ;                                                      # Debug Activated True/False
$SVER   = "1.2" ;                                                       # Current version number




# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_cpu_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    unlink($WPNG);                                                      # Make sure png don't exist
    $GTITLE  = ucfirst(${WHOST_NAME}) . " - CPU - From $START to $END"; # Set GRaph Title
    $CMD     = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";      # rrdtool gph filename 
    $CMD    .= " --title \"$WTITLE\" ";                                 # Insert Title in Command
    $CMD    .= "--vertical-label \"percentage(%)\" ";                   # Set Vertical Legend
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD    .= "--upper-limit 100 --lower-limit 0 ";                    # Set Upper & Lower Limit
    $CMD    .= " DEF:total=$WRRD:cpu_total:MAX DEF:user=$WRRD:cpu_user:MAX ";
    $CMD    .= " DEF:sys=$WRRD:cpu_sys:MAX     DEF:wait=$WRRD:cpu_wait:MAX ";
    $CMD    .= " CDEF:csys=user,sys,+              CDEF:cwait=user,sys,wait,+,+  ";
    $CMD    .= " AREA:cwait#99CC96:\"% Wait\"      AREA:csys#CC3333:\"% Sys\" ";
    $CMD    .= " AREA:user#336699:\"% User\"       LINE2:total#000000:\"% total\" ";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}




# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_runqueue_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    unlink($WPNG);                                                      # Make sure png don't exist
    $GTITLE  = ucfirst(${WHOST_NAME}) . " - RunQueue - From $START to $END"; # Set GRaph Title
    $CMD     = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";      # rrdtool gph filename 
    $CMD    .= " --title \"$WTITLE\" ";                                 # Insert Title in Command
    $CMD    .= "--vertical-label \"Load\"";                             # Set Vertical Legend
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= " DEF:runque=$WRRD:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
    $CMD .= " DEF:runq=$WRRD:proc_runq:MAX LINE2:runq#000000:";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}



# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
# HOSTNAME  = Name of Host,                 WHOST_DESC  = Host Desciption from MySql Database 
# WTYPE     = cpu,runqueue,diskio,memory,paging_activity,paging_space_usage,network_eth[a,b,c]
# WOS       = linux,aix (lowercase allways) RRDTOOL     = Path to rrdtool       DEBUG = True,False
# ==================================================================================================
function create_standard_graphic($WHOST_NAME,$WHOST_DESC,$WTYPE,$WOS,$RRDTOOL,$DEBUG)
{
    $RRD_FILE   = SADM_WWW_RRD_DIR ."/${WHOST_NAME}/${WHOST_NAME}.rrd"; # Where Host RRD Is
    $PNGDIR     = SADM_WWW_TMP_DIR . "/perf" ;                          # Where png file generated
    $IMGDIR     = "/tmp/perf" ;                                         # png Dir. for Web Server
    $TODAY      = date("d.m.Y");                                        # Today Date DD.MM.YYY
    $YESTERDAY  = mktime(0, 0, 0, date("m"), date("d")-1,   date("Y")); # Return Yesterday EpochTime 
    $YESTERDAY  = date ("d.m.Y",$YESTERDAY);                            # Yesterday Date DD.MM.YYY
    $YESTERDAY2 = mktime(0, 0, 0, date("m"), date("d")-2,   date("Y")); # Today -2 Days in EpochTime 
    $YESTERDAY2 = date ("d.m.Y",$YESTERDAY2);                           # Today -2 Days in DD.MM.YY
    $LASTWEEK   = mktime(0, 0, 0, date("m"), date("d")-7,   date("Y")); # Today -7 Days in EpochTime
    $LASTWEEK   = date ("d.m.Y",$LASTWEEK);                             # Today -7 Days in DD.MM.YY
    $LASTMONTH  = mktime(0, 0, 0, date("m"), date("d")-31,  date("Y")); # Today -31 Days EpochTime
    $LASTMONTH  = date ("d.m.Y",$LASTMONTH);                            # Today -31 Days DD.MM.YY
    $LASTYEAR   = mktime(0, 0, 0, date("m"), date("d")-365, date("Y")); # Today -365 Days EpochTime
    $LASTYEAR   = date ("d.m.Y",$LASTYEAR);                             # Today -365 Days DD.MM.YY
    $LAST2YEAR  = mktime(0, 0, 0, date("m"), date("d")-730, date("Y")); # Today -730 Days EpochTime
    $LAST2YEAR  = date ("d.m.Y",$LAST2YEAR);                            # Today -730 Days DD.MM.YY
    $HRS_START  = "00:00" ;                                             # Graph Default Startup Time
    $HRS_END    = "23:59" ;                                             # Graph Default End Time

    # Print Variables above for debugging purpose.
    if ($DEBUG) { 
        echo "\n<br>RRDTOOL    = $RRDTOOL";
        echo "\n<br>RRD_FILE   = $RRD_FILE";
        echo "\n<br>PNGDIR     = $PNGDIR";
        echo "\n<br>IMGDIR     = $IMGDIR";
        echo "\n<br>TODAY      = $TODAY     ";
        echo "\n<br>YESTERDAY  = $YESTERDAY ";
        echo "\n<br>YESTERDAY2 = $YESTERDAY2";
        echo "\n<br>LASTWEEK   = $LASTWEEK  ";
        echo "\n<br>LASTMONTH  = $LASTMONTH ";
        echo "\n<br>LASTYEAR   = $LASTYEAR  ";
        echo "\n<br>LAST2YEAR  = $LAST2YEAR ";
        echo "\n<br>HRS_START  = $HRS_START ";
        echo "\n<br>HRS_END    = $HRS_END   ";
    }

    switch ($WTYPE) {
        case "cpu":                                                     # Generate CPU Graphic
            # Generate Big CPU Graphic for the last 2 Days -----------------------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_cpu_day.png";           # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - CPU - From $START to $END" ;  # Set Graph Title 
            create_cpu_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Small CPU Graphic for the last 7 Days ---------------------------------------
            $START  = "$HRS_START $LASTWEEK" ;                          # Start 7 days ago at 00:00
            $END    = "$HRS_END   $YESTERDAY";                          # End Yesterday at 23:00
            $GFILE  = "${PNGDIR}/${WHOST_NAME}_cpu_week.png";           # Name of png to generate
            $GTITLE = ucfirst(${WHOST_NAME})." - CPU - Last 7 Days" ;   # Set Graph Title 
            create_cpu_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 31 Days --------------------------------------
            $START  = "$HRS_START $LASTMONTH" ;                         # Start 31 days ago at 00:00
            $END    = "$HRS_END   $YESTERDAY";                          # End Yesterday at 23:00
            $GFILE  = "${PNGDIR}/${WHOST_NAME}_cpu_month.png";          # Name of png to generate
            $GTITLE = ucfirst(${WHOST_NAME})." - CPU - Last 4 weeks" ;  # Set Graph Title 
            create_cpu_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 365 Days -------------------------------------
            $START  = "$HRS_START $LASTYEAR" ;                          # Start 365 day ago at 00:00
            $END    = "$HRS_END   $YESTERDAY";                          # End Yesterday at 23:00
            $GFILE  = "${PNGDIR}/${WHOST_NAME}_cpu_year.png";           # Name of png to generate
            $GTITLE = ucfirst(${WHOST_NAME})." - CPU - Last 365 Days" ; # Set Graph Title 
            create_cpu_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);  
            break;

        case "runqueue":
            # Generate Big RunQueue Graphic for the last 2 Days -----------------------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_runqueue_day.png";           # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - RunQueue - From $START to $END" ;  # Set Graph Title 
            create_runqueue_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Small CPU Graphic for the last 7 Days ---------------------------------------
            $START  = "$HRS_START $LASTWEEK" ;                          # Start 7 days ago at 00:00
            $END    = "$HRS_END   $YESTERDAY";                          # End Yesterday at 23:00
            $GFILE  = "${PNGDIR}/${WHOST_NAME}_runqueue_week.png";           # Name of png to generate
            $GTITLE = ucfirst(${WHOST_NAME})." - RunQueue - Last 7 Days" ;   # Set Graph Title 
            create_runqueue_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 31 Days --------------------------------------
            $START  = "$HRS_START $LASTMONTH" ;                         # Start 31 days ago at 00:00
            $END    = "$HRS_END   $YESTERDAY";                          # End Yesterday at 23:00
            $GFILE  = "${PNGDIR}/${WHOST_NAME}_runqueue_month.png";          # Name of png to generate
            $GTITLE = ucfirst(${WHOST_NAME})." - RunQueue - Last 4 weeks" ;  # Set Graph Title 
            create_runqueue_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 365 Days -------------------------------------
            $START  = "$HRS_START $LASTYEAR" ;                          # Start 365 day ago at 00:00
            $END    = "$HRS_END   $YESTERDAY";                          # End Yesterday at 23:00
            $GFILE  = "${PNGDIR}/${WHOST_NAME}_runqueue_year.png";           # Name of png to generate
            $GTITLE = ucfirst(${WHOST_NAME})." - RunQueue - Last 365 Days" ; # Set Graph Title 
            create_runqueue_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);  
            break;

            


        case "memory":
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"in MB\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
   	            $CMD4       = "CDEF:memtotal=memused,memfree,+ ";
	            $CMD5       = "AREA:memused#294052:\"Memory Use\" ";
	            $CMD6       = "LINE2:memtotal#000000:\"Total Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3 " . " $CMD4". " $CMD5". " $CMD6" ;
			}else{
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
	            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . " $CMD4" ;
			}
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
            $CMD2       = "--vertical-label \"in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
   	            $CMD4       = "CDEF:memtotal=memused,memfree,+ ";
	            $CMD5       = "AREA:memused#294052:\"Memory Use\" ";
	            $CMD6       = "LINE2:memtotal#000000:\"Total Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3 " . " $CMD4". " $CMD5". " $CMD6" ;
			}else{
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
	            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
   	            $CMD4       = "CDEF:memtotal=memused,memfree,+ ";
	            $CMD5       = "AREA:memused#294052:\"Memory Use\" ";
	            $CMD6       = "LINE2:memtotal#000000:\"Total Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3 " . " $CMD4". " $CMD5". " $CMD6" ;
			}else{
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
	            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
   	            $CMD4       = "CDEF:memtotal=memused,memfree,+ ";
	            $CMD5       = "AREA:memused#294052:\"Memory Use\" ";
	            $CMD6       = "LINE2:memtotal#000000:\"Total Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3 " . " $CMD4". " $CMD5". " $CMD6" ;
			}else{
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
	            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;


        case "memory_usage":
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 " ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Memory Usage Pct\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
	            $CMD4       = "LINE2:memused#000000:\"Memory used by Processes\" LINE2:memfree#FF0000:\"Free Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}else{
	            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
	            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
				$CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
	            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
				$CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
	            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
				$CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
	            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250  --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
	            $CMD4       = "LINE2:memused#000000:\"Memory used by Processes\" LINE2:memfree#FF0000:\"Free Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}else{
	            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
	            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
				$CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
	            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
				$CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
	            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
				$CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
	            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
	            $CMD4       = "LINE2:memused#000000:\"Memory used by Processes\" LINE2:memfree#FF0000:\"Free Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}else{
	            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
	            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
				$CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
	            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
				$CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
	            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
				$CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
	            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
	            $CMD4       = "LINE2:memused#000000:\"Memory used by Processes\" LINE2:memfree#FF0000:\"Free Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}else{
	            $CMD3       = "DEF:mem_new_proc=$RRD_FILE:mem_new_proc:MAX ";      
	            $CMD4       = "DEF:mem_new_fscache=$RRD_FILE:mem_new_fscache:MAX ";
				$CMD5       = "DEF:mem_new_system=$RRD_FILE:mem_new_system:MAX ";
	            $CMD6       = "CDEF:totproc=mem_new_proc,mem_new_system,+  ";
				$CMD7       = "CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
	            $CMD8       = "AREA:wcache#DFC184:\"FS Cache %\" ";
				$CMD9       = "AREA:totproc#2A75A9:\"Process %\" ";
	            $CMDA       = "AREA:mem_new_system#7EB5D6:\"System %\" ";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" . "$CMD5" . "$CMD6" . "$CMD7" . "$CMD8" . "$CMD9". "$CMDA" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
			break ;


           
        case "diskio":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 250 --width 950";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX ";
	            $CMD4       = "LINE2:read#000000:\"DISKS Read MB/Sec\"  LINE2:write#0000FF:\"Disks Write MB/Sec\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}else{
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#DC143C:\"Disk Read per second\" ";
	            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 125 --width 250";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX ";
	            $CMD4       = "LINE2:read#000000:\"DISKS Read MB/Sec\"  LINE2:write#0000FF:\"Disks Write MB/Sec\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}else{
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#DC143C:\"Disk Read per second\" ";
	            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 125 --width 250";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX ";
	            $CMD4       = "LINE2:read#000000:\"DISKS Read MB/Sec\"  LINE2:write#0000FF:\"Disks Write MB/Sec\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}else{
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#DC143C:\"Disk Read per second\" ";
	            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 125 --width 250";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX ";
	            $CMD4       = "LINE2:read#000000:\"DISKS Read MB/Sec\"  LINE2:write#0000FF:\"Disks Write MB/Sec\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}else{
	            $CMD3       = "DEF:read=$RRD_FILE:disk_kbread_sec:MAX  AREA:read#DC143C:\"Disk Read per second\" ";
	            $CMD4       = "DEF:write=$RRD_FILE:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . $CMD4 ;
			}
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
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 250 --width 950";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:pgsec=$RRD_FILE:swap_in_out_sec:MAX LINE2:pgsec#000000:\"Swap pages IN + OUT per second\"";
	            //$CMD3       = "DEF:pgsec=$RRD_FILE:pg_in_out_sec:MAX LINE2:pgsec#000000:\"Swap pages IN + OUT per second\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
	            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 125 --width 250";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:pgsec=$RRD_FILE:swap_in_out_sec:MAX LINE2:pgsec#000000:\"Swap pages IN + OUT per second\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
	            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 125 --width 250";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:pgsec=$RRD_FILE:swap_in_out_sec:MAX LINE2:pgsec#000000:\"Swap pages IN + OUT per second\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
	            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 125 --width 250";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:pgsec=$RRD_FILE:swap_in_out_sec:MAX LINE2:pgsec#000000:\"Swap pages IN + OUT per second\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
	            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "paging_space_usage":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
			if ( $WOS == "linux" ) {
                $CMD2       = "--vertical-label \"in Pct\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:swapused=$RRD_FILE:swap_used_pct:MAX ";
                $CMD4       = "AREA:swapused#CC9A57:\"% Swap Space Used\" ";
                $CMD5       = "LINE2:swapused#000000: ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3". " $CMD4" . " $CMD5" ;
			}else{
                $CMD2       = "--vertical-label \"in MB\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
	            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>cmd = $CMD";
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
			if ( $WOS == "linux" ) {
                $CMD2       = "--vertical-label \"in Pct\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:swapused=$RRD_FILE:swap_used_pct:MAX ";
                $CMD4       = "AREA:swapused#CC9A57:\"% Swap Space Used\" ";
                $CMD5       = "LINE2:swapused#000000: ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3". " $CMD4" . " $CMD5" ;
			}else{
                $CMD2       = "--vertical-label \"in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
	            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
			if ( $WOS == "linux" ) {
                $CMD2       = "--vertical-label \"in PCT\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:swapused=$RRD_FILE:swap_used_pct:MAX ";
                $CMD4       = "AREA:swapused#CC9A57:\"% Swap Space Used\" ";
                $CMD5       = "LINE2:swapused#000000: ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3". " $CMD4" . " $CMD5" ;
			}else{
                $CMD2       = "--vertical-label \"in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
	            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
			if ( $WOS == "linux" ) {
                $CMD2       = "--vertical-label \"in Pct\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:swapused=$RRD_FILE:swap_used_pct:MAX ";
                $CMD4       = "AREA:swapused#CC9A57:\"% Swap Space Used\" ";
                $CMD5       = "LINE2:swapused#000000: ";
	            $CMD        = "$CMD1" . " $CMD2 " . " $CMD3". " $CMD4" . " $CMD5" ;
			}else{
                $CMD2       = "--vertical-label \"in MB\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
	            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
	            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;

        case "network_etha":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_kbytesin:MAX  DEF:kbout=$RRD_FILE:etha_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:etha_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_kbytesin:MAX  DEF:kbout=$RRD_FILE:etha_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:etha_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_kbytesin:MAX  DEF:kbout=$RRD_FILE:etha_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:etha_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_kbytesin:MAX  DEF:kbout=$RRD_FILE:etha_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:etha_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:etha_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;

        case "network_ethb":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethb_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethb_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethb_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethb_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethb_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethb_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethb_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethb_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethb_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            break;


        case "network_ethc":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethc_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethc_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethc_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethc_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethc_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethc_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_kbytesin:MAX  DEF:kbout=$RRD_FILE:ethc_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:ethc_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:ethc_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            break;
}
        return ;
    }


# ==================================================================================================
#                          Display Performance Graphic Page just Generated 
# ==================================================================================================
function display_graph ($WHOST_NAME,$WHOST_DESC,$WTYPE)
{
    $FONTCOLOR = "Green"; 
    $IMGDIR = "/tmp/perf" ;

    $IMG_DAY   = "${IMGDIR}/${WHOST_NAME}_${WTYPE}_day.png";
    $IMG_WEEK  = "${IMGDIR}/${WHOST_NAME}_${WTYPE}_week.png";
    $IMG_MTH   = "${IMGDIR}/${WHOST_NAME}_${WTYPE}_month.png";
    $IMG_YEAR  = "${IMGDIR}/${WHOST_NAME}_${WTYPE}_year.png";
    $URL_WEEK  = "/view/perf/sadm_server_perf_week.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE";
    $URL_MTH   = "/view/perf/sadm_server_perf_month.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE";
    $URL_YEAR  = "/view/perf/sadm_server_perf_2year.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE";
    $ALT_WEEK  = "Larger view of last week";
    $ALT_MTH   = "Detailed view of last month";
    $ALT_YEAR  = "View last 2 years";

    # Table definition for the 4 graph (Yesterday, Last 7 Days, Last 4 weeks, Last 365 Days)
    echo "\n\n<table style='width:80%' align=center border=0 cellspacing=0>\n";

    # Display Title of the Graph
    echo "<tr>" ;
    #echo "<td style='width:80%' align=center colspan=3 bgcolor='153450'><font color=$FONTCOLOR>";
    echo "<td style='width:80%' align=center colspan=3><strong><font color=$FONTCOLOR>";
    echo  ucfirst($WTYPE) . " Usage</font></strong></td>";
    echo "</tr>";
    
    echo "\n<tr><td colspan=3 ><img src=${IMG_DAY}></td></tr>" ; 
    echo "\n<tr align=center>";
    echo "\n<td><A HREF='${URL_WEEK}'><img src=${IMG_WEEK} alt=\"${ALT_WEEK}\"></a></td>";
    echo "\n<td><A HREF='${URL_MTH}'> <img src=${IMG_MTH}  alt=\"${ALT_MTH} \"></a></td>";
    echo "\n<td><A HREF='${URL_YEAR}'><img src=${IMG_YEAR} alt=\"${ALT_YEAR}\"></a></td>";
    echo "\n</tr>" ;

    echo "\n</table><br><br>";
    return ;
}
	
 

# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    if (isset($_GET['host']) ) { 
        $HOSTNAME = $_GET['host'];
        $sql = "SELECT * FROM `server` WHERE `srv_name` = '$HOSTNAME' ";
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.   
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Server (" . $HOSTNAME . ") not found.\n";      # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
            exit;                                                       # Exit - Should not occurs
        }else{                                                          # If row was found
            $row = mysqli_fetch_assoc($result);                         # Read the Associated row
        }
        $HOSTDESC = $row['srv_desc'];                                   # Get Host Description
        $HOST_OS  = $row['srv_ostype'];                                 # Get O/S Type linux/aix

        echo "<center><strong><H2>";
        echo "Performance Graph for Server $HOSTNAME";
        echo "</strong></H2></center><br>";
    
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"cpu",$HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "cpu");
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "runqueue", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "runqueue");
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "diskio", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "diskio");
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "memory", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "memory");
        if ($HOST_OS == "aix") {
            create_standard_graphic ($HOSTNAME, $HOSTDESC, "memory_usage", $HOST_OS,SADM_RRDTOOL,$DEBUG);
            display_graph ($HOSTNAME, $HOSTDESC, "memory_usage");
        }
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "paging_activity", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "paging_activity");
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "paging_space_usage", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "paging_space_usage");

        create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_etha", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "network_etha");
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_ethb", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "network_ethb");
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_ethc", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        display_graph ($HOSTNAME, $HOSTDESC, "network_ethc");
        if ($HOST_OS == "aix") {
            create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_eth2", $HOST_OS,SADM_RRDTOOL,$DEBUG);
            display_graph ($HOSTNAME, $HOSTDESC, "network_eth2");
        }
    }else{                                                              # If No Key Rcv or Blank
        $err_msg = "No Server Name Received - Please Advise" ;          # Construct Error Msg.
        sadm_alert ($err_msg) ;                                         # Display Error Msg. Box
        ?>
        <script>location.replace("/view/perf/sadm_server_perf_menu.php");</script>
        <?php                                                           # Back 2 List Page
        #echo "<script>location.replace('" . URL_MAIN . "');</script>";
        exit ; 
    }

    # Link pour fichier nmon
    if ($HOST_OS == "aix") {
        echo "<center><A HREF='/data/nmon/archive/aix/$HOSTNAME'>Fichier NMON de ce serveur</a></center>\n";
    }else{
       echo "<center><A HREF='/data/nmon/archive/linux/$HOSTNAME'>Fichier NMON de ce serveur</a></center>\n";
    }

    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>

