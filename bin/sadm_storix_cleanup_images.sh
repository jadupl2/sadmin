#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script is run to keep only $NB_COPY of each server image into $NFS_REM_MOUNT
#   Synopsis:   This script is used to elete old storix image from the image repository.
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#

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
NB_COPY=2                                      ; export NB_COPY         # Nb. Copy of images to keep
REMOTE_HOST="nas_storix.maison.ca"             ; export REMOTE_HOST     # NAS BOX NAME
NFS_REM_MOUNT="/volume1/storix/image"          ; export NFS_REM_MOUNT   # Remote NFS Mount Point
NFS_LOC_MOUNT="/mnt/storix"                    ; export NFS_LOC_MOUNT   # Local NFS Mount Point
NFS_STORIX_DIR="/storix"                       ; export NFS_STORIX_DIR  # Where Storix TOC File Are

																				     
# ==================================================================================================
#           Function to only keep $NB_COPY of each server image on the server
# ==================================================================================================
clean_storix_dir()
{
    write_log "${SA_LINE}"
    write_log "Keep only $NB_COPY copies of Storix images per host"

    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${NFS_LOC_MOUNT} ]
        then mkdir ${NFS_LOC_MOUNT} ; chmod 2775 ${NFS_LOC_MOUNT} ; fi
        
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

    cd ${NFS_LOC_MOUNT}

    # Build a list of all hostname that have a backup in $NFS_REM_MOUNT
    write_log "${SA_LINE}"
    ls -1 SB:*:TOC* | cut -d: -f4 | sort -u | while read stclient
          do
          write_log "Checking images of host $stclient ..."
        
          # For each backup ID to be removed...
          ls -1t SB:*${stclient}*TOC* | sed "1,${NB_COPY}d" | cut -d: -f5 | while read backupid
            do
  
                # Delete all files related to this backup ID
                write_log " "
                write_log "Need to delete image backup ID #$backupid of $stclient ..."
                ls -1 SB:*:*:*:$backupid:*:* | while read backup_file
                    do
                        write_log "Deleting file $backup_file ..."
                        #ls -l $backup_file
                        rm -f $backup_file
                    done
                write_log " "
            done
          done
          
   # Umount THE NFS Mount of the Images
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
   
    return 0
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                          # Initialize the LOG and RC File - Check existence of Dir.
    clean_storix_dir                    # Clean up old multiple copies of Storix Images
    rc=$? ; export rc                   # Save Return Code
    sadm_stop $rc                       # Saveand trim Logs
    exit $GLOBAL_ERROR                  # Exit with Error code value


