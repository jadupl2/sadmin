#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_housekeeping.sh
#   Synopsis :  Set Owner/Group, Priv/Protection on www sub-directories and cleanup www/tmp/perf dir.
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# Enhancements/Corrections Version Log
# 2017_07_07    v1.8 Code enhancement
# 2018_05_14    v1.9 Correct problem on MacOS with change owner/group command
# 2018_06_05    v2.0 Added www/tmp/perf removal of *.png files older than 5 days.
# 2018_06_09    v2.1 Add Help and version function, change script name & Change startup order
# 2018_08_28    v2.2 Delete rch and log older than the number of days specified in sadmin.cfg
# 2018_11_29    v2.3 Restructure for performance and don't delete rch/log files anymore.
#@2019_05_19 Update: v2.4 Add server crontab file to housekeeping
#@2020_02_19 Update: v2.5 Restructure & added archiving of old alert history to history archive. 
#@2020_05_23 Update: v2.6 Minor change about reading /etc/environment and change logging messages.
#@2020_12_16 Update: v2.7 Include code to include in SADMIN server crontab the daily report email.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x




#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # If SADMIN EnvVar not right
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null          # SADMIN in /etc/environment
         if [ $? -eq 0 ]                                                # Found SADMIN in /etc/env..
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' Environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                 # Current Script filename(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`       # Current Script filename(without extension)
export SADM_TPID="$$"                                   # Current Script Process ID.
export SADM_HOSTNAME=`hostname -s`                      # Current Host name without Domain Name
export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Std Libr.).
export SADM_VER='2.7'                                   # Current Script Version
export SADM_EXIT_CODE=0                                 # Current Script Default Exit Return Code
export SADM_LOG_TYPE="B"                                # writelog go to [S]creen [L]ogFile [B]oth
export SADM_LOG_APPEND="N"                              # [Y]=Append Existing Log [N]=Create New Log
export SADM_LOG_HEADER="Y"                              # [Y]=Include Log Header  [N]=No log Header
export SADM_LOG_FOOTER="Y"                              # [Y]=Include Log Footer  [N]=No log Footer
export SADM_MULTIPLE_EXEC="N"                           # Allow running multiple copy at same time ?
export SADM_PID_TIMEOUT=7200                            # Nb. Sec. a PID can block script execution
export SADM_LOCK_TIMEOUT=3600                           # Sec. before Server Lock File get deleted
export SADM_USE_RCH="Y"                                 # Gen. History Entry in ResultCodeHistory 
export SADM_DEBUG=0                                     # Debug Level - 0=NoDebug Higher=+Verbose
export SADM_TMP_FILE1=""                                # Tmp File1 you can use, Libr. will set name
export SADM_TMP_FILE2=""                                # Tmp File2 you can use, Libr. will set name
export SADM_TMP_FILE3=""                                # Tmp File3 you can use, Libr. will set name

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                          # LOAD SADMIN Standard Shell Libr. Functions
export SADM_OS_NAME=$(sadm_get_osname)                  # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
export SADM_OS_VERSION=$(sadm_get_osversion)            # O/S Full Version Number  (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)      # O/S Major Version Number (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/CFG/SADMIN.CFG FILE).
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                               # 0=None 1=AlertOnError 2=AlertOnOK 3=Always
#export SADM_ALERT_GROUP="default"                      # Alert Group to advise (alert_group.cfg)
#export SADM_MAIL_ADDR="your_email@domain.com"          # Email to send log (Override sadmin.cfg)
#export SADM_MAX_LOGLINE=500                            # At the end Trim log to 500 Lines(0=NoTrim)
#export SADM_MAX_RCLINE=35                              # At the end Trim rch to 35 Lines (0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 

#===================================================================================================




# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT            # Error Counter
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL            # Set Debug Level
yellow=$(tput setaf 3)                      ; export yellow                 # Yellow color
white=$(tput setaf 7)                       ; export white                  # White color
ARC_DAYS=7                                  ; export ARC_DAYS               # ALert Age to move



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}


show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
    printf "\n\n" 
}




# --------------------------------------------------------------------------------------------------
#                             General Directories Owner/Group and Privilege
# --------------------------------------------------------------------------------------------------
set_dir()
{
    VAL_DIR=$1 ; VAL_OCTAL=$2 ; VAL_OWNER=$3 ; VAL_GROUP=$4
    RETURN_CODE=0

    if [ -d "$VAL_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Change $VAL_DIR to $VAL_OCTAL"
             chmod $VAL_OCTAL $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on 'chmod' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             sadm_writelog "Change chmod gou-s $VAL_DIR"
             chmod gou-s $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on 'chmod' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             sadm_writelog "Change $VAL_DIR owner to ${VAL_OWNER}.${VAL_GROUP}"
             chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on 'chown' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             ls -ld $VAL_DIR | tee -a $SADM_LOG
             if [ $RETURN_CODE = 0 ] ; then sadm_writelog "OK" ; fi
    fi
    return $RETURN_CODE
}



# --------------------------------------------------------------------------------------------------
# Move Alert older than 30 days from $SADMIN/cfg/alert_history.txt to $SADMIN/cfg/alert_archive.txt
# --------------------------------------------------------------------------------------------------
alert_housekeeping()
{
    sadm_write "${BOLD}${YELLOW}Move Alert older than $ARC_DAYS days to the alert history file.\n" 
    sadm_write "They are move from $SADM_ALERT_HIST to $SADM_ALERT_ARC file.${NORMAL}\n"

    # If History archive doesn't exist, create it.
    if [ ! -f "$SADM_ALERT_ARC" ]                                       # If Archive don't exist
        then cp $SADM_ALERT_ARCINI $SADM_ALERT_ARC                      # Create Initial Archive
             chmod 664 $SADM_ALERT_ARC 
             chown $SADM_USER:$SADM_GROUP $SADM_ALERT_ARC
    fi 

    # Create file that will eventually become the New Alert History File from the template
    cp $SADM_ALERT_HINI $SADM_TMP_FILE3                                 # Create new Initial History
     
    # Alert than happen before Calculate Epoch time (archive_epoch) will be archive.
    current_epoch=$(sadm_get_epoch_time)                                # Get Current Epoch
    alert_age=`echo "86400 * $ARC_DAYS" | $SADM_BC`                     # Nb of Sec. before Archive
    archive_epoch=`echo $current_epoch - $alert_age | $SADM_BC`         # Archive Epoch Threshold
    if [ $SADM_DEBUG -gt 0 ]                                            # Under Debug
        then sadm_writelog "Alert before $archive_epoch are archive."   # Show Epoch Threshold
    fi

    # Read Alert History file
    cat $SADM_ALERT_HIST | while read line  ; 
        do
        #echo "line=$line" 
        if  [[ "$line" =~ ^[[:space:]]*# ]] ; then continue ; fi
        num=`echo $line | awk -F\; '{ print $1 }'`                      # Get Current Alert Epoch
        alert_epoch=`echo "$num" | grep -E ^\-?[0-9]?\.?[0-9]+$`        # Valid is Level is Numeric
        if [ "$alert_epoch" = "" ] ; then continue ; fi                 # No it's not numeric, skip
        if [ $alert_epoch -lt $archive_epoch ]
            then if [ $SADM_DEBUG -gt 0 ] ;then  sadm_writelog "Alert added to archive." ;fi
                 echo $line >> $SADM_ALERT_ARC
                 ldate=`echo $line | awk -F\; '{ print $4 }'`           # Extract Alert Date
                 ltime=`echo $line | awk -F\; '{ print $3 }'`           # Extract Alert Time
                 lhost=`echo $line | awk -F\; '{ print $6 }'`           # Extract Alert Host
                 lmess=`echo $line | awk -F\; '{ print $8 }'`           # Extract Error Mess
                 sadm_write "Archiving Alert: $ldate $ltime $lhost $lmess \n"
            else if [ $SADM_DEBUG -gt 0 ] ;then sadm_writelog "Alert left in history file." ;fi
                 echo $line >> $SADM_TMP_FILE3
        fi 
        done
    
    # Replace current history file by the tmp just created.
    cp $SADM_TMP_FILE3 $SADM_ALERT_HIST
    chmod 664 $SADM_ALERT_HIST
    chown $SADM_USER:$SADM_GROUP $SADM_ALERT_HIST
}



# --------------------------------------------------------------------------------------------------
#                               General Directories Housekeeping Function
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_write "\n"
    sadm_write "${YELLOW}${BOLD}Server Directories HouseKeeping.${NORMAL}\n"

    # Reset privilege on WWW Directory files
    if [ -d "$SADM_WWW_DIR" ]
        then CMD="find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \;"
             find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "${SADM_ERROR} running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
             fi
             CMD="find $SADM_WWW_DIR -exec chown -R ${SADM_WWW_USER}:${SADM_WWW_GROUP} {} \;"
             find $SADM_WWW_DIR -exec chown -R ${SADM_WWW_USER}:${SADM_WWW_GROUP} {} \;>/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "${SADM_ERROR} running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
             fi
    fi
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_write "\n"
    sadm_write "${YELLOW}${BOLD}Server Files HouseKeeping.${NORMAL}\n"

    # Make sure crontab for SADMIN server have proper permission and owner
    sadm_writelog "Make sure SADMIN crontab file have proper permission and owner"
    afile="/etc/cron.d/sadm_server"
    if [ -f "$afile" ]
        then CMD="chmod 0644 $afile && chown root:root $afile"
             chmod 0644 $afile && chown root:root $afile 
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} running ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
    fi

    # Make sure crontab for O/S Update have proper permission and owner
    afile="/etc/cron.d/sadm_osupdate"
    if [ -f "$afile" ]
        then CMD="chmod 0644 $afile && chown root:root $afile"
             chmod 0644 $afile && chown root:root $afile 
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} running ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
    fi

    # Make sure crontab for Backup have proper permission and owner
    afile="/etc/cron.d/sadm_backup"
    if [ -f "$afile" ]
        then CMD="chmod 0644 $afile && chown root:root $afile"
             chmod 0644 $afile && chown root:root $afile 
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} running ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
    fi

    # Set Permission on all files in the images directory.
    sadm_write "\n"
    sadm_write "${YELLOW}${BOLD}Setting permissions in the website directories.${NORMAL}\n"
    CMD="find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \;"
    find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running $CMD \n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.php files 
    CMD="find $SADM_WWW_DIR -type f -name *.php -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.php -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.css files 
    CMD="find $SADM_WWW_DIR -type f -name *.css -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.css -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.js files 
    CMD="find $SADM_WWW_DIR -type f -name *.js -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.js -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running $CMD \n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.rrd files 
    CMD="find $SADM_WWW_DIR -type f -name *.rrd -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.rrd -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "${SADM_ERROR} running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running $CMD \n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.pdf files 
    CMD="find $SADM_WWW_DIR -type f -name *.pdf -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.pdf -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "${SADM_ERROR} running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
    fi

    # Set Permission on all files in www/dat directories.
    CMD="find $SADM_WWW_DAT_DIR -type f -exec chmod 664 {} \;"
    find $SADM_WWW_DAT_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
    fi

    # Delete performance graph (*.png) generated by web interface older than 5 days.
    if [ -d "$SADM_WWW_PERF_DIR" ]
        then sadm_write "\n" 
             sadm_write "${YELLOW}${BOLD}Delete any *.png files older than 5 days in ${SADM_WWW_PERF_DIR}.${NORMAL}\n"
             CMD="find $SADM_WWW_PERF_DIR -type f -mtime +5 -name '*.png' -exec rm -f {} \;"
             find $SADM_WWW_PERF_DIR -type f -mtime +5 -name "*.png" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} running ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
    fi
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
# This function make sure that the SADMIN server contains latest scripts version that was added.
# --------------------------------------------------------------------------------------------------
function adjust_server_crontab()
{
    # Make sure the Daily Email Report is in the SADMIN server crontab.
    F="/etc/cron.d/sadm_server"
    if ! grep -q 'sadm_daily_report.sh' $F 
       then echo "#" >> $F 
            echo "# SADMIN Daily Email Report about Scripts, ReaR and Daily Backup" >> $F 
            echo "04 07 * * * root $SADMIN/bin/sadm_daily_report.sh > /dev/null 2>&1" >> $F 
            echo "#" >> $F  
            sadm_write "${BOLD}${YELLOW}Daily Email Report added to ${F}${NORMAL}.\n" 
    fi 

    # Push SERVER $SADMIN/bin $SADMIN/lib $SADMIN/.*.cfg to all actives clients.
    # -s To include push of $SADMIN/sys
    # -u To include push of $SADMIN/(usr/bin usr/lib usr/cfg) 
    F="/etc/cron.d/sadm_server"
    if ! grep -q 'sadm_push_sadmin.sh' $F 
       then echo "#" >> $F 
            echo "# Daily push of $SADMIN/(lib,bin,/cfg/.*) to all active servers (Optional)" >>$F 
            echo "#   -s To include push of $SADMIN/sys" >> $F
            echo "#   -u To include push of $SADMIN/(usr/bin usr/lib usr/cfg)" >> $F 
            echo "#30 11,20 * * * root ${SADMIN}/bin/sadm_push_sadmin.sh > /dev/null 2>&1" >>$F 
            echo "#" >> $F  
            sadm_write "${BOLD}${YELLOW}Daily Push of SADMIN Scripts added to ${F}${NORMAL}.\n" 
    fi 
    sadm_write "\n" 
    return 0                                                            # Return OK to Caller
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi

# Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

# If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted\n "                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

# If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_write "Script can run only on SADMIN server (${SADM_SERVER})\n."
             sadm_write "Process aborted\n"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Del PID
             exit 1                                                     # Exit To O/S with error
    fi

    adjust_server_crontab                                               # Check sadm_server crontab
    alert_housekeeping                                                  # Prune Alert History File
    if [ $? -eq 0 ]
       then sadm_write "$SADM_OK Alert archiving done.\n"
       else sadm_write "$SADM_ERROR While archiving alert.\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
    fi 
    dir_housekeeping                                                    # Do Dir HouseKeeping
    file_housekeeping                                                   # Do File HouseKeeping

    if [ $ERROR_COUNT -ne 0 ] ; then SADM_EXIT_CODE=1 ; else SADM_EXIT_CODE=0 ; fi
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
