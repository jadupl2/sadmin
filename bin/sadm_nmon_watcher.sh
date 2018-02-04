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
# 1.8   Nov 2016
#       Enhance checking for nmon existence and add some message for user.
#       ReTested in AIX
# 1.9   Dec 2016
#       Change to run on Aix 7.x and minor corrections
# 2017_12_29 J.Duplessis 
#       V2.0 Add Warning message stating that nmon not available on MacOS
# 2017_01_27 J.Duplessis 
#       V2.1 Now list two newest nmon files in $SADMIN/dat/nmon & Fix minor Bug & add comments
# 2017_02_02 J.Duplessis 
#       V2.2 Show number of nmon running only once, if nmon is already running
# 2017_02_04 J.Duplessis 
#       V2.3 Snapshot will be taken every 2 minutes instead of 5.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $sadmin/lib/sadmlib_test.sh for viewing functions and informations avail. to you .
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to SADMIN directory" ;exit 1 ;fi
wlib="${SADMIN}/lib/sadmlib_std.sh"                                     # SADMIN Library Location
if [ ! -f $wlib ] ;then echo "SADMIN Library ($wlib) Not Found" ;exit 1 ;fi
#
# These are Global variables used by SADMIN Libraries - Some influence the behavior of some function
# These variables need to be defined prior to loading the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='2.3'                             ; export SADM_VER            # Your Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# Load SADMIN Libraries
[ -f ${SADMIN}/lib/sadmlib_std.sh ]    && . ${SADMIN}/lib/sadmlib_std.sh
#
# These variables are defined in sadmin.cfg file - You can override them here on a per script basis
# --------------------------------------------------------------------------------------------------
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE  # Max Nb. Lines in LOG file
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE   # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR    # Email Address to send status
#
# An email can be sent at the end of the script depending on the ending status
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE    # 0=No 1=OnErr 2=Success 3=All
#
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------

# Calculate the number of Snap Shot Till 23:55 today
# -------------------------------------------------------------------------------------
CUR_DATE=`date +"%Y.%m.%d"`              ; export CUR_DATE          # Current Date
NOW="$CUR_DATE 23:59:58"                 ; export NOW               # Build epoch cmd date format
EPOCH_NOW=$(sadm_get_epoch_time)         ; export EPOCH_NOW         # Get Current Epoch Time
EPOCH_END=`sadm_date_to_epoch "${NOW}"`  ; export EPOCH_END         # Epoch Value of Today at 23:58
TOT_SEC=`echo "${EPOCH_END}-${EPOCH_NOW}"|bc`                       # Nb Sec. between now & 23:58
TOT_MIN=`echo "${TOT_SEC}/60"| bc`                                  # Nb of Minutes till 23:58
TOT_SNAPSHOT=`echo "${TOT_MIN}/5"| bc`                              # Nb. of 5 Min till 23:58
TOT_SNAPSHOT=`echo "${TOT_MIN}/2"| bc`                              # Nb. of 2 Min till 23:58
#TOT_SNAPSHOT=`expr $TOT_SNAPSHOT - 1 `                             # Sub. 1 SnapShot just to be sure


    
# --------------------------------------------------------------------------------------------------
# Check availibility of 'nmon' and permmission and 
# Deactivate nmon cron file 
#   - If nmon is not running, for any reason SADMIN will restart it, with proper parameters to 
#       run until 23:55 (sadm_nmon_watcher.sh) 
#   - SADMIN will start a fresh daemon every night at midnight.
#       (admin cron - sadmin_nmon_midnight_restart.sh)
# --------------------------------------------------------------------------------------------------
pre_validation()
{
    NMON=`which nmon >/dev/null 2>&1`                                   # Is nmon executable Avail.?
    if [ $? -eq 0 ]                                                     # If it is, Save Full Path 
        then NMON=`which nmon`                                          # Save 'nmon' location 
             export NMON                                                # Make Avail. to SubProcess
             sadm_writelog "[OK] Yes, 'nmon' is available ($NMON)"      # Show user result OK
        else sadm_writelog "[ERROR] The command 'nmon' was not found"   # Show User Error
             return 1                                                   # Return error to caller
    fi
    if [ ! -x $NMON ]                                                   # Is nmon executable ?
       then sadm_writelog "'nmon' ($NMON) missing execution permission" # Advise User of error
            return 1                                                    # Return Error to Caller
    fi

    # If nmon started by cron - Put crontab line in comment
    # What to make sure that only one nmon is running and is the one controlled by this script
    if [ $(sadm_get_ostype) = "LINUX" ]                                 # On Linux O/S
        then nmon_cron='/etc/cron.d/nmon-script'                        # Name of the nmon cron file
             if [ -r "$nmon_cron" ]                                     # nmon cron file exist ?
                then commented=`grep 'nmon-script' ${nmon_cron} |cut -d' ' -f1` # 1st Char nmon line
                     if [ "$commented" = "0" ]                          # Cron Line not in commented
                        then sed -i -e 's/^/#/' $nmon_cron              # Then Put line in comment
                             sadm_writelog "$nmon_cron file was put in comment" # Advise user 
                        else sadm_writelog "$nmon_cron file is in comment - OK" # Advise user 
                     fi
             fi
    fi
    return 0
}


# --------------------------------------------------------------------------------------------------
#    - Check if nmon is running - If not start it and set parameter so it stop at 23:55
# --------------------------------------------------------------------------------------------------
#
check_nmon()
{

    # On Aix we might be running 'nmon' (older aix) or 'topas_nmon' (latest Aix)
    if [ $(sadm_get_ostype) = "AIX" ]                                   # If Server is running Aix
        then ${SADM_WHICH} topas_nmon >/dev/null 2>&1                   # Lastest Aix use topas_nmon
             if [ $? -eq 0 ]                                            # topas_nmon on system ?
                then TOPAS_NMON=`${SADM_WHICH} topas_nmon`              # Save Path to topas_nmon
                     WSEARCH="${SADM_NMON}|${TOPAS_NMON}"               # Will search for both nmon
                else WSEARCH=$SADM_NMON                                 # Will search for nmon only
                     TOPAS_NMON=""                                      # topas_nmon path not found
             fi
        else WSEARCH=$SADM_NMON                                         # Linux search for nmon only
    fi
    
    # Kill any nmon running without the option -s120 (Our switch) - Want only one nmon running
    # This will eliminate the nmon running from the crontab with rpm installation
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
    if [ $nmon_count -gt 1 ] 
        then #NMON_PID=`ps -ef | grep nmon |grep -v grep |grep s120 |awk '{ print $2 }'`
             #sadm_writelog "Found another nmon process running at $NMON_PID"
             sadm_writelog "Found another nmon process running with s120 parameter"
             ps -ef | grep nmon |grep -v grep |grep s120 | tee -a $SADM_LOG 2>&1
             ps -ef | grep nmon |grep -v grep |grep s120 | awk '{ print $2 }' | xargs kill -9
             #kill -9 "$NMON_PID"
             sadm_writelog "We just kill them - Only one nmon process should be running"
    fi
             
 
    # Search Process Status (ps) and display number of nmon process running currently
    sadm_writelog " "                                                   # Blank line in log
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process actually running"  # Show Nb. nmon Running
    ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl | tee -a $SADM_LOG

    # nmon_count = 0 = Not running - Then we start it 
    # nmon_count = 1 = Running - Then OK
    # nmon_count = * = More than one runing ? Kill them and then we start a fresh one
    # not running nmon, start it
    sadm_writelog " "
    case $nmon_count in
        0)  sadm_writelog "The nmon process is not running - Starting nmon daemon ..."
            sadm_writelog "We will start a fresh one that will terminate at 23:55"
            sadm_writelog "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_writelog "$SADM_NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR "
            $SADM_NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR  >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_writelog "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
            fi
            sadm_writelog " "
            nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
            sadm_writelog "The number of nmon process running after restarting it is : $nmon_count"
            ps -ef | grep -E "$WSEARCH" | grep -v grep | nl
            ;;
        1)  sadm_writelog "Nmon already Running ... Nothing to Do."
            SADM_EXIT_CODE=0
            ;;
        *)  sadm_writelog "There seems to be more than one nmon process running ??"
            ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl 
            sadm_writelog "We will kill them both and start a fresh one that will terminate at 23:55"
            ps -ef | grep -E "$WSEARCH" | grep -v grep |grep s120 |awk '{ print $2 }' |xargs kill -9 |tee -a $SADM_LOG 2>&1
            sadm_writelog "We will start a fresh one that will terminate at 23:55"
            sadm_writelog "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_writelog "$SADM_NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR "
            $SADM_NMON -f s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_writelog "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
                else SADM_EXIT_CODE=0
            fi
            # Search Process Status (ps) and display number of nmon process running currently
            sadm_writelog " "                                                   # Blank line in log
            nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
            sadm_writelog "There is $nmon_count nmon process actually running"  # Show Nb. nmon Running
            ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl | tee -a $SADM_LOG
            ;;
    esac

    # Display Last two nmon files created
    sadm_writelog " "                                                   # Blank line in log
    sadm_writelog "Last two nmon files created"                         # SHow what were doing
    ls -ltr $SADM_NMON_DIR | tail -2 |  while read wline ; do sadm_writelog "$wline"; done
    sadm_writelog " "                                                   # Blank line in log

    return $SADM_EXIT_CODE
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    if [ "$(sadm_get_ostype)" == "DARWIN" ]                             # nmon not available on OSX
        then sadm_writelog "The command nmon is not available on MacOS" # Advise user that won't run
             sadm_writelog "Script can't continue"                      # Process can't continue
             sadm_stop 0                                                # Close Everything Cleanly
             exit 0                                                     # Exit back to bash
    fi

    sadm_writelog "----------------------"
    sadm_writelog "CURRENT EPOCH               = $EPOCH_NOW"
    sadm_writelog "CURRENT DATE/TIME           = `date +"%Y.%m.%d %H:%M:%S"`"
    sadm_writelog "END EPOCH                   = $EPOCH_END" 
    sadm_writelog "END DATE/TIME               = $NOW"
    sadm_writelog "SECONDS TILL 23:59:58       = $TOT_SEC" 
    sadm_writelog "MINUTES TILL 23:59:58       = $TOT_MIN"
    sadm_writelog "SECONDS BETWEEN SNAPSHOT    = 120"
    sadm_writelog "Nb. SnapShot till 23:59:58  = $TOT_SNAPSHOT" 
    sadm_writelog "----------------------"

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
