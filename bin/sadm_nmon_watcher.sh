#!/usr/bin/env sh 
# --------------------------------------------------------------------------------------------------
#   Title    : sadm_nmon_respwan.sh 
#   Author   : Jacques Duplessis 
#   Synopsis : Restart then nmon daemon, if it's not already running
#               - Start it with proper parameters so it finished at 23:55
#   Version  :  1.5
#   Date     :  November 2015 
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
#set +x

#

#
#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
#===================================================================================================

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib

# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export ADM_MAIL_ADDR        # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                          ; export SADM_MAIL_TYPE       # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME        # Company Name
#SADM_USER="sadmin"                        ; export SADM_USER            # sadmin user account
#SADM_GROUP="sadmin"                       ; export SADM_GROUP           # sadmin group account
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE     # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE      # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=40                      ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#===================================================================================================
#





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------

# Calculate the number of Snap Shot Till 23:55 today
# -------------------------------------------------------------------------------------
CUR_DATE=`date +"%Y.%m.%d"`              ; export CUR_DATE          # Current Date
NOW="$CUR_DATE 23:55:00"                 ; export NOW               # Build epoch cmd date format
EPOCH_NOW=$(sadm_epoch_time)             ; export EPOCH_NOW         # Get Current Epoch Time
EPOCH_END=`sadm_date_to_epoch "${NOW}"`  ; export EPOCH_END         # Epoch Value of Today at 23:55
TOT_SEC=`echo "${EPOCH_END}-${EPOCH_NOW}"|bc`                       # Nb Sec. between now & 23:55
TOT_MIN=`echo "${TOT_SEC}/60"| bc`                                  # Nb of Minutes till 23:55
TOT_SNAPSHOT=`echo "${TOT_MIN}/5"| bc`                              # Nb. of 5 MIn till 23:55
TOT_SNAPSHOT=`expr $TOT_SNAPSHOT - 1 `			                    # Sub. 1 SnapShot just to be sure

    
# --------------------------------------------------------------------------------------------------
#     - Set command path used in the script (Some path are different on some RHEL Version)
#     - Check if Input exist and is readable
# --------------------------------------------------------------------------------------------------
#
pre_validation()
{

    # Verify if the nmon programe is on the system
    sadm_logger "Verifying if nmon is accessible"
    NMON=`$SADM_WHICH nmon >/dev/null 2>&1`
    if [ $? -ne 0 ]
        then sadm_logger "Error : The command 'nmon' could not be found" 
             sadm_logger "        This program is need by $SADM_INST script of the SADMIN tools"
             sadm_logger "        Please install it and re-run this script"
             sadm_logger "        To install it, use the following command depending on your distro"
             sadm_logger "        Use 'yum install nmon' or 'apt-get install nmon'"
             sadm_logger "Script Aborted"
             SADM_EXIT_CODE=1
             return $SADM_EXIT_CODE                                     # Return Error to Caller
    fi
    NMON=`$SADM_WHICH nmon` ; export NMON
    sadm_logger "The nmon command was found at $NMON"
    

    # If nmon started by cron - Put crontab line in comment
    # What to make sure that only one nmon is running and is the one controlled by this script
    nmon_cron='/etc/cron.d/nmon-script'                                 # Name of the nmon cron file
    if [ -r "$nmon_cron" ]                                              # nmon cron file exist ?
       then commented=`grep 'nmon-script' ${nmon_cron} |cut -d' ' -f1`  # Get 1st Char Of nmon line
            if [ "$commented" = "0" ]                                   # Cron Line not in commented
                then sed -i -e 's/^/#/' $nmon_cron                      # Then Put line in comment
                     sadm_logger "$nmon_cron file was put in comment"   # Leave trace of this
                else sadm_logger "$nmon_cron file is in comment - OK"   # Leave trace of this
            fi
    fi 
    
    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
#    - Stop / Start nmon Daemon once a day at 23:55
# --------------------------------------------------------------------------------------------------
#
restart_nmon()
{
 
    
    # Kill any nmon running without the option -s300 (Our switch) - Want only one nmon running
    # This will eliminate the nmon running from the crontab with rpm installation
    nmon_count=`ps -ef | grep "$NMON" |grep -v grep |grep -v s300 |wc -l |tr -d ' '`
    if [ $nmon_count -ne 0 ] 
        then NMON_PID=`ps -ef | grep "$NMON" |grep -v grep |grep -v s300 |awk '{ print $2 }'`
             sadm_logger "Found another nmon process running at $NMON_PID"
             ps -ef | grep "$NMON" |grep -v grep |grep -v s300 | tee -a $SADM_LOG 2>&1
             kill -9 "$NMON_PID"
             sadm_logger "We just kill it - Only one nmon process should be running"
    fi
             
 
    # Display Current Running Number of nmon process
    nmon_count=`ps -ef | grep "$NMON" | grep 's300' | grep -v grep | wc -l`
    sadm_logger "There is $nmon_count nmon process actually running"
    ps -ef | grep "$NMON" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG


    # nmon_count = 0 = Not running - Then we start it 
    # nmon_count = 1 = Running - Then OK
    # nmon_count = * = More than one runing ? Kill them and then we start a fresh one
    # not running nmon, start it
    sadm_logger " "
    case $nmon_count in
        0)  sadm_logger "The nmon process is not running - Starting nmon daemon ..."
            sadm_logger "We will start a fresh one that will terminate at 23:55"
            sadm_logger "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_logger "$NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f "
            $NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_logger "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
            fi
            sadm_logger " "
            nmon_count=`ps -ef | grep $NMON | grep -v grep | wc -l`
            sadm_logger "The number of nmon process running after restarting it is : $nmon_count"
            ps -ef | grep $NMON | grep -v grep | nl
            ;;
        1)  sadm_logger "Nmon already Running ... Nothing to Do."
            SADM_EXIT_CODE=0
            ;;
        *)  sadm_logger "There seems to be more than one nmon process running ??"
            ps -ef | grep "$NMON" | grep 's300' | grep -v grep | nl 
            sadm_logger "We will kill them both and start a fresh one that will terminate at 23:55"
            ps -ef | grep "$NMON" | grep -v grep |grep s300 |awk '{ print $2 }' |xargs kill -9 |tee -a $SADM_LOG 2>&1
            sadm_logger "We will start a fresh one that will terminate at 23:55"
            sadm_logger "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_logger "$NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f "
            $NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_logger "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
                else SADM_EXIT_CODE=0
            fi
            sadm_logger " "
            nmon_count=`ps -ef | grep $NMON | grep -v grep | wc -l`
            sadm_logger "The number of nmon process running after restarting it is : $nmon_count"
            ps -ef | grep $NMON | grep -v grep | nl
            ;;
    esac

    # Display Process Info after starting nmon
    return $SADM_EXIT_CODE
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    pre_validation                                                      # nmon Cmd present ?
    if [ $? -ne 0 ]                                                     # If not there
        then sadm_stop 1                                                # Upd. RC & Trim Log & Set RC
             exit 1                                                     # Abort Program
    fi                             
    restart_nmon                                                        # nmon not running start it
    SADM_EXIT_CODE=$?                                                   # Recuperate error code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # if error occured
        then sadm_logger "Problem starting nmon"                        # Advise User
    fi
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
