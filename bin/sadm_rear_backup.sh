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

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x

#
#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
#===================================================================================================

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  


#
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
#SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
#SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=60                        ; export SADM_SAR_KEEPDAYS  # Days to keep old *.sar
#SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
#SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log
#SADM_PGUSER="postgres"                      ; export SADM_PGUSER        # PostGres User Name
#SADM_PGGROUP="postgres"                     ; export SADM_PGGROUP       # PostGres Group Name
#SADM_PGDB=""                                ; export SADM_PGDB          # PostGres DataBase Name
#SADM_PGSCHEMA=""                            ; export SADM_PGSCHEMA      # PostGres DataBase Schema
#SADM_PGHOST=""                              ; export SADM_PGHOST        # PostGres DataBase Host
#SADM_PGPORT=5432                            ; export SADM_PGPORT        # PostGres Listening Port
#SADM_RW_PGUSER=""                           ; export SADM_RW_PGUSER     # Postgres Read/Write User 
#SADM_RW_PGPWD=""                            ; export SADM_RW_PGPWD      # PostGres Read/Write Passwd
#SADM_RO_PGUSER=""                           ; export SADM_RO_PGUSER     # Postgres Read Only User 
#SADM_RO_PGPWD=""                            ; export SADM_RO_PGPWD      # PostGres Read Only Passwd
#SADM_SERVER=""                              ; export SADM_SERVER        # Server FQN Name
#SADM_DOMAIN=""                              ; export SADM_DOMAIN        # Default Domain Name

#===================================================================================================
#






# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
NFS_IP="192.168.1.47"                               ; export NFS_IP         # NFS Server IP
NFS_DIR="/volume1/Linux_DR"                         ; export NFS_DIR        # Dir where Backup Go
NFS_MOUNT="/mnt/nfs1"                               ; export NFS_MOUNT      # Local NFS Mount Point 
REAR_COPY=2                                         ; export REAR_COPY      # Nb. of images to keep


# --------------------------------------------------------------------------------------------------
#                     Create the Rescue ISO and a tar file of the server
# --------------------------------------------------------------------------------------------------
create_backup()
{
    REAR=`which rear`
    if ${SADM_WHICH} rear >/dev/null 2>&1                               # command is found ?
        then REAR=`${SADM_WHICH} rear`                                  # Store Path of command
        else sadm_writelog "Command rear is not found - Job Aborted"    # Advise User Aborting
             return 1
    fi
    
    # Remove default crontab job - So we can decide otherwise when we run rear from this script
    if [ -r /etc/cron.d/rear ] ; then rm -f /etc/cron.d/rear >/dev/null 2>&1; fi
    
    # Create the bootable ISO on the NFS Server
    sadm_writelog " "
    sadm_writelog "$SADM_TEN_DASH"; sadm_writelog "$REAR mkrescue -v "       
    $REAR mkrescue -v | tee -a $SADM_LOG                                 # Produce Bootable ISO
    if [ $? -ne 0 ]
        then sadm_writelog "Creation of Rescue ISO completed with Error - Aborting Script"
             return 1 
        else sadm_writelog "Creation of Rescue ISO completed with Success"
    fi
    
    # Create the Backup TGZ file on the NFS Server
    sadm_writelog "" 
    sadm_writelog "$SADM_TEN_DASH"; sadm_writelog "$REAR mkbackup -v "       
    $REAR mkbackup -v | tee -a $SADM_LOG                                  # Produce Backup for DR
    if [ $? -ne 0 ]
        then sadm_writelog "Creation of Rear Backup completed with Error - Aborting Script"
             return 1 
        else sadm_writelog "Creation of Rear Backup completed with Success"
    fi
    
    return 0                                                            # Return Default return code
}



# --------------------------------------------------------------------------------------------------
# Mount the NFS Drive, check (change)) permission and make sure we have the correct number of copies
# --------------------------------------------------------------------------------------------------
rear_housekeeping()
{
    FNC_ERROR=0                                                       # Cleanup Error Default 0
    sadm_writelog "Beginning ReaR Housekeeping ... "
    sadm_writelog " "
 
    # Make sure Local mount point exist
    if [ ! -d ${NFS_MOUNT} ] ; then mkdir ${NFS_MOUNT} ; chmod 775 ${NFS_MOUNT} ; fi

    # Mount the NFS Mount point 
    sadm_writelog "Mounting the NFS Drive on $NFS_IP"
    umount ${NFS_MOUNT} > /dev/null 2>&1
    sadm_writelog "mount ${NFS_IP}:${NFS_DIR} ${NFS_MOUNT}"
    mount ${NFS_IP}:${NFS_DIR} ${NFS_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]
        then RC=1
             sadm_writelog "Mount of $NFS_DIR on NFS server $NFS_IP Failed Proces Aborted"
             umount ${NFS_MOUNT} > /dev/null 2>&1
             return 1
    fi
    sadm_writelog "NFS mount succeeded ..."
    df -h | grep nfs | tee -a $SADM_LOG 2>&1

    
    # Make sure the Directory of the host exist on NFS Server and have proper permission
    if [ ! -d  "${NFS_MOUNT}/$(sadm_get_hostname)" ]
        then mkdir ${NFS_MOUNT}/$(sadm_get_hostname)
        if [ $? -ne 0 ] ; then sadm_writelog "Error returned on previous command" ;FNC_ERROR=1; fi
    fi
    sadm_writelog "chmod 775 ${NFS_MOUNT}/$(sadm_get_hostname)"
    chmod 775 ${NFS_MOUNT}/$(sadm_get_hostname) >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_writelog "Error returned on previous command" ; FNC_ERROR=1; fi
    

    # Create Environnement Variable of all files about to deal with below
    REAR_DIR="${NFS_MOUNT}/$(sadm_get_hostname)"                        # Rear Host Backup Directory
    REAR_NAME="${REAR_DIR}/rear_$(sadm_get_hostname)"                   # ISO & Backup Prefix Name
    REAR_ISO="${REAR_NAME}.iso"                                         # Rear Host ISO File Name
    PREV_ISO="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").iso"          # Rear Backup ISO 
    REAR_BAC="${REAR_NAME}.tar.gz"                                      # Rear Host Backup File Name
    PREV_BAC="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").tar.gz"       # Rear Previous Backup File  

    # Make a copy of actual ISO before creating a new one   
    sadm_writelog " "
    if [ -r "$REAR_ISO" ]
        then sadm_writelog "Rename actual ISO before creating a new one"
             sadm_writelog "mv $REAR_ISO $PREV_ISO"
             mv $REAR_ISO $PREV_ISO >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error trying to move $REAR_ISO to $PREV_ISO"
                 else sadm_writelog "The ISO rename was done successfully"
             fi
    fi
    
    # Make a copy of actual Backup file before creating a new one   
    sadm_writelog " "
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
    sadm_writelog "Here is a list of ReaR backup and ISO on NFS Server for $(sadm_get_hostname)"
    #sadm_writelog "ls -1t ${REAR_NAME}*.iso | sort -r"
    ls -1t ${REAR_NAME}*.iso | sort -r | tee -a $SADM_LOG
    #sadm_writelog "ls -1t ${REAR_NAME}*.gz  | sort -r"
    ls -1t ${REAR_NAME}*.gz  | sort -r | tee -a $SADM_LOG

    COUNT_GZ=` ls -1t  ${REAR_NAME}*.gz  |sort -r |sed 1,${REAR_COPY}d | wc -l`  # Nb of GZ  to Del.
    if [ "$COUNT_GZ" -ne 0 ]
        then sadm_writelog "Number of backup file(s) to delete is $COUNT_GZ"
             sadm_writelog " "
             sadm_writelog "List of backup file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${REAR_COPY}d | tee -a $SADM_LOG
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${REAR_COPY}d | xargs rm -f >> $SADM_LOG 2>&1
             if [ $RC -ne 0 ] ; then sadm_writelog "Problem deleting backup file(s)" ;FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ; then sadm_writelog "Backup was deleted with success" ; fi
        else RC=0
             sadm_writelog " "
             sadm_writelog "We don't need to delete any backup file"
    fi
        
    COUNT_ISO=`ls -1t  ${REAR_NAME}*.iso |sort -r |sed 1,${REAR_COPY}d | wc -l`  # Nb of ISO  to Del.
    if [ "$COUNT_ISO" -ne 0 ]
        then sadm_writelog "Number of backup file(s) to delete is $COUNT_ISO"
             sadm_writelog " "
             sadm_writelog "List of ISO file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${REAR_COPY}d | tee -a $SADM_LOG
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${REAR_COPY}d | xargs rm -f >> $SADM_LOG 2>&1
             if [ $RC -ne 0 ] ; then sadm_writelog "Problem deleting ISO file(s)"; FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ; then sadm_writelog "ISO file(s) deleted with success" ; fi
        else RC=0
             sadm_writelog " "
             sadm_writelog "We don't need to delete any ISO file"
    fi
        

    # Make sure Host Directory permission and files below are ok
    sadm_writelog " "
    sadm_writelog "chmod 664 ${REAR_NAME}*"
    chmod 664 ${REAR_NAME}* >> /dev/null 2>&1
        
    # Ok Cleanup up is finish - Unmount the NFS
    sadm_writelog " "
    sadm_writelog "Unmounting NFS mount directories"
    sadm_writelog "umount ${NFS_MOUNT}"
    umount ${NFS_MOUNT} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_writelog "Error returned on previous command" ; FNC_ERROR=1; fi

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

    rear_housekeeping                                                   # Set Perm. & rm old version
    if [ $? -eq 0 ]                                                     # If went OK do Clean up
        then create_backup                                              # Set Perm. & rm old version
             if [ $? -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi               # Error encounter exitcode=1
        else SADM_EXIT_CODE=1                                           # Error encounter exitcode=1
    fi
 
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
