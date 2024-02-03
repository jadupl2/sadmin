#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_startup.sh
#   Date:       25 October 2015
#   Synopsis:   This script is run when the system is started (via sadmin.service).
#               Called by /etc/systemd/system/sadmin.service (systemd) or /etc/init.d/sadmin (SysV)
#               
# --------------------------------------------------------------------------------------------------
#set -x
#
# CHANGE LOG
# ----------
# 2017_06_06 startup/shutdown V2.2 Log Enhancement
# 2017_06_07 startup/shutdown V2.3 Restructure to use the SADM Library and Send email on execution.
# 2017_06_08 startup/shutdown V2.4 Added removal of files in (pid) /sadmin/tmp at system boot
# 2017_06_13 startup/shutdown V2.5 Removal of sysmon lock file (/sadmin/sysmon.lock) at system boot.
# 2017_06_21 startup/shutdown V2.6 Added Clock Synchronization with 0.ca.pool.ntp.org
# 2017_07_17 startup/shutdown V2.7 Add Section to put command to execute on specified Systems
# 2017_07_21 startup/shutdown V2.8 Message display when starting Cosmetic Change 
# 2017_08_03 startup/shutdown V2.9 Bug Fix - Missing Quote
# 2018_01_27 startup/shutdown V3.0a Start 'nmon' as standard startup procedure 
# 2018_01_31 startup/shutdown V3.1 Execution of /etc/profile.d/sadmin.sh to set SADMIN Env. Variable
# 2018_02_02 startup/shutdown V3.2 Redirect output of starting nmon in the log.
# 2018_02_04 startup/shutdown V3.3 Remove all pid files when starting server
# 2018_06_22 startup/shutdown V3.4 Add Error Message when error synchronizing change.
# 2018_09_19 startup/shutdown V3.5 Updated to include the Alert Group
# 2018_10_16 startup/shutdown V3.6 Suppress Header and footer from the log (Cleaner Status display).
# 2018_10_18 startup/shutdown V3.7 Only send alert when exit with error.
# 2018_11_02 startup/shutdown V3.8 Added sleep before updating time clock (Raspbian Problem)
# 2019_03_27 startup/shutdown v3.9 If 'ntpdate' report an error, show error message.
# 2020_05_27 startup/shutdown v3.10 Force using bash instead of dash (Problem on Ubuntu).
# 2019_12_07 startup/shutdown v3.11 Avoid NTP Server name resolution (DNS not up), use IP Addr. now.
# 2020_11_04 startup/shutdown v3.13 Update SADMIN section & use env cmd to use proper bash shell.
# 2021_05_13 startup/shutdown v3.14 Check if ntpdate is present before syncing time.
# 2021_06_11 startup/shutdown v3.15 When syncing time redirect output to script log.
# 2022_04_06 startup/shutdown v3.16 Remove ip setting for raspi8
# 2022_07_24 startup/shutdown v3.17 Update SADMIN section to 1.51 and no-ip Client for Dynamic IP
# 2022_09_15 startup/shutdown v3.18 When error feed error log and fix 'nmon' wasn't starting.
# 2023_07_17 startup/shutdown v3.19 Updated to use faster python version of 'sadm_nmon_watcher'.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT ^C
#set -x 




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.56
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='3.19'                                     # Script version number
export SADM_PDESC="Script run at the system startup (via sadmin.service)." 
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# ---------------------------------------------------------------------------------------





# --------------------------------------------------------------------------------------------------
#                                   This Script environment variables
# --------------------------------------------------------------------------------------------------
export NTP_SERVER="68.69.221.61 162.159.200.1 205.206.70.2"             # Canada NTP Pool



# Send email when the system is back online
# --------------------------------------------------------------------------------------------------
poweron_mail()
{
    sadm_write_log " "
    sadm_write_log "Sending 'Startup' email to $SADM_MAIL_ADDR"         # Show what we're doing

    ws="System '$SADM_HOSTNAME' has just started."                      # Email subject

    # Body message
    wb0=$(printf "$(date)")
    wb1=$(printf "System '${SADM_HOSTNAME}' is back online.")
    bootmsg="$SADMIN/sys/boot_msg"                                      # who init reboot message 
    if [ -f "$bootmsg" ] 
        then wb2=$(cat $bootmsg)
             rm -f $bootmsg
    fi 
    wb3="Have a nice day from ${SADM_PN}."
    wb4="See you soon !"
    wb=$(printf "$wb0 \n $wb1 \n $wb2 \n $wb3 \n $wb4")
    
    we="$SADM_MAIL_ADDR"                                                # Send email to SysAdmin
    sadm_sendmail "$we" "$ws" "$wb"
    RC=$?
    if [ $RC -eq 0 ] 
        then sadm_write_log "[ OK ] Mail sent successfully to $we"
        else sadm_write_err "[ ERROR ] Problem sending email to $we" 
    fi 
    return $RC 
}



# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    ERROR_COUNT=0                                           
    sadm_write_log "*** Running SADM System Startup Script on $(sadm_get_fqdn)  ***"
    sadm_write_log " "
    sadm_write_log "Running Startup Standard Procedure"
    
    sadm_write_log "  Remove system lock file ("${SADMIN}/${SADM_HOSTNAME}.lock")."
    rm -f "${SADMIN}/${SADM_HOSTNAME}.lock" >> $SADM_LOG 2>>$SADM_ELOG

    sadm_write_log "  Removing files in '$SADMIN/tmp directory."
    rm -f ${SADMIN}/tmp/* >> $SADM_LOG 2>>$SADM_ELOG

    sadm_write_log "  Removing SADM System Monitor Lock File ${SADMIN}/sysmon.lock"
    rm -f ${SADMIN}/sysmon.lock >> "$SADM_LOG" 2>>"$SADM_ELOG"

    # Force Date/Time Synchronization at startup with NTP servers (if ntpdate is installed).
    command -v ntpdate >/dev/null 2>&1
    if (( $? == 0 ))
        then sadm_write_log "  Force system clock synchronization with NTP server $NTP_SERVER"
             ntpdate -u $NTP_SERVER >> "$SADM_LOG" 2>>"$SADM_ELOG"
             if [ $? -ne 0 ] 
                then sadm_write_err "   - [ ERROR ] Synchronizing Time with $NTP_SERVER" 
                     ((ERROR_COUNT++))
             fi
    fi 

    # Force Date/Time Synchronization at startup with 'chrony' servers (if chrony is installed).
    command -v chronyc >/dev/null 2>&1
    if (( $? == 0 ))
        then sadm_write_log "  Force system clock synchronization with \"chronyc 'burst 4/4'\""
             chronyc 'burst 4/4' >> "$SADM_LOG" 2>>"$SADM_ELOG"
             if [ $? -ne 0 ] 
                then sadm_write_err "   - [ ERROR ] Synchronizing Time with \"chronyc 'burst 4/4'\"" 
                ((ERROR_COUNT++))
             fi
    fi 

    # Start performance monitor 'nmon'.
    sadm_write_log "  Start 'nmon' performance system monitor tool"
    pgrep 'nmon' >/dev/null 2>&1                                        
    if [[ $? -ne 0 ]]                                                   # If nmon not running
        then ${SADMIN}/bin/sadm_nmon_watcher.py > /dev/null 2>&1        # Start nmon script
             if [ $? -ne 0 ] 
                then sadm_write_err "   - [ ERROR ] Starting 'nmon' System Monitor." 
                     ((ERROR_COUNT++))
                else sadm_write_log "   - [ OK ] Performance system monitor 'nmon' is started." 
             fi
    fi 

    # Special startup operation for each particular system
    sadm_write_log " "
    sadm_write_log "Starting specific startup procedure for '$SADM_HOSTNAME'."
    sadm_write_log " " 
    case "$SADM_HOSTNAME" in
        "gandalf" )     sadm_write_log "  - Start 'noip2'to update dynamic DNS"
                        /usr/local/bin/noip2 >/dev/null 2>&1
                        ;;

        *)      	    sadm_write_log "  No particular procedure needed for $SADM_HOSTNAME"
                        ;;
    esac

    sadm_write_log " "
    sadm_write_log "End of startup script."                              # End of Script Message

    #poweron_mail    
    #if [ $? -ne 0 ] ; then ((ERROR_COUNT++)) ; fi
        
    return $ERROR_COUNT                                                 # Return Default return code
}
 



#  S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Won't come back if error
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong 
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
