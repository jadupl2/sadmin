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
# Change Log
# 2017_06_06    V2.2 Log Enhancement
# 2017_06_07    V2.3 Restructure to use the SADM Library and Send email on execution.
# 2017_06_08    V2.4 Added removal of files in (pid) /sadmin/tmp at system boot
# 2017_06_13    V2.5 Added removal of sysmon lock file (/sadmin/sysmon.lock) at system boot
# 2017_06_21    V2.6 Added Clock Synchronization with 0.ca.pool.ntp.org
# 2017_07_17    V2.7 Add Section to put command to execute on specified Systems
# 2017_07_21    V2.8 Message display when starting Cosmetic Change 
# 2017_08_03    V2.9 Bug Fix - Missing Quote
# 2018_01_27    V3.0a Start 'nmon' as standard startup procedure 
# 2018_01_31    V3.1 Added execution of /etc/profile.d/sadmin.sh to have SADMIN Env. Var. Defined
# 2018_02_02    V3.2 Redirect output of starting nmon in the log (already log by sadm_nmon_watcher.sh).
# 2018_02_04    V3.3 Remove all pid when starting server - Make sure there is no leftover.
# 2018_06_22    V3.4 Remove output of ntpdate & Add Error Message when error synchronizing change.
# 2018_09_19    V3.5 Updated to include the Alert Group
# 2018_10_16    V3.6 Suppress Header and footer from the log (Cleaner Status display).
# 2018_10_18    V3.7 Only send alert when exit with error.
# 2018_11_02    V3.8 Added sleep before updating time clock (Raspbian Problem)
# 2019_03_27 Update: v3.9 If 'ntpdate' report an error, show error message and add cosmetic messages
# 2019_03_29 Update: v3.10 Get SADMIN Directory Location from /etc/environment
#@2019_12_07 Update: v3.11 Avoid NTP Server name resolution (DNS not up), use IP Addr. now.
#@2020_05_27 Fix: v3.12 Force using bash instead of dash & problem setting SADMIN env. variable.
#@2020_11_04 Minor: v3.13 Update SADMIN section & use env cmd to use proper bash shell.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x 



#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================

# MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # If SADMIN EnvVar not right
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null          # SADMIN in /etc/environment
         if [ $? -eq 0 ]                                                # Yes it is 
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' Environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                 # Current Script filename(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`       # Current Script filename(without extension)
export SADM_TPID="$$"                                   # Current Script Process ID.
export SADM_HOSTNAME=`hostname -s`                      # Current Host name without Domain Name
export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Std Libr.).
export SADM_VER='3.13'                                  # Current Script Version
export SADM_EXIT_CODE=0                                 # Current Script Default Exit Return Code
export SADM_LOG_TYPE="B"                                # writelog go to [S]creen [L]ogFile [B]oth
export SADM_LOG_APPEND="Y"                              # [Y]=Append Existing Log [N]=Create New One
export SADM_LOG_HEADER="Y"                              # [Y]=Include Log Header  [N]=No log Header
export SADM_LOG_FOOTER="Y"                              # [Y]=Include Log Footer  [N]=No log Footer
export SADM_MULTIPLE_EXEC="N"                           # Allow running multiple copy at same time ?
export SADM_USE_RCH="N"                                 # Gen. History Entry in ResultCodeHistory 
export SADM_DEBUG=0                                     # Debug Level - 0=NoDebug Higher=+Verbose
export SADM_TMP_FILE1=""                                # Tmp File1 you can use, Libr. will set name
export SADM_TMP_FILE2=""                                # Tmp File2 you can use, Libr. will set name
export SADM_TMP_FILE3=""                                # Tmp File3 you can use, Libr. will set name

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                          # LOAD SADMIN Standard Shell Libr. Functions
export SADM_OS_NAME=$(sadm_get_osname)                  # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
export SADM_OS_VERSION=$(sadm_get_osversion)            # O/S Full Version Number  (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)      # O/S Major Version Number (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/CFG/SADMIN.CFG FILE).
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                               # 0=None 1=AlertOnError 2=AlertOnOK 3=Always
#export SADM_ALERT_GROUP="default"                      # Alert Group to advise (alert_group.cfg)
#export SADM_MAIL_ADDR="your_email@domain.com"          # Email to send log (Override sadmin.cfg)
#export SADM_MAX_LOGLINE=500                            # At the end Trim log to 500 Lines(0=NoTrim)
#export SADM_MAX_RCLINE=35                              # At the end Trim rch to 35 Lines (0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================



# --------------------------------------------------------------------------------------------------
#                                   This Script environment variables
# --------------------------------------------------------------------------------------------------
export NTP_SERVER="68.69.221.61 162.159.200.1 205.206.70.2"             # Canada NTP Pool



# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    ERROR_COUNT=0
    sadm_writelog "*** Running SADM System Startup Script on $(sadm_get_fqdn)  ***"
    sadm_writelog " "
    
    sadm_writelog "Running Startup Standard Procedure"
    sadm_writelog "  Removing old files (log,pid) in ${SADM_TMP_DIR}"
    rm -f ${SADM_TMP_DIR}/* >> $SADM_LOG 2>&1

    sadm_writelog "  Removing SADM System Monitor Lock File ${SADM_BASE_DIR}/sysmon.lock"
    rm -f ${SADM_BASE_DIR}/sysmon.lock >> $SADM_LOG 2>&1

    sadm_writelog "  Synchronize System Clock with NTP server $NTP_SERVER"
    sleep 2
    ntpdate -u $NTP_SERVER >$SADM_TMP_FILE1 2>&1
    if [ $? -ne 0 ] 
        then sadm_writelog "  NTP Error Synchronizing Time with $NTP_SERVER" 
             cat $SADM_TMP_FILE1 | while read wline ; do sadm_writelog "$wline"; done
             ERROR_COUNT=$(($ERROR_COUNT+1))
    fi
             
    sadm_writelog "  Start 'nmon' performance system monitor tool"
    ${SADM_BIN_DIR}/sadm_nmon_watcher.sh > /dev/null 2>&1
    if [ $? -ne 0 ] 
        then sadm_writelog "  Error starting 'nmon' System Monitor." 
             ERROR_COUNT=$(($ERROR_COUNT+1))
    fi

    # Special Operation for some particular System
    sadm_writelog " "
    sadm_writelog "Starting specific startup procedure for $SADM_HOSTNAME"
    case "$SADM_HOSTNAME" in
        "myhost" )      sadm_writelog "  Start SysInfo Web Server"
                        /myapp/bin/start_httpd.sh >> $SADM_LOG 2>&1
                        if [ $? -ne 0 ] 
                            then sadm_writelog "  Error starting 'MyApp httpd' Service." 
                                 ERROR_COUNT=$(($ERROR_COUNT+1))
                        fi
                        ;;
                *)      sadm_writelog "  No particular procedure needed for $SADM_HOSTNAME"
                        ;;
    esac

    sadm_writelog " "
    return $ERROR_COUNT                                              # Return Default return code
}
 
# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_writelog "End of startup script."                              # End of Script Message
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
