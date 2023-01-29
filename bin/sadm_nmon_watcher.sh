#!/usr/bin/env bash 
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
# 2018_09_19    V2.6 Added Alert Group
# 2021_06_12 nolog: V2.7 Update SADMIN Section, add std command line option 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.50
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null 
         if [ $? -eq 0 ]                                   # Found SADMIN in /etc/env.
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.7'                                      # Script Version
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy ?
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. LockFile
export SADM_USE_RCH="Y"                                    # Update RCH HistoryFile 
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # LOAD SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Server
# ---------------------------------------------------------------------------------------





# --------------------------------------------------------------------------------------------------
# Show Script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}




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
# Check availability of 'nmon' and permission and 
# Deactivate nmon cron file 
#   - If nmon is not running, for any reason SADMIN will restart it, with proper parameters to 
#       run until 23:55 (sadm_nmon_watcher.sh) 
#   - SADMIN will start a fresh daemon every night at midnight.
#       (admin cron - sadmin_nmon_midnight_restart.sh)
# --------------------------------------------------------------------------------------------------
pre_validation()
{

    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write_log "----------------------"
             sadm_write_log "CURRENT EPOCH               = $EPOCH_NOW"
             sadm_write_log "CURRENT DATE/TIME           = `date +"%Y.%m.%d %H:%M:%S"`"
             sadm_write_log "END EPOCH                   = $EPOCH_END" 
             sadm_write_log "END DATE/TIME               = $NOW"
             sadm_write_log "SECONDS TILL 23:59:58       = $TOT_SEC" 
             sadm_write_log "MINUTES TILL 23:59:58       = $TOT_MIN"
             sadm_write_log "SECONDS BETWEEN SNAPSHOT    = 120"
             sadm_write_log "Nb. SnapShot till 23:59:58  = $TOT_SNAPSHOT" 
             sadm_write_log "----------------------"
             sadm_write_log " "
    fi
    
    NMON=`which nmon >/dev/null 2>&1`                                   # Is nmon executable Avail.?
    if [ $? -eq 0 ]                                                     # If it is, Save Full Path 
        then export NMON=`which nmon`                                   # Save 'nmon' location 
             sadm_write_log "[OK] Yes, 'nmon' is available ($NMON)"     # Show user result OK
        else sadm_write_err "[ERROR] The command 'nmon' was not found"  # Show User Error
             return 1                                                   # Return error to caller
    fi
    if [ ! -x $NMON ]                                                   # Is nmon executable ?
       then sadm_write_log "'nmon' ($NMON) missing execution permission" # Advise User of error
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
                             sadm_write_log "$nmon_cron file was put in comment" # Advise user 
                        else sadm_write_log "$nmon_cron file is in comment - OK" # Advise user 
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
        then ${SADM_WHICH} topas_nmon >/dev/null 2>&1                   # Latest Aix use topas_nmon
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
             #sadm_write_log "Found another nmon process running at $NMON_PID"
             sadm_write_log "Found another nmon process running with s120 parameter"
             ps -ef | grep nmon |grep -v grep |grep s120 | tee -a $SADM_LOG 2>&1
             ps -ef | grep nmon |grep -v grep |grep s120 | awk '{ print $2 }' | xargs kill -9
             #kill -9 "$NMON_PID"
             sadm_write_log "We just kill them - Only one nmon process should be running"
    fi
             
 
    # Search Process Status (ps) and display number of nmon process running currently
    sadm_write_log " "                                                   # Blank line in log
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
    sadm_write_log "There is $nmon_count nmon process actually running"  # Show Nb. nmon Running
    ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl | tee -a $SADM_LOG

    # nmon_count = 0 = Not running - Then we start it 
    # nmon_count = 1 = Running - Then OK
    # nmon_count = * = More than one running ? Kill them and then we start a fresh one
    # not running nmon, start it
    sadm_write_log " "
    case $nmon_count in
        0)  sadm_write_log "The nmon process is not running - Starting nmon daemon ..."
            sadm_write_log "We will start a fresh one that will terminate at 23:55"
            sadm_write_log "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_write_log "$SADM_NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR "
            $SADM_NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR  >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_write_log "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
            fi
            sadm_write_log " "
            nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
            sadm_write_log "The number of nmon process running after restarting it is : $nmon_count"
            ps -ef | grep -E "$WSEARCH" | grep -v grep | nl
            ;;
        1)  sadm_write_log "Nmon already Running ... Nothing to Do."
            SADM_EXIT_CODE=0
            ;;
        *)  sadm_write_log "There seems to be more than one nmon process running ??"
            ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl 
            sadm_write_log "We will kill them both and start a fresh one that will terminate at 23:55"
            ps -ef | grep -E "$WSEARCH" | grep -v grep |grep s120 |awk '{ print $2 }' |xargs kill -9 |tee -a $SADM_LOG 2>&1
            sadm_write_log "We will start a fresh one that will terminate at 23:55"
            sadm_write_log "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
            sadm_write_log "$SADM_NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR "
            $SADM_NMON -f s120 -c${TOT_SNAPSHOT} -t -m $SADM_NMON_DIR >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_write_log "Error while starting - Not Started !" 
                     SADM_EXIT_CODE=1 
                else SADM_EXIT_CODE=0
            fi
            # Search Process Status (ps) and display number of nmon process running currently
            sadm_write_log " "                                                   # Blank line in log
            nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
            sadm_write_log "There is $nmon_count nmon process actually running"  # Show Nb. nmon Running
            ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl | tee -a $SADM_LOG
            ;;
    esac

    # Display Last two nmon files created
    sadm_write_log " "                                                   # Blank line in log
    sadm_write_log "Last nmon files created"                             # SHow what were doing
    ls -ltr $SADM_NMON_DIR | tail -2 |  while read wline ; do sadm_write_log "$wline"; done
    sadm_write_log " "                                                   # Blank line in log

    return $SADM_EXIT_CODE
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}




# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    if [ "$(sadm_get_ostype)" = "DARWIN" ]                              # nmon not available on OSX
        then sadm_write_log "Command 'nmon' isn't available on MacOS"   # Advise user that won't run
             sadm_write_log "Script can't continue"                     # Process can't continue
             sadm_stop 0                                                # Close Everything Cleanly
             exit 0                                                     # Exit back to bash
    fi

    pre_validation                                                      # Does 'nmon' cmd present ?
    if [ $? -ne 0 ]                                                     # If not there
        then sadm_stop 1                                                # Upd. RC & Trim Log & Set RC
             exit 1                                                     # Abort Program
    fi                             
    
    # Check if nmon is running
    check_nmon                                                          # nmon not running start it
    SADM_EXIT_CODE=$?                                                   # Recuperate error code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # if error occurred
        then sadm_write_log "Problem starting nmon ...."                # Advise User
    fi
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
