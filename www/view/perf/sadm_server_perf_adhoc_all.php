<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/connection.php'); ?>
<?php include($_SERVER['DOCUMENT_ROOT'].'/includes/header.php')  ; ?>
<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/functions.php'); ?>
<?php include($_SERVER['DOCUMENT_ROOT'].'/unix/server_menu.php')  ; ?>

<?php
// ================================================================================================
//                       Create 2 Years Graph for the server received in parameter
// ================================================================================================
function create_standard_graphic( $WHOST_NAME, $WHOST_DESC , $WTYPE, $WPERIOD, $WOS)
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
	case "2years" :
            $START      = "$HRS_START $LAST2YEAR" ;
            $END        = "$HRS_END   $YESTERDAY";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last $WPERIOD" ;
            break;
}

    switch ($WTYPE) {
        case "cpu":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:user=$RRD_FILE:cpu_busy:MAX LINE2:user#0000FF:\"% CPU time busy\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3";
			}else{
	            $CMD3       = "DEF:total=$RRD_FILE:cpu_total:MAX DEF:user=$RRD_FILE:cpu_user:MAX ";
	            $CMD4       = "DEF:sys=$RRD_FILE:cpu_sys:MAX     DEF:wait=$RRD_FILE:cpu_wait:MAX ";
	            $CMD5       = "CDEF:csys=user,sys,+              CDEF:cwait=user,sys,wait,+,+  ";
	            $CMD6       = "AREA:cwait#99CC96:\"% Wait\"      AREA:csys#CC3333:\"% Sys\" ";
	            $CMD7       = "AREA:user#336699:\"% User\"       LINE2:total#000000:\"% total\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" . " $CMD4" . " $CMD5" . " $CMD6" . " $CMD7";
			}
			$outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "memory":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
	            $CMD4       = "LINE2:memused#000000:\"Memory used by Processes\" LINE2:memfree#FF0000:\"Free Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}else{
	            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 " ;
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
	            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}
			$outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "memory_usage":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
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
            break;

        case "runqueue":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 125 --width 250";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_rque:MAX LINE2:runque#0000FF:\"Number of tasks waiting for CPU resources\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
			$outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "diskio":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
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
            break;

        case "paging_activity":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
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
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:swapused=$RRD_FILE:swap_used_pct:MAX LINE2:swapused#000000:\"% Swap Space Used\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
	            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
			$outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "network_eth0":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth0_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#000000:\"KB Received\" LINE2:kbout#0000FF:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth0_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth0_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
			$outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "network_eth1":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth1_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#000000:\"KB Received\" LINE2:kbout#0000FF:\"KB Transmitted\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth1_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
			$outline    = exec ("$CMD", $array_out, $retval);
            break;

        case "network_eth2":
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WPERIOD}_all.png";
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 125 --width 250 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth2_kbytesout:MAX ";
	            $CMD4       = "LINE2:kbin#000000:\"KB Received\" LINE2:kbout#0000FF:\"KB Transmitted\"";
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
	

 
// ================================================================================================
//                                    Main Program Start Here
// ================================================================================================
//echo "wtype $_POST['wtype']";
//echo "<br />"; 
//echo "wperiod $_POST['wperiod']";  
//echo "<br />";
//echo "wservers $_POST['wservers']"; 

	if (isset($_POST['wtype']) ) { 
	    $WTYPE = $_POST['wtype'];
	    switch ($WTYPE) {
		case "cpu"  :
	            break;
		case "memory" :
	            break;
		case "memory_usage" :
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
		case "network_eth2" :
	            break;
		default:
		    echo "The WTYPE received is invalid ($WTYPE)" ;
		    exit ;
		}
	}else{
	    echo "The WTYPE received is invalid ($WTYPE)" ;
	    exit ;
	}

	if (isset($_POST['wperiod']) ) { 
		$WPERIOD = $_POST['wperiod'];
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
	}else{
		echo "The WPERIOD received is invalid ($WPERIOD)" ;
		exit ;
	}
	
	if (isset($_POST['wservers']) ) { 
		$WSERVERS = $_POST['wservers'];
	    switch ($WSERVERS) {
		case "all_linux"  :
	            $result = mysql_query("SELECT * FROM `servers` where server_os='Linux' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
	            break;
		case "all_aix" :
	            $result = mysql_query("SELECT * FROM `servers` where server_os='Aix' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
	            break;
		case "all_servers"  :
	            $result = mysql_query("SELECT * FROM `servers` where (server_os='Linux' or server_os='Aix') and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
	            break;
		case "all_linux_prod" :
	            $result = mysql_query("SELECT * FROM `servers` where server_os='Linux' and server_type='Prod' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
	            break;
		case "all_linux_dev"  :
	            $result = mysql_query("SELECT * FROM `servers` where server_os='Linux' and server_type='Dev' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
	            break;
		case "all_aix_prod" :
	            $result = mysql_query("SELECT * FROM `servers` where server_os='Aix' and server_type='Prod' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
	            break;
		case "all_aix_dev"  :
	            $result = mysql_query("SELECT * FROM `servers` where server_os='Aix' and server_type='Dev' and server_active=1 and server_graphic=1 order by server_name" ) or trigger_error(mysql_error()); 
	            break;
		default:
		    echo "The WOS received is invalid ($WOS)" ;
		    exit ;
	    }
	}else{
		echo "The WOS received is invalid ($WOS)" ;
		exit ;
	}

    $COUNT=0;
    echo "<center><strong><H1>Performance Graph for $WSERVERS servers ($WTYPE/$WPERIOD)</strong></H1></center><br>";

    echo "<table width=750 align=center border=2 cellspacing=1>\n";
    echo "  <tr>\n" ;
    while ($row = mysql_fetch_array($result)){
          $COUNT+=1;
          $HOSTNAME = $row['server_name'] ;
		  $HOSTDESC = $row['server_desc'] ;
		  $HOSTOS   = $row['server_os'];
          create_standard_graphic ($HOSTNAME, $HOSTDESC, $WTYPE, $WPERIOD, $HOSTOS);
          display_graph ($HOSTNAME, $HOSTDESC, $WTYPE , $WPERIOD, $COUNT, $HOSTOS);
    }
    echo "  </tr>\n" ; 
    echo "</table><br><br>";

?>
<?php require      ($_SERVER['DOCUMENT_ROOT'].'/includes/footer.php')  ; ?>
