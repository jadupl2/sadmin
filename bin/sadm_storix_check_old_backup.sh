#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Check for old Storix Backup - Check the Date of the TOC and ISO file
#               If backup older than $LIMIT_DAYS send email alert
#               May Indicating problem (Backup not taken)
#   Synopsis:   This script is used to identify Storix backup not taken
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
set -x
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
LIMIT_DAYS=15                                  ; export LIMIT_DAYS      # Max. days before warning 
REMOTE_HOST="nas_storix.maison.ca"             ; export REMOTE_HOST     # NAS BOX NAME
NFS_REM_MOUNT="/volume1/storix"                ; export NFS_REM_MOUNT   # Remote NFS Mount Point
NFS_LOC_MOUNT="/mnt/storix"                    ; export NFS_LOC_MOUNT   # Local NFS Mount Point
STORIX_ISO_DIR="${NFS_LOC_MOUNT}/iso"          ; export STORIX_ISO_DIR  # Storix ISO Directory
STORIX_IMG_DIR="${NFS_LOC_MOUNT}/image"        ; export STORIX_IMG_DIR  # Storix Image Directory
																				     
# ==================================================================================================
#           Function to check Storix Backup Date are older than $LIMIT_DAYS
# ==================================================================================================
check_storix_date()
{
    write_log "${SA_LINE}"  
    write_log "Check Storix Backup older than ${LIMIT_DAYS} days on ${REMOTE_HOST} in ${NFS_REM_MOUNT}" 
    
    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${NFS_LOC_MOUNT} ] ; then mkdir ${NFS_LOC_MOUNT} ; chmod 2775 ${NFS_LOC_MOUNT} ; fi
        
    # Check to make sure it is not already mounted
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
     
    # Mount the NFS drive on the NAS
    write_log "Mounting the NAS NFS"
    write_log "mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}"
    mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}
    RC=$?

    # If the mount NFS did not work - Abort Script after advising user (update logs)
    if [ $RC -ne 0 ]
        then write_log "Script Aborted - Unable to mount NFS Drive on the NAS"
             return 1
    fi

    # Check for outdated Storix TOC files
    write_log "${SA_LINE}" 
    write_log "Verification of Storix TOC Files older than ${LIMIT_DAYS} days."
    find $STORIX_IMG_DIR -type f -mtime +${LIMIT_DAYS} -name "*:TOC*" -ls > $SADM_TMP_FILE1
    LATE_BACKUP=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`
    if [ $LATE_BACKUP -eq 0 ] 
       then write_log "No Storix backup are dated more than ${LIMIT_DAYS} days"  
            RC1=0
       else RC1=1           
            write_log "There are ${LATE_BACKUP} images that are older than ${LIMIT_DAYS} days."
            cat $SADM_TMP_FILE1 >>  $LOG
    fi
    write_log "${SA_LINE}" 
 
    # Check for outdated Storix ISO files
    write_log "Verification of Storix ISO Files older than ${LIMIT_DAYS} days."
    find $STORIX_ISO_DIR -type f -mtime +${LIMIT_DAYS} -name "*.iso" -ls > $SADM_TMP_FILE1
    LATE_BACKUP=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`
    if [ $LATE_BACKUP -eq 0 ] 
       then write_log "No Storix ISO are dated more than ${LIMIT_DAYS} days"  
            RC2=0
       else RC2=1
            write_log "There are ${LATE_BACKUP} ISO File(s) that are older than ${LIMIT_DAYS} days."
            cat $SADM_TMP_FILE1 >>  $LOG
    fi
   write_log "${SA_LINE}" 
 
    # Add the two results code and return it to function caller
    RC=$(($RC1+$RC2))                                                  # Total  Errors    
    if [ "$RC" -ne 0 ] ; then RC=1 ; fi
   
    # Umount THE NFS Mount of the Terabyte Images
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
    
    return $RC
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                          # Initialize the LOG and RC File - Check existence of Dir.
    check_storix_date                   # Check if got Storix Backup older than LIMIT_DAY
    SADM_EXIT_CODE=$?                     # Save Return Code
    sadm_stop $SADM_EXIT_CODE             # Saveand trim Logs
    exit $SADM_EXIT_CODE                  # Exit with Error code value
    


