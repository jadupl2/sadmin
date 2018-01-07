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
SADM_VER='1.2'                             ; export SADM_VER            # Your Script Version
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
MYSQLDUMP=""                        ; export MYSQLDUMP                  # Save mysqldump Full Path
DIR_BACKUP="${SADMIN}/dat/dbb"      ; export DIR_BACKUP                 # Root DataBase Backup Dir.

# Backup File Name
BACKUP_FILE=""                      ; export BACKUP_FILE                # Backup File Name
BACKUP_SUFFIX=""                    ; export BACKUP_SUFFIX              # Backup File Name Suffix
BACKUP_DB=""                        ; export BACKUP_DB                  # Backup Database Name

# Daily Backup Info 
BACKUP_DAILY_TO_KEEP=14             ; export BACKUP_DAILY_TO_KEEP       # Nb. Daily Backup to keep
DIR_DAY="${DIR_BACKUP}/daily"       ; export DIR_DAY                    # Dir. For Daily Backup                                 

# Weekly Backup Info
DIR_WEEK="${DIR_BACKUP}/weekly"     ; export DIR_WEEK                   # Dir. For Weekly Backup
BACKUP_CUR_DAY=`date +"%u"`         ; export BACKUP_CUR_DAY             # Current Day in Week 1=Mon
BACKUP_WEEK_DAY=5                   ; export BACKUP_WEEK_DAY            # Day Week Backup 1=Mon7=Sun
BACKUP_WEEK_TO_KEEP=14              ; export BACKUP_WEEK_TO_KEEP        # Nb. Weekly Backup to keep

# Monthly Backup Info
DIR_MTH="${DIR_BACKUP}/monthly"     ; export DIR_MTH                    # Dir. For Monthly Backup
BACKUP_CUR_DATE=`date +"%d"`        ; export BACKUP_CUR_DATE            # Current Date Nb. of Month
BACKUP_MONTH_DATE=1                 ; export BACKUP_MONTH_DATE          # Monthly Backup Date (1-28)
BACKUP_MONTH_TO_KEEP=14             ; export BACKUP_MONTH_TO_KEEP       # Nb. Monthly Backup to keep

# Yearly Backup Info
DIR_YEAR="${DIR_BACKUP}/yearly"     ; export DIR_YEAR                   # Dir. For Yearly Backup
BACKUP_CUR_MTH=`date +"%m"`         ; export BACKUP_CUR_MTH             # Current Month Number 
BACKUP_YEAR_MTH=1                   ; export BACKUP_YEAR_MTH            # Yearly Backup Month (1-12)
BACKUP_YEAR_DATE=2                  ; export BACKUP_YEAR_DATE           # Yearly Backup Date (1-28)
BACKUP_YEAR_TO_KEEP=10              ; export BACKUP_YEAR_TO_KEEP        # Nb. Yearly Backup to keep


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
    if [ ! -d "${DIR_BACKUP}" ]                                         # Main Backup Dir. Exist ?
        then mkdir $DIR_BACKUP                                          # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $DIR_BACKUP               # Assign it SADM USer&Group
             chmod 775 $DIR_BACKUP                                      # Read/Write to SADM Usr/Grp
    fi

    # Daily Backup Directory
    if [ ! -d "${DIR_DAY}" ]                                            # Daily Backup Dir. Exist ?
        then mkdir $DIR_DAY                                             # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $DIR_DAY                  # Assign it SADM USer&Group
             chmod 775 $DIR_DAY                                         # Read/Write to SADM Usr/Grp
    fi

    # Weekly Backup Directory
    if [ ! -d "${DIR_WEEK}" ]                                            # Daily Backup Dir. Exist ?
        then mkdir $DIR_WEEK                                             # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $DIR_WEEK                  # Assign it SADM USer&Group
             chmod 775 $DIR_WEEK                                         # Read/Write to SADM Usr/Grp
    fi

    # Monthly Backup Directory
    if [ ! -d "${DIR_MTH}" ]                                            # Monthly Backup Dir. Exist?
        then mkdir $DIR_MTH                                             # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $DIR_MTH                  # Assign it SADM USer&Group
             chmod 775 $DIR_MTH                                         # Read/Write to SADM Usr/Grp
    fi

    # Yearly Backup Directory
    if [ ! -d "${DIR_YEAR}" ]                                           # Yearly Backup Dir. Exist?
        then mkdir $DIR_YEAR                                            # Create Directory
             chown ${SADM_USER}:${SADM_GROUP} $DIR_YEAR                 # Assign it SADM USer&Group
             chmod 775 $DIR_YEAR                                        # Read/Write to SADM Usr/Grp
    fi

}

#===================================================================================================
#               Delete Backup File according to the number of backup user wants to keep
#===================================================================================================
backup_cleanup()
{
    BACKUP_DAILY_TO_KEEP=2             ; export BACKUP_DAILY_TO_KEEP       # Nb. Daily Backup to keep
    DIR_DAY="${DIR_BACKUP}/weekly/sadmin"       ; export DIR_DAY                    # Dir. For Daily Backup                                 

    ls -lt ${DIR_DAY}
    NUMFILE=`ls -1t ${DIR_DAY} | wc -l` 
    echo "Num of File = $NUMFILE"

    NUM2DEL=`echo "$NUMFILE - $BACKUP_DAILY_TO_KEEP" | $SADM_BC`
    echo "Num to Del = $NUM2DEL"

    ls -lt ${DIR_DAY} | tail -${NUM2DEL}
    return
}
    
#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
backup_db()
{
    CURRENT_DB=$1                                                       # Database Name to Backup

    # Build the Backup File Name
    BACKUP_SUFFIX=`date +"%Y_%m_%d_%H_%M_%S_%A"`                        # Backup File Name Suffix
    BACKUP_FILE="${CURRENT_DB}_${BACKUP_SUFFIX}.sql"                    # Build Backup File Name 

    # Determine the Directory where the backup will be created
    BDIR="${DIR_DAY}/$CURRENT_DB"                                       # Default goes in Daily Dir.
    if [ "${BACKUP_CUR_DAY}" -eq "$BACKUP_WEEK_DAY" ]                   # It's the Weekly Backup Day
        then BDIR="${DIR_WEEK}/$CURRENT_DB"                             # Will be Weekly Backup Dir. 
    fi 
    if [ "$BACKUP_CUR_DATE" -eq "$BACKUP_MONTH_DATE" ]                  # It's Monthly Backup Date ?
        then BDIR="${DIR_MTH}/$CURRENT_DB"                              # Will be Monthly Backup Dir
    fi 
    if [ "$BACKUP_CUR_DATE" -eq "$BACKUP_YEAR_DATE" ]                   # It's Year Backup Date ?
        then if [ "$BACKUP_CUR_MTH" -eq "$BACKUP_YEAR_MTH" ]            # And It's Year Backup Mth ?
                then BDIR="${DIR_YEAR}/$CURRENT_DB"                     # Will be Yearly Backup Dir
             fi
    fi 

    # Make Sure Backup Destination Directory Exist
    if [ ! -d "${BDIR}" ]                                               # Backup Dir. Exist?
        then mkdir $BDIR                                                # Create Final Backup Dir.
             chown ${SADM_USER}:${SADM_GROUP} $BDIR                     # Assign it SADM USer&Group
             chmod 775 $BDIR                                            # Read/Write to SADM Usr/Grp
    fi

    BFILE="${BDIR}/${BACKUP_FILE}"                                      # Backup Filename Full Path 
    sadm_writelog "The Backup Directory is ${BDIR}"                     # Show User Backup Directory
    sadm_writelog "The Backup FileName is ${BACKUP_FILE}"               # Show User Backup Filename
    touch $BFILE                                                        # Create empty backup file
    chown ${SADM_USER}:${SADM_GROUP} $BFILE                             # Assign it SADM USer&Group
    chmod 600 $BFILE                                                    # Read/Write 2 SADM Usr Only

    CREDENTIAL="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD -h $SADM_DBHOST"   # User,Passwd and Host Used
    if [ $DEBUG_LEVEL -gt 5 ]                                           # If Debug Level > 5 
        then sadm_writelog "$MYSQLDUMP $CREDENTIAL $SADM_DBNAME "       # Debug = Write Command Used
    fi
    sadm_writelog "Starting Backup of Database $CURRENT_DB"             # Advise User were Starting
    $MYSQLDUMP $CREDENTIAL $SADM_DBNAME > $BFILE 2>&1                   # Run the Database Backup
    if [ $? -ne 0 ]                                                     # If Can't be found 
        then sadm_writelog "[ERROR] The 'mysqldump' command failed"     # Advise User
             return 1                                                   # Return Error to Caller
        else sadm_writelog "[SUCCESS] Backup Succeeded"                 # Advise User
    fi


}

#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    backup_setup                                                        # Is Setup/Requirement ok ?
    if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller

    #backup_db "sadmin"                                                  # Backup the Database
    #if [ $? -ne 0 ] ; then return 1 ; fi                                # If Error Return to Caller
    
    backup_cleanup                                                      # Purge unwanted Backup file
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

    # MAIN SCRIPT PROCESS HERE ---------------------------------------------------------------------
    main_process                                                        # Main Process

    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
