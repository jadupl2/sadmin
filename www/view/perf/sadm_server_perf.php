<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/connection.php'); ?>
<?php include($_SERVER['DOCUMENT_ROOT'].'/includes/header.php')  ; ?>
<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/functions.php'); ?>
<?php include($_SERVER['DOCUMENT_ROOT'].'/unix/server_menu.php')  ; ?>
<script type="text/javascript">
<!-- hide
function OLpreviewImage(src) {
    return '<img src="' + src + '"/>';
}
// end hiding -->
</script>

<?php
// ================================================================================================
//                       Transform date (DD/MM/YYY) into MYSQL format
// ================================================================================================
function create_standard_graphic( $WHOST_NAME, $WHOST_DESC , $WTYPE, $WOS )
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
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
				$CMD3       = "DEF:user=$RRD_FILE:cpu_busy:MAX LINE2:user#000000:\"% CPU time busy\"";
				$CMD4       = "DEF:user2=$RRD_FILE:cpu_busy:MAX AREA:user2#336699:\"\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4";
			}else{
	            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX DEF:user=$RRD_FILE:cpu_user:MAX ";
	            $CMD4       = "DEF:sys=$RRD_FILE:cpu_sys:MAX     DEF:wait=$RRD_FILE:cpu_wait:MAX ";
	            $CMD5       = "CDEF:csys=user,sys,+              CDEF:cwait=user,sys,wait,+,+  ";
	            $CMD6       = "AREA:cwait#99CC96:\"% Wait\"      AREA:csys#CC3333:\"% Sys\" ";
	            $CMD7       = "AREA:user#336699:\"% User\"       LINE2:total#000000:\"% total\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . " $CMD4" . " $CMD5" . " $CMD6" . " $CMD7";
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 7 days
            $START      = "$HRS_START $LASTWEEK" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "week" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 7 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
				$CMD3       = "DEF:user=$RRD_FILE:cpu_busy:MAX LINE2:user#000000:\"% CPU time busy\"";
				$CMD4       = "DEF:user2=$RRD_FILE:cpu_busy:MAX AREA:user2#336699:\"\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4";
			}else{
	            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX DEF:user=$RRD_FILE:cpu_user:MAX ";
	            $CMD4       = "DEF:sys=$RRD_FILE:cpu_sys:MAX     DEF:wait=$RRD_FILE:cpu_wait:MAX ";
	            $CMD5       = "CDEF:csys=user,sys,+              CDEF:cwait=user,sys,wait,+,+  ";
	            $CMD6       = "AREA:cwait#99CC96:\"% Wait\"      AREA:csys#CC3333:\"% Sys\" ";
	            $CMD7       = "AREA:user#336699:\"% User\"       LINE2:total#000000:\"% total\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . " $CMD4" . " $CMD5" . " $CMD6" . " $CMD7";
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 4 weeks
            $START      = "$HRS_START $LASTMONTH" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "month" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 4 weeks" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
				$CMD3       = "DEF:user=$RRD_FILE:cpu_busy:MAX LINE2:user#000000:\"% CPU time busy\"";
				$CMD4       = "DEF:user2=$RRD_FILE:cpu_busy:MAX AREA:user2#336699:\"\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4";
			}else{
	            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX DEF:user=$RRD_FILE:cpu_user:MAX ";
	            $CMD4       = "DEF:sys=$RRD_FILE:cpu_sys:MAX     DEF:wait=$RRD_FILE:cpu_wait:MAX ";
	            $CMD5       = "CDEF:csys=user,sys,+              CDEF:cwait=user,sys,wait,+,+  ";
	            $CMD6       = "AREA:cwait#99CC96:\"% Wait\"      AREA:csys#CC3333:\"% Sys\" ";
	            $CMD7       = "AREA:user#336699:\"% User\"       LINE2:total#000000:\"% total\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . " $CMD4" . " $CMD5" . " $CMD6" . " $CMD7";
			}
            $outline    = exec ("$CMD", $array_out, $retval);

            // Build command to execute and produce last 365 Days
            $START      = "$HRS_START $LASTYEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $WINTERVAL  = "year" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 365 days" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
				$CMD3       = "DEF:user=$RRD_FILE:cpu_busy:MAX LINE2:user#000000:\"% CPU time busy\"";
				$CMD4       = "DEF:user2=$RRD_FILE:cpu_busy:MAX AREA:user2#336699:\"\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4";
			}else{
	            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX DEF:user=$RRD_FILE:cpu_user:MAX ";
	            $CMD4       = "DEF:sys=$RRD_FILE:cpu_sys:MAX     DEF:wait=$RRD_FILE:cpu_wait:MAX ";
	            $CMD5       = "CDEF:csys=user,sys,+              CDEF:cwait=user,sys,wait,+,+  ";
	            $CMD6       = "AREA:cwait#99CC96:\"% Wait\"      AREA:csys#CC3333:\"% Sys\" ";
	            $CMD7       = "AREA:user#336699:\"% User\"       LINE2:total#000000:\"% total\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . " $CMD4" . " $CMD5" . " $CMD6" . " $CMD7";
			}
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
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"in MB\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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



        case "runqueue":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 250 --width 950";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_rque:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runque2=$RRD_FILE:proc_rque:MAX LINE2:runque2#000000:";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3"  .  " $CMD4" ;
			}else{
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
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
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_rque:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runque2=$RRD_FILE:proc_rque:MAX LINE2:runque2#000000:";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3"  .  " $CMD4" ;
			}else{
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
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
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_rque:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runque2=$RRD_FILE:proc_rque:MAX LINE2:runque2#000000:";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3"  .  " $CMD4" ;
			}else{
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
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
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_rque:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runque2=$RRD_FILE:proc_rque:MAX LINE2:runque2#000000:";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3"  .  " $CMD4" ;
			}else{
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            //    echo "<br>outline = $outline";
            //    echo "<br>array_out = $array_out";
            //    echo "<br>retval = $retval" ;
            break;

           
        case "diskio":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"MB/Second\" --height 250 --width 950";
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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
			if ( $WOS == "Linux" ) {
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

        case "network_eth0":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth0_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth0_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth0_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth0_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
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
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth1_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth1_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth1_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth1_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
            break;


        case "network_eth2":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$HRS_START $YESTERDAY2" ;
            $END        = "$HRS_END $YESTERDAY";
            $WINTERVAL  = "day" ;
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." - From $START to $END" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth2_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth2_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth2_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
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
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth2_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#192823:\"KB Received\" LINE2:kbout#DD1E2F:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
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
    //echo "   <td width=750 align=center colspan=3 bgcolor='aqua'>" . strtoupper($WTYPE) . " usage $WHOST_NAME - $WHOST_DESC</td>\n";
    echo "   <td width=750 align=center colspan=3 bgcolor='153450'><font color=$FONTCOLOR>" . strtoupper($WTYPE) . " usage $WHOST_NAME - $WHOST_DESC</font></bold></td>\n";

    echo "  </tr>\n";
    
    echo "  <tr align=left>\n";
    echo "   <td colspan=3 ><img src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_day.png></td>\n";
    echo "  </tr>\n" ; 
    echo "  <tr align=center>\n";
    echo "   <td><A HREF='/unix/server_perf_week.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE'><img  src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_week.png alt=\"Click to see larger view of last week   \"></a></td>\n";
    echo "   <td><A HREF='/unix/server_perf_month.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE'><img src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_month.png alt=\"Click to see a detailed view of last month  \"></a></td>\n";
    echo "   <td><A HREF='/unix/server_perf_2year.php?host=$WHOST_NAME&$WHOST_DESC&$WTYPE'><img src=${IMGDIR}/${WHOST_NAME}_${WTYPE}_year.png  alt=\"Click to view last 2 years\"></a></td>\n";
    echo "  </tr>\n" ; 
    echo "</table><br><br>";
    return ;
}
	
 
if (isset($_GET['host']) ) { 
    $HOSTNAME = $_GET['host'];
    $row = mysql_fetch_array ( mysql_query("SELECT * FROM `servers` WHERE `server_name` = '$HOSTNAME' "));
    $HOSTDESC   = $row['server_desc'];
	$HOST_OS     = $row['server_os'];

    echo "<center><strong><H1>Performance Graph - server $HOSTNAME - $HOSTDESC</strong></H1></center><br>";
    
    create_standard_graphic ($HOSTNAME, $HOSTDESC, "cpu", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "cpu");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "runqueue", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "runqueue");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "diskio", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "diskio");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "memory", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "memory");

	if ($HOST_OS == "Aix") {
        create_standard_graphic ($HOSTNAME, $HOSTDESC, "memory_usage", $HOST_OS);
        display_graph ($HOSTNAME, $HOSTDESC, "memory_usage");
	}
	
    create_standard_graphic ($HOSTNAME, $HOSTDESC, "paging_activity", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "paging_activity");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "paging_space_usage", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "paging_space_usage");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_eth0", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "network_eth0");

    create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_eth1", $HOST_OS);
    display_graph ($HOSTNAME, $HOSTDESC, "network_eth1");

	if ($HOST_OS == "Aix") {
		create_standard_graphic ($HOSTNAME, $HOSTDESC, "network_eth2", $HOST_OS);
        display_graph ($HOSTNAME, $HOSTDESC, "network_eth2");
	}
}
	if ($HOST_OS == "Aix") {
       echo "<center><A HREF='/data/nmon/archive/aix/$HOSTNAME'>Fichier NMON de ce serveur</a></center>\n";
    }else{
       echo "<center><A HREF='/data/nmon/archive/linux/$HOSTNAME'>Fichier NMON de ce serveur</a></center>\n";

    }

    
?>
<?php require      ($_SERVER['DOCUMENT_ROOT'].'/includes/footer.php')  ; ?>
