#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_housekeeping.sh
#   Synopsis :  Set Owner/Group, Priv/Protection on www sub-directories and cleanup www/tmp/perf dir.
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# Enhancements/Corrections Version Log
# 2017_07_07    v1.8 Code enhancement
# 2018_05_14    v1.9 Correct problem on MacOS with change owner/group command
# 2018_06_05    v2.0 Added www/tmp/perf removal of *.png files older than 5 days.
# 2018_06_09    v2.1 Add Help and version function, change script name & Change startup order
# 2018_08_28    v2.2 Delete rch and log older than the number of days specified in sadmin.cfg
# 2018_11_29    v2.3 Restructure for performance and don't delete rch/log files anymore.
# 2019_05_19 Update: v2.4 Add server crontab file to housekeeping
# 2020_02_19 Update: v2.5 Restructure & added archiving of old alert history to history archive. 
# 2020_05_23 Update: v2.6 Minor change about reading /etc/environment and change logging messages.
# 2020_12_16 Update: v2.7 Include code to include in SADMIN server crontab the daily report email.
# 2021_05_29 server: v2.8 Code optimization, update SADMIN section and Help screen.
# 2021_07_30 server: v2.9 Solve intermittent error on monitor page.
# 2021_08_17 nolog  v2.10 chmod 1777 $SADM_WWW_TMP_DIR 
# 2022_05_03 server v2.11 Secure email passwd file ($SADMIN/cfg/.gmpw).
# 2022_07_13 server v2.12 Fix typo that was preventing script from running under certain condition.
# 2023_04_17 server v2.13 Secure permission on email password files ($SADMIN/cfg/.gmpw & .gmpw64).
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT ^C
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
export SADM_VER='2.13'                                     # Script version number
export SADM_PDESC="Set owner,group,permission on www sub-directories and archive old alerts."
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
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
# ---------------------------------------------------------------------------------------





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT            # Error Counter
ARC_DAYS=7                                  ; export ARC_DAYS               # ALert Age to move
export SADM_TEN_DASH=`printf %10s |tr " " "-"`                              # 10 dashes line



# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
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
                then sadm_writelog "Error occurred on 'chmod' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             sadm_writelog "Change chmod gou-s $VAL_DIR"
             chmod gou-s $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occurred on 'chmod' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             sadm_writelog "Change $VAL_DIR owner to ${VAL_OWNER}.${VAL_GROUP}"
             chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occurred on 'chown' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
    fi
    return $RETURN_CODE
}



# --------------------------------------------------------------------------------------------------
# Move Alert older than 30 days from $SADMIN/cfg/alert_history.txt to $SADMIN/cfg/alert_archive.txt
# --------------------------------------------------------------------------------------------------
alert_housekeeping()
{
    sadm_writelog "Move Alert older than $ARC_DAYS days to the alert history file." 
    sadm_writelog "Move from $SADM_ALERT_HIST to $SADM_ALERT_ARC file."

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
    sadm_write "Server Directories HouseKeeping.\n"

    # Reset privilege on WWW Directory files
    if [ -d "$SADM_WWW_DIR" ]
        then CMD="find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \;"
             find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
             fi
             CMD="find $SADM_WWW_DIR -exec chown -R ${SADM_WWW_USER}:${SADM_GROUP} {} \;"
             find $SADM_WWW_DIR -exec chown -R ${SADM_WWW_USER}:${SADM_GROUP} {} \;>/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] running ${CMD}"
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
    sadm_write "Server Files HouseKeeping.\n"

    # Make sure crontab for SADMIN server have proper permission and owner
    sadm_writelog "Make sure SADMIN crontab file have proper permission and owner"
    afile="/etc/cron.d/sadm_server"
    if [ -f "$afile" ]
        then CMD="chmod 0644 $afile && chown root:root $afile"
             chmod 0644 $afile && chown root:root $afile 
             if [ $? -ne 0 ]
                then sadm_write "[ ERROR ] running ${CMD}\n"
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
                then sadm_write "[ ERROR ] running ${CMD}\n"
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
                then sadm_write "[ ERROR ] running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} running ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
    fi

    # Set Permission on all files in the images directory.
    sadm_write "\n"
    sadm_write "Setting permissions in the website directories.\n"
    CMD="find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \;"
    find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running $CMD \n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.php files 
    CMD="find $SADM_WWW_DIR -type f -name '*.php' -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name '*.php' -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.css files 
    CMD="find $SADM_WWW_DIR -type f -name '*.css' -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name '*.css' -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running ${CMD}\n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.js files 
    CMD="find $SADM_WWW_DIR -type f -name '*.js' -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name '*.js' -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "$SADM_ERROR running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running $CMD \n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.rrd files 
    CMD="find $SADM_WWW_DIR -type f -name '*.rrd' -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name '*.rrd' -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "[ ERROR ] running ${CMD}\n"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_write "${SADM_OK} running $CMD \n"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at $ERROR_COUNT \n" ;fi
    fi

    # Set Permission on all *.pdf files 
    CMD="find $SADM_WWW_DIR -type f -name '*.pdf' -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name '*.pdf' -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write "[ ERROR ] running ${CMD}\n"
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
             sadm_write "Delete any *.png files older than 5 days in ${SADM_WWW_PERF_DIR}.\n"
             CMD="find $SADM_WWW_PERF_DIR -type f -mtime +5 -name '*.png' -exec rm -f {} \;"
             find $SADM_WWW_PERF_DIR -type f -mtime +5 -name "*.png" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] running ${CMD}\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK} running ${CMD}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
    fi

    # $SADMIN/www/tmp writable by everyone (If not cause intermittent problem with monitor page refresh)
    chmod 1777 $SADM_WWW_TMP_DIR  

    if [ -f "$DBPASSFILE" ]     ; then chmod 644 $DBPASSFILE ; fi 
    if [ -f "$GMPW_FILE_TXT" ]  ; then chmod 644 $GMPW_FILE_TXT ; fi 
    if [ -f "$GMPW_FILE_B64" ]  ; then chmod 644 $GMPW_FILE_B64 ; fi 
    
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
# This function make sure that the SADMIN server contains latest scripts version that was added.
# --------------------------------------------------------------------------------------------------
function adjust_server_crontab()
{
    # Make sure the Daily Email Report is in the SADMIN server crontab.
    F="/etc/cron.d/sadm_server"
    grep -q 'sadm_daily_report.sh' "$F" 
    if [ $? -ne 0 ] 
       then echo "#" >> $F 
            echo "# SADMIN Daily Email Report about Scripts, ReaR and Daily Backup" >> $F 
            echo "04 07 * * * root $SADMIN/bin/sadm_daily_report.sh > /dev/null 2>&1" >> $F 
            echo "#" >> $F  
            sadm_write "${BOLD}${YELLOW}Daily Email Report added to ${F}${NORMAL}.\n" 
    fi 

    # Create cron entry to push server $SADMIN/bin $SADMIN/lib $SADMIN/.*.cfg to all actives clients.
    # -s To include push of $SADMIN/sys
    # -u To include push of $SADMIN/(usr/bin usr/lib usr/cfg) 
    F="/etc/cron.d/sadm_server"
    grep -q 'sadm_push_sadmin.sh' $F 
    if [ $? -ne 0 ] 
       then echo "#" >> $F 
            echo "# Daily push of $SADMIN/\(lib,bin,/cfg/\.\*\) to all active servers - Optional" >>$F 
            echo "#   -s To include push of $SADMIN/sys" >> $F
            echo "#   -u To include push of $SADMIN/\(usr/bin usr/lib usr/cfg\)" >> $F 
            echo "#30 11,20 * * * root ${SADMIN}/bin/sadm_push_sadmin.sh > /dev/null 2>&1" >>$F 
            echo "#" >> $F  
            sadm_write "${BOLD}${YELLOW}Daily Push of SADMIN Scripts added to ${F}${NORMAL}.\n" 
    fi 
    sadm_write_log " " 
    return 0                                                            # Return OK to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                            
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
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------

    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    adjust_server_crontab                                               # Check sadm_server crontab
    alert_housekeeping                                                  # Prune Alert History File
    if [ $? -eq 0 ]
       then sadm_write_log "[ OK ] Alert archiving done."
       else sadm_write_err "[ ERROR ] While archiving alert."
            ERROR_COUNT=$(($ERROR_COUNT+1))
    fi 
    dir_housekeeping                                                    # Do Dir HouseKeeping
    file_housekeeping                                                   # Do File HouseKeeping

    if [ $ERROR_COUNT -ne 0 ] ; then SADM_EXIT_CODE=1 ; else SADM_EXIT_CODE=0 ; fi
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
