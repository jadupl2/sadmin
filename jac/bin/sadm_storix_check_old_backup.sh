#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Check for old Storix Backup - Check the Date of the TOC and ISO file
#               If backup older than $LIMIT_DAYS send email alert
#               May Indicating problem (Backup not taken)
#   Synopsis:   This script is used to identify Storix backup not taken
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#set -x
#
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2017_07_31 JDuplessis - V1.8 Adding ISO and TOC directory location in the script log
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
SADM_VER='1.8'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
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
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                                  ; export DEBUG_LEVEL     # 0=NoDebug Higher=+Verbose
LIMIT_DAYS=60                                  ; export LIMIT_DAYS      # Max. days before warning
REMOTE_HOST="batnas.maison.ca"                 ; export REMOTE_HOST     # NAS BOX NAME
NFS_REM_MOUNT="/volume1/storix"                ; export NFS_REM_MOUNT   # Remote NFS Mount Point
NFS_LOC_MOUNT="/mnt/storix"                    ; export NFS_LOC_MOUNT   # Local NFS Mount Point
STORIX_ISO_DIR="${NFS_LOC_MOUNT}/iso"          ; export STORIX_ISO_DIR  # Storix ISO Directory
STORIX_IMG_DIR="${NFS_LOC_MOUNT}/image"        ; export STORIX_IMG_DIR  # Storix Image Directory

# ==================================================================================================
#           Function to check Storix Backup Date are older than $LIMIT_DAYS
# ==================================================================================================
check_storix_date()
{
    #sadm_writelog "${SADM_TEN_DASH}"
    #sadm_writelog "Check Storix Backup older than ${LIMIT_DAYS} days on ${REMOTE_HOST} in ${NFS_REM_MOUNT}"

    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${NFS_LOC_MOUNT} ] ; then mkdir ${NFS_LOC_MOUNT} ; chmod 2775 ${NFS_LOC_MOUNT} ; fi

    # Check to make sure it is not already mounted
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1

    # Mount the NFS drive on the NAS
    sadm_writelog "Mounting the NAS NFS"
    sadm_writelog "mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}"
    mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}
    RC=$?

    # If the mount NFS did not work - Abort Script after advising user (update logs)
    if [ $RC -ne 0 ]
        then sadm_writelog "Script Aborted - Unable to mount NFS Drive on the NAS"
             return 1
    fi

    # Check for outdated Storix TOC files
    sadm_writelog " " ; sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Identifying Storix TOC Files older than ${LIMIT_DAYS} days in $STORIX_IMG_DIR"
    find $STORIX_IMG_DIR -type f -mtime +${LIMIT_DAYS} -name "*:TOC*" -ls > $SADM_TMP_FILE1
    LATE_BACKUP=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`
    if [ $LATE_BACKUP -eq 0 ]
       then sadm_writelog "No Storix backup are dated more than ${LIMIT_DAYS} days"
            RC1=0
       else RC1=1
            sadm_writelog "There are ${LATE_BACKUP} images that are older than ${LIMIT_DAYS} days."
            cat $SADM_TMP_FILE1 | tee -a  $SADM_LOG
    fi

    # Check for outdated Storix ISO files
    sadm_writelog " " ; sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Identifying Storix ISO Files older than ${LIMIT_DAYS} days in $STORIX_ISO_DIR"
    find $STORIX_ISO_DIR -type f -mtime +${LIMIT_DAYS} -name "*.iso" -ls > $SADM_TMP_FILE1
    LATE_BACKUP=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'`
    if [ $LATE_BACKUP -eq 0 ]
       then sadm_writelog "No Storix ISO are dated more than ${LIMIT_DAYS} days"
            RC2=0
       else RC2=1
            sadm_writelog "There are ${LATE_BACKUP} ISO File(s) that are older than ${LIMIT_DAYS} days."
            cat $SADM_TMP_FILE1 | tee -a $SADM_LOG
    fi
   sadm_writelog " "

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
