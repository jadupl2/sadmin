#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script rsync all the content of Storix ISO directory onto the NAS BOX.
#               This script is run daily after the image backup are done 
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#set -x
#
#
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $SADM_BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH
#   VARIABLES AND FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                               ; export SADM_PN         # Current Script name
SADM_VER='1.5'                                 ; export SADM_VER        # This Script Version
SADM_INST=`echo "$SADM_PN" |awk -F\. '{print $1}'` ; export SADM_INST   # Script name without ext.
SADM_TPID="$$"                                 ; export SADM_TPID       # Script PID
SADM_EXIT_CODE=0                               ; export SADM_EXIT_CODE  # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}             ; export SADM_BASE_DIR   # Script Root Base Directory
SADM_LOG_TYPE="B"                              ; export SADM_LOG_TYPE   # 4Logger S=Scr L=Log B=Both
#
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT (DEFAULT CAN BE CHANGED IN $SADM_BASE_DIR/cfg/sadmin.cfg)
#SADM_MAIL_ADDR="your_email@domain.com"        ; export ADM_MAIL_ADDR    # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE   # 0=No 1=Err 2=Succes 3=All
SADM_MAX_LOGLINE=5000                          ; export SADM_MAX_LOGLINE # Max Nb. Lines in LOG )
SADM_MAX_RCLINE=100                            ; export SADM_MAX_RCLINE  # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#

#
#

# This Script environment variable
LOCAL_ISO_DIR="/stbackups/iso"                ; export LOCAL_ISO_DIR    # Storix ISO Directory
REMOTE_HOST="nas_storix.maison.ca"            ; export REMOTE_HOST      # NAS BOX NAME
REMOTE_ISO_DIR="/volume1/storix/iso"          ; export REMOTE_ISO_DIR   # ISO Dir. on NAS Box

																				     
# ==================================================================================================
#           Rsync the Storix ISO Directory of local server to the NAS BOX
# ==================================================================================================
rsync_storix_iso()
{
    sadm_logger "${SA_LINE}"  
    sadm_logger "Rsync the local directory $LOCAL_ISO_DIR with ${REMOTE_HOST}:${REMOTE_ISO_DIR}" 
    sadm_logger "rsync -e 'ssh -p 22' -vrOltD --delete ${LOCAL_ISO_DIR}/ ${REMOTE_HOST}:${REMOTE_ISO_DIR}/"
    sadm_logger " "
    rsync -e 'ssh -p 22' -vrOltD --delete ${LOCAL_ISO_DIR}/ ${REMOTE_HOST}:${REMOTE_ISO_DIR}/ >> $LOG  2>&1
    rc=$? ; export rc                                                    # Save Return Code
 
    # If error was reported  
    if [ "$rc" -ne 0 ]
        then sadm_logger "Rsync ISO - Error $rc returned"
             rc=1
        else sadm_logger "SUCCESS - No error reported by synchronization of iso files"
    fi
    return $rc
}

# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                          # Initialize the LOG and RC File - Check existence of Dir.
        
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
        then sadm_logger "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
        
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    rsync_storix_iso                    # Rsync local Storix ISO with Remote NAS Dir.
    rc=$? ; export rc                   # Save Return Code
    sadm_stop $rc                       # Saveand trim Logs
    exit $SADM_EXIT_CODE                  # Exit with Error code value


