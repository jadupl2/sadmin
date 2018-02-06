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
#   2017_01_02  JDuplessis
#       V2.3 Small Corrections and added comments
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
#                               Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose

# NFS Backup Parameters Values are taken from sadmin.cfg file
#SADM_BACKUP_NFS_SERVER=""                   ; export SADM_BACKUP_NFS_SERVER
#SADM_BACKUP_NFS_MOUNT_POINT=""              ; export SADM_BACKUP_NFS_MOUNT_POINT
#SADM_BACKUP_NFS_TO_KEEP=3                   ; export SADM_BACKUP_NFS_TO_KEEP

# LIST OF DIRECTORIES THAT WILL BE BACKUP (IF THEY EXIST OF COURSE)
# YOU NEED TO CHANGE THEM TO ADAPT TO YOUR ENVIRONMENT (Each line MUST end with a space)
BACKUP_DIR="/cadmin /sadmin /home /storix /mystuff /sysadmin /sysinfo /aix_data /gitrepos /wiki "
BACKUP_DIR="$BACKUP_DIR /os /www /scom /slam /install /linternux /useradmin /svn /stbackups "
BACKUP_DIR="$BACKUP_DIR /etc /var/adsmlog /var/named /var/www /wsadmin /psadmin "
BACKUP_DIR="$BACKUP_DIR /var/ftp /var/lib/mysql /var/spool/cron "
export BACKUP_DIR
#
TOTAL_ERROR=0                                       ; export TOTAL_ERROR       # Total Rsync Error
LOCAL_MOUNT="/mnt/backup"                           ; export LOCAL_MOUNT_POINT # Local NFS Mnt Point 
ARCHIVE_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}"       ; export ARCHIVE_DIR       # Where Backup Stored
#
WEEKDAY=("index0" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
MTH_NAME=("index0" "January" "February" "March" "April" "May" "June" "July" "August" "September" 
        "October" "November" "December")

# Backup Directories
DAILY_DIR="${BACKUP_ROOT_DIR}/daily"     ; export DAILY_DIR             # Dir. For Daily Backup                                 
WEEKLY_DIR="${BACKUP_ROOT_DIR}/weekly"   ; export WEEKLY_DIR            # Dir. For Weekly Backup
MONTHLY_DIR="${BACKUP_ROOT_DIR}/monthly" ; export MONTHLY_DIR           # Dir. For Monthly Backup
YEARLY_DIR="${BACKUP_ROOT_DIR}/yearly"   ; export YEARLY_DIR            # Dir. For Yearly Backup
LATEST_DIR="${BACKUP_ROOT_DIR}/latest"   ; export LATEST_DIR            # Latest Backup Directory

# Number of backup to keep per backup type
DAILY_BACKUP_TO_KEEP=14             ; export DAILY_BACKUP_TO_KEEP       # Nb. Daily Backup to keep
WEEKLY_BACKUP_TO_KEEP=5             ; export WEEKLY_BACKUP_TO_KEEP      # Nb. Weekly Backup to keep
MONTHLY_BACKUP_TO_KEEP=14           ; export MONTHLY_BACKUP_TO_KEEP     # Nb. Monthly Backup to keep
YEARLY_BACKUP_TO_KEEP=7             ; export YEARLY_BACKUP_TO_KEEP      # Nb. Yearly Backup to keep

# Trigger per backup type
WEEKLY_BACKUP_DAY=5                 ; export WEEKLY_BACKUP_DAY          # Day Week Backup 1=Mon7=Sun
MONTHLY_BACKUP_DATE=1               ; export MONTHLY_BACKUP_DATE        # Monthly Backup Date (1-28)
YEARLY_BACKUP_MONTH=1               ; export YEARLY_BACKUP_MONTH        # Yearly Backup Month (1-12)
YEARLY_BACKUP_DATE=2                ; export YEARLY_BACKUP_DATE         # Yearly Backup Date (1-28)


# --------------------------------------------------------------------------------------------------
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
    echo "             -c   (Compress Backup)"
    echo " "
}


#===================================================================================================
#                 Make sure we have everything needed to start and succeed the backup
#===================================================================================================
backup_setup()
{
    sadm_writelog "----------"                                          # Insert Sperator Dash Line
    sadm_writelog "Setup Backup Environment ..."                        # Advise User were Starting
    
    which mysqldump >/dev/null 2>&1                                     # See if mysqldump available
    if [ $? -ne 0 ]                                                     # If Can't be found 
        then sadm_writelog "The 'mysqldump' command can't be found"     # Advise User
             sadm_writelog "The Backup cannot be started"               # No Backup can be performed
             return 1                                                   # Return Error to Caller
        else                                                            # If mysqldump was found
            MYSQLDUMP=`which mysqldump`                                 # Save mysqldump Full Path
    fi

    # Main Backup Directory
    if [ ! -d "${BACKUP_ROOT_DIR}" ]                                    # Main Backup Dir. Exist ?
        then mkdir $BACKUP_ROOT_DIR                                     # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $BACKUP_ROOT_DIR          # Assign it SADM USer&Group
             chmod 750 $BACKUP_ROOT_DIR                                 # Read/Write to SADM Usr/Grp
    fi

    # Daily Backup Directory
    if [ ! -d "${DAILY_DIR}" ]                                          # Daily Backup Dir. Exist ?
        then mkdir $DAILY_DIR                                           # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $DAILY_DIR                # Assign it SADM USer&Group
             chmod 750 $DAILY_DIR                                       # Read/Write to SADM Usr/Grp
    fi

    # Weekly Backup Directory
    if [ ! -d "${WEEKLY_DIR}" ]                                         # Daily Backup Dir. Exist ?
        then mkdir $WEEKLY_DIR                                          # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $WEEKLY_DIR               # Assign it SADM USer&Group
             chmod 750 $WEEKLY_DIR                                      # Read/Write to SADM Usr/Grp
    fi

    # Monthly Backup Directory
    if [ ! -d "${MONTHLY_DIR}" ]                                        # Monthly Backup Dir. Exist?
        then mkdir $MONTHLY_DIR                                         # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $MONTHLY_DIR              # Assign it SADM USer&Group
             chmod 750 $MONTHLY_DIR                                     # Read/Write to SADM Usr/Grp
    fi

    # Yearly Backup Directory
    if [ ! -d "${YEARLY_DIR}" ]                                         # Yearly Backup Dir. Exist?
        then mkdir $YEARLY_DIR                                          # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $YEARLY_DIR               # Assign it SADM USer&Group
             chmod 750 $YEARLY_DIR                                      # Read/Write to SADM Usr/Grp
    fi

    # Latest Backup Directory
    if [ ! -d "${LATEST_DIR}" ]                                         # Latest Backup Dir Exist?
        then mkdir $LATEST_DIR                                          # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $LATEST_DIR               # Give it SADM USer&Group
             chmod 750 $LATEST_DIR                                      # R/W to SADM Usr/Grp
    fi

    # Produce a file that contains all databases name, excluding the specified in $DBEXCLUDE
    $SADM_MYSQL $CREDENTIAL --batch --skip-column-names -e "show databases" > $SADM_TMP_FILE1
    grep -vE "$DBEXCLUDE" $SADM_TMP_FILE1 > $SADM_TMP_FILE2             # Excl.chosen DB from Backup

    # If Database Name (-n) was specified, check if exist in Database
    if [ "$BACKUP_NAME" != 'all' ]                                      # If Backup one Database
        then grep -i "$BACKUP_NAME" $SADM_TMP_FILE2 > /dev/null 2>&1    # Grep for DB Name in DBList
             if [ $? -ne 0 ]                                            # If DB wasn't found 
                then sadm_writelog "The Database $BACKUP_NAME doesn't exist in Database" 
                     sadm_writelog "The valid Database name are : "     # SHow user List valid DB
                     while read dbname                                  # Read DB List one by one
                        do
                        sadm_writelog "$dbname"                         # Display DB Name
                        done <$SADM_TMP_FILE2
                     return 1                                           # Return Error to Caller
                else echo "$BACKUP_NAME" > $SADM_TMP_FILE2              # Put Name in List to Backup
             fi
    fi

    sadm_writelog "You have chosen to : "
    if [ "$BACKUP_NAME" = 'all' ] 
        then sadm_writelog " - Backup All Databases"
             sadm_writelog "   - Except these databases ; $DBEXCLUDE" 
        else sadm_writelog " - Backup the Database '$BACKUP_NAME'" 
    fi
    if [ "$COMPRESS_BACKUP" = 'Y' ] 
        then sadm_writelog " - Compress the backup file" 
        else sadm_writelog " - Not compress the backup file"
    fi
    sadm_writelog " - Keep $DAILY_BACKUP_TO_KEEP daily backups"
    sadm_writelog " - Keep $WEEKLY_BACKUP_TO_KEEP weekly backups"
    sadm_writelog " - Keep $MONTHLY_BACKUP_TO_KEEP monthly backups"
    sadm_writelog " - Keep $YEARLY_BACKUP_TO_KEEP yearly backups"
    sadm_writelog " - Do the weekly backup on ${WEEKDAY[$WEEKLY_BACKUP_DAY]}"
    sadm_writelog " - Do the monthy backup on the $MONTHLY_BACKUP_DATE of every month"
    sadm_writelog " - Do the yearly backup on the $YEARLY_BACKUP_DATE of ${MTH_NAME[$YEARLY_BACKUP_MONTH]} every year"
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
                sadm_writelog "${SADM_TEN_DASH}"                        # Line of 10 Dash in Log
                sadm_writelog "Current directory is `pwd`"              # Print Current Dir.
                if [ "$COMPRESS" == "ON" ] 
                    then BACK_FILE="${BASE_NAME}_${TIME_STAMP}.tgz"     # Final tgz Backup file name
                         sadm_writelog "tar -cvzf ${ARCHIVE_DIR}/${BACK_FILE} --exclude '*.iso' ." 
                         tar -cvzf ${ARCHIVE_DIR}/${BACK_FILE} --exclude '*.iso' . >/dev/null 2>&1 
                    else BACK_FILE="${BASE_NAME}_${TIME_STAMP}.tar"     # Final tar Backup file name
                         sadm_writelog "tar -cvf ${ARCHIVE_DIR}/${BACK_FILE} --exclude '*.iso' ." 
                         tar -cvf ${ARCHIVE_DIR}/${BACK_FILE} --exclude '*.iso' . >/dev/null 2>&1 
                fi
                RC=$?                                                   # Save Return Code
                if [ $? -ne 0 ]                                         # If Error while Backup
                    then MESS="[ERROR] ${RC} while creating $BACK_FILE" # Advise Backup Error
                         sadm_writelog "$MESS"                          # Advise User - Log Info
                         RC=1                                           # Make Sure Return Code is 0
                    else MESS="[OK] Creating Backup file $BACK_FILE"    # Advise Backup Success
                         sadm_writelog "$MESS"                          # Advise User - Log Info
                         RC=0                                           # Make Sure Return Code is 0
                fi
                TOTAL_ERROR=$(($TOTAL_ERROR+$RC))                       # Total = Cumulate RC Value
                if [ "$TOTAL_ERROR" -ne 0 ]                             # If TotalError is not 0
                    then sadm_writelog "Total of Error is $TOTAL_ERROR" # Print Current Total Error
                fi
           else MESS="Skip $WDIR doesn't exist on $(sadm_get_fqdn)"     # Sel. Backup Dir not present
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
                   then sadm_writelog "Will delete $FILE_COUNT file(s) in ${WDIR}"
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


# ==================================================================================================
#                Mount the NFS Directory where all the backup files will be stored
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

# ==================================================================================================
#                              S T A R T   O F   M A I N    P R O G R A M
# ==================================================================================================
#
    sadm_start                                                          # Init Env.Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9])
    COMPRESS="OFF" 
    while getopts "hcd:" opt ; do                                        # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            c) COMPRESS="ON"                                            # Compress backup activated
               ;;
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
             sadm_writelog "Backup compression is $COMPRESS"            # Show Status of compression
    fi
    mount_nfs                                                           # Mount NFS Dir.
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    create_backup                                                       # Create TGZ of Seleted Dir.
    BACKUP_ERROR=$?                                                     # Save the Total Error
    clean_backup_dir                                                    # Delete Old Backup
    CLEANING_ERROR=$?                                                   # Save the Total Error
    SADM_EXIT_CODE=$(($BACK_ERROR+$CLEANING_ERROR))                     # Total=Backup+Cleaning Err.
    umount_nfs                                                          # Umounting NFS Drive
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
