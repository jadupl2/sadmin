#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script rsync all the content of Storix ISO directory onto the NAS BOX.
#               This script is run daily after the image backup are done 
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#set -x
 
# --------------------------------------------------------------------------------------------------
#  These variables got to be defined prior to calling the initialize (sadm_init.sh) script
#  These variables are use and needed by the sadm_init.sh script.
#  Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='3.1'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Output to log=0 1=Screen+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Of Line in RCLOG (Trim)
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
#
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -f ${BASE_DIR}/lib/sadm_init.sh ] && . ${BASE_DIR}/lib/sadm_init.sh   # Init Var. & Load sadm functions
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
    write_log "${SA_LINE}"  
    write_log "Rsync the local directory $LOCAL_ISO_DIR with ${REMOTE_HOST}:${REMOTE_ISO_DIR}" 
    write_log "rsync -e 'ssh -p 22' -vrOltD --delete ${LOCAL_ISO_DIR}/ ${REMOTE_HOST}:${REMOTE_ISO_DIR}/"
    write_log " "
    rsync -e 'ssh -p 22' -vrOltD --delete ${LOCAL_ISO_DIR}/ ${REMOTE_HOST}:${REMOTE_ISO_DIR}/ >> $LOG  2>&1
    rc=$? ; export rc                                                    # Save Return Code
 
    # If error was reported  
    if [ "$rc" -ne 0 ]
        then write_log "Rsync ISO - Error $rc returned"
             rc=1
        else write_log "SUCCESS - No error reported by synchronization of iso files"
    fi
    return $rc
}

# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                          # Initialize the LOG and RC File - Check existence of Dir.
    rsync_storix_iso                    # Rsync local Storix ISO with Remote NAS Dir.
    rc=$? ; export rc                   # Save Return Code
    sadm_stop $rc                       # Saveand trim Logs
    exit $GLOBAL_ERROR                  # Exit with Error code value


