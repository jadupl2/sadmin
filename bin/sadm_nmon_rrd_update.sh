#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis 
#   Title       :   sadm_nmon_rrd_update.sh
#   Synopsis    :   Script to Update the RRD (Roud Robin Database) Stat. file from nmon output file.
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

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_01_13 JDuplessis V1.0 - Initial Version
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.0'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#




#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
USAGE="Usage : ${SADM_PN} [nmon-file]"           ; export USAGE              # Script Usage Message

                                                                        # 9=Huge Output
DASH=`printf %100s | tr " " "-"`            ; export DASH               # 80 dashes
RC=0                                        ; export RC                 # Script Return Code
OSNAME=`uname -s |tr '[:lower:]' '[:upper:]'`; export OSNAME             # Get OS Name (AIX or Linux)
CUR_DATE=`date +"%Y_%m_%d"`                 ; export CUR_DATE           # Current Date
CUR_TIME=`date +"%H_%M_%S"`                 ; export CUR_TIME           # Current Time
CUR_DATE=`date +"%Y-%m-%d"`                 ; export CUR_DATE           # Current Date ("2013-01-30")
#   
NMON_FILE_LIST="${SADM_WWW_TMP_DIR}/nmon_list.$$"    ; export NMON_FILE_LIST     # NMON File List
NMON_FILE="${TMP_DIR}/nmon_file.$$"         ; export NMON_FILE          # Sorted nmon file 4 processing
LOG="${RC_DIR}/${INST}.log"                 ; export LOG                # Script LOG
RCLOG="${RC_DIR}/rc.${HOSTNAME}.${INST}.log"; export RCLOG              # xSCOM event log Result file
#
# RRD Custom Variables
RRD_DIR="Will be set later on"              ; export RRD_DIR            # RRD Directory Location
RRD_FILE="Will be set later on"             ; export RRD_FILE           # RRD Filename for nmon file
RRD_OWNER="jadupl2"                         ; export RRD_OWNER          # RRD Dir. & File Owner Name
RRD_GROUP="apache"                          ; export RRD_GROUP          # RRD Dir. & File Group Name
RRD_FILE_PERM="664"                         ; export RRD_FILE_PROT      # RRD File Permission
RRD_DIR_PERM="775"                          ; export RRD_DIR_PROT       # RRD Dir Permission

# Check Availibilty of needed commands
RRDTOOL=`which rrdtool 2>/dev/null`         ; export RRDTOOL   	        # Get Location of rrdtool
if [ $? -ne 0 ] ; then sadm_writelog "Script aborted : Command rrdtool not available" ; exit 1 ; fi
#
CUT=`which cut 2>/dev/null`                 ; export CUT                # Get Path to cut command
if [ $? -ne 0 ] ; then sadm_writelog "Script aborted : Command cut not available" ; exit 1 ; fi
#





#===================================================================================================
#                   Get Info about nmon file before we start processing it.
#===================================================================================================
read_nmon_info_and_setup_rrd()
{
    sadm_writelog "NMON FILE NAME= $NMON_FILE"                          # Display Name of NMON File        
    
    # Get HostName from nmon file
    NMON_HOST=`grep "^AAA,host" $NMON_FILE | awk -F, '{ print $3 }'`    # Get HostName from nmon file
    
    # Get The Nmon Operating System - Aix got no AAA,OS Line in nmon file
    grep -i "^AAA,AIX," $NMON_FILE > /dev/null 2>&1                     # Check if it is an AIX nmon
    if [ $?  -eq 0 ]                                                    # Yes it is an Aix nmon
       then NMON_OS=Aix                                                 # Set NMON_OS to aix
       else NMON_OS=`grep "^AAA,OS" $NMON_FILE |awk -F, '{ print $3 }'` # Get OS Name
    fi 
    NMON_OS=`echo $NMON_OS | tr '[:lower:]' '[:upper:]'`                # Make all O/S Uppercase
    
    # Validate O/S - Only Aix and Linux Supported
    if [ "$NMON_OS" != "AIX" ] &&  [ "$NMON_OS" != "LINUX" ]            # Advise if Unsupported O/S
        then sadm_writelog "Operating System $NMON_OS is not supported" # Show user it's unsupported
             sadm_writelog "Only Linux and Aix are supported"           # Show Supported O/S
             return 1                                                   # Return Error to Caller
    fi
    
    # Get The Number of Snapshot in current file
    NMON_SNAPSHOTS=`grep "^AAA,snapshots" $NMON_FILE | awk -F, '{ print $3 }'`
    
    # Get the number of Monitoring Intervals (Usually 300 Sec. / 5 min.)
    NMON_INTERVAL=`grep "^AAA,interval" $NMON_FILE | awk -F, '{ print $3 }'`
    
    # If RRD Directory doesn't exist - then create it
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
        then sadm_writelog "Creating RRD File for $NMON_HOST Host ($RRD_FILE)."
             $RRDTOOL create $RRD_FILE                       \
                --start "00:00 01.01.2013" --step 300   \
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
                DS:eth0_readkbs:GAUGE:1200:0:U         \
                DS:eth1_readkbs:GAUGE:1200:0:U         \
                DS:eth2_readkbs:GAUGE:1200:0:U         \
                DS:eth0_writekbs:GAUGE:1200:0:U        \
                DS:eth1_writekbs:GAUGE:1200:0:U        \
                DS:eth2_writekbs:GAUGE:1200:0:U        \
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
#                              Display CPU Array in Memory
#===================================================================================================
display_cpu_array()
{
    echo "Number of element in CPU array is ${#ARRAY_CPU[*]}"
    for (( i = 1 ; i <= ${#ARRAY_CPU[@]} ; i++ ))
        do
        sadm_writelog "CPU Array Index [$i]: Value : ${ARRAY_CPU[$i]}"
        done        
}






#===================================================================================================
#                      Collect CPU Stat and put them in the ARRAY_CPU 
#===================================================================================================
#
# ======== Aix nmon lines
# 6767 CPU_ALL,CPU Total spet1008,User%,Sys%,Wait%,Idle%,Busy,PhysicalCPUs
# 6768 CPU_ALL,T0001,29.2,4.8,14.0,52.1,,8
# 6769 CPU_ALL,T0002,40.3,2.5,2.1,55.2,,8
#
# ======== Linux nmon lines
# 5588 CPU_ALL,CPU Total lxmq1001,User%,Sys%,Wait%,Idle%,Busy,CPUs
# 5589 CPU_ALL,T0001,14.5,13.6,17.8,54.1,,16
# 5590 CPU_ALL,T0002,13.1,5.4,4.4,77.1,,16
#===================================================================================================
build_cpu_array()
{
    sadm_writelog "Processing CPU usage information."
    # Isolate CPU_ALL Records
    grep "^CPU_ALL" $NMON_FILE | grep -iv "User%,Sys%,Wait%" | sort >$TMP_FILE 
    
    while read wline                                                    # Read All CPU_ALL Records
        do
        NTIME=`echo $wline | cut -d, -f 2 | cut -c2-5`                  # Get SnapShot Number
        NUSER=`echo $wline | awk -F, '{ print $3 }'`                    # Get User CPU % Rounded
        if [ "$NUSER" = "" ] ; then NUSER=0.0 ; fi                      # If Not Specified then 0.0
        NSYST=`echo $wline |  awk -F, '{ print $4 }'`                   # Get System CPU % Rounded
        if [ "$NSYST" = "" ] ; then NSYST=0.0 ; fi                      # If Not Specified then 0.0
        NWAIT=`echo $wline |  awk -F, '{ print $5 }'`                   # Get Wait CPU % Rounded
        if [ "$NWAIT" = "" ] ; then NWAIT=0.0 ; fi                      # If Not Specified then 0.0
        NIDLE=`echo $wline |  awk -F, '{ print $6 }'`                   # Get Idle CPU % Rounded
        if [ "$NIDLE" = "" ] ; then NIDLE=0.0 ; fi                      # If Not Specified then 0.0
        NTOTAL=`echo $NUSER + $NSYST + $NWAIT | bc -l `                 # Field Total CPU Usage

        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now
        ARRAY_CPU[$INDX]="${NUSER},${NSYST},${NWAIT},${NIDLE},${NTOTAL}" # Put Stat. in Array
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -ne 0 ]
            then sadm_writelog "-----\nLINE   = $wline"
                 if [ $DEBUG_LEVEL -gt 1 ]
                    then    sadm_writelog "NTIME  = $NTIME"
                            sadm_writelog "NUSER  = $NUSER"
                            sadm_writelog "NSYST  = $NSYST"
                            sadm_writelog "NWAIT  = $NWAIT"
                            sadm_writelog "NIDLE  = $NIDLE"
                            sadm_writelog "NTOTAL = $NTOTAL"
                 fi
                 sadm_writelog "INDEX = $INDX - ${ARRAY_CPU[${INDX}]}"        
        fi    
        done <  $TMP_FILE
    sadm_writelog "End of CPU usage information."

}





#===================================================================================================
#                              Display Epoch Array in Memory
#===================================================================================================
display_epoch_array()
{
    echo "Number of element in SnapShot/Epoch array is ${#ARRAY_TIME[*]}"
    for (( i = 1 ; i <= ${#ARRAY_TIME[@]} ; i++ ))
        do
        sadm_writelog "SnapShot/Epoch Array Index [$i]: Value : ${ARRAY_TIME[$i]}"
        done        
}






#===================================================================================================
#                      Build Epoch Array Based on ZZZZ Records in nmon file
#===================================================================================================
build_epoch_array()
{
    sadm_writelog "Processing ZZZZ Time Lines."

    grep "^ZZZZ" $NMON_FILE | sort > $TMP_FILE                          # Isolate ZZZZ Rec. in tmp file
    while read wline                                                    # Process all Temp file
    do
        ZCOUNT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`        # Get SnapShot Number
        ZCOUNT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`        # Get SnapShot Number
        ZTIME=`echo  $wline | awk -F, '{ print $3 }'`                   # Get Time of SnapShot
        ZDATE=`echo  $wline | awk -F, '{ print $4 }'`                   # Get Date of SnapShot

        ZHRS=`echo  $ZTIME  | awk -F: '{ print $1 }'`                   # Get Hrs from Time
        ZMIN=`echo  $ZTIME  | awk -F: '{ print $2 }'`                   # Get Min from Time
        ZSEC=`echo  $ZTIME  | awk -F: '{ print $3 }'`                   # Get Sec from Time
        
        ZDD=`echo  $ZDATE  | awk -F- '{ print $1 }'`                    # Get Day from Date
        ZYY=`echo  $ZDATE  | awk -F- '{ print $3 }'`                    # Get Year from Date

        # Get Uppercase Month Name
        ZMONTH=`echo $ZDATE |awk -F- '{ print $2 }'| tr '[:lower:]' '[:upper:]'` 
        
        # Convert Month Name into Number
        case $ZMONTH in
            JAN) ZMM=1 ;;
            FEB) ZMM=2 ;;
            MAR) ZMM=3 ;;
            APR) ZMM=4 ;;
            MAY) ZMM=5 ;;
            JUN) ZMM=6 ;;
            JUL) ZMM=7 ;;
            AUG) ZMM=8 ;;
            SEP) ZMM=9 ;;
            OCT) ZMM=10 ;;
            NOV) ZMM=11 ;;
            DEC) ZMM=12 ;;
        esac
        
        NMON_EPOCH=`$EPOCH "$ZYY $ZMM $ZDD $ZHRS $ZMIN $ZSEC"`          # Convert Date to epoch
        if [ $DEBUG_LEVEL -ne 0 ]                                             # If Debug Activated
            then  sadm_writelog "Processing ZZZ Line : $wline"
                  sadm_writelog "Date ${ZDD}/${ZMM}/${ZYY} ${ZHRS}:${ZMIN}:${ZSEC} in Epoch is $NMON_EPOCH"
        fi
        ZCOUNT=`expr ${ZCOUNT} + 0`                                     # Make sure in numeric

        # Store Epoch and Date/Time in Snapshot Array
        ARRAY_TIME[$ZCOUNT]="${NMON_EPOCH},${ZDD}/${ZMM}/${ZYY} ${ZHRS}:${ZMIN}:${ZSEC}"
        done <  $TMP_FILE
    sadm_writelog "End of Processing ZZZZ Time Lines."
        
        

}




#===================================================================================================
#                      Collect RunQueue Stat and put them in the RUNQ_CPU 
#===================================================================================================
#
# ======== Aix nmon lines
# PROC,Processes spet1008,Runnable,Swap-in,pswitch,syscall,read,write,fork,exec,sem,msg
# PROC,T0005,19.66,0.03,2754,60601,1905,254,8,9,0,0
#
# ======== Linux nmon lines
# PROC,Processes lxmq1001,Runnable,Swap-in,pswitch,syscall,read,write,fork,exec,sem,msg
# PROC,T0001,6.0,-1.0,0.0,-1.0,-1.0,-1.0,0.0,-1.0,-1.0,-1.0
# PROC,T0002,7.0,-1.0,42170.9,-1.0,-1.0,-1.0,47.5,-1.0,-1.0,-1.0
#
#===================================================================================================
build_runqueue_array()
{
    sadm_writelog "Processing RunQueue information."
    # Isolate PROC,T Records
    grep "^PROC,T" $NMON_FILE | sort >$TMP_FILE 
    
    while read wline                                                    # Read All Records
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`         # Get SnapShot Number
#        NRUNQ=`echo $wline | awk -F, '{ print int($3+0.5)}'`            # Get RunQueue Rounded
        NRUNQ=`echo $wline | awk -F, '{ print $3 }'`            # Get RunQueue Rounded
        if [ "$NRUNQ" = "" ] ; then NRUNQ=0.0 ; fi                      # If Not Specified then 0.0

        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now
        ARRAY_RUNQ[$INDX]="${NRUNQ}"                                    # Put Stat. in Array
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -ne 0 ]
            then sadm_writelog "-----\nLINE   = $wline"
                 if [ $DEBUG_LEVEL -gt 1 ]
                    then    sadm_writelog "NTIME  = $NTIME"
                            sadm_writelog "NRUNQ  = $NRUNQ"
                 fi
                 sadm_writelog "INDEX = $INDX - ${ARRAY_RUNQ[${INDX}]}"        
        fi    
        done <  $TMP_FILE
    sadm_writelog "Finish collecting RunQueue information."
}








#===================================================================================================
#                      Collect Disk I/O Stat and put them in the ARRAY_DISKREAD
#===================================================================================================
#
# ======== Aix nmon lines
# DISKREAD,Disk Read KB/s
# spet1008,hdisk10,hdisk8,hdisk9,hdisk14,hdisk13,hdisk15,hdisk16,hdisk5,hdisk12,hdisk7,hdisk1
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
#
# ======== Linux nmon lines
# DISKREAD,Disk Read KB/s
# lxmq1001,cciss/c0d0,cciss/c0d0p1,cciss/c0d0p2,dm-0,dm-2,dm-3,dm-4,dm-5,dm-6,dm-7,dm-8,dm
# -9,dm-10,dm-11,dm-12,dm-13,dm-14,dm-15,sda,sda1,sdb,sdb1,sdc,sdc1,sdd,sdd1,sde,sdf,sdg,s
# dg1,sdh,sdh1,sdi,sdi1,sdj,sdj1,sdk,sdl,dm-16,dm-17,dm-18,dm-19,dm-20,dm-21,dm-22,dm-23,d
# m-24,dm-25,dm-26,dm-27,dm-28,dm-29,dm-30,dm-31,dm-32,dm-33,dm-34,dm-35,dm-36,dm-37,dm-38
# ,dm-39,dm-40,dm-41,dm-42,dm-43,dm-44,dm-45,dm-46,dm-47,dm-48,dm-49,dm-50,dm-51,dm-52,dm-
# 53,dm-54,dm-55,dm-56,dm-57,dm-58,dm-59,dm-60,dm-61,dm-62,dm-63,dm-64,dm-65,dm-66,dm-67,d
# m-68,dm-69,dm-70,dm-71,dm-75,dm-76,dm-77,dm-78,dm-79,dm-80,dm-81,dm-82,dm-83,dm-84,dm-85
# ,dm-86,dm-88,dm-89,dm-90,dm-91,dm-92,dm-93,dm-94,dm-95,dm-96,dm-97,dm-98,dm-99,dm-100,dm
# -101,dm-102,dm-103,dm-104,dm-105,dm-106,dm-107,dm-108,dm-109,dm-110,dm-111,dm-112,dm-113
# ,dm-114,dm-115,dm-116,sdm,sdm1,sdn,sdn1,sdo,sdo1,sdp,sdp1,dm-117,dm-118,dm-120,dm-121,dm
# -123,dm-124,dm-125
# DISKREAD,T0001,2862.6,0.0,2837.0,49.4,0.0,341.5,0.0,3.9,0.0,5.9,0.0,0.0,2.0,0.0,0.0,0.0,
# 0.0,0.0,25.7,0.0,536.5,484.7,77.0,51.3,79.0,53.3,67.1,25.7,603.6,552.3,25.7,0.0,1138.1,1
# 087.3,838.6,786.7,25.7,252.7,562.2,510.3,1162.3,854.4,41.5,211.2,828.7,484.7,1136.7,536.
# 5,0.0,0.0,0.0,0.0,422.5,0.0,0.0,505.4,0.0,7.9,0.0,525.1,0.0,0.0,0.0,0.0,0.0,0.0,154.0,0.
# 0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,98.7,0.0,854.8,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
# ,0.0,0.0,144.1,0.0,0.0,0.0,0.0,0.0,0.0,0.0,5.9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0
# .0,33.6,0.0,0.0,0.0,169.8,0.0,0.0,15.8,0.0,0.0,0.0,0.0,61.2,0.0,0.0,0.0,2.0,0.0,114.5,0.
# 0,0.0,0.0,0.0,0.0,130.3,79.0,458.0,406.7,25.7,0.0,25.7,0.0,104.6,398.8,0.0,0.0,0.0,0.0,0
#.0
#===================================================================================================
build_disk_read_array()
{
    sadm_writelog "Processing Disk Read information."
    # Isolate PROC,T Records
    grep "^DISKREAD,T" $NMON_FILE | sort >$TMP_FILE                     # Isolate Disk Read Line

    while read wline                                                    # Read All Records
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`         # Get SnapShot Number
        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now
        NCOUNT=`echo $wline | awk -F, '{ print NF }'`                   # Count No of fields on line
        if [ "$NCOUNT" = "" ] ; then NCOUNT=0.0 ; fi                    # If Not Specified then 0.0
        if [ $NCOUNT -eq 0  ] ; then break ; fi                         # If no comma ? = Nxt Line
        #if [ $OSNAME == "LINUX" ] ;then echo -n "." ;else echo ".\c" ;fi # Inform Ops on Nb Disks

        WTOTAL=0                                                        # Clear line total field
        if [ $DEBUG_LEVEL -eq 9 ] ; then sadm_writelog "Calculate Total of Line: $wline" ;fi
        for i in $(seq 3 $NCOUNT)                                       # Process all fields on line
            do
            WFIELD=`echo $wline | $CUT -d, -f $i`                       # Get Field on line
            WTOTAL=`echo $WTOTAL + $WFIELD | $BC -l `                   # Add Field to Line Total
            if [ $DEBUG_LEVEL -eq 9 ] ; then sadm_writelog "Added $WFIELD and Total is now $WTOTAL" ; fi
            done
        
        # Put Line total in the Disk Read Array - Convert Kb/s to Mb/s
        ARRAY_DISKREAD[$INDX]=`echo "${WTOTAL} / 1024"| $BC -l`         # Put Stat. in Array
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -gt 4 ]
            then sadm_writelog "-----\nLINE   = $wline"
                 if [ $DEBUG_LEVEL -gt 1 ]
                    then    sadm_writelog "NTIME  = $NTIME"
                            sadm_writelog "TOTAL_READ_KBS  = $WTOTAL"
                 fi
                 sadm_writelog "INDEX = $INDX - ${ARRAY_DISKREAD[${INDX}]}"        
        fi    
        done <  $TMP_FILE
    sadm_writelog "Finish collecting Disk Read information."
}




#===================================================================================================
#                      Collect Disk I/O Stat and put them in the ARRAY_DISKREAD
#===================================================================================================
#
# ======== Aix nmon lines
# DISKWRITE,Disk Write KB/s
# spet1008,hdisk10,hdisk8,hdisk9,hdisk14,hdisk13,hdisk15,hdisk16,hdisk5,hdisk12,hdisk7,hdisk1
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
#
# ======== Linux nmon lines
# DISKWRITE,Disk Write KB/s
# lxmq1001,cciss/c0d0,cciss/c0d0p1,cciss/c0d0p2,dm-0,dm-2,dm-3,dm-4,dm-5,dm-6,dm-7,dm-8,dm
# -9,dm-10,dm-11,dm-12,dm-13,dm-14,dm-15,sda,sda1,sdb,sdb1,sdc,sdc1,sdd,sdd1,sde,sdf,sdg,s
# dg1,sdh,sdh1,sdi,sdi1,sdj,sdj1,sdk,sdl,dm-16,dm-17,dm-18,dm-19,dm-20,dm-21,dm-22,dm-23,d
# m-24,dm-25,dm-26,dm-27,dm-28,dm-29,dm-30,dm-31,dm-32,dm-33,dm-34,dm-35,dm-36,dm-37,dm-38
# ,dm-39,dm-40,dm-41,dm-42,dm-43,dm-44,dm-45,dm-46,dm-47,dm-48,dm-49,dm-50,dm-51,dm-52,dm-
# 53,dm-54,dm-55,dm-56,dm-57,dm-58,dm-59,dm-60,dm-61,dm-62,dm-63,dm-64,dm-65,dm-66,dm-67,d
# m-68,dm-69,dm-70,dm-71,dm-75,dm-76,dm-77,dm-78,dm-79,dm-80,dm-81,dm-82,dm-83,dm-84,dm-85
# ,dm-86,dm-88,dm-89,dm-90,dm-91,dm-92,dm-93,dm-94,dm-95,dm-96,dm-97,dm-98,dm-99,dm-100,dm
# -101,dm-102,dm-103,dm-104,dm-105,dm-106,dm-107,dm-108,dm-109,dm-110,dm-111,dm-112,dm-113
# ,dm-114,dm-115,dm-116,sdm,sdm1,sdn,sdn1,sdo,sdo1,sdp,sdp1,dm-117,dm-118,dm-120,dm-121,dm
# -123,dm-124,dm-125
# 7901 DISKWRITE,T0001,469.9,0.0,469.9,0.0,0.0,0.0,0.0,469.9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.
# 0,0.0,0.0,0.0,223.1,223.1,51.3,51.3,49.4,49.4,26.2,0.0,244.8,244.8,0.0,0.0,140.2,140.2,5
# 3.3,53.3,0.0,381.0,244.8,223.1,191.5,102.7,25.7,381.0,102.7,223.1,191.5,244.8,0.0,0.0,11
# 4.5,0.0,272.4,0.0,0.0,51.3,0.0,29.6,0.0,15.8,0.0,0.0,0.0,0.0,0.0,0.0,15.8,0.0,0.0,0.0,0.
# 0,0.0,0.0,0.0,0.0,0.0,39.5,0.0,173.7,0.0,0.0,0.0,0.0,0.0,23.7,0.0,0.0,23.7,0.0,0.0,0.0,3
# 5.5,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,7.9,0.0,0.0,0.0,0.0,23.7,0.0,39.5,0.
# 0,0.0,0.0,9.9,0.0,0.0,25.7,0.0,7.9,0.0,5.9,92.3,0.0,0.0,0.0,0.0,0.0,160.4,0.0,0.0,0.0,23
# .7,0.0,0.0,0.0,149.1,149.1,0.0,0.0,0.0,0.0,0.0,149.1,0.0,0.0,0.0,0.0,0.0
# 7902 DISKWRITE,T0002,34330.0,0.0,34330.0,34.8,5.9,19.8,6.2,34206.8,0.0,18.4,0.0,0.0,25.7,1.1,
#.0
#===================================================================================================
build_disk_write_array()
{
    sadm_writelog "Processing Disk write information."
    # Isolate PROC,T Records
    grep "^DISKWRITE,T" $NMON_FILE | sort >$TMP_FILE 

    while read wline                                                    # Read All Records
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`         # Get SnapShot Number
        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now
        NCOUNT=`echo $wline | awk -F, '{ print NF }'`                   # Count No of fields on line
        if [ "$NCOUNT" = "" ] ; then NCOUNT=0.0 ; fi                    # If Not Specified then 0.0
        if [ $NCOUNT -eq 0  ] ; then break ; fi                         # If no comma ? = Nxt Line
        #if [ $OSNAME == "LINUX" ] ;then echo -n "." ;else echo ".\c" ;fi # Inform Ops on Nb Disks

        WTOTAL=0                                                        # Clear line total field
        if [ $DEBUG_LEVEL -eq 9 ] ; then sadm_writelog "Calculate Total of Line: $wline" ;fi
        for i in $(seq 3 $NCOUNT)                                       # Process all fields on line
            do
            WFIELD=`echo $wline | $CUT -d, -f $i`                       # Get Field on line
            WTOTAL=`echo $WTOTAL + $WFIELD | $BC -l `                   # Add Field to Line Total
            if [ $DEBUG_LEVEL -eq 9 ] ; then sadm_writelog "Added $WFIELD and Total is now $WTOTAL" ; fi
            done
        
        ARRAY_DISKWRITE[$INDX]=`echo "${WTOTAL} / 1024"| $BC -l`         # Put Stat. in Array
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -gt 4 ]
            then sadm_writelog "-----\nLINE   = $wline"
                 if [ $DEBUG_LEVEL -gt 1 ]
                    then    sadm_writelog "NTIME  = $NTIME"
                            sadm_writelog "TOTAL_READ_KBS  = $WTOTAL"
                 fi
                 sadm_writelog "INDEX = $INDX - ${ARRAY_DISKWRITE[${INDX}]}"        
        fi    
        done <  $TMP_FILE
    sadm_writelog "Finish collecting Disk Write information."
}


#===================================================================================================
#                      Collect Network Stat and put them in the ARRAY_NET
#===================================================================================================
#
# ======== Aix nmon lines
# NET,Network I/O spet1008,en0-read-KB/s,en1-read-KB/s,en2-read-KB/s,lo0-read-KB/s,en0-write-KB/s,
# en1-write-KB/s,en2-write-KB/s,lo0-write-KB/s
# NET,T0001,167.1,0.7,0.0,21.6,59.0,0.0,0.0,21.6
# NET,T0002,27.4,0.6,0.0,3.4,12.3,0.0,0.0,3.4
# NET,T0003,43.0,1.2,0.0,2.8,16.6,313.9,0.0,2.8
#
# ======== Linux nmon lines
# NET,Network I/O lxmq1001,lo-read-KB/s,eth0-read-KB/s,eth1-read-KB/s,eth2-read-KB/s,eth3-read-KB/s,
# sit0-read-KB/s,lo-write-KB/s,eth0-write-KB/s,eth1-write-KB/s,eth2-write-KB/s,eth3-write-KB/s,
# sit0-write-KB/s,
# NET,T0001,5.1,253.4,0.7,0.0,0.0,0.0,5.1,425.5,0.0,0.0,0.0,0.0,
# NET,T0002,79.9,313.2,13.2,0.0,0.0,0.0,79.9,1607.3,2790.8,0.0,0.0,0.0,
#===================================================================================================
#===================================================================================================
build_net_array()
{
    sadm_writelog "Processing Network Activity Information."
    
    # Detect Number of field on Network Statistics Line
    NUM_FIELD=`grep "^NET,Network I/O" $NMON_FILE | awk -F, '{ print NF }'`
    if [ $DEBUG_LEVEL -gt 5 ]
        then sadm_writelog "Number of Field on Network Statistics Line Header: $NUM_FIELD"
    fi 
    

    # Make sure index are at zero, if no interface are found
    # ----------------------------------------------------------------------------------------------
    IF0_READ_IDX=0  ; IF1_READ_IDX=0    ; IF2_READ_IDX=0
    IF0_WRITE_IDX=0 ; IF1_WRITE_IDX=0   ; IF2_WRITE_IDX=0

    
    # Aix - Get Nb of the field for en0-read,en0-write,en1-read,en1-write,en2-read,en2-write
    # Linux - Get Nb of the field for eth0-read,eth0-write,eth1-read,eth1-write,eth2-read,eth2-write
    # ----------------------------------------------------------------------------------------------
    grep "^NET,Network" $NMON_FILE > $TMP2_FILE                         
    while read wline                   # Read Network Stat Lines
        do
        for i in $(seq 1 $NUM_FIELD)
            do
            if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "($i) Network Header Line is : $wline" ;fi
            WFIELD=`echo $wline | cut -d, -f $i`
            if [ "$NMON_OS" == "AIX" ] 
               then if [ "$WFIELD" == "en0-read-KB/s"  ]  ; then IF0_READ_IDX=$i  ; fi 
                    if [ "$WFIELD" == "en1-read-KB/s"  ]  ; then IF1_READ_IDX=$i  ; fi 
                    if [ "$WFIELD" == "en2-read-KB/s"  ]  ; then IF2_READ_IDX=$i  ; fi 
                    if [ "$WFIELD" == "en0-write-KB/s" ]  ; then IF0_WRITE_IDX=$i ; fi 
                    if [ "$WFIELD" == "en1-write-KB/s" ]  ; then IF1_WRITE_IDX=$i ; fi 
                    if [ "$WFIELD" == "en2-write-KB/s" ]  ; then IF2_WRITE_IDX=$i ; fi 
               else if [ "$WFIELD" == "eth0-read-KB/s" ]  ; then IF0_READ_IDX=$i  ; fi
                    if [ "$WFIELD" == "eth1-read-KB/s" ]  ; then IF1_READ_IDX=$i  ; fi
                    if [ "$WFIELD" == "eth2-read-KB/s" ]  ; then IF2_READ_IDX=$i  ; fi
                    if [ "$WFIELD" == "eth0-write-KB/s" ] ; then IF0_WRITE_IDX=$i ; fi
                    if [ "$WFIELD" == "eth1-write-KB/s" ] ; then IF1_WRITE_IDX=$i ; fi
                    if [ "$WFIELD" == "eth2-write-KB/s" ] ; then IF2_WRITE_IDX=$i ; fi
            fi
            done
        done < $TMP2_FILE
        
    # If Debug is Activated - Display Important Variables before exiting function
    if [ $DEBUG_LEVEL -gt 5 ]
        then sadm_writelog "IF0_READ_IDX  is $IF0_READ_IDX"        
             sadm_writelog "IF1_READ_IDX  is $IF1_READ_IDX"        
             sadm_writelog "IF2_READ_IDX  is $IF2_READ_IDX"        
             sadm_writelog "IF0_WRITE_IDX is $IF0_WRITE_IDX"        
             sadm_writelog "IF1_WRITE_IDX is $IF1_WRITE_IDX"        
             sadm_writelog "IF2_WRITE_IDX is $IF2_WRITE_IDX"        
    fi
        
    # Extract the interfaces read and write KB/s from the nmon file and put them in ARRAY_NET
    # ----------------------------------------------------------------------------------------------
    grep "^NET,T" $NMON_FILE > $TMP2_FILE
    while read wline                         # Read Network Stat Lines
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`         # Get SnapShot Number
        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now
        if [ $IF0_READ_IDX  -ne 0 ] ;then IF0_READ_KBS=`echo $wline  | cut -d, -f$IF0_READ_IDX`  ;fi           # First Interface Read KB/s
        if [ $IF1_READ_IDX  -ne 0 ] ;then IF1_READ_KBS=`echo $wline  | cut -d, -f$IF1_READ_IDX`  ;fi          # 2nd Interface Read KB/s
        if [ $IF2_READ_IDX  -ne 0 ] ;then IF2_READ_KBS=`echo $wline  | cut -d, -f$IF2_READ_IDX`  ;fi          # Third Interface Read KB/s
        if [ $IF0_WRITE_IDX -ne 0 ] ;then IF0_WRITE_KBS=`echo $wline | cut -d, -f$IF0_WRITE_IDX` ;fi          # First Interface Write KB/s
        if [ $IF1_WRITE_IDX -ne 0 ] ;then IF1_WRITE_KBS=`echo $wline | cut -d, -f$IF1_WRITE_IDX` ;fi          # 2nd Interface Write KB/s
        if [ $IF2_WRITE_IDX -ne 0 ] ;then IF2_WRITE_KBS=`echo $wline | cut -d, -f$IF2_WRITE_IDX` ;fi          # Third Interface Write KB/s
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -gt 5 ]
            then sadm_writelog "Network Stat. Line is : $wline"
                 sadm_writelog "IF0-READ-KBS   : $IF0_READ_KBS"        
                 sadm_writelog "IF1-READ-KBS   : $IF1_READ_KBS"        
                 sadm_writelog "IF2-READ-KBS   : $IF2_READ_KBS"        
                 sadm_writelog "IF0-WRITE-KBS  : $IF0_WRITE_KBS"        
                 sadm_writelog "IF1-WRITE-KBS  : $IF1_WRITE_KBS"        
                 sadm_writelog "IF2-WRITE-KBS  : $IF2_WRITE_KBS"        
        fi    
        ARRAY_NET[$INDX]="$IF0_READ_KBS,$IF1_READ_KBS,$IF2_READ_KBS,$IF0_WRITE_KBS,$IF1_WRITE_KBS,$IF2_WRITE_KBS"
        done < $TMP2_FILE
    sadm_writelog "Finishing Network Activity Information."
}




#===================================================================================================
#                      Collect Memory Stat and put them in the ARRAY_MEM 
#===================================================================================================
#
# ======== Aix nmon lines
# MEM,Memory spet1008,Real Free %,Virtual free %,Real free(MB),Virtual free(MB),Real
# total(MB),Virtual total(MB)
# MEM,T0001,18.8,77.7,7738.3,15508.6,41216.0,19968.0
# MEM,T0002,18.4,77.7,7601.8,15509.4,41216.0,19968.0
#
# ======== Linux nmon lines
# MEM,Memory MB
# lxmq1001,memtotal,hightotal,lowtotal,swaptotal,memfree,highfree,lowfree,swapfree,memshar
# ed,cached,active,bigfree,buffers,swapcached,inactive
# MEM,T0001,96680.1,0.0,96680.1,18432.0,248.5,0.0,248.5,17914.3,-0.0,86337.2,41480.0,-1.0,
# 337.4,7.8,51422.5
# MEM,T0002,96680.1,0.0,96680.1,18432.0,259.9,0.0,259.9,17920.2,-0.0,86541.1,42375.7,-1.0,
# 358.2,2.1,50618.1
#===================================================================================================
build_memory_array()
{
    sadm_writelog "Processing Memory information."
    grep "^MEM,T" $NMON_FILE | sort >$TMP_FILE 
    
    while read wline                                                    # Read All Records
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`         # Get SnapShot Number
        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now

        MEM_TOTAL=`echo $wline | awk -F, '{ print $7 }'`                # Real Total Memory in MB
        MEM_FREE=`echo $wline | awk -F, '{ print $5 }'`                 # Real Free Memory in MB
        MEM_USE=`echo $MEM_TOTAL - $MEM_FREE | $BC -l `                  # Calculate Memory Use

        VIR_TOTAL=`echo $wline | awk -F, '{ print $8 }'`                # Virtual Total Memory in MB
        VIR_FREE=`echo $wline | awk -F, '{ print $6 }'`                 # Virtual Free Memory in MB
        VIR_USE=`echo $VIR_TOTAL - $VIR_FREE | $BC -l `                  # Calculate Virtual Mem Use


        # Put Memory Statistics in Array
        ARRAY_MEMORY[$INDX]="${MEM_TOTAL},${MEM_FREE},${MEM_USE},${VIR_TOTAL},${VIR_FREE},${VIR_USE}"
        
        if [ $DEBUG_LEVEL -gt 5 ]
            then sadm_writelog "Memory line is $wline"
                 sadm_writelog "ARRAY_MEMORY[$INDX]=${MEM_TOTAL},${MEM_FREE},${MEM_USE},${VIR_TOTAL},${VIR_FREE},${VIR_USE}"
        fi

        done <  $TMP_FILE
    sadm_writelog "Finish collecting Memory information."
}






#===================================================================================================
#                      Collect Memory Stat and put them in the ARRAY_MEM 
#===================================================================================================
#
# ======== Aix nmon lines
# MEMNEW,Memory New spet1008,Process%,FScache%,System%,Free%,Pinned%,User%
# MEMNEW,T0001,50.5,34.6,6.9,8.0,7.0,81.6
#
# ======== Linux nmon lines
# NOT EXIST ON LINUX
#===================================================================================================
build_memnew_array()
{
    sadm_writelog "Processing Memory New information."
    grep "^MEMNEW,T" $NMON_FILE | sort >$TMP_FILE 
    
    while read wline                                                    # Read All Records
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`         # Get SnapShot Number
        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now

        M_PROCESS=`echo $wline | awk -F, '{ print $3 }'`           # Process %
        M_FSCACHE=`echo $wline | awk -F, '{ print $4 }'`           # FSCache %
        M_SYSTEM=` echo $wline | awk -F, '{ print $5 }'`           # System  %
        M_FREE=`   echo $wline | awk -F, '{ print $6 }'`           # Free  %
        M_PINNED=` echo $wline | awk -F, '{ print $7 }'`           # Pinned %
        M_USER=`   echo $wline | awk -F, '{ print $8 }'`           # User %

        # Put Memory Statistics in Array
        ARRAY_MEMNEW[$INDX]="${M_PROCESS},${M_FSCACHE},${M_SYSTEM},${M_FREE},${M_PINNED},${M_USER}"
        
        if [ $DEBUG_LEVEL -gt 5 ]
            then sadm_writelog "Memory line is $wline"
                 sadm_writelog "ARRAY_MEMNEW[$INDX]=${M_PROCESS},${M_FSCACHE},${M_SYSTEM},${M_FREE},${M_PINNED},${M_USER}"
        fi

        done <  $TMP_FILE
    sadm_writelog "Finish collecting Memory New information."
}






#===================================================================================================
#               Collect Pagein and Pageout Stat and put them in the ARRAY_PAGING
#===================================================================================================
#
# ======== Aix nmon lines
# PAGE,Paging spet1008,faults,pgin,pgout,pgsin,pgsout,reclaims,scans,cycles
# 11681 PAGE,T0001,13956.7,24.0,749.8,12.4,0.3,0.0,0.0,0.0
# 11682 PAGE,T0002,3866.7,0.5,185.5,0.1,0.2,0.0,0.0,0.0
#
# ======== Linux nmon lines
# VM,Paging and Virtual
# Memory,nr_dirty,nr_writeback,nr_unstable,nr_page_table_pages,nr_mapped,nr_slab,pgpgin,pg
# pgout,pswpin,pswpout,pgfree,pgactivate,pgdeactivate,pgfault,pgmajfault,pginodesteal,slab
# s_scanned,kswapd_steal,kswapd_inodesteal,pageoutrun,allocstall,pgrotated,pgalloc_high,pg
# alloc_normal,pgalloc_dma,pgrefill_high,pgrefill_normal,pgrefill_dma,pgsteal_high,pgsteal
# _normal,pgsteal_dma,pgscan_kswapd_high,pgscan_kswapd_normal,pgscan_kswapd_dma,pgscan_dir
# ect_high,pgscan_direct_normal,pgscan_direct_dma
# 10213 VM,T0001,-1,38,-1,10,-1,1291,-1,-1,-1,888427005615,-1,207847281401,7293399,321873500513,
# 2191,-1,0,-1,693230,-1,-1,-1,292295512,5292295512,-1,91,238,38870095174,-1,-1,71927408,1
# 00,278,7471,-1,1,3170198
#
#===================================================================================================
build_paging_activity_array()
{
    sadm_writelog "Processing Paging Activity information."
    
    # Search proper lines depending upon OS Processing
    if [ "$NMON_OS" == "AIX" ] 
        then grep "^PAGE,T" $NMON_FILE | sort >$TMP_FILE
        else grep "^VM,T"   $NMON_FILE | sort >$TMP_FILE
    fi
        
    
    while read wline                                                    # Read All Records
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`         # Get SnapShot Number
        INDX=`expr ${NTIME} + 0`                                        # Empty field are Zero now
        if [ "$NMON_OS" == "AIX" ]
            then PAGE_IN=`echo $wline | awk -F, '{ print $6 }'`         # AIX pgin stat.
                 PAGE_OUT=`echo $wline | awk -F, '{ print $7 }'`        # AIX pgout stat.
            else PAGE_IN=`echo $wline | awk -F, '{ print $8 }'`         # LINUX pgin stat.
                 PAGE_OUT=`echo $wline | awk -F, '{ print $9 }'`        # LINUX pgout stat.
        fi
        ARRAY_PAGING[$INDX]="${PAGE_IN},${PAGE_OUT}"                    # Put Stat. in Array
        
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG_LEVEL -gt 5 ]
            then sadm_writelog "-----\nLINE   = $wline"
                 if [ $DEBUG_LEVEL -gt 1 ]
                    then    sadm_writelog "NTIME     = $NTIME"
                            sadm_writelog "PAGE_IN   = $PAGE_IN"
                            sadm_writelog "PAGE_OUT  = $PAGE_OUT"
                 fi
                 sadm_writelog "INDEX = $INDX - ${ARRAY_PAGING[${INDX}]}"        
        fi    
        done <  $TMP_FILE
    sadm_writelog "Finish collecting Paging Activity information."
}



#===================================================================================================
#                        Commands run at the end of the script
#===================================================================================================
rrd_update()
{
    sadm_writelog "Updating RRD Database."
    for (( i = 1 ; i <= ${#ARRAY_TIME[@]} ; i++ ))
        do
        if [ $DEBUG_LEVEL -gt 1 ]
            then sadm_writelog "ARRAY_CPU   [$i]: ${ARRAY_CPU[$i]}"
                 sadm_writelog "ARRAY_TIME  [$i]: ${ARRAY_TIME[$i]}"
        fi
    
        A_USER=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $1}'`
        A_SYST=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $2}'`
        A_WAIT=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $3}'`
        A_IDLE=` echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $4}'`
        A_TOTAL=`echo ${ARRAY_CPU[$i]}           | awk -F, '{ print $5}'`
        A_EPOCH=`echo ${ARRAY_TIME[$i]}          | awk -F, '{ print $1}'`
        A_DATE=`echo ${ARRAY_TIME[$i]}           | awk -F, '{ print $2}'`
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
        A_ETH0_READ=`echo ${ARRAY_NET[$i]}       | awk -F, '{ print $1}'`
        A_ETH1_READ=`echo ${ARRAY_NET[$i]}       | awk -F, '{ print $2}'`
        A_ETH2_READ=`echo ${ARRAY_NET[$i]}       | awk -F, '{ print $3}'`
        A_ETH0_WRITE=`echo ${ARRAY_NET[$i]}      | awk -F, '{ print $4}'`
        A_ETH1_WRITE=`echo ${ARRAY_NET[$i]}      | awk -F, '{ print $5}'`
        A_ETH2_WRITE=`echo ${ARRAY_NET[$i]}      | awk -F, '{ print $6}'`
        A_MPROCESS=`echo ${ARRAY_MEMNEW[$i]}     | awk -F, '{ print $1}'` 
        A_MFSCACHE=`echo ${ARRAY_MEMNEW[$i]}     | awk -F, '{ print $2}'` 
        A_MSYSTEM=`echo ${ARRAY_MEMNEW[$i]}      | awk -F, '{ print $3}'` 
        A_MFREE=`echo ${ARRAY_MEMNEW[$i]}        | awk -F, '{ print $4}'` 
        A_MPINNED=`echo ${ARRAY_MEMNEW[$i]}      | awk -F, '{ print $5}'` 
        A_MUSER=`echo ${ARRAY_MEMNEW[$i]}        | awk -F, '{ print $6}'` 
        
        if [ $DEBUG_LEVEL -eq 9 ]
        then sadm_writelog "A_DATE      =   $A_DATE"            
             sadm_writelog "A_USER      =   $A_USER"
             sadm_writelog "A_SYST      =   $A_SYST"            
             sadm_writelog "A_WAIT      =   $A_WAIT"            
             sadm_writelog "A_IDLE      =   $A_IDLE"            
             sadm_writelog "A_TOTAL     =   $A_TOTAL"            
             sadm_writelog "A_EPOCH     =   $A_EPOCH"            
             sadm_writelog "A_RUNQ      =   $A_RUNQ"            
             sadm_writelog "A_DISKREAD  =   $A_DISKREAD"            
             sadm_writelog "A_DISKWRITE =   $A_DISKWRITE"            
             sadm_writelog "A_MEM_TOTAL =   $A_MEM_TOTAL"            
             sadm_writelog "A_MEM_FREE  =   $A_MEM_FREE"            
             sadm_writelog "A_MEM_USED  =   $A_MEM_USED"            
             sadm_writelog "A_VIR_TOTAL =   $A_VIR_TOTAL"            
             sadm_writelog "A_VIR_FREE  =   $A_VIR_FREE"            
             sadm_writelog "A_VIR_USED  =   $A_VIR_USED"            
             sadm_writelog "A_PAGE_OUT  =   $A_PAGE_OUT"            
             sadm_writelog "A_PAGE_IN   =   $A_PAGE_IN"            
             sadm_writelog "A_ETH0_READ =   $A_ETH0_READ"            
             sadm_writelog "A_ETH0_WRITE=   $A_ETH0_WRITE"            
             sadm_writelog "A_ETH1_READ =   $A_ETH1_READ"            
             sadm_writelog "A_ETH1_WRITE=   $A_ETH1_WRITE"            
             sadm_writelog "A_ETH2_READ =   $A_ETH2_READ"            
             sadm_writelog "A_ETH2_WRITE=   $A_ETH2_WRITE"            
             sadm_writelog "A_MPROCESS  =   $A_MPROCESS"
             sadm_writelog "A_MFSCACHE  =   $A_MFSCACHE"
             sadm_writelog "A_MSYSTEM   =   $A_MSYSTEM"
             sadm_writelog "A_MFREE     =   $A_MFREE"
             sadm_writelog "A_MPINNED   =   $A_MPINNED"
             sadm_writelog "A_MUSER     =   $A_MUSER"
        fi
       

        field_name1="cpu_user:cpu_sys:cpu_wait:cpu_idle:cpu_total:proc_runq:"
        field_name2="disk_kbread_sec:disk_kbwrtn_sec:mem_free:mem_used:mem_total:"
        field_name3="page_in:page_out:"
        field_name4="eth0_readkbs:eth1_readkbs:eth2_readkbs:"
        field_name5="eth0_writekbs:eth1_writekbs:eth2_writekbs:"
        field_name6="page_free:page_used:page_total:"
        field_name7="mem_new_proc:mem_new_fscache:mem_new_system:mem_new_free:mem_new_pinned:mem_new_user"
        field_name="${field_name1}${field_name2}${field_name3}${field_name4}${field_name5}${field_name6}${field_name7}"
        
        field_value1="${A_USER}:${A_SYST}:${A_WAIT}:${A_IDLE}:${A_TOTAL}:${A_RUNQ}:"
        field_value2="${A_DISKREAD}:${A_DISKWRITE}:${A_MEM_FREE}:${A_MEM_USED}:${A_MEM_TOTAL}:"
        field_value3="${A_PAGE_IN}:${A_PAGE_OUT}:"
        field_value4="${A_ETH0_READ}:${A_ETH1_READ}:${A_ETH2_READ}:"
        field_value5="${A_ETH0_WRITE}:${A_ETH1_WRITE}:${A_ETH2_WRITE}:"
        field_value6="${A_VIR_FREE}:${A_VIR_USED}:${A_VIR_TOTAL}:"
        field_value7="${A_MPROCESS}:${A_MFSCACHE}:${A_MSYSTEM}:${A_MFREE}:${A_MPINNED}:${A_MUSER}"
        field_value="${field_value1}${field_value2}${field_value3}${field_value4}${field_value5}${field_value6}${field_value7}"
                        
        #if [ $DEBUG_LEVEL -eq 0 ] ; then sadm_writelog "rrdupdate ${RRD_FILE} ${A_EPOCH} ${A_DATE} ${NMON_FILE}"; fi
        if [ $DEBUG_LEVEL -gt 1 ] ; then sadm_writelog "rrdupdate ${RRD_FILE} -t ${A_EPOCH}:${field_name} ${field_value}"; fi
        rrdupdate ${RRD_FILE} -t ${field_name} ${A_EPOCH}:${field_value}
        RC=$?
        
        if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "rrdupdate return code is $RC" ; fi
        done
    
    
    # Clear all Arrays before beginning next SnapShot
    unset ARRAY_TIME ARRAY_CPU      ARRAY_RUNQ      ARRAY_DISKREAD ARRAY_DISKWRITE  
    unset ARRAY_NET  ARRAY_MEMNEW   ARRAY_PAGING    ARRAY_MEMORY
}





#===================================================================================================
#                               Main process of the script is Here
#===================================================================================================
main_process()
{
    ERROR_COUNT=0                                                       # Set Error counter to zero

    # Produce a list of all Yesterday nmon file (sorted)
    YESTERDAY=`date -d "1 day ago" '+%y%m%d'`                           # Get Yesterday Date
    find $SADM_WWW_DAT_DIR -type f -name "*_${YESTERDAY}_*.nmon" |sort > $NMON_FILE_LIST

    while read NMON_FILE                                                # Process nmon file 1 by 1
        do
        sadm_writelog "`printf %10s |tr ' ' '-'`"                       # Write Dash Line to Log
        sadm_writelog "Processing the file $NMON_FILE"                  # Show User File Processing
        
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

        # Put Snapshot No & Epoch Time in ARRAY_TIME
        build_epoch_array                                   
        if [ $DEBUG_LEVEL -gt 5 ] ; then display_epoch_array ; fi       # Ext. Debug Display Epoch Array
        
        # Put CPU stat in ARRAY_CPU
        build_cpu_array                                     
        if [ $DEBUG_LEVEL -gt 5 ] ; then display_cpu_array ; fi         # Ext. Debug Display CPU Array
        
        # Put RunQueue stat in ARRAY_RUNQ
        build_runqueue_array                                     
        if [ $DEBUG_LEVEL -gt 5 ] ; then display_cpu_array ; fi         # Ext. Debug Display CPU Array

        build_disk_read_array                                           # Build Disk Read Stat Array
        build_disk_write_array                                          # Build Disk Write Stat Array
        build_memory_array                                              # Build Memory Stat Array
        build_paging_activity_array                                     # Build Pagein/PageOut Array
        build_net_array                                                 # Build Network Activity Array
        if [ "$NMON_OS" == "AIX" ] ; then build_memnew_array ; fi       # Build MemNew Array if Aix
        
        # Update the RRD file based on Array Content
        rrd_update                                                      # Update the RRD Function

        # Make sure Archive Directory Exist For the Processing Host
        low_nmon_os=`echo $NMON_OS  |tr '[:upper:]' '[:lower:]'`        # Make osname lowercase
        if [ ! -d ${NMON_ARC}/${low_nmon_os}/${NMON_HOST} ]             # if server arc dir not exist
            then mkdir -p  ${NMON_ARC}/${low_nmon_os}/${NMON_HOST}      # Create it
                 chmod 775 ${NMON_ARC}/${low_nmon_os}/${NMON_HOST}      # Assign protection
        fi

        # Move Processed nmon file to Archive Directory
        sadm_writelog "Moving $NMON_FILE to ${NMON_ARC}/${low_nmon_os}/${NMON_HOST}" # Write Action to Log
        mv $NMON_FILE ${NMON_ARC}/$low_nmon_os/${NMON_HOST}            # Move nmon file to Archive Dir.
        sadm_writelog "${DASH}"                                            # Write Dash Line to Log
        
        done < $NMON_FILE_LIST
}

 
#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN Server
        then sadm_writelog "Script only run on SADMIN system (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    #if [ "$(whoami)" != "root" ]                                        # Is it root running script?
    #    then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
    #         sadm_writelog "Process aborted"                            # Abort advise message
    #         sadm_stop 1                                                # Close/Trim Log & Upd. RCH
    #         exit 1                                                     # Exit To O/S
    #fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9]) ---------------------------------
    while getopts "hd:" opt ; do                                        # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) help_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell
               ;;
           \?) sadm_writelog "Invalid option: -$OPTARG"                 # Invalid Option Message
               help_usage                                               # Display Help Usage
               sadm_stop 1                                              # Close the shop
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ]                                           # If Debug is Activated
        then sadm_writelog "Debug activated, Level ${DEBUG_LEVEL}"      # Display Debug Level
    fi

    main_process                                                        # Execute the main process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
