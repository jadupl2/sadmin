#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script rsync all the content of Storix ISO directory onto the NAS BOX.
#               This script is run daily after the image backup are done 
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#set -x
#set -x
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH VARIABLES AND
#   FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
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
    rsync_storix_iso                    # Rsync local Storix ISO with Remote NAS Dir.
    rc=$? ; export rc                   # Save Return Code
    sadm_stop $rc                       # Saveand trim Logs
    exit $GLOBAL_ERROR                  # Exit with Error code value


