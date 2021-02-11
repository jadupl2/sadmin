#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_shutdown.sh
#   Date:       25 October 2015
#   Synopsis:   This script is run when the sadmin.service is shutdown when server goes down.
#               Called by /etc/systemd/system/sadmin.service (systemd) or /etc/init.d/sadmin (SysV)
# --------------------------------------------------------------------------------------------------
# Version 2.2 - Log Enhancement
# Version 2.3 - Restructure to use the SADM Library and Send email on execution.
# Version 2.4 - Add sleep of 5 sec. at the end, to allow completion of sending email before shutdown
# Version 2.5 - Added code to run shutdown command based on Hostname
# 2017_08_05    V2.6 Send email only on Execution Error
# 2018_01_31    V2.7 Added execution of /etc/profile.d/sadmin.sh to have SADMIN Env. Var. Defined
# 2018_09_19    V2.8 Added Alert Group Utilization
# 2018_10_18    v2.9 Remove execution of /etc/profile.d/sadmin.sh (Don't need anymore)
#@2019_03_29 Update: v2.10 Get SADMIN Directory Location from /etc/environment
#@2020_05_27 Fix: v2.11 Force using bash instead of dash & problem setting SADMIN env. variable.
#@2020_11_04 Minor: v2.12 Update SADMIN section & use env cmd to use proper bash shell.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT ^C
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
export SADM_VER='2.12'                                  # Current Script Version
export SADM_EXIT_CODE=0                                 # Current Script Default Exit Return Code
export SADM_LOG_TYPE="B"                                # writelog go to [S]creen [L]ogFile [B]oth
export SADM_LOG_APPEND="Y"                              # [Y]=Append Existing Log [N]=Create New One
export SADM_LOG_HEADER="Y"                              # [Y]=Include Log Header  [N]=No log Header
export SADM_LOG_FOOTER="Y"                              # [Y]=Include Log Footer  [N]=No log Footer
export SADM_MULTIPLE_EXEC="N"                           # Allow running multiple copy at same time ?
export SADM_USE_RCH="Y"                                 # Gen. History Entry in ResultCodeHistory 
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




# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    sadm_writelog "*** Running SADM System Shutdown Script on $(sadm_get_fqdn)  ***"
    sadm_writelog " "


    # Special Operation for some particular System
    sadm_writelog " "
    sadm_writelog "Shutdown procedure for $SADM_HOSTNAME"
    case "$SADM_HOSTNAME" in
        "myhost" )      sadm_writelog "Stop MyApp Web Server ..."
                        /myapp/bin/stop_httpd.sh >> $SADM_LOG 2>&1
                        ;;
                *)      sadm_writelog "  No particular procedure needed for $SADM_HOSTNAME"
                        ;;
    esac

    sadm_writelog " "
    return 0                                                            # Return Default return code
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
             exit 1                                                     # Exit To O/S
    fi
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
