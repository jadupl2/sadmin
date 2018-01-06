#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_mksysb.sh
#   Synopsis : .
#   Version  :  1.6
#   Date     :  14 November 2015
#   Requires :  sh
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
# Enhancements/Corrections Version Log
# 1.5   Initial Version 
# 1.6   Minor Corrections
# 2018_01_04 JDuplessis
#   V1.7 Use the $SADMIN/cfg/sadmin.cfg NFS Information for mksysb destination
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x

#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.0'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                                 ;export DEBUG_LEVEL       # 0=NoDebug Higher=+Verbose
TOTAL_ERROR=0                                 ;export TOTAL_ERROR       # Total Rsync Error
LOCAL_MOUNT="/mnt/mksysb"                     ;export LOCAL_MOUNT_POINT # Local NFS Mnt Point 
OUTPUT_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}"  ;export OUTPUT_DIR        # Where Backup Stored

# Value below are taken for SADMIN configuration ($SADMIN/cfg/sadmin.cfg)
#SADM_MKSYSB_NFS_SERVER = batnfs.maison.ca
#SADM_MKSYSB_NFS_MOUNT_POINT = /volume1/mksysb
#SADM_MKSYSB_BACKUP_TO_KEEP = 2




# ==================================================================================================
#                Mount the NFS Directory where all the mksysb files will be stored
# ==================================================================================================
mount_nfs()
{
    # Make sur the Local Mount Point Exist ---------------------------------------------------------
    if [ ! -d ${LOCAL_MOUNT} ]                                          # Mount Point doesn't exist
        then mkdir ${LOCAL_MOUNT}                                       # Create if not exist
             sadm_writelog "Create local mount point $LOCAL_MOUNT"     # Advise user we create Dir.
             chmod 775 ${LOCAL_MOUNT}                                   # Change Protection
    fi
    
    # Mount the NFS Drive - Where the TGZ File will reside -----------------------------------------
    sadm_writelog "Mounting NFS Drive on $SADM_BACKUP_NFS_SERVER"       # Show NFS Server Name
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted
    sadm_writelog "mount ${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT} ${LOCAL_MOUNT}" 
    mount ${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "[ERROR] Mount NFS Failed - Proces Aborted"  # Error - Advise User
             return 1                                                   # End Function with error
    fi
    
    # Make sure the Server Backup Directory exist on NFS Drive -------------------------------------
    if [ ! -d ${OUTPUT_DIR} ]                                           # Check if mksysb Dir Exist
        then mkdir ${OUTPUT_DIR}                                        # If Not Create it
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_writelog "[ERROR] Creating Directory $OUTPUT_DIR"
                     sadm_writelog "        On the NFS Server ${SADM_BACKUP_NFS_SERVER}"
                     return 1                                           # End Function with error
             fi
             chmod 775 $OUTPUT_DIR                                      # Assign Protection
    fi
    return 0 
}


# ==================================================================================================
#                                Unmount NFS Backup Directory
# ==================================================================================================
umount_nfs()
{
    sadm_writelog "Unmounting NFS mount directory $LOCAL_MOUNT"         # Advise user we umount
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "[ERROR] Umounting NFS Dir. $LOCAL_MOUNT"    # Error - Advise User
             return 1                                                   # End Function with error
    fi
    return 0
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    mount_nfs                                                           # Mount NFS Dir.
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    sadm_writelog "Starting Mksysb ..."                                 # Advise USer 
    sadm_writelog "mksysb -i -e -X ${OUTPUT_DIR}/${SADM_HOSTNAME}.mksysb"
    mksysb -i -e -X ${OUTPUT_DIR}/${SADM_HOSTNAME}.mksysb  >> $SADM_LOG 2>&1
    SADM_EXIT_CODE=$?
    umount_nfs                                                          # Umounting NFS Drive
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
