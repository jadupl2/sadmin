#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_housekeeping.sh
#   Synopsis :  Set Owner/Group, Priv/Protection on www sub-directories and cleanup www/tmp/perf dir.
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2017_07_07 server v1.08 Code enhancement
# 2018_05_14 server v1.09 Correct problem on MacOS with change owner/group command
# 2018_06_05 server v2.00 Added www/tmp/perf removal of *.png files older than 5 days.
# 2018_06_09 server v2.01 Add Help and version function, change script name & Change startup order
# 2018_08_28 server v2.02 Delete rch and log older than the number of days specified in sadmin.cfg
# 2018_11_29 server v2.03 Restructure for performance and don't delete rch/log files anymore.
# 2019_05_19 server v2.04 Add server crontab file to housekeeping
# 2020_02_19 server v2.05 Restructure & added archiving of old alert history to history archive. 
# 2020_05_23 server v2.06 Minor change about reading /etc/environment and change logging messages.
# 2020_12_16 server v2.07 Include code to include in SADMIN server crontab the daily report email.
# 2021_05_29 server v2.08 Code optimization, update SADMIN section and Help screen.
# 2021_07_30 server v2.09 Solve intermittent error on monitor page.
# 2021_08_17 nolog  v2.10 chmod 1777 $SADM_WWW_TMP_DIR 
# 2022_05_03 server v2.11 Secure email passwd file ($SADMIN/cfg/.gmpw).
# 2022_07_13 server v2.12 Fix typo that was preventing script from running under certain condition.
# 2023_04_17 server v2.13 Secure permission on email password files ($SADMIN/cfg/.gmpw & .gmpw64).
# 2023_09_17 server v2.14 Add removal of file older than 1 day in $SADMIN/www/tmp directory.
# 2023_12_20 server v2.15 If Daily report line still in sadm_server crontab, remove it (depreciated).
# 2023_12_24 server v2.16 Code optimization and minor bug fix.
# 2024_04_02 server v2.17 Change 'sadm_write' to 'sadm_write_log'.
#@2024_04_15 server v2.18 Fix problem when moving lines from alert history to alert archive file.
#@2024_04_22 server v2.19 Alert older than '$SADM_DAYS_HISTORY' defined in sadmin.cfg are archived.
#@2024_04_22 server v2.20 Trim the alert archive file to '$SADM_MAX_ARC_LINE' defined in sadmin.cfg.
#@2024_05_15 server v2.21 Correct a typo that was causing the script to crash.
#@2024_10_31 server v2.22 Fix "$SADMIN/www/tmp/perf" permission (prevent to view performance graph).
#@2024_12_17 server v2.23 Code revision and optimization.
#@2025_01_04 server v2.24 Also apply removal policy of old .rch, log and *.nmon  in $SADMIN/www/dat.
#@2025_04_01 server v2.25 Delete any *.lock older than 1 day in $SADMIN.
#@2026_02_07 server v2.26 Code enhancement.
#@2026_03_09 server v2.27 Change Owner of Database backup.
#@2026_03_12 server v2.28 Special chown & chmod for $SADMIN/dat/dbb (Database backup)
#@2026_08_25 server v2.29 Enhance archiving portion, Update to secttion 1.60,
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT ^C
#set -x



# ---------   S T A R T   O F   S A D M I N   R E Q U I R E D   C O D E   S E C T I O N  -----------
# v1.60 - Setup Global Variables and load the SADMIN standard library $SADMIN/lib/sadmlib_std.sh.
#       - To use SADMIN scripting tools, this section MUST be present near the top of your code.    
#
# Make sure environment variable 'SADMIN' is defined, if it's not, exit with error message.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\n[ ERROR ] Set 'SADMIN' environment variable to the install directory." 
        printf "\n  - Add a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 
fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\n[ ERROR ] SADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 
fi 


# SADMIN Section of your program that is shared with SADMIN Bash Library.
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s|tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.
export SADM_DEBUG=0                                        # Debug Level(0-9), 0 = NoDebug
export SADM_EXIT_CODE=0                                    # Pgm. Default Exit Code
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)

export SADM_VER='2.29'                                     # Script version number
export SADM_DESC="Archive old alert to alert archive file and set permission in www directories."
export SADM_ROOT_ONLY="Y"                                  # Pgm. run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Pgm. run only on SADMIN server? [Y]/[N]
export SADM_GROUP_ONLY='N'                                 # Pgm. run only if usr part of SADMIN Grp
export SADM_MULTIPLE_EXEC="N"                              # Can Run Simultaneous copy of script Y/N
export SADM_QUIET="N"                                      # Y=HideMsg & Error#  N=Show Msg & Error#
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Append log ? Y=AppendLog,N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y = ProduceLogHeader, N = NoLogHeader
export SADM_LOG_FOOTER="Y"                                 # Y = ProduceLogFooter, N = NoLogFooter
export SADM_USE_RCH="Y"                                    # Update the RCH History File (Y/N)
export SADM_ERRMSG=""                                      # Error Message returned by Library 
export SADM_ERRNO=0                                        # Error number (0=OK) returned by Library
export SADM_PID_TIMEOUT=7200                               # Sec. before PID file is remove,7200=2hr
export SADM_LOCK_TIMEOUT=3600                              # Sec. before System LockFile is Del, 1hr
export SADM_DB_USED="N"                                    # Use or Not, Got to be on SADMIN server
export SADM_DB_NAME="sadmin"                               # Database Name SADM_DBNAME in sadmin.cfg
export SADM_TMP_FILE1=$(mktemp -q "$SADMIN/tmp/sadm_tmp1_XXX") # Make tmpfile1, rm in sadm_stop()
export SADM_TMP_FILE2=$(mktemp -q "$SADMIN/tmp/sadm_tmp2_XXX") # Make tmpfile2, rm in sadm_stop()
export SADM_TMP_FILE3=$(mktemp -q "$SADMIN/tmp/sadm_tmp3_XXX") # Make tmpfile3, rm in sadm_stop()

# Load SADMIN Bash Shell Library, ready to  be used.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Init SADMIN tools, load cfg files

# Example of some functions and variable you can use.
export SADM_OS_NAME=$(sadm_get_osname)                     # REDHAT,ROCKY,ALMA,CENTOS,DEBIAN,UBUNTU.
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# Variables Below Are Taken From SADMIN Configuration File (sadmin.cfg) when the Library is loaded.
# You Can Overridde them On A Per Program Basis (If Needed).
export SADM_ALERT_TYPE=3                                   # 0=NoAlert 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Error Group Define in alert_group.cfg
#export SADM_WARNING_GROUP="default"                        # Warning Alert Group (alert_group.cfg)   
#export SADM_INFO_GROUP="default"                           # Info Alert Group (in alert_group.cfg)
#export SADM_ALERT_REPEAT=0                                 # 0=No Alert Repeat, Sec. between Repeat
#export SADM_MAIL_ADDR="your_email@domain.com"              # Send email to...default in sadmin.cfg
#export SADM_MAX_LOGLINE=400                                # Nb of Lines to trim (0=NoTrim)
#export SADM_MAX_RCHLINE=35                                 # Nb of Lines to trim (0=NoTrim)
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
export ERROR_COUNT=0                                                    # Error Counter





# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" "$(basename "$0")" "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_DESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n   ${BOLD}${YELLOW}[-X]${NORMAL}\t\t\tRemove the PID file & run script"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
# Move alert older than $SADM_DAYS_HISTORY days in $SADMIN/cfg/sadmin.cfg,
# from $SADMIN/cfg/alert_history.txt to $SADMIN/cfg/alert_archive.txt
# --------------------------------------------------------------------------------------------------
alert_archiving()
{
    sadm_write_log "---------------------------"
    sadm_write_log "Archiving Alerts "
    sadm_write_log "---------------------------"

    # If Alert archive file doesn't exist, create it (Make Alert History & Archive exists)
    if [ ! -f "$SADM_ALERT_ARC" ]                                       # If Archive file not found
        then sadm_write_log "Archive Alert file doesn't exist '$SADM_ALERT_ARC'." 
             if [ -f $SADM_ALERT_ARCINI ]                               # Alert arc. template exist 
                then sadm_write_log "Using Alert Archive Template to create the initial archive." 
                     sadm_write_log "cp $SADM_ALERT_ARCINI $SADM_ALERT_ARC" 
                     cp -v $SADM_ALERT_ARCINI $SADM_ALERT_ARC           # Use alert archive template
                else sadm_write_log "No Archive Alert template either, creating an empty archive." 
                     sadm_write_log "touch $SADM_ALERT_ARC" 
                     touch $SADM_ALERT_ARC                              # Alert Archive file
                     touch $SADM_ALERT_INI                              # Alert history template
             fi 
    fi 
    chmod 664 $SADM_ALERT_ARC 
    chown $SADM_USER:$SADM_GROUP $SADM_ALERT_ARC

    # Summary before start Archiving
    sadm_write_log "As define by 'SADM_DAYS_HISTORY' variable in '$SADM_CFG_FILE'."
    sadm_write_log "We will be moving alerts older than $SADM_DAYS_HISTORY days to the alert archive."
    history_alert_count="$(grep -viE "^#|^$" $SADM_ALERT_HIST | wc -l | cut -d' ' -f1)"
    sadm_write_log "Actual Alert History File '$SADM_ALERT_HIST' have $history_alert_count alerts."
    archive_alert_count="$(grep -viE "^#|^$" $SADM_ALERT_ARC | wc -l | cut -d' ' -f1)"
    sadm_write_log "Actual Alert Archive File '$SADM_ALERT_ARC' have $archive_alert_count lines."

    # Create file that will eventually become the New Alert History File after the move
    cp $SADM_ALERT_HINI $SADM_TMP_FILE3                                 # Create tmp Initial History
     
    # Calculate the epoch time (now - $SADM_DAYS_HISTORY * 86400) so we know alert older than $SADM_DAYS_HISTORY.
    current_epoch=$(sadm_get_epoch_time)                                # Get Current Epoch
    alert_age=$(( $SADM_DAYS_HISTORY * 86400 ))                         # Alert Age (86400 sec=1day)
    archive_epoch=$(( $current_epoch - $alert_age ))                    # Calculate archive epoch 
    if [ "$SADM_DEBUG" -gt 4 ] 
        then sadm_writelog "Current epoch time   : '$current_epoch'."
             sadm_writelog "Epoch $SADM_DAYS_HISTORY days ago   : '$archive_epoch'."
             sadm_writelog "Alert older than this epoch time ($archive_epoch), are moved to the alert archive file."
    fi 

    # Read Alert History file line by line
    # Example of a line in alert history file
    # 1654542300;01;15:05;2022.06.06;E;borg;mail_sysadmin;borg.maison.ca unresponsive (Can't SSH to it);;20220606_1505
    move_count=0                                                        # Count moved alerts to Arch
    while read line  ; 
        do
        if [[ "$SADM_DEBUG" -gt 0 ]] ; then sadm_write_log "Alert = '$line'" ; fi 
        if [[ "$line" =~ ^[[:space:]]*# ]] ; then continue ; fi         # Skip blank or comment line
        num=$(echo $line | awk -F\; '{ print $1 }')                     # Get Current Alert Epoch
        alert_epoch=$(echo "$num" | grep -E ^\-?[0-9]?\.?[0-9]+$)       # Is epoch line is Numeric ?
        if [[ "$alert_epoch" = "" ]] ; then continue ; fi               # No it's not numeric, skip

        # If current alert epoch time is before the epoch archive calculated value.
        if [ $alert_epoch -lt $archive_epoch ]                          # Alert older than ArchEpoch
            then echo $line >> $SADM_ALERT_ARC                          # Append to Alert Archive
                 ((move_count++))                                       # Alert move to ArchiveCount
                 ldate=$(echo $line | awk -F\; '{ print $4 }')          # Extract Alert Date
                 ltime=$(echo $line | awk -F\; '{ print $3 }')          # Extract Alert Time
                 lhost=$(echo $line | awk -F\; '{ print $6 }')          # Extract Alert Host
                 lmess=$(echo $line | awk -F\; '{ print $8 }')          # Extract Error Mess
                 if [ "$SADM_DEBUG" -gt 4 ] ;then sadm_write_log "Archive: $ldate $ltime $lhost $lmess" ;fi
            else echo $line >> $SADM_TMP_FILE3                          # Keep Line in new History
                 if [ "$SADM_DEBUG" -gt 5 ] ;then sadm_write_log "Alert not old enough : $line" ;fi
        fi 
        done < $SADM_ALERT_HIST
    
    # Show actual number of alert in Alert History file (Short Term)
    sadm_write_log " "
    sadm_write_log "Number of alert moved to Archive is ${move_count}."
    history_alert_count="$(grep -viE "^#|^$" $SADM_TMP_FILE3 | wc -l | cut -d' ' -f1)"
    sadm_write_log "Actual Alert History File '$SADM_ALERT_HIST' have $history_alert_count alerts."

    # Show actual number of lines in Alert Archive file (Long Term)
    archive_alert_count="$(grep -viE "^#|^$" $SADM_ALERT_ARC | wc -l | cut -d' ' -f1)"
    sadm_write_log "Actual Alert Archive File '$SADM_ALERT_ARC' have $archive_alert_count lines."

    # Replace current history file by the tmp just created.
    cat $SADM_ALERT_INI $SADM_TMP_FILE3 > $SADM_ALERT_HIST              # Creatingh New history file
    chmod 664 $SADM_ALERT_HIST                                          # Set history permission
    chown $SADM_USER:$SADM_GROUP $SADM_ALERT_HIST                       # Set Owner:Group of History

    # Trim alert archive files to $SADM_MAX_ARC_LINE
    sadm_write_log " "
    sadm_write_log "As specified in '$SADM_CFG_FILE' by the value in 'SADM_MAX_ARC_LINE'." 
    sadm_write_log "We are trimming the archive file to $SADM_MAX_ARC_LINE lines." 
    sadm_trimfile "$SADM_ALERT_ARC" "$SADM_MAX_ARC_LINE"

    return
}



# --------------------------------------------------------------------------------------------------
# Function that set the Owner/Group and Privilege of the Filename received.
# --------------------------------------------------------------------------------------------------
set_file()
{
    VAL_FILE=$1                                                         # Directory Name
    VAL_OCTAL=$2                                                        # chmod octal value
    VAL_OWNER=$3                                                        # Directory Owner 
    VAL_GROUP=$4                                                        # Directory Group name
    RETURN_CODE=0                                                       # Reset Error Counter

    # Check if file to change exist 
    if [[ ! -f "$VAL_FILE" ]]                                           # If file do not exist
        then sadm_write_err "[ ERROR ] File '$VAL_FILE' do not exist."
             return 1                                                   # Return error to caller
    fi                      

    CMD="chmod ${VAL_OCTAL} ${VAL_FILE}"                                # Chmod to value received 
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save Exit Code 
    if [ $RC -eq 0 ]                                                    # Complete with no Error ?
        then sadm_write_log "[ OK ] $CMD" 
        else sadm_write_err "[ ERROR ] $CMD"
             ((RETURN_CODE++))
    fi 

    CMD="chown ${VAL_OWNER}:${VAL_GROUP} ${VAL_FILE}"                   # Change Owner:Group 
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save Exit Code 
    if [ $RC -eq 0 ]                                                    # Complete with no Error ?
        then sadm_write_log "[ OK ] $CMD" 
        else sadm_write_err "[ ERROR ] $CMD"
             ((RETURN_CODE++))
    fi 

    return $RETURN_CODE
}


# --------------------------------------------------------------------------------------------------
#                               General Directories Housekeeping Function
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_write_log ""
    sadm_write_log ""
    sadm_write_log "-------------------------------"
    sadm_write_log "Server Directories Housekeeping"
    sadm_write_log "-------------------------------"

    # Check if $SADMIN/www exist
    if [ ! -d "$SADM_WWW_DIR" ]                                         # If doesn't exist
        then sadm_write_err "[ ERROR ] Directory '$SADM_WWW_DIR' doesn't exist ?" 
             sadm_write_err "[ ERROR ] You may not be on the SADMIN server." 
             return 1
    fi 

    # All directories in $SADMIN/www must be 775 
    CMD="find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \;"
    find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_write_err "[ ERROR ] running ${CMD}"
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error at $ERROR_COUNT" ;fi
    fi

    # ALL Directories $SADMIN/www must be own by SADM_WWW_USER:SADM_GROUP
    CMD="find $SADM_WWW_DIR -type d -exec chown ${SADM_WWW_USER}:${SADM_GROUP} {} \; "
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -eq 0 ]                                                    # Complete with no Error ?
        then sadm_write_log "[ OK ] $CMD" 
        else sadm_write_err "[ ERROR ] $CMD"
             ((ERROR_COUNT++))
    fi 

    CMD="find $SADM_WWW_DIR -type f -exec chown $SADM_WWW_USER:$SADM_GROUP {} \;"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -eq 0 ]                                                    # Complete with no Error ?
        then sadm_write_log "[ OK ] $CMD" 
        else sadm_write_err "[ ERROR ] $CMD"
             ((ERROR_COUNT++))
    fi 

    # Change Permission and Owner on $SADMIN/www/tmp
    CMD="chown ${SADM_WWW_USER}:${SADM_GROUP} $SADM_WWW_TMP_DIR && chmod 1777 '$SADM_WWW_TMP_DIR'"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -eq 0 ]                                                    # Complete with no Error ?
        then sadm_write_log "[ OK ] $CMD" 
        else sadm_write_err "[ ERROR ] $CMD"
             ((ERROR_COUNT++))
    fi 
  
    # Change Permission and Owner on $SADMIN/www/tmp/perf
    CMD="chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_PERF_DIR && chmod 1777 '$SADM_WWW_PERF_DIR'" 
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -ne 0 ]                                                    # Complete with no Error ?
       then sadm_write_err "[ ERROR ] running ${CMD}"
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
    fi
    

    # Change permission on all files in $SADMIN/www/dat to 664
    CMD="find $SADM_WWW_DAT_DIR -type f -exec chmod 0664 {} \;"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -ne 0 ]                                                    # Complete with no Error ?
       then sadm_write_err "[ ERROR ] running ${CMD}."
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
    fi
    
    
    # Database Backup : Change permission on all files in $SADMIN/dat/dbb to 664
    CMD="find $SADM_DBB_DIR -type f -exec chmod 0664 {} \;"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -ne 0 ]                                                    # Complete with no Error ?
       then sadm_write_err "[ ERROR ] running ${CMD}"
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
    fi
    
    # Database Backup : Make sure all files belongs to "$SADM_USER:$SADM_GROUP" define in sadmin.cfg
    CMD="find $SADM_DBB_DIR -type f -exec chown $SADM_USER:$SADM_GROUP {} \;"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -ne 0 ]                                                    # Complete with no Error ?
       then sadm_write_err "[ ERROR ] running ${CMD}"
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
    fi

    # Database Backup : Change permission on directories in $SADMIN/dat/dbb to 775
    CMD="find $SADM_DBB_DIR -type d -exec chmod 0775 {} \;"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -ne 0 ]                                                    # Complete with no Error ?
       then sadm_write_err "[ ERROR ] running ${CMD}"
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
    fi
        
   
    # Database Backup : Make sure all backup directories belong to "$SADM_USER:$SADM_GROUP" 
    CMD="find $SADM_DBB_DIR -type d -exec chown $SADM_USER:$SADM_GROUP {} \;"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    RC=$?                                                               # Save rsync Exit Code 
    if [ $RC -ne 0 ]                                                    # Complete with no Error ?
       then sadm_write_err "[ ERROR ] running ${CMD}"
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
    fi

    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total error count at ${ERROR_COUNT}." ;fi
    return $ERROR_COUNT
}






# --------------------------------------------------------------------------------------------------
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
files_housekeeping()
{
    sadm_write_log " "
    sadm_write_log " "
    sadm_write_log "-------------------------------"
    sadm_write_log "Server Files Housekeeping"
    sadm_write_log "-------------------------------"

    # Make sure crontab for SADMIN server have proper permission and owner
    sadm_write_log "Make sure SADMIN crontab file have proper permission and owner"
    set_file "/etc/cron.d/sadm_client"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_server"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_osupdate"     "0644" "root" "root"
    set_file "/etc/cron.d/sadm_backup"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_rear_backup"  "0644" "root" "root"
    set_file "/etc/cron.d/sadm_vm"           "0644" "root" "root"


    sadm_write_log " "
    sadm_write_log " "
    sadm_write_log "-------------------------------"
    sadm_write_log "Server Files Pruning"
    sadm_write_log "-------------------------------"

    # Delete performance graph (*.png) generated by web interface older than 5 days.
    if [ -d "$SADM_WWW_PERF_DIR" ]
        then sadm_write_log " "
             sadm_write_log "Remove any temporary graph generated (*.png) older than 5 days in ${SADM_WWW_PERF_DIR}."
             CMD="find $SADM_WWW_PERF_DIR -type f -mtime +5 -name '*.png' -exec rm -f {} \;"
             f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
             if [ $RC -ne 0 ]                                           # Complete with no Error ?
                then sadm_write_err "[ ERROR ] running ${CMD}"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] ${CMD}"
             fi             
    fi


    # Delete tmp files older than 1 day in $SADMIN/www/tmp
    if [ -d "$SADM_WWW_TMP_DIR" ]
        then sadm_write_log " "
             sadm_write_log "Remove tmp files older than 1 day in ${SADM_WWW_TMP_DIR}."
             CMD="find $SADM_WWW_TMP_DIR -type f -mtime +1 -exec rm -f {} \;"
             f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
             if [ $RC -ne 0 ]                                           # Complete with no Error ?
                then sadm_write_err "[ ERROR ] running ${CMD}"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] ${CMD}"
             fi             
    fi 


    # Remove *.rch files older than ${SADM_RCH_KEEPDAYS} days (in sadmin.cfg) in $SADMIN/dat/rch.
    if [[ -d "$SADM_WWW_DAT_DIR" ]]
        then 

            # Remove *.rch older than ${SADM_RCH_KEEPDAYS} days in $SADMIN/www/dat
            sadm_write_log " "
            sadm_write_log "Remove any *.rch file(s) older than $SADM_RCH_KEEPDAYS days in $SADM_LOG_DIR."
            sadm_write_log "The number of days is set by the variable 'SADM_RCH_KEEPDAYS' in '$SADM_CFG_FILE'."
            CMD="find ${SADM_WWW_DAT_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name \"*.rch\" -exec rm -f {} \;"
            find $SADM_WWW_DAT_DIR -type f -mtime +$SADM_RCH_KEEPDAYS -name "*.rch" -exec ls -l {} \; | nl | tee -a $SADM_LOG
            find $SADM_WWW_DAT_DIR -type f -mtime +$SADM_RCH_KEEPDAYS -name "*.rch" -exec rm -f {} \;
            if [ $? -ne 0 ]
               then sadm_write_err "[ ERROR ] With $CMD"
                    ((ERROR_COUNT++))
               else sadm_write_log "[ OK ] $CMD"
            fi
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi


            # Remove *.log & *.elog files in $SADMIN/www/dat dir. older than $SADM_LOG_KEEPDAYS days
            sadm_write_log " "
            sadm_write_log "Remove any *.log file(s) older than $SADM_LOG_KEEPDAYS days in $SADM_LOG_DIR."
            sadm_write_log "The number of days is set by the variable 'SADM_LOG_KEEPDAYS' in '$SADM_CFG_FILE'."
            CMD="find "$SADM_WWW_DAT_DIR" -type f -mtime +${SADM_LOG_KEEPDAYS} -name \"*.log\" -exec rm -f {} \;"
            find "$SADM_WWW_DAT_DIR" -type f -mtime +$SADM_LOG_KEEPDAYS -name "*.log" -exec ls -l {} \; | nl | tee -a $SADM_LOG
            find "$SADM_WWW_DAT_DIR" -type f -mtime +$SADM_LOG_KEEPDAYS -name "*.log" -exec rm -f {} \; 
            if [ $? -ne 0 ]
               then sadm_write_err "[ ERROR ] $CMD"
                    ((ERROR_COUNT++))
               else sadm_write_log "[ OK ] $CMD"
            fi


            # Remove *.elog files in $SADMIN/www/dat dir. older than $SADM_LOG_KEEPDAYS days
            sadm_write_log " "
            sadm_write_log "Remove any *.elog file(s) older than $SADM_LOG_KEEPDAYS days in $SADM_LOG_DIR."
            sadm_write_log "The number of days is set by the variable 'SADM_LOG_KEEPDAYS' in '$SADM_CFG_FILE'."
            CMD="find "$SADM_WWW_DAT_DIR" -type f -mtime +${SADM_LOG_KEEPDAYS} -name \"*.elog\" -exec rm -f {} \;"
            find "$SADM_WWW_DAT_DIR" -type f -mtime +$SADM_LOG_KEEPDAYS -name "*.elog" -exec ls -l {} \; | nl | tee -a $SADM_LOG
            find "$SADM_WWW_DAT_DIR" -type f -mtime +$SADM_LOG_KEEPDAYS -name "*.elog" -exec rm -f {} \; 
            if [ $? -ne 0 ]
               then sadm_write_err "[ ERROR ] $CMD"
                    ((ERROR_COUNT++))
               else sadm_write_log "[ OK ] $CMD"
            fi


            # Remove *.nmon files in $SADMIN/www/dat dir. older than $SADM_NMON_KEEPDAYS days
            sadm_write_log " "
            sadm_write_log "Remove *.nmon file(s) older than ${SADM_NMON_KEEPDAYS} days in ${SADM_WWW_DAT_DIR}." 
            sadm_write_log "The number of days is set by the variable 'SADM_NMON_KEEPDAYS' in '$SADM_CFG_FILE'."
            CMD="find $SADM_WWW_DAT_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec rm {} \;"
            find $SADM_WWW_DAT_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec ls -l {} \;  | nl | tee -a $SADM_LOG
            find $SADM_WWW_DAT_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec rm {} \; >/dev/null 2>&1
            if [ $? -ne 0 ]
               then sadm_write_err "[ ERROR ] With $CMD"
                    ((ERROR_COUNT++))
               else sadm_write_log "[ OK ] $CMD"
            fi
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi

    fi
    

    # Delete $SADMIN/*.lock files older than 1 days.
    sadm_write_log " "
    sadm_write_log "Delete any lock files older than 1 days in '$SADMIN'."
    CMD="find $SADMIN -name \"*.lock\" -type f -mtime +1 -exec rm -f {} \;"
    f=$(mktemp) ; { eval "$CMD" ; echo $?>$f ; } | tee -a $SADM_LOG 2>&1 ; RC=$(cat $f) 
    if [ $RC -ne 0 ]                                           # Complete with no Error ?
       then sadm_write_err "[ ERROR ] running ${CMD}"
            ((ERROR_COUNT++))
       else sadm_write_log "[ OK ] ${CMD}"
    fi  
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error at $ERROR_COUNT" ;fi
    
    # set 664 on password file on Sadmin server
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
    # If Daily report line still in sadm_server crontab, remove it.
    F="/etc/cron.d/sadm_server"
    grep -q 'sadm_daily_report.sh' "$F" 
    if [ $? -ne 0 ] ; then sed -i '/sadm_daily_report/d' $F ; fi


    # Daily push of /opt/sadmin to all active servers (Optional)
    #   -c To copy $SADMIN/cfg/sadmin_client.cfg to $SADMIN/cfg/sadmin.cfg on all systems.
    #      The 'SADM_HOSTYPE=S' is changed to 'SADM_HOST_TYPE=C' before copy is done to clients. 
    #      Use if you wish to have the same sadmin.cfg on all active systems.
    #   -s To copy $SADMIN/sys to all actives systems.
    #      Use if you wish to have the same startup and shutdown scripts on all systems.
    #   -u To copy $SADMIN/usr/bin, $SADMIN/usr/lib, $SADMIN/usr/cfg to all active systems.
    #   -n Copy SADMIN version to the host name you specify (Do not copy config files).
    #
    F="/etc/cron.d/sadm_server"
    grep -q 'sadm_push_sadmin.sh' $F 
    if [ $? -ne 0 ] 
        then 
cat <<HERE >> $F
#
# Daily push of /opt/sadmin to all active servers (Optional)
#   -c To copy $SADMIN/cfg/sadmin_client.cfg to $SADMIN/cfg/sadmin.cfg on all systems.
#      The 'SADM_HOSTYPE=S' is changed to 'SADM_HOST_TYPE=C' before copy is done to clients. 
#      Use if you wish to have the same sadmin.cfg on all active systems.
#   -s To copy $SADMIN/sys to all actives systems.
#      Use if you wish to have the same startup and shutdown scripts on all systems.
#   -u To copy $SADMIN/usr/bin, $SADMIN/usr/lib, $SADMIN/usr/cfg to all active systems.
#   -n Copy SADMIN version to the host name you specify (Do not copy config files).
30 16 * * * root \${SADMIN}/bin/sadm_push_sadmin.sh > /dev/null 2>&1
#
HERE
      
        sadm_write_log "${BOLD}${YELLOW}Daily Push of SADMIN Scripts added to ${F}${NORMAL}.\n" 
    fi 
    return 0                                                            # Return OK to Caller
}


# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    adjust_server_crontab                                               # Check sadm_server crontab

    alert_archiving                                                     # Prune Alert History File
    if [ $? -eq 0 ]
       then sadm_write_log "[ SUCCESS ] Archiving of alerts done."
       else sadm_write_err "[ ERROR ] While archiving the old alerts."
            ((ERROR_COUNT++)) 
    fi 

    dir_housekeeping                                                    # Do Dir HouseKeeping
    if [ $? -eq 0 ]
       then sadm_write_log "[ SUCCESS ] Directories housekeeping."
       else sadm_write_err "[ ERROR ] While doing directories housekeeping."
            ((ERROR_COUNT++)) 
    fi 

    files_housekeeping                                                   # Do File HouseKeeping
    if [ $? -eq 0 ]
       then sadm_write_log " "
            sadm_write_log "[ SUCCESS ] SADMIN server files housekeeping."
       else sadm_write_log " "
            sadm_write_err "[ ERROR ] While doing the SADMIN server files housekeeping."
            ((ERROR_COUNT++)) 
    fi 

    return $SADM_EXIT_CODE
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# -h) Show Help Usage, -v) Show Script Version,  -d0-9] Set Debug Level  -X=Delete PID file.
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hvX" opt ; do                                      # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=$(echo "$SADM_DEBUG" |grep -E "^\-?[0-9]?\.?[0-9]+$") # Valid if Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nInvalid debug level.\n"                # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
            X) /usr/bin/rm -f "${SADMIN}/tmp/${SADM_INST}.pid" >/dev/null 2>&1
               printf "\n${BOLD}${BLINK}${YELLOW}The PID File ("${SADMIN}/tmp/${SADM_INST}.pid") is now removed.${NORMAL}\n" 
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
    main_process                                                        # Main processing function
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
