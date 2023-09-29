#! /usr/bin/env bash 
# --------------------------------------------------------------------------------------------------
# Title:        sadm_backup.sh
# Author:       Jacques Duplessis
# Date:         2015-08-28 
# Updated:      2021-03-29 
# Tag:          man sadm_backup 
# Category:     backup 
# Description:
# Backup files and directories are specified in the backup list file ${SADMIN}/cfg/backup_list.txt.
# Files & directories specified in the exclude list ${SADMIN}/cfg/backup_exclude.txt are excluded.
# Backup is compress by default, unless you specify not to (-n).
# Destination of the backup (NFS Server & Directory) is specified within the SADMIN configuration
# file ($SADMIN/cfg/sadmin.cfg) with the fields 'SADM_BACKUP_NFS_SERVER' and 
# 'SADM_BACKUP_NFS_MOUNT_POINT'.
# Only the number of copies specified in the backup section of SADMIN configuration
# file ($SADMIN/cfg/sadmin.cfg) will be kept, old backup are deleted at the end of each backup.
# Should be run Daily (Recommended).
#
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
#
# 2017_01_02 backup V1.2 Exclude *.iso added to tar command
# 2017_10_02 backup V2.1 Added /wsadmin in the backup
# 2017_12_27 backup V2.2 Adapt to new Library and Take NFS Server From SADMIN Config file Now
# 2018_01_02 backup V2.3 Small Corrections and added comments
# 2018_02_09 backup V2.4 Begin Testing new version with daily,weekly,monthly and yearly backup
# 2018_02_09 backup V2.5 First Production Version
# 2018_02_10 backup V2.6 Switch to bash instead of sh (Problem with Dash and array)
# 2018_02_10 backup V2.7 Create Backup Link in the latest directory
# 2018_02_10 backup V2.8 Add Exclude File Variable
# 2018_02_11 backup V2.9 Fix Bug Creating Unnecessary Server Directory on local mount point
# 2018_02_14 backup V3.0 Removal of old backup according to policy are now working
# 2018_02_16 backup V3.1 Minor Esthetics corrections
# 2018_02_18 backup V3.2 If tar exit with error 1, consider that it's not an error (nmon,log,rch,...).
# 2018_05_15 backup V3.3 Added LOG_HEADER, LOG_FOOTER, USE_RCH Variable to add flexibility to log control
# 2018_05_25 backup V3.4 Fix Problem with Archive Directory Name
# 2018_05_28 backup V3.5 Group Backup by Date in each server directories - Easier to Search and Manage.
# 2018_05_28 backup V3.6 Backup Parameters now come from sadmin.cfg, no need to modify script anymore.
# 2018_05_31 backup V3.7 List of files and directories to backup and to exclude.
# 2018_06_02 backup V3.8 Add -v switch to display script version & Some minor corrections
# 2018_06_18 backup v3.9 Backup compression is ON by default now (-n if don't want compression)
# 2018_09_16 backup v3.10 Insert Alert Group Default
# 2018_10_02 backup v3.11 Advise User & Trap Error when mounting NFS Mount point.
# 2019_01_10 backup v3.12 Changed: Name of Backup List and Exclude file can be change.
# 2019_01_11 backup v3.13 Fix C/R problem after using the Web UI to change backup & exclude list.
# 2019_02_01 backup v3.14 Reduce Output when no debug is activated.
# 2019_07_18 backup v3.15 Modified to backup MacOS system onto a NFS drive.
# 2020_04_01 backup v3.16 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2020_04_06 backup v3.17 Don't show anymore directories that are skip because they don't exist.
# 2020_04_08 backup v3.18 Fix 'chown' error.
# 2020_04_09 backup v3.19 Minor logging adjustment.
# 2020_04_10 backup v3.20 If backup_list.txt contains $ at beginning of line, it Var. is resolved
# 2020_04_11 backup v3.21 Log output changes.
# 2020_05_18 backup v3.22 Backup Dir. Structure changed, now group by System instead of backup type
# 2020_05_24 backup v3.23 Automatically move backup from old dir. structure to the new.
# 2020_07_13 backup v3.24 New System Main Backup Directory was not created with right permission.
# 2020_09_23 backup v3.25 Modification to log recording.
# 2020_10_26 backup v3.26 Suppress 'chmod' error message on backup directory.
# 2021_01_05 backup v3.27 List backup directory content at the end of backup.
# 2021_03_29 backup v3.28 Exclude list is shown before each backup (tar) begin.
# 2021_03_29 backup v3.29 Log of each backup (tar) recorded and place in backup directory.
# 2021_05_24 backup v3.30 Optimize code & update command line options [-v] & [-h]. 
# 2021_06_04 backup v3.31 Fix sporadic problem with exclude list. 
# 2021_06_05 backup v3.32 Include backup & system information in each backup log.
# 2021_05_14 backup v3.33 Now the log include the size of each day of backup.
# 2022_08_14 backup v3.34 Error message written to log and also to error log.
# 2022_08_17 backup v3.35 Include new SADMIN section 1.52
# 2022_09_04 backup v3.36 False error message was written to error log.
# 2022_09_23 backup v3.37 Fix problem mounting NFS on newer version of MacOS.
# 2022_10_30 backup v3.38 After each backup show, the backup size in the log.
# 2022_11_11 backup v3.39 Add size of current & previous backup at end of log.
# 2022_11_16 backup v3.40 Depreciate use of environment variable in backup or exclude list.
# 2023_01_06 backup v3.41 Add cmdline '-w' to suppress warning (dir. not exist) on output.
# 2023_01_06 backup v3.42 Fix problem with format of 'stat' command on MacOS.
# 2023_03_26 backup v3.43 Write current, previous and host total backup size in log for reference.
# 2023_04_10 backup v3.44 Fix backup calculating total size occupied by host.
# 2023_04_11 backup v3.45 Previous & Total backup size wasn't always right & added more info in log.
#@2023_09_13 backup v3.46 More info in log, backup size and cleaning improvement.
#===================================================================================================
trap 'sadm_stop 1; exit 1' 2                                            # INTERCEPT The Control-C
#set -x




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.55
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]     # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='3.46'                                     # Script version number
export SADM_PDESC="Backup files and directories specified in the backup list file."
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# ---------------------------------------------------------------------------------------




# --------------------------------------------------------------------------------------------------
#                               Script environment variables
# --------------------------------------------------------------------------------------------------
export TOTAL_ERROR=0                                                    # Total Backup Error
export CUR_DAY_NUM=`date +"%u"`                                         # Current Day in Week 1=Mon
export CUR_DATE_NUM=`date +"%d"`                                        # Current Date Nb. in Month
export CUR_MTH_NUM=`date +"%m"`                                         # Current Month Number
export CUR_DATE=`date "+%C%y_%m_%d"`                                    # Date Format 2018_05_27
if [ "$SADM_OS_TYPE" = "DARWIN" ]                                       # If on MacOS
    then export LOCAL_MOUNT="/tmp/nfs1"                                 # NFS Mount Point for MacOS
    else export LOCAL_MOUNT="/mnt/backup"                               # NFS Mount Point for Linux
fi    
export TODAY_ROOT_DIR=""                                                # Will be filled by Script
export BACKUP_DIR=""                                                    # Will be Final Backup Dir.

# Active Backup File List and Initial File Backup List are defined in SADM Library (sadmlib_std.sh)
# They can be overwritten here.
# export SADM_BACKUP_LIST="${SADMIN}/cfg/backup_list.txt"               # Active Backup List
# export SADM_BACKUP_LIST_INIT="${SADMIN}/cfg/.backup_list.txt"         # Initial Backup List
#
# Active Backup Exclude List and Initial Exclude List File defined in SADM Library (sadmlib_std.sh)
# They can be overwritten here.
#export SADM_BACKUP_EXCLUDE="${SADMIN}/cfg/backup_exclude.txt"          # Active Backup Exclude List
#export SADM_BACKUP_EXCLUDE_INIT="${SADMIN}/cfg/.backup_exclude.txt"    # Initial Backup Excl. List

# The Backup Information are taken from SADMIN Configuration file ($SADMIN/cfg/sadmin.cfg)
# (Example below)
# $SADM_BACKUP_NFS_SERVER          NFS Backup IP or Server Name        : .batnas.maison.ca.
# $SADM_BACKUP_NFS_MOUNT_POINT     NFS Backup Mount Point              : ./volume1/backup_linux.
# $SADM_DAILY_BACKUP_TO_KEEP       Nb. of Daily Backup to keep         : .4. ..
# $SADM_WEEKLY_BACKUP_TO_KEEP      Nb. of Weekly Backup to keep        : .4.
# $SADM_MONTHLY_BACKUP_TO_KEEP     Nb. of Monthly Backup to keep       : .4.
# $SADM_YEARLY_BACKUP_TO_KEEP      Nb. of Yearly Backup to keep        : .2.
# $SADM_WEEKLY_BACKUP_DAY          Weekly Backup Day (1=Mon,...,7=Sun) : .5.
# $SADM_MONTHLY_BACKUP_DATE        Monthly Backup Date (1-28)          : .1.
# $SADM_YEARLY_BACKUP_MONTH        Month to take Yearly Backup (1-12)  : .12.
# $SADM_YEARLY_BACKUP_DATE         Date to do Yearly Backup(1-DayInMth): .31.

# Backup Directories for current backup
export DAILY_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}/daily"                # Dir. For Daily Backup
export WEEKLY_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}/weekly"              # Dir. For Weekly Backup
export MONTHLY_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}/monthly"            # Dir. For Monthly Backup
export YEARLY_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}/yearly"              # Dir. For Yearly Backup
export LATEST_DIR="${LOCAL_MOUNT}/${SADM_HOSTNAME}/latest"              # Latest Backup Directory
export BACKUP_TYPE=""                                                   # [D]ay [W]eek [M]th [Y]ear

# Days and month name used to display inform to user before beginning the backup
WEEKDAY=("index0" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
MTH_NAME=("index0" "January" "February" "March" "April" "May" "June" "July" "August" "September"
        "October" "November" "December")


#
# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\n\t${BOLD}${YELLOW}-d${NORMAL} Set Debug (verbose) Level [0-9]"
    printf "\n\t${BOLD}${YELLOW}-h${NORMAL} Display this help message"
    printf "\n\t${BOLD}${YELLOW}-n${NORMAL} Backup with NO compression (default compress)"
    printf "\n\t${BOLD}${YELLOW}-v${NORMAL} Show script version info"
    printf "\n\t${BOLD}${YELLOW}-w${NORMAL} Don't show warning (dir. not exist)" 
    printf "\n\n" 
}


#===================================================================================================
# Check id Backup Directories structure exist, if not create them.
# Remove Previous backup link in the latest directory
# Make sure we have everything needed to start and succeed the backup
#===================================================================================================
backup_setup()
{
    sadm_write_log " "
    sadm_write_log "Setup Backup Environment ..."                       # Advise User were Starting

    # Do Daily Backup Directory Exist
    if [ ! -d "${DAILY_DIR}" ]                                          # Daily Backup Dir. Exist ?
        then sadm_write_log "Making Daily backup directory $DAILY_DIR"  # Show user what were doing
             mkdir -p $DAILY_DIR                                        # Create Directory
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] mkdir $DAILY_DIR" ; return 1 ; fi
             chmod 775 $DAILY_DIR                                       # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] chmod 775 $DAILY_DIR " ; return 1 ;fi
    fi

    # Do Weekly Backup Directory Exist
    if [ ! -d "${WEEKLY_DIR}" ]                                         # Daily Backup Dir. Exist ?
        then sadm_write_log "Making weekly backup directory $WEEKLY_DIR" # Show what were doing
             mkdir -p $WEEKLY_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] mkdir $WEEKLY_DIR" ; return 1 ; fi
             chmod 775 $WEEKLY_DIR                                      # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] chmod 775 $WEEKLY_DIR" ; return 1 ;fi
    fi

    # Do Monthly Backup Directory Exist
    if [ ! -d "${MONTHLY_DIR}" ]                                        # Monthly Backup Dir. Exist?
        then sadm_write_log "Making Monthly backup directory $MONTHLY_DIR" # Show what were doing
             mkdir -p $MONTHLY_DIR                                      # Create Directory
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] mkdir $MONTHLY_DIR" ; return 1 ; fi
             chmod 775 $MONTHLY_DIR                                     # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] chmod 775 $MONTHLY_DIR " ; return 1 ;fi
    fi

    # Do Yearly Backup Directory Exist
    if [ ! -d "${YEARLY_DIR}" ]                                         # Yearly Backup Dir. Exist?
        then sadm_write_log "Making Yearly backup directory $YEARLY_DIR" # Show user what were doing
             mkdir -p $YEARLY_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] mkdir $YEARLY_DIR" ; return 1 ; fi
             chmod 775 $YEARLY_DIR                                      # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] chmod 775 $YEARLY_DIR" ; return 1 ;fi
             #chown ${SADM_USER}:${SADM_GROUP} $YEARLY_DIR               # Assign it SADM USer&Group
             #if [ $? -ne 0 ]
             #   then sadm_write_err "[ ERROR ] chown ${SADM_USER}:${SADM_GROUP} $YEARLY_DIR \n"
             #        return 1
             #fi
    fi

    # Do Latest Backup Directory Exist
    if [ ! -d "${LATEST_DIR}" ]                                         # Latest Backup Dir Exist?
        then sadm_write_log "Making latest backup directory $LATEST_DIR" # Show what were doing
             mkdir -p $LATEST_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] mkdir $LATEST" ; return 1 ; fi
             chmod 775 $LATEST_DIR                                      # R/W to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] chmod 775 $LATEST_DIR" ; return 1 ;fi
    fi

    # Remove previous backup link in the latest directory
    sadm_write "Removing previous backup links in $LATEST_DIR \n"
    rm -f $LATEST_DIR/20* > /dev/null 2>&1

    # Determine the root backup for today (Daily,Weekly,Monthly or Yearly) 
    TODAY_ROOT_DIR="${DAILY_DIR}"                                       # Default goes in Daily Dir.
    BACKUP_TYPE="D"                                                     # Default is a [D]ay Backup
    LINK_DIR="../daily/${CUR_DATE}"                                     # Latest Backup Link Dir.
    if [ "${CUR_DAY_NUM}" -eq "$SADM_WEEKLY_BACKUP_DAY" ]               # It's the Weekly Backup Day
        then TODAY_ROOT_DIR="${WEEKLY_DIR}"                             # Will be Weekly Backup Dir.
             LINK_DIR="../../weekly/${CUR_DATE}"                        # Latest Backup Link Dir.
             BACKUP_TYPE="W"                                            # It is a [W]eekly Backup
    fi
    if [ "$CUR_DATE_NUM" -eq "$SADM_MONTHLY_BACKUP_DATE" ]              # It's Monthly Backup Date ?
        then TODAY_ROOT_DIR="${MONTHLY_DIR}"                            # Will be Monthly Backup Dir
             LINK_DIR="../monthly/${CUR_DATE}"                          # Latest Backup Link Dir.
             BACKUP_TYPE="M"                                            # It is a [M]onthly Backup
    fi
    if [ "$CUR_DATE_NUM" -eq "$SADM_YEARLY_BACKUP_DATE" ]               # It's Year Backup Date ?
        then if [ "$CUR_MTH_NUM" -eq "$SADM_YEARLY_BACKUP_MONTH" ]      # And It's Year Backup Mth ?
                then TODAY_ROOT_DIR="${YEARLY_DIR}"                     # Will be Yearly Backup Dir
                     LINK_DIR="../yearly/${CUR_DATE}"                   # Latest Backup Link Dir.
                     BACKUP_TYPE="Y"                                    # It is a [Y]early Backup

             fi
    fi

    # Make sure the Server Backup Directory With Today's Date exist on NFS Drive -------------------
    BACKUP_DIR="${TODAY_ROOT_DIR}/${CUR_DATE}"                          # Set Today Backup Directory
    if [ ! -d ${BACKUP_DIR} ]                                           # Check if Server Dir Exist
        then sadm_write_log "Making today backup directory $BACKUP_DIR"
             mkdir ${BACKUP_DIR}                                        # If Not Create it
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_write_err "[ ERROR ] Creating directory ${BACKUP_DIR}"
                     sadm_write_err "On the NFS server ${SADM_BACKUP_NFS_SERVER}"
                     return 1                                           # End Function with error
             fi
             #chown ${SADM_USER}:${SADM_GROUP} ${BACKUP_DIR}             # Assign it SADM USer&Group
             chmod 775 ${BACKUP_DIR}                                    # Assign Protection
    fi

    # Make Sure backup file list exist.
    if [ ! -f "$SADM_BACKUP_LIST" ]
        then if [ -f "$SADM_BACKUP_LIST_INIT" ]                         # If Def. Backup List Exist
                then sadm_write_log "Backup File List ($SADM_BACKUP_LIST) doesn't exist."
                     sadm_write_log "Using Default Backup List ($SADM_BACKUP_LIST_INIT) file."
                     cp $SADM_BACKUP_LIST_INIT $SADM_BACKUP_LIST >>$SADM_LOG 2>&1
                else sadm_write_log "No Backup List File ($SADM_BACKUP_LIST) or Default ($SADM_BACKUP_LIST_INIT)."
                     sadm_write_log "Aborting Backup"
                     sadm_write_log "Put Dir & files to backup in $SADM_BACKUP_LIST and retry"
                     return 1                                           # Return Error to Caller
             fi
    fi

    # Make Sure backup exclude list file exist.
    if [ ! -f "$SADM_BACKUP_EXCLUDE" ]
        then if [ -f "$SADM_BACKUP_EXCLUDE_INIT" ]                      # If Def. Backup List Exist
                then sadm_write_log "Backup Exclude List File ($SADM_BACKUP_EXCLUDE) doesn't exist."
                     sadm_write_log "Using Default Backup Exclude List ($SADM_BACKUP_EXCLUDE_INIT) file."
                     cp $SADM_BACKUP_EXCLUDE_INIT $SADM_BACKUP_EXCLUDE >>$SADM_LOG 2>&1
                else sadm_write_log "No Backup exclude list ($SADM_BACKUP_EXCLUDE) or default ($SADM_BACKUP_EXCLUDE_INIT)."
                     sadm_write_log "Aborting Backup"
                     sadm_write_log "Put Dir & files to exclude in $SADM_BACKUP_EXCLUDE and retry."
                     return 1                                           # Return Error to Caller
             fi
    fi

    # Show Backup Preferences
    sadm_write_log " "
    case $BACKUP_TYPE in
        D) sadm_write_log "Today `date` we are starting a [Daily] backup ..." 
           ;;
        W) sadm_write_log "Today `date` we are starting a [Weekly] backup ..."
           ;;
        M) sadm_write_log "Today `date` we are starting a [Monthly] backup ..."
           ;;
        Y) sadm_write_log "Today `date` we are starting a [Yearly] backup ..."
           ;;
    esac 
    sadm_write_log " " 
    sadm_write_log "Base on SADMIN configuration file, you have chosen to:"
    #if [ "$COMPRESS" = 'ON' ]
    #    then sadm_write " - Compress the backup file\n"
    #    else sadm_write " - Not compress the backup\n"
    #fi
    sadm_write_log " - Keep $SADM_DAILY_BACKUP_TO_KEEP daily backups"
    sadm_write_log " - Keep $SADM_WEEKLY_BACKUP_TO_KEEP weekly backups"
    sadm_write_log " - Keep $SADM_MONTHLY_BACKUP_TO_KEEP monthly backups"
    sadm_write_log " - Keep $SADM_YEARLY_BACKUP_TO_KEEP yearly backups"
    sadm_write_log " - Do the weekly backup on ${WEEKDAY[$SADM_WEEKLY_BACKUP_DAY]}"
    sadm_write_log " - Do the monthly backup on the $SADM_MONTHLY_BACKUP_DATE of every month"
    sadm_write_log " - Do the yearly backup on the $SADM_YEARLY_BACKUP_DATE of ${MTH_NAME[$SADM_YEARLY_BACKUP_MONTH]} every year"
    sadm_write_log " - Backup directory is ${BACKUP_DIR}"
    sadm_write_log " - Using backup list file ${SADM_BACKUP_LIST}"
    sadm_write_log " - Using backup exclude list file ${SADM_BACKUP_EXCLUDE}"
    return 0
}


# --------------------------------------------------------------------------------------------------
#   Create Backup Files Main Function - Loop for each file specified in the backup_list.txt file
# --------------------------------------------------------------------------------------------------
create_backup()
{
    CUR_PWD=$(pwd)                                                      # Save Current Working Dir.
    TOTAL_ERROR=0                                                       # Make Sure Variable is at 0

    # Show Backup list content
    sadm_write_log " " 
    sadm_write_log "Content of backup list file ($SADM_BACKUP_LIST)" 
    cat $SADM_BACKUP_LIST | while read ln ; do sadm_write_log "${ln}" ;done 
    sadm_write_log " "

    # Show Backup exclude list 
    sadm_write_log " " 
    sadm_write_log "Content of backup exclude list file ($SADM_BACKUP_EXCLUDE)" 
    cat $SADM_BACKUP_EXCLUDE | while read ln ; do sadm_write_log "${ln}" ;done 
    sadm_write_log " "

    # Read one by one the line of the backup include file
    while read backup_line                                              # Loop Until EOF Backup List
        do
        FC=`echo $backup_line | cut -c1`                                # Get First Char. of Line
        backup_line=`echo $backup_line | tr -d '\r'`                    # Remove EndOfLine CR if any 
        backup_line=`echo $backup_line | sed 's/[[:blank:]]*$//'`       # Remove Blank & Tab if any 
        if [ "$FC" = "#" ] || [ ${#backup_line} -eq 0 ]                 # Line begin with # or Empty
            then continue                                               # Skip, Go read Next Line
        fi  
        
        if [ -d "${backup_line}" ]                                      # If line is a Dir. & Exist
            then sadm_write_log " "
            else if [ -f "$backup_line" ] && [ -r "$backup_line" ]      # If File to Backup Readable
                    then if [ $SADM_DEBUG -gt 2 ] 
                            then sadm_write_log "File to Backup : [${backup_line}]" 
                         fi
                    else if [ "$SHOW_WARNING" = "Y" ] 
                            then sadm_write_log " "
                                 sadm_write_log "${SADM_TEN_DASH}"      # Line of 10 Dash in Log
                                 MESS1="You asked to backup '$backup_line', "
                                 MESS2="but it doesn't exist on ${SADM_HOSTNAME}."
                                 sadm_write_err "[ WARNING ] ${MESS1}${MESS2}" 
                         fi 
                         continue                                       # Go Read Nxt Line to backup
                    fi
        fi

        BASE_NAME=$(echo "$backup_line" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' )
        TIME_STAMP=$(date "+%C%y_%m_%d-%H_%M_%S")                       # Current Date & Time

        # Backup File
        if [ -f "$backup_line" ] && [ -r "$backup_line" ]               # Line is a File & Readable
            then
                sadm_write_log " "
                sadm_write_log "${SADM_TEN_DASH}"                       # Line of 10 Dash in Log
                sadm_write_log "Backup file: [${backup_line}]"          # Show Backup filename                 
                BACK_LOG="${BACKUP_DIR}/${TIME_STAMP}_${BASE_NAME}.log" # Backup log on NAS filename
                echo "# $SADM_PN v$SADM_VER - $SADM_HOSTNAME - $(sadm_capitalize $SADM_OS_NAME) v$SADM_OS_VERSION " >>$BACK_LOG 2>&1
                cd /                                                    # Be sure we are on /
                if [ "$COMPRESS" == "ON" ]                              # If compression ON
                    then BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tgz"     # Final tgz Backup file name
                         echo "# Backup of .$backup_line started at `date`" >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         echo "tar -cvzf ${BACKUP_DIR}/${BACK_FILE} .$backup_line" >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         sadm_write "tar -cvzf ${BACKUP_DIR}/${BACK_FILE} .$backup_line \n"
                         tar -cvzf ${BACKUP_DIR}/${BACK_FILE} .$backup_line >>$BACK_LOG 2>&1
                         RC=$?                                          # Save Return Code
                         echo "Backup ended at $(date) with exit code of $RC"  >>$BACK_LOG 2>&1
                    else BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tar"     # Final tar Backup file name
                         echo "# Backup of .$backup_line started at `date`" >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         echo "tar -cvf ${BACKUP_DIR}/${BACK_FILE} .$backup_line" >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         sadm_write "tar -cvf ${BACKUP_DIR}/${BACK_FILE} .$backup_line \n"
                         tar -cvf ${BACKUP_DIR}/${BACK_FILE} .$backup_line >>$BACK_LOG 2>&1
                         RC=$?                                          # Save Return Code
                         echo "Backup ended at `date` with exit code of $RC"  >>$BACK_LOG 2>&1
                fi
        fi

        # Backup Directory
        if [ -d ${backup_line} ]                                        # Dir to Backup Exist ?
           then sadm_write_log " "                                      # Insert Blank Line
                sadm_write_log "${SADM_TEN_DASH}"                       # Line of 10 Dash in Log
                sadm_write_log "Starting backup of [$backup_line]"      # Show Dir will backup
                cd /                                                    # Make sure we are on /
                sadm_write_log "Initiating backup from `pwd`"           # Print Current Working Dir.

                # Build Backup Exclude list to include Dir. Sockets file (Prevent false error)
                find .$backup_line -type s -print > /tmp/exclude  2>/dev/null  # Sockets in exclude
                while read excl_line                                    # Loop Until EOF Excl. File
                    do
                    FC=$(echo $excl_line | cut -c1)                     # Get First Char. of Line
                    if [ "$FC" = "#" ] || [ ${#excl_line} -eq 0 ]       # Skip Comment or Blank Line
                        then continue                                   # Blank or Comment = NxtLine
                    fi
                    echo "$excl_line" >> /tmp/exclude                   # Add Line to Exclude List
                    done < $SADM_BACKUP_EXCLUDE                         # Read Backup Exclude File

                # Show Exclude list Content under Debug mode 
                if [ $SADM_DEBUG -gt 2 ] 
                    then sadm_write_log " "
                         sadm_write_log "Content of exclude file(s), including socket file(s):" 
                         cat /tmp/exclude| while read ln ;do sadm_write_log "${ln}" ;done 
                         sadm_write_log " "
                fi 

                BACK_LOG="${BACKUP_DIR}/${TIME_STAMP}_${BASE_NAME}.log" 
                echo "# $SADM_PN v$SADM_VER - $SADM_HOSTNAME - $(sadm_capitalize $SADM_OS_NAME) v$SADM_OS_VERSION " >>$BACK_LOG 2>&1
                if [ "$COMPRESS" == "ON" ]
                    then BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tgz"     # Final tgz Backup file name
                         sadm_write "tar -cvzf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .$backup_line\n"
                         echo "# Backup of .$backup_line started at `date`" >>$BACK_LOG 2>&1
                         echo " "  >>$BACK_LOG 2>&1
                         echo "# Exclude list content (/tmp/exclude) :" >>$BACK_LOG 2>&1
                         cat /tmp/exclude >>$BACK_LOG 2>&1
                         echo " "  >>$BACK_LOG 2>&1
                         echo "tar -cvzf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .$backup_line" >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         tar -cvzf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .$backup_line >>$BACK_LOG 2>&1
                         RC=$?                                          # Save Return Code
                         echo "Backup ended at `date` with exit code of $RC"  >>$BACK_LOG 2>&1
                    else BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tar"     # Final tar Backup file name
                         sadm_write "tar -cvf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .$backup_line\n"
                         echo "# Backup of .$backup_line started at `date`" >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         echo "# Exclude list content (/tmp/exclude) :" >>$BACK_LOG 2>&1
                         cat /tmp/exclude >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         echo "tar -cvf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .$backup_line " >>$BACK_LOG 2>&1
                         echo "#"  >>$BACK_LOG 2>&1
                         tar -cvf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .$backup_line >>$BACK_LOG 2>&1
                         RC=$?                                          # Save Return Code
                         echo "Backup ended at `date` with exit code of $RC"  >>$BACK_LOG 2>&1
                fi
        fi

        # Error 1 = File(s) changed while backup running, don't report that as an error.
        if [ $RC -eq 1 ] ; then RC=0 ; fi                               # File Changed while backup
        if [ $RC -ne 0 ]                                                # If Error while Backup
            then MESS="[ ERROR #${RC} ] while creating $BACK_FILE"      # Advise Backup Error
                 sadm_write_err "${MESS}"                               # Advise User - Log Info
                 RC=1                                                   # Make Sure Return Code is 0
            else MESS="[ SUCCESS ] Creating Backup $BACK_FILE"          # Advise Backup Success
                 sadm_write_log "${MESS}"                               # Advise User - Log Info
                 RC=0                                                   # Make Sure Return Code is 0
        fi

        # Show backup tgz file size
        if [ "$SADM_OS_TYPE" = "DARWIN" ] 
            then BSIZE=$(stat -f%z ${BACKUP_DIR}/${BACK_FILE})
            else BSIZE=$(stat --format=%s ${BACKUP_DIR}/${BACK_FILE})
        fi 
        BTOTAL=$(echo "$BSIZE /1024/1024" | bc)                             
        sadm_write_log "Backup size is ${BTOTAL}MB."

        # Create link to backup in the server latest directory
        cd ${LATEST_DIR}
        sadm_write_log "Create link to latest backup of ${backup_line} in ${LATEST_DIR}"
        sadm_write_log "Current directory: `pwd`"                       # Print Current Dir.
        sadm_write_log "ln -s ${LINK_DIR}/${BACK_FILE} ${BACK_FILE}"
        ln -s ${LINK_DIR}/${BACK_FILE} ${BACK_FILE}  >>$SADM_LOG 2>&1   # Run Soft Link Command
        if [ $? -ne 0 ]                                                 # If Error trying to link
            then sadm_write_err "ln -s ${LINK_DIR}/${BACK_FILE} ${BACK_FILE}"
                 sadm_write_err "[ ERROR ] Creating link backup in latest directory."
                 RC=1
            else sadm_write_log "[ SUCCESS ] Creating link."            # Advise User - Log Info
                 RC=0                                                   # Make Sure Return Code is 0
        fi
        TOTAL_ERROR=$(($TOTAL_ERROR+$RC))                               # Total = Cumulate RC Value
        rm -f /tmp/exclude >/dev/null 2>&1                              # Remove socket tmp file
        done < $SADM_BACKUP_LIST                                          # For Loop Read Backup List


    # End of Backup
    cd "$CUR_PWD"                                                       # Restore Previous Cur Dir.
    sadm_write_log " "                                                  # Insert Blank Line
    sadm_write_log "Total error(s) while creating backup: ${TOTAL_ERROR}."
    sadm_write_log "${SADM_TEN_DASH}"                                   # Line of 10 Dash in Log
    sadm_write_log " "                                                  # Insert Blank Line

    # List Backup Directory
    #sadm_write_log " "
    #sadm_write_log "Content of today backup directory (${BACKUP_DIR}):"
    #ls -l ${BACKUP_DIR} | while read wline ; do write_log "$wline"; done
    #sadm_write_log " "

    return $TOTAL_ERROR                                                 # Return Total of Error
}




# --------------------------------------------------------------------------------------------------
#               Keep only the number of backup copies specified in $SADM_DAILY_BACKUP_TO_KEEP
# --------------------------------------------------------------------------------------------------
clean_backup_dir()
{
    TOTAL_ERROR=0                                                       # Reset Total of error
    sadm_write "\n"
    CUR_PWD=$(pwd)                                                       # Save Current Working Dir.

    BTYPE="SADM_DAILY_BACKUP_TO_KEEP"
    BID="Daily"
    BDIR="$DAILY_DIR"
    BKEEP="$SADM_DAILY_BACKUP_TO_KEEP"
    purge_dir "$BTYPE" "$BID" "$BDIR" "$BKEEP" 

    BTYPE="SADM_WEEKLY_BACKUP_TO_KEEP"
    BID="Weekly"
    BDIR="$WEEKLY_DIR"
    BKEEP="$SADM_WEEKLY_BACKUP_TO_KEEP"
    purge_dir "$BTYPE" "$BID" "$BDIR" "$BKEEP" 

    BTYPE="SADM_MONTHLY_BACKUP_TO_KEEP"
    BID="Monthly"
    BDIR="$MONTHLY_DIR"
    BKEEP="$SADM_MONTHLY_BACKUP_TO_KEEP"
    purge_dir "$BTYPE" "$BID" "$BDIR" "$BKEEP" 
    
    BTYPE="SADM_YEARLY_BACKUP_TO_KEEP"
    BID="Yearly"
    BDIR="$YEARLY_DIR"
    BKEEP="$SADM_YEARLY_BACKUP_TO_KEEP"
    purge_dir "$BTYPE" "$BID" "$BDIR" "$BKEEP" 
    
    # Create a list of all directories that begin with "20*" in system backup directory
    # We end up with a file with line like this "16G	./daily/2023_04_09"  (Size and dir. name)
    cd "${LOCAL_MOUNT}/${SADM_HOSTNAME}"
    sadm_write_log "List of all backup directories for $SADM_HOSTNAME in ${LOCAL_MOUNT}/${SADM_HOSTNAME}"
    find . -type d -name "20*" 2>/dev/null -exec du -h {} \; |nl| while read wline ; do sadm_write_log "$wline"; done
   
    # Get the last two backup date and size
    find . -type d -name "20*" 2>/dev/null -exec du -h {} \; > $SADM_TMP_FILE1
    last2date=$(find . -type d -name "20*" 2>/dev/null -exec du -h {} \; |awk -F'/' '{print $3}' |sort |tail -2)
    last_date=$(echo $last2date | awk '{ print $2 }')
    last_size=$(grep "$last_date" $SADM_TMP_FILE1 | awk '{print $1}')
    prev_date=$(echo $last2date | awk '{ print $1 }')
    prev_size=$(grep "$prev_date" $SADM_TMP_FILE1 | awk '{print $1}')

    # Create Line that is used by 'Daily Backup Status' web page to show size of last 2 backup.
    sadm_write_log " "
    sadm_write_log "${SADM_TEN_DASH}"                                   # Line of 10 Dash in Log
    total_size=$(du -hs . | awk '{print $1}')
    sadm_write_log "current backup size = $last_size"
    sadm_write_log "previous backup size = $prev_size"
    sadm_write_log "Total backup size = $total_size"

    cd "$CUR_PWD"
    return 0
} 





# --------------------------------------------------------------------------------------------------
# Keep only the number of backup copies specified in $SADM_DAILY_BACKUP_TO_KEEP
#    BTYPE="SADM_YEARLY_BACKUP_TO_KEEP"
#    BID="Yearly "
#    BDIR="$YEARLY_DIR"
#    BKEEP=$SADM_YEARLY_BACKUP_TO_KEEP
#    purge_dir "$BTYPE" "$BID" "$BDIR" "BKEEP" 
# --------------------------------------------------------------------------------------------------
purge_dir()
{
    BTYPE="$1"                                                          # Nb Copy var. in sadmin.cfg
    BID="$2"                                                            # Daily,Weekly,Monthly,Yearly
    BDIR="$3"                                                           # Directory where backup are
    BKEEP="$4"                                                          # Nb copies a preserver
  
    cd "$BDIR"                                                          # Go in Backup Directory
    if [ $? -ne 0 ] ; then sadm_write_err "Can't change to directory $BDIR - No purge" ;return 1 ;fi
    
    sadm_write_log "List of '$BID' backup currently on disk:"
    du -h . | grep -v '@eaDir' | nl | while read ln ;do sadm_write_log "${ln}" ;done
    sadm_write_log " "
    sadm_write_log "For '$BID' backup, you asked to keep '$BKEEP' copies." 
    sadm_write_log "You can modify this value by changing '$BTYPE' value in \$SADMIN/cfg/sadmin.cfg."

    backup_count=$(ls -1| grep -v '@eaDir' | awk -F'-' '{ print $1 }' |sort -r |uniq |wc -l)
    b2del=$(($backup_count - $BKEEP))                                     # Calc. Nb. Days to remove
    #sadm_write_log " "
    sadm_write_log "You now have currently $backup_count copies of $BID backup(s)."

    # If current number of backup days on disk is greater than nb. of backup to keep, then cleanup.
    if [ "$backup_count" -gt "$BKEEP" ]
        then sadm_write_log "So we need to delete $b2del copy of '$BID' backup."
             ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |tail -$b2del > $SADM_TMP_FILE3
             cat $SADM_TMP_FILE3 |while read ln ;do sadm_write_log "Deleting ${ln}" ;rm -fr ${ln}* ;done
             sadm_write_log " "
             sadm_write_log "List of '$BID' backup currently on disk after cleanup."
             du -h . | grep -v '@eaDir' | while read ln ;do sadm_write "${ln}\n" ;done
        else sadm_write_log "No clean up needed"
    fi
    sadm_write_log " "
    sadm_write_log "${SADM_TEN_DASH}"                                   # Line of 10 Dash in Log
    sadm_write_log " "                                                  # Insert Blank Line
    return 0                                                            # Return to caller
}


# ==================================================================================================
#                Mount the NFS Directory where all the backup files will be stored
# ==================================================================================================
mount_nfs()
{
    # Make sur the Local Mount Point Exist ---------------------------------------------------------
    if [ ! -d ${LOCAL_MOUNT} ]                                          # Mount Point doesn't exist
        then sadm_write_log "Create local mount point ${LOCAL_MOUNT}"   # Advise user we create Dir.
             mkdir ${LOCAL_MOUNT}                                       # Create if not exist
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_write_err "[ ERROR ] Failed to create directory ${LOCAL_MOUNT}, process aborted."
                return 1                                                # End Function with error
             fi
             chmod 775 ${LOCAL_MOUNT}                                   # Change Protection
    fi

    # Mount the NFS Drive - Where the Backup file will reside -----------------------------------------
    REM_MOUNT="${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT}"
    sadm_write "Mounting NFS Drive on ${SADM_BACKUP_NFS_SERVER}.\n"     # Show NFS Server Name
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted
    if [ "$SADM_OS_TYPE" = "DARWIN" ]                                   # If on MacOS
        then sadm_write_log "mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT}"
             mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
        else sadm_write_log "mount ${REM_MOUNT} ${LOCAL_MOUNT}"         # If on Linux/Aix
             mount ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1         # Mount NFS Drive
    fi
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_write_err "[ ERROR ] Mount NFS Failed - Process Aborted" # Error - Advise User
             return 1                                                   # End Function with error
        else sadm_write_log "[ SUCCESS ] NFS Mount Succeeded."          # NFS Mount Succeeded Msg
    fi

    # Create System Main Directory
    F="${LOCAL_MOUNT}/${SADM_HOSTNAME}"
    if [ ! -d ${F} ]                                                    # Check if Server Dir Exist
        then sadm_write_log "Making System main backup directory $F"
             mkdir ${F}                                                 # If Not Create it
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_write_log "[ ERROR ] Creating Main System Backup Directory ${F}"
                     return 1                                           # End Function with error
             fi
            chmod 775 ${F}                                              # Assign Permission
    fi

    return 0
}


# ==================================================================================================
#                                Unmount NFS Backup Directory
# ==================================================================================================
umount_nfs()
{
    sadm_write_log " "
    sadm_write_log "Unmounting NFS mount directory ${LOCAL_MOUNT}"
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_write_err "[ ERROR ] Unmounting NFS Directory $LOCAL_MOUNT"   
             return 1                                                   # End Function with error
        else sadm_write_log "[ SUCCESS ] Unmounting NFS Directory $LOCAL_MOUNT" 
    fi
    return 0
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    COMPRESS="ON"                                                       # Backup Compression Default
    SHOW_WARNING="N"                                                    # Don't show warning
    while getopts "d:hnv" opt ; do                                      # Loop to process Switch
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
            n) COMPRESS="OFF"                                           # No Compress backup
               ;;               
            w) SHOW_WARNING="Y"                                         # Show warning 
               ;;               
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}


#===================================================================================================
# MAIN CODE START HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    mount_nfs                                                           # Mount NFS Dir.
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    backup_setup                                                        # Create Necessary Dir.
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    create_backup                                                       # Create TGZ of Selected Dir
    SADM_EXIT_CODE=$?                                                   # Save Backup Result Code
    clean_backup_dir                                                    # Delete Old Backup
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Cleaning up
    umount_nfs                                                          # Unmounting NFS Drive
    sadm_stop $SADM_EXIT_CODE                                           # Close & Trim rch,log,pid
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
