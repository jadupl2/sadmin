#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_shutdown.sh
#   Date:       25 October 2015
#   Synopsis:   This script is run when the sadmin.service is shutdown when server goes down.
#               Called by /etc/systemd/system/sadmin.service (systemd) or /etc/init.d/sadmin (SysV)
# --------------------------------------------------------------------------------------------------
# 2015_01_09 startup/shutdown v2.2  Log Enhancement
# 2015_02_09 startup/shutdown v2.3  Restructure to use the SADM Library and Send email on execution.
# 2015_04_09 startup/shutdown v2.4  Add sleep of 5 sec. at the end, to allow completion shutdown
# 2015_04_09 startup/shutdown v2.5  Added code to run shutdown command based on Hostname
# 2017_08_05 startup/shutdown V2.6  Send email only on Execution Error
# 2018_01_31 startup/shutdown V2.7  Added execution of /etc/profile.d/sadmin.sh to have SADMIN Var. 
# 2018_09_19 startup/shutdown V2.8  Added Alert Group Utilization
# 2018_10_18 startup/shutdown v2.9  Remove execution of /etc/profile.d/sadmin.sh(Don't need anymore)
# 2019_03_29 startup/shutdown v2.10 Get SADMIN Directory Location from /etc/environment
# 2020_05_27 startup/shutdown v2.11 Force using bash instead of dash & problem setting SADMIN var.
# 2020_11_04 startup/shutdown v2.12 Update SADMIN section & use env cmd to use proper bash shell.
# 2022_09_15 startup/shutdown v2.13 Update SADMIN section 1.52 & minor changes.
# 2023_07_17 startup/shutdown v2.14 Update with latest SADMIN section(v1.56).
#@2024_05_02 startup/shutdown v2.15 Send shutdown email if 'SADM_EMAIL_SHUTDOWN' = "Y" in sadmin.cfg.
#@2025_03_25 startup/shutdown v2.16 Change format of shutdown email sent to sysadmin.
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
export SADM_VER='2.16'                                     # Script version number
export SADM_PDESC="Executed when the system is brought down by the sadmin.service."
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




# Send email when the system goes offline.
# --------------------------------------------------------------------------------------------------
shutdown_mail()
{
    sadm_write_log " "
    sadm_write_log "Send shutdown email to $SADM_MAIL_ADDR"
    ws="SADM_INFO: System '$SADM_HOSTNAME' going down." 
    wb=$(echo -e "\n$(date)\nSystem '${SADM_HOSTNAME}' '$(sadm_get_host_ip)' is going offline.\nEmail sent by '${SADM_PN}'.\nSee you soon !\n\n")
    we="$SADM_MAIL_ADDR"
    sadm_sendmail "$we" "$ws" "$wb" 
    RC=$?
    return $RC
}


# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    sadm_write_log "*** Running SADM System Shutdown Script on $(sadm_get_fqdn)  ***"
    ERROR_COUNT=0

    # Special Operation for some particular System
    sadm_write_log " "
    sadm_write_log "Shutdown procedure for $SADM_HOSTNAME"
    case "$SADM_HOSTNAME" in
        "myhost" )  sadm_write_log "Stop MyApp Web Server ..."
                    /myapp/bin/stop_httpd.sh >> $SADM_LOG 2>&1
                    if [ $? -ne 0 ] 
                        then sadm_write_err "  [ ERROR ] Stopping Web Server ..." 
                             (($ERROR_COUNT+1))
                    fi  
                    ;;
                *)  sadm_write_log "  No particular shutdown procedure needed for '$SADM_HOSTNAME'."
                    ;;
    esac

    sadm_write_log " "

    if [ "$SADM_EMAIL_SHUTDOWN" = "Y" ] 
        then shutdown_mail    
             if [ $? -ne 0 ] ; then ((ERROR_COUNT++)) ; fi
             sleep 10                                                   # Give time to send email   
    fi     
    
    return $ERROR_COUNT                                                 # Return Default return code
}



# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Won't come back if error
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong 
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
