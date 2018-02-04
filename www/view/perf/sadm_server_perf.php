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
#   2018_01_30 JDuplessis
#       V 1.3 First Working Version
#   2018_01_31 JDuplessis
#       V 1.4 Restructure & Enhance Look & Create Library to used by others pages
#   2018_02_02 JDuplessis
#       V 1.5 Added message when cannot produce graph because no data in rrd available
#   2018_02_03 JDuplessis
#       V1.6 Comments Added 
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
$DEBUG  = False  ;                                                      # Debug Activated True/False
$SVER   = "1.6" ;                                                       # Current version number






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

    switch ($WTYPE) {
        case "cpu":                                                     # Generate CPU Graphic
            # Generate Big CPU Graphic for the last 2 Days -----------------------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_cpu_last2days.png";     # Name of png to generate
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
            display_graph ($WHOST_NAME,$WHOST_DESC,"cpu",$DEBUG);       # Show Graph Just Generated
            break;

        case "runqueue":
            # Generate Big RunQueue Graphic for the last 2 Days ------------------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_runqueue_last2days.png";# Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - RunQueue - ";         # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_runq_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Small CPU Graphic for the last 7 Days ---------------------------------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_runqueue_week.png";     # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - RunQueue - ";         # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_runq_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 31 Days --------------------------------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_runqueue_month.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - RunQueue - ";         # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_runq_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 365 Days -------------------------------------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_runqueue_year.png";     # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - RunQueue - ";         # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_runq_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);  
            display_graph ($WHOST_NAME,$WHOST_DESC,"runqueue",$DEBUG);  # Show Graph Just Generated
            break;

        case "memory":
            # Generate Big Memory Graphic for the last 2 Days ------------------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memory_last2days.png";  # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Memory - ";           # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_mem_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Small CPU Graphic for the last 7 Days ---------------------------------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memory_week.png";       # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Memory - ";           # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_mem_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 31 Days --------------------------------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memory_month.png";      # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Memory - ";           # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_mem_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small CPU Graphic for the last 365 Days -------------------------------------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memory_year.png";       # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Memory - ";           # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_mem_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);  
            display_graph ($WHOST_NAME,$WHOST_DESC,"memory",$DEBUG);    # Show Graph Just Generated
            break;

        case "diskio":
            # Generate Big Disks I/O Graphic for the last 2 Days -----------------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_diskio_last2days.png";  # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Disks I/O - ";        # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_disk_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Small Disks I/O Graphic for the last 7 Days ---------------------------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_diskio_week.png";       # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Disks I/O - ";        # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_disk_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small Disks I/O Graphic for the last 31 Days --------------------------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_diskio_month.png";      # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Disks I/O - ";        # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_disk_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small Disks I/O Graphic for the last 365 Days -------------------------------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_diskio_year.png";       # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Disks I/O - ";        # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_disk_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);  
            display_graph ($WHOST_NAME,$WHOST_DESC,"diskio",$DEBUG);    # Show Graph Just Generated
            break;

        case "page_inout":
            # Generate Big Paging Activity Graphic for the last 2 Days -----------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_paging_last2days.png";  # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Paging Act. - ";      # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_paging_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Small Paging Activity Graphic for the last 7 Days ---------------------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_paging_week.png";       # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Paging Act. - ";      # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_paging_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small Paging Activity Graphic for the last 31 Days --------------------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_paging_month.png";      # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Paging Act. - ";      # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_paging_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small Paging Activity Graphic for the last 365 Days -------------------------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_paging_year.png";       # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Paging Act. - ";      # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_paging_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"paging",$DEBUG);    # Show Graph Just Generated
            break;
           
        case "swap_space":
            # Generate Big Swap Space Usage Graphic for the last 2 Days ----------------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_swap_last2days.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Swap Space - ";       # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_swap_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Small Swap Space Usage Graphic for the last 7 Days --------------------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_swap_week.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Swap Space - ";       # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_swap_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small Swap Space Usage Graphic for the last 31 Days -------------------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_swap_month.png";        # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Swap Space - ";       # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_swap_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Small Swap Space Usage Graphic for the last 365 Days ------------------------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_swap_year.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Swap Space - ";       # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_swap_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
            display_graph ($WHOST_NAME,$WHOST_DESC,"swap",$DEBUG);      # Show Graph Just Generated
            break;
           
        case "network_etha":
            # Generate Big First Network Interface Usage Graphic for the last 2 Days ---------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_neta_last2days.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 1st Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"a");

            # Generate Small First Network Interface Usage Graphic for the last 7 Days -------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_neta_week.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 1st Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"a");

            # Generate Small First Network Interface Usage Graphic for the last 31 Days ------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_neta_month.png";        # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 1st Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"a");

            # Generate Small First Network Interface Usage Graphic for the last 365 Days -----------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_neta_year.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 1st Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"a");
            display_graph ($WHOST_NAME,$WHOST_DESC,"neta",$DEBUG);      # Show Graph Just Generated
            break;

        case "network_ethb":
            # Generate Big Second Network Interface Usage Graphic for the last 2 Days ---------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netb_last2days.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 2nd Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"b");

            # Generate Small Second Network Interface Usage Graphic for the last 7 Days -------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netb_week.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 2nd Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"b");

            # Generate Small Second Network Interface Usage Graphic for the last 31 Days ------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netb_month.png";        # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 2nd Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"b");

            # Generate Small Second Network Interface Usage Graphic for the last 365 Days -----------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netb_year.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 2nd Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"b");
            display_graph ($WHOST_NAME,$WHOST_DESC,"netb",$DEBUG);      # Show Graph Just Generated
            break;

        case "network_ethc":
            # Generate Big Third Network Interface Usage Graphic for the last 2 Days ---------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netc_last2days.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 3th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"c");

            # Generate Small Third Network Interface Usage Graphic for the last 7 Days -------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netc_week.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 3th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"c");

            # Generate Small Third Network Interface Usage Graphic for the last 31 Days ------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netc_month.png";        # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 3th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"c");

            # Generate Small Third Network Interface Usage Graphic for the last 365 Days -----------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netc_year.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 3th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"c");
            display_graph ($WHOST_NAME,$WHOST_DESC,"netc",$DEBUG);      # Show Graph Just Generated
            break;

            case "network_ethd":
            # Generate Big Fourth Network Interface Usage Graphic for the last 2 Days ---------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netd_last2days.png";    # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 4th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG,"d");

            # Generate Small Fourth Network Interface Usage Graphic for the last 7 Days -------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netd_week.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 4th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"d");

            # Generate Small Fourth Network Interface Usage Graphic for the last 31 Days ------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netd_month.png";        # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 4th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"d");

            # Generate Small Fourth Network Interface Usage Graphic for the last 365 Days -----------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_netd_year.png";         # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - 4th Network Dev - ";  # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_net_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG,"d");
            display_graph ($WHOST_NAME,$WHOST_DESC,"netd",$DEBUG);      # Show Graph Just Generated
            break;

        case "mem_distribution":
            # Generate Big Memory Distribution Usage Graphic for the last 2 Days --------------------
            $START   = "$HRS_START $YESTERDAY2" ;                       # Start 2 days ago at 00:00
            $END     = "$HRS_END $YESTERDAY";                           # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memdist_last2days.png"; # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Mem Distribution - "; # Set Graph Title Part I
            $GTITLE .= "From $START to $END" ;                          # Set Graph Title Part II
            create_memdist_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"B",$DEBUG);

            # Generate Big Memory Distribution Usage Graphic for the last 7 Days --------------------
            $START   = "$HRS_START $LASTWEEK" ;                         # Start 7 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memdist_week.png";      # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Mem Distribution - "; # Set Graph Title Part I
            $GTITLE .= "Last 7 Days" ;                                  # Set Graph Title Part II
            create_memdist_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Big Memory Distribution Usage Graphic for the last 31 Days -------------------
            $START   = "$HRS_START $LASTMONTH" ;                        # Start 31 days ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memdist_month.png";     # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Mem Distribution - "; # Set Graph Title Part I
            $GTITLE .= "Last 4 weeks" ;                                 # Set Graph Title Part II
            create_memdist_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);

            # Generate Big Memory Distribution Usage Graphic for the last 365 Days ------------------
            $START   = "$HRS_START $LASTYEAR" ;                         # Start 365 day ago at 00:00
            $END     = "$HRS_END   $YESTERDAY";                         # End Yesterday at 23:00
            $GFILE   = "${PNGDIR}/${WHOST_NAME}_memdist_year.png";      # Name of png to generate
            $GTITLE  = ucfirst(${WHOST_NAME})." - Mem Distribution - "; # Set Graph Title Part I
            $GTITLE .= "Last 365 Days" ;                                # Set Graph Title Part II
            create_memdist_graph($WHOST_NAME,$RRDTOOL,$RRD_FILE,$START,$END,$GTITLE,$GFILE,"S",$DEBUG);
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
    $OSDIR  = SADM_WWW_DIR . "$IMGDIR";

    # Web Server Path to PNG Graph Image
    $IMG_DAY   = "${IMGDIR}/${WHOST}_${WTYPE}_last2days.png";           # Last 2 Days PNG Path 
    $IMG_WEEK  = "${IMGDIR}/${WHOST}_${WTYPE}_week.png";                # Last 7 Days PNG Path
    $IMG_MTH   = "${IMGDIR}/${WHOST}_${WTYPE}_month.png";               # Last 31 Days PNG Path
    $IMG_YEAR  = "${IMGDIR}/${WHOST}_${WTYPE}_year.png";                # Last 365 Days PNG Path

    # O/S Path to PNG Graph Image
    $IMG_OSDAY  = "${OSDIR}/${WHOST}_${WTYPE}_last2days.png";           # Last 2 Days PNG O/S Path 
    $IMG_OSWEEK = "${OSDIR}/${WHOST}_${WTYPE}_week.png";                # Last 7 Days PNG O/S Path
    $IMG_OSMTH  = "${OSDIR}/${WHOST}_${WTYPE}_month.png";               # Last 31 Days PNG O/S Path
    $IMG_OSYEAR = "${OSDIR}/${WHOST}_${WTYPE}_year.png";                # Last 365 Days PNG O/S Path

    # Web Page URL if User click on one of the PNG Graph
    $URL1      = "/view/perf/sadm_server_perf_";                        # Common URL Start Part 
    $URL_DAY   = $URL1 . "yesterday.php?host=$WHOST&$WTYPE";            # URL For Daily Display
    $URL_WEEK  = $URL1 . "week.php?host=$WHOST&$WTYPE";                 # URL for Week Display
    $URL_MTH   = $URL1 . "month.php?host=$WHOST&$WTYPE";                # URL for Month Display
    $URL_YEAR  = $URL1 . "2year.php?host=$WHOST&$WTYPE";                # URL for Year Display

    # When cursor move over the graph, Message below will be displyed
    $ALT_DAY   = "View Yesterday Graph Only";                           # Day Message when on Graph
    $ALT_WEEK  = "Larger view of last week";                            # Week Message when on Graph
    $ALT_MTH   = "Larger view of last month";                           # Mth Message when on Graph
    $ALT_YEAR  = "Larger View last years";                              # Year Message when on Graph

    # Read the netdev.txt file to get the interface Name of each of possible 4 Network Interfaces
    $netdev1="" ; $netdev2=""; $netdev3=""; $netdev4="";                # Clear Net interface name 
    $netcount  = 0;                                                     # Network  Interface Counter
    $NETDEV = SADM_WWW_RRD_DIR . "/${WHOST}/" . SADM_WWW_NETDEV ;       # Server Path to netdev.txt
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
    }else{
        $netdev1 = "1st" ;                                              # Set Name of Net interface1
        $netdev2 = "2nd" ;                                              # Set Name of Net interface2
        $netdev3 = "3rd" ;                                              # Set Name of Net interface3
        $netdev4 = "4th" ;                                              # Set Name of Net interface4
    }

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

    # Table definition for the 4 graph (Yesterday, Last 7 Days, Last 4 weeks, Last 365 Days)
    echo "\n\n<table style='width:80%' align=center border=0 cellspacing=0>\n";

    # Display Big Graph for last 2 days 
    echo "\n<tr>";
    echo "\n<td colspan=3>";
    if (file_exists($IMG_OSDAY)) {
        echo "<A HREF='${URL_DAY}'> <img src=${IMG_DAY} alt=\"${ALT_DAY}\"></a>";
    }else{
        echo "<center>No $WTITLE data for last 2 days </center>";
    }
    echo "</td>";
    echo "\n</tr>" ;

    # Display Small Graph for last week
    echo "\n\n<tr>";
    echo "\n<td>";
    if (file_exists($IMG_OSWEEK)) {
        echo "<A HREF='${URL_WEEK}'><img src=${IMG_WEEK} alt=\"${ALT_WEEK}\"></a></td>";
    }else{
        echo "<center>No $WTITLE for last week</center>";
    }
    echo "</td>";

    # Display Small Graph for last month
    echo "\n<td>";
    if (file_exists($IMG_OSMTH)) {
        echo "<A HREF='${URL_MTH}'><img src=${IMG_MTH} alt=\"${ALT_MTH}\"></a></td>";
    }else{
        echo "<center>No $WTITLE for last month</center>";
    }
    echo "</td>";

    # Display Small Graph for last month
    echo "\n<td>";
    if (file_exists($IMG_OSYEAR)) {
        echo "<A HREF='${URL_YEAR}'><img src=${IMG_YEAR} alt=\"${ALT_YEAR}\"></a></td>";
    }else{
        echo "<center>No $WTITLE for last year</center>";
    }
    echo "</td>";

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
        $HOSTDESC     = $row['srv_desc'];                                   # Get Host Description
        $HOST_OS      = $row['srv_ostype'];                                 # Get O/S Type linux/aix
        $HOST_DOMAIN  = $row['srv_domain'];                             # Get Server Domain

        echo "<center><strong><H2>";
        echo "Summary performance graph for server '$HOSTNAME'";
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
