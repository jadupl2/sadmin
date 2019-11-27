#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis 
#   Title       :   sadm__nmon_rrd_update.sh
#   Synopsis    :   Script that Create/Update RRD (Round Robin Database) file from nmon output file.
#                   This script Read the nmon file (ex: server1_130324_0000.nmon) and update the
#                   statistic in the Proper RRD File.
#                   When the server RRD file is not found, it is created, then updated.
#   Version     :   1.0
#   Date        :   13 January 2018
#   Requires    :   sh and SADMIN Library
#
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# Change Log
#
# 2018_01_13    V1.0b Initial Version
# 2018_01_20    V1.0c Work in Progress
# 2018_01_21    V1.0d Work in Progress
# 2018_01_22    V1.0e Work in Progress
# 2018_01_23    V1.0f First woking Version
# 2018_01_24    V1.1 Add Sub and Total for Error and Success After RRD Update
# 2018_01_25    V1.2 Check if epoch time is less than last rrd epoch before rrdupdate & show friendly message
#               V1.2a Added removal on work temp. file at the end
# 2018_01_28    V1.3 Add nmon file counter during process & bug fix
# 2018_02_04    V1.4 List of all nmon files this script will process before update rrd begin.
# 2018_02_07    V1.5 Remove some log entry not needed
# 2018_02_08    V1.6 Fix Compatibility Problem with 'dash' shell (if statement)
# 2018_02_08    V1.7 Fix Minor Problem with Netdev Counter
# 2018_02_11    V1.8 Small Message Change
# 2018_02_12    V1.9 Add RRD Update Warning Total after each file processed.
# 2018_06_04    v2.0 Adapt to new SADMIN Libr.
# 2018_06_09    v2.1 Change Help and Version Function, Change Script Name, Change Startup Order
# 2018_07_14    v2.2 Switch to Bash Shell instead of sh (Causing Problem with Dash on Debian/Ubuntu)
# 2018_09_17    v2.3 Insert Default Alert Group 
#@2018_11_26 Fix: v2.4 Problem running on RHEL8 with rrdtool 1.7, wasn't updating the rrd database.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.4'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                   # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    export SADM_MAX_LOGLINE=150000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
RC=0                                        ; export RC                 # Script Return Code
CUR_DATE=`date +"%Y_%m_%d"`                 ; export CUR_DATE           # Current Date (2013_01_30)
CUR_TIME=`date +"%H_%M_%S"`                 ; export CUR_TIME           # Current Time (19_09_06)
CUR_DATE=`date +"%Y-%m-%d"`                 ; export CUR_DATE           # Current Date (2013-01-30)
#   
NMON_FILE_LIST="${SADM_TMP_DIR}/nmonls.$$"  ; export NMON_FILE_LIST     # NMON File List to Process
NMON_FILE="${SADM_TMP_DIR}/nmon_file.$$"    ; export NMON_FILE          # Sorted nmon file 4 processing
NMON_OS=""                                  ; export NMON_HOST          # OSName of the nmon file
#
# RRD Custom Variables
RRD_DIR="Will be set later on"              ; export RRD_DIR            # RRD Directory Location
RRD_FILE="Will be set later on"             ; export RRD_FILE           # RRD Filename for nmon file
#




# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-f   nmon file  (to process only one nmon file)"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
    printf "\n\n" 
}


#===================================================================================================
#                   Get Info about nmon file before we start processing it.
#===================================================================================================
read_nmon_info_and_setup_rrd()
{
    NMON_HOST=`grep "^AAA,host" $NMON_FILE | awk -F, '{ print $3 }'`    # Get HostName from nmon file
    grep -i "^AAA,AIX," $NMON_FILE > /dev/null 2>&1                     # Check if it is an AIX nmon
    if [ $?  -eq 0 ]                                                    # Yes it is an Aix nmon
       then NMON_OS="AIX"                                               # Set NMON_OS to aix
       else NMON_OS=`grep "^AAA,OS" $NMON_FILE |awk -F, '{ print $3 }'` # Get OS Name from nmon file
    fi 
    NMON_OS=`echo $NMON_OS | tr '[:lower:]' '[:upper:]'`                # Make all O/S Uppercase
    
    # Validate O/S - Only Aix and Linux Supported
    if [ "$NMON_OS" != "AIX" ] &&  [ "$NMON_OS" != "LINUX" ]            # Advise if Unsupported O/S
        then sadm_writelog "Operating System $NMON_OS is not supported" # Show user it's unsupported
             sadm_writelog "Only Linux and Aix are supported"           # Show Supported O/S
             return 1                                                   # Return Error to Caller
    fi
    
    # Get The Number of Snapshot in current file
    NMON_SNAPSHOTS=`grep "^AAA,snapshots" $NMON_FILE | awk -F, '{ print $3 }'` # Get Nb Snapshots
    export NMON_SNAPSHOTS                                               # Make Nb Snapshot Avail

    # Get the number of Monitoring Intervals (Usually 300 Sec. / 5 min.)
    NMON_INTERVAL=`grep "^AAA,interval" $NMON_FILE | awk -F, '{ print $3 }'`
    
    # If RRD Output Directory doesn't exist for the current host - then create it
    RRD_DIR="${SADM_WWW_RRD_DIR}/${NMON_HOST}"  ; export RRD_DIR   	    # Setup the RRD Location Dir
    if [ ! -d $RRD_DIR ]                                                # If Host Dir. don't exist
        then sadm_writelog "Creating Directory $RRD_DIR"                # Inform USer
             mkdir -p $RRD_DIR                                          # Create dir
             chmod 2775 ${RRD_DIR}                                      # Directory Permission
             chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} ${RRD_DIR}        # Directory Owner/Group
    fi

    # If RRD DataBase does not exist create it 
    RRD_FILE="${RRD_DIR}/${NMON_HOST}.rrd"  ; export RRD_FILE  	        # Setup the RRD File Name
    if [ ! -e  $RRD_FILE ]                                              # Create rrd if not exist
        then sadm_writelog "Creating RRD File for $NMON_HOST ($RRD_FILE)"
             $RRDTOOL create $RRD_FILE                       \
                --start "00:00 01.01.2019" --step 300  \
                DS:cpu_user:GAUGE:900:0:100            \
                DS:cpu_sys:GAUGE:900:0:100             \
                DS:cpu_wait:GAUGE:900:0:100            \
                DS:cpu_idle:GAUGE:900:0:100            \
                DS:cpu_total:GAUGE:900:0:100           \
                DS:mem_new_proc:GAUGE:900:0:100        \
                DS:mem_new_fscache:GAUGE:900:0:100     \
                DS:mem_new_system:GAUGE:900:0:100      \
                DS:mem_new_free:GAUGE:900:0:100        \
                DS:mem_new_pinned:GAUGE:900:0:100      \
                DS:mem_new_user:GAUGE:900:0:100        \
                DS:mem_free:GAUGE:1200:0:U             \
                DS:mem_used:GAUGE:1200:0:U             \
                DS:mem_total:GAUGE:1200:0:U            \
                DS:page_in:GAUGE:1200:0:U              \
                DS:page_out:GAUGE:1200:U:U             \
                DS:page_free:GAUGE:1200:0:U            \
                DS:page_used:GAUGE:1200:0:U            \
                DS:page_total:GAUGE:1200:0:U           \
                DS:disk_kbread_sec:GAUGE:1200:0:U      \
                DS:disk_kbwrtn_sec:GAUGE:1200:0:U      \
                DS:proc_runq:GAUGE:1200:0:U            \
                DS:etha_readkbs:GAUGE:1200:0:U         \
                DS:ethb_readkbs:GAUGE:1200:0:U         \
                DS:ethc_readkbs:GAUGE:1200:0:U         \
                DS:ethd_readkbs:GAUGE:1200:0:U         \
                DS:etha_writekbs:GAUGE:1200:0:U        \
                DS:ethb_writekbs:GAUGE:1200:0:U        \
                DS:ethc_writekbs:GAUGE:1200:0:U        \
                DS:ethd_writekbs:GAUGE:1200:0:U        \
                RRA:MAX:0.5:1:210240
             chmod $664 ${RRD_FILE}                                     # RRD File permission
             chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} ${RRD_FILE}       # RRD File Owner/Group
    fi
 
    # If Debug is Activated - Display Important Variables before exiting function
    if [ "$DEBUG_LEVEL" -gt 1 ]
        then sadm_writelog "NMON_HOST      = $NMON_HOST"
             sadm_writelog "NMON_OS        = $NMON_OS"
             sadm_writelog "NMON_INTERVAL  = $NMON_INTERVAL"
             sadm_writelog "NMON_SNAPSHOTS = $NMON_SNAPSHOTS"
             sadm_writelog "RRD_DIR        = $RRD_DIR"
             sadm_writelog "RRD_FILE       = $RRD_FILE"
             sadm_writelog "NMON_FILE      = $NMON_FILE"
    fi    
}




#===================================================================================================
#                      Collect CPU Stat and put them in the ARRAY_CPU 
#===================================================================================================
#
# ======== Aix nmon lines
# 6767 CPU_ALL,CPU Total server_aix,User%,Sys%,Wait%,Idle%,Busy,PhysicalCPUs
# 6768 CPU_ALL,T0001,29.2,4.8,14.0,52.1,,8
# 6769 CPU_ALL,T0002,40.3,2.5,2.1,55.2,,8
#
# ======== Linux nmon lines
# grep "^CPU_ALL" linux.nmon | sort
#   CPU_ALL,CPU Total ubuntu1604,User%,Sys%,Wait%,Idle%,Busy,CPUs
#   CPU_ALL,T0001,44.4,55.6,0.0,0.0,,1
#   CPU_ALL,T0288,0.6,0.7,0.0,98.6,,1
#
#===================================================================================================
build_cpu_array()
{
    #sadm_writelog " " 
    grep "^CPU_ALL" $NMON_FILE | grep -iv "User%,Sys%,Wait%" | sort >$SADM_TMP_FILE1
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. of CPU_ALL Lines
    sadm_writelog "Processing $NMON_HOST '^CPU_ALL' Lines ($NBLINES elements)."

    while read wline                                                    # Read All CPU_ALL Records
        do
        SNAPSHOT=`echo $wline | cut -d, -f 2 | cut -c2-5`               # Get SnapShot Number
        NUSER=`echo $wline | awk -F, '{ print $3 }'`                    # Get User CPU % Rounded
        if [ "$NUSER" = "" ] ; then NUSER=0.0 ; fi                      # If Not Specified then 0.0
        NSYST=`echo $wline |  awk -F, '{ print $4 }'`                   # Get System CPU % Rounded
        if [ "$NSYST" = "" ] ; then NSYST=0.0 ; fi                      # If Not Specified then 0.0
        NWAIT=`echo $wline |  awk -F, '{ print $5 }'`                   # Get Wait CPU % Rounded
        if [ "$NWAIT" = "" ] ; then NWAIT=0.0 ; fi                      # If Not Specified then 0.0
        NIDLE=`echo $wline |  awk -F, '{ print $6 }'`                   # Get Idle CPU % Rounded
        if [ "$NIDLE" = "" ] ; then NIDLE=0.0 ; fi                      # If Not Specified then 0.0
        NTOTAL=`echo $NUSER + $NSYST + $NWAIT | $SADM_BC -l `           # Field Total CPU Usage

        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now
        ARRAY_CPU[$INDX]="${NUSER},${NSYST},${NWAIT},${NIDLE},${NTOTAL}" # Put Stat. in Array
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -gt 3 ]
            then sadm_writelog "CPU_ALL LINE = $wline"
                 if [ $DEBUG_LEVEL -gt 5 ] 
                    then SVAL="SNAPSHOT=$SNAPSHOT NUSER=$NUSER NSYST=$NSYST "
                         SVAL="$SVAL NWAIT=$NWAIT NIDLE=$NIDLE NTOTAL=$NTOTAL"
                         sadm_writelog "    - $SVAL"
                 fi
                 sadm_writelog "    - INDEX = $INDX - ${ARRAY_CPU[${INDX}]}"
        fi
        done <  $SADM_TMP_FILE1

    # Array is now loaded - Debug at 1,3 or 3 Display Number of array Elements
    if [ $DEBUG_LEVEL -gt 0 ] 
        then sadm_writelog "${#ARRAY_CPU[*]} Elements in CPU array."
    fi
    
    # Array is now loaded - Debug at 7,8 or 9 DIsplay Array content
    if [ $DEBUG_LEVEL -gt 6 ] 
        then for (( i = 1 ; i <= ${#ARRAY_CPU[@]} ; i++ ))
                do
                sadm_writelog "CPU Array Index [$i]: Value : ${ARRAY_CPU[$i]}"
                done   
    fi
    #sadm_writelog "End of CPU usage information."
}






#===================================================================================================
#                      Build Epoch Array Based on ZZZZ Records in nmon file
#
# ======== Aix nmon lines
#   ZZZZ,T0001,00:01:44,08-MAY-2013
#   ZZZZ,T0002,00:06:44,08-MAY-2013
#
# ======== Linux nmon lines
#   $ grep "^ZZZZ" linux.nmon | sort
#   ZZZZ,T0001,23:55:06,03-JAN-2018
#   ZZZZ,T0288,23:50:07,04-JAN-2018
#
#===================================================================================================
build_epoch_array()
{
    grep "^ZZZZ" $NMON_FILE | sort > $SADM_TMP_FILE1                    # Isolate ZZZZ Rec.>tmp file
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. of ZZZZ Lines
    #sadm_writelog " " 
    sadm_writelog "Processing $NMON_HOST '^ZZZZ' Time Lines ($NBLINES elements)."  
    while read wline                                                    # Process all Temp file
        do
        ZCOUNT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`        # Get SnapShot Number 
        ZTIME=` echo $wline | awk -F, '{ print $3 }'`                   # Get Time of the SnapShot
        ZHRS=`  echo $ZTIME | awk -F: '{ print $1 }'`                   # Get Hrs from SnapShot Time
        ZMIN=`  echo $ZTIME | awk -F: '{ print $2 }'`                   # Get Min from SnapShot Time
        ZSEC=`  echo $ZTIME | awk -F: '{ print $3 }'`                   # Get Sec from SnapShot Time
        ZDATE=` echo $wline | awk -F, '{ print $4 }'`                   # Get Date of the SnapShot
        ZDD=`   echo $ZDATE | awk -F- '{ print $1 }'`                   # Get Day from SnapShot Date
        ZYY=`   echo $ZDATE | awk -F- '{ print $3 }'`                   # Year from SnapShot Date
        ZMONTH=`echo $ZDATE | awk -F- '{ print $2 }'| tr '[:lower:]' '[:upper:]'` # Upper Month Name
        if [ "$ZMONTH" = "JAN" ] ; then ZMM=1  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "FEB" ] ; then ZMM=2  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "MAR" ] ; then ZMM=3  ;fi                      # Convert Mth Name to Number 
        if [ "$ZMONTH" = "APR" ] ; then ZMM=4  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "MAY" ] ; then ZMM=5  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "JUN" ] ; then ZMM=6  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "JUL" ] ; then ZMM=7  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "AUG" ] ; then ZMM=8  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "SEP" ] ; then ZMM=9  ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "OCT" ] ; then ZMM=10 ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "NOV" ] ; then ZMM=11 ;fi                      # Convert Mth Name to Number
        if [ "$ZMONTH" = "DEC" ] ; then ZMM=12 ;fi                      # Convert Mth Name to Number
        XDATE="${ZYY}.${ZMM}.${ZDD} ${ZHRS}:${ZMIN}:${ZSEC}"            # Date/Time in proper format
        NMON_EPOCH=$(sadm_date_to_epoch "$XDATE")                       # Snapshot Date to epoch
        ZCOUNT=`expr ${ZCOUNT} + 0`                                     # Make sure is numeric

        # Store Epoch and Date/Time in Snapshot Array
        ARRAY_TIME[$ZCOUNT]="${NMON_EPOCH},${ZDD}/${ZMM}/${ZYY} ${ZHRS}:${ZMIN}:${ZSEC}"
        if [ $DEBUG_LEVEL -gt 3 ]                                       # If Debug Activated
            then sadm_writelog "Processing ZZZ Line : $wline"           # Show ZZZ Current Line
                 A="ARRAY_TIME[$ZCOUNT]=${NMON_EPOCH},${ZDD}/${ZMM}/${ZYY} ${ZHRS}:${ZMIN}:${ZSEC}"
                 sadm_writelog "   - ${A}"                              # Show Debug Info
        fi
        done <  $SADM_TMP_FILE1

    # Array is now loaded - Debug at 7,8 or 9 DIsplay Array content
    if [ $DEBUG_LEVEL -gt 6 ] 
        then sadm_writelog " "
             for (( i = 1 ; i <= ${#ARRAY_TIME[@]} ; i++ ))             # Debug Display Epoch Array
                do
                sadm_writelog "SnapShot/Epoch Array Index [$i]: Value : ${ARRAY_TIME[$i]}"
                done      
    fi 
    # Array is now loaded - Debug at 1,3 or 3 Display Number of array Elements
    if [ $DEBUG_LEVEL -gt 0 ] 
        then sadm_writelog "${#ARRAY_TIME[*]} Elements in SnapShot/Epoch array"
    fi
    #sadm_writelog "End of Processing ZZZZ Time Lines."
}




#===================================================================================================
#                      Collect RunQueue Stat and put them in the RUNQ_CPU 
#===================================================================================================
#
# ======== Aix nmon lines
# PROC,Processes server_aix,Runnable,Swap-in,pswitch,syscall,read,write,fork,exec,sem,msg
# PROC,T0005,19.66,0.03,2754,60601,1905,254,8,9,0,0
#
# ======== Linux nmon lines
# PROC,Processes ubuntu1604,Runnable,Blocked,pswitch,syscall,read,write,fork,exec,sem,msg
# PROC,T0001,2,0,0.0,-1.0,-1.0,-1.0,0.0,-1.0,-1.0,-1.0
# PROC,T0288,1,0,184.4,-1.0,-1.0,-1.0,16.9,-1.0,-1.0,-1.0
#
#===================================================================================================
build_runqueue_array()
{
    #sadm_writelog " " 
    grep "^PROC,T" $NMON_FILE | sort >$SADM_TMP_FILE1
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. of CPU_ALL Lines
    sadm_writelog "Processing $NMON_HOST '^PROC,T' Lines ($NBLINES elements)."

    while read wline                                                    # Read All Proc Records
        do
        SNAPSHOT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`      # Get SnapShot Number
 #        NRUNQ=`echo $wline | awk -F, '{ print int($3+0.5)}'`           # Get RunQueue Rounded
        NRUNQ=`echo $wline | awk -F, '{ print $3 }'`                    # Get RunQueue Rounded
        if [ "$NRUNQ" = "" ] ; then NRUNQ=0.0 ; fi                      # If Not Specified then 0.0
        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now
        ARRAY_RUNQ[$INDX]="${NRUNQ}"                                    # Put Stat. in Array
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -gt 3 ]
            then sadm_writelog "PROC,T LINE = $wline"
                 sadm_writelog "    - INDEX = $INDX - RUNQUEUE = ${ARRAY_RUNQ[${INDX}]}"
        fi    
        done <  $SADM_TMP_FILE1
    #sadm_writelog "End of RunQueue processing"
}








#===================================================================================================
#                      Collect Disk I/O Stat and put them in the ARRAY_DISKREAD
#===================================================================================================
#
# ======== Aix nmon lines
# DISKREAD,Disk Read KB/s
# server_aix,hdisk10,hdisk8,hdisk9,hdisk14,hdisk13,hdisk15,hdisk16,hdisk5,hdisk12,hdisk7,hdisk1
# 7,hdisk18,hdisk21,hdisk19,hdisk22,hdisk4,hdisk25,hdisk29,hdisk26,hdisk30,hdisk23,hdisk27,hd
# isk2,hdisk35,hdisk32,hdisk24,hdisk20,hdisk36,hdisk38,hdisk37,hdisk40,hdisk31,hdisk44,hdisk4
# 5,hdisk28,hdisk46,hdisk33,hdisk47,hdisk49,hdisk34,hdisk41,hdisk43,hdisk50,hdisk54,hdisk56,h
# disk55,hdisk52,hdisk53,hdisk58,hdisk42,hdisk60,hdisk63,hdisk48,hdisk39,hdisk64,hdisk51,hdis
# k68,hdisk66,hdisk59,hdisk69,hdisk70,hdisk73,hdisk72,hdisk67,hdisk74,hdisk61,hdisk77,hdisk57
# ,hdisk78,hdisk79,hdisk82,hdisk81,hdisk83,hdisk76,hdisk84,hdisk11,hdisk65,hdisk88,hdisk90,hd
# isk89,hdisk62,hdisk91,hdisk94,hdisk92,hdisk75,hdisk3,hdisk97,hdisk98,hdisk71,hdisk80,hdisk6
# ,hdisk85,hdisk86,hdisk87,hdisk93,hdisk95,hdisk96,hdisk0,hdisk1,cd0,hdisk99,hdisk102,hdisk10
# 1,hdisk100,hdisk104,hdisk103,hdisk105,hdisk106,hdisk108,hdisk111,hdisk118,hdisk116,hdisk107
# ,hdisk112,hdisk113,hdisk114,hdisk115,hdisk110,hdisk109,hdisk117,hdisk120,hdisk121,hdisk119,
# hdisk122,hdisk123,hdisk126,hdisk127,hdisk124,hdisk125,hdisk129,hdisk131,hdisk128,hdisk135,h
# disk139,hdisk137,hdisk138,hdisk136,hdisk134,hdisk130,hdisk132,hdisk133
# DISKREAD,T0001,21.7,70.5,11.9,6.9,18.0,5.5,11.8,5.0,21.2,1.4,2.4,54.3,2.0,68.8,0.3,5.2,1.6,
# 586.5,11.0,685.8,6.9,27.9,10.1,50.5,689.7,1.0,49.3,3.1,223.7,101.7,391.6,677.3,0.4,94.7,1.4
# ,1.8,2.3,1.1,3.8,95.4,1.5,0.8,0.8,11.1,6.3,36.4,82.3,1.0,32.4,11.3,1.9,1.3,8.5,0.8,0.8,5.6,
# 8.7,4.6,8.8,5.0,1.4,222.5,184.8,228.2,7.4,4.0,400.8,20.6,278.6,6.3,1902.3,488.9,0.9,2.7,0.8
# ,22.0,67.7,0.8,1.1,0.8,3.8,1.5,0.8,0.6,3.7,5.4,2.9,38.2,3.4,93.1,117.4,1.5,1.2,0.9,0.8,0.5,
# 2.5,209.2,24.1,0.0,36.7,365.8,236.5,666.6,0.2,0.2,14.9,0.3,0.3,0.2,0.3,2.7,20.9,0.2,2.6,2.8
# ,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.2,0.3,0.3,0.2,0.2,0.2,0.3,51.2,0.3,0.1,0.3,0.3,0
# 2,0.3,1.2
#
# ======== Linux nmon lines
# DISKREAD,Disk Read KB/s host,loop0,loop1,sda,sda1,sda2,dm-0,dm-1,dm-2,dm-3,dm-4,dm-5,dm-6,dm-7
# DISKREAD,T0001,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
# DISKREAD,T0002,0.0,0.0,224.9,0.4,212.5,32.9,19.4,59.1,20.8,19.1,19.1,20.6,20.4
# ...
# DISKREAD,T0287,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
# DISKREAD,T0288,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
#
#===================================================================================================
build_disk_read_array()
{
    #sadm_writelog " " 
    grep "^DISKREAD,T" $NMON_FILE | sort >$SADM_TMP_FILE1               # Isolate Disk Read Line
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. DISKREAD Lines
    sadm_writelog "Processing $NMON_HOST '^DISKREAD' Lines ($NBLINES elements)."

    while read wline                                                    # Read All Records
        do
        SNAPSHOT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`      # Get SnapShot Number
        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now
        NCOUNT=`echo $wline | awk -F, '{ print NF }'`                   # Count No of fields on line
        if [ "$NCOUNT" = ""  ] ; then NCOUNT=0.0 ; fi                   # If Not Specified then 0.0
        if [ "$NCOUNT" -eq 0 ] ; then continue   ; fi                   # If no comma ? = Nxt Line
        if [ "$INDX" -eq 1  ]  ; then NBDEV=$NCOUNT ; fi                # Save Nb Disks Dealing with

        WTOTAL=0                                                        # Clear line total field
        if [ $DEBUG_LEVEL -eq 9 ] ; then sadm_writelog "Disk Read Line: $wline" ;fi
        for i in $(seq 3 $NCOUNT)                                       # Process all fields on line
            do
            WFIELD=`echo $wline | $CUT -d, -f $i`                       # Get Field on line
            WTOTAL=`echo $WTOTAL + $WFIELD | $SADM_BC -l `              # Add Field to Line Total
            if [ $DEBUG_LEVEL -eq 9 ]                                   # Full Debug Info
                then sadm_writelog "Add $WFIELD & Total Read : $WTOTAL" # Show KBS Added & Total
            fi
            done
        #ARRAY_DISKREAD[$INDX]=`echo "${WTOTAL} / 1024"| $SADM_BC -l`    # Convert KBS>MBS in Array
        ARRAY_DISKREAD[$INDX]=${WTOTAL}                                 # Total Read KBS in Array
        if [ $DEBUG_LEVEL -gt 4 ] ;then sadm_writelog "LINE=$wline" ;fi # Show Processing Line 
        if [ $DEBUG_LEVEL -gt 1 ]                                       # Debug Activated 
            then sadm_writelog "Snapshot $INDX Read at ${ARRAY_DISKREAD[${INDX}]} Mb/s"
        fi    
        done <  $SADM_TMP_FILE1
    #sadm_writelog "End of collecting Read information for the $NBDEV Devices "
}




#===================================================================================================
#                      Collect Disk I/O Stat and put them in the ARRAY_DISKWRITE
#===================================================================================================
#
# ======== Aix nmon lines
# DISKWRITE,Disk Write KB/s
# server_aix,hdisk10,hdisk8,hdisk9,hdisk14,hdisk13,hdisk15,hdisk16,hdisk5,hdisk12,hdisk7,hdisk1
# 7,hdisk18,hdisk21,hdisk19,hdisk22,hdisk4,hdisk25,hdisk29,hdisk26,hdisk30,hdisk23,hdisk27,hd
# isk2,hdisk35,hdisk32,hdisk24,hdisk20,hdisk36,hdisk38,hdisk37,hdisk40,hdisk31,hdisk44,hdisk4
# 5,hdisk28,hdisk46,hdisk33,hdisk47,hdisk49,hdisk34,hdisk41,hdisk43,hdisk50,hdisk54,hdisk56,h
# disk55,hdisk52,hdisk53,hdisk58,hdisk42,hdisk60,hdisk63,hdisk48,hdisk39,hdisk64,hdisk51,hdis
# k68,hdisk66,hdisk59,hdisk69,hdisk70,hdisk73,hdisk72,hdisk67,hdisk74,hdisk61,hdisk77,hdisk57
# ,hdisk78,hdisk79,hdisk82,hdisk81,hdisk83,hdisk76,hdisk84,hdisk11,hdisk65,hdisk88,hdisk90,hd
# isk89,hdisk62,hdisk91,hdisk94,hdisk92,hdisk75,hdisk3,hdisk97,hdisk98,hdisk71,hdisk80,hdisk6
# ,hdisk85,hdisk86,hdisk87,hdisk93,hdisk95,hdisk96,hdisk0,hdisk1,cd0,hdisk99,hdisk102,hdisk10
# 1,hdisk100,hdisk104,hdisk103,hdisk105,hdisk106,hdisk108,hdisk111,hdisk118,hdisk116,hdisk107
# ,hdisk112,hdisk113,hdisk114,hdisk115,hdisk110,hdisk109,hdisk117,hdisk120,hdisk121,hdisk119,
# hdisk122,hdisk123,hdisk126,hdisk127,hdisk124,hdisk125,hdisk129,hdisk131,hdisk128,hdisk135,h
# disk139,hdisk137,hdisk138,hdisk136,hdisk134,hdisk130,hdisk132,hdisk133
# 7924 DISKWRITE,T0001,4.3,0.2,0.2,0.1,13.7,0.3,0.2,0.2,5.0,0.2,0.2,0.3,0.1,0.2,0.1,19.7,17.2,0.0,
# 73.0,1.0,0.2,0.2,0.3,0.0,0.1,0.1,0.5,41.8,0.0,0.1,0.1,0.0,4.2,0.1,12.7,0.1,3.0,0.8,0.2,96.6
# ,0.0,0.1,113.5,1.6,0.2,72.9,0.8,3.0,0.2,0.1,0.1,0.1,0.8,0.0,0.0,0.3,0.0,0.0,0.5,0.0,0.0,23.
# 7,72.0,6.4,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.1,0.0,0.2,0.0,3.0,0.9,0.0,0.0,0.0,0.0,0.0,0.2,0.0,
# 0.0,0.4,0.0,49.9,0.0,0.0,0.3,0.0,0.0,0.0,0.0,0.0,0.0,2700.1,2700.8,0.0,0.0,1.4,1.2,2.8,0.0,
# 0.0,0.0,0.0,0.0,0.0,0.0,0.0,20.5,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.
# 0,0.0,0.0,0.0,0.0,0.0,0.2,0.0,0.0,0.2,0.0,0.0,0.0,0.0
#
# ======== Linux nmon lines
# DISKWRITE,Disk Write KB/s host,loop0,loop1,sda,sda1,sda2,dm-0,dm-1,dm-2,dm-3,dm-4,dm-5,dm-6,dm-7
# DISKWRITE,T0001,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
# DISKWRITE,T0288,0.0,0.0,2.1,0.0,2.1,0.0,0.0,0.0,0.5,0.0,0.0,0.5,1.2
#
#===================================================================================================
build_disk_write_array()
{
    #sadm_writelog " " 
    grep "^DISKWRITE,T" $NMON_FILE | sort >$SADM_TMP_FILE1              # Isolate Disk Write Line
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. DISKWRITE Lines
    sadm_writelog "Processing $NMON_HOST '^DISKWRITE' Lines ($NBLINES elements)."

    while read wline                                                    # Read All Records
        do
        SNAPSHOT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`      # Get SnapShot Number
        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now
        NCOUNT=`echo $wline | awk -F, '{ print NF }'`                   # Count No of fields on line
        if [ "$NCOUNT" = ""  ] ; then NCOUNT=0.0 ; fi                   # If Not Specified then 0.0
        if [ "$NCOUNT" -eq 0 ] ; then continue   ; fi                   # If no comma ? = Nxt Line
        if [ "$INDX" -eq 1  ]  ; then NBDEV=$NCOUNT ; fi                # Save Nb Disks Dealing with

        WTOTAL=0                                                        # Clear line total field
        if [ $DEBUG_LEVEL -eq 9 ] ; then sadm_writelog "Disk Write Line: $wline" ;fi
        for i in $(seq 3 $NCOUNT)                                       # Process all fields on line
            do
            WFIELD=`echo $wline | $CUT -d, -f $i`                       # Get Field on line
            WTOTAL=`echo $WTOTAL + $WFIELD | $SADM_BC -l `              # Add Field to Line Total
            if [ $DEBUG_LEVEL -eq 9 ]                                   # Full Debug Info
                then sadm_writelog "Add $WFIELD & Total Write: $WTOTAL" # Show KBS Added & Total
            fi
            done
        #ARRAY_DISKWRITE[$INDX]=`echo "${WTOTAL} / 1024"| $SADM_BC -l`   # Convert KBS>MBS in Array
        ARRAY_DISKWRITE[$INDX]=${WTOTAL}                                # Total Write KBS in Array
        if [ $DEBUG_LEVEL -gt 4 ] ;then sadm_writelog "LINE=$wline" ;fi # Show Processing Line 
        if [ $DEBUG_LEVEL -gt 1 ]                                       # Debug Activated 
            then sadm_writelog "Snapshot $INDX Write at ${ARRAY_DISKWRITE[${INDX}]} Mb/s"
        fi    
        done <  $SADM_TMP_FILE1
    #sadm_writelog "End of collecting Write information for the $NBDEV Devices "
}


#===================================================================================================
#                      Collect Network Stat and put them in the ARRAY_NET
#===================================================================================================
#
# ======== Aix nmon lines
# NET,Network I/O server_aix,en0-read-KB/s,en1-read-KB/s,en2-read-KB/s,lo0-read-KB/s,en0-write-KB/s,
#   en1-write-KB/s,en2-write-KB/s,lo0-write-KB/s
# NET,T0001,167.1,0.7,0.0,21.6,59.0,0.0,0.0,21.6
# NET,T0002,27.4,0.6,0.0,3.4,12.3,0.0,0.0,3.4
#
# ======== Linux nmon lines
# NET,Network I/O server_linux,lo-read-KB/s,eth0-read-KB/s,eth1-read-KB/s,eth2-read-KB/s,
#   eth3-read-KB/s,sit0-read-KB/s,lo-write-KB/s,eth0-write-KB/s,eth1-write-KB/s,eth2-write-KB/s,
#   eth3-write-KB/s,sit0-write-KB/s,
# NET,T0001,5.1,253.4,0.7,0.0,0.0,0.0,5.1,425.5,0.0,0.0,0.0,0.0,
# NET,T0002,79.9,313.2,13.2,0.0,0.0,0.0,79.9,1607.3,2790.8,0.0,0.0,0.0,
#
# NET,Network I/O ubuntu1604,lo-read-KB/s,ens160-read-KB/s,lo-write-KB/s,ens160-write-KB/s,
# NET,T0001,0.1,0.3,0.1,0.0,
# NET,T0002,0.2,0.5,0.2,0.4,
#
#===================================================================================================
build_net_array()
{

    # Get and Show number of Network Snapshot
    grep "^NET,T" $NMON_FILE | sort >$SADM_TMP_FILE1                    # Extract NET from nmon file
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. of NET Lines
    #sadm_writelog " " 
    sadm_writelog "Processing Network of $NMON_HOST ($NMON_OS) '^NET,' Lines ($NBLINES elements)."

    # Determine and show Number of Network Devices in NMON file (Minus the loop interface)
    HDLINE=`grep "^NET," $NMON_FILE | head -1`                          # Get Network Header Line 
    NBFLD=`echo $HDLINE | awk -F, '{ print NF }'`                       # Get Nb Field on Heading
    if  [ ${HDLINE: -1} = "," ] ; then let NBFLD="$NBFLD - 1" ; fi      # extra , at end of line ??
    #if [ "$NMON_OS" = "LINUX" ] ; then let NBFLD="$NBFLD - 1" ; fi     # extra , at end of line ??
    if [ $DEBUG_LEVEL -gt 6 ] 
        then sadm_writelog "Nb.Fields= $NBFLD Heading Line= $HDLINE"    # Show Net Heading Line 
    fi
    let NBDEV="($NBFLD - 4) / 2"                                        # Remove Heading + lo device
    sadm_writelog "System $NMON_HOST have $NBDEV network interface(s)"  # Show user Nb. Network Dev.


    # From The ^NET, header line (first line of the ^NET,)
    # Get name of each device, type of stat (Read/Write) and column number of statistics on line
    # Produce a file $SADM_TMP_FILE2 used later on (Example of line: ens160,read,4)
    if [ -f "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 ; fi       # Del Work file if exist
    indx=3                                                              # Start at 3 to skip header
    while [ $indx -le $NBFLD ]                                          # Inspect All Dev Name
        do
        devname=$( echo $HDLINE | cut -d, -f ${indx} | cut -d'-' -f 1)  # Get Network Device Name
        typename=$(echo $HDLINE | cut -d, -f ${indx} | cut -d'-' -f 2)  # Get read or write string
        colname=`  echo $HDLINE | cut -d, -f ${indx}`                   # Extract Column Name
        if [ "$devname" != "lo" ] && [ "$devname" != "lo0" ]            # Don't need loop interface
            then if [ $DEBUG_LEVEL -gt 7 ]                              # Show Line added to file
                    then echo "colnum= ${indx} Dev= $devname typename= $typename colname= $colname" 
                 fi
                 echo "${devname},${typename},${indx}" >>$SADM_TMP_FILE2 # Add Net Dev info to file
        fi
        ((indx++))                                                      # Increment Indx,process nxt
        done 


    # Finally we have a file with all netdevice (Format dev,[read|write],column where stat are.
    # Example : eth0,read,4
    #           eth0,write,10
    cat $SADM_TMP_FILE2 | sort | uniq > $SADM_TMP_FILE3                 # Sort file, No Dup
    if [ $DEBUG_LEVEL -gt 4 ]           
        then sadm_writelog "Network Devices in nmon file and column where stat are"
             cat $SADM_TMP_FILE3
    fi

    # Create work file ($SADM_TMP_FILE2) with only the first four (max) network devices we will use
    cat $SADM_TMP_FILE3 | awk -F, '{ print $1 }' | sort | uniq | head -4 >$SADM_TMP_FILE2 # Only Dev
    sadm_writelog "Chosen Network Devices (Up to 4)"                    # Show user what follow
    dcount=0;                                                           # Network Device Counter
    cat $SADM_TMP_FILE2 | while read wline                              # Show resulting netdev file
        do dcount=$((dcount+1))                                         # Increment Device Counter
           sadm_writelog "  $dcount) $wline"                            # Show DevCount & DevName
        done
    cp $SADM_TMP_FILE2 ${RRD_DIR}/netdev.txt

    # Set Default Values for Interface Name, Read Column and Write Column where stat are 
    if1name=""  ; if1rc=0   ; if1wc=0                                   # if1 Name,ReadCol, WriteCol
    if2name=""  ; if2rc=0   ; if2wc=0                                   # if2 Name,ReadCol, WriteCol
    if3name=""  ; if3rc=0   ; if3wc=0                                   # if3 Name,ReadCol, WriteCol
    if4name=""  ; if4rc=0   ; if4wc=0                                   # if4 Name,ReadCol, WriteCol

    # Read Choosen 4 Interfaces and save column ready to read nmon file
    COUNTER=1                                                           # Interface Counter
    while read -r wif                                                   # Read Net Dev Chosen File
        do 
        if [ $COUNTER -eq 1 ]                                           # For First Interface
            then if1name=$wif                                           # Interface 1 Name
                 if1rc=`grep "^${wif},read"  $SADM_TMP_FILE3 |awk -F, '{print $3}'` # If1 Read Col
                 if1wc=`grep "^${wif},write" $SADM_TMP_FILE3 |awk -F, '{print $3}'` # if1 Write Col
                 if [ "$if1rc" = "" ] ; then if1rc=0 ; fi               # Read Column Not ok in nmon
                 if [ "$if1wc" = "" ] ; then if1wc=0 ; fi               # Write Column Not ok in nmon
        fi
        if [ $COUNTER -eq 2 ]                                           # For second Interface
            then if2name=$wif                                           # Set Interface 2 Name
                 if2rc=`grep "^${wif},read"  $SADM_TMP_FILE3 |awk -F, '{print $3}'` # If2 Read Col
                 if2wc=`grep "^${wif},write" $SADM_TMP_FILE3 |awk -F, '{print $3}'` # if2 Write Col
                 if [ "$if2rc" = "" ] ; then if2rc=0 ; fi               # Read Column Not ok in nmon
                 if [ "$if2wc" = "" ] ; then if2wc=0 ; fi               # Write Column Not ok in nmon
        fi
        if [ $COUNTER -eq 3 ]                                           # For third Interface
            then if3name=$wif                                           # Set Interface 3 Name
                 if3rc=`grep "^${wif},read"  $SADM_TMP_FILE3 |awk -F, '{print $3}'` # If3 Read Col
                 if3wc=`grep "^${wif},write" $SADM_TMP_FILE3 |awk -F, '{print $3}'` # if3 Write Col
                 if [ "$if3rc" = "" ] ; then if3rc=0 ; fi               # Read Column Not ok in nmon
                 if [ "$if3wc" = "" ] ; then if3wc=0 ; fi               # Write Column Not ok in nmon
        fi
        if [ $COUNTER -eq 4 ]                                           # For the fouth Interface
            then if4name=$wif                                           # Set Interface 3 Name
                 if4rc=`grep "^${wif},read"  $SADM_TMP_FILE3 |awk -F, '{print $3}'` # If3 Read Col
                 if4wc=`grep "^${wif},write" $SADM_TMP_FILE3 |awk -F, '{print $3}'` # if3 Write Col
                 if [ "$if4rc" = "" ] ; then if4rc=0 ; fi               # Read Column Not ok in nmon
                 if [ "$if4wc" = "" ] ; then if4wc=0 ; fi               # Write Column Not ok in nmon
        fi
        let COUNTER=COUNTER+1 
        done < $SADM_TMP_FILE2
        if [ $DEBUG_LEVEL -gt 4 ]                                       # Interface Read/Write Col
            then sadm_writelog "if1rc=$if1rc if2rc=$if2rc if3rc=$if3rc if4rc=$if4rc" # Show ReadCol
                 sadm_writelog "if1wc=$if1wc if2wc=$if2wc if3wc=$if3wc if4wc=$if4wc" # Show WriteCol
        fi  


    # Now Let's Process each "^NET,T" line in file $SADM_TMP_FILE1, Produce at top of this function
    # Example of Line: NET,T0002,79.9,313.2,13.2,0.0,0.0,0.0,79.9,1607.3,2790.8,0.0,0.0,0.0,
    while read wline                                                    # Read Network Stat Lines
        do
        if [ $DEBUG_LEVEL -gt 4 ] ; then sadm_writelog "NET Line = $wline" ;fi # Show Net Line 
        SNAPSHOT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`      # Get SnapShot Number
        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now
        if [ "$if1rc" -ne 0 ] ; then if1r=$(echo $wline |cut -d, -f ${if1rc}) ; fi  # if1 Read Stat
        if [ "$if2rc" -ne 0 ] ; then if2r=$(echo $wline |cut -d, -f ${if2rc}) ; fi  # if2 Read Stat
        if [ "$if3rc" -ne 0 ] ; then if3r=$(echo $wline |cut -d, -f ${if3rc}) ; fi  # if3 Read Stat
        if [ "$if4rc" -ne 0 ] ; then if4r=$(echo $wline |cut -d, -f ${if4rc}) ; fi  # if4 Read Stat
        if [ "$if1wc" -ne 0 ] ; then if1w=$(echo $wline |cut -d, -f ${if1wc}) ; fi  # if1 Write Stat
        if [ "$if2wc" -ne 0 ] ; then if2w=$(echo $wline |cut -d, -f ${if2wc}) ; fi  # if2 Write Stat
        if [ "$if3wc" -ne 0 ] ; then if3w=$(echo $wline |cut -d, -f ${if3wc}) ; fi  # if3 Write Stat
        if [ "$if4wc" -ne 0 ] ; then if4w=$(echo $wline |cut -d, -f ${if4wc}) ; fi  # if4 Write Stat
        ARRAY_NET[$INDX]="$if1r,$if2r,$if3r,$if4r,$if1w,$if2w,$if3w,$if4w"  # Put Stat in Net Array
        if [ $DEBUG_LEVEL -gt 4 ] 
            then sadm_writelog "ARRAY_NET[$INDX]=$if1r,$if2r,$if3r,$if4r,$if1w,$if2w,$if3w,$if4w"
        fi    

        # Debugging info - List Device Name , Stat Read Column, Stat Write Column, Read & Write Stat
        if [ $DEBUG_LEVEL -gt 4 ]                                       # High Debug Info
            then for i in `seq 1 4`;                                    # List info for the 4 NetDev
                    do
                    if [ $i -eq 1 ] &&  [ "$if1name" != "" ]            # third Interface non Blank
                        then S="if1name=$if1name if1rc=$if1rc if1wc=$if1wc if1r=$if1r if1w=$if1w"
                             sadm_writelog "$S"
                    fi
                    if [ $i -eq 2 ] &&  [ "$if2name" != "" ]            # third Interface non Blank
                        then S="if2name=$if2name if2rc=$if2rc if2wc=$if2wc if2r=$if2r if2w=$if2w"
                             sadm_writelog "$S"
                    fi
                    if [ $i -eq 3 ] &&  [ "$if3name" != "" ]            # third Interface non Blank
                        then S="if3name=$if3name if3rc=$if3rc if3wc=$if3wc if3r=$if3r if3w=$if3w"
                             sadm_writelog "$S"
                    fi
                    if [ $i -eq 4 ] &&  [ "$if4name" != "" ]            # third Interface non Blank
                        then S="if4name=$if4name if4rc=$if4rc if4wc=$if4wc if4r=$if4r if4w=$if4w"
                             sadm_writelog "$S"
                    fi
                    done  
        fi
        done < $SADM_TMP_FILE1
    #sadm_writelog "Finishing Network Activity Information."
}




#===================================================================================================
#                      Collect Memory Stat and put them in the ARRAY_MEM 
#===================================================================================================
#
# ======== Aix nmon lines
# MEM,Memory server_aix,Real Free %,Virtual free %,Real free(MB),Virtual free(MB),Real
# total(MB),Virtual total(MB)
# MEM,T0001,18.8,77.7,7738.3,15508.6,41216.0,19968.0
# MEM,T0002,18.4,77.7,7601.8,15509.4,41216.0,19968.0
#
# ======== Linux nmon lines
# MEM,Memory MB ubuntu1604,memtotal,hightotal,lowtotal,swaptotal,memfree,highfree,lowfree,swapfree,
#     memshared,cached,active,bigfree,buffers,swapcached,inactive
# MEM,T0001,1496.3,-0.0,-0.0,1952.0,224.3,-0.0,-0.0,1948.1,-0.0,951.1,452.6,-1.0,57.0,1.0,595.6
# MEM,T0288,1496.3,-0.0,-0.0,1952.0,319.3,-0.0,-0.0,1948.1,-0.0,855.2,459.7,-1.0,56.7,1.0,491.7
# 
#===================================================================================================
build_memory_array()
{
    #sadm_writelog " " 

    if [ "$NMON_OS" = "AIX" ]                                           # If on AIX
        then grep "^MEM," $NMON_FILE | head -1 >$SADM_TMP_FILE2         # Aix Memory Header Line
             hd_mem_total=` cat $SADM_TMP_FILE2 |awk -F, '{print $7}'`  # Aix Header for Mem Total
             hd_mem_free=`  cat $SADM_TMP_FILE2 |awk -F, '{print $5}'`  # Aix Header for Mem Free
             hd_vir_total=` cat $SADM_TMP_FILE2 |awk -F, '{print $8}'`  # Aix Header for Vir Total
             hd_vir_free=`  cat $SADM_TMP_FILE2 |awk -F, '{print $6}'`  # Aix Header for Vir Free
        else grep "^MEM," $NMON_FILE | head -1 >$SADM_TMP_FILE2         # Linux Memory Header Line
             hd_mem_total=` cat $SADM_TMP_FILE2 |awk -F, '{print $3}'`  # Linux Header for Mem Total
             hd_mem_free=`  cat $SADM_TMP_FILE2 |awk -F, '{print $7}'`  # Linux Header for Mem Free
             hd_vir_total=` cat $SADM_TMP_FILE2 |awk -F, '{print $6}'`  # Linux Header for Vir Total
             hd_vir_free=`  cat $SADM_TMP_FILE2 |awk -F, '{print $10}'` # Linux Header for Vir Free
    fi
    grep "^MEM,T" $NMON_FILE | sort >$SADM_TMP_FILE1                    # Extract MEM from nmon file
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. of MEM Lines
    sadm_writelog "Processing $NMON_OS - $NMON_HOST '^MEM,T' Lines ($NBLINES elements)."

    while read wline                                                    # Process Extract File 
        do
        SNAPSHOT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`      # Get SnapShot Number
        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now
        if [ "$NMON_OS" = "AIX" ]                                       # If on AIX
            then MEM_TOTAL=`echo $wline | awk -F, '{ print $7 }'`       # AIX Total Memory in MB
                 MEM_FREE=` echo $wline | awk -F, '{ print $5 }'`       # AIX Free Memory in MB
            else MEM_TOTAL=`echo $wline | awk -F, '{ print $3 }'`       # Real Memory in MB
                 MEM_FREE=` echo $wline | awk -F, '{ print $7 }'`       # Free Memory in MB
        fi            
        MEM_USE=`echo $MEM_TOTAL - $MEM_FREE | $SADM_BC -l `            # Calculate Memory Use

        if [ "$NMON_OS" =  "AIX" ]                                      # If on AIX
            then VIR_TOTAL=`echo $wline | awk -F, '{ print $8 }'`       # Aix Virt. Total Mem in MB
                 VIR_FREE=` echo $wline | awk -F, '{ print $6 }'`       # Aix Virt. Free Mem in MB
            else VIR_TOTAL=`echo $wline | awk -F, '{ print $6 }'`       # Linux swap Total in MB
                 VIR_FREE=` echo $wline | awk -F, '{ print $10 }'`      # Linux swap  Free in MB
        fi
        VIR_USE=`echo $VIR_TOTAL - $VIR_FREE | $SADM_BC -l `            # Calc.Virtual/Swap Use

        # Put Memory Statistics in Array
        ARRAY_MEMORY[$INDX]="${MEM_TOTAL},${MEM_FREE},${MEM_USE},${VIR_TOTAL},${VIR_FREE},${VIR_USE}"
        
        if [ $DEBUG_LEVEL -gt 4 ] ;then sadm_writelog "Memory line: $wline" ;fi 
        if [ $DEBUG_LEVEL -gt 1 ]
            then SLINE="$INDX ${hd_mem_total}=${MEM_TOTAL}MB  ${hd_mem_free}=${MEM_FREE}MB Use ${MEM_USE}MB" 
                 SLINE="$SLINE ${hd_vir_total}=${VIR_TOTAL}MB ${hd_vir_free}=${VIR_FREE}MB Use ${VIR_USE}MB"
                 sadm_writelog "$SLINE" 
        fi

        done <  $SADM_TMP_FILE1
    #sadm_writelog "End of collection Memory information - Hard ${MEM_TOTAL}MB, Virtual ${VIR_TOTAL}MB"
}






#===================================================================================================
#                      Collect Memory Stat and put them in the ARRAY_MEM 
#===================================================================================================
#
# ======== Aix nmon lines
# MEMNEW,Memory New server_aix,Process%,FScache%,System%,Free%,Pinned%,User%
# MEMNEW,T0001,50.5,34.6,6.9,8.0,7.0,81.6
# MEMNEW,T0288,41.4,27.6,13.0,18.1,11.7,65.1
#
# ======== Linux nmon lines
# NOT EXIST ON LINUX
#===================================================================================================
build_memnew_array()
{
    if [ "$NMON_OS" != "AIX" ]                                          # If Not an Aix nmon File
        then return 0                                                   # Return to Caller
    fi
    
    #sadm_writelog " " 

    # Get the header of fields we will extract (Want to be sure using the right column)
    grep "^MEMNEW," $NMON_FILE | head -1 >$SADM_TMP_FILE2               # Aix MemNew Header Line
    hd_proc=`   cat $SADM_TMP_FILE2 | awk -F, '{print $3}'`             # Aix Mem Used by Process
    hd_fscache=`cat $SADM_TMP_FILE2 | awk -F, '{print $4}'`             # Aix Mem Used by FS Cache
    hd_system=` cat $SADM_TMP_FILE2 | awk -F, '{print $5}'`             # Aix Mem Used by System
    hd_free=`   cat $SADM_TMP_FILE2 | awk -F, '{print $6}'`             # Aix Free Memory
    hd_pin=`    cat $SADM_TMP_FILE2 | awk -F, '{print $7}'`             # Aix Pinned Memory 
    hd_user=`   cat $SADM_TMP_FILE2 | awk -F, '{print $8}'`             # Aix Mem Used by Users

    # Extract Aix Memory Usage
    grep "^MEMNEW,T" $NMON_FILE | sort >$SADM_TMP_FILE1                 # Aix Memory Utilization 
    NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`                # Calc. Nb. of Snapshot 
    sadm_writelog "Processing $NMON_OS Memory Utilization '^MEMNEW,T' Lines ($NBLINES elements)"
    
    while read wline                                                    # Read All Records
        do
        SNAPSHOT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`      # Get SnapShot Number
        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now

        M_PROCESS=`echo $wline | awk -F, '{ print $3 }'`                # Process %
        M_FSCACHE=`echo $wline | awk -F, '{ print $4 }'`                # FSCache %
        M_SYSTEM=` echo $wline | awk -F, '{ print $5 }'`                # System  %
        M_FREE=`   echo $wline | awk -F, '{ print $6 }'`                # Free  %
        M_PINNED=` echo $wline | awk -F, '{ print $7 }'`                # Pinned %
        M_USER=`   echo $wline | awk -F, '{ print $8 }'`                # User %

        # Put Memory Statistics in Array
        ARRAY_MEMNEW[$INDX]="${M_PROCESS},${M_FSCACHE},${M_SYSTEM},${M_FREE},${M_PINNED},${M_USER}"
        
        if [ $DEBUG_LEVEL -gt 4 ]
            then sadm_writelog "Memory line is $wline"
                 SLINE="$INDX ${hd_proc}=${M_PROCESS} ${hd_fscache}=${M_FSCACHE} ${hd_system}=${M_SYSTEM}"
                 SLINE="$SLINE ${hd_free}=${M_FREE} ${hs_pin}=${M_PINNED} ${hd_user}=${M_USER}"
                 sadm_writelog "$SLINE" 
        fi

        done <  $SADM_TMP_FILE1
    #sadm_writelog "Finish collecting Memory New information."
}






#===================================================================================================
#               Collect Pagein and Pageout Stat and put them in the ARRAY_PAGING
#===================================================================================================
#
# ======== Aix nmon lines
# PAGE,Paging server_aix,faults,pgin,pgout,pgsin,pgsout,reclaims,scans,cycles
# PAGE,T0001,13956.7,24.0,749.8,12.4,0.3,0.0,0.0,0.0
# PAGE,T0288,3502.2,174.2,73.5,0.1,0.0,0.0,0.0,0.0
#
# ======== Linux nmon lines
# VM,Paging and Virtual Memory,nr_dirty,nr_writeback,nr_unstable,nr_page_table_pages,nr_mapped,
# nr_slab,pgpgin,pgpgout,pswpin,pswpout,pgfree,pgactivate,pgdeactivate,pgfault,pgmajfault,
# pginodesteal,slabs_scanned,kswapd_steal,kswapd_inodesteal,pageoutrun,allocstall,pgrotated,
# pgalloc_high,pgalloc_normal,pgalloc_dma,pgrefill_high,pgrefill_normal,pgrefill_dma,pgsteal_high,
# pgsteal_normal,pgsteal_dma,pgscan_kswapd_high,pgscan_kswapd_normal,pgscan_kswapd_dma,
# pgscan_direct_high,pgscan_direct_normal,pgscan_direct_dma
# VM,T0001,40,0,0,862,7632,-1,0,0,0,0,50274,6,0,60655,0,0,0,0,0,0,0,0,0,0,542,0,0,0,0,0,0,0,0,0,0,0,0
# VM,T0002,36,0,0,791,7267,-1,67484,10126,0,0,3136449,4513,75,3851039,0,0,0,0,0,0,0,126,0,0,33684,0,0,0,0,0,0,0,0,0,0,0,0
# VM,T0288,14,0,0,791,7473,-1,0,640,0,0,393429,171,0,471837,0,0,0,0,0,0,0,0,0,0,4254,0,0,0,0,0,0,0,0,0,0,0,0
#
#===================================================================================================
build_paging_activity_array()
{
    #sadm_writelog " " 
    if [ "$NMON_OS" = "AIX" ]                                           # If an Aix nmon File
        then grep "^PAGE," $NMON_FILE | head -1 >$SADM_TMP_FILE2        # Aix Paging Header Line
             hd_pgin=` cat $SADM_TMP_FILE2 | awk -F, '{print $6}'`      # Aix Header for pgin
             hd_pgout=`cat $SADM_TMP_FILE2 | awk -F, '{print $7}'`      # Aix Header for pgout
             grep "^PAGE,T" $NMON_FILE | sort >$SADM_TMP_FILE1          # Aix Paging Activity
             NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`       # Calc. Nb. of Paging Lines
             sadm_writelog "Processing $NMON_OS Paging Activity '^PAGE,T' Lines ($NBLINES elements)"
        else grep "^VM" $NMON_FILE | head -1 >$SADM_TMP_FILE2           # Linux Virt Mem.Header Line
             hd_pgin=` cat $SADM_TMP_FILE2 | awk -F, '{print $9}'`      # Header for pgin
             hd_pgout=`cat $SADM_TMP_FILE2 | awk -F, '{print $10}'`     # Header for pgout
             grep "^VM,T"   $NMON_FILE | sort >$SADM_TMP_FILE1          # Linux Virt Memory Activity
             NBLINES=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`       # Calc. Nb. of Virtual Lines
             sadm_writelog "Processing $NMON_OS Paging Activity '^VM,T'  Lines ($NBLINES elements)"
    fi
        
    while read wline                                                    # Read All Records
        do
        SNAPSHOT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`      # Get SnapShot Number
        INDX=`expr ${SNAPSHOT} + 0`                                     # Empty field are Zero now
        if [ "$NMON_OS" = "AIX" ]                                       # Dealing with Aix nmon file
            then PAGE_IN=` echo $wline | awk -F, '{ print $6 }'`        # AIX pgin stat.
                 PAGE_OUT=`echo $wline | awk -F, '{ print $7 }'`        # AIX pgout stat.
            else PAGE_IN=` echo $wline | awk -F, '{ print $9 }'`        # LINUX pgin stat.
                 PAGE_OUT=`echo $wline | awk -F, '{ print $10 }'`       # LINUX pgout stat.
        fi
        ARRAY_PAGING[$INDX]="${PAGE_IN},${PAGE_OUT}"                    # Put Stat. in Array
        
        # If Debug is Activated
        if [ $DEBUG_LEVEL -gt 4 ]
            then sadm_writelog "Paging line is $wline"
                 sadm_writelog "$SNAPSHOT  ${hd_pgin} = $PAGE_IN  ${hd_pgout} = $PAGE_OUT"
        fi    
        done <  $SADM_TMP_FILE1
    #sadm_writelog "End of collecting Paging Activity information"
}



#===================================================================================================
#                        Commands run at the end of the script
#===================================================================================================
rrd_update()
{
    TOTAL_ERROR=0 ; TOTAL_SUCCESS=0 ; TOTAL_WARNING=0 ;                 # Set Total Err-Warn-Success
    sadm_writelog "Updating RRD Database ${RRD_FILE}"                   # Starting RRD Update
    for (( i = 1 ; i <= ${#ARRAY_TIME[@]} ; i++ ))                      # Process time Array Size
        do
        ERROR_COUNT=0 ; SUCCESS=0                                       # Reset Error Success Count
        if [ $DEBUG_LEVEL -gt 1 ]                                       # Debug Activated
            then sadm_writelog "ARRAY_TIME  [$i]: ${ARRAY_TIME[$i]}"    # Show Time of Snapshot
        fi
    
        A_EPOCH=`echo ${ARRAY_TIME[$i]}          | awk -F, '{ print $1}'`
        A_DATE=`echo ${ARRAY_TIME[$i]}           | awk -F, '{ print $2}'`
        A_USER=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $1}'`
        A_SYST=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $2}'`
        A_WAIT=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $3}'`
        A_IDLE=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $4}'`
        A_TOTAL=`echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $5}'`
        A_RUNQ=`echo ${ARRAY_RUNQ[$i]}           | awk -F, '{ print $1}'`
        A_DISKREAD=`echo ${ARRAY_DISKREAD[$i]}   | awk -F, '{ print $1}'`
        A_DISKWRITE=`echo ${ARRAY_DISKWRITE[$i]} | awk -F, '{ print $1}'`
        A_MEM_TOTAL=`echo ${ARRAY_MEMORY[$i]}    | awk -F, '{ print $1}'`
        A_MEM_FREE=`echo ${ARRAY_MEMORY[$i]}     | awk -F, '{ print $2}'`
        A_MEM_USED=`echo ${ARRAY_MEMORY[$i]}     | awk -F, '{ print $3}'`
        A_VIR_TOTAL=`echo ${ARRAY_MEMORY[$i]}    | awk -F, '{ print $4}'`
        A_VIR_FREE=`echo ${ARRAY_MEMORY[$i]}     | awk -F, '{ print $5}'`
        A_VIR_USED=`echo ${ARRAY_MEMORY[$i]}     | awk -F, '{ print $6}'`
        A_PAGE_IN=`echo ${ARRAY_PAGING[$i]}      | awk -F, '{ print $1}'`
        A_PAGE_OUT=`echo ${ARRAY_PAGING[$i]}     | awk -F, '{ print $2}'`
        A_ETHA_READ=`echo ${ARRAY_NET[$i]}       | awk -F, '{ print $1}'`
        A_ETHB_READ=`echo ${ARRAY_NET[$i]}       | awk -F, '{ print $2}'`
        A_ETHC_READ=`echo ${ARRAY_NET[$i]}       | awk -F, '{ print $3}'`
        A_ETHD_READ=`echo ${ARRAY_NET[$i]}       | awk -F, '{ print $4}'`
        A_ETHA_WRITE=`echo ${ARRAY_NET[$i]}      | awk -F, '{ print $5}'`
        A_ETHB_WRITE=`echo ${ARRAY_NET[$i]}      | awk -F, '{ print $6}'`
        A_ETHC_WRITE=`echo ${ARRAY_NET[$i]}      | awk -F, '{ print $7}'`
        A_ETHD_WRITE=`echo ${ARRAY_NET[$i]}      | awk -F, '{ print $8}'`
        A_MPROCESS=`echo ${ARRAY_MEMNEW[$i]}     | awk -F, '{ print $1}'` 
        A_MFSCACHE=`echo ${ARRAY_MEMNEW[$i]}     | awk -F, '{ print $2}'` 
        A_MSYSTEM=`echo ${ARRAY_MEMNEW[$i]}      | awk -F, '{ print $3}'` 
        A_MFREE=`echo ${ARRAY_MEMNEW[$i]}        | awk -F, '{ print $4}'` 
        A_MPINNED=`echo ${ARRAY_MEMNEW[$i]}      | awk -F, '{ print $5}'` 
        A_MUSER=`echo ${ARRAY_MEMNEW[$i]}        | awk -F, '{ print $6}'` 
        
        if [ "$A_ETHA_READ" = "" ]   ; then A_ETHA_READ="0.0"  ; fi
        if [ "$A_ETHB_READ" = "" ]   ; then A_ETHB_READ="0.0"  ; fi 
        if [ "$A_ETHC_READ" = "" ]   ; then A_ETHC_READ="0.0"  ; fi 
        if [ "$A_ETHD_READ" = "" ]   ; then A_ETHD_READ="0.0"  ; fi 
        if [ "$A_ETHA_WRITE" = "" ]  ; then A_ETHA_WRITE="0.0" ; fi 
        if [ "$A_ETHB_WRITE" = "" ]  ; then A_ETHB_WRITE="0.0" ; fi 
        if [ "$A_ETHC_WRITE" = "" ]  ; then A_ETHC_WRITE="0.0" ; fi 
        if [ "$A_ETHD_WRITE" = "" ]  ; then A_ETHD_WRITE="0.0" ; fi 
        if [ "$A_MPROCESS" = "" ]    ; then A_MPROCESS="0.0"   ; fi
        if [ "$A_MFSCACHE" = "" ]    ; then A_MFSCACHE="0.0"   ; fi
        if [ "$A_MSYSTEM" = "" ]     ; then A_MSYSTEM="0.0"    ; fi 
        if [ "$A_MFREE" = "" ]       ; then A_MFREE="0.0"      ; fi
        if [ "$A_MPINNED" = "" ]     ; then A_MPINNED="0.0"    ; fi
        if [ "$A_MUSER" = "" ]       ; then A_MUSER="0.0"      ; fi

        if [ $DEBUG_LEVEL -gt 6 ]
        then sadm_writelog "Values before running the rrdupdate"
             sadm_writelog "SNAPSHOT    =   $i"            
             sadm_writelog "A_DATE      =   ..${A_DATE}.."            
             sadm_writelog "A_EPOCH     =   ..${A_EPOCH}.."            
             sadm_writelog "A_USER      =   ..${A_USER}.."
             sadm_writelog "A_SYST      =   ..${A_SYST}.."            
             sadm_writelog "A_WAIT      =   ..${A_WAIT}.."            
             sadm_writelog "A_IDLE      =   ..${A_IDLE}.."            
             sadm_writelog "A_TOTAL     =   ..${A_TOTAL}.."            
             sadm_writelog "A_RUNQ      =   ..${A_RUNQ}.."            
             sadm_writelog "A_DISKREAD  =   ..${A_DISKREAD}.."            
             sadm_writelog "A_DISKWRITE =   ..${A_DISKWRITE}.."            
             sadm_writelog "A_MEM_TOTAL =   ..${A_MEM_TOTAL}.."            
             sadm_writelog "A_MEM_FREE  =   ..${A_MEM_FREE}.."            
             sadm_writelog "A_MEM_USED  =   ..${A_MEM_USED}.."            
             sadm_writelog "A_VIR_TOTAL =   ..${A_VIR_TOTAL}.."            
             sadm_writelog "A_VIR_FREE  =   ..${A_VIR_FREE}.."            
             sadm_writelog "A_VIR_USED  =   ..${A_VIR_USED}.."            
             sadm_writelog "A_PAGE_OUT  =   ..${A_PAGE_OUT}.."            
             sadm_writelog "A_PAGE_IN   =   ..${A_PAGE_IN}.."            
             sadm_writelog "A_ETHA_READ =   ..${A_ETHA_READ}.."            
             sadm_writelog "A_ETHA_WRITE=   ..${A_ETHA_WRITE}.."            
             sadm_writelog "A_ETHB_READ =   ..${A_ETHB_READ}.."            
             sadm_writelog "A_ETHB_WRITE=   ..${A_ETHB_WRITE}.."            
             sadm_writelog "A_ETHC_READ =   ..${A_ETHC_READ}.."            
             sadm_writelog "A_ETHC_WRITE=   ..${A_ETHC_WRITE}.."            
             sadm_writelog "A_ETHD_READ =   ..${A_ETHD_READ}.."            
             sadm_writelog "A_ETHD_WRITE=   ..${A_ETHD_WRITE}.."            
             sadm_writelog "A_MPROCESS  =   ..${A_MPROCESS}.."
             sadm_writelog "A_MFSCACHE  =   ..${A_MFSCACHE}.."
             sadm_writelog "A_MSYSTEM   =   ..${A_MSYSTEM}.."
             sadm_writelog "A_MFREE     =   ..${A_MFREE}.."
             sadm_writelog "A_MPINNED   =   ..${A_MPINNED}.."
             sadm_writelog "A_MUSER     =   ..${A_MUSER}.."
        fi
       

        field_name1="cpu_user:cpu_sys:cpu_wait:cpu_idle:cpu_total:proc_runq:"
        field_name2="disk_kbread_sec:disk_kbwrtn_sec:mem_free:mem_used:mem_total:"
        field_name3="page_in:page_out:"
        field_name4="etha_readkbs:ethb_readkbs:ethc_readkbs:ethd_readkbs:"
        field_name5="etha_writekbs:ethb_writekbs:ethc_writekbs:ethd_writekbs:"
        field_name6="page_free:page_used:page_total:"
        field_name7="mem_new_proc:mem_new_fscache:mem_new_system:mem_new_free:mem_new_pinned:mem_new_user"
        field_name="${field_name1}${field_name2}${field_name3}${field_name4}${field_name5}${field_name6}${field_name7}"
        
        field_value1="${A_USER}:${A_SYST}:${A_WAIT}:${A_IDLE}:${A_TOTAL}:${A_RUNQ}:"
        field_value2="${A_DISKREAD}:${A_DISKWRITE}:${A_MEM_FREE}:${A_MEM_USED}:${A_MEM_TOTAL}:"
        field_value3="${A_PAGE_IN}:${A_PAGE_OUT}:"
        field_value4="${A_ETHA_READ}:${A_ETHB_READ}:${A_ETHC_READ}:${A_ETHD_READ}:"
        field_value5="${A_ETHA_WRITE}:${A_ETHB_WRITE}:${A_ETHC_WRITE}:${A_ETHD_WRITE}:"
        field_value6="${A_VIR_FREE}:${A_VIR_USED}:${A_VIR_TOTAL}:"
        field_value7="${A_MPROCESS}:${A_MFSCACHE}:${A_MSYSTEM}:${A_MFREE}:${A_MPINNED}:${A_MUSER}"
        field_value="${field_value1}${field_value2}${field_value3}${field_value4}${field_value5}${field_value6}${field_value7}"

        RRD_LAST_EPOCH=`${RRDTOOL} last ${RRD_FILE}`                    # Get RRD Last Epoch Update
        if [ "${A_EPOCH}" = "" ]                                        # If Epoch is Blank ?
            then sadm_writelog "Epoch time invalid (${A_EPOCH}) can't run rrdupdate"
                 RC=1
            else if [ ${A_EPOCH} -le $RRD_LAST_EPOCH ]                  #epoch<=last epoch Upd. done
                    then sadm_writelog "[WARNING] NMON Epoch Time (${A_EPOCH}) <= last epoch (${RRD_LAST_EPOCH}) in RRD"
                         TOTAL_WARNING=$(($TOTAL_WARNING+1))            # Increment Total Warning 
                         RC=0
                    else if [ $DEBUG_LEVEL -gt 0 ] 
                            then sadm_writelog "$RRDUPDATE ${RRD_FILE} -t ${field_name} ${A_EPOCH}:${field_value}"
                         fi
                         $RRDUPDATE ${RRD_FILE} -t ${field_name} ${A_EPOCH}:${field_value} >>$SADM_LOG 2>&1
                         RC=$?
                 fi
        fi
        if [ $RC -ne 0 ] 
            then TOTAL_ERROR=$(($TOTAL_ERROR+1))                        # Increment Total Error  
                 if [ $DEBUG_LEVEL -gt 0 ] 
                    then sadm_writelog "$RRDUPDATE ${RRD_FILE} -t ${field_name} ${A_EPOCH}:${field_value}"
                         sadm_writelog "[ERROR] Return Code $RC"
                 fi
            else TOTAL_SUCCESS=$(($TOTAL_SUCCESS+1))                    # Increment Total Counter 
                 if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "[Success] Return Code $RC" ; fi
        fi
        done
    
    if [ $TOTAL_ERROR -ne 0 ] || [ $TOTAL_WARNING -ne 0 ]
        then MSG="UPDATE SUMMARY FOR $NMON_HOST - TOTAL: "
             MSG="$MSG $TOTAL_SUCCESS success, $TOTAL_ERROR error(s), "
             MSG="$MSG $TOTAL_WARNING warning."
             sadm_writelog "$MSG"
        else sadm_writelog "[SUCCESS] Updating $NMON_HOST RRD Database ($TOTAL_SUCCESS)"
    fi

    # Clear all Arrays before beginning next SnapShot
    unset ARRAY_TIME ARRAY_CPU      ARRAY_RUNQ      ARRAY_DISKREAD ARRAY_DISKWRITE  
    unset ARRAY_NET  ARRAY_MEMNEW   ARRAY_PAGING    ARRAY_MEMORY
    #sadm_writelog "End of RRD Update" 
    return $ERROR_COUNT
}





#===================================================================================================
#                               Main process of the script is Here
#===================================================================================================
main_process()
{
    ERROR_COUNT=0                                                       # Set Error counter to zero
    NMON_COUNT=0                                                        # Process NMON file counter 
    
    # Produce a list of all Yesterday nmon file (sorted) or use file passed with -f command line
    YESTERDAY=`date -d "1 day ago" '+%y%m%d'`                           # Get Yesterday Date
    if [ "$CMD_FILE" != "" ] 
        then echo "$CMD_FILE" > $NMON_FILE_LIST
        else find $SADM_WWW_DAT_DIR -type f -name "*_${YESTERDAY}_*.nmon" |sort > $NMON_FILE_LIST
    fi
            
    # 
    sadm_writelog "List of nmon files we are about to process :" 
    sadm_writelog "find $SADM_WWW_DAT_DIR -type f -name \"*_${YESTERDAY}_*.nmon\""
    filecount=0
    cat $NMON_FILE_LIST |  while read wline 
        do 
        filecount=$(($filecount+1))                                     # Increment File Counter 
        snapshotcount=`grep "ZZZZ,T" $wline | wc -l`                    # Cnt SnapSHot in nmon file
        sadm_writelog " ${filecount})  There is $snapshotcount snapshots in $wline"   
        done

    while read NMON_FILE                                                # Process nmon file 1 by 1
        do
        NMON_COUNT=$(($NMON_COUNT+1))                                   # Increment Error Counter 
        sadm_writelog " " 
        sadm_writelog "`printf %10s |tr ' ' '-'`"                       # Write Dash Line to Log
        sadm_writelog "[${NMON_COUNT}] Processing $NMON_FILE"           # Show User File Processing
        
        # If Nmon file is not readable- Advise and skip 
        if  [ ! -r "$NMON_FILE" ]                                       # If file is not redeable
            then  sadm_writelog "Skipping File $NMON_FILE Not Readable" # Show User file is skipped
                  ERROR_COUNT=$(($ERROR_COUNT+1))                       # Increment Error Counter 
                  continue                                              # Continue with next file
        fi

        # Minimum test to insure that the file is a nmon 
        grep "^AAA,host" $NMON_FILE >/dev/null 2>&1                     # Must Have AAA.host line
        if [ $? -ne 0 ]                                                 # Not an nmon file
            then  sadm_writelog "File is not a valid NMON file."        # Advise user we skip file
                  ERROR_COUNT=$(($ERROR_COUNT+1))                       # Increment Error Counter 
                  continue                                              # Continue with next file
        fi

        # Get Nmon file Info & Setup RRD Dir & File
        read_nmon_info_and_setup_rrd                                    # Create RRD Dir & File
        if [ $? -ne 0 ]                                                 # Not an nmon file
            then  sadm_writelog "Problem found with NMON file $NMON_FILE" # Advise user 
                  ERROR_COUNT=$(($ERROR_COUNT+1))                       # Increment Error Counter 
                  continue                                              # Continue with next file
        fi
        #sadm_writelog "Empty rrd created"
        #exit 

        # Build an Array indexed by Snotshot Number for Each data we want to collect
        build_epoch_array                                               # Put Snapshot/Epoch Array
        build_cpu_array                                                 # Put CPU stat in Array
        build_runqueue_array                                            # Put RunQueue in Array
        build_disk_read_array                                           # Build Disk Read Array
        build_disk_write_array                                          # Build Disk Write Array
        build_memory_array                                              # Real/Vir Mem Stat Array
        build_paging_activity_array                                     # Pagein/PageOut Array
        build_net_array                                                 # Build Network Activity Array
        build_memnew_array                                              # Aix nmon Build MemNew
        rrd_update                                                      # Update RRD from arrays 
        done < $NMON_FILE_LIST

        # Remove Temporary file
        if [ -r $NMON_FILE_LIST ] ; then rm -f $NMON_FILE_LIST ; fi
}

 
#===================================================================================================
#                                       Script Start HERE
#===================================================================================================


# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:f:" opt ; do                                     # Loop to process Switch
        case $opt in
            f) CMD_FILE=$OPTARG                                         # Get nmon Filename Specify
               if [ ! -r "$CMD_FILE" ]                                  # If file not readable
                    then sadm_writelog "Nmon File $CMD_FILE not found"  # Show User Error 
                         sadm_stop 0
                         exit 0
               fi
               ;;                                                       # No stop after each page
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$DEBUG_LEVEL" | grep -E ^\-?[0-9]?\.?[0-9]+$` #
               if [ "$num" = "" ] 
                  then printf "\nDebug Level specified is invalid\n" 
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi

# Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

# If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

# If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
#    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
#        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
#             sadm_writelog "Process aborted"                            # Abort advise message
#             sadm_stop 1                                                # Close/Trim Log & Del PID
#             exit 1                                                     # Exit To O/S with error
#    fi


# Check Availibilty of rrdupdate and cut command
    RRDUPDATE=`which rrdupdate 2>/dev/null` ; export RRDUPDATE          # Get Location of rrdupdate
    if [ $? -ne 0 ]                                                     # Command rrdupdate Not Avail.
        then sadm_writelog "Script aborted : rrdupdate command not found" # Show User Error
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi
    RRDTOOL=`which rrdtool 2>/dev/null` ; export RRDTOOL                # Get Location of rrdtool
    if [ $? -ne 0 ]                                                     # Command rrdtool Not Avail.
        then sadm_writelog "Script aborted : rrdtool command not found" # Show User Error
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi
    RRDUPDATE="$RRDTOOL update"  ; export RRDUPDATE          # Get Location of rrdupdate
    CUT=`which cut 2>/dev/null`                 ; export CUT            # Get Path to cut command
    if [ $? -ne 0 ]                                                     # cut Command not found
        then sadm_writelog "Script aborted : 'cut' command not found"   # Show User Error
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi

    main_process                                                        # Execute the main process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

# SADMIN Closing procedure - Close/Trim log and rch file, Remove PID File, Send email if requested
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    