#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script is run to keep only $NB_COPY of each server image into $NFS_REM_MOUNT
#   Synopsis:   This script is used to elete old storix image from the image repository.
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# Change Log
# 2017_07_31 JDuplessis
#   V1.9  Added cleanup for Local USB Disk
# 2017_08_07 JDuplessis
#   V1.10 Added umount to make sure Storix USB Backup work
# 2017_08_10 JDuplessis
#   V1.11 Usage of USB External is an option now, based on USB_ATTACH Variable
# 2018_05_20 JDuplessis
#   V1.12 Fix /mnt/storix not unmounting at the end of clean up
#
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
SADM_VER='1.12'                            ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh

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
NB_COPY=2                                      ; export NB_COPY         # Nb. Copy of images to keep
REMOTE_HOST="batnas.maison.ca"                 ; export REMOTE_HOST     # NAS BOX NAME
NFS_REM_MOUNT="/volume1/storix/image"          ; export NFS_REM_MOUNT   # Remote NFS Mount Point
NFS_LOC_MOUNT="/mnt/storix"                    ; export NFS_LOC_MOUNT   # Local NFS Mount Point
NFS_STORIX_DIR="/storix"                       ; export NFS_STORIX_DIR  # Where Storix TOC File Are

USB_ATTACH="Y"                                 ; export USB_ATTACH      # (Y/N) Yes if USB is Attach
USB_LOC_MOUNT="/disk01"                        ; export USB_LOC_MOUNT   # Local USB Mount Point
USB_NBCOPY=12                                  ; export USB_NBCOPY      # Nb Image to keep on USB

# ==================================================================================================
#           Function to only keep $NB_COPY of each server image on the server
# ==================================================================================================
clean_nfs_storix_dir()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Keep only $NB_COPY copies of Storix images per host"

    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${NFS_LOC_MOUNT} ]
        then mkdir ${NFS_LOC_MOUNT} ; chmod 2775 ${NFS_LOC_MOUNT} ; fi

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

    cd ${NFS_LOC_MOUNT}

    # Build a list of all hostname that have a backup in $NFS_REM_MOUNT
    sadm_writelog "${SADM_TEN_DASH}"
    ls -1 SB:*:TOC* | cut -d: -f4 | sort -u | while read stclient
          do
          sadm_writelog "Checking images of host $stclient ..."

          # For each backup ID to be removed...
          ls -1t SB:*${stclient}*TOC* | sed "1,${NB_COPY}d" | cut -d: -f5 | while read backupid
            do

                # Delete all files related to this backup ID
                sadm_writelog " "
                sadm_writelog "Need to delete image backup ID #$backupid of $stclient ..."
                ls -1 SB:*:*:*:$backupid:*:* | while read backup_file
                    do
                        sadm_writelog "Deleting file $backup_file ..."
                        #ls -l $backup_file
                        rm -f $backup_file
                    done
                sadm_writelog " "
            done
          done

    # Umount THE NFS Mount of the Images
    cd /
    sadm_writelog "Unmounting $USB_LOC_MOUNT"
    umount $USB_LOC_MOUNT >/dev/null 2>&1
    return 0
}



# ==================================================================================================
#           Function to only keep $NB_COPY of each server image on the server
# ==================================================================================================
clean_usb_storix_dir()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Keep only $USB_NBCOPY copies of Storix images on USB Disk"

    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${USB_LOC_MOUNT} ]
        then mkdir ${USB_LOC_MOUNT} ; chmod 2775 ${USB_LOC_MOUNT} ; fi

    # Mount Local USB Drive
    sadm_writelog "Mounting $USB_LOC_MOUNT"
    umount /run/media/jacques/5f5a5d54-7c43-4122-8055-ec8bbc2d08d5  >/dev/null 2>&1
    umount /run/media/jacques/C113-470B >/dev/null 2>&1
    umount /run/media/jacques/b3a2bafd-f722-4b20-b09c-cf950744f24d >/dev/null 2>&1
    umount $USB_LOC_MOUNT >/dev/null 2>&1
    mount $USB_LOC_MOUNT >/dev/null 2>&1
    RC=$?
    # If the mount NFS did not work - Abort Script after advising user (update logs)
    if [ $RC -ne 0 ]
        then sadm_writelog "Script Aborted - The USB isn't mounted on $USB_LOC_MOUNT"
             return 1
    fi

    # Check if USB Disk is Mounted
    sadm_writelog "Verifying if the USB disk is mounted on $USB_LOC_MOUNT"
    #sadm_writelog "mount | grep '$USB_LOC_MOUNT'"
    mount | awk '{ print $3 }' | grep "$USB_LOC_MOUNT" > /dev/null 2>&1
    RC=$?

    # If the mount NFS did not work - Abort Script after advising user (update logs)
    if [ $RC -ne 0 ]
        then sadm_writelog "Script Aborted - The USB isn't mounted on $USB_LOC_MOUNT"
             return 1
    fi

    cd ${USB_LOC_MOUNT}
    # Build a list of all hostname that have a backup in $USB_LOC_MOUNT
    #sadm_writelog "${SADM_TEN_DASH}"
    ls -1 SB:*:TOC* | cut -d: -f4 | sort -u | while read stclient
          do
          sadm_writelog "Checking images of host $stclient ..."

          # For each backup ID to be removed...
          ls -1t SB:*${stclient}*TOC* | sed "1,${USB_NBCOPY}d" | cut -d: -f5 | while read backupid
            do

                # Delete all files related to this backup ID
                sadm_writelog " "
                sadm_writelog "Need to delete image backup ID #$backupid of $stclient ..."
                ls -1 SB:*:*:*:$backupid:*:* | while read backup_file
                    do
                        sadm_writelog "Deleting file $backup_file ..."
                        #ls -l $backup_file
                        rm -f $backup_file
                    done
                sadm_writelog " "
            done
          done

    # UnMount Local USB Drive
    cd /
    sadm_writelog "Unmounting $USB_LOC_MOUNT"
    umount $USB_LOC_MOUNT >/dev/null 2>&1

    return 0
}

# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    rc1=0 ; rc2=0 ; export rc1 rc2                                      # Reset Error Indicator to 0
    clean_nfs_storix_dir                                                # Clean up NFS multiple copy
    rc1=$? ; export rc1                                                 # Save Return Code
    if [ "$USB_ATTACH" == "Y" ]                                         # If USB Attached to Server 
        then clean_usb_storix_dir                                       # Clean up USB multiple copy
             rc2=$? ; export rc2                                        # Save Return Code
    fi
    SADM_EXIT_CODE=$(($rc1+$rc2))                                       # Total Errors

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE