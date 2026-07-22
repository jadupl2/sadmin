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
# 2017_06_06 startup/shutdown V02.02.00 Log Enhancement
# 2017_06_07 startup/shutdown V02.03.00 Restructure to use the SADM Library and Send email on execution.
# 2017_06_08 startup/shutdown V02.04.00 Added removal of files in (pid) /sadmin/tmp at system boot
# 2017_06_13 startup/shutdown V02.05.00 Removal of sysmon lock file (/sadmin/sysmon.lock) at system boot.
# 2017_06_21 startup/shutdown V02.06.00 Added Clock Synchronization with 0.ca.pool.ntp.org
# 2017_07_17 startup/shutdown V02.07.00 Add Section to put command to execute on specified Systems
# 2017_07_21 startup/shutdown V02.08.00 Message display when starting Cosmetic Change 
# 2017_08_03 startup/shutdown V02.09.00 Bug Fix - Missing Quote
# 2018_01_27 startup/shutdown V03.00.00 Start 'nmon' as standard startup procedure 
# 2018_01_31 startup/shutdown V03.01.00 Execution of /etc/profile.d/sadmin.sh to set SADMIN Env. Variable
# 2018_02_02 startup/shutdown V03.02.00 Redirect output of starting nmon in the log.
# 2018_02_04 startup/shutdown V03.03.00 Remove all pid files when starting server
# 2018_06_22 startup/shutdown V03.04.00 Add Error Message when error synchronizing change.
# 2018_09_19 startup/shutdown V03.05.00 Updated to include the Alert Group
# 2018_10_16 startup/shutdown V03.06.00 Suppress Header and footer from the log (Cleaner Status display).
# 2018_10_18 startup/shutdown V03.07.00 Only send alert when exit with error.
# 2018_11_02 startup/shutdown V03.08.00 Added sleep before updating time clock (Raspbian Problem)
# 2019_03_27 startup/shutdown v03.09.00 If 'ntpdate' report an error, show error message.
# 2020_05_27 startup/shutdown v03.10.00 Force using bash instead of dash (Problem on Ubuntu).
# 2019_12_07 startup/shutdown v03.11.00 Avoid NTP Server name resolution (DNS not up), use IP Addr. now.
# 2020_11_04 startup/shutdown v03.13.00 Update SADMIN section & use env cmd to use proper bash shell.
# 2021_05_13 startup/shutdown v03.14.00 Check if ntpdate is present before syncing time.
# 2021_06_11 startup/shutdown v03.15.00 When syncing time redirect output to script log.
# 2022_04_06 startup/shutdown v03.16.00 Remove ip setting for raspi8
# 2022_07_24 startup/shutdown v03.17.00 Update SADMIN section to 1.51 and no-ip Client for Dynamic IP
# 2022_09_15 startup/shutdown v03.18.00 When error feed error log and fix 'nmon' wasn't starting.
# 2023_07_17 startup/shutdown v03.19.00 Updated to use faster python version of 'sadm_nmon_watcher'.
#@2024_04_17 startup/shutdown v03.20.00 Minor adjustment when starting 'nmon' performance monitor.
#@2024_05_02 startup/shutdown v03.21.00 Send startup email if 'SADM_EMAIL_STARTUP' = "Y" in sadmin.cfg.
#@2024_09_12 startup/shutdown v03.22.00 Change default script description 'SADM_DESC'.
#@2025_03_25 startup/shutdown v03.23.00 Change format of Power ON email to sysadmin.
#@2026_03_06 startup/shutdown v03.24.00 Correct typo when an error occur.
#@2026_06_24 startup/shutdown v03.25.00 now include removal of any .rpt file in $SADMIN/dat/rpt.
#@2026_07_08 startup/shutdown v03.25.01 now include removal of any .rpt file in $SADMIN/dat/rpt.
#@2026_07_08 startup/shutdown v03.26.02 On server, remove some .rpt in $SADMIN/www/dat/HOSTNAME/rpt.
#@2026_07_22 startup/shutdown v03.26.03 Add more info in Email sent to SADMIN admin.
## --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT ^C
#set -x 



                                                                                          
# ---------   S T A R T   O F   S A D M I N   R E Q U I R E D   C O D E   S E C T I O N  -----------
# v1.60 - Setup Global Variables and load the SADMIN standard library $SADMIN/lib/sadmlib_std.sh.
#       - To use SADMIN scripting tools, this section MUST be present near the top of your code.    
#
# Make sure environment variable 'SADMIN' is defined, if it's not, exit with error message.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\n[ ERROR ] Set 'SADMIN' environment variable to the install directory." 
        printf "\n  - Add a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 
fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\n[ ERROR ] SADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 
fi 


# SADMIN Section of your program that is shared with SADMIN Bash Library.
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s|tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.
export SADM_DEBUG=0                                        # Debug Level(0-9), 0 = NoDebug
export SADM_EXIT_CODE=0                                    # Pgm. Default Exit Code
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)

export SADM_VER='03.26.03'                                 # Script version number
export SADM_DESC="Run when the system is started (via sadmin.service)." 
export SADM_ROOT_ONLY="Y"                                  # Pgm. run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Pgm. run only on SADMIN server? [Y]/[N]
export SADM_GROUP_ONLY='N'                            # Pgm. run only if usr part of SADMIN Grp
export SADM_MULTIPLE_EXEC="N"                              # Can Run Simultaneous copy of script Y/N
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Append log ? Y=AppendLog,N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y = ProduceLogHeader, N = NoLogHeader
export SADM_LOG_FOOTER="Y"                                 # Y = ProduceLogFooter, N = NoLogFooter
export SADM_USE_RCH="Y"                                    # Update the RCH History File (Y/N)
export SADM_QUIET="N"                                      # Y=HideMsg & Error#  N=Show Msg & Error#
export SADM_ERRMSG=""                                      # Error Message returned by Library 
export SADM_ERRNO=0                                        # Error number (0=OK) returned by Library
export SADM_PID_TIMEOUT=7200                               # Sec. before PID file is remove,7200=2hr
export SADM_LOCK_TIMEOUT=3600                              # Sec. before System LockFile is Del, 1hr
export SADM_DB_USED="N"                                    # Use or Not, Got to be on SADMIN server
export SADM_DB_NAME="sadmin"                               # Database Name SADM_DBNAME in sadmin.cfg
export SADM_TMP_FILE1=$(mktemp -q "$SADMIN/tmp/sadm_tmp1_XXX") # Make tmpfile1, rm in sadm_stop()
export SADM_TMP_FILE2=$(mktemp -q "$SADMIN/tmp/sadm_tmp2_XXX") # Make tmpfile2, rm in sadm_stop()
export SADM_TMP_FILE3=$(mktemp -q "$SADMIN/tmp/sadm_tmp3_XXX") # Make tmpfile3, rm in sadm_stop()

# Load SADMIN Bash Shell Library, ready to  be used.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Init SADMIN tools, load cfg files

# Example of some functions and variable you can use.
export SADM_OS_NAME=$(sadm_get_osname)                     # REDHAT,ROCKY,ALMA,CENTOS,DEBIAN,UBUNTU.
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# Variables Below Are Taken From SADMIN Configuration File (sadmin.cfg) when the Library is loaded.
# You Can Overridde them On A Per Program Basis (If Needed).
#export SADM_ALERT_TYPE=1                                   # 0=NoAlert 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Error Group Define in alert_group.cfg
#export SADM_WARNING_GROUP="default"                        # Warning Alert Group (alert_group.cfg)   
#export SADM_INFO_GROUP="default"                           # Info Alert Group (in alert_group.cfg)
#export SADM_ALERT_REPEAT=0                                 # 0=No Alert Repeat, Sec. between Repeat
#export SADM_MAIL_ADDR="your_email@domain.com"              # Send email to...default in sadmin.cfg
#export SADM_MAX_LOGLINE=400                                # Nb of Lines to trim (0=NoTrim)
#export SADM_MAX_RCHLINE=35                                 # Nb of Lines to trim (0=NoTrim)
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------







# --------------------------------------------------------------------------------------------------
#                                   This Script environment variables
# --------------------------------------------------------------------------------------------------
export NTP_SERVER="68.69.221.61 162.159.200.1 205.206.70.2"             # Canada NTP Pool





# Send email to sysadmin when the system is starting
# --------------------------------------------------------------------------------------------------
poweron_mail()
{
    sadm_write_log " "
    sadm_write_log "Sending 'Startup' email to $SADM_MAIL_ADDR"         # Show what we're doing

    wb="$SADMIN/tmp/body$$$.txt"                                        # work email body file
    ws="SADM_INFO: System '$SADM_HOSTNAME' just started."               # Email subject
    we="$SADM_MAIL_ADDR"                                                # Send email to SysAdmin

    # Create the Body of email in a text file 
    echo -e "System '${SADM_HOSTNAME}' has just started on $(date)" > $wb
    echo -e "The program '${SADM_PN}' is reponsable for sending this email." >> $wb
    echo -e "\n\nLast 3 Reboot :\n$(last reboot | head -3)\n" >> $wb
    echo -e "Have a nice day !" >> $wb

    sadm_sendmail "$we" "$ws" "$wb"
    RC=$? 
    if [ $RC -eq 0 ] 
        then sadm_write_log "[ OK ] Mail sent successfully to $we"
        else sadm_write_err "[ ERROR ] Problem sending email to $we" 
    fi 
    
    if [ -f  "$wb" ] ; then rm -f "$wb" ; fi                            # Remove body file
    return $RC 
}





# System Standard Startup Procedure for every servers.
# --------------------------------------------------------------------------------------------------
normal_startup()
{
    ERROR_COUNT=0 

    sadm_write_log " "
    sadm_write_log "Running Standard Startup Procedure:"
    
    sadm_write_log "  - Remove SADMIN tools system lock file '${SADMIN}/${SADM_HOSTNAME}.lock'."
    rm -f "${SADMIN}/${SADM_HOSTNAME}.lock" >> $SADM_LOG 2>>$SADM_ELOG

    sadm_write_log "  - Remove any '*.rpt' left in '$SADM_RPT_DIR'."
    rm -f "${SADM_RPT_DIR}/*.rpt" >> $SADM_LOG 2>>$SADM_ELOG
    
    if [ "$SADM_HOST_TYPE" = "S" ] 
        then sadm_write_log "  - Remove any '*.rpt' left in '$SADM_WWW_RPT_DIR'."
             rm -f "${SADM_WWW_RPT_DIR}/*.rpt" >> $SADM_LOG 2>>$SADM_ELOG
    fi
    
    sadm_write_log "  - Removing temporary files in '$SADMIN/tmp' directory."
    rm -f ${SADMIN}/tmp/*  >> $SADM_LOG 2>&1
    
    sadm_write_log "  - Removing SADMIN system monitor lock file ${SADMIN}/sysmon.lock."
    rm -f ${SADMIN}/sysmon.lock  >> $SADM_LOG 2>&1


    # Synchronize system clock with NTP Servers
    command -v ntpdate >/dev/null                                       # Is ntpdate cmd on system ?
    if [ $? -eq 0 ]                                                   # ntpdate command on system
        then sadm_write_log "  - Synchronize clock with NTP server 'ntpdate -u $NTP_SERVER'."
             ntpdate -u $NTP_SERVER >> $SADM_LOG 2>&1                   # Synchronize with NTP server
             if [ $? -ne 0 ]                                            # If failed to synchronize
                then sadm_write_err "  - [ ERROR ] ntpdate - time synchronization with $NTP_SERVER" 
                     ((ERROR_COUNT++))
                else sadm_write_log "  - [ SUCCESS ] Time synchronization done with $NTP_SERVER" 
                     sadm_write_log "    - Current Date and Time: $(date)"

             fi
        else command -v chronyc >/dev/null                              # Is chrony cmd on system ?
             if [ $? -eq 0 ]                                          # chrony cmd is on system!
                then sadm_write_log "  - Synchronize clock with 'chronyc makestep' command."
                     chronyc makestep >> $SADM_LOG 2>&1
                     if [ $? -ne 0 ] 
                        then sadm_write_err "  - [ ERROR ] Time synchronization 'chronyc makestep'."
                            ((ERROR_COUNT++))
                            sadm_write_err "System clock were not able to be synchronized with NTP Servers."
                            sadm_write_err "Command 'ntpdate' or 'chronyc' commands not found on this system."  
                            sadm_write_err "Is the current date and time are ok : $(date) ?" 
                     fi 
                else sadm_write_log "  - [ SUCCESS ] Time synchronization '$cmdpath makestep'." 
                     sadm_write_log "    - Current Date and Time: $(date)"
             fi
    fi 


    # Start performance monitor 'nmon'.
    # Use 'sadm_nmon_watcher.py' if Python3 is available, otherwise use 'sadm_nmon_watcher.sh'.
    sadm_write_log "  - Start 'nmon' performance system monitor tool."
    #[   -x /usr/bin/python3 ] && $SADMIN/bin/sadm_nmon_watcher.py >/dev/null 2>&1 # Start nmon 
    #[ ! -x /usr/bin/python3 ] && $SADMIN/bin/sadm_nmon_watcher.sh >/dev/null 2>&1 # Start nmon 
    $SADMIN/usr/mon/swatch_nmon.sh >> $SADM_LOG 2>&1
    RC=$?
    if [ $RC -ne 0 ] 
       then sadm_write_err "     - [ ERROR ] Starting 'nmon' System Monitor." 
            ((ERROR_COUNT++))
       else sadm_write_log "     - [ OK ] Performance system monitor 'nmon' is started." 
    fi

    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{

    ERROR_COUNT=0                                           
    sadm_write_log "*** Running SADMIN system startup script on $(sadm_get_fqdn) ***"


    # Perform the System Standard Startup Procedure for every servers.
    normal_startup                                                      # Sync.Time,start nmon,...
    if [ $? -ne 0 ]                                                     # If we had some error
        then sadm_write_err "Some error(s) occurred during the standard startup procedure." 
             ((ERROR_COUNT++))                                          # Increase Error Count 
             sadm_stop $ERROR_COUNT                                     # Normal shutdown of SADMIN
             exit 1                                                     # Exit with error code 1
    fi


    # Special startup operation for each particular system
    sadm_write_log " "
    sadm_write_log "Starting specific startup procedure for '$SADM_HOSTNAME' system."
    case "$SADM_HOSTNAME" in
        "gandalf" )     sadm_write_log "  - Start 'noip2'to update dynamic DNS"
                        /usr/local/bin/noip2 >/dev/null 2>&1
                        ;;
        *)      	    sadm_write_log "  No special procedure needed at startup on $SADM_HOSTNAME"
                        ;;
    esac

    sadm_write_log " "
    sadm_write_log "End of startup script."                              # End of Script Message

    if [ "$SADM_EMAIL_STARTUP" = "Y" ] 
        then poweron_mail    
             if [ $? -ne 0 ] ; then ((ERROR_COUNT++)) ; fi
    fi 
    return $ERROR_COUNT                                                 # Return Default return code
}
 



#  S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Won't come back if error
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
