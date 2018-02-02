<?php
# ================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_perf_adhoc_all.php
#   Version  :  1.0
#   Date     :  25 January 2018
#   Requires :  php
#   Synopsis :  Show CPU Performance Graphics of All Server(s) for Yesterday
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
#   2018_02_01 JDuplessis
#       V 1.0 Initial Version
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
    $RRD_FILE   = SADM_WWW_RRD_DIR ."/${WHOST}/${WHOST}.rrd"; # Where Host RRD Is
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
        echo "\n<br>PERIOD     = $WPERIOD";
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

    if ($WPERIOD == "yesterday")  { $START = "$HRS_START $YESTERDAY"  ;} 
    if ($WPERIOD == "last2days")  { $START = "$HRS_START $YESTERDAY2" ;} 
    if ($WPERIOD == "week")       { $START = "$HRS_START $LASTWEEK"   ;} 
    if ($WPERIOD == "month")      { $START = "$HRS_START $LASTMONTH"   ;} 
    if ($WPERIOD == "year")       { $START = "$HRS_START $LASTYEAR"   ;} 
    if ($WPERIOD == "last2years") { $START = "$HRS_START $LAST2YEAR"  ;} 
    $END   = "$HRS_END $YESTERDAY";                                     # End Yesterday at 23:00
    $GFILE = "${PNGDIR}/${WHOST}_${WTYPE}_${WPERIOD}_all.png";          # Name of png to generate
    $GTITLE = ucfirst(${WHOST})." ${WTYPE} ${WPERIOD}";                 # Set Graph Title 
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
#                     Display server graphic type selected for the period selected 
# ================================================================================================
function display_png ($WHOST,$WTYPE,$WPERIOD,$WCOUNT,$DEBUG)
{
    $IMGDIR = "/tmp/perf" ;                                         # png Dir. for Web Server
    $WEBFILE = "${IMGDIR}/${WHOST}_${WTYPE}_${WPERIOD}_all.png";
    $OSFILE  = SADM_WWW_DIR . "$WEBFILE";
    $URL     = "/view/perf/sadm_server_perf.php";                        # Common URL Start Part 

    echo "\n<td>";
    if (file_exists($OSFILE)) {
        echo "<a href=${URL}?host=$WHOST><img src=${WEBFILE}></a>";
    }else{
        echo "<center><a href=${URL}?host=$WHOST>";
        echo "No data for $OSFILE  $WPERIOD - Server '${WHOST}'";
        echo "</a></center>";
    }
    echo "</td>";
    if ( ($WCOUNT % 3) == 0 ) { echo "</tr><tr>\n" ;  }
    return ;
}
	

 
// ================================================================================================
//                                    Main Program Start Here
// ================================================================================================

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
    if (isset($_POST['wtype']) ) { 
        $WTYPE = $_POST['wtype'];
        switch ($WTYPE) {
            case "cpu"        : break;
            case "runqueue"   : break;
            case "memory"     : break;
            case "diskio"     : break;
            case "memdist"    : break;
            case "page_inout" : break;
            case "swap_space" : break;
            case "neta"       : break;
            case "netb"       : break;
            case "netc"       : break;
            case "netd"       : break;
            default:
                echo "The WTYPE parameter received is invalid ($WTYPE)" ;
                exit ;
        }
    }else{
        echo "The WTYPE parameter was not received ($WTYPE)" ;
        exit ;
    }

    # Valid the Graph Period that is requested
    if (isset($_POST['wperiod']) ) { 
        $WPERIOD = $_POST['wperiod'];
        switch ($WPERIOD) {
            case "yesterday"  :
                break;
            case "last2days" :
                break;
            case "week" :
                break;
            case "month"  :
                break;
            case "year" :
                break;
            case "last2years" :
                break;
            default:
                echo "The Period received is invalid ($WPERIOD)" ;
                exit ;
        }
    }else{
        echo "The Period received is invalid ($WPERIOD)" ;
        exit ;
    }


    # Valid the Graph Period that is requested
    if (isset($_POST['wcat']) ) { 
        $WCAT = $_POST['wcat'];
    }else{
        echo "The Category received is invalid ($WCAT)" ;
        exit ;
    }

    
    # Validate the Server(s) Requested
    if (isset($_POST['wservers']) ) { 
        $WSERVERS = $_POST['wservers'];
        $sql="SELECT * FROM server " ;
	    switch ($WSERVERS) {
		case "all_linux"  :
            $sql .= "where srv_ostype='linux' and srv_active=1 order by srv_name";
            break;
        case "all_aix" :
            $sql .= "where srv_ostype='aix' and srv_active=1 order by srv_name";
	        break;
		case "all_servers"  :
	        $sql .= "where srv_active=1 order by srv_name";
	        break;
		case "all_linux_prod" :
        $sql .= "where srv_ostype=='linux' and srv_cat='Prod' and server_active=1 order by server_name";
        break;
        case "all_linux_dev"  :
            $sql .= "where srv_ostype=='linux' and srv_cat='Dev' and server_active=1 order by server_name";
	        break;
		case "all_aix_prod" :
            $sql .= "where srv_ostype=='aix' and srv_cat='Prod' and server_active=1 order by server_name";
            break;
        case "all_aix_dev"  :
            $sql .= "where srv_ostype=='aix' and srv_cat='Prod' and server_active=1 order by server_name";
            break;
        default:
		    echo "The WOS received is invalid ($WOS)" ;
		    exit ;
        }
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Sql Failed \n";                                # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_alert ($err_msg1 . $err_msg2 . $err_msg3 . $err_msg4); # Display Msg. Box for User
            exit;                                                       # Exit - Should not occurs
        }
	}else{
		echo "The WOS received is invalid ($WOS)" ;
		exit ;
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

