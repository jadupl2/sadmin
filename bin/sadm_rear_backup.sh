#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rear_backup.sh
#   Synopsis :  This script produce an bootable iso and a backup restorable after booting from iso.
#   Version  :  1.6
#   Date     :  14 December 2016
#   Requires :  sh
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
#
#  History
#  1.7  Dec 2016    Add Check to see if Rear Configuration file isnt't present, abort Job (Exit 1)
#  1.8  Mar 2017    Move test if rear is installed first, if not abort process up front.
#                   Error Message more verbose and More Customization
#  2.0  Apr 2017    Return Code returned by Rear handle correctly
#                   Script Messages more informative
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
SADM_VER='2.0'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadmlib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadmlib_server.sh  

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
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
NFS_SERVER="batnas.maison.ca"               ; export NFS_SERVER         # Remote Backup Name
NFS_DIR="/volume1/Linux_DR"                 ; export NFS_DIR            # Dir where Backup Go
NFS_MOUNT="/mnt/nfs1"                       ; export NFS_MOUNT          # Local NFS Mount Point 
REAR_COPY=2                                 ; export REAR_COPY          # Nb. of images to keep
REAR_CFGFILE="/etc/rear/site.conf"          ; export REAR_CFGFILE       # Read Configuration file


# --------------------------------------------------------------------------------------------------
#                     Create the Rescue ISO and a tar file of the server
# --------------------------------------------------------------------------------------------------
create_backup()
{
    # Create the bootable ISO on the NFS Server
    sadm_writelog " "
    sadm_writelog "$SADM_TEN_DASH"; 
    sadm_writelog "***** CREATING THE 'ReaR' BOOTABLE ISO *****"
    sadm_writelog " "
    sadm_writelog "$REAR mkrescue -v "       
    $REAR mkrescue -v | tee -a $SADM_LOG                                 # Produce Bootable ISO
    if [ $? -ne 0 ]
        then sadm_writelog "***** ISO creation completed with error - Aborting Script *****"
             return 1 
        else sadm_writelog "***** ISO created with Success *****"
    fi
    
    # Create the Backup TGZ file on the NFS Server
    sadm_writelog "" 
    sadm_writelog "$SADM_TEN_DASH"; 
    sadm_writelog "***** CREATING THE 'ReaR' BACKUP *****"
    sadm_writelog " "
    sadm_writelog "$REAR mkbackup -v "       
    $REAR mkbackup -v | tee -a $SADM_LOG                                  # Produce Backup for DR
    if [ $? -ne 0 ]
        then sadm_writelog "***** Rear Backup completed with Error - Aborting Script *****"
             return 1 
        else sadm_writelog "***** Rear Backup completed with Success *****"
    fi
    
    return 0                                                            # Return Default return code
}



# --------------------------------------------------------------------------------------------------
# Mount the NFS Drive, check (change)) permission and make sure we have the correct number of copies
# --------------------------------------------------------------------------------------------------
rear_housekeeping()
{
    FNC_ERROR=0                                                       # Cleanup Error Default 0
    sadm_writelog "***** Perform ReaR Housekeeping *****"
    
    # Make sure Local mount point exist
    if [ ! -d ${NFS_MOUNT} ] ; then mkdir ${NFS_MOUNT} ; chmod 775 ${NFS_MOUNT} ; fi

    # Mount the NFS Mount point 
    sadm_writelog "Mounting the NFS Drive on $NFS_SERVER"
    umount ${NFS_MOUNT} > /dev/null 2>&1
    sadm_writelog "mount ${NFS_SERVER}:${NFS_DIR} ${NFS_MOUNT}"
    mount ${NFS_SERVER}:${NFS_DIR} ${NFS_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]
        then RC=1
             sadm_writelog "Mount of $NFS_DIR on NFS server $NFS_SERVER Failed"
             sadm_writelog "Proces Aborted"
             umount ${NFS_MOUNT} > /dev/null 2>&1
             return 1
    fi
    sadm_writelog "NFS mount succeeded ..."
    df -h | grep ${NFS_MOUNT} | tee -a $SADM_LOG 2>&1

    
    # Make sure the Directory of the host exist on NFS Server and have proper permission
    if [ ! -d  "${NFS_MOUNT}/${SADM_HOSTNAME}" ]
        then mkdir ${NFS_MOUNT}/${SADM_HOSTNAME}
             if [ $? -ne 0 ] 
                then sadm_writelog "Error can't create directory ${NFS_MOUNT}/${SADM_HOSTNAME}" 
                     return 1 
             fi
    fi
    sadm_writelog "chmod 775 ${NFS_MOUNT}/${SADM_HOSTNAME}"
    chmod 775 ${NFS_MOUNT}/${SADM_HOSTNAME} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] 
       then sadm_writelog "Error can't chmod directory ${NFS_MOUNT}/${SADM_HOSTNAME}" 
            return 1 
    fi
    
    # Create Environnement Variable of all files we are about to deal with below
    REAR_DIR="${NFS_MOUNT}/${SADM_HOSTNAME}"                            # Rear Host Backup Dir.
    REAR_NAME="${REAR_DIR}/rear_${SADM_HOSTNAME}"                       # ISO & Backup Prefix Name
    REAR_ISO="${REAR_NAME}.iso"                                         # Rear Host ISO File Name
    PREV_ISO="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").iso"          # Rear Backup ISO 
    REAR_BAC="${REAR_NAME}.tar.gz"                                      # Rear Host Backup File Name
    PREV_BAC="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").tar.gz"       # Rear Previous Backup File  

    # Make a copy of actual ISO before creating a new one   
    if [ -r "$REAR_ISO" ]
        then sadm_writelog " "
             sadm_writelog "Rename actual ISO before creating a new one"
             sadm_writelog "mv $REAR_ISO $PREV_ISO"
             mv $REAR_ISO $PREV_ISO >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error trying to move $REAR_ISO to $PREV_ISO"
                 else sadm_writelog "The ISO rename was done successfully"
             fi
    fi
    
    # Make a copy of actual Backup file before creating a new one   
    if [ -r "$REAR_BAC" ]
        then sadm_writelog "Rename actual Backup file before creating a new one"
             sadm_writelog "mv $REAR_BAC $PREV_BAC"
             mv $REAR_BAC $PREV_BAC >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error trying to move $REAR_BAC to $PREV_BAC"
                 else sadm_writelog "The rename of the backup file was done successfully"
             fi
    fi
                    
    sadm_writelog " "
    sadm_writelog "You choose to keep $REAR_COPY backup files on the NFS server"
    sadm_writelog "Here is a list of ReaR backup and ISO on NFS Server for ${SADM_HOSTNAME}"
    #sadm_writelog "ls -1t ${REAR_NAME}*.iso | sort -r"
    ls -1t ${REAR_NAME}*.iso | sort -r | tee -a $SADM_LOG
    ls -1t ${REAR_NAME}*.gz  | sort -r | tee -a $SADM_LOG

    COUNT_GZ=` ls -1t  ${REAR_NAME}*.gz  |sort -r |sed 1,${REAR_COPY}d | wc -l`  # Nb of GZ  to Del.
    if [ "$COUNT_GZ" -ne 0 ]
        then sadm_writelog " "
             sadm_writelog "Number of backup file(s) to delete is $COUNT_GZ"
             sadm_writelog "List of backup file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${REAR_COPY}d | tee -a $SADM_LOG
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${REAR_COPY}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] ;then sadm_writelog "Problem deleting backup file(s)" ;FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ;then sadm_writelog "Backup was deleted with success" ;fi
        else RC=0
             sadm_writelog " "
             sadm_writelog "We don't need to delete any backup file"
    fi
        
    COUNT_ISO=`ls -1t  ${REAR_NAME}*.iso |sort -r |sed 1,${REAR_COPY}d | wc -l`  # Nb of ISO  to Del.
    if [ "$COUNT_ISO" -ne 0 ]
        then sadm_writelog " "
             sadm_writelog "Number of ISO file(s) to delete is $COUNT_ISO"
             sadm_writelog "List of ISO file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${REAR_COPY}d | tee -a $SADM_LOG
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${REAR_COPY}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] ; then sadm_writelog "Problem deleting ISO file(s)"; FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ; then sadm_writelog "ISO file(s) deleted with success" ; fi
        else RC=0
             sadm_writelog " "
             sadm_writelog "We don't need to delete any ISO file"
    fi
        
    # Make sure Host Directory permission and files below are ok
    sadm_writelog " "
    sadm_writelog "Make sure backup are readable."
    sadm_writelog "chmod 664 ${REAR_NAME}*"
    chmod 664 ${REAR_NAME}* >> /dev/null 2>&1
        
    # Ok Cleanup up is finish - Unmount the NFS
    sadm_writelog "Unmounting NFS mount directories"
    sadm_writelog "umount ${NFS_MOUNT}"
    umount ${NFS_MOUNT} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_writelog "Error returned on previous command" ; FNC_ERROR=1; fi

    sadm_writelog " "
    sadm_writelog "***** ReaR Backup Housekeeping is terminated *****"
    sadm_writelog " "
    return $FNC_ERROR
}




# --------------------------------------------------------------------------------------------------
#                                    Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Check if REAR is not installed - Abort Process 
    REAR=`${SADM_WHICH} rear`
    if ${SADM_WHICH} rear >/dev/null 2>&1                               # command is found ?
        then REAR=`${SADM_WHICH} rear`                                  # Store Path of command
        else sadm_writelog "COMMAND 'rear' ISN'T FOUND - JOB ABORTED"   # Advise User Aborting
             sadm_stop 1                                                # Upd. RCH File & Trim Log 
             exit 1                                                     # Exit With Global Err (0/1)
    fi

    # If Rear configuration is not there - Abort Process
    if [ ! -r "$REAR_CFGFILE" ]                                         # ReaR Site config exist?
        then sadm_writelog "The $REAR_CFGFILE isn't present"            # Warn User - Missing file
             sadm_writelog "The backup will not run - Job Aborted"      # Warn User - No Backup
             sadm_stop 1                                                # Upd. RCH File & Trim Log 
             exit 1                                                     # Exit With Global Err (0/1)
    fi
    
    # Remove default crontab job - So we can decide otherwise when we run rear from this script
    if [ -r /etc/cron.d/rear ] ; then rm -f /etc/cron.d/rear >/dev/null 2>&1; fi
    
    rear_housekeeping                                                   # Set Perm. & rm old version
    if [ $? -eq 0 ]                                                     # If went OK do Clean up
        then create_backup                                              # Set Perm. & rm old version
             if [ $? -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi               # Error encounter exitcode=1
        else SADM_EXIT_CODE=1                                           # Error encounter exitcode=1
    fi
 
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
