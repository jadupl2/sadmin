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
#
# 2017_07_31    V1.9  Added cleanup for Local USB Disk
# 2017_08_07    V1.10 Added umount to make sure Storix USB Backup work
# 2017_08_10    V1.11 Usage of USB External is an option now, based on USB_ATTACH Variable
# 2018_05_20    V1.12 Fix /mnt/storix not unmounting at the end of clean up
# 2018_06_04    V1.13 Adapt to new SADMIN Libr.
# 2018_06_12    V1.14 Fix umounting problem with NFS & add List of USB Backup Images before cleanup
# 2018_07_22    V1.15 Change Message showing number image to keep
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x




#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.15'                              # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================





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
    sadm_writelog "Keep $NB_COPY copies of Storix images per host"

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
    sadm_writelog "Unmounting ${NFS_LOC_MOUNT}"
    umount ${NFS_LOC_MOUNT} >/dev/null 2>&1
    if [ $? -ne 0 ] 
        then sadm_writelog "Cannot unmount ${NFS_LOC_MOUNT}"
    fi
    return 0
}



# ==================================================================================================
#           Function to only keep $NB_COPY of each server image on the server
# ==================================================================================================
clean_usb_storix_dir()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Keep $USB_NBCOPY copies of Storix images on USB Disk"

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
    sadm_writelog "Listing images of USB Disk"
    ls -lt SB:*:TOC* | sort | nl 
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
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Check NFS Storix Backup
    rc1=0 ; rc2=0 ; export rc1 rc2                                      # Reset Error Indicator to 0
    clean_nfs_storix_dir                                                # Clean up NFS multiple copy
    rc1=$? ; export rc1                                                 # Save Return Code

    # If USB Disk attach to server, do cleanup on it too.
    if [ "$USB_ATTACH" == "Y" ]                                         # If USB Attached to Server 
        then clean_usb_storix_dir                                       # Clean up USB multiple copy
             rc2=$? ; export rc2                                        # Save Return Code
    fi
    SADM_EXIT_CODE=$(($rc1+$rc2))                                       # Total Errors

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE