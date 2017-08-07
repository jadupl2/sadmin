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
# 2017_08_03 JDuplessis - V2.9 Bug Fix - Missing Quote
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='2.9'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="Y"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
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
    sadm_writelog "  Removing old files in ${SADM_TMP_DIR}"
    rm -f ${SADM_TMP_DIR}/* >> $SADM_LOG 2>&1

    sadm_writelog "  Removing SADM System Monitor Lock File ${SADM_BASE_DIR}/sysmon.lock"
    rm -f ${SADM_BASE_DIR}/sysmon.lock >> $SADM_LOG 2>&1

    sadm_writelog "  Synchronize System Clock with NTP server $NTP_SERVER"
    ntpdate -u $NTP_SERVER >> $SADM_LOG 2>&1

    # Special Operation for some particular System
    sadm_writelog " "
    sadm_writelog "Starting particular startup procedure for $SADM_HOSTNAME"
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
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
