<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/connection.php'); ?>
<?php include($_SERVER['DOCUMENT_ROOT'].'/includes/header.php')  ; ?>
<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/functions.php'); ?>
<?php include($_SERVER['DOCUMENT_ROOT'].'/unix/server_menu.php')  ; ?>

<?php
// ================================================================================================
//                       Transform date (DD/MM/YYY) into MYSQL format
// ================================================================================================
function create_standard_graphic( $WHOST_NAME,$WHOST_DESC,$WTYPE,$WSDATE,$WEDATE,$WSTIME,$WETIME,$WOS)
{
    $WEBDIR     = $_SERVER['DOCUMENT_ROOT'];
    $RRD_DIR   = "$WEBDIR/rrd/perf" ;
    $RRDTOOL    = "/usr/bin/rrdtool";
    $PNGDIR     = "$WEBDIR/images/perf" ;  
    $TODAY      = date("d.m.Y");
    $RRD_FILE   = "$RRD_DIR/${WHOST_NAME}/$WHOST_NAME.rrd";
    $WINTERVAL  = "adhoc" ;

    switch ($WTYPE) {
        case "cpu":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
			$CMD2       = "--vertical-label \"percentage(%)\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
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
			break ;

		
        case "runqueue":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Load\" --height 250 --width 950";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_rque:MAX LINE2:runque#0000FF:\"Number of tasks waiting for CPU resources\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:runque=$RRD_FILE:proc_runq:MAX AREA:runque#CC9A57:\"Number of tasks waiting for CPU resources\"";
				$CMD4       = "DEF:runq=$RRD_FILE:proc_runq:MAX LINE2:runq#000000:";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
			break ;

        case "memory":
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 " ;
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX DEF:memfree=$RRD_FILE:mem_free:MAX ";
	            $CMD4       = "LINE2:memused#000000:\"Memory used by Processes\" LINE2:memfree#FF0000:\"Free Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}else{
	            $CMD3       = "DEF:memused=$RRD_FILE:mem_used:MAX   AREA:memused#294052:\"Memory Use\" ";
	            $CMD4       = "DEF:memtotal=$RRD_FILE:mem_total:MAX LINE2:memtotal#000000:\"Total Memory\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4" ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
			break ;

        case "memory_usage":
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
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
			break ;
		
        case "diskio":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
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
			break ;

        case "paging_activity":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"Pages/Second\" --height 250 --width 950";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:pgsec=$RRD_FILE:swap_in_out_sec:MAX LINE2:pgsec#000000:\"Swap pages IN + OUT per second\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:page_in=$RRD_FILE:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
	            $CMD4       = "DEF:page_out=$RRD_FILE:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
			$outline    = exec ("$CMD", $array_out, $retval);
			break ;

        case "paging_space_usage":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"percentage(%)\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:swapused=$RRD_FILE:swap_used_pct:MAX LINE2:swapused#000000:\"% Swap Space Used\"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" ;
			}else{
	            $CMD3       = "DEF:page_used=$RRD_FILE:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
	            $CMD4       = "DEF:page_total=$RRD_FILE:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\" ";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3" .  " $CMD4" ;
			}
			$outline    = exec ("$CMD", $array_out, $retval);
			break ;

        case "network_eth0":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
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
			break ;

        case "network_eth1":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
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
			break ;

        case "network_eth2":
            // Build command to execute and produce last 2 days of Graph
            $START      = "$WSTIME $WSDATE" ;
            $END        = "$WETIME $WEDATE";
            $GFILE      = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_${WINTERVAL}.png";
            $GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) . " performance between the $WSDATE at $WSTIME and the $WEDATE at $WETIME" ;
            $CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
            $CMD2       = "--vertical-label \"KB/s\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
			if ( $WOS == "Linux" ) {
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth1_kbytesin:MAX  DEF:kbout=$RRD_FILE:eth1_kbytesout:MAX ";
				$CMD4       = "LINE2:kbin#000000:\"KB Received\" LINE2:kbout#0000FF:\"KB Transmitted\"";
				$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}else{
	            $CMD3       = "DEF:kbin=$RRD_FILE:eth2_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
	            $CMD4       = "DEF:kbout=$RRD_FILE:eth2_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
	            $CMD        = "$CMD1" . " $CMD2 " .  " $CMD3 " . "$CMD4 " ;
			}
            $outline    = exec ("$CMD", $array_out, $retval);
			break ;
    }
}


// ================================================================================================
//                       Display Graphic Page 
// ================================================================================================
function display_graph ( $WHOST_NAME, $WHOST_DESC , $WTYPE)
{
    $PNGDIR    = "/images/perf" ;
	$GFILENAME = "${PNGDIR}/${WHOST_NAME}_${WTYPE}_adhoc.png"; 
	$GTITLE    = strtoupper($WTYPE) . " usage $WHOST_NAME - $WHOST_DESC";
    $FONTCOLOR = "White"; 
    echo "<table width=750 align=center border=1 cellspacing=0>\n";
	
    echo "<tr>\n" ;
    echo "   <td width=750 align=center bgcolor='153450'><font color=$FONTCOLOR>$GTITLE</font></bold></td>\n";
    echo "</tr>\n";
    
    echo "  <tr>\n";
    echo "  <td><img src=$GFILENAME></td>\n";
    echo "  </tr>\n" ;
    echo "</table><br><br>";
    return ;
}
	
 

 
// ================================================================================================
//                                    Main Program Start Here
// ================================================================================================

//	$SERVER_NAME = $_POST['server_name'];  	echo "server_name   $SERVER_NAME <br>";
//	$SDATE = $_POST['sdate'];  				echo "sdate   $SDATE  <br>";
//	$EDATE = $_POST['edate'];  				echo "edate   $EDATE  <br>";
//	$STIME = $_POST['stime'];  				echo "stime   $STIME  <br>";
//	$ETIME = $_POST['etime'];  				echo "etime   $ETIME  <br>";

	if (isset($_POST['server_name']) ) { 
	    $SERVER_NAME = $_POST['server_name'];
		$row = mysql_fetch_array ( mysql_query("SELECT * FROM `servers` WHERE `server_name` = '$SERVER_NAME' "));
		$SERVER_DESC   = $row['server_desc'];
		$SERVER_OS     = $row['server_os'];
	}else{
	    echo "The server name was not received !";
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
	    exit ;
	}

	if (isset($_POST['sdate']) ) { 
	    $SDATE = str_replace ("-",".",$_POST['sdate']);
	}else{
	    echo "The starting date was not received !";
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
	    exit ;
	}

	if (isset($_POST['edate']) ) { 
	    $EDATE = str_replace ("-",".",$_POST['edate']);
	}else{
	    echo "The ending date was not received !";
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
	    exit ;
	}

	if (isset($_POST['stime']) ) { 
	    $STIME = str_replace ("-",".",$_POST['stime']);
	}else{
	    echo "The starting time was not received !";
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
	    exit ;
	}

	if (isset($_POST['etime']) ) { 
	    $ETIME = str_replace ("-",".",$_POST['etime']);
	}else{
	    echo "The ending time was not received !";
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
	    exit ;
	}

	echo "<center><strong><H1>Performance Graph for $SERVER_OS server $SERVER_NAME - $SERVER_DESC</strong></H1></center><br>";

	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'cpu',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "cpu");
	
	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'runqueue',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "runqueue");
	
	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'diskio',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "diskio");

	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'memory',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "memory");

	if ($SERVER_OS == "Aix") {
		create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'memory_usage',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
	    display_graph ($SERVER_NAME, $SERVER_DESC, "memory_usage");
	}
	
	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'paging_activity',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "paging_activity");

	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'paging_space_usage',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "paging_space_usage");

	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'network_eth0',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "network_eth0");

	create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'network_eth1',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
    display_graph ($SERVER_NAME, $SERVER_DESC, "network_eth1");

	if ($SERVER_OS == "Aix") {
		create_standard_graphic( $SERVER_NAME,$SERVER_DESC,'network_eth2',$SDATE,$EDATE,$STIME,$ETIME,$SERVER_OS);
		display_graph ($SERVER_NAME, $SERVER_DESC, "network_eth2");
	}
?>
<?php require      ($_SERVER['DOCUMENT_ROOT'].'/includes/footer.php')  ; ?>
