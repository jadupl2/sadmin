#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_server_backupdb.sh
#   Synopsis    :   MariaDB/MySQL Database Backup
#   Version     :   1.0
#   Date        :   4 January 2018
#   Requires    :   sh and SADM Library
#   Description :   Take a backup of all (Default) or selected (sadmin) database.
#                   Backup are created in the chosen directory (BACKUP_DIR)
#                   
#
#   Copyright (C) 2016-2018 Jacques Duplessis <sadmlinux@gmail.com> - http://sadmin.ca
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
# 2018_01_04 backup v1.0 Initial Backup MySQL Database Script
# 2018_01_05 backup v1.1 Test Bug Corrections
# 2018_01_06 backup v1.2 Added Cleanup Function to Purge files based on nb. of files user wants to keep
# 2018_01_07 backup v1.3 Added directory latest (always contain last backup) & Display Paramaters to users
# 2018_01_08 backup v1.4 Global Restructure and variable naming
# 2018_01_10 backup v1.5 Default to backup ALL MySQL Databases present, except the one specified.
# 2018_06_03 backup v1.6 Small Ameliorations and corrections
# 2018_06_11 backup v1.7 Change name to sadm_backupsd.sh
# 2018_06_19 backup v1.8 Default option is to Compress Backup - Add -u to do uncompressed backup
# 2018_07_14 backup v1.9 Switch to Bash Shell instead of sh (Causing Problem with Dash on Debian/Ubuntu)
# 2018_08_19 backup v2.0 Add '-b' to specify backup directory, enhance log verbose. 
# 2018_09_16 backup v2.1 Insert Alert Group Default
# 2020_04_01 backup v2.2 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2021_05_26 backup v2.3 Added command line option option [-b backup_dir] [-n dbname].
#@2022_08_17 backup v2.4 Updated with SADMIN section 1.52
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.52
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] # SADMIN defined ? SADMIN Libr. exist   
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi # Last chance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.4'                                      # Script version number
export SADM_PDESC="Take a backup of all (Default) or selected (sadmin) database."
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
# ---------------------------------------------------------------------------------------




#===================================================================================================
# Scripts Variables 
#===================================================================================================
CUR_DAY_NUM=`date +"%u"`            ; export CUR_DAY_NUM                # Current Day in Week 1=Mon
CUR_DATE_NUM=`date +"%d"`           ; export CUR_DATE_NUM               # Current Date Nb. in Month
CUR_MTH_NUM=`date +"%m"`            ; export CUR_MTH_NUM                # Current Month Number 
MYSQLDUMP=""                        ; export MYSQLDUMP                  # Save mysqldump Full Path
BACKUP_FILENAME=""                  ; export BACKUP_FILENAME            # Backup File Name
BACKUP_NAME="all"                   ; export BACKUP_NAME                # DB Name to Backup or 'all'
ERROR_COUNT=0                       ; export ERROR_COUNT                # Total Backup Error Counter
COMPRESS_BACKUP="Y"                 ; export COMPRESS_BACKUP            # Default Compress Backup 


WEEKDAY=("index0" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
MTH_NAME=("index0" "January" "February" "March" "April" "May" "June" "July" "August" "September" 
        "October" "November" "December")

# MySQL Connections Credential (Default Take Read/Write User in $SADMIN/cfg/sadmin.cfg)
CREDENTIAL="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD -h $SADM_DBHOST" ; export CREDENTIAL # for MySQL

# Database Name to exclude from backup, separate each name by the pipe symbol '|'.
#export DBEXCLUDE="information_schema|performance_schema"  
export DBEXCLUDE=""  


# Number of backup to keep per backup type
export DAILY_BACKUP_TO_KEEP=4                                           # Nb. Daily Backup to keep
export WEEKLY_BACKUP_TO_KEEP=4                                          # Nb. Weekly Backup to keep
export MONTHLY_BACKUP_TO_KEEP=4                                         # Nb. Monthly Backup to keep
export YEARLY_BACKUP_TO_KEEP=2                                          # Nb. Yearly Backup to keep

# What day/date per backup type
export WEEKLY_BACKUP_DAY=5                                              # Day Week Backup 1=Mon7=Sun
export MONTHLY_BACKUP_DATE=1                                            # Monthly Backup Date (1-28)
export YEARLY_BACKUP_MONTH=6                                            # Yearly Backup Month (1-12)
export YEARLY_BACKUP_DATE=31                                            # Yearly Backup Date (1-28)



# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n   ${BOLD}${YELLOW}[-b backup_dir]${NORMAL}\tDirectory where backup are stored"
    printf "\n   ${BOLD}${YELLOW}[-n dbname]${NORMAL}\t\tBackup only database name specified"
    printf "\n   ${BOLD}${YELLOW}[-u]${NORMAL}\t\t\tDo not compress backup"
    printf "\n\n" 
}

 
#===================================================================================================
#                 Make sure we have everything needed to start and succeed the backup
#===================================================================================================
backup_setup()
{
    sadm_write "\n----------Setup Backup Environment ...\n"             # Advise User were Starting
    
    which mysqldump >/dev/null 2>&1                                     # See if mysqldump available
    if [ $? -ne 0 ]                                                     # If Can't be found 
        then sadm_write_err "The 'mysqldump' command can't be found."   # Advise User
             sadm_write_err "The Backup cannot be started."             # No Backup can be performed
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
    cat $SADM_TMP_FILE1 > $SADM_TMP_FILE2
    
    # Exclude chosen DB from Backup
    if [ "$DBEXCLUDE" != "" ] ; then grep -vE "$DBEXCLUDE" $SADM_TMP_FILE1 > $SADM_TMP_FILE2 ;fi
    
    # If Database Name (-n) was specified, check if exist in Database
    if [ "$BACKUP_NAME" != 'all' ]                                      # If Backup one Database
        then grep -i "$BACKUP_NAME" $SADM_TMP_FILE2 > /dev/null 2>&1    # Grep for DB Name in DBList
             if [ $? -ne 0 ]                                            # If DB wasn't found 
                then sadm_write_err "The Database $BACKUP_NAME doesn't exist in Database.\n" 
                     sadm_write_err "The valid Database name are : \n"  # SHow user List valid DB
                     while read dbname                                  # Read DB List one by one
                        do
                        sadm_write "${dbname}\n"                        # Display DB Name
                        done <$SADM_TMP_FILE2
                     return 1                                           # Return Error to Caller
                else echo "$BACKUP_NAME" > $SADM_TMP_FILE2              # Put Name in List to Backup
             fi
    fi
    
    #sadm_write "You have chosen to : \n"
    if [ "$BACKUP_NAME" = 'all' ] 
        then sadm_write " - Backup All Databases.\n"
             if [ "$DBEXCLUDE" != "" ] 
                then sadm_write "   - Except these databases ; $DBEXCLUDE \n" 
             fi 
        else sadm_write " - Backup the Database '$BACKUP_NAME' \n" 
    fi
    if [ "$COMPRESS_BACKUP" = 'Y' ] 
        then sadm_write " - Compress the backup file.\n" 
        else sadm_write " - Not compress the backup file.\n"
    fi
    sadm_write " - Keep $DAILY_BACKUP_TO_KEEP daily backups.\n"
    sadm_write " - Keep $WEEKLY_BACKUP_TO_KEEP weekly backups.\n"
    sadm_write " - Keep $MONTHLY_BACKUP_TO_KEEP monthly backups.\n"
    sadm_write " - Keep $YEARLY_BACKUP_TO_KEEP yearly backups.\n"
    sadm_write " - Do the weekly backup on ${WEEKDAY[$WEEKLY_BACKUP_DAY]}.\n"
    sadm_write " - Do the monthly backup on the $MONTHLY_BACKUP_DATE of every month.\n"
    sadm_write " - Do the yearly backup on the $YEARLY_BACKUP_DATE of ${MTH_NAME[$YEARLY_BACKUP_MONTH]} every year.\n"
}

#===================================================================================================
# Delete Backup File according to the number of backup user wants to keep 
# Will Receive Daily, Weekly, Monthly and Yearly Directory Name
#===================================================================================================
backup_cleanup()
{
    CLEAN_DIR=$1                                                        # Save Backup Dir. to Clean
    NB_KEEP=$2                                                          # Nb. OF Backup to Keep
    sadm_write "\nCleaning `basename $CLEAN_DIR` Backup (Keep last $NB_KEEP Backups).\n"   

    # Produce a list of Databases Directories in $CLEAN_DIR 
    find $CLEAN_DIR -type d -print |grep -v "${CLEAN_DIR}$" >${SADM_TMP_FILE1} 
    if [ ! -s ${SADM_TMP_FILE1} ]                                       # Result file is Empty
       then sadm_write "      - No Backup to delete (Currently 0).\n"   # No Backup done yet
            return 0                                                    # Return Caller
    fi 

    # Process all Databases Directories Found
    pwd_save=`pwd`                                                      # Save Current Directory
    while read dbdir                                                    # Read All DB Dir to process
        do
        sadm_write "    - Pruning $dbdir Database Backup.\n"            # Show User Database pruning
        cd $dbdir                                                       # cd to Database Backup Dir.
        if [ $SADM_DEBUG -gt 0 ] ; then ls -l ; fi                     # In Debug List Backup files
        NB_BACKUP=`ls -1 | wc -l | tr -d ' '`                           # Count Nb. Backup in Dir.
        NB_DELETE=`echo "$NB_BACKUP - $NB_KEEP" | $SADM_BC`             # Nb. Backup to Delete
        if [ $SADM_DEBUG -gt 0 ]                                       # If Debug Activated
            then sadm_write "NB_DELETE = $NB_BACKUP - $NB_KEEP \n"      # Show Math Done to Get Nb
        fi
        if [ "$NB_DELETE" -gt 0 ]                                       # At Least 1 Backup to del.?
            then sadm_write "      - $NB_DELETE Backup(s) out of $NB_BACKUP will be remove.\n"  
                 if [ $SADM_DEBUG -gt 0 ] ; then ls -1t | tail -${NB_DELETE} ;fi 
                 ls -1t | tail -${NB_DELETE} | while read bname         # Process each Backup to Del
                    do
                    sadm_write "      - Deleting file $bname ...\n"     # Show Backup file to Del.
                    rm -f $bname                                        # Remove Database Backup
                    done                 
            else sadm_write "      - No Backup to delete (We have now $NB_BACKUP backup file(s)).\n"  
        fi
        done < ${SADM_TMP_FILE1}                                        # List of Database to clean
    cd $pwd_save                                                        # cd to previous save dir.
    return
}

    
#===================================================================================================
#                             Backup Database Function
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

    sadm_write "\n----------\nStarting Backup of Database ${CURRENT_DB}.\n"  # Advise User were Starting
    BFILE="${BACKUP_DIR}/${BACKUP_FILENAME}"                            # Backup Filename Full Path 
    sadm_write "Backup Directory is ${BACKUP_DIR}\n"                    # Show User Backup Directory
    if [ "$COMPRESS_BACKUP" = 'Y' ]                                     # If Compress option Chosen
        then sadm_write "Backup FileName is ${BACKUP_FILENAME}.gz\n"    # Show Compress Backup Name
        else sadm_write "Backup FileName is ${BACKUP_FILENAME}\n"       # Show User Backup Filename
    fi
    touch $BFILE                                                        # Create empty backup file
    chown ${SADM_USER}:${SADM_GROUP} $BFILE                             # Assign it SADM USer&Group
    chmod 640 $BFILE                                                    # Read/Write 2 SADM Usr Only
    if [ $SADM_DEBUG -gt 5 ]                                           # If Debug Level > 5 
        then sadm_write "$MYSQLDUMP $CREDENTIAL $SADM_DBNAME \n"        # Debug = Write Command Used
    fi

    sadm_write "Running mysqldump ...\n"                                # Inform User
    $MYSQLDUMP $CREDENTIAL $SADM_DBNAME > $BFILE 2>&1                   # Run the Database Backup
    if [ $? -ne 0 ]                                                     # If Can't be found 
        then sadm_write_err "[ERROR] The 'mysqldump' command failed \n" # Advise User
             return 1                                                   # Return Error to Caller
        else sadm_write "[SUCCESS] Backup Succeeded \n"                 # Advise User
             rm -f ${LATEST_DIR}/${CURRENT_DB}*                         # Remove Last DB Backup
             if [ "$COMPRESS_BACKUP" = 'Y' ]                            # If Compress option Chosen
                then gzip $BFILE                                        # Compress File
                     BFILE="${BFILE}.gz"                                # Add .gz to Backup Filename
                     cp ${BFILE} ${LATEST_DIR}                          # Copy Backup to Latest Dir.
                     chmod 440 ${LATEST_DIR}/${BACKUP_FILENAME}.gz      # Make file only Readable 
                     chown ${SADM_USER}:${SADM_GROUP} ${LATEST_DIR}/${BACKUP_FILENAME}.gz
                else cp ${BFILE} ${LATEST_DIR}                          # Copy Backup to Latest Dir.
                     chmod 440 ${LATEST_DIR}/${BACKUP_FILENAME}         # Make file only Readable 
                     chown ${SADM_USER}:${SADM_GROUP} ${LATEST_DIR}/${BACKUP_FILENAME} 
             fi
    fi
}

#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    # Make sure at least (-a or -n) we have a database backup to do.
    if [ "$BACKUP_NAME"  = "" ]                                         # No Database Name Specified
        then sadm_write "[ERROR] No Database Name Specified.\n"
             return 1
    fi

    # Backup Directories
    DAILY_DIR="${BACKUP_ROOT_DIR}/daily"     ; export DAILY_DIR             # Dir. For Daily Backup                                 
    WEEKLY_DIR="${BACKUP_ROOT_DIR}/weekly"   ; export WEEKLY_DIR            # Dir. For Week Backup
    MONTHLY_DIR="${BACKUP_ROOT_DIR}/monthly" ; export MONTHLY_DIR           # Dir. For Mth Backup
    YEARLY_DIR="${BACKUP_ROOT_DIR}/yearly"   ; export YEARLY_DIR            # Dir. For Yearly Backup
    LATEST_DIR="${BACKUP_ROOT_DIR}/latest"   ; export LATEST_DIR            # Latest Backup Dir.

    # Make Sure Backup Directories exist, Option given are valid and show user options chosen ------
    backup_setup                                                        # Is Setup/Requirement ok ?
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller

    # Backup All Databases included in $SADM_TMP_FILE2 (created in backup_setup)--------------------
    while read dbname                                                   # Read DB Name one by one
        do
        backup_db "$dbname"                                             # Backup the Database
        if [ $? -ne 0 ] ; then ERROR_COUNT=$((ERROR_COUNT + 1)) ; fi    # Count Backup Error 
        done <$SADM_TMP_FILE2                                           # End of DBNAme to Backup
    if [ "$ERROR_COUNT" -ne 0 ] ; then return 1 ; fi                    # If Error Return to Caller

    # Prune Backup Directories to respect the number of backup to keep, based on user choice -------
    sadm_write "\n----------\n"                                         # Insert Sperator Dash Line
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


# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    BACKUP_NAME="all"                                                   # DB to Backup Default=All
    BACKUP_ROOT_DIR="$SADM_DBB_DIR"                                     # Default DB Backup Dir.
    COMPRESS_BACKUP="Y"                                                 # Compress Backup by Default

    while getopts "hvd:bn:u" opt ; do                                   # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
            b) BACKUP_ROOT_DIR=$OPTARG                                  # Database Backup Directory
               ;;
            n) BACKUP_NAME=$OPTARG                                      # Database Name to Backup
               ;;
            u) COMPRESS_BACKUP="N"                                      # Backup Uncompress 
               ;;               
        esac                                                            # End of case
    done                                                                # End of while
    return 
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
