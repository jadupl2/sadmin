#!/bin/bash
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Backup and Compress directories choosen in $BACKUP_LIST as tar files (tgz)
#   Date:       28 August 2015
#   Synopsis:   This script is used to create a tgz file of all directories speciied in the 
#               variable $BACKUP_LIST to NFS $ARCHIVE_DIR .
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
#   2018_01_02  JDuplessis
#       V2.3 Small Corrections and added comments
#   2018_02_09  JDuplessis
#       V2.4 Begin Testing new version with daily,weekly,monthly and yearly backup
#   2018_02_09  JDuplessis
#       V2.5 Fisrt Production Version 
#   2018_02_10  JDuplessis
#       V2.6 Switch to bash instead of sh (Problem with Dash and array)
#       V2.7 Create Backup Link in the latest directory
#       V2.8 Add Exclude File Variable
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
SADM_VER='2.8'                             ; export SADM_VER            # Your Script Version
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
DEBUG_LEVEL=0                       ; export DEBUG_LEVEL                # 0=NoDebug Higher=+Verbose
TOTAL_ERROR=0                       ; export TOTAL_ERROR                # Total Rsync Error
CUR_DAY_NUM=`date +"%u"`            ; export CUR_DAY_NUM                # Current Day in Week 1=Mon
CUR_DATE_NUM=`date +"%d"`           ; export CUR_DATE_NUM               # Current Date Nb. in Month
CUR_MTH_NUM=`date +"%m"`            ; export CUR_MTH_NUM                # Current Month Number 

# NFS Backup Parameters Values are taken from sadmin.cfg file
#SADM_BACKUP_NFS_SERVER=""                   ; export SADM_BACKUP_NFS_SERVER
#SADM_BACKUP_NFS_MOUNT_POINT=""              ; export SADM_BACKUP_NFS_MOUNT_POINT
#SADM_BACKUP_NFS_TO_KEEP=3                   ; export SADM_BACKUP_NFS_TO_KEEP

# LIST OF DIRECTORIES THAT WILL BE BACKUP (IF THEY EXIST OF COURSE)
# YOU NEED TO CHANGE THEM TO ADAPT TO YOUR ENVIRONMENT (Each line MUST end with a space)
BACKUP_LIST="/cadmin /sadmin /home /storix /mystuff /sysadmin /sysinfo /aix_data /gitrepos /wiki "
BACKUP_LIST="$BACKUP_LIST /os /www /scom /slam /install /linternux /useradmin /svn /stbackups "
BACKUP_LIST="$BACKUP_LIST /etc /var/adsmlog /var/named /var/www /wsadmin /psadmin "
BACKUP_LIST="$BACKUP_LIST /var/ftp /var/lib/mysql /var/spool/cron "
export BACKUP_LIST
#

# List of Files to exclude from Backup
EXCLUDE_LIST="*.iso "                           ; export EXCLUDE_LIST   # Files Excluded from Backup

LOCAL_MOUNT="/mnt/backup"                       ; export LOCAL_MOUNT    # Local NFS Mount Point 
ARCHIVE_DIR=""                                  ; export ARCHIVE_DIR    # Where Backup Stored
#
WEEKDAY=("index0" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
MTH_NAME=("index0" "January" "February" "March" "April" "May" "June" "July" "August" "September" 
        "October" "November" "December")


# Root Backup Directories
DDIR="${LOCAL_MOUNT}/daily"             ; export DDIR                   # Root Dir. Daily Backup
WDIR="${LOCAL_MOUNT}/weekly"            ; export WDIR                   # Root Dir. Weekly Backup
MDIR="${LOCAL_MOUNT}/monthly"           ; export MDIR                   # Root Dir. Monthly Backup
YDIR="${LOCAL_MOUNT}/yearly"            ; export YDIR                   # Root Dir. Yearly Backup
LDIR="${LOCAL_MOUNT}/latest"            ; export LDIR                   # Root Dir. Latest Backup

# Backup Directories for current backup
DAILY_DIR="${DDIR}/${SADM_HOSTNAME}"    ; export DAILY_DIR              # Dir. For Daily Backup
WEEKLY_DIR="${WDIR}/${SADM_HOSTNAME}"   ; export WEEKLY_DIR             # Dir. For Weekly Backup
MONTHLY_DIR="${MDIR}/${SADM_HOSTNAME}"  ; export MONTHLY_DIR            # Dir. For Monthly Backup
YEARLY_DIR="${YDIR}/${SADM_HOSTNAME}"   ; export YEARLY_DIR             # Dir. For Yearly Backup
LATEST_DIR="${LDIR}/${SADM_HOSTNAME}"   ; export LATEST_DIR             # Latest Backup Directory

# Number of backup to keep per backup type
DAILY_BACKUP_TO_KEEP=2                  ; export DAILY_BACKUP_TO_KEEP   # Nb. Daily Backup to keep
WEEKLY_BACKUP_TO_KEEP=3                 ; export WEEKLY_BACKUP_TO_KEEP  # Nb. Weekly Backup to keep
MONTHLY_BACKUP_TO_KEEP=3                ; export MONTHLY_BACKUP_TO_KEEP # Nb. Monthly Backup to keep
YEARLY_BACKUP_TO_KEEP=2                 ; export YEARLY_BACKUP_TO_KEEP  # Nb. Yearly Backup to keep

# Trigger per backup type (When to do a weekly, monthly and Yearly Backup)
WEEKLY_BACKUP_DAY=5                     ; export WEEKLY_BACKUP_DAY      # Day Week Backup 1=Mon7=Sun
MONTHLY_BACKUP_DATE=1                   ; export MONTHLY_BACKUP_DATE    # Monthly Backup Date (1-28)
YEARLY_BACKUP_MONTH=12                  ; export YEARLY_BACKUP_MONTH    # Yearly Backup Month (1-12)
YEARLY_BACKUP_DATE=31                   ; export YEARLY_BACKUP_DATE     # Yearly Backup Date (1-28)


# --------------------------------------------------------------------------------------------------
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
help_usage()
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
    
    # Daily Root Backup Directory
    if [ ! -d "${DDIR}" ]                                               # Daily Backup Dir. Exist ?
        then sadm_writelog "Making Daily backup directory $DDIR"        # Show user what were doing
             mkdir -p $DDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $DDIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $DDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $DDIR" 
                     return 1 
             fi
             chmod 775 $DDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $DDIR" ; return 1 ;fi
    fi
    
    # Daily Backup Directory
    if [ ! -d "${DAILY_DIR}" ]                                          # Daily Backup Dir. Exist ?
        then sadm_writelog "Making Daily backup directory $DAILY_DIR"   # Show user what were doing
             mkdir -p $DAILY_DIR                                        # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $DAILY_DIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $DAILY_DIR                # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $DAILY_DIR" 
                     return 1 
             fi
             chmod 775 $DAILY_DIR                                       # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $DAILY_DIR" ; return 1 ;fi
    fi

    # Weekly Root Backup Directory
    if [ ! -d "${WDIR}" ]                                               # Daily Backup Dir. Exist ?
        then sadm_writelog "Making Weekly backup directory $WDIR"       # Show user what were doing
             mkdir -p $WDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $WDIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $WDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $WDIR" 
                     return 1 
             fi
             chmod 775 $WDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $WDIR" ; return 1 ;fi
    fi
    
    # Weekly Backup Directory
    if [ ! -d "${WEEKLY_DIR}" ]                                         # Daily Backup Dir. Exist ?
        then sadm_writelog "Making Weekly backup directory $WEEKLY_DIR" # Show user what were doing
             mkdir -p $WEEKLY_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $WEEKLY_DIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $WEEKLY_DIR               # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $WEEKLY_DIR" 
                     return 1 
             fi
             chmod 775 $WEEKLY_DIR                                      # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $WEEKLY_DIR" ; return 1 ;fi
    fi

    # Monthly Root Backup Directory
    if [ ! -d "${MDIR}" ]                                               # Monthly Backup Dir. Exist?
        then sadm_writelog "Making Monthly backup directory $MDIR"      # Show user what were doing
             mkdir -p $MDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $MDIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $MDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $MDIR" 
                     return 1 
             fi
             chmod 775 $MDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $MDIR" ; return 1 ;fi
    fi

    # Monthly Backup Directory
    if [ ! -d "${MONTHLY_DIR}" ]                                        # Monthly Backup Dir. Exist?
        then sadm_writelog "Making Monthly backup directory $MONTHLY_DIR" # Show user what were doing
             mkdir -p $MONTHLY_DIR                                      # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $MONTHLY_DIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $MONTHLY_DIR              # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $MONTHLY_DIR" 
                     return 1 
             fi
             chmod 775 $MONTHLY_DIR                                     # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $MONTHLY_DIR" ; return 1 ;fi
    fi


    # Yearly Root Backup Directory
    if [ ! -d "${YDIR}" ]                                               # Yearly Backup Dir. Exist?
        then sadm_writelog "Making Yearly backup directory $YDIR"       # Show user what were doing
             mkdir -p $YDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $YDIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $YDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $YDIR" 
                     return 1 
             fi
             chmod 775 $YDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $YDIR" ; return 1 ;fi
    fi
    
    # Yearly Backup Directory
    if [ ! -d "${YEARLY_DIR}" ]                                         # Yearly Backup Dir. Exist?
        then sadm_writelog "Making Yearly backup directory $YEARLY_DIR" # Show user what were doing
             mkdir -p $YEARLY_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $YEARLY_DIR" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $YEARLY_DIR               # Assign it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $YEARLY_DIR" 
                     return 1 
             fi
             chmod 775 $YEARLY_DIR                                      # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $YEARLY_DIR" ; return 1 ;fi
    fi

    # Latest Root Backup Directory
    if [ ! -d "${LDIR}" ]                                               # Latest Backup Dir Exist?
        then sadm_writelog "Making latest backup directory $LDIR"       # Show user what were doing
             mkdir -p $LDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $LATEST" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $LDIR                     # Give it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $LDIR" 
                     return 1 
             fi
             chmod 775 $LDIR                                            # R/W to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $LDIR" ; return 1 ;fi
    fi

    # Latest Backup Directory
    if [ ! -d "${LATEST_DIR}" ]                                         # Latest Backup Dir Exist?
        then sadm_writelog "Making latest backup directory $LATEST_DIR" # Show user what were doing
             mkdir -p $LATEST_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] mkdir $LATEST" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $LATEST_DIR               # Give it SADM USer&Group
             if [ $? -ne 0 ] 
                then sadm_writelog "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $LATEST_DIR" 
                     return 1 
             fi
             chmod 775 $LATEST_DIR                                      # R/W to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] chmod 775 $LATEST_DIR" ; return 1 ;fi
    fi

    # Remove previous backup link in the latest directory
    sadm_writelog "Removing previous backup links in $LATEST_DIR"
    rm -f $LATEST_DIR/20* > /dev/null 2>&1 

    # Determine the Directory where the backup will be created
    ARCHIVE_DIR="${DAILY_DIR}"                                          # Default goes in Daily Dir.
    LINK_DIR="../../daily/${SADM_HOSTNAME}"                             # Latest Backup Link Dir.
    if [ "${CUR_DAY_NUM}" -eq "$WEEKLY_BACKUP_DAY" ]                    # It's the Weekly Backup Day
        then ARCHIVE_DIR="${WEEKLY_DIR}"                                # Will be Weekly Backup Dir. 
             LINK_DIR="../../weekly/${SADM_HOSTNAME}"                   # Latest Backup Link Dir.
    fi 
    if [ "$CUR_DATE_NUM" -eq "$MONTHLY_BACKUP_DATE" ]                   # It's Monthly Backup Date ?
        then ARCHIVE_DIR="${MONTHLY_DIR}"                               # Will be Monthly Backup Dir
             LINK_DIR="../../monthly/${SADM_HOSTNAME}"                  # Latest Backup Link Dir.
    fi 
    if [ "$CUR_DATE_NUM" -eq "$YEARLY_BACKUP_DATE" ]                    # It's Year Backup Date ?
        then if [ "$CUR_MTH_NUM" -eq "$YEARLY_BACKUP_MONTH" ]           # And It's Year Backup Mth ?
                then ARCHIVE_DIR="${YEARLY_DIR}"                        # Will be Yearly Backup Dir
                     LINK_DIR="../../yearly/${SADM_HOSTNAME}"           # Latest Backup Link Dir.
             fi
    fi 
    
    # Make Sure Backup Destination Directory Exist
    if [ ! -d "${ARCHIVE_DIR}" ]                                         # Backup Dir. Exist?
        then sadm_writelog "Making Today backup directory $ARCHIVE_DIR"  # Show user what were doing
             mkdir $ARCHIVE_DIR                                          # Create Final Backup Dir.
             chown ${SADM_USER}:${SADM_GROUP} $ARCHIVE_DIR               # Assign it SADM USer&Group
             chmod 770 $ARCHIVE_DIR                                      # Read/Write to SADM Usr/Grp
    fi

    # Show Backup Preferences
    sadm_writelog " " 
    sadm_writelog "You have chosen to : "
    if [ "$COMPRESS" = 'ON' ] 
        then sadm_writelog " - Compress the backup file" 
        else sadm_writelog " - Not compress the backup"
    fi
    sadm_writelog " - Backup Directory is ${ARCHIVE_DIR}"
    sadm_writelog " - Keep $DAILY_BACKUP_TO_KEEP daily backups"
    sadm_writelog " - Keep $WEEKLY_BACKUP_TO_KEEP weekly backups"
    sadm_writelog " - Keep $MONTHLY_BACKUP_TO_KEEP monthly backups"
    sadm_writelog " - Keep $YEARLY_BACKUP_TO_KEEP yearly backups"
    sadm_writelog " - Do the weekly backup on ${WEEKDAY[$WEEKLY_BACKUP_DAY]}"
    sadm_writelog " - Do the monthy backup on the $MONTHLY_BACKUP_DATE of every month"
    sadm_writelog " - Do the yearly backup on the $YEARLY_BACKUP_DATE of ${MTH_NAME[$YEARLY_BACKUP_MONTH]} every year"
    return 0
}


# --------------------------------------------------------------------------------------------------
#        Create Backup Files Main Function - Loop for each file specified in $BACKUP_LIST
# --------------------------------------------------------------------------------------------------
create_backup()
{
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_TEN_DASH}"                                    # Line of 80 Equal Char.
    sadm_writelog "Starting the Backup Process"                         # Advise Backup Process Begin
    sadm_writelog " "                                                   # Blank Line
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.
    TOTAL_ERROR=0                                                       # Make Sure Variable is at 0

    # Do a Backup Of All Selected Directories - Defined in BACKUP_LIST Variables
    for WDIR in $BACKUP_LIST                                             # Loop Dir. To Backup
        do
        if [ -d ${WDIR} ]                                               # Dir to Backup Exist ?
           then cd $WDIR                                                # Ok then CD into it
            
                # Construct Backup File Name (Dir+Date_Time_tgz)
                BASE_NAME=`echo "$WDIR" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' `
                TIME_STAMP=`date "+%C%y_%m_%d-%H_%M_%S"`                # Date & Time
                sadm_writelog "${SADM_TEN_DASH}"                        # Line of 10 Dash in Log
                sadm_writelog "Current directory is `pwd`"              # Print Current Dir.

                # Build Backup Exclude list 
                find . -type s -print > /tmp/exclude                    # Put all Sockets in exclude
                for excl in $EXCLUDE_LIST                               # Loop through all excludes
                    do
                    echo "$excl" >> /tmp/exclude                        # Buil the Exclude List
                    done
                if [ $DEBUG_LEVEL -gt 0 ]                               # If Debug Show Exclude List 
                    then sadm_writelog " " ; sadm_writelog "Content of exclude file" 
                         cat /tmp/exclude| while read ln ;do sadm_writelog "$ln" ;done
                         sadm_writelog " "
                fi

                # Perform the Backup using tar command
                if [ "$COMPRESS" == "ON" ] 
                    then BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tgz"     # Final tgz Backup file name
                         sadm_writelog "tar -cvzf ${ARCHIVE_DIR}/${BACK_FILE} -X /tmp/exclude ." 
                         tar -cvzf ${ARCHIVE_DIR}/${BACK_FILE} -X /tmp/exclude . >/dev/null 2>>$SADM_LOG
                         RC=$?                                          # Save Return Code
                    else BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tar"     # Final tar Backup file name
                         sadm_writelog "tar -cvf ${ARCHIVE_DIR}/${BACK_FILE} -X /tmp/exclude ." 
                         tar -cvf ${ARCHIVE_DIR}/${BACK_FILE} -X /tmp/exclude . >/dev/null 2>>$SADM_LOG
                         RC=$?                                          # Save Return Code
                fi
                if [ $RC -ne 0 ]                                        # If Error while Backup
                    then MESS="[ERROR] ${RC} while creating $BACK_FILE" # Advise Backup Error
                         sadm_writelog "$MESS"                          # Advise User - Log Info
                         RC=1                                           # Make Sure Return Code is 0
                    else MESS="[SUCCESS] Creating Backup $BACK_FILE"    # Advise Backup Success
                         sadm_writelog "$MESS"                          # Advise User - Log Info
                         RC=0                                           # Make Sure Return Code is 0
                fi
                TOTAL_ERROR=$(($TOTAL_ERROR+$RC))                       # Total = Cumulate RC Value

                # Create link to backup in the server latest directory
                cd ${LATEST_DIR} 
                if [ $DEBUG_LEVEL -gt 0 ]                               # If Debug is Activated
                   then sadm_writelog "Current directory is `pwd`"      # Print Current Dir.
                        sadm_writelog "ln -s ${LINK_DIR}/${BACK_FILE} ${BACK_FILE}" 
                fi
                ln -s ${LINK_DIR}/${BACK_FILE} ${BACK_FILE}   

                rm -f /tmp/exclude >/dev/null 2>&1                      # Remove socket tmp file
           else MESS="[SKIPPING] $WDIR doesn't exist on $(sadm_get_fqdn)" 
                sadm_writelog "${SADM_TEN_DASH}"                        # Line of 10 Dash in Log
                sadm_writelog "$MESS"                                   # Advise User - Log Info
        fi
        done
    
    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_TEN_DASH}"                                    # Line of 10 Equal Char.
    sadm_writelog "Total error(s) while creating backup is $TOTAL_ERROR"
    return $TOTAL_ERROR                                                 # Return Total of Error 
}


# --------------------------------------------------------------------------------------------------
#               Keep only the number of backup copies specied in $SADM_BACKUP_NFS_TO_KEEP
# --------------------------------------------------------------------------------------------------
clean_backup_dir()
{
    TOTAL_ERROR=0                                                       # Reset Total of error 
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_TEN_DASH}"                                    # Line of 10 Equal Char.
    sadm_writelog "Applying chosen policy to ${ARCHIVE_DIR} directory"  # Msg to user
    sadm_writelog "Keep only last $SADM_BACKUP_NFS_TO_KEEP copies of each backup in ${ARCHIVE_DIR}"
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.

    # Enter Server Backup Directory
    # May need to delete some backup if more than $SADM_BACKUP_NFS_TO_KEEP copies
    cd ${ARCHIVE_DIR}                                                   # Change Dir. To Backup Dir.
    #sadm_writelog "Current Backup directory is `pwd`"                   # Print Current Dir.

    sadm_writelog "List of backup date in `pwd`"                        # List of Date in Backup Dir
    ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq | while read ln ;do sadm_writelog "$ln" ;done
    backup_count=`ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |wc -l` 

    sadm_writelog "We need to keep the last $SADM_BACKUP_NFS_TO_KEEP most recent backups"
    sadm_writelog "We have now $backup_count backup(s)." 

    if [ "$backup_count" -gt "$SADM_BACKUP_NFS_TO_KEEP" ] 
        then sadm_writelog "So we will delete these backup date(s)"
             ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |tail -$SADM_BACKUP_NFS_TO_KEEP > $SADM_TMP_FILE3
             cat $SADM_TMP_FILE3 | while read ln ;do sadm_writelog "$ln" ;done
             #cat $SADM_TMP_FILE3 | while read ln ;do sadm_writelog "Deleting $ln" ;rm -f ${ln}* ;done
             sadm_writelog "Here is the list of backup that reside in ${ARCHIVE_DIR}"
             ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq | while read ln ;do sadm_writelog "$ln" ;done        else sadm_writelog "No clean up needed"
    fi 
    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    return 0                                                            # Return to caller
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
        else sadm_writelog "[SUCCESS] NFS Mount Succeeded"              # NFS Mount Succeeded Msg
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
    sadm_writelog " "                                                   # Blank Line
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
    backup_setup                                                        # Create Necessary Dir.
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    create_backup                                                       # Create TGZ of Seleted Dir.
    SADM_EXIT_CODE=$?                                                   # If Made so far not error 
    clean_backup_dir                                                    # Delete Old Backup
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    umount_nfs                                                          # Umounting NFS Drive
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
