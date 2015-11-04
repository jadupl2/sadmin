#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script is run to keep only $NB_COPY of each terabyte server image into
#               $TERABYTE_IMG_DIR
#   Synopsis:   This script is used to delete old terabyte image from the image repository on NAS
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#set -x

# --------------------------------------------------------------------------------------------------
#  These variables got to be defined prior to calling the initialize (sadm_init.sh) script
#  These variables are use and needed by the sadm_init.sh script.
#  Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.0'                                      ; export VER             # Program version
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
NB_COPY=4                                      ; export NB_COPY         # Nb. Copy of images to keep
REMOTE_HOST="batnas.maison.ca"                 ; export REMOTE_HOST     # NAS BOX NAME
NFS_REM_MOUNT="/volume1/os_images/terabyte"    ; export NFS_REM_MOUNT   # Remote NFS Mount Point
NFS_LOC_MOUNT="/mnt/tera"                      ; export NFS_LOC_MOUNT   # Local NFS Mount Point

# List of servers that have terabyte images 
TERA_SERVER="holmes   watson sherlock hercule quatro"

																				     
# ==================================================================================================
#           Function to only keep $NB_COPY of each windows server image on the server
# ==================================================================================================
clean_terabyte_dir()
{
    GLOBAL_ERROR=0
    write_log "${SA_LINE}"
    write_log "Keep $NB_COPY copies of TeraByte images per host"


    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${NFS_LOC_MOUNT} ]
        then mkdir ${NFS_LOC_MOUNT} ; chmod 2775 ${NFS_LOC_MOUNT} ; fi
        
    # Check to make sure it is not already mounted
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
    
    # Mount the NFS drive on the NAS
    write_log "${SA_LINE}"
    write_log "Mount the NAS NFS"
    write_log "mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}"
    mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}
    RC=$?

    # If the mount NFS did not work - Abort Script after advising user (update logs)
    if [ $RC -ne 0 ]
        then write_log " "
             write_log "SCRIPT ABORTED - UNABLE TO MOUNT NFS DRIVE ON THE NAS"
             return 1
    fi

    # Change to OS Image Directory
    cd ${NFS_LOC_MOUNT}
    write_log "${SA_LINE}"
    write_log "List of current TeraByte Images in `pwd`"
    ls -lt | nl >> $LOG
    write_log " "
        
    for WSERVER in $TERA_SERVER
        do
        write_log " "
        write_log "${SA_LINE}"
        write_log "List of Terabyte Images for server ${WSERVER}"
        ls -lt *_${WSERVER}.TBI >> $LOG
        FILE_COUNT=`ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d | wc -l`
        if [ "$FILE_COUNT" -ne 0 ]
            then    write_log " "
                    write_log "Number of TBI file(s) to delete is $FILE_COUNT"
                    write_log "Terabyte TBI File(s) Deleted :"
                    ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d >> $LOG
                    ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d | xargs rm -f >> $LOG 2>&1
                    RC=$?
                    if [ $RC -ne 0 ]
                        then    write_log "RESULT : Error $RC returned while cleaning up ${WSERVER} TBI files"
                                RC=1
                        else    write_log "RESULT : Clean up of ${WSERVER} went OK"
                                RC=0
                    fi
            else    RC=0
                    write_log "RESULT : No file(s) to delete for ${WSERVER} - OK"
        fi 
        GLOBAL_ERROR=`echo $GLOBAL_ERROR + $RC | bc `
        write_log "Total of Error is $GLOBAL_ERROR"
        done
    
     # Umount THE NFS Mount of the Terabyte Images
    write_log "${SA_LINE}"
    cd $BASE_DIR
    write_log "Unmount NAS NFS"
    write_log "umount ${NFS_LOC_MOUNT}"
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
    
    write_log "${SA_LINE}"
    write_log "Grand Total of Error is $GLOBAL_ERROR"
    return $GLOBAL_ERROR
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                          # Initialize the LOG and RC File - Check existence of Dir.
    clean_terabyte_dir                  # Clean up old multiple copies of Storix Images
    rc=$? ; export rc                   # Save Return Code
    sadm_stop $rc                       # Saveand trim Logs
    exit $GLOBAL_ERROR                  # Exit with Error code value


