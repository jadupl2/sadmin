#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_client_housekeeping.sh
#   Synopsis :  Verify existence of SADMIN Dir. along with their Prot/Priv and purge old log,rch,nmon.
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tool are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
# This code was originally written by Jacques Duplessis <sadmlinux@gmail.com>.
# Developer Web Site : https://sadmin.ca
#   
# --------------------------------------------------------------------------------------------------
# 2017_08_08 client v1.7 Add /sadmin/jac in the housekeeping and change 600 to 644 for configuration file
# 2017-10-10 client v1.8 Remove deletion of release file on sadm client in /sadmin/cfg
# 2018-01-02 client v1.9 Delete file not needed anymore
# 2018_05_14 client v1.10 Correct problem on MacOS with change owner/group command
# 2018_06_04 client v1.11 Add User Directories, Database Backup Directory, New Backup Cfg Files
# 2018_06_05 client v1.12 Enhance Output Display - Add Missing Setup Dir, Review Purge Commands
# 2018_06_09 client v1.13 Add Help and Version Function - Change Startup Order
# 2018_06_13 client v1.14 Change all files in $SADMIN/cfg to 664.
# 2018_07_30 client v1.15 Make sure sadmin crontab files in /etc/cron.d have proper owner & permission.
# 2018_09_16 client v1.16 Include Cleaning of alert files needed only on SADMIN server.
# 2018_09_28 client v1.17 Code Optimize and Cleanup
# 2018_10_27 client v1.18 Remove old dir. not use anymore (if exist)
# 2018_11_02 client v1.19 Code Maint. & Comment
# 2018_11_23 client v1.20 An error is signal when the 'sadmin' account is lock, preventing cron to run.
# 2018_11_24 client v1.21 Check SADM_USER status, give more precise explanation & corrective cmd if lock.
# 2018_12_15 client v1.22 Fix Error Message on MacOS trying to find SADMIN User in /etc/passwd.
# 2018_12_18 client v1.23 Don't delete SADMIN server directories if SADM_HOST_TYPE='D' in sadmin.cfg
# 2018_12_19 client v1.24 Fix typo Error & Enhance log output
# 2018_12_22 client v1.25 Minor change - More Debug info.
# 2019_01_28 client v1.26 Add readme.pdf and readme.html to housekeeping
# 2019_03_03 client v1.27 Make sure .gitkeep files exist in important directories
# 2019_04_17 client v1.28 Make 'sadmin' account & password never expire (Solve Acc. & sudo Lock)
# 2019_05_19 client v1.29 Change for lowercase readme.md,license,changelog.md files and bug fixes.
# 2019_06_03 client v1.30 Include logic to convert RCH file format to the new one, if not done.
# 2019_07_14 client v1.31 Add creation of Directory /preserve/mnt if it doesn't exist (Mac Only)
# 2019_07_23 client v1.32 Remove utilization of history sequence number file.
# 2019_08_19 client v1.33 Check /etc/cron.d/sadm_rear_backup permission & remove /etc/cron.d/rear
# 2019_11_25 client v1.34 Remove deletion of $SADMIN/www on SADMIN client.
# 2020_01_21 client v1.35 Remove alert_group.cfg and alert_slack.cfg, if present in $SADMIN/cfg
# 2020_04_01 client v1.36 Code rewrite for better performance and maintenance. 
# 2020_04_04 client v1.37 Fix minor bugs & Restructure log presentation
# 2020_04_28 client v1.38 Update readme file permission from 0644 to 0664
# 2020_05_08 client v1.39 Update Change permission change on $SADMIN/usr/bin from 0755 to 775.
# 2020_07_10 client v1.40 If no password have been assigned to 'sadmin' a temporary one is assigned. 
# 2020_07_20 client v1.41 Change permission of log and rch to allow normal user to run script.
# 2020_09_10 client v1.42 Make sure permission are ok in user library directory ($SADMIN/usr/lib).
# 2020_09_12 client v1.43 Make sure that "${SADM_UCFG_DIR}/.gitkeep" exist to be part of git clone.
# 2020_09_20 client v1.44 Minor adjustments to log entries.
# 2020_11_07 client v1.45 Remove old rch conversion code execution.
# 2020_12_16 client v1.46 Minor code change (Isolate the check for sadmin user and group)
# 2020_12_26 client v1.47 Doesn't delete Database Password File, cause problem during server setup.
# 2021_05_23 client v1.48 Remove conversion of old history file format (not needed anymore).
# 2021_06_06 client v2.00 Make sure that sadm_client crontab run 'sadm_nmon_watcher.sh' regularly.
# 2021_06_06 client v2.01 Remove script that run 'swatch_nmon.sh' from system monitor config file.
# 2021_06_06 client v2.02 Fix problem related to system monitor file update.
# 2021_06_10 client v2.03 Fix problem removing 'nmon' watcher from monitor file.
# 2021_07_22 client v2.04 Fix problem when run the 1st time during setup script.
# 2022_07_02 client v2.05 Set permission for new gmail passwd file ($SADMIN/cfg/.gmpw)
# 2022_07_13 client v2.06 Update new SADMIN section v1.51 and code revision..
# 2022_09_20 client v2.07 Use SSH port specify per server & update SADMIN section to v1.52.
# 2022_09_24 client v2.08 Change MacOS mount point name (/preserve don't exist anymore)
# 2023_04_10 client v2.09 Remove unencrypted email pwd file ($SADMIN/cfg/.gmpw) on client (not on server).
# 2023_04_16 client v2.10 On client using encrypted email pwd file '$SADMIN/cfg/.gmpw64'.
# 2023_05_02 nolog  v2.11 Solved permission problem on email password file.
# 2023_07_11 client v2.12 Modify sadm_client crontab to use new python 'sadm_nmon_watcher.py'.
# 2023_07_12 client v2.13 Remove duplicated lines in /etc/cron.d/sadm_client file.
# 2023_07_12 client v2.14 If gmail text pwd file '\$SADMIN/cfg/.gmpw' exist, remove it. 
# 2023_09_18 client v2.15 Update SADMIN section (v1.56) and minor improvement.
# 2023_12_22 client v2.16 Added comment within client crontab.
# 2024_04_02 client v2.17 'sadm_write' to 'sadm_write_log' changes.
#@2024_04_05 client v2.18 Remove files that are not needed on SADMIN client.
#@2024_04_16 client v2.19 Replace 'sadm_write' with 'sadm_write_log' and 'sadm_write_err'.
#@2024_05_02 client v2.20 Remove unnecessary file(s) on client.
#@2024_06_13 client v2.21 Verification 'sadmin' account & more cleanup on client.
#@2024_12_17 client v2.22 Add option to auto-generate sadmin user password.
#@2024_12_17 client v2.23 Code optimization, fix minor bugs and add deletion of empty log.
#@2025_04_22 client v2.24 Fix bug concerning verification of 'SADMIN_USER' account expiration.
#@2025_05_26 client v2.25 Enhance log presentation and code optimization.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # INTERCEPT The ^C
#set -x



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.56
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
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
export SADM_VER='2.25'                                      # Script version number
export SADM_PDESC="Set \$SADMIN owner/group/permission, prune old log,rch files ,check sadmin account."
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
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
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
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
export ERROR_COUNT=0                                                    # Error Counter
export LIMIT_DAYS=14                                                    # RCH+LOG Delete after
export DIR_ERROR=0                                                      # ReturnCode = Nb. of Errors
export FILE_ERROR=0                                                     # ReturnCode = Nb. of Errors



# ---------------------             ----------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
#  Set 'sadmin' user with a new generated password & account standard setting. 
# --------------------------------------------------------------------------------------------------
generate_password()
{
    chage -m 0 -M 30 -W 10 -E -1 -I -1 $SADM_USER              # Setup standard for sadmin
    random_pwd=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16; echo)  # Generate random pwd
    echo "${SADM_USER}:${random_pwd}" | chpasswd >> "$SADM_LOG" 2>&1 # Assign pwd to sadmin
    if [ $? -ne 0 ] 
       then sadm_write_err "[ ERROR ] ${SADM_USER}:${random_pwd} |chpasswd " 
            ((error_counter++))                                # Increment Error by 1
            return $error_counter 
    fi 

#    random_pwd=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16; echo)     # Generate random password
#    echo "${SADM_USER}:${random_pwd}" | chpasswd >> "$SADM_LOG" 2>&1    # Assign password to user
#    passwd -u   $SADM_USER   >> $SADM_LOG 2>&1                          # Unlock user. 
#    chage -m 5  $SADM_USER                                              # 5 days before change again
#    chage -M 90 $SADM_USER                                              # password valid for 90 days
#    chage -W 10 $SADM_USER                                              # Warn 10 days before expire
#    chage -E -1 $SADM_USER                                              # Account expires to never
#    chage -I -1 $SADM_USER                                              # Password inactive to never
    sadm_write_log "  - Value of 'SADM_PWD_RANDOM' is set to 'Y' in sadmin.cfg." 
    sadm_write_log "  - Random password generation is activated for user '$SADM_USER'." 
    sadm_write_log "  - A new random password have been assigned to user '${SADM_USER}'."
}




# --------------------------------------------------------------------------------------------------
#             Check Daily if sadmin Account is lock (Disabling crontab script to work) 
# --------------------------------------------------------------------------------------------------
check_sadmin_account()
{
    sadm_write_log "Verifying '$SADM_USER' account status"

    # (MacOS) - Don't execute this function under MacOS (Not coded yet)
    if [ "$SADM_OS_TYPE" = "DARWIN" ] 
        then sadm_write_err "[ WARNING ] No check of user '$SADM_USER' for the moment on MacOS."
             return 0 
    fi 

    # '$SADM_GROUP' group define in sadmin.cfg, should exist in O/S, if not advise user & abort
    grep "^${SADM_GROUP}:"  /etc/group >/dev/null 2>&1                  # $SADMIN Group defined ?
    if [ $? -ne 0 ]                                                     # SADM_GROUP not Defined
       then sadm_write_err "[ ERROR ] Group '$SADM_GROUP' not present." # Advise user will create
            sadm_write_err "Create group or change 'SADM_GROUP' value in $SADMIN/sadmin.cfg."
            sadm_write_err "Process Aborted."                           # Abort got be created
            ((error_counter++))                                         # Increment Error by 1
            return $error_counter 
    fi
    
    # '$SADM_USER' user account should exist. 
    grep "^${SADM_USER}:" /etc/passwd >/dev/null 2>&1                   # $SADMIN User Defined ?
    if [ $? -ne 0 ]                                                     # OH Not There
       then sadm_write_err "[ ERROR ] User '$SADM_USER' not present."   # SADM_USER not found
            sadm_write_err "Create user or change 'SADM_USER' value in $SADMIN/sadmin.cfg."
            sadm_write_err "Process Aborted."                           # Abort got be created
            ((error_counter++))                                         # Increment Error by 1
            return $error_counter 
    fi
    
    # (AIX) - Check if sadmin Aix account is part of the users lock list.
    if [ "$SADM_OS_TYPE"  = "AIX" ]
        then lsuser -a account_locked $SADM_USER | grep -i 'true' >/dev/null 2>&1
             if [ $? -eq 0 ] 
                then sadm_write_err "[ ERROR ] Account $SADM_USER is lock and need attention."
                     sadm_write_err "  - Please check and unlock it with these commands ; "
                     sadm_write_err "   - chsec -f /etc/security/lastlog -a 'unsuccessful_login_count=0' -s $SADM_USER "
                     sadm_write_err "   - chuser 'account_locked=false' $SADM_USER "
                     ((error_counter++))                                # Increment Error by 1
                     return $error_counter 
             fi
    fi


    # User have chosen to have 'sadmin' user password ($SADM_PWD_RANDOM in sadmin.cfg) change daily.
    # The password set will be unknow to user (Use 'sudo'or 'su' cmd to access account).
    # 
    # We recommend using ssh key authentication mode to connect directly.
    # -m 0  = Set the minimum number of days between password changes (0 = no minimum).
    # -M 90 = Set the maximum number of days during which a password is valid (90 Days).
    # -W 14 = Number of days of warning before a password change is required (14 Days).
    # -E -1 = Set the date or number of days since January 1, 1970 on which the user's account 
    #         will no longer be accessible.
    #         Passing the number -1 as the EXPIRE_DATE will remove an account expiration date.
    # -I 100  Set the number of days of inactivity after a password has expired before the 
    #         account is locked. -1= Will not check, never locked.
    #

    # Set Standard for the SADMIN Account
    if [ "$(sadm_get_ostype)" = "LINUX" ] ; then chage -m 0 -M 90 -W 14 -E -1 -I 100 $SADM_USER ; fi 


    if [ "$SADM_PWD_RANDOM" = "Y" ]                                     # If user want new pwd daily
        then random_pwd=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16; echo)  # Generate random pwd
             echo "${SADM_USER}:${random_pwd}" | chpasswd               # Assign pwd to sadmin
             if [ $? -ne 0 ] 
                then sadm_write_err "[ ERROR ] ${SADM_USER}:${random_pwd} |chpasswd " 
                     ((error_counter++))                                # Increment Error by 1
                     return $error_counter 
             fi 
             passwd -u $SADM_USER   >/dev/null 2>&1                     # MakeSure acc. is unlock
             if [ $? -ne 0 ] ; then sadm_write_err "[ ERROR ] passwd -u $SADM_USER" ; return 1 ; fi 
             if [ "$SADM_DEBUG" -ne 0 ] 
                 then sadm_write_log "  - 'SADM_PWD_RANDOM' is set to 'Y' in SADMIN config file."
             fi
             sadm_write_log "  - Random password generation is activated for user '$SADM_USER'." 
             sadm_write_log "  - A new random password have been assigned to user '${SADM_USER}'."
             return $error_counter                                      # Error counter to caller
    fi 


    # Check if sadmin account is lock.
    # 'passwd -S sadmin', display account status information. 
    # The status information consists of 7 fields. 
    #   1-  The first field is the user's login name. 
    #   2-  The second field indicates if the user account has a locked password (L or LK), 
    #       has no password (NP),or has a usable password (P), and (PS) password set.
    #   3-  The third field is the date of the last password change. 
    #   4-7 The next four fields are the minimum age, maximum age, warning period, and inactivity 
    #       period for the password. These ages are expressed in days.
    #
    # Example : passwd -S sadmin
    #    sadmin P 1970-01-01 0 99999 7 -1
    #
    error_counter=0
    sadm_write_log "Check if user '$SADM_USER' is lock." 
    acc_status=$(passwd -S $SADM_USER | awk '{ print $2 }')             # Get Account status
    case $acc_status in
        L|LK)   sadm_write_err "  - Account '$SADM_USER' is lock with status '$acc_status'." 
                if [ "$SADM_PWD_RANDOM" = "Y" ]                         # If random passwd needed
                    then generate_password                              # Generate random passwd
                         if [ $? -ne 0 ]                                # Error generating password
                             then sadm_write_err "[ ERROR ] Error generating $SADM_USER password."
                                  sadm_write_err "User '$SADM_USER' require attention, check aging."
                                  chage -l $SADM_USER >> $SADM_LOG 2>&1
                                  ((error_counter++))                   # Increment Error by 1
                         fi 
                    else ((error_counter++))                            # Increment Error by 1
                fi                 
                ;;           
        NP)     sadm_write_err "  - Account '$SADM_USER' have no password, status is '$acc_status'." 
                if [ "$SADM_PWD_RANDOM" = "Y" ]                         # If random passwd needed
                    then generate_password                              # Generate random passwd
                         if [ $? -ne 0 ]                                # Error generating password
                             then sadm_write_err "[ ERROR ] Error generating $SADM_USER password."
                                  sadm_write_err "User '$SADM_USER' require attention, check aging."
                                  chage -l $SADM_USER >> $SADM_LOG 2>&1
                                  ((error_counter++))                   # Increment Error by 1
                         fi 
                    else ((error_counter++))                            # Increment Error by 1
                fi
                ;;
        P|PS)   sadm_write_log "  - Valid password for account '$SADM_USER' status is '$acc_status'." 
                ;;
            *)  sadm_write_err "Unknown '$SADM_USER' user state, status is '$acc_status'."
                ((error_counter++))                                     # Increment Error by 1
                ;;
    esac   


    # Field # 3 in /etc/shadow : 
    #   - Is the date of the last password change, expressed as the number of days since Jan 1,1970. 
    #   - A '0' has a special meaning, it force user to change password at the next login.
    #   - An empty field means that password aging features are disabled.
    last_passwd_change=$(grep $SADM_USER /etc/shadow | awk -F\: '{ print $3 }')
    if [ "$last_passwd_change" = "0" ]
        then sadm_write_err "  - The password of '$SADM_USER' user need to be change." 
             sadm_write_err "  - The 'sadmin' cron jobs may not run if you don't change it."
             if [ "$SADM_PWD_RANDOM" = "Y" ]                            # If random passwd needed
                then generate_password                                  # Generate random passwd
                     if [ $? -ne 0 ]                                    # Error generating password
                         then sadm_write_err "[ ERROR ] Error generating $SADM_USER password."
                              sadm_write_err "User '$SADM_USER' require attention, check aging."
                              chage -l $SADM_USER >> $SADM_LOG 2>&1
                              ((error_counter++))                       # Increment Error by 1
                     fi 
                else ((error_counter++))                                # Increment Error by 1
             fi 
    fi 


    # Get password expire date & convert it to epoch time and check if pwd expiry date < today.
    pwd_expire_date=$(chage -l $SADM_USER | grep -i '^Password expires' | awk -F\: '{ print $NF }')
    pwd_expire_date=$(echo "$pwd_expire_date" | tr "-" ".")             # Replace dash with dot
    pwd_expire_epoch=$(sadm_date_to_epoch "$pwd_expire_date 00:00:00")  # Expiry date to Epoch time
    cur_epoch_time=$(sadm_get_epoch_time)                               # Get Current date to Epoch
    if [ "$pwd_expire_epoch" -lt "$cur_epoch_time" ]                    # If password expired
        then sadm_write_err "  - The password of '$SADM_USER' user is expired." 
             sadm_write_err "  - The 'sadmin' cron jobs may not run if you don't change it."
             if [ "$SADM_PWD_RANDOM" = "Y" ]                            # If random passwd is OK 
                then generate_password                                  # Generate random passwd
                     if [ $? -ne 0 ]                                    # Error generating password
                         then sadm_write_err "[ ERROR ] Error generating $SADM_USER password."
                              sadm_write_err "User '$SADM_USER' require attention, check aging."
                              chage -l $SADM_USER >> $SADM_LOG 2>&1
                              ((error_counter++))                       # Increment Error by 1
                     fi 
                else ((error_counter++))                                # Increment Error by 1
             fi
    fi 

    if [ $error_counter -eq 0 ] ; then sadm_write_log "  - Account '$SADM_USER' in valid." ;fi
    return $error_counter
}


# --------------------------------------------------------------------------------------------------
# Put in place the python version on the nmon watcher.
# Change 'sadm_nmon_watcher.sh' for 'sadm_nmon_watcher.py' in /etc/cron.d/sadm_client
# --------------------------------------------------------------------------------------------------
set_new_nmon_watcher()
{
    if [[ -f "/etc/cron.d/sadm_client" ]]
       then sed -i 's/sadm_nmon_watcher.sh/sadm_nmon_watcher.py/' /etc/cron.d/sadm_client 
    fi 
    return 0 
}




# --------------------------------------------------------------------------------------------------
#                             General Directories Owner/Group and Privilege
# --------------------------------------------------------------------------------------------------
set_dir()
{
    VAL_DIR=$1                                                          # Directory Name
    VAL_OCTAL=$2                                                        # chmod octal value
    VAL_OWNER=$3                                                        # Directory Owner 
    VAL_GROUP=$4                                                        # Directory Group name
    RETURN_CODE=0                                                       # Reset Error Counter

    if [ -d "$VAL_DIR" ]                                                # If Directory Exist
        then sadm_write_log "  - chmod $VAL_OCTAL $VAL_DIR " "NOLF"
             chmod $VAL_OCTAL $VAL_DIR  >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] On 'chmod' operation for ${VALDIR}."
                     ((ERROR_COUNT++))                                  # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ]"
             fi
             sadm_write_log "  - chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR " "NOLF"
             chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] On 'chown' operation for ${VALDIR}."
                     ((ERROR_COUNT++))                                  # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ]"
             fi
    fi
    return $RETURN_CODE
}


# --------------------------------------------------------------------------------------------------
#                             General Directories Owner/Group and Privilege
# --------------------------------------------------------------------------------------------------
set_files_recursive()
{
    VAL_DIR=$1                                                          # File or Directory Name
    VAL_OCTAL=$2                                                        # chmod octal value
    VAL_OWNER=$3                                                        # Directory Owner 
    VAL_GROUP=$4                                                        # Directory Group name
    RETURN_CODE=0                                                       # Reset Error Counter

    # Make sure DAT Directory $SADM_DAT_DIR Directory files is own by sadmin
    if [ -d "$VAL_DIR" ]
        then CMD="find $VAL_DIR -type f -exec chown ${VAL_OWNER}:${VAL_GROUP} {} \;" 
             find $VAL_DIR -type f -exec chown ${VAL_OWNER}:${VAL_GROUP} {} \; #>/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With command $CMD"
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ] $CMD"
             fi

             CMD="find $VAL_DIR -type f -exec chmod $VAL_OCTAL {} \;" 
             find $VAL_DIR -type f -exec chmod $VAL_OCTAL {} \; #>/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With $CMD"
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ] $CMD"
             fi
    fi
    return $RETURN_CODE
}





# --------------------------------------------------------------------------------------------------
# Function that set the Owner/Group and Privilege of the Directories received.
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_write_log " "
    sadm_write_log "SADMIN CLIENT DIRECTORIES HOUSEKEEPING"
    sadm_write_log ""

    ERROR_COUNT=0
    
    # Setup basic SADMIN directories structure and permissions
    sadm_freshen_directories_structure
    sadm_write_log "[ OK ] Directories structure" 

    # Taking care of lost+found directory (If present) in AIX and Linux.
    if [ -d "$SADM_BASE_DIR/lost+found" ]
        then if [ "$SADM_OS_TYPE" = "AIX" ]
                then set_dir "$SADM_BASE_DIR/lost+found" "4775" "root" "system" 
                else set_dir "$SADM_BASE_DIR/lost+found" "4775" "root" "root"   
             fi
    fi

    return $ERROR_COUNT
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

    if [ -f "$VAL_FILE" ]                                               # If file exist
        then CMD="chmod ${VAL_OCTAL} ${VAL_FILE}"
             chmod ${VAL_OCTAL} ${VAL_FILE}
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With $CMD."
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ] $CMD"
             fi

             CMD="chown ${VAL_OWNER}:${VAL_GROUP} ${VAL_FILE}" 
             chown ${VAL_OWNER}:${VAL_GROUP} ${VAL_FILE}
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With $CMD."
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ] $CMD"
             fi
    fi
    return $RETURN_CODE
}



# --------------------------------------------------------------------------------------------------
# General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_write_log ""
    sadm_write_log "SADMIN CLIENT FILES HOUSEKEEPING"
    sadm_write_log ""

   # Just to make sure .gitkeep file always exist in some directories (for git).
    if [ ! -f "${SADM_TMP_DIR}/.gitkeep" ]  ; then touch ${SADM_TMP_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_LOG_DIR}/.gitkeep" ]  ; then touch ${SADM_LOG_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_DAT_DIR}/.gitkeep" ]  ; then touch ${SADM_DAT_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_SYS_DIR}/.gitkeep" ]  ; then touch ${SADM_SYS_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_UBIN_DIR}/.gitkeep" ] ; then touch ${SADM_UBIN_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_ULIB_DIR}/.gitkeep" ] ; then touch ${SADM_ULIB_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_UCFG_DIR}/.gitkeep" ] ; then touch ${SADM_UCFG_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_UDOC_DIR}/.gitkeep" ] ; then touch ${SADM_UDOC_DIR}/.gitkeep ; fi 

    # Remove ReaR default cron - We want to run ReaR Backup from our crontab 'etc/cron.d/sadm_rear'.
    if [ -r /etc/cron.d/rear ] ; then rm -f /etc/cron.d/rear >/dev/null 2>&1; fi

    # Remove file(s) and directories used by SADMIN server and not needed on SADMIN client
    if [ "$SADM_HOST_TYPE" = "C" ]                                  # If not on SADMIN server      
        then if [ -f "$SADM_ALERT_ARC"  ] ; then rm -f "$SADM_ALERT_ARC"  >/dev/null 2>&1 ;fi
             if [ -f "$SADM_ALERT_HIST" ] ; then rm -f "$SADM_ALERT_HIST" >/dev/null 2>&1 ;fi
             if [ -f "$GMPW_FILE_TXT"   ] ; then rm -f "$GMPW_FILE_TXT"   >/dev/null 2>&1 ;fi
             if [ -f "$DBPASSFILE"      ] ; then rm -f "$DBPASSFILE"      >/dev/null 2>&1 ;fi
             if [ -d "$SADM_DBB_DIR"    ] ; then rm -fr "$SADM_DBB_DIR" ; fi
             if [ -d "$SADM_NET_DIR"    ] ; then rm -fr "$SADM_NET_DIR" ; fi    
             f="${SADM_CFG_DIR}/sadmin_client.cfg" 
             if [ -f "$f" ] ; then rm -f "$f" >/dev/null 2>&1 ; fi
             f="${SADM_CFG_DIR}/sherlock.smon"
             if [ -f "$f" ] ; then rm -f "$f" >/dev/null 2>&1 ; fi 
             f="$SADM_WWW_LIB_DIR/.crontab.txt"
             if [ -f "$f" ] ; then rm -f "$f" >/dev/null 2>&1 ; fi
    fi 

    # Set the owner/group and privilege of all files in these directories.
    set_files_recursive "$SADM_DAT_DIR"        "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_DOC_DIR"        "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_WWW_DIR"        "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_LOG_DIR"        "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_CFG_DIR"        "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_USR_DIR"        "0644" "${SADM_USER}" "${SADM_GROUP}" 

    set_files_recursive "$SADM_BIN_DIR"        "0755" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_SYS_DIR"        "0775" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_LIB_DIR"        "0775" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_PKG_DIR"        "0755" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_SETUP_DIR"      "0775" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_UBIN_DIR"       "0775" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_ULIB_DIR"       "0775" "${SADM_USER}" "${SADM_GROUP}" 
    set_files_recursive "$SADM_UMON_DIR"       "0775" "${SADM_USER}" "${SADM_GROUP}" 

    if  [ "$SADM_HOST_TYPE" = "S" ] 
        then set_files_recursive "$SADM_WWW_DIR" "0664" "${SADM_WWW_USER}" "${SADM_WWW_GROUP}" 
    fi

    # SADMIN directories and Readme, changelog and license file.
    set_file "$SADM_TMP_DIR"                 "1777" "${SADM_USER}" "${SADM_GROUP}"     
    set_file "${SADM_BASE_DIR}/readme.md"    "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/readme.html"  "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/readme.pdf"   "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/LICENSE"      "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/license"      "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/changelog.md" "0644" "${SADM_USER}" "${SADM_GROUP}" 
    
    # Password files
    set_file "$GMPW_FILE_B64"                "0644" "${SADM_USER}" "${SADM_GROUP}"
    set_file "/etc/postfix/sasl_passwd"      "0600"  "root" "root"
    set_file "/etc/postfix/sasl_passwd.db"   "0600"  "root" "root"

    sadm_write_log ""
    sadm_write_log "SADMIN FILES PRUNING"

    # Remove files older than 2 days and *.pid file in $SADMIN/tmp directory.
    if [ -d "$SADM_TMP_DIR" ]
        then sadm_write_log " "
             sadm_write_log "Remove unmodified file(s) for more than 2 days in ${SADM_TMP_DIR}."
             CMD="find $SADM_TMP_DIR  -type f -mtime +2 -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -mtime +2 -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] $CMD" 
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] $CMD"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi
             fi

             sadm_write_log " "
             sadm_write_log "Remove all pid files once a day - This prevent script from not running."
             CMD="find $SADM_TMP_DIR  -type f -name \"*.pid\" -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -name "*.pid" -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] $CMD"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] $CMD"
             fi
             if [ $ERROR_COUNT -ne 0 ] ; then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi
             touch ${SADM_TMP_DIR}/.gitkeep
    fi


    # Remove *.rch files older than ${SADM_RCH_KEEPDAYS} days (in sadmin.cfg) in $SADMIN/dat/rch.
    if [ -d "${SADM_RCH_DIR}" ]
        then sadm_write_log " "
             sadm_write_log "Remove any unmodified *.rch file(s) for more than ${SADM_RCH_KEEPDAYS} days in ${SADM_RCH_DIR}."
             CMD="find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name \"*.rch\" -exec rm -f {} \;"
             find $SADM_RCH_DIR -type f -mtime +${SADM_RCH_KEEPDAYS} -name "*.rch" -exec rm -f {} \;
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With $CMD"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] $CMD"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi
    fi

    # Remove any *.log in SADMIN LOG Directory older than ${SADM_LOG_KEEPDAYS} days
    if [ -d "${SADM_LOG_DIR}" ]
        then sadm_write_log " "
             sadm_write_log "Remove any *.log file(s) older than $SADM_LOG_KEEPDAYS days."
             CMD="find "$SADM_LOG_DIR" -type f -mtime +${SADM_LOG_KEEPDAYS} -name \"*.log\" -exec rm -f {} \;"
             find "$SADM_LOG_DIR" -type f -mtime +${SADM_LOG_KEEPDAYS} -name "*.log" -exec rm -f {} \; 
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] $CMD"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] $CMD"
             fi

             sadm_write_log " "
             sadm_write_log "Remove empty log file(s)."
             CMD="find $SADM_LOG_DIR -type f -name \"*.log\" -size 0 -exec rm {} \;"
             find $SADM_LOG_DIR -type f -name "*.log" -size 0 -exec rm {} \;
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With $CMD"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] $CMD"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi
    fi


    # Delete old nmon files - As defined in the sadmin.cfg file
    if [ -d "${SADM_NMON_DIR}" ]
        then sadm_write_log " "
             sadm_write_log "Remove any unmodified *.nmon file(s) for more than ${SADM_NMON_KEEPDAYS} days in ${SADM_NMON_DIR}." 
             CMD="find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec rm {} \;"
             find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec rm {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With $CMD"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] $CMD"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi
    fi

    # Delete old rpt files - Should not happen but let's do it to be clean.
    if [ -d "${SADM_RPT_DIR}" ]
        then sadm_write_log " "
             sadm_write_log "Remove any unmodified *.rpt file(s) for more than ${SADM_NMON_KEEPDAYS} days in ${SADM_RPT_DIR}." 
             CMD="find $SADM_RPT_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name \"*.rpt\" -exec rm {} \;"
             find $SADM_RPT_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.rpt" -exec rm {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] With $CMD"
                     ((ERROR_COUNT++))
                else sadm_write_log "[ OK ] $CMD"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write_log "Total Error: ${ERROR_COUNT}" ;fi
    fi
    
    return $ERROR_COUNT
}





# --------------------------------------------------------------------------------------------------
# The script Remove some old files or files on client that should not be there
# --------------------------------------------------------------------------------------------------
function remove_client_unwanted_files()
{
    sadm_write_log ""
    sadm_write_log "REMOVE SADMIN SERVER FILES ON CLIENT (if any)"
    sadm_write_log ""

    if [ "$SADM_HOST_TYPE" = "C" ] 
        then rm sherlock.smon        >/dev/null 2>&1
             rm alert_archive.txt    >/dev/null 2>&1
             rm sadmin_client.cfg    >/dev/null 2>&1
             rm .dbpass              >/dev/null 2>&1
             rm .gmpw                >/dev/null 2>&1
    fi 
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
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
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
    check_sadmin_account                                                # SADMIN User Account Lock ?
    ACC_ERROR=$?                                                        # Return number of errors
    if [ "$ACC_ERROR" -eq 0 ]
        then dir_housekeeping                                           # Do Dir HouseKeeping
             DIR_ERROR=$?                                               # ReturnCode = Nb. of Errors
             if [ "$DIR_ERROR" -eq 0 ]
                then file_housekeeping                                  # Do File HouseKeeping
                     FILE_ERROR=$?                                      # ReturnCode = Nb. of Errors
             fi
    fi 

    set_new_nmon_watcher                                                # Use Python nmon_watcher  
    remove_client_unwanted_files                                        # Del Server file not client

    SADM_EXIT_CODE=$(($DIR_ERROR+$FILE_ERROR+$ACC_ERROR))               # Error= DIR+File+Lock Func.
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
