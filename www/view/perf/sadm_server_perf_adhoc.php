<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_perf_adhoc.php
#   Version  :  1.0
#   Date     :  23 January 2018
#   Requires :  php
#   Synopsis :  Present Options to Generate Performance Graphics for Server(s)#   
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
#   2018_01_23 JDuplessis
#       V 1.0 Initial Version
#   2018_02_03 JDuplessis
#       V 1.1 First Working Version
#
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmlib_graph.php');      # Load sadmin Graph Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # </head>Heading & SideBar


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "1.1" ;                                                        # Current version number




// ================================================================================================
//                       Transform date (DD/MM/YYY) into MYSQL format
// ================================================================================================
function gen_png ($WHOST,$WOS,$WSDATE,$WSTIME,$WEDATE,$WETIME,$RRDTOOL,$DEBUG)
{
    $RRD_FILE   = SADM_WWW_RRD_DIR ."/${WHOST}/${WHOST}.rrd"; # Where Host RRD Is
    $PNGDIR     = SADM_WWW_TMP_DIR . "/perf" ;                          # Where png file generated
    $IMGDIR     = "/tmp/perf" ;                                         # png Dir. for Web Server
    $TODAY      = date("d.m.Y");                                        # Today Date DD.MM.YYY
    $START      = "$WSTIME $WSDATE" ;
    $END        = "$WETIME $WEDATE";

    # Generate the PNG Performance Graph
    $WTYPE  = "cpu";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_cpu_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE  = "runqueue";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_runq_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE  = "memory";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_mem_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE  = "diskio";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_disk_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);  

    $WTYPE  = "page_inout";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_paging_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE  = "swap_space";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_swap_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
   
    $WTYPE  = "neta";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"a");
   
    $WTYPE  = "netb";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"b");
   
    $WTYPE  = "netc";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE WSTIME to $WEDATE $WETIME";
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"c");
   
    $WTYPE  = "netd";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"d");

    $WTYPE  = "memdist";
    $GFILE  = "${PNGDIR}/${WHOST}_${WTYPE}_adhoc.png";
    $GTITLE = "${WHOST} - " . strtoupper($WTYPE) . " from $WSDATE $WSTIME to $WEDATE $WETIME";
    create_memdist_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
}


// ================================================================================================
//                       Display Graphic Page 
// ================================================================================================
function display_png ($WHOST,$WTYPE,$WTITLE)
{
    $IMGDIR  = "/tmp/perf" ;                                            # PNG Dir. for Web Server
    $WEBFILE = "${IMGDIR}/${WHOST}_${WTYPE}_adhoc.png";                 # PNG File Path for Web Srv
    $OSFILE  = SADM_WWW_DIR . "$WEBFILE";                               # PNG File Path for O/S
    $URL     = "/view/perf/sadm_server_perf.php";                       # URL to View Yesterday PNG
    $FONTCOLOR = "Green";                                               # Heading Color
    echo "<center><h2>${WTITLE}</strong></center>";                     # Display Graph Title    
    
    # Display PNG Based on Parameters received
    if (file_exists($OSFILE)) {                                         # If PNG file exist on O/S
        echo "<center>";                                                # Center Graph
        echo "<a href=${URL}?host=$WHOST><img src=${WEBFILE}></a>";     # Show PNG with Link to Yest
        echo "</center>";                                               # Center Msg to User
    }else{                                                              # If file not there
        echo "<center><a href=${URL}?host=$WHOST>";                     # Center Msg to User
        echo "No data for $WPERIOD - Server '${WHOST}'";                # Show Host & Period instead
        echo "</a></center>";                                           # Finish File not found msg
    }
    echo "<br>";                                                        # Space line between graph
    return ;                                                            # Return to caller
}
	
 

 
# ==================================================================================================
#                                     Main Program Start Here
# ==================================================================================================

    # Show Debugging Information
    if ($DEBUG) {                                                       # In Debug Show Param. Rcv
        echo "\n<br>Parameters Received";                               # Show What is display below
        echo "\n<br>Server Name = " . $_POST['server_name'];            # Show Server Name received
        echo "\n<br>Start Date  = " . $_POST['sdate'];                  # Show Graph Start Date
        echo "\n<br>End Date    = " . $_POST['edate'];                  # Show Graph End Date
        echo "\n<br>Start Time  = " . $_POST['stime'];                  # Show Graph Start Time
        echo "\n<br>End Time    = " . $_POST['etime'];                  # Show Graph End Time 
        echo "\n<br>";                                                  # Blank Line
    }

    # Validate Server Name Received (if Any) and get Server description and O/S name
    if (isset($_POST['server_name']) ) {                                # server_name POST Exist ?
        $SERVER_NAME = $_POST['server_name'];                           # Save the Server Name
        $sql = "SELECT * FROM `server` WHERE `srv_name` = '$SERVER_NAME'";
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Server (" . $SERVER_NAME . ") not found.\n";   # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
            exit;                                                       # Exit - Should not occurs
        }
        $row = mysqli_fetch_assoc($result);                             # Gather Result from Query
		$SERVER_DESC   = $row['srv_desc'];                              # Save Server Description
		$SERVER_OS     = $row['srv_ostype'];                            # Save O/S Type aix/linux
	}else{
	    echo "The server name was not received !";                      # If Server Name not Set ?
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
	    exit ;                                                          # End of the Page
	}

    # Graph Start Date was received ?
	if (isset($_POST['sdate']) ) {                                      # Start Date Exist ?
	    $SDATE = str_replace ("-",".",$_POST['sdate']);                 # Replace - with . in date
	}else{
	    echo "The starting date was not received !";                    # Not Set ?, Inform User
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>"; # Show Back Link
	    exit ;                                                          # End of Page
	}

    # Graph End Date was received ?
	if (isset($_POST['edate']) ) {                                      # End Date Exist ?
	    $EDATE = str_replace ("-",".",$_POST['edate']);                 # Replace - with . in date
	}else{
	    echo "The ending date was not received !";                      # Not Set ?, Inform User
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>"; # Show Back Link
	    exit ;                                                          # End of Page
	}

    # Graph Start Time received ? 
    if (isset($_POST['stime']) ) {                                      # Start Time Exist ? 
	    $STIME = str_replace ("-",".",$_POST['stime']);                 # Replace - with .. in Time
	}else{                                                              # If Time was not received
	    echo "The starting time was not received !";                    # Inform User
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>"; # Show Back Link
	    exit ;                                                          # End of Page
	}

    # Graph End Time received ? 
    if (isset($_POST['etime']) ) {                                      # Start Time Exist ? 
	    $ETIME = str_replace ("-",".",$_POST['etime']);                 # Replace - with .. in Time
	}else{                                                              # If Time was not received
	    echo "The ending time was not received !";                      # Inform User
		echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>"; # Show Back Link
	    exit ;                                                          # End of Page
	}

    # Show Debugging Information
    if ($DEBUG) {                                                       # In Debug Show Final Var.
        echo "\n<br>Parameters Modified";                               # Show What is display below
        echo "\n<br>Server Name = " . $SERVER_NAME;                     # Show Server Name 
        echo "\n<br>Start Date  = " . $SDATE;                           # Show Graph Start Date
        echo "\n<br>End Date    = " . $EDATE;                           # Show Graph End Date
        echo "\n<br>Start Time  = " . $STIME;                           # Show Graph Start Time
        echo "\n<br>End Time    = " . $ETIME;                           # Show Graph End Time 
        echo "\n<br>";                                                  # Blank Line
    }

    # Read Network Device Name file (netdev.txt) & get the interface Name of each possible 4 Devices
    $netdev1="" ; $netdev2=""; $netdev3=""; $netdev4="";                # Clear Net interface name 
    $netcount  = 0;                                                     # Network  Interface Counter
    $NETDEV = SADM_WWW_RRD_DIR . "/${SERVER_NAME}/" . SADM_WWW_NETDEV ; # Server Path to netdev.txt
    if (file_exists($NETDEV)) {                                         # If Network Dev file exist
        $handle = fopen($NETDEV, "r");                                  # Open netdev.txt of server
        if ($handle) {                                                  # If Successfully Open
            while (($line = fgets($handle)) !== false) {                # If Still Line to read
                $netcount++;                                            # Increase Line Number
                if ($netcount == 1) { $netdev1 = $line ; }              # Get Name of Net interface1
                if ($netcount == 2) { $netdev2 = $line ; }              # Get Name of Net interface2
                if ($netcount == 3) { $netdev3 = $line ; }              # Get Name of Net interface3
                if ($netcount == 4) { $netdev4 = $line ; }              # Get Name of Net interface4
            }
            fclose($handle);                                            # Close Network DevName file
        }    
    }

    # Under Debug, Show Name of device file, Name of each Network Interface and Number of interfaces
    if ($DEBUG) { 
        echo "\n<br>Netdev filename is $NETDEV";
        echo "\n<br>dev1= $netdev1 \n<br>dev2= $netdev2 \n<br>dev3= $netdev3 \n<br>dev4= $netdev4";
        echo "\n<br>NetCount is $netcount";
    }

    # Display Standard Page Heading ----------------------------------------------------------------
    display_std_heading("NotHome","Adhoc Performance Graph for $SERVER_NAME","","",$SVER); 

    # Display This page heading --------------------------------------------------------------------
    echo "<center><H1>";
    echo " Adhoc Performance Graph for " . $SERVER_NAME;
    echo "</H1></center><br>";

    # Generate and Display Graph for server --------------------------------------------------------
    gen_png ($SERVER_NAME,$SERVER_OS,$SDATE,$STIME,$EDATE,$ETIME,SADM_RRDTOOL,$DEBUG); # Gen PNG
    display_png($SERVER_NAME,"cpu","CPU usage");                        # CPU Graph
    display_png($SERVER_NAME,"runqueue","Run Queue Usage");             # Run Queue Graph
    display_png($SERVER_NAME,"memory","Memory usage"    );              # Memory Graph
    display_png($SERVER_NAME,"diskio","Disk I/O"    );                  # Disk I/O Graph
    if ($SERVER_OS == "aix") { display_png($SERVER_NAME,"memdist","Memory Distribution"); } # AixMem
    display_png($SERVER_NAME,"page_inout","Page in/out");               # Paging - Page In, Page out
    display_png($SERVER_NAME,"swap_space","Swap space usage");          # Swap Space Usage

    $WTITLE = "1st Network Interface" ;                                 # Set Default Graph Title
    if ($netdev1 != "") { $WTITLE = "Network Interface $netdev1"; }     # Include DevDev Name 
    display_png($SERVER_NAME,"neta",$WTITLE);                           # 1st Network Interface

    $WTITLE = "2nd Network Interface" ;                                 # Set Default Graph Title
    if ($netdev2 != "") { 
        $WTITLE = "Network Interface $netdev2";                         # Include DevDev Name 
        display_png($SERVER_NAME,"netb",$WTITLE);                       # 2nd Network Interface
    }
    $WTITLE = "3rd Network Interface" ;                                 # Set Default Graph Title
    if ($netdev3 != "") {
        $WTITLE = "Network Interface $netdev3";                         # Include DevDev Name 
        display_png($SERVER_NAME,"netc",$WTITLE);                       # 3rd Network Interface
    }
    $WTITLE = "4th Network Interface" ;                                 # Set Default Graph Title
    if ($netdev4 != "") {
        $WTITLE = "Network Interface $netdev4";                         # Include DevDev Name 
        display_png($SERVER_NAME,"netd",$WTITLE);                       # 4th Network Interface
    }
    echo "\n<br><br>";                                                  # End of table

    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
