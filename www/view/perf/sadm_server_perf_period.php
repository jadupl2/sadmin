<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_perf_period.php
#   Version  :  1.0
#   Date     :  23 January 2018
#   Requires :  php
#   Synopsis :  Generate Performance Graphics of one server for the period and host received 
#                   1st parameter is the hostname
#                   2nd parameter is the period of the graph to display
#                       Valid period are "yesterday","last2days","last7days","last31days",
#                                        "last365days","last730days"
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#       V 1.2 Performance & Restructure 
#       V 1.3 Initial production version
#   2018_02_07 JDuplessis
#       V 1.4 Bug Fix & Add Link to various period on page
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
$SVER  = "1.3" ;                                                        # Current version number




# ==================================================================================================
#         Generate and display all the performance graph type for date/time range received
# ==================================================================================================
function gen_png ($WHOST,$WOS,$WPERIOD,$RRDTOOL,$DEBUG)
{
    $RRD_FILE   = SADM_WWW_RRD_DIR ."/${WHOST}/${WHOST}.rrd";           # Where Host RRD Is
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
    if ($DEBUG) {                                                       # If Debug is Activated
        echo "\n<br>RRDTOOL    = $RRDTOOL";                             # Full Path to rrdtool Bin.
        echo "\n<br>PERIOD     = $WPERIOD";                             # Show the Period received
        echo "\n<br>RRD_FILE   = $RRD_FILE";                            # Show RRD file we will use
        echo "\n<br>PNGDIR     = $PNGDIR";                              # PNG Dir. for the O/S
        echo "\n<br>IMGDIR     = $IMGDIR";                              # PNG Dir. for Web Server
        echo "\n<br>TODAY      = $TODAY     ";                          # Today's Date
        echo "\n<br>YESTERDAY  = $YESTERDAY ";                          # Yesterday Date
        echo "\n<br>YESTERDAY2 = $YESTERDAY2";                          # Date before Yesterday
        echo "\n<br>LASTWEEK   = $LASTWEEK  ";                          # Today Minus  7 Days Date
        echo "\n<br>LASTMONTH  = $LASTMONTH ";                          # Today Minus 31 Days Date
        echo "\n<br>LASTYEAR   = $LASTYEAR  ";                          # Today Minus 365 Days Date
        echo "\n<br>LAST2YEAR  = $LAST2YEAR ";                          # Today Minus 730 Days Date
        echo "\n<br>HRS_START  = $HRS_START ";                          # Start Hours of Graph
        echo "\n<br>HRS_END    = $HRS_END   ";                          # End Hours of Graph
    }

    # Set Start/End Date and Time based on the WPERIOD requested 
    switch ($WPERIOD) {
        case "yesterday"   : $GSTART = "$HRS_START $YESTERDAY";         # Format for RRDTOOL
                             $HSTART = "$YESTERDAY $HRS_START";         # Format for Heading
                             break; 
        case "last2days"   : $GSTART = "$HRS_START  $YESTERDAY2";       # Format for RRDTOOL
                             $HSTART = "$YESTERDAY2 $HRS_START";        # Format for Heading
                             break; 
        case "last7days"   : $GSTART = "$HRS_START $LASTWEEK";          # Format for RRDTOOL
                             $HSTART = "$LASTWEEK  $HRS_START";         # Format for Heading
                             break; 
        case "last31days"  : $GSTART = "$HRS_START $LASTMONTH";         # Format for RRDTOOL
                             $HSTART = "$LASTMONTH $HRS_START";         # Format for Heading
                             break; 
        case "last365days" : $GSTART = "$HRS_START $LASTYEAR";          # Format for RRDTOOL
                             $HSTART = "$LASTYEAR $HRS_START";          # Format for Heading
                             break; 
        case "last730days" : $GSTART = "$HRS_START $LAST2YEAR";         # Format for RRDTOOL
                             $HSTART = "$LAST2YEAR $HRS_START";         # Format for Heading
                             break; 
        default:                                                        # If invalid period
            echo "The WPERIOD received is invalid ($WPERIOD)" ;         # Advise users
            exit ;                                                      # End of Page
    }
    $GEND = "$HRS_END $YESTERDAY" ;                                     # Format for RRDTOOLS 
    $HEND = "$YESTERDAY $HRS_END" ;                                     # Format for Heading
    
    # Generate the PNG Performance Graph
    $WTYPE   = "cpu";                                                   # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_cpu_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE   = "runqueue";                                               # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_runq_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE  = "memory";                                                 # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_mem_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE  = "diskio";                                                 # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_disk_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG);  

    $WTYPE  = "page_inout";                                             # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_paging_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG);

    $WTYPE  = "swap_space";                                             # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_swap_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG);
   
    $WTYPE  = "neta";                                                   # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG,"a");
   
    $WTYPE  = "netb";                                                   # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG,"b");
   
    $WTYPE  = "netc";                                                   # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG,"c");
   
    $WTYPE  = "netd";                                                   # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG,"d");

    $WTYPE  = "memdist";                                                # Graph Type
    $GFILE   = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # Output PNG FileName
    $GTITLE  = "${WHOST} - " . strtoupper($WTYPE) . " from $HSTART to $HEND"; # Graph Title
    create_memdist_graph($WHOST,$RRDTOOL,$RRD_FILE,$GSTART,$GEND,$GTITLE,$GFILE,"B",$DEBUG);
}


# ==================================================================================================
#           Display Large Performance Graphic Page fo the host, type and period received 
# ==================================================================================================
function display_png ($WHOST,$WTYPE,$WTITLE,$WPERIOD)
{
    $IMGDIR  = "/tmp/perf" ;                                            # PNG Dir. for Web Server
    $WEBFILE = "${IMGDIR}/${WHOST}_${WTYPE}_${WPERIOD}.png";            # PNG File Path for Web Srv
    $OSFILE  = SADM_WWW_DIR . "$WEBFILE";                               # PNG File Path from O/S
    $URL     = "/view/perf/sadm_server_perf.php";                       # URL to View Yesterday Perf

    # Web Page URL if User click on one of the PNG Graph
    $URL1        = "/view/perf/sadm_server_perf_period.php";            # Common URL Start Part 
    $URL_DAY     = $URL1 . "?host=$WHOST&period=yesterday";             # URL For Daily Display
    $URL_2DAYS   = $URL1 . "?host=$WHOST&period=last2days";             # URL for Week Display
    $URL_7DAYS   = $URL1 . "?host=$WHOST&period=last7days";             # URL for Week Display
    $URL_31DAYS  = $URL1 . "?host=$WHOST&period=last31days";            # URL for Month Display
    $URL_365DAYS = $URL1 . "?host=$WHOST&period=last365days";           # URL for Year Display
    $URL_730DAYS = $URL1 . "?host=$WHOST&period=last730days";           # URL for 2 Years Display
    
    # When cursor move over the graph, Message below will be displayed
    $ALT_DAY     = "Click to view yesterday graph of $WHOST";           # Day Message when on Graph
    $ALT_2DAYS   = "Click for last 2 days Graph";                       # Week Message when on Graph
    $ALT_7DAYS   = "Click for last 7 days Graph";                       # Week Message when on Graph
    $ALT_31DAYS  = "Click for last 31 days Graph";                      # Mth Message when on Graph
    $ALT_375DAYS = "Click for last 365 days Graph ";                    # Year Message when on Graph
    $ALT_730DAYS = "Click for last 730 days Graph ";                    # Year Message when on Graph

    echo "\n<center>";                                                  # Center Title & Graph 
    echo "\n<h2><strong>${WTITLE}</strong></h2>";                       # Display Graph Title    
    echo "\n<a href='${URL_DAY}' data-toggle='tooltip' title='${ALT_DAY}'>Yesterday</a>";
    echo str_repeat('&nbsp;', 2);                                       # 2 Spaces between Title
    echo "\n<a href='${URL_2DAYS}' data-toggle='tooltip' title='${ALT_2DAYS}'>Last 2 Days</a>";
    echo str_repeat('&nbsp;', 2);                                       # 2 Spaces between Title
    echo "\n<a href='${URL_7DAYS}' data-toggle='tooltip' title='${ALT_7DAYS}'>Last 7 Days</a>";
    echo str_repeat('&nbsp;', 2);                                       # 2 Spaces between Title
    echo "\n<a href='${URL_31DAYS}' data-toggle='tooltip' title='${ALT_31DAYS}'>Last 31 Days</a>";
    echo str_repeat('&nbsp;', 2);                                       # 2 Spaces between Title
    echo "\n<a href='${URL_365DAYS}' data-toggle='tooltip' title='${ALT_365DAYS}'>Last 365 Days</a>";
    echo str_repeat('&nbsp;', 2);                                       # 2 Spaces between Title
    echo "\n<a href='${URL_730DAYS}' data-toggle='tooltip' title='${ALT_730DAYS}'>Last 730 Days</a>";
    echo "<br>";
    echo "<br>";

    echo "\n<a href=${URL}?host=$WHOST>";                               # Link 2 Yesterday Perf Page
    if (file_exists($OSFILE)) {                                         # If PNG file exist on O/S
        echo "<img src=${WEBFILE}>";                                    # Show PNG Graph
    }else{                                                              # If PNG file not there
        echo "No data for $WPERIOD - Server '${WHOST}'";                # Show Host & Period instead
    }
    echo "</a>";                                                        # End of Link 
    echo "\n</center>";                                                 # End of centering
    echo "\n<br>";                                                      # Space line between graph
    return ;                                                            # Return to caller
}

 

# ==================================================================================================
#                                     Main Program Start Here
# ==================================================================================================

    # Show Debugging Information
    if ($DEBUG) {                                                       # In Debug Show Param. Rcv
        echo "\n<br>Parameters Received";                               # Show What is display below
        echo "\n<br>Server Name = " . $_GET['host'];                    # Show Server Name received
        echo "\n<br>Period      = " . $_GET['period'];                  # Show Graph Period
        echo "\n<br>";                                                  # Blank Line
    }

    # Validate if Server Name Received (if Any) and get Server description and O/S name
    if (isset($_GET['host']) ) {                                        # server_name POST Exist ?
        $WSERVER = $_GET['host'];                                       # Save the Server Name
        $sql = "SELECT * FROM server WHERE srv_name = '$WSERVER'";      # Build SQL Stat Read Server
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Server (" . $WSERVER . ") not found.\n";       # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
            exit;                                                       # Exit - Should not occurs
        }
        $row = mysqli_fetch_assoc($result);                             # Gather Result from Query
        $WDESC   = $row['srv_desc'];                                    # Save Server Description
        $WOS     = $row['srv_ostype'];                                  # Save O/S Type aix/linux
    }else{                                                              # Server name not Set
        echo "The server name was not set !";                           # If Server Name not Set ?
        echo "<a href='javascript:history.go(-1)'>Go back</a>";         # Back to Previous Page
        exit ;                                                          # End of the Page
    }

    # Graph Period is Set ?
    if (isset($_GET['period']) ) {                                      # period is Set ?
        $WPERIOD = $_GET['period'];                                     # period of graph
        switch ($WPERIOD) {
            case "yesterday"   : $HPERIOD="Yesterday"  ;   break;       # Graph for yesterday
            case "last2days"   : $HPERIOD="last 2 days";   break;       # Graph for last 2 days
            case "last7days"   : $HPERIOD="last 7 days";   break;       # Graph for last 7 days
            case "last31days"  : $HPERIOD="last 31 days";  break;       # Graph for last 31 days
            case "last365days" : $HPERIOD="last 365 days"; break;       # Graph for last 365 days
            case "last730days" : $HPERIOD="last 730 days"; break;       # Graph for last 730 days
            default:                                                    # If invalid period
                echo "The WPERIOD received is invalid ($WPERIOD)" ;     # Advise users
                exit ;                                                  # End of Page
        }
    }else{                                                              # No Start Date 
        echo "The Graph Period was not set !";                          # Not Set ?, Inform User
        echo "<a href='javascript:history.go(-1)'>Go back</a>";         # Back to Previous Page
        exit ;                                                          # End of Page
    }

    # Read Network Device Name file (netdev.txt) & get the interface Name of each possible 4 Devices
    $netdev1="" ; $netdev2=""; $netdev3=""; $netdev4="";                # Clear Net interface name 
    $netcount  = 0;                                                     # Network  Interface Counter
    $NETDEV = SADM_WWW_RRD_DIR . "/${WSERVER}/" . SADM_WWW_NETDEV ;     # Server Path to netdev.txt
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
    $title1="Performance graph of '$WSERVER' for $HPERIOD";
    $title2="";
    display_lib_heading("NotHome","$title1","",$SVER); 
    
    # Generate Graph for server --------------------------------------------------------------------
    gen_png ($WSERVER,$WOS,$WPERIOD,SADM_RRDTOOL,$DEBUG);               # Generate the Graph PNG

    # Display THe Performance Graph ----------------------------------------------------------------
    display_png($WSERVER,"cpu","CPU usage",$WPERIOD);                   # CPU Graph
    display_png($WSERVER,"runqueue","Run Queue Usage",$WPERIOD);        # Run Queue Graph
    display_png($WSERVER,"memory","Memory usage",$WPERIOD);             # Memory Graph
    display_png($WSERVER,"diskio","Disk I/O",$WPERIOD);                 # Disk I/O Graph
    if ($WOS == "aix") {                                                # If an Aix Server
        display_png($WSERVER,"memdist","Memory Distribution",$WPERIOD); # AixMem
    } 
    display_png($WSERVER,"page_inout","Page in/out",$WPERIOD);          # Paging - Page In, Page out
    display_png($WSERVER,"swap_space","Swap space usage",$WPERIOD);     # Swap Space Usage

    # Display Network Interface Graph
    $WTITLE = "1st Network Interface" ;                                 # Set Default Graph Title
    if ($netdev1 != "") { $WTITLE = "Network Interface $netdev1"; }     # Include DevDev Name 
    display_png($WSERVER,"neta",$WTITLE,$WPERIOD);                      # Allways show 1st Interface
    $WTITLE = "2nd Network Interface" ;                                 # Set Net2 Def. Graph Title
    if ($netdev2 != "") {                                               # If we have 2nd Interface
        $WTITLE = "Network Interface $netdev2";                         # Include 2nd Dev Name 
        display_png($WSERVER,"netb",$WTITLE,$WPERIOD);                  # 2nd Network Interface
    }
    $WTITLE = "3rd Network Interface" ;                                 # Set Net3 Def. Graph Title
    if ($netdev3 != "") {                                               # If we have 3rd Interface
        $WTITLE = "Network Interface $netdev3";                         # Include 3rd Dev Name 
        display_png($WSERVER,"netc",$WTITLE,$WPERIOD);                  # 3rd Network Interface
    }
    $WTITLE = "4th Network Interface" ;                                 # Set Net4 Def. Graph Title
    if ($netdev4 != "") {                                               # If we have 4th Interface
        $WTITLE = "Network Interface $netdev4";                         # Include 4th Dev Name 
        display_png($WSERVER,"netd",$WTITLE,$WPERIOD);                  # 4th Network Interface
    }
    echo "\n<br><br>";                                                  # End of table
    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
