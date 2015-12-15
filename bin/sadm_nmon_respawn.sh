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

#set -x
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH VARIABLES AND
#   FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#
#



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------

# Calculate the number of Snap Shot Till 23:55 today
# -------------------------------------------------------------------------------------
CUR_DATE=`date +"%Y %m %d"`              ; export CUR_DATE          # Current Date
NOW="$CUR_DATE 23 55 00"                 ; export NOW               # Build epoch cmd date format
EPOCH_NOW=`$EPOCH`                       ; export EPOCH_NOW         # Get Current Epoch Time
EPOCH_END=`$EPOCH "${NOW}"`              ; export EPOCH_END         # Epoch Value of Today at 23:55
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
    sadm_logger "Verifying if nmon is accessible"
    NMON=`which nmon >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then NMON=`which nmon`
        else sadm_logger "Error : The command 'nmon' was not found" ; return 1
    fi
    export NMON
    sadm_logger "Yes it is at $NMON"
}


# --------------------------------------------------------------------------------------------------
#    - Stop / Start nmon Daemon once a day at 23:55
# --------------------------------------------------------------------------------------------------
#
restart_nmon()
{
 
    # Display Current Running Number of nmon process
    nmon_count=`ps -ef | grep 'nmon' | grep 's300' | grep -v grep | wc -l`
    sadm_logger "There are $nmon_count nmon process actually running"
    ps -ef | grep 'nmon' | grep 's300' | grep -v grep | nl


    # If not running nmon, start it
    sadm_logger " "
    if [ $nmon_count -eq 0 ] 
        then sadm_logger "Starting nmon daemon ..."
             sadm_logger "$NMON -s300 -c${TOT_SNAPSHOT} -t -m $NMON_DIR -f "
             $NMON -s300 -c${TOT_SNAPSHOT} -t -m $NMON_DIR -f >> $LOG 2>&1
             if [ $? -ne 0 ] ; then sadm_logger "Error while starting - Not Started !" ; return 1 ; fi
        else sadm_logger "Nmon already Running ... Nothing to Do."
             return 0 
    fi

    # Display Process Info after starting nmon
    sadm_logger " "
    nmon_count=`ps -ef | grep $NMON | grep -v grep | wc -l`
    sadm_logger "The number of nmon process running after restarting it is : $nmon_count"
    ps -ef | grep $NMON | grep -v grep | nl

    return 0 
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
    sadm_logger "Number of Snapshot till 23:55 is $TOT_SNAPSHOT"          # Nb. SnapShot Till 23:55
    restart_nmon                                                        # nmon not running start it
    GLOBAL_ERROR=$?                                                     # Recuperate error code
    if [ $GLOBAL_ERROR -ne 0 ]                                          # if error occured
        then sadm_logger "Problem starting nmon"                          # Advise User
    fi
    sadm_stop $GLOBAL_ERROR                                             # Upd. RC & Trim Log & Set RC
    exit $GLOBAL_ERROR                                                  # Exit Glob. Err.Code (0/1)
