#! /usr/bin/env bash 
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Backup & optionally compress directories or files specified in the backup list file
#               ($SADMIN/cfg/backup_list.txt) as tar files (tar or tgz)
#   Date:       28 August 2015
#   Synopsis:   This script is used to create Backups files of all directories specified in the
#               backup list file ($SADMIN/cfg/backup_list.txt) to the NFS server specified
#               in $SADMIN/cfg/sadmin.cfg .
#               Only the number of copies specified in the backup section of SADMIN configuration
#               file ($SADMIN/cfg/sadmin.cfg) will be kept, old backup are deleted at the end of
#               each backup.
#               Should be run Daily (Recommended) .
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# 2017_01_02  V1.2 Exclude *.iso added to tar command
# 2017_10_02  V2.1 Added /wsadmin in the backup
# 2017_12_27  V2.2 Adapt to new Library and Take NFS Server From SADMIN Config file Now
# 2018_01_02  V2.3 Small Corrections and added comments
# 2018_02_09  V2.4 Begin Testing new version with daily,weekly,monthly and yearly backup
# 2018_02_09  V2.5 First Production Version
# 2018_02_10  V2.6 Switch to bash instead of sh (Problem with Dash and array)
#             V2.7 Create Backup Link in the latest directory
#             V2.8 Add Exclude File Variable
# 2018_02_11  V2.9 Fix Bug Creating Unnecessary Server Directory on local mount point
# 2018_02_14  V3.0 Removal of old backup according to policy are now working
# 2018_02_16  V3.1 Minor Esthetics corrections
# 2018_02_18  V3.2 If tar exit with error 1, consider that it's not an error (nmon,log,rch,...).
#                  This exit code means that some files were changed while being archived and so
#                  the resulting archive does not contain the exact copy of the file set.
# 2018_05_15  V3.3 Added LOG_HEADER, LOG_FOOTER, USE_RCH Variable to add flexibility to log control
# 2018_05_25  V3.4 Fix Problem with Archive Directory Name
# 2018_05_28  V3.5 Group Backup by Date in each server directories - Easier to Search and Manage.
# 2018_05_28  V3.6 Backup Parameters now come from sadmin.cfg, no need to modify script anymore.
# 2018_05_31  V3.7 List of files and directories to backup and to exclude from it come from a
#                  user defined files respectively name 'backup_list.txt' and 'backup_exclude.txt'
#                  in $SADMIN/cfg Directory.
# 2018_06_02  V3.8 Add -v switch to display script version & Some minor corrections
# 2018_06_18  v3.9 Backup compression is ON by default now (-n if don't want compression)
# 2018_09_16  v3.10 Insert Alert Group Default
# 2018_10_02  v3.11 Advise User & Trap Error when mounting NFS Mount point.
# 2019_01_10 Changed: v3.12 Changed: Name of Backup List and Exclude file can be change.
# 2019_01_11 Fixes: v3.13 Fix C/R problem after using the Web UI to change backup & exclude list.
# 2019_02_01 Improve: v3.14 Reduce Output when no debug is activated.
#@2019_07_18 Improve: v3.15 Modified to backup MacOS system onto a NFS drive.
#@2020_04_01 Update: v3.16 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
#===================================================================================================
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x



#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "\n'SADMIN' Environment variable was temporarily set to ${SADMIN}."
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='3.16'                              # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=35                          # When script end Trim rch file to 35 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================








# --------------------------------------------------------------------------------------------------
#                               Script environment variables
# --------------------------------------------------------------------------------------------------
HOSTNAME=`hostname -s`              ; export HOSTNAME                   # Current Host name
TOTAL_ERROR=0                       ; export TOTAL_ERROR                # Total Backup Error
CUR_DAY_NUM=`date +"%u"`            ; export CUR_DAY_NUM                # Current Day in Week 1=Mon
CUR_DATE_NUM=`date +"%d"`           ; export CUR_DATE_NUM               # Current Date Nb. in Month
CUR_MTH_NUM=`date +"%m"`            ; export CUR_MTH_NUM                # Current Month Number
CUR_DATE=`date "+%C%y_%m_%d"`       ; export CUR_DATE                   # Date Format 2018_05_27
if [ "$SADM_OS_TYPE" = "DARWIN" ]                                       # If on MacOS
    then LOCAL_MOUNT="/preserve/nfs"  ; export LOCAL_MOUNT              # NFS Mount Point for OSX
    else LOCAL_MOUNT="/mnt/backup"    ; export LOCAL_MOUNT              # NFS Mount Point for Linux
fi    
ARCHIVE_DIR=""                      ; export ARCHIVE_DIR                # Will be filled by Script
BACKUP_DIR=""                       ; export BACKUP_DIR                 # Will be Final Backup Dir.

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

# Root Backup Directories
DDIR="${LOCAL_MOUNT}/daily"             ; export DDIR                   # Root Dir. Daily Backup
WDIR="${LOCAL_MOUNT}/weekly"            ; export WDIR                   # Root Dir. Weekly Backup
MDIR="${LOCAL_MOUNT}/monthly"           ; export MDIR                   # Root Dir. Monthly Backup
YDIR="${LOCAL_MOUNT}/yearly"            ; export YDIR                   # Root Dir. Yearly Backup
LDIR="${LOCAL_MOUNT}/latest"            ; export LDIR                   # Root Dir. Latest Backup

# Backup Directories for current backup
DAILY_DIR="${DDIR}/${HOSTNAME}"         ; export DAILY_DIR              # Dir. For Daily Backup
WEEKLY_DIR="${WDIR}/${HOSTNAME}"        ; export WEEKLY_DIR             # Dir. For Weekly Backup
MONTHLY_DIR="${MDIR}/${HOSTNAME}"       ; export MONTHLY_DIR            # Dir. For Monthly Backup
YEARLY_DIR="${YDIR}/${HOSTNAME}"        ; export YEARLY_DIR             # Dir. For Yearly Backup
LATEST_DIR="${LDIR}/${HOSTNAME}"        ; export LATEST_DIR             # Latest Backup Directory

# Days and month name used to display inform to user before beginning the backup
WEEKDAY=("index0" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
MTH_NAME=("index0" "January" "February" "March" "April" "May" "June" "July" "August" "September"
        "October" "November" "December")


# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-n   (Backup with NO compression)"
    printf "\n\n"
}


#===================================================================================================
#                 Make sure we have everything needed to start and succeed the backup
#===================================================================================================
backup_setup()
{
    sadm_write "\n----------\nSetup Backup Environment ...\n"           # Advise User were Starting

    # Daily Root Backup Directory
    if [ ! -d "${DDIR}" ]                                               # Daily Backup Dir. Exist ?
        then sadm_write "Making Daily backup directory ${DDIR}.\n"      # Show user what were doing
             mkdir -p $DDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir ${DDIR}.\n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $DDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $DDIR \n"
                     return 1
             fi
             chmod 775 $DDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $DDIR \n" ; return 1 ;fi
    fi

    # Daily Backup Directory
    if [ ! -d "${DAILY_DIR}" ]                                          # Daily Backup Dir. Exist ?
        then sadm_write "Making Daily backup directory $DAILY_DIR \n"   # Show user what were doing
             mkdir -p $DAILY_DIR                                        # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $DAILY_DIR \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $DAILY_DIR                # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $DAILY_DIR \n"
                     return 1
             fi
             chmod 775 $DAILY_DIR                                       # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $DAILY_DIR \n" ; return 1 ;fi
    fi

    # Weekly Root Backup Directory
    if [ ! -d "${WDIR}" ]                                               # Daily Backup Dir. Exist ?
        then sadm_write "Making Weekly backup directory $WDIR \n"       # Show user what were doing
             mkdir -p $WDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $WDIR \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $WDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $WDIR \n"
                     return 1
             fi
             chmod 775 $WDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $WDIR \n" ; return 1 ;fi
    fi

    # Weekly Backup Directory
    if [ ! -d "${WEEKLY_DIR}" ]                                         # Daily Backup Dir. Exist ?
        then sadm_write "Making Weekly backup directory $WEEKLY_DIR \n" # Show user what were doing
             mkdir -p $WEEKLY_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $WEEKLY_DIR \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $WEEKLY_DIR               # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $WEEKLY_DIR \n"
                     return 1
             fi
             chmod 775 $WEEKLY_DIR                                      # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $WEEKLY_DIR \n" ; return 1 ;fi
    fi

    # Monthly Root Backup Directory
    if [ ! -d "${MDIR}" ]                                               # Monthly Backup Dir. Exist?
        then sadm_write "Making Monthly backup directory $MDIR \n"      # Show user what were doing
             mkdir -p $MDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $MDIR \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $MDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $MDIR \n"
                     return 1
             fi
             chmod 775 $MDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $MDIR \n" ; return 1 ;fi
    fi

    # Monthly Backup Directory
    if [ ! -d "${MONTHLY_DIR}" ]                                        # Monthly Backup Dir. Exist?
        then sadm_write "Making Monthly backup directory $MONTHLY_DIR \n" # Show user what were doing
             mkdir -p $MONTHLY_DIR                                      # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $MONTHLY_DIR \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $MONTHLY_DIR              # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $MONTHLY_DIR \n"
                     return 1
             fi
             chmod 775 $MONTHLY_DIR                                     # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $MONTHLY_DIR \n" ; return 1 ;fi
    fi

    # Yearly Root Backup Directory
    if [ ! -d "${YDIR}" ]                                               # Yearly Backup Dir. Exist?
        then sadm_write "Making Yearly backup directory $YDIR \n"       # Show user what were doing
             mkdir -p $YDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $YDIR \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $YDIR                     # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $YDIR \n"
                     return 1
             fi
             chmod 775 $YDIR                                            # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $YDIR \n" ; return 1 ;fi
    fi

    # Yearly Backup Directory
    if [ ! -d "${YEARLY_DIR}" ]                                         # Yearly Backup Dir. Exist?
        then sadm_write "Making Yearly backup directory $YEARLY_DIR \n" # Show user what were doing
             mkdir -p $YEARLY_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $YEARLY_DIR \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $YEARLY_DIR               # Assign it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $YEARLY_DIR \n"
                     return 1
             fi
             chmod 775 $YEARLY_DIR                                      # Read/Write to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $YEARLY_DIR \n" ; return 1 ;fi
    fi

    # Latest Root Backup Directory
    if [ ! -d "${LDIR}" ]                                               # Latest Backup Dir Exist?
        then sadm_write "Making latest backup directory $LDIR \n"       # Show user what were doing
             mkdir -p $LDIR                                             # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $LATEST \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $LDIR                     # Give it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $LDIR \n"
                     return 1
             fi
             chmod 775 $LDIR                                            # R/W to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $LDIR \n" ; return 1 ;fi
    fi

    # Latest Backup Directory
    if [ ! -d "${LATEST_DIR}" ]                                         # Latest Backup Dir Exist?
        then sadm_write "Making latest backup directory $LATEST_DIR \n" # Show user what were doing
             mkdir -p $LATEST_DIR                                       # Create Directory
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] mkdir $LATEST \n" ; return 1 ; fi
             chown ${SADM_USER}:${SADM_GROUP} $LATEST_DIR               # Give it SADM USer&Group
             if [ $? -ne 0 ]
                then sadm_write "[ERROR] chown ${SADM_USER}:${SADM_GROUP} $LATEST_DIR \n"
                     return 1
             fi
             chmod 775 $LATEST_DIR                                      # R/W to SADM Usr/Grp
             if [ $? -ne 0 ] ; then sadm_write "[ERROR] chmod 775 $LATEST_DIR \n" ; return 1 ;fi
    fi

    # Remove previous backup link in the latest directory
    sadm_write "Removing previous backup links in $LATEST_DIR \n"
    rm -f $LATEST_DIR/20* > /dev/null 2>&1

    # Determine the Directory where the backup will be created
    ARCHIVE_DIR="${DAILY_DIR}"                                          # Default goes in Daily Dir.
    LINK_DIR="../../daily/${HOSTNAME}/${CUR_DATE}"                      # Latest Backup Link Dir.
    if [ "${CUR_DAY_NUM}" -eq "$SADM_WEEKLY_BACKUP_DAY" ]               # It's the Weekly Backup Day
        then ARCHIVE_DIR="${WEEKLY_DIR}"                                # Will be Weekly Backup Dir.
             LINK_DIR="../../weekly/${HOSTNAME}/${CUR_DATE}"            # Latest Backup Link Dir.
    fi
    if [ "$CUR_DATE_NUM" -eq "$SADM_MONTHLY_BACKUP_DATE" ]              # It's Monthly Backup Date ?
        then ARCHIVE_DIR="${MONTHLY_DIR}"                               # Will be Monthly Backup Dir
             LINK_DIR="../../monthly/${HOSTNAME}/${CUR_DATE}"           # Latest Backup Link Dir.
    fi
    if [ "$CUR_DATE_NUM" -eq "$SADM_YEARLY_BACKUP_DATE" ]               # It's Year Backup Date ?
        then if [ "$CUR_MTH_NUM" -eq "$SADM_YEARLY_BACKUP_MONTH" ]      # And It's Year Backup Mth ?
                then ARCHIVE_DIR="${YEARLY_DIR}"                        # Will be Yearly Backup Dir
                     LINK_DIR="../../yearly/${HOSTNAME}/${CUR_DATE}"    # Latest Backup Link Dir.
             fi
    fi

    # Make sure the Server Backup Directory exist on NFS Drive -------------------------------------
    if [ ! -d ${ARCHIVE_DIR} ]                                          # Check if Server Dir Exist
        then sadm_write "Making today archive directory $ARCHIVE_DIR \n" # Show user what were doing
             mkdir ${ARCHIVE_DIR}                                       # If Not Create it
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_write "[ERROR] Creating Directory $ARCHIVE_DIR \n"
                     sadm_write "        On the NFS Server ${SADM_BACKUP_NFS_SERVER} \n"
                     return 1                                           # End Function with error
             fi
             chown ${SADM_USER}:${SADM_GROUP} $ARCHIVE_DIR              # Assign it SADM USer&Group
             chmod 775 $ARCHIVE_DIR                                     # Assign Protection
    fi

    # Make sure the Server Backup Directory With Today's Date exist on NFS Drive -------------------
    BACKUP_DIR="${ARCHIVE_DIR}/${CUR_DATE}"                             # Set Backup Directory
    if [ ! -d ${BACKUP_DIR} ]                                           # Check if Server Dir Exist
        then sadm_write "Making today backup directory $BACKUP_DIR \n"
             mkdir ${BACKUP_DIR}                                        # If Not Create it
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_write "[ERROR] Creating Directory ${BACKUP_DIR} \n"
                     sadm_write "        On the NFS Server ${SADM_BACKUP_NFS_SERVER}\n"
                     return 1                                           # End Function with error
             fi
             chown ${SADM_USER}.${SADM_GROUP} ${BACKUP_DIR}             # Assign it SADM USer&Group
             chmod 775 ${BACKUP_DIR}                                    # Assign Protection
    fi


    # Make Sure backup file list exist.
    if [ ! -f "$SADM_BACKUP_LIST" ]
        then if [ -f "$SADM_BACKUP_LIST_INIT" ]                         # If Def. Backup List Exist
                then sadm_write "Backup File List ($SADM_BACKUP_LIST) doesn't exist.\n"
                     sadm_write "Using Default Backup List ($SADM_BACKUP_LIST_INIT) file.\n"
                     cp $SADM_BACKUP_LIST_INIT $SADM_BACKUP_LIST >>$SADM_LOG 2>&1
                else sadm_write "No Backup List File ($SADM_BACKUP_LIST) or Default ($SADM_BACKUP_LIST_INIT).\n"
                     sadm_write "Aborting Backup\n"
                     sadm_write "Put Dir & files to backup in $SADM_BACKUP_LIST and retry\n"
                     return 1                                           # Return Error to Caller
             fi
    fi

    # Make Sure backup exclude list file exist.
    if [ ! -f "$SADM_BACKUP_EXCLUDE" ]
        then if [ -f "$SADM_BACKUP_EXCLUDE_INIT" ]                      # If Def. Backup List Exist
                then sadm_write "Backup Exclude List File ($SADM_BACKUP_EXCLUDE) doesn't exist.\n"
                     sadm_write "Using Default Backup Exclude List ($SADM_BACKUP_EXCLUDE_INIT) file.\n"
                     cp $SADM_BACKUP_EXCLUDE_INIT $SADM_BACKUP_EXCLUDE >>$SADM_LOG 2>&1
                else sadm_write "No Backup Exclude list ($SADM_BACKUP_EXCLUDE) or Default ($SADM_BACKUP_EXCLUDE_INIT).\n"
                     sadm_write "Aborting Backup\n"
                     sadm_write "Put Dir & files to exclude in $SADM_BACKUP_EXCLUDE and retry.\n"
                     return 1                                           # Return Error to Caller
             fi
    fi

    # Show Backup Preferences
    sadm_write "You have chosen to : \n"
    if [ "$COMPRESS" = 'ON' ]
        then sadm_write " - Compress the backup file\n"
        else sadm_write " - Not compress the backup\n"
    fi
    sadm_write " - Keep $SADM_DAILY_BACKUP_TO_KEEP daily backups.\n"
    sadm_write " - Keep $SADM_WEEKLY_BACKUP_TO_KEEP weekly backups.\n"
    sadm_write " - Keep $SADM_MONTHLY_BACKUP_TO_KEEP monthly backups.\n"
    sadm_write " - Keep $SADM_YEARLY_BACKUP_TO_KEEP yearly backups.\n"
    sadm_write " - Do the weekly backup on ${WEEKDAY[$SADM_WEEKLY_BACKUP_DAY]}.\n"
    sadm_write " - Do the monthly backup on the $SADM_MONTHLY_BACKUP_DATE of every month.\n"
    sadm_write " - Do the yearly backup on the $SADM_YEARLY_BACKUP_DATE of ${MTH_NAME[$SADM_YEARLY_BACKUP_MONTH]} every year.\n"
    sadm_write " - Backup Directory is ${BACKUP_DIR}.\n"
    sadm_write " - Using Backup list file ${SADM_BACKUP_LIST}.\n"
    sadm_write " - Using Backup exclude list file ${SADM_BACKUP_EXCLUDE}.\n"
    return 0
}


# --------------------------------------------------------------------------------------------------
#   Create Backup Files Main Function - Loop for each file specified in the backup_list.txt file
# --------------------------------------------------------------------------------------------------
create_backup()
{
    sadm_write "\n${SADM_TEN_DASH}\nStarting the Backup Process\n\n"    # Advise Backup Process Begin
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.
    TOTAL_ERROR=0                                                       # Make Sure Variable is at 0

    while read backup_line                                              # Loop Until EOF Backup List
        do
        FC=`echo $backup_line | cut -c1`                                # Get First Char. of Line
        backup_line=`echo $backup_line | tr -d '\r'`                    # Remove EndOfLine CR if any 
        backup_line=`echo $backup_line | sed 's/[[:blank:]]*$//'`       # Remove Blank & Tab if any 
        if [ "$FC" = "#" ] || [ ${#backup_line} -eq 0 ]                 # Line begin with # or Empty
            then continue                                               # Skip, Go read Next Line
        fi  

        # Check if File or Directory to Backup and if they Exist
        sadm_write "${SADM_TEN_DASH}\n"                                 # Line of 10 Dash in Log
        if [ -d "${backup_line}" ]                                      # Dir. To Backup Exist
            then if [ $SADM_DEBUG -gt 0 ] 
                    then sadm_write "Directory to Backup : [${backup_line}]\n" # Processing Line
                 fi
            else if [ -f "$backup_line" ] && [ -r "$backup_line" ]      # If File to Backup Readable
                    then if [ $SADM_DEBUG -gt 0 ] 
                            then sadm_write "File to Backup : ${backup_line}.\n"  # Print Current File
                         fi
                    else MESS="[SKIPPING] [$backup_line] doesn't exist on $(sadm_get_fqdn)"
                             sadm_write "${MESS}\n"                     # Advise User - Log Info
                             continue                                   # Go Read Nxt Line to backup
                    fi
        fi

        BASE_NAME=`echo "$backup_line" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' `
        TIME_STAMP=`date "+%C%y_%m_%d-%H_%M_%S"`                        # Current Date & Time

        # Backup File
        if [ -f "$backup_line" ] && [ -r "$backup_line" ]               # Line is a File & Readable
            then
                if [ "$COMPRESS" == "ON" ]                              # If compression ON
                    then BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tgz"     # Final tgz Backup file name
                         sadm_write "tar -cvzf ${BACKUP_DIR}/${BACK_FILE} $backup_line \n"
                         tar -cvzf ${BACKUP_DIR}/${BACK_FILE} $backup_line >/dev/null 2>>$SADM_LOG
                         RC=$?                                          # Save Return Code
                    else BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tar"     # Final tar Backup file name
                         sadm_write "tar -cvf ${BACKUP_DIR}/${BACK_FILE} $backup_line \n"
                         tar -cvf ${BACKUP_DIR}/${BACK_FILE} $backup_line >/dev/null 2>>$SADM_LOG
                         RC=$?                                          # Save Return Code
                fi
        fi

        # Backup Directory
        if [ -d ${backup_line} ]                                        # Dir to Backup Exist ?
           then cd $backup_line                                         # Ok then Change Dir into it
                sadm_write "Current directory is: [`pwd`]\n"            # Print Current Dir.
                # Build Backup Exclude list
                find . -type s -print > /tmp/exclude                    # Put all Sockets in exclude
                while read excl_line                                    # Loop Until EOF Excl. File
                    do
                    FC=`echo $excl_line | cut -c1`                      # Get First Char. of Line
                    if [ "$FC" = "#" ] || [ ${#excl_line} -eq 0 ]       # Skip Comment or Blank Line
                        then continue                                   # Blank or Comment = NxtLine
                    fi
                    echo "$excl_line" >> /tmp/exclude                   # Add Line to Exclude List
                    done < $SADM_BACKUP_EXCLUDE                         # Read Backup Exclude File
                if [ $SADM_DEBUG -gt 0 ]                                # If Debug Show Exclude List
                    then sadm_write "Content of exclude file\n"        # Show User what's coming
                         cat /tmp/exclude| while read ln ;do sadm_write "${ln}\n" ;done # Show Excl.
                fi
                # Perform the Backup using tar command
                if [ "$COMPRESS" == "ON" ]
                    then BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tgz"     # Final tgz Backup file name
                         sadm_write "tar -cvzf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .\n"
                         tar -cvzf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude . >/dev/null 2>>$SADM_LOG
                         RC=$?                                          # Save Return Code
                    else BACK_FILE="${TIME_STAMP}_${BASE_NAME}.tar"     # Final tar Backup file name
                         sadm_write "tar -cvf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude .\n"
                         tar -cvf ${BACKUP_DIR}/${BACK_FILE} -X /tmp/exclude . >/dev/null 2>>$SADM_LOG
                         RC=$?                                          # Save Return Code
                fi
        fi

        # Error 1 = File(s) changed while backup running, don't report that as an error.
        if [ $RC -eq 1 ] ; then RC=0 ; fi                               # File Changed while backup

        # Create link to backup in the server latest directory
        cd ${LATEST_DIR}
        if [ $SADM_DEBUG -gt 0 ] 
            then sadm_write "Current directory is : `pwd`\n"            # Print Current Dir.
                 sadm_write "ln -s ${LINK_DIR}/${BACK_FILE} ${BACK_FILE}\n" # Command we'll execute
        fi
        sadm_write "Create Link to latest backup of ${backup_line}\n"   # Show User what were doing
        ln -s ${LINK_DIR}/${BACK_FILE} ${BACK_FILE}  >>$SADM_LOG 2>&1   # Run Soft Link Command
        if [ $? -ne 0 ]                                                 # If Error trying to link
            then sadm_write "[ERROR] Creating Link Backup in latest Directory\n"
        fi
        
        if [ $RC -ne 0 ]                                                # If Error while Backup
            then MESS="[ERROR] ${RC} while creating $BACK_FILE"         # Advise Backup Error
                 sadm_write "${MESS}\n"                                 # Advise User - Log Info
                 RC=1                                                   # Make Sure Return Code is 0
            else MESS="[SUCCESS] Creating Backup $BACK_FILE"            # Advise Backup Success
                 sadm_write "${MESS}\n"                                 # Advise User - Log Info
                 RC=0                                                   # Make Sure Return Code is 0
        fi
        TOTAL_ERROR=$(($TOTAL_ERROR+$RC))                               # Total = Cumulate RC Value

        rm -f /tmp/exclude >/dev/null 2>&1                              # Remove socket tmp file
        done < $SADM_BACKUP_LIST                                         # For Loop Read Backup List


    # End of Backup
    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    sadm_write "\n${SADM_TEN_DASH}\nTotal error(s) while creating backup is ${TOTAL_ERROR}.\n"
    return $TOTAL_ERROR                                                 # Return Total of Error
}


# --------------------------------------------------------------------------------------------------
#               Keep only the number of backup copies specied in $SADM_DAILY_BACKUP_TO_KEEP
# --------------------------------------------------------------------------------------------------
clean_backup_dir()
{
    TOTAL_ERROR=0                                                       # Reset Total of error
    sadm_write "\n${SADM_TEN_DASH}\nApplying chosen retention policy to ${ARCHIVE_DIR} directory\n"
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.

    # Enter Server Backup Directory
    # May need to delete some backup if more than $SADM_DAILY_BACKUP_TO_KEEP copies
    cd ${ARCHIVE_DIR}                                                   # Change Dir. To Backup Dir.

    # List Current backup days we have and Count Nb. how many we need to delete
    sadm_write "List of backup currently on disk:\n"
    ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |while read ln ;do sadm_write "${ln}\n" ;done
    backup_count=`ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |wc -l` # Calc. Nb. Days of backup
    day2del=$(($backup_count-$SADM_DAILY_BACKUP_TO_KEEP))               # Calc. Nb. Days to remove
    sadm_write "\nKeep only the last $SADM_DAILY_BACKUP_TO_KEEP days of each backup.\n"
    sadm_write "We now have $backup_count days of backup(s).\n"         # Show Nb. Backup Days

    # If current number of backup days on disk is greater than nb. of backup to keep, then cleanup.
    if [ "$backup_count" -gt "$SADM_DAILY_BACKUP_TO_KEEP" ]
        then sadm_write "So we need to delete $day2del day(s) of backup.\n"
             ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |tail -$day2del > $SADM_TMP_FILE3
             cat $SADM_TMP_FILE3 |while read ln ;do sadm_write "Deleting ${ln}\n" ;rm -fr ${ln}* ;done
             sadm_write "\nList of backup currently on disk:\n"
             ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |while read ln ;do sadm_write "${ln}\n" ;done
        else sadm_write "No clean up needed\n"
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
        then sadm_write "Create local mount point ${LOCAL_MOUNT}\n"     # Advise user we create Dir.
             mkdir ${LOCAL_MOUNT}                                       # Create if not exist
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_write "[ERROR] Creating local mount point - Process aborted.\n"
                return 1                                                # End Function with error
             fi
             chmod 775 ${LOCAL_MOUNT}                                   # Change Protection
    fi

    # Mount the NFS Drive - Where the Backup file will reside -----------------------------------------
    REM_MOUNT="${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT}"
    sadm_write "Mounting NFS Drive on ${SADM_BACKUP_NFS_SERVER}.\n"     # Show NFS Server Name
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted
    if [ "$SADM_OS_TYPE" = "DARWIN" ]                                   # If on MacOS
        then sadm_write "mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT}.\n"
             mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
        else sadm_write "mount ${REM_MOUNT} ${LOCAL_MOUNT}.\n"          # If on Linux/Aix
             mount ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1         # Mount NFS Drive
    fi
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_write "[ERROR] Mount NFS Failed - Process Aborted.\n" # Error - Advise User
             return 1                                                   # End Function with error
        else sadm_write "[SUCCESS] NFS Mount Succeeded.\n"              # NFS Mount Succeeded Msg
    fi
    return 0
}


# ==================================================================================================
#                                Unmount NFS Backup Directory
# ==================================================================================================
umount_nfs()
{
    sadm_write "\n${SADM_TEN_DASH}\nUnmounting NFS mount directory ${LOCAL_MOUNT}.\n"
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_write "[ERROR] Unmounting NFS Dir. $LOCAL_MOUNT \n"   # Error - Advise User
             return 1                                                   # End Function with error
        else sadm_write "[SUCCESS] Unmounting NFS Dir. $LOCAL_MOUNT \n" # Succeeded to Demount NFS
    fi
    return 0
}

# ==================================================================================================
#                              S T A R T   O F   M A I N    P R O G R A M
# ==================================================================================================
#
    sadm_start                                                          # Start Using SADM Tools
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9])
    COMPRESS="ON"                                                       # Backup Compression Default
    while getopts "hvnd:" opt ; do                                      # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               ;;                                                       # No stop after each page
            n) COMPRESS="OFF"                                           # No Compress backup
               ;;
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $SADM_DEBUG -gt 0 ]                                            # If Debug is Activated
        then printf "\nDebug activated, Level ${SADM_DEBUG}"            # Display Debug Level
             printf "\nBackup compression is $COMPRESS"                 # Show Status of compression
    fi

    mount_nfs                                                           # Mount NFS Dir.
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    backup_setup                                                        # Create Necessary Dir.
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS
    create_backup                                                       # Create TGZ of Selected Dir
    SADM_EXIT_CODE=$?                                                   # Save Backup Result Code
    clean_backup_dir                                                    # Delete Old Backup
    if [ $? -ne 0 ] ; then umount_nfs ; sadm_stop 1 ; exit 1 ; fi       # If Error While Cleaning up
    umount_nfs                                                          # Umounting NFS Drive

    sadm_stop $SADM_EXIT_CODE                                           # Close & Trim rch,log,pid
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
