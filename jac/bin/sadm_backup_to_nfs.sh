#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Backup and Compress directories choosen in $BACKUP_DIR as tar files (tgz)
#   Date:       28 August 2015
#   Synopsis:   This script is used to create a tgz file of all directories speciied in the 
#               variable $BACKUP_DIR to NFS $ARCHIVE_DIR .
#               Only the specified ($NB_VER) copies of each tgz files will be kept
#               Can be Run Once a week or Once every couple of Day (As you choose)
# --------------------------------------------------------------------------------------------------
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
#   1.6 - Jan 2-17 - Exclude *.iso added to tar command
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
SADM_VER='1.6'                             ; export SADM_VER            # This Script Version
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
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  

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

TOTAL_ERROR=0                           ; export TOTAL_ERROR            # Total Rsync Error
NB_VER=4                                ; export NB_VER                 # Nb Version to keep
#
NFS_SERVER="ds410.maison.ca"            ; export NFS_SERVER             # Remoote Backup Name
REM_BASE_DIR="/volume1/linux"           ; export REM_BASE_DIR           # Remote Base Dir.
#
LOCAL_MOUNT_DIR="/linux"                ; export LOCAL_MOUNT_POINT      # Local NFS MOunt Point 
ARCHIVE_DIR="${LOCAL_MOUNT_DIR}/$(sadm_get_hostname)" ; export ARCHIVE_DIR  # NFS Backup Dir.

# List of Directories to Backup
BACKUP_DIR="/cadmin /sadmin /home /storix /sysadmin /sysinfo /aix_data /gitrepos /wiki "
BACKUP_DIR="$BACKUP_DIR /os /www /scom /slam /install /linternux /useradmin /svn /stbackups "
BACKUP_DIR="$BACKUP_DIR /etc /var/adsmlog /var/named /var/www /var/ftp /var/lib/mysql /var/spool/cron "
export BACKUP_DIR




# --------------------------------------------------------------------------------------------------
#        Create Backup Files Main Function - Loop for each file specified in $BACKUP_DIR
# --------------------------------------------------------------------------------------------------
create_backup()
{
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    sadm_writelog "Starting the Backup Process"                         # Advise Backup Process Begin
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.
    TOTAL_ERROR=0                                                       # Make Sure Variable is at 0

    # Do a Backup Of All Selected Directories - Defined in BACKUP_DIR Variables
    for WDIR in $BACKUP_DIR                                             # Loop Dir. To Backup
        do
        if [ -d ${WDIR} ]                                               # Dir to Backup Exist ?
           then cd $WDIR                                                # Ok then CD into it
            
                # Construct Backup File Name (Dir+Date_Time_tgz)
                BASE_NAME=`echo "$WDIR" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' `
                TIME_STAMP=`date "+%C%y_%m_%d_%H_%M_%S"`                # Date & Time
                TGZ_FILE="${BASE_NAME}_${TIME_STAMP}.tgz"               # Final TGZ Name
                
                sadm_writelog "${SADM_TEN_DASH}"                        # Line of 10 Dash in Log
                sadm_writelog "Current directory is `pwd`"              # Print Current Dir.
                sadm_writelog "tar -cvzf  ${ARCHIVE_DIR}/${TGZ_FILE} --exclude '*.iso' ." 
                tar -cvzf ${ARCHIVE_DIR}/${TGZ_FILE} --exclude '*.iso' . >/dev/null 2>&1 
                RC=$?                                                   # Save Return Code
                if [ $? -ne 0 ]                                         # If Error while Backup
                    then MESS="ERROR No.${RC} while creating $TGZ_FILE" # Advise Backup Error
                         sadm_writelog "$MESS"                          # Advise User - Log Info
                         RC=1                                           # Make Sure Return Code is 0
                    else MESS="SUCCESS Creating Backup file $TGZ_FILE"  # Advise Backup Success
                         sadm_writelog "$MESS"                          # Advise User - Log Info
                         RC=0                                           # Make Sure Return Code is 0
                fi
                TOTAL_ERROR=$(($TOTAL_ERROR+$RC))                       # Total = Cumulate RC Value
                sadm_writelog "Total of Error is $TOTAL_ERROR"          # Print Current Total Error
           else MESS="Skip $WDIR doesn't exist on $(sadm_get_hostname)" # Sel. Backup Dir not present
                sadm_writelog "${SADM_TEN_DASH}"                        # Line of 10 Dash in Log
                sadm_writelog "$MESS"                                   # Advise User - Log Info
        fi
        done
    
    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    sadm_writelog "Total error(s) while creating backup is $TOTAL_ERROR"
    return $TOTAL_ERROR                                                 # Return Total of Error 
}


# --------------------------------------------------------------------------------------------------
#                       Keep only the number of backup copies specied in $NB_VER
# --------------------------------------------------------------------------------------------------
clean_backup_dir()
{
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    sadm_writelog "Keep only last $NB_VER copies of each backup in ${ARCHIVE_DIR}"
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.
    TOTAL_ERROR=0                                                       # Make Sure Variable is at 0

    # Enter Server Backup Directory - May need to delete some backup if more than $NB_VER copies
    cd ${ARCHIVE_DIR}                                                   # Change Dir. To Backup Dir.
    sadm_writelog "Current directory is `pwd`"                          # Print Current Dir.
    sadm_writelog " "                                                   # Blank Line in Log
    
    # Verify how many backup exist for each directory Selected  - Defined in BACKUP_DIR Variables
    for WDIR in $BACKUP_DIR
        do
        if [ -d ${WDIR} ]                                               # if Dir exist on Localhost
           then BASE_NAME=`echo "$WDIR" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' `
                FILE_COUNT=`ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${NB_VER}d" | wc -l`
                sadm_writelog "${SADM_TEN_DASH}"                        # Line of 10 Dash in Log

                if [ "$FILE_COUNT" -ne 0 ]
                   then sadm_writelog "Will delete $FILE_COUNT file(s) in ${WDIR} is"
                        sadm_writelog "Here is a list of $BASE_NAME before the cleanup ..."
                        ls -t1 ${BASE_NAME}*.tgz | sort -r | nl | tee -a $SADM_LOG
                        sadm_writelog "File(s) Deleted are :"
                        ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${NB_VER}d" | tee -a $SADM_LOG
                        ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${NB_VER}d" | xargs rm -f >> $SADM_LOG 2>&1
                        RC=$?
                        if [ $RC -ne 0 ]
                            then sadm_writelog "ERROR $RC while cleaning up ${BASE_NAME} files"
                                 RC=1
                            else sadm_writelog "SUCCESS Deleting ${BASE_NAME} file(s)"
                                 RC=0
                        fi
                        sadm_writelog "Here is a list of $BASE_NAME after the cleanup ..."
                        ls -t1 ${BASE_NAME}*.tgz | sort -r | nl | tee -a $SADM_LOG
                   else RC=0
                        sadm_writelog "No file(s) to delete ($BASE_NAME) - OK"
                fi 
                TOTAL_ERROR=`echo $TOTAL_ERROR + $RC | bc `
                sadm_writelog "Total of Error is $TOTAL_ERROR"
        fi
        done
    
    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    sadm_writelog "Total error(s) while cleaning backup file(s) is $TOTAL_ERROR"
    return $TOTAL_ERROR                                                 # Return Total of Error 
}


# --------------------------------------------------------------------------------------------------
#                Mount the NFS Directory where all the backup files will be stored
# --------------------------------------------------------------------------------------------------
mount_nfs()
{
    # Local Mount Point Verification
    if [ ! -d ${LOCAL_MOUNT_DIR} ]                                      # Check mount point exist
        then mkdir ${LOCAL_MOUNT_DIR}                                   # Create if not exist
             write_log "Creating local mount point $LOCAL_MOUNT_DIR"    # Advise user we create Dir.
             chmod 775 ${LOCAL_MOUNT_DIR}                               # Change Protection
    fi
    
    # Mount the NFS Drive - Where the TGZ File will reside
    sadm_writelog "Mounting NFS Drive on $NFS_SERVER"                   # Display NFS Server Name
    sadm_writelog "mount ${NFS_SERVER}:${REM_BASE_DIR} ${LOCAL_MOUNT_DIR}" # Display Mount Command
    umount ${LOCAL_MOUNT_DIR} > /dev/null 2>&1                          # Make sure not mounted
    mount ${NFS_SERVER}:${REM_BASE_DIR} ${LOCAL_MOUNT_DIR} >>$SADM_LOG 2>&1 # Mount NFS Mount Point
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "Mount NFS Failed Proces Aborted"            # Error - Advise User
             return 1                                                   # End Function with error
    fi
    
    # Make sure the Current Server Directory exist on NFS Drive
    if [ ! -d ${ARCHIVE_DIR} ]                                          # Check if Server Dir Exist
        then mkdir ${ARCHIVE_DIR}                                       # If NOt Creare it
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_writelog "Error Creating Directory $ARCHIVE_DIR"
                     sadm_writelog "On the NFS Server ${NFS_SERVER}"    # Indicate NFS Server
                     return 1                                           # End Function with error
             fi
             chmod 775 $ARCHIVE_DIR                                     # Assign Protection
    fi
    return 0 
}


# --------------------------------------------------------------------------------------------------
#                                Unmount NFS Backup Directory
# --------------------------------------------------------------------------------------------------
umount_nfs()
{
   sadm_writelog "Unmounting NFS mount directory $LOCAL_MOUNT_DIR"      # Advise user we umount
   umount $LOCAL_MOUNT_DIR >> $SADM_LOG 2>&1                            # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "NFS Error umounting Dir. $LOCAL_MOUNT_DIR"  # Error - Advise User
             return 1                                                   # End Function with error
    fi
   return 0
}

# --------------------------------------------------------------------------------------------------
#                       S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Init Env. Dir & RC/Log File

    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    mount_nfs                                                           # Mount NFS Archive Dir.
    if [ $? -ne 0 ]                                                     # If Error While MOunt NFS
        then umount_nfs                                                 # Try to umount it Make Sure
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    create_backup                                                       # Create TGZ of Seleted Dir.
    BACKUP_ERROR=$?                                                     # Save the Total Error
    clean_backup_dir                                                    # Delete Old Backup
    CLEANING_ERROR=$?                                                   # Save the Total Error
    SADM_EXIT_CODE=$(($BACK_ERROR+$CLEANING_ERROR))                     # Total=Backup+Cleaning Err.
    umount_nfs                                                          # Umounting NFS Drive
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
