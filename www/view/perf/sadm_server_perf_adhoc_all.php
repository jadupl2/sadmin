<?php
# ================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_perf_adhoc_all.php
#   Version  :  1.0
#   Date     :  25 January 2018
#   Requires :  php
#   Synopsis :  Show Performance Graphics of ALL Server(s) of certain Catagory.
#               Usefull to look at all servers on one page & spot problem on some server.
#
#   Copyright (C) 2018 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
#   2018_02_01 JDuplessis
#       v1.0 Initial Version
#   2018_02_02 JDuplessis
#       v1.1 First Working version
#   2018_02_03 JDuplessis
#       v1.2 Change Titles and Bug Fixes
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
$SVER  = "1.2a" ;                                                        # Current version number


# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
# HOSTNAME  = Name of Host,                 WHOST_DESC  = Host Desciption from MySql Database 
# WTYPE     = cpu,runqueue,diskio,memory,page_inout,swap_space,network_eth[a,b,c]
# WPERIOD   = yesterday,last2days,week,month,year or last2years
# WOS       = linux,aix (lowercase allways) RRDTOOL     = Path to rrdtool       DEBUG = True,False
# ==================================================================================================
function gen_png($WHOST,$WHOST_DESC,$WTYPE,$WPERIOD,$WOS,$RRDTOOL,$DEBUG)
{
    $RRD_FILE   = SADM_WWW_RRD_DIR ."/${WHOST}/${WHOST}.rrd";           # Build Name of RRD to use
    $PNGDIR     = SADM_WWW_TMP_DIR . "/perf" ;                          # Where PNG file generated
    $IMGDIR     = "/tmp/perf" ;                                         # PNG Dir. for Web Server
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

    # Set Start Date and Time Based on the Period selected
    if ($WPERIOD == "yesterday")  { $START = "$HRS_START $YESTERDAY" ;} # Start Yesterday Date/Time 
    if ($WPERIOD == "last2days")  { $START = "$HRS_START $YESTERDAY2";} # Start 2days ago Date/Time
    if ($WPERIOD == "week")       { $START = "$HRS_START $LASTWEEK"  ;} # Start 7days ago Date/Time
    if ($WPERIOD == "month")      { $START = "$HRS_START $LASTMONTH" ;} # Start 31Days ago Date/Time
    if ($WPERIOD == "year")       { $START = "$HRS_START $LASTYEAR"  ;} # Start 365Days ago
    if ($WPERIOD == "last2years") { $START = "$HRS_START $LAST2YEAR" ;} # Start 730Days ago 
    
    # Set End Time and Date, PNG name and Graph Title
    $END   = "$HRS_END $YESTERDAY";                                     # End Yesterday at 23:00
    $GFILE = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}_all.png";          # Name of PNG to generate

    # Set the graph Title
    if ($WPERIOD == "yesterday")  { $GTITLE2 = "$YESTERDAY"    ;}       # Set Yesterday Title2
    if ($WPERIOD == "last2days")  { $GTITLE2 = "Last 2 days"   ;}       # Set Last 2Days Title2
    if ($WPERIOD == "week")       { $GTITLE2 = "Last 7 days"   ;}       # Set Last 7Days Title2
    if ($WPERIOD == "month")      { $GTITLE2 = "Last 31 days"  ;}       # Set Last 31Days Title2
    if ($WPERIOD == "year")       { $GTITLE2 = "Last 365 days" ;}       # Set Last 365Days Title2
    if ($WPERIOD == "last2years") { $GTITLE2 = "Last 730 days" ;}       # Set Last 730Days Title2
    $GTITLE = ${WHOST} ." ${WTYPE} ${GTITLE2}";                         # Set Graph Title + Title2

    # Generate the PNG graph based on the type of ressource selected
    switch ($WTYPE) {
        case "cpu":                                                     # Generate CPU Graphic  
            create_cpu_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            break;

            case "runqueue":
            create_runq_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            break;

        case "memory":
            create_mem_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            break;

        case "diskio":
            create_disk_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);  
            break;

        case "page_inout":
            create_paging_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            break;
           
        case "swap_space":
            create_swap_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            break;
           
        case "network_etha":
            create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"a");
        break;

        case "network_ethb":
            create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"b");
            break;

        case "network_ethc":
            create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"c");
            break;

        case "network_ethd":
            create_net_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"d");
            break;

        case "mem_distribution":
            create_memdist_graph($WHOST,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            break;
    }
        return ;
}

# ================================================================================================
#                     Display Server Graphic type selected for the period selected 
# ================================================================================================
function display_png ($WHOST,$WTYPE,$WPERIOD,$WCOUNT,$DEBUG) {
    $IMGDIR  = "/tmp/perf" ;                                            # PNG Dir. for Web Server
    $WEBFILE = "${IMGDIR}/${WHOST}_${WTYPE}_${WPERIOD}_all.png";        # PNG File Path for Web Srv
    $OSFILE  = SADM_WWW_DIR . "$WEBFILE";                               # PNG File Path for O/S
    $URL     = "/view/perf/sadm_server_perf.php";                       # URL to View Yesterday PNG

    # Display PNG Based on Parameters received
    echo "\n<td>";                                                      # Start Table Data Line
    if (file_exists($OSFILE)) {                                         # If PNG file exist on O/S
        echo "<a href=${URL}?host=$WHOST><img src=${WEBFILE}></a>";     # Show PNG with Link to Yest
    }else{                                                              # If file not there
        echo "<center><a href=${URL}?host=$WHOST>";                     # Center Msg to User
        echo "No data for $WPERIOD - Server '${WHOST}'";                # Show Host & Period instead
        echo "</a></center>";                                           # Finish File not found msg
    }
    echo "</td>";                                                       # End Table Data Line
    if ( ($WCOUNT % 3) == 0 ) { echo "</tr><tr>\n" ;  }                 # Change row, 3 PNG per line
    return ;                                                            # Return to caller
}
	

 
# ==================================================================================================
#                                     Main Program Start Here
# ==================================================================================================

    # Show Debugging Information
    if ($DEBUG) {                                                       # In Debug Show Param. Rcv
        echo "\n<br>Parameters Received";                               # Show What is display below
        echo "\n<br>Graph Type   = " . $_POST['wtype'];                 # Show Graph type received
        echo "\n<br>Graph Period = " . $_POST['wperiod'];               # Show Graph Period Rcv
        echo "\n<br>Servers      = " . $_POST['wservers'];              # Show Servers Opt Received
        echo "\n<br>Category     = " . $_POST['wcat'];                  # Show Category Opt Recv.
        echo "\n<br>";                                                  # Blank Line
    }

    # Validate the type of Graph Requested ---------------------------------------------------------
    if (isset($_POST['wtype']) ) {                                      # If received type of Graph
        $WTYPE = $_POST['wtype'];                                       # Save type of Graph
        switch ($WTYPE) {                                               # Start Type Validation
            case "cpu"        : break;                                  # CPU Graph
            case "runqueue"   : break;                                  # Run Queue Graph
            case "memory"     : break;                                  # Memory Graph
            case "diskio"     : break;                                  # Disk I/O Graph
            case "memdist"    : break;                                  # Aix Memory Distribution
            case "page_inout" : break;                                  # Paging - Page In, Page out
            case "swap_space" : break;                                  # Swap Space Usage
            case "neta"       : break;                                  # 1st Network Interface
            case "netb"       : break;                                  # 2nd Network Interface
            case "netc"       : break;                                  # 3rd Network Interface
            case "netd"       : break;                                  # 4th Network Interface
            default:                                                    # If not a valid Graph Type
                echo "Graph type received is invalid ($WTYPE)";         # Inform User Msg
                exit ;                                                  # End of the page 
        }
    }else{                                                              # If no Graph Type Received
        echo "The WTYPE parameter was not set" ;                        # Inform User Message
        exit ;                                                          # End of page
    }

    # Valid the Graph Period that is requested -----------------------------------------------------
    if (isset($_POST['wperiod']) ) {                                    # if the period is defined
        $WPERIOD = $_POST['wperiod'];                                   # Save the graph Period
        switch ($WPERIOD) {                                             # Validate the period
            case "yesterday"    : break;                                # Graph for Yesterday
            case "last2days"    : break;                                # Graph of last 2 days
            case "week"         : break;                                # Graph for last 7 days
            case "month"        : break;                                # Graph for last 31 days
            case "year"         : break;                                # Graph for last 365 Days
            case "last2years"   : break;                                # Graph for last 730 Days
            default:                                                    # Graph selected not valid
                echo "The Period received is invalid ($WPERIOD)" ;      # Advise User
                exit ;                                                  # End of page
        }
    }else{                                                              # If no period was set
        echo "The period parameter was not set" ;                       # Inform user message
        exit ;                                                          # End of page
    }

    # Validate the server category that is requested -----------------------------------------------
    if (isset($_POST['wcat']) ) {                                       # if the Category is defined
        $WCAT = $_POST['wcat'];                                         # Save Category Option
    }else{                                                              # No Category Option defined
        echo "The Category parameter was not set" ;                     # Inform User message
        exit ;                                                          # End of page
    }


    # Validate if the server option was set --------------------------------------------------------
    if (isset($_POST['wservers']) ) {                                   # if Server Opt is defined
        $WSERVERS = $_POST['wservers'];                                 # Save Server Option
    }else{                                                              # No Server Option defined
        echo "The Server parameter was not set" ;                       # Inform User message
        exit ;                                                          # End of page
    }

    # Construct the select statement base on the parameters received -------------------------------
    $sql="SELECT * FROM server " ;                                      # Begin construct Select St.
    switch ($WSERVERS) {                                                # Based on Server option
        
        case "all_linux"  :                                             # If all Linux Servers
            if ($WCAT == "all_cat") {                                   # And All Categories
                $sql .= "where srv_ostype='linux'";                     # Select Linux O/S
            }else{                                                      # If not all categories
                $sql .= "where srv_ostype='linux' and srv_cat='$WCAT'"; # Linux O/S & Cat. Selected
            }
            $sql .= " and srv_active=1 and srv_graph=1 ";               # Active & Graph Perf=Yes
            $sql .= " order by srv_name";                               # Active Srv/Order by name
            break;                                                      # Ok Select Stat. completed

        case "all_aix" :                                                # If all Aix Servers
            if ($WCAT == "all_cat") {                                   # And All Categories
                $sql .= "where srv_ostype='aix'";                       # Select Aix O/S
            }else{                                                      # If not all categories
                $sql .= "where srv_ostype='aix' and srv_cat='$WCAT'";   # Aix O/S & Cat. Selected
            }
            $sql .= " and srv_active=1 and srv_graph=1 ";               # Active & Graph Perf=Yes
            $sql .= " order by srv_name";                               # Active Srv/Order by name
            break;                                                      # Ok Select Stat. completed   

        case "all_servers"  :
            if ($WCAT == "all_cat") {                                   # And All Categories
                $sql .= "where srv_active=1 and srv_graph=1 ";          # Active & Graph Perf=Yes
                $sql .= " order by srv_name";                           # Active Srv/Order by name
            }else{                                                      # If not all categories
                $sql .= "where srv_active=1 and srv_graph=1 ";          # Active & Graph Perf=Yes
                $sql .= " and srv_cat='$WCAT'";                         # Only Cat. Selected
                $sql .= " order by srv_name";                           # Order by server name
            }
            break;                                                      # Ok Select Stat. completed   

        default:
            $sql .= "where srv_active=1 and srv_name='$WSERVER' " ;     # Only Server selected
            if ($WCAT == "all_cat") {                                   # And All Categories
                $sql .= " order by srv_name";                           # Order by server name
            }else{                                                      # If not all categories
                $sql .= "and srv_cat='$WCAT'";                          # Only Cat. Selected
                $sql .= " order by srv_name";                           # Order by server name
            }
            break;                                                      # Ok Select Stat. completed   
    }

    # Execute SQL
    if ( ! $result=mysqli_query($con,$sql)) {                           # Execute SQL Select
        $err_line = (__LINE__ -1) ;                                     # Error on preceeding line
        $err_msg1 = "Sql Failed \n";                                    # Row was not found Msg.
        $err_msg2 = strval(mysqli_errno($con)) . ") " ;                 # Insert Err No. in Message
        $err_msg3 = mysqli_error($con) . "\nAt line "  ;                # Insert Err Msg and Line No 
        $err_msg4 = $err_line . " in " . basename(__FILE__);            # Insert Filename in Mess.
        sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4);     # Display Msg. Box for User
        exit;                                                            # Exit - Should not occurs
    }

    # Display Standard Page Heading ----------------------------------------------------------------
    display_std_heading("NotHome","Graph Performance for all servers","","",$SVER); 

    # Display This page heading --------------------------------------------------------------------
    echo "<center><H1>";
    echo ucfirst($WTYPE) . " Performance Graph of " . str_replace("_"," ",$WSERVERS);
    echo " for " . ucfirst($WPERIOD) ;
    echo "</H1></center><br>";

    # Generate and Display Graph for all servers selected from the SQL Query -----------------------
    echo "\n<table style='width:80%' align=center border=1 cellspacing=1>";
    echo "\n<tr>" ;                                                     # Initial Table Row
    $COUNT=0;                                                           # Graph per line count
    while ($row = mysqli_fetch_assoc($result)) {                        # Gather Result from Query
          $COUNT+=1;                                                    # Increment Graph counter
          $HOSTNAME = $row['srv_name'] ;                                # Save Server Name
		  $HOSTDESC = $row['srv_desc'] ;                                # Save Server Description
          $HOSTOS   = $row['srv_ostype'];                               # Save O/S name aix/linux
          gen_png ($HOSTNAME, $HOSTDESC, $WTYPE, $WPERIOD, $HOSTOS,SADM_RRDTOOL,$DEBUG); # Gen PNG
          display_png ($HOSTNAME,$WTYPE,$WPERIOD,$COUNT,$DEBUG);        # Show PNG Just Generated

        }
    echo "\n</tr>" ;                                                    # End Last Table row
    echo "\n</table>\n<br><br>";                                        # End of table

    echo "\n</div> <!-- End of SimpleTable          -->" ;              # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>

