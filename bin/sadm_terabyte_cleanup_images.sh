#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script is run to keep only $NB_COPY of each terabyte server image into
#               $TERABYTE_IMG_DIR
#   Synopsis:   This script is used to delete old terabyte image from the image repository on NAS
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
    sadm_logger "${SA_LINE}"
    sadm_logger "Keep $NB_COPY copies of TeraByte images per host"


    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${NFS_LOC_MOUNT} ]
        then mkdir ${NFS_LOC_MOUNT} ; chmod 2775 ${NFS_LOC_MOUNT} ; fi
        
    # Check to make sure it is not already mounted
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
    
    # Mount the NFS drive on the NAS
    sadm_logger "${SA_LINE}"
    sadm_logger "Mount the NAS NFS"
    sadm_logger "mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}"
    mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}
    RC=$?

    # If the mount NFS did not work - Abort Script after advising user (update logs)
    if [ $RC -ne 0 ]
        then sadm_logger " "
             sadm_logger "SCRIPT ABORTED - UNABLE TO MOUNT NFS DRIVE ON THE NAS"
             return 1
    fi

    # Change to OS Image Directory
    cd ${NFS_LOC_MOUNT}
    sadm_logger "${SA_LINE}"
    sadm_logger "List of current TeraByte Images in `pwd`"
    ls -lt | nl >> $LOG
    sadm_logger " "
        
    for WSERVER in $TERA_SERVER
        do
        sadm_logger " "
        sadm_logger "${SA_LINE}"
        sadm_logger "List of Terabyte Images for server ${WSERVER}"
        ls -lt *_${WSERVER}.TBI >> $LOG
        FILE_COUNT=`ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d | wc -l`
        if [ "$FILE_COUNT" -ne 0 ]
            then    sadm_logger " "
                    sadm_logger "Number of TBI file(s) to delete is $FILE_COUNT"
                    sadm_logger "Terabyte TBI File(s) Deleted :"
                    ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d >> $LOG
                    ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d | xargs rm -f >> $LOG 2>&1
                    RC=$?
                    if [ $RC -ne 0 ]
                        then    sadm_logger "RESULT : Error $RC returned while cleaning up ${WSERVER} TBI files"
                                RC=1
                        else    sadm_logger "RESULT : Clean up of ${WSERVER} went OK"
                                RC=0
                    fi
            else    RC=0
                    sadm_logger "RESULT : No file(s) to delete for ${WSERVER} - OK"
        fi 
        GLOBAL_ERROR=`echo $GLOBAL_ERROR + $RC | bc `
        sadm_logger "Total of Error is $GLOBAL_ERROR"
        done
    
     # Umount THE NFS Mount of the Terabyte Images
    sadm_logger "${SA_LINE}"
    cd $BASE_DIR
    sadm_logger "Unmount NAS NFS"
    sadm_logger "umount ${NFS_LOC_MOUNT}"
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
    
    sadm_logger "${SA_LINE}"
    sadm_logger "Grand Total of Error is $GLOBAL_ERROR"
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


