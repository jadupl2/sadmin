#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Backup and Compress directories choosen in $BACKUP_DIR as tar files (tgz)
#   Date:       28 August 2015
#   Synopsis:   This script is used to create a tgz file of all directories speciied in the 
#               variable $BACKUP_DIR to NFS $ARCHIVE_DIR .
#               Only the specified ($SADM_BACKUP_NFS_TO_KEEP) copies of each tgz files will be kept
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
#   2017_10_02  JDuplessis
#       V2.1 Added /wsadmin in the backup
#   2017_12_27  JDuplessis
#       V2.2 Adapt to new Library and Take NFS Server From SADMIN Config file Now
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $sadmin/lib/sadmlib_test.sh for viewing functions and informations avail. to you .
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to SADMIN directory" ;exit 1 ;fi
wlib="${SADMIN}/lib/sadmlib_std.sh"                                     # SADMIN Library Location
if [ ! -f $wlib ] ;then echo "SADMIN Library ($wlib) Not Found" ;exit 1 ;fi
#
# These are Global variables used by SADMIN Libraries - Some influence the behavior of some function
# These variables need to be defined prior to loading the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='2.2'                             ; export SADM_VER            # Your Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# Load SADMIN Libraries
[ -f ${SADMIN}/lib/sadmlib_std.sh ]    && . ${SADMIN}/lib/sadmlib_std.sh
[ -f ${SADMIN}/lib/sadmlib_server.sh ] && . ${SADMIN}/lib/sadmlib_server.sh
#
# These variables are defined in sadmin.cfg file - You can override them here on a per script basis
# --------------------------------------------------------------------------------------------------
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE  # Max Nb. Lines in LOG file
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE   # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR    # Email Address to send status
#
# An email can be sent at the end of the script depending on the ending status
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE    # 0=No 1=OnErr 2=Success 3=All
#
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#                               Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose

# Value are now taken from sadmin.cfg file
#SADM_BACKUP_NFS_SERVER=""                   ; export SADM_BACKUP_NFS_SERVER
#SADM_BACKUP_NFS_MOUNT_POINT=""              ; export SADM_BACKUP_NFS_MOUNT_POINT
#SADM_BACKUP_NFS_TO_KEEP=3                   ; export SADM_BACKUP_NFS_TO_KEEP

# LIST OF DIRECTORIES THAT WILL BE BACKUP (IF THEY EXIST OF COURSE)
# YOU NEED TO CHANGE THEM TO ADAPT TO YOUR ENVIRONMENT (Each line MUST end with a space)
BACKUP_DIR="/cadmin /sadmin /home /storix /mystuff /sysadmin /sysinfo /aix_data /gitrepos /wiki "
BACKUP_DIR="$BACKUP_DIR /os /www /scom /slam /install /linternux /useradmin /svn /stbackups "
BACKUP_DIR="$BACKUP_DIR /etc /var/adsmlog /var/named /var/www /wsadmin "
BACKUP_DIR="$BACKUP_DIR /var/ftp /var/lib/mysql /var/spool/cron "
export BACKUP_DIR
#
TOTAL_ERROR=0                                       ; export TOTAL_ERROR       # Total Rsync Error
LOCAL_MOUNT="/mnt/backup"                           ; export LOCAL_MOUNT_POINT # Local NFS Mnt Point 
ARCHIVE_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}"       ; export ARCHIVE_DIR       # Where Backup Stored


# --------------------------------------------------------------------------------------------------
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
    echo " "
}



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
                    then MESS="[ERROR] ${RC} while creating $TGZ_FILE"  # Advise Backup Error
                         sadm_writelog "$MESS"                          # Advise User - Log Info
                         RC=1                                           # Make Sure Return Code is 0
                    else MESS="[OK] Creating Backup file $TGZ_FILE"     # Advise Backup Success
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
#               Keep only the number of backup copies specied in $SADM_BACKUP_NFS_TO_KEEP
# --------------------------------------------------------------------------------------------------
clean_backup_dir()
{
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    sadm_writelog "Keep only last $SADM_BACKUP_NFS_TO_KEEP copies of each backup in ${ARCHIVE_DIR}"
    sadm_writelog "${SADM_DASH}"                                        # Line of 80 Equal Char.
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.
    TOTAL_ERROR=0                                                       # Make Sure Variable is at 0

    # Enter Server Backup Directory
    # May need to delete some backup if more than $SADM_BACKUP_NFS_TO_KEEP copies
    cd ${ARCHIVE_DIR}                                                   # Change Dir. To Backup Dir.
    sadm_writelog "Current directory is `pwd`"                          # Print Current Dir.
    sadm_writelog " "                                                   # Blank Line in Log
    
    # Verify how many backup exist for each directory Selected  - Defined in BACKUP_DIR Variables
    for WDIR in $BACKUP_DIR
        do
        if [ -d ${WDIR} ]                                               # if Dir exist on Localhost
           then BASE_NAME=`echo "$WDIR" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' `
                FILE_COUNT=`ls -t1 ${BASE_NAME}*.tgz |sort -r |sed "1,${SADM_BACKUP_NFS_TO_KEEP}d"|wc -l`
                sadm_writelog "${SADM_TEN_DASH}"                        # Line of 10 Dash in Log

                if [ "$FILE_COUNT" -ne 0 ]
                   then sadm_writelog "Will delete $FILE_COUNT file(s) in ${WDIR} is"
                        sadm_writelog "Here is a list of $BASE_NAME before the cleanup ..."
                        ls -t1 ${BASE_NAME}*.tgz | sort -r | nl | tee -a $SADM_LOG
                        sadm_writelog "File(s) Deleted are :"
                        ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${SADM_BACKUP_NFS_TO_KEEP}d" | tee -a $SADM_LOG
                        ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${SADM_BACKUP_NFS_TO_KEEP}d" | xargs rm -f >> $SADM_LOG 2>&1
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
    if [ ! -d ${LOCAL_MOUNT} ]                                          # Mount Point doesn't exist
        then mkdir ${LOCAL_MOUNT}                                       # Create if not exist
             sadm_write_log "Create local mount point $LOCAL_MOUNT"     # Advise user we create Dir.
             chmod 775 ${LOCAL_MOUNT}                                   # Change Protection
    fi
    
    # Mount the NFS Drive - Where the TGZ File will reside
    sadm_writelog "Mounting NFS Drive on $SADM_BACKUP_NFS_SERVER"       # Show NFS Server Name
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted
    sadm_writelog "mount ${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT} ${LOCAL_MOUNT}" 
    mount ${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "[ERROR] Mount NFS Failed - Proces Aborted"  # Error - Advise User
             return 1                                                   # End Function with error
    fi
    
    # Make sure the Current Server Backup Directory exist on NFS Drive
    if [ ! -d ${ARCHIVE_DIR} ]                                          # Check if Server Dir Exist
        then mkdir ${ARCHIVE_DIR}                                       # If NOt Creare it
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_writelog "[ERROR] Creating Directory $ARCHIVE_DIR"
                     sadm_writelog "        On the NFS Server ${SADM_BACKUP_NFS_SERVER}"
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
    sadm_writelog "Unmounting NFS mount directory $LOCAL_MOUNT"         # Advise user we umount
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "[ERROR] Umounting NFS Dir. $LOCAL_MOUNT"    # Error - Advise User
             return 1                                                   # End Function with error
    fi
    return 0
}

# --------------------------------------------------------------------------------------------------
#                              S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Init Env. Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9])
    while getopts "hd:" opt ; do                                        # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) help_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell
               ;;
           \?) sadm_writelog "Invalid option: -$OPTARG"                 # Invalid Option Message
               help_usage                                               # Display Help Usage
               sadm_stop 1                                              # Close the shop
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ]                                           # If Debug is Activated
        then sadm_writelog "Debug activated, Level ${DEBUG_LEVEL}"      # Display Debug Level
    fi

    mount_nfs                                                           # Mount NFS Archive Dir.
    if [ $? -ne 0 ]                                                     # If Error While MOunt NFS
        then umount_nfs                                                 # Try to umount it Make Sure
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
