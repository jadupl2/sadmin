<?php
# ================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_perf_yesterday.php
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
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmlib_graph.php');      # Load sadmin Graph Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # </head>Heading & SideBar


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG  = false ;                                                       # Debug Activated True/False
$SVER   = "1.1" ;                                                       # Current version number
$IMGDIR = "/tmp/perf" ;


# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
# HOSTNAME  = Name of Host,                 WHOST_DESC  = Host Desciption from MySql Database 
# WTYPE     = cpu,runqueue,diskio,memory,page_inout,swap_space,network_eth[a,b,c]
# WOS       = linux,aix (lowercase allways) RRDTOOL     = Path to rrdtool       DEBUG = True,False
# ==================================================================================================
function create_standard_graphic($WHOST_NAME,$WHOST_DESC,$WTYPE,$WOS,$RRDTOOL,$DEBUG)
{
    $RRD_FILE   = SADM_WWW_RRD_DIR ."/${WHOST_NAME}/${WHOST_NAME}.rrd"; # Where Host RRD Is
    $PNGDIR     = SADM_WWW_TMP_DIR . "/perf" ;                          # Where png file generated
    $IMGDIR     = "/tmp/perf" ;                                         # png Dir. for Web Server
    $YESTERDAY  = mktime(0, 0, 0, date("m"), date("d")-1,   date("Y")); # Return Yesterday EpochTime 
    $YESTERDAY  = date ("d.m.Y",$YESTERDAY);                            # Yesterday Date DD.MM.YYY
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
            # Generate Big CPU Graphic for Yesterday -----------------------------------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_cpu_yesterday.png";     # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - CPU - From $START to $END" ;  # Set Graph Title 
            create_cpu_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"cpu",$DEBUG);       # Show Graph Just Generated
            break;
            
        case "runqueue":
            # Generate Big RunQueue Graphic for Yesterday ------------------------------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_runqueue_yesterday.png";# Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - RunQueue - ";         # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_runq_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"runqueue",$DEBUG);  # Show Graph Just Generated
            break;

        case "memory":
            # Generate Big Memory Graphic for Yesterday --------------------------------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memory_yesterday.png";  # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Memory - ";           # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_mem_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"memory",$DEBUG);    # Show Graph Just Generated
            break;

        case "diskio":
            # Generate Big Disks I/O Graphic for Yesterday -----------------------------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_diskio_yesterday.png";  # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Disks I/O - ";        # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_disk_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"diskio",$DEBUG);    # Show Graph Just Generated
            break;

        case "page_inout":
            # Generate Big Paging Activity Graphic for Yesterday -----------------------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_paging_yesterday.png";  # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Paging Act. - ";      # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_paging_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"paging",$DEBUG);    # Show Graph Just Generated
            break;

        case "swap_space":
            # Generate Big Swap Space Usage Graphic for Yesterday ----------------------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_swap_yesterday.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Swap Space - ";       # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_swap_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"swap",$DEBUG);      # Show Graph Just Generated
            break;
           
        case "network_etha":
            # Generate Big First Network Interface Usage Graphic for Yesterday ---------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_neta_yesterday.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 1st Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"a");
            display_graph ($WHOST_NAME,$WHOST_DESC,"neta",$DEBUG);      # Show Graph Just Generated
            break;

        case "network_ethb":
            # Generate Big Second Network Interface Usage Graphic for Yesterday --------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netb_yesterday.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 2nd Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"b");
            display_graph ($WHOST_NAME,$WHOST_DESC,"netb",$DEBUG);      # Show Graph Just Generated
            break;

        case "network_ethc":
            # Generate Big Third Network Interface Usage Graphic for Yesterday ---------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netc_yesterday.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 3th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"c");
            display_graph ($WHOST_NAME,$WHOST_DESC,"netc",$DEBUG);      # Show Graph Just Generated
            break;

        case "network_ethd":
            # Generate Big Fourth Network Interface Usage Graphic for Yesterday --------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netd_yesterday.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 4th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"d");
            display_graph ($WHOST_NAME,$WHOST_DESC,"netd",$DEBUG);      # Show Graph Just Generated
            break;

        case "mem_distribution":
            # Generate Big Memory Distribution Usage Graphic for Yesterday -------------------------
            $START   = "$HRS_START $YESTERDAY" ;                        # Yesterday at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memdist_yesterday.png"; # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Mem Distribution - "; # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_memdist_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"memdist",$DEBUG);   # Show Graph Just Generated
            break;
    }
    return ;
}


# ==================================================================================================
#                    Display Performance Graphic Page For the Host just Generated 
# ==================================================================================================
function display_graph ($WHOST,$WDESC,$WTYPE,$DEBUG)
{
    $IMGDIR = "/tmp/perf" ;                                             # Dir. where created PNG are
    $IMG_DAY   = "${IMGDIR}/${WHOST}_${WTYPE}_yesterday.png";           # Path to PNG File

    # Read the netdev.txt file to get the interface Name of each of possible 4 Network Interfaces
    $netdev="" ; $netdev2=""; $netdev3=""; $netdev4="";                 # Clear Net interface name 
    $netcount  = 0;                                                     # Network  Interface Counter
    $NETDEV = SADM_WWW_RRD_DIR . "/${WHOST}/" . SADM_WWW_NETDEV ;       # Server Path to netdev.txt
    $handle = fopen($NETDEV, "r");                                      # Open netdev.txt of server
    if ($handle) {                                                      # If Successfully Open
        while (($line = fgets($handle)) !== false) {                    # If Still Line to read
            $netcount++;                                                # Increase Line Number
            if ($netcount == 1) { $netdev1 = $line ; }                  # Get Name of Net interface1
            if ($netcount == 2) { $netdev2 = $line ; }                  # Get Name of Net interface2
            if ($netcount == 3) { $netdev3 = $line ; }                  # Get Name of Net interface3
            if ($netcount == 4) { $netdev4 = $line ; }                  # Get Name of Net interface4
        }
    }
    fclose($handle);                                                    # Close Network DevName file

    # Under Debug, Show Name of device file, Name of each Network Interface and Number of interfaces
    if ($DEBUG) { 
        echo "\n<br>Netdev filename is $NETDEV";
        echo "\n<br>dev1= $netdev1 \n<br>dev2= $netdev2 \n<br>dev3= $netdev3 \n<br>dev4= $netdev4";
        echo "\n<br>NetCount is $netcount";
    }

    # Set Performance Graph Title based on the WTYPE received
    switch ($WTYPE) {
        case "cpu":                                                     
            $WTITLE = "CPU usage";                                      # Set Graph Title
            break;
        case "runqueue":                                                 
            $WTITLE = "Run Queue usage";                                # Set Graph Title
            break;
        case "memory":                                                   
            $WTITLE = "Memory usage";                                   # Set Graph Title
            break;
        case "memdist":                                        
            $WTITLE = "Memory Distribution";                            # Set Graph Title
            break;
        case "diskio":                                                  
            $WTITLE = "Disks I/O (read/write)";                         # Set Graph Title
            break;
        case "paging":                                              
            $WTITLE = "Pages in/out";                                   # Set Graph Title
            break;
        case "swap":                                              
            $WTITLE = "Swap Space usage";                               # Set Graph Title
            break;
        case "neta":                                            
            $WTITLE = "1st Network Interface" ;                         # Set Default Graph Title
            if ($netdev1 != "") $WTITLE = "Network Interface $netdev1"; # Include DevDev Name 
            break;
        case "netb":                                            
            $WTITLE = "2nd Network Interface";                          # Set Graph Title
            if ($netdev2 != "") $WTITLE = "Network Interface $netdev2"; # Include DevDev Name 
            break;
        case "netc":                                            
            $WTITLE = "3rd Network Interface";                          # Set Graph Title
            if ($netdev3 != "") $WTITLE = "Network Interface $netdev3"; # Include DevDev Name 
            break;
        case "netd":                                            
            $WTITLE = "4th Network Interface";                          # Set Graph Title
            if ($netdev4 != "") $WTITLE = "Network Interface $netdev4"; # Include DevDev Name 
            break;
        default :                                                       # Default - if no good type
            $WTITLE = "Invalid Graph Type Requested ($WTYPE)";          # Invalid WTYPE Received
    }

    # If No Network Interface, return to caller, no need to display empty graph
    if (($WTYPE == "neta") and ($netdev1 == "")) { return ; }           # No Net Interface 1 = Done 
    if (($WTYPE == "netb") and ($netdev2 == "")) { return ; }           # No Net Interface 2 = Done 
    if (($WTYPE == "netc") and ($netdev3 == "")) { return ; }           # No Net Interface 3 = Done 
    if (($WTYPE == "netd") and ($netdev4 == "")) { return ; }           # No Net Interface 4 = Done

    # Display Title of the Graph
    $FONTCOLOR = "Green";                                               # Heading Color
    echo "<center><h2>${WTITLE}</strong></center>";                     # Display Graph Title

    # Table definition for the Yesterday Graph
    echo "\n\n<table style='width:80%' align=center border=0 cellspacing=0>\n";

    # Display Yesterday Graph
    echo "\n<tr>";
    echo "\n<td colspan=3><img src=${IMG_DAY}></td>";
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
        $HOSTDESC     = $row['srv_desc'];                               # Get Host Description
        $HOST_OS      = $row['srv_ostype'];                             # Get O/S Type linux/aix
        $HOST_DOMAIN  = $row['srv_domain'];                             # Get Server Domain

        echo "<center><strong><H2>";
        echo "Performance graph of server '$HOSTNAME' for Yesterday";
        echo "</strong></H2></center><br>";
    
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"cpu"          ,$HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"runqueue"     ,$HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"memory"       ,$HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"diskio"       ,$HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"page_inout"   ,$HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"swap_space"   ,$HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"network_etha", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"network_ethb", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"network_ethc", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        create_standard_graphic ($HOSTNAME,$HOSTDESC,"network_ethd", $HOST_OS,SADM_RRDTOOL,$DEBUG);
        if ($HOST_OS == "aix") {
            create_standard_graphic ($HOSTNAME,$HOSTDESC,"mem_distribution",$HOST_OS,SADM_RRDTOOL,$DEBUG);
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

    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>
