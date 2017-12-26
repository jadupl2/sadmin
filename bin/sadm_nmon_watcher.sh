#!/usr/bin/env sh 
# --------------------------------------------------------------------------------------------------
#   Title    : sadm_nmon_watcher.sh 
#   Author   : Jacques Duplessis 
#   Synopsis : Restart then nmon daemon, if it's not already running at midnight
#   Version  : 1.5
#   Date     : November 2015 
#   Requires : sh
# --------------------------------------------------------------------------------------------------
# 1.7   Modification making sure that nmon is available on the server.
#       If not found a copy in /sadmin/pkg/nmon/aix in used to create the link /usr/bin/nmon.
# --------------------------------------------------------------------------------------------------
# 1.8   Nov 2016
#       Enhance checking for nmon existence and add some message for user.
#       ReTested in AIX
# --------------------------------------------------------------------------------------------------
# 1.9   Dec 2016
#       Change to run on Aix 7.x and minor corrections
#
#set +x

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
SADM_VER='1.9'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_LOG_APPEND="Y"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadmlib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadmlib_server.sh  # sadm server lib

# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR        # Default is in sadmin.cfg
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
EPOCH_NOW=$(sadm_get_epoch_time)         ; export EPOCH_NOW         # Get Current Epoch Time
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

    # Verify if the nmon executable was found by SADM Library
    if [ "$SADM_NMON" = "" ] 
        then SADM_EXIT_CODE=1 
             sadm_writelog "The nmon command was NOT found - Cannot start daemon"
        else sadm_writelog "The nmon command was found at $SADM_NMON"
             NMON=$SADM_NMON
             SADM_EXIT_CODE=0
    fi

    # If nmon started by cron - Put crontab line in comment
    # What to make sure that only one nmon is running and is the one controlled by this script
    if [ $(sadm_get_ostype) = "LINUX" ]
        then nmon_cron='/etc/cron.d/nmon-script'                        # Name of the nmon cron file
             if [ -r "$nmon_cron" ]                                     # nmon cron file exist ?
                then commented=`grep 'nmon-script' ${nmon_cron} |cut -d' ' -f1` # Get 1st Char Of nmon line
                     if [ "$commented" = "0" ]                          # Cron Line not in commented
                        then sed -i -e 's/^/#/' $nmon_cron              # Then Put line in comment
                             sadm_writelog "$nmon_cron file was put in comment" # Leave trace of this
                        else sadm_writelog "$nmon_cron file is in comment - OK" # Leave trace of this
                     fi
             fi
    fi
    
    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
#    - Check if nmon is running - If not start it and set parameter so it stop at 23:55
# --------------------------------------------------------------------------------------------------
#
check_nmon()
{
    if [ $(sadm_get_ostype) = "AIX" ]
        then ${SADM_WHICH} topas_nmon >/dev/null 2>&1
             if [ $? -eq 0 ]
                then TOPAS_NMON=`${SADM_WHICH} topas_nmon`
                     WSEARCH="${SADM_NMON}|${TOPAS_NMON}"
                else WSEARCH=$SADM_NMON
             fi
        else WSEARCH=$SADM_NMON
    fi
    
    
    # Kill any nmon running without the option -s300 (Our switch) - Want only one nmon running
    # This will eliminate the nmon running from the crontab with rpm installation
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    if [ $nmon_count -gt 1 ] 
        then #NMON_PID=`ps -ef | grep nmon |grep -v grep |grep s300 |awk '{ print $2 }'`
             #sadm_writelog "Found another nmon process running at $NMON_PID"
             sadm_writelog "Found another nmon process running with s300 parameter"
             ps -ef | grep nmon |grep -v grep |grep s300 | tee -a $SADM_LOG 2>&1
             ps -ef | grep nmon |grep -v grep |grep s300 | awk '{ print $2 }' | xargs kill -9
             #kill -9 "$NMON_PID"
             sadm_writelog "We just kill them - Only one nmon process should be running"
    fi
             
 
    # Display Current Running Number of nmon process
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process actually running"
    ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG


    # nmon_count = 0 = Not running - Then we start it 
    # nmon_count = 1 = Running - Then OK
    # nmon_count = * = More than one runing ? Kill them and then we start a fresh one
    # not running nmon, start it
    sadm_writelog " "
    case $nmon_count in
        0)  sadm_writelog "The nmon process is not running - Starting nmon daemon ..."
            sadm_writelog "We will start a fresh one that will terminate at 23:55"
            sadm_writelog "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_writelog "$SADM_NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f "
            $SADM_NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_writelog "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
            fi
            sadm_writelog " "
            nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
            sadm_writelog "The number of nmon process running after restarting it is : $nmon_count"
            ps -ef | grep -E "$WSEARCH" | grep -v grep | nl
            ;;
        1)  sadm_writelog "Nmon already Running ... Nothing to Do."
            SADM_EXIT_CODE=0
            ;;
        *)  sadm_writelog "There seems to be more than one nmon process running ??"
            ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl 
            sadm_writelog "We will kill them both and start a fresh one that will terminate at 23:55"
            ps -ef | grep -E "$WSEARCH" | grep -v grep |grep s300 |awk '{ print $2 }' |xargs kill -9 |tee -a $SADM_LOG 2>&1
            sadm_writelog "We will start a fresh one that will terminate at 23:55"
            sadm_writelog "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_writelog "$SADM_NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f "
            $SADM_NMON -s300 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR -f >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_writelog "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
                else SADM_EXIT_CODE=0
            fi
            sadm_writelog " "
            nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
            sadm_writelog "The number of nmon process running after restarting it is : $nmon_count"
            ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl 
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
    
    # Don't Check nmon status when nmon rotation script (sadm_nmon_midnight_restart) is running
    if [ ! -e "${SADM_TMP_DIR}/sadm_nmon_midnight_restart.pid" ]        # nmon No Rotation running ?
        then check_nmon                                                 # nmon not running start it
             SADM_EXIT_CODE=$?                                          # Recuperate error code
             if [ $SADM_EXIT_CODE -ne 0 ]                               # if error occured
                then sadm_writelog "Problem starting nmon"              # Advise User
             fi
        else sadm_writelog "Don't check nmon when sadm_nmon_midnight_restart.sh is running"
    fi

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
