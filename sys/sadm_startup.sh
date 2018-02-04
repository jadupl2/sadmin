#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_startup.sh
#   Date:       25 October 2015
#   Synopsis:   This script is run when the system is started (via sadmin.service).
#               Called by /etc/systemd/system/sadmin.service
# --------------------------------------------------------------------------------------------------
#set -x
#
# Version 2.2 - June 2017
#               Log Enhancement
# Version 2.3 - June 2017
#               Restructure to use the SADM Library and Send email on execution.
# Version 2.4 - June 2017
#               Added removal of files in (pid) /sadmin/tmp at system boot
# Version 2.5 - June 2017
#               Added removal of sysmon lock file (/sadmin/sysmon.lock) at system boot
# Version 2.6 - June 2017
#               Added Clock Synchronization with 0.ca.pool.ntp.org
# Version 2.7 - July 2017
#               Add Section to put command to execute on specified Systems
# Version 2.8 - July 2017
#               Message display when starting Cosmetic Change 
# 2017_08_03 JDuplessis 
#   V2.9 Bug Fix - Missing Quote
# 2018_01_27 JDuplessis 
#   V3.0a Start 'nmon' as standard startup procedure 
# 2018_01_31 JDuplessis 
#   V3.1 Added execution of /etc/profile.d/sadmin.sh to have SADMIN Env. Var. Defined
# 2018_02_02 JDuplessis 
#   V3.2 Redirect output of starting nmon in the log (already log by sadm_nmon_watcher.sh).
# 2018_02_04 JDuplessis 
#   V3.3 Remove all pid when starting server - Make sure there is no leftover.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x 
. /etc/profile.d/sadmin.sh                                              # Get SADMIN Var. Defined


#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='3.3'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="Y"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#




# --------------------------------------------------------------------------------------------------
#                                   This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
SADM_MAIL_TYPE=3                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
NTP_SERVER="0.ca.pool.ntp.org"              ; export NTP_SERVER         # Canada NTP Pool



# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    sadm_writelog "*** Running SADM System Startup Script on $(sadm_get_fqdn)  ***"
    sadm_writelog " "
    
    sadm_writelog "Running Startup Standard Procedure"
    sadm_writelog "  Removing old files (log,pid) in ${SADM_TMP_DIR}"
    rm -f ${SADM_TMP_DIR}/* >> $SADM_LOG 2>&1

    sadm_writelog "  Removing SADM System Monitor Lock File ${SADM_BASE_DIR}/sysmon.lock"
    rm -f ${SADM_BASE_DIR}/sysmon.lock >> $SADM_LOG 2>&1

    sadm_writelog "  Synchronize System Clock with NTP server $NTP_SERVER"
    ntpdate -u $NTP_SERVER >> $SADM_LOG 2>&1

    sadm_writelog "  Start 'nmon' System Monitor"
    ${SADM_BIN_DIR}/sadm_nmon_watcher.sh > /dev/null 2>&1

    # Special Operation for some particular System
    sadm_writelog " "
    sadm_writelog "Starting specific startup procedure for $SADM_HOSTNAME"
    case "$SADM_HOSTNAME" in
        "raspi4" )      sadm_writelog "  systemctl restart rpcbind"
                        systemctl restart rpcbind >> $SADM_LOG 2>&1
                        sadm_writelog "  systemctl restart nfs-kernel-server"
                        systemctl restart nfs-kernel-server >> $SADM_LOG 2>&1
                        ;;
        "nomad" )       sadm_writelog "  Start SysInfo Web Server"
                        /sysinfo/bin/start_httpd.sh >> $SADM_LOG 2>&1
                        ;;
        "holmes" )      umount /run/media/jacques/5f5a5d54-7c43-4122-8055-ec8bbc2d08d5  >/dev/null 2>&1
                        umount /run/media/jacques/C113-470B >/dev/null 2>&1
                        umount /run/media/jacques/b3a2bafd-f722-4b20-b09c-cf950744f24d >/dev/null 2>&1
                        #sadm_writelog "  Mount External USB (Storix Backup)"
                        #sadm_writelog "  mount /disk01"
                        #mount /disk01  >> $SADM_LOG 2>&1
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
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by user 'root'"      # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
