#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_backupdb.sh
#   Synopsis    :   MySQL SADMIN Database Backup
#   Version     :   1.0
#   Date        :   4 January 2018
#   Requires    :   sh and SADM Library
#   Description :   Run from this script take a backup of the sadmin database.
#                   Backup are created in the chosen directory (BACKUP_DIR)
#                   
#
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
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
# CHANGELOG
#
# 2018_01_04 JDuplessis
#   V1.0 Initial Backup MySQL Database Script
#   V1.1 Test Bug Corrections
# 2018_01_06 JDuplessis
#   V1.2 Added Cleanup Function to Purge files based on nb. of files user wants to keep
# 2018_01_07 JDuplessis
#   V1.3 Added directory latest (always contain last backup) & Display Paramaters to users
# 2018_01_0 JDuplessis
#   V1.4 Global Restructure and variable naming
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
# These Global variables are used by SADMIN Libraries - They influence behavior of some functions
# These variables need to be defined prior to loading the SADMIN function Libraries
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='1.4'                             ; export SADM_VER            # Your Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But you can override them here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE    # Max Nb. Lines in LOG file
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE     # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send status
#===================================================================================================




#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                       ; export DEBUG_LEVEL                # 0=NoDebug Higher=+Verbose
CUR_DAY_NUM=`date +"%u"`            ; export CUR_DAY_NUM                # Current Day in Week 1=Mon
CUR_DATE_NUM=`date +"%d"`           ; export CUR_DATE_NUM               # Current Date Nb. in Month
CUR_MTH_NUM=`date +"%m"`            ; export CUR_MTH_NUM                # Current Month Number 
MYSQLDUMP=""                        ; export MYSQLDUMP                  # Save mysqldump Full Path
BACKUP_ROOT_DIR="${SADMIN}/dat/dbb" ; export BACKUP_ROOT_DIR            # Root DataBase Backup Dir.
BACKUP_FILENAME=""                  ; export BACKUP_FILENAME            # Backup File Name
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


#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
#===================================================================================================
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
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

    sadm_writelog "You have chosen to : "
    sadm_writelog " - Keep $DAILY_BACKUP_TO_KEEP daily backups"
    sadm_writelog " - Keep $WEEKLY_BACKUP_TO_KEEP weekly backups"
    sadm_writelog " - Keep $MONTHLY_BACKUP_TO_KEEP monthly backups"
    sadm_writelog " - Keep $YEARLY_BACKUP_TO_KEEP yearly backups"
    sadm_writelog " - Do the weekly backup on ${WEEKDAY[$WEEKLY_BACKUP_DAY]}"
    sadm_writelog " - Do the monthy backup on the $MONTHLY_BACKUP_DATE of every month"
    sadm_writelog " - Do the yearly backup on the $YEARLY_BACKUP_DATE of ${MTH_NAME[$YEARLY_BACKUP_MONTH]} every year"
}

#===================================================================================================
# Delete Backup File according to the number of backup user wants to keep 
# Will Receive Daily, Weekly, Monthly and Yearly Directory Name
#===================================================================================================
backup_cleanup()
{
    CLEAN_DIR=$1                                                        # Save Backup Dir. to Clean
    NB_KEEP=$2                                                          # Nb. OF Backup to Keep
    sadm_writelog "Cleaning `basename $CLEAN_DIR` Backup (Keep last $NB_KEEP Backups)"   

    # Produce a list of Databases Directories in $CLEAN_DIR 
    find $CLEAN_DIR -type d -print |grep -v "${CLEAN_DIR}$" >${SADM_TMP_FILE1} 
    if [ ! -s ${SADM_TMP_FILE1} ]                                       # Result file is Empty
       then sadm_writelog "      - No Backup to delete (Currently 0)"   # No Backup done yet
            return 0                                                    # Return Caller
    fi 

    # Process all Databases Directories Found
    pwd_save=`pwd`                                                      # Save Current Directory
    while read dbdir                                                    # Read All DB Dir to process
        do
        sadm_writelog "    - Pruning `basename $dbdir` Database Backup" # Show User Database pruning
        cd $dbdir                                                       # cd to Database Backup Dir.
        if [ $DEBUG_LEVEL -gt 0 ] ; then ls -l ; fi                     # In Debug List Backup files
        NB_BACKUP=`ls -1 | wc -l | tr -d ' '`                           # Count Nb. Backup in Dir.
        let "NB_DELETE = $NB_BACKUP - $NB_KEEP"                         # Nb. Backup to Delete
        if [ $DEBUG_LEVEL -gt 0 ]                                       # If Debug Activated
            then sadm_writelog "NB_DELETE = $NB_BACKUP - $NB_KEEP"      # Show Math Done to Get Nb
        fi
        if [ "$NB_DELETE" -gt 0 ]                                       # At Least 1 Backup to del.?
            then sadm_writelog "      - $NB_DELETE Backup(s) out of $NB_BACKUP will be remove"  
                 if [ $DEBUG_LEVEL -gt 0 ] ; then ls -1t | tail -${NB_DELETE} ;fi 
                 ls -1t | tail -${NB_DELETE} | while read bname         # Process each Backup to Del
                    do
                    sadm_writelog "      - Deleting file $bname ..."    # Show Backup file to Del.
                    rm -f $bname                                        # Remove Database Backup
                    done                 
            else sadm_writelog "      - No Backup to delete (Currently $NB_BACKUP)"  
        fi
        done < ${SADM_TMP_FILE1}                                        # List of Database to clean
    cd $pwd_save                                                        # cd to previous save dir.
    return
}

    
#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
backup_db()
{
    CURRENT_DB=$1                                                       # Database Name to Backup
    BACKUP_FILENAME="${CURRENT_DB}_`date +"%Y_%m_%d_%H_%M_%S_%A"`.sql"  # Build Backup File Name 

    # Determine the Directory where the backup will be created
    BACKUP_DIR="${DAILY_DIR}/$CURRENT_DB"                               # Default goes in Daily Dir.
    if [ "${CUR_DAY_NUM}" -eq "$WEEKLY_BACKUP_DAY" ]                    # It's the Weekly Backup Day
        then BACKUP_DIR="${WEEKLY_DIR}/$CURRENT_DB"                     # Will be Weekly Backup Dir. 
    fi 
    if [ "$CUR_DATE_NUM" -eq "$MONTHLY_BACKUP_DATE" ]                   # It's Monthly Backup Date ?
        then BACKUP_DIR="${MONTHLY_DIR}/$CURRENT_DB"                    # Will be Monthly Backup Dir
    fi 
    if [ "$CUR_DATE_NUM" -eq "$YEARLY_BACKUP_DATE" ]                    # It's Year Backup Date ?
        then if [ "$CUR_MTH_NUM" -eq "$YEARLY_BACKUP_MONTH" ]           # And It's Year Backup Mth ?
                then BACKUP_DIR="${YEARLY_DIR}/$CURRENT_DB"             # Will be Yearly Backup Dir
             fi
    fi 

    # Make Sure Backup Destination Directory Exist
    if [ ! -d "${BACKUP_DIR}" ]                                         # Backup Dir. Exist?
        then mkdir $BACKUP_DIR                                          # Create Final Backup Dir.
             chown ${SADM_USER}:${SADM_GROUP} $BACKUP_DIR               # Assign it SADM USer&Group
             chmod 770 $BACKUP_DIR                                      # Read/Write to SADM Usr/Grp
    fi

    sadm_writelog " "                                                   # Insert Blank Line in Log
    sadm_writelog "----------"                                          # Insert Sperator Dash Line
    sadm_writelog "Starting Backup of Database $CURRENT_DB"             # Advise User were Starting
    BFILE="${BACKUP_DIR}/${BACKUP_FILENAME}"                            # Backup Filename Full Path 
    sadm_writelog "Backup Directory is ${BACKUP_DIR}"                   # Show User Backup Directory
    sadm_writelog "Backup FileName is ${BACKUP_FILENAME}"               # Show User Backup Filename
    touch $BFILE                                                        # Create empty backup file
    chown ${SADM_USER}:${SADM_GROUP} $BFILE                             # Assign it SADM USer&Group
    chmod 600 $BFILE                                                    # Read/Write 2 SADM Usr Only

    CREDENTIAL="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD -h $SADM_DBHOST"   # User,Passwd and Host Used
    if [ $DEBUG_LEVEL -gt 5 ]                                           # If Debug Level > 5 
        then sadm_writelog "$MYSQLDUMP $CREDENTIAL $SADM_DBNAME "       # Debug = Write Command Used
    fi

    sadm_writelog "Running mysqldump ..."                               # Inform User
    $MYSQLDUMP $CREDENTIAL $SADM_DBNAME > $BFILE 2>&1                   # Run the Database Backup
    if [ $? -ne 0 ]                                                     # If Can't be found 
        then sadm_writelog "[ERROR] The 'mysqldump' command failed"     # Advise User
             return 1                                                   # Return Error to Caller
        else sadm_writelog "[SUCCESS] Backup Succeeded"                 # Advise User
             rm -f ${LATEST_DIR}/${CURRENT_DB}*                         # Remove Last DB Backup
             cp ${BFILE} ${LATEST_DIR}                                  # Copy Backup to Latest Dir.
             chmod 400 ${LATEST_DIR}/${BACKUP_FILENAME}                 # Make file only Readable 
             chown ${SADM_USER}:${SADM_GROUP} ${LATEST_DIR}/${BACKUP_FILENAME}  # Give Usr Access
    fi
}

#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    backup_setup "sadmin"                                               # Is Setup/Requirement ok ?
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller

    backup_db "sadmin"                                                  # Backup the Database
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller

    sadm_writelog " "                                                   # Insert Blank Line in Log
    sadm_writelog "----------"                                          # Insert Sperator Dash Line
    backup_cleanup "$DAILY_DIR"   "$DAILY_BACKUP_TO_KEEP"               # Purge unwanted Backup file
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller
    backup_cleanup "$WEEKLY_DIR"  "$WEEKLY_BACKUP_TO_KEEP"              # Purge unwanted Backup file
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller
    backup_cleanup "$MONTHLY_DIR" "$MONTHLY_BACKUP_TO_KEEP"             # Purge unwanted Backup file
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller
    backup_cleanup "$YEARLY_DIR"  "$YEARLY_BACKUP_TO_KEEP"              # Purge unwanted Backup file
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller   
    return 0                                                            # Return to Caller 
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN Server
        then sadm_writelog "Script only run on SADMIN system (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9]) ---------------------------------
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

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
