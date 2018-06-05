#!/usr/bin/env sh 
# --------------------------------------------------------------------------------------------------
#   Title    : sadm_nmon_watcher.sh 
#   Author   : Jacques Duplessis 
#   Synopsis : Restart nmon daemon, if it's not already running (with end time at 23:58:58)
#   Version  : 1.5
#   Date     : November 2015 
#   Requires : sh
# --------------------------------------------------------------------------------------------------
# Change log
#
# 2016_10_10    v1.7 Modification making sure that nmon is available on the server.
#               If not found a copy in /sadmin/pkg/nmon/aix in used to create the link /usr/bin/nmon
# 2016_11_11    v1.8 Enhance checking for nmon existence and add some message for user, ReTested AIX
# 2016_12_20    v1.9 Change to run on Aix 7.x and minor corrections
# 2017_12_29    v2.0 Add Warning message stating that nmon not available on MacOS
# 2017_01_27    V2.1 Now list two newest nmon files in $SADMIN/dat/nmon & Fix minor Bug & add comment
# 2017_02_02    V2.2 Show number of nmon running only once, if nmon is already running
# 2017_02_04    V2.3 Snapshot will be taken every 2 minutes instead of 5.
# 2017_02_08    V2.4 Fix Compatibility problem with 'sadh' shell (If statement) 
# 2018_06_04    V2.5 Adapt to new Libr.
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.5'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================





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
    sadm_writelog "Last nmon files created"                             # SHow what were doing
    ls -ltr $SADM_NMON_DIR | tail -2 |  while read wline ; do sadm_writelog "$wline"; done
    sadm_writelog " "                                                   # Blank line in log

    return $SADM_EXIT_CODE
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    if [ "$(sadm_get_ostype)" = "DARWIN" ]                              # nmon not available on OSX
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

    pre_validation                                                      # Does 'nmon' cmd present ?
    if [ $? -ne 0 ]                                                     # If not there
        then sadm_stop 1                                                # Upd. RC & Trim Log & Set RC
             exit 1                                                     # Abort Program
    fi                             
    
    # Check if nmon is running
    check_nmon                                                          # nmon not running start it
    SADM_EXIT_CODE=$?                                                   # Recuperate error code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # if error occured
        then sadm_writelog "Problem starting nmon ...."                 # Advise User
    fi
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
