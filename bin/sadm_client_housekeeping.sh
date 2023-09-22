#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_housekeeping.sh
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
#@2023_07_11 client v2.12 Update sadm_client crontab to use the new python 'sadm_nmon_watcher.py'.
#@2023_07_12 client v2.13 Remove duplicated lines in /etc/cron.d/sadm_client file.
#@2023_07_12 client v2.14 If not on SADMIN server, remove Gmail text pwd file '.gmpw' (if exist). 
#@2023_09_18 client v2.15 Update SADMIN section and minor improvement.
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
export SADM_VER='2.15'                                      # Script version number
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
ERROR_COUNT=0                               ; export ERROR_COUNT        # Error Counter
LIMIT_DAYS=14                               ; export LIMIT_DAYS         # RCH+LOG Delete after
DIR_ERROR=0                                 ; export DIR_ERROR          # ReturnCode = Nb. of Errors
FILE_ERROR=0                                ; export FILE_ERROR         # ReturnCode = Nb. of Errors




# --------------------------------------------------------------------------------------------------
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
#             Check Daily if sadmin Account is lock (Disabling crontab script to work) 
# --------------------------------------------------------------------------------------------------
check_sadmin_account()
{
    lock_error=0
    sadm_write "\n"
    sadm_write "${BOLD}Check status of account '$SADM_USER' ...${NORMAL}\n" 

    # Make sure sadmin account is not asking for password change and block crontab sudo.
    # So we make sadmin account non-expirable and password non-expire
    if [ "$SADM_OS_TYPE"  = "LINUX" ]                                   # On Linux Operating System
        then sadm_write "  - Making sure account '$SADM_USER' doesn't expire.\n" 
             usermod -e '' $SADM_USER >/dev/null 2>&1                   # Make Account non-expirable
             sadm_write "  - Making sure password for '$SADM_USER' doesn't expire.\n"
             chage -I -1 -m 0 -M 99999 -E -1 $SADM_USER >/dev/null 2>&1 # Make sadmin pwd non-expire
             sadm_write "  - We recommend changing '$SADM_USER' password at regular interval.\n"
    fi

    # Check if sadmin account is lock.
    if [ "$SADM_OS_TYPE"  = "LINUX" ]                                   # On Linux Operating System
        then passwd -S $SADM_USER | grep -i 'locked' > /dev/null 2>&1   # Check if Account is locked
             if [ $? -eq 0 ]                                            # If Account is Lock
                then upass=`grep "^$SADM_USER" /etc/shadow | awk -F: '{ print $2 }'` # Get pwd hash
                     if [ "$upass" = "!!" ]                             # if passwd is '!!'' = NoPwd
                        then sadm_write "  - [WARNING] User $SADM_USER has no password.\n" 
                             echo "47up&wd40!" | passwd --stdin $SADM_USER
                             sadm_write "  - A temporary password was assigned to ${SADM_USER}, please change it now !!\n"
                        else first2char=`echo $upass | cut -c1-2`       # Get passwd first two Char.
                             if [ "$first2char" = "!!" ]                # First 2 Char are '!!' 
                                then sadm_write "  - [ERROR] Account $SADM_USER is locked.\n"
                                     sadm_write "  - Use 'passwd -u $SADM_USER' to unlock it.\n"
                                     lock_error=1                       # Set Error Flag ON
                                else firstchar=`echo $upass | cut -c1`  # Get passwd first Char.
                                     if [ "$firstchar" = "!" ]          # First Char is "!'
                                        then sadm_write "  - [ERROR] Account $SADM_USER is locked.\n"
                                             sadm_write "  - Use 'usermod -U $SADM_USER' to unlock it.\n"
                                             lock_error=1               # Set Error Flag ON
                                        else sadm_write "  - We use 'passwd -S $SADM_USER' to check if user account is lock.\n"
                                             sadm_write "  - You need to fix that, so the account unlock.\n"
                                             lock_error=1               # Set Error Flag ON
                                     fi                                            
                             fi 
                     fi 
             fi
    fi
  
    # Check if sadmin Aix account is locked.
    if [ "$SADM_OS_TYPE"  = "AIX" ]
        then lsuser -a account_locked $SADM_USER | grep -i 'true' >/dev/null 2>&1
             if [ $? -eq 0 ] 
                then sadm_write "  - ${SADM_ERROR} Account $SADM_USER is locked and need to be unlock ...\n"
                     sadm_write "  - Please check the account and unlock it with these commands ; \n"
                     sadm_write "  - chsec -f /etc/security/lastlog -a 'unsuccessful_login_count=0' -s $SADM_USER \n"
                     sadm_write "  - chuser 'account_locked=false' $SADM_USER \n"
                     lock_error=1
             fi
    fi

    if [ $lock_error -eq 0 ] 
        then sadm_write "  - No problem with '$SADM_USER' account. ${SADM_OK}\n" 
    fi
    return $lock_error
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

    # This is to eliminate the duplicate lines in /etc/cron.d/sadm_client
    # Because of an earlier bug, line for sadm_nmon_watcher were added more than once.
    awk -i inplace '!sadm_nmon_watcher[$0]++' /etc/cron.d/sadm_client

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
        then sadm_write "  - chmod $VAL_OCTAL $VAL_DIR "
             chmod $VAL_OCTAL $VAL_DIR  >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On 'chmod' operation for ${VALDIR}.\n"
                     ((ERROR_COUNT++))                                  # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write "${SADM_OK}\n"
             fi
             sadm_write "  - chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR "
             chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On 'chown' operation for ${VALDIR}.\n"
                     ((ERROR_COUNT++))                                  # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write "${SADM_OK}\n"
             fi
             #lsline=`ls -ld $VAL_DIR`
             #sadm_write "${lsline}\n"
    fi
    return $RETURN_CODE
}


# --------------------------------------------------------------------------------------------------
#                             General Directories Owner/Group and Privilege
# --------------------------------------------------------------------------------------------------
set_files_recursive()
{
    VAL_DIR=$1                                                          # Directory Name
    VAL_OCTAL=$2                                                        # chmod octal value
    VAL_OWNER=$3                                                        # Directory Owner 
    VAL_GROUP=$4                                                        # Directory Group name
    RETURN_CODE=0                                                       # Reset Error Counter

    # Make sure DAT Directory $SADM_DAT_DIR Directory files is own by sadmin
    if [ -d "$VAL_DIR" ]
        then sadm_write "  - find $VAL_DIR -type f -exec chown ${VAL_OWNER}:${VAL_GROUP} {} \; "
             find $VAL_DIR -type f -exec chown ${VAL_OWNER}:${VAL_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On 'chown' operation of ${VALDIR}.\n"
                     ((ERROR_COUNT++))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write "${SADM_OK}\n"
             fi
             sadm_write "  - find $VAL_DIR -type f -exec chmod $VAL_OCTAL{} \; "
             find $VAL_DIR -type f -exec chmod $VAL_OCTAL {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On 'chmod' operation of ${VALDIR}.\n"
                     ((ERROR_COUNT++))
                else sadm_write "${SADM_OK}\n"
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
    fi
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi
    return $RETURN_CODE
}





# --------------------------------------------------------------------------------------------------
# Function that set the Owner/Group and Privilege of the Directories received.
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_write "${BOLD}SADMIN Client Directories Housekeeping.${NORMAL}\n"
    ERROR_COUNT=0                                                       # Reset Error Count

    # Setup basic SADMIN directories structure and permissions
    sadm_freshen_directories_structure

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

    if [ -f "$VAL_FILE" ]
        then sadm_write "  - chmod ${VAL_OCTAL} ${VAL_FILE} "
             chmod ${VAL_OCTAL} ${VAL_FILE}
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] On 'chmod' operation on ${VAL_FILE}."
                     ((ERROR_COUNT++))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ]"
             fi
             sadm_write "  - chown ${VAL_OWNER}:${VAL_GROUP} ${VAL_FILE} "
             chown ${VAL_OWNER}:${VAL_GROUP} ${VAL_FILE}
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] On 'chown' operation on ${VAL_FILE}."
                     ((ERROR_COUNT++))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write_log "[ OK ]"
             fi
             #lsline=`ls -l $VAL_FILE`
             #sadm_write "${lsline}\n"
    fi

    return $RETURN_CODE
}



# --------------------------------------------------------------------------------------------------
# General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_write "\n"
    sadm_write "${BOLD}SADMIN Client Files Housekeeping.${NORMAL}\n"

   # Just to make sure .gitkeep file always exist
    if [ ! -f "${SADM_TMP_DIR}/.gitkeep" ]  ; then touch ${SADM_TMP_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_LOG_DIR}/.gitkeep" ]  ; then touch ${SADM_LOG_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_DAT_DIR}/.gitkeep" ]  ; then touch ${SADM_DAT_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_SYS_DIR}/.gitkeep" ]  ; then touch ${SADM_SYS_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_UBIN_DIR}/.gitkeep" ] ; then touch ${SADM_UBIN_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_ULIB_DIR}/.gitkeep" ] ; then touch ${SADM_ULIB_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_UCFG_DIR}/.gitkeep" ] ; then touch ${SADM_UCFG_DIR}/.gitkeep ; fi 
    if [ ! -f "${SADM_UDOC_DIR}/.gitkeep" ] ; then touch ${SADM_UDOC_DIR}/.gitkeep ; fi 

    # - Remove files that should only be there on the SADMIN Server not the client.
    # - Delete plain text email password file on client
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]
       then afile="$SADM_WWW_LIB_DIR/.crontab.txt"
            if [ -f $afile ]         ; then rm -f $afile         >/dev/null 2>&1 ; fi
     
       else set_file "$GMPW_FILE_TXT" "0600" "${SADM_USER}" "${SADM_GROUP}"
    fi

    # Remove default crontab job - We want to run the ReaR Backup from the sadm_rear_backup crontab.
    if [ -f "$GMPW_FILE_B64" ] 
        then chmod 664 $GMPW_FILE_B64
             chown  ${SADM_USER}:${SADM_GROUP} $GMPW_FILE_B64
    fi 
    
    # No Password file ($SADMIN/cfg/.gmpw)non encrypted on client, remote it.
    if [ -f "$GMPW_FILE_TXT" ] && [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]
        then rm -f $GMPW_FILE_TXT >/dev/null 2>&1
    fi

    # Remove default crontab job - We want to run the ReaR Backup from the sadm_rear_backup crontab.
    if [ -r /etc/cron.d/rear ] ; then rm -f /etc/cron.d/rear >/dev/null 2>&1; fi

    # Make sure some files have proper permission and owner
    set_file "/etc/cron.d/sadm_client"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_server"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_osupdate"     "0644" "root" "root"
    set_file "/etc/cron.d/sadm_backup"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_rear_backup"  "0644" "root" "root"

    # If old file '.rch_conversion_done' exist, then delete it (Not needed anymore)
    if [ -r "$SADM_CFG_DIR/.rch_conversion_done" ]
        then rm -f $SADM_CFG_DIR/.rch_conversion_done > /dev/null 2>&1 
    fi
    
    set_files_recursive "$SADM_TMP_DIR"        "1777" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_DAT_DIR"        "0664" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_LOG_DIR"        "0666" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_USR_DIR"        "0644" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_UBIN_DIR"       "0775" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_ULIB_DIR"       "0775" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_UMON_DIR"       "0775" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_CFG_DIR"        "0664" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_SYS_DIR"        "0770" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_BIN_DIR"        "0775" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_LIB_DIR"        "0775" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi

    set_files_recursive "$SADM_PKG_DIR"        "0755" "${SADM_USER}" "${SADM_GROUP}" 
    if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}.\n" ;fi


    # SADMIN Readme, changelog and license file.
    set_file "${SADM_BASE_DIR}/readme.md"    "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/readme.html"  "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/readme.pdf"   "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/LICENSE"      "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/license"      "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/changelog.md" "0664" "${SADM_USER}" "${SADM_GROUP}" 
    
    # Password files
    set_file "${SADM_CFG_DIR}/.dbpass"       "0644" "${SADM_USER}" "${SADM_GROUP}"
    set_file "$GMPW_FILE_TXT"                "0644" "${SADM_USER}" "${SADM_GROUP}"
    set_file "$GMPW_FILE_B64"                "0644" "${SADM_USER}" "${SADM_GROUP}"
    set_file "/etc/postfix/sasl_passwd"      "0600"  "root" "root"
    set_file "/etc/postfix/sasl_passwd.db"   "0600"  "root" "root"

    sadm_write "\n"
    sadm_write "${BOLD}SADMIN Files Pruning.${NORMAL}\n"

    # Remove files older than 7 days in SADMIN TMP Directory
    if [ -d "$SADM_TMP_DIR" ]
        then sadm_write_log "  - Remove unmodified file(s) for more than 7 days in ${SADM_TMP_DIR}."
             sadm_write "    - find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -mtime +7 -exec ls -l {} \; >> $SADM_LOG
             find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write " ${SADM_ERROR} On last pruning operation.\n"
                     ((ERROR_COUNT++))
                else sadm_write " ${SADM_OK}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
             sadm_write "  - Remove all pid files once a day - This prevent script from not running.\n"
             sadm_write "    - find $SADM_TMP_DIR  -type f -name '*.pid' -exec rm -f {} \; "
             find $SADM_TMP_DIR  -type f -name "*.pid" -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On last pruning operation.\n"
                     ((ERROR_COUNT++))
                else sadm_write "${SADM_OK}\n"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             touch ${SADM_TMP_DIR}/.gitkeep
    fi

    # Remove *.rch (Return Code History) files older than ${SADM_RCH_KEEPDAYS} days in SADMIN/DAT/RCH Dir.
    if [ -d "${SADM_RCH_DIR}" ]
        then sadm_write "  - Remove any unmodified *.rch file(s) for more than ${SADM_RCH_KEEPDAYS} days in ${SADM_RCH_DIR}.\n"
             #echo "  - List of rch file that will be deleted." >> $SADM_LOG
             find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name "*.rch" -exec ls -l {} \; >>$SADM_LOG
             sadm_write "    - find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name '*.rch' -exec rm -f {} \;"
             find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name "*.rch" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_write " ${SADM_ERROR} On last operation.\n"
                     ((ERROR_COUNT++))
                else sadm_write " ${SADM_OK}\n"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
    fi

    # Remove any *.log in SADMIN LOG Directory older than ${SADM_LOG_KEEPDAYS} days
    if [ -d "${SADM_LOG_DIR}" ]
        then sadm_write "  - Remove any unmodified *.log file(s) for more than ${SADM_LOG_KEEPDAYS} days in ${SADM_LOG_DIR}.\n"
             #sadm_write "    - List of log file that will be deleted.\n" 
             #find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name "*.log" -exec ls -l {} \; >>$SADM_LOG
             sadm_write "    - find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name '*.log' -exec rm -f {} \; "
             find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name "*.log" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On last operation.\n"
                     ((ERROR_COUNT++))
                else sadm_write "${SADM_OK}\n"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
    fi

    # Delete old nmon files - As defined in the sadmin.cfg file
    if [ -d "${SADM_NMON_DIR}" ]
        then sadm_write "  - Remove any unmodified *.nmon file(s) for more than ${SADM_NMON_KEEPDAYS} days in ${SADM_NMON_DIR}.\n"
             #sadm_write "    - List of nmon file that will be deleted.\n"
             #find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec ls -l {} \; >> $SADM_LOG 2>&1
             sadm_write "    - find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name '*.nmon' -exec rm {} \; "
             find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec rm {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On last operation.\n"
                     ((ERROR_COUNT++))
                else sadm_write "${SADM_OK}\n"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
    fi

    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
# This function check if the SADMIN group ($SADM_GROUP) and user ($SADM_USER) exist on system.
# If not the advise user about what to do and abort script execution & return error to O/S/
# --------------------------------------------------------------------------------------------------
function check_sadmin_user()
{
    # The '$SADM_GROUP' (Define in sadmin.cfg) group should exist - If not advise user & abort
    if [ "$SADM_OS_TYPE" != "DARWIN" ]                                  # If not on MacOS
        then grep "^${SADM_GROUP}:"  /etc/group >/dev/null 2>&1         # $SADMIN Group Defined ?
             if [ $? -ne 0 ]                                            # SADM_GROUP not Defined
                then sadm_write "Group ${SADM_GROUP} not present.\n"    # Advise user will create
                     sadm_write "Create group or change 'SADM_GROUP' value in $SADMIN/sadmin.cfg.\n"
                     sadm_write "Process Aborted.\n"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
                     exit 1                                             # Exit with Error
             fi
    fi

    # The '$SADM_USER' user exist user - if not create it and make it part of 'sadmin' group.
    if [ "$SADM_OS_TYPE" != "DARWIN" ]                                  # If not on MacOS
        then grep "^${SADM_USER}:" /etc/passwd >/dev/null 2>&1          # $SADMIN User Defined ?
             if [ $? -ne 0 ]                                            # NO Not There
                then sadm_write "User $SADM_USER not present.\n"        # usr in sadmin.cfg not found
                     sadm_write "Create user or change 'SADM_USER' value in $SADMIN/sadmin.cfg\n"
                     sadm_write "Process Aborted.\n"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
                     exit 1                                             # Exit with Error
             fi
    fi
    return 0                                                            # Return OK to Caller
}




# --------------------------------------------------------------------------------------------------
# Inspect sadm_client crontab to make sure that this line is in it. 
# "*/45 * * * *  %s sudo ${SADMIN}/bin/sadm_nmon_watcher.sh > /dev/null 2>&1"
# The script check if 'nmon. is running, if isn't the script will start it with the right parameters
# --------------------------------------------------------------------------------------------------
function check_sadm_client_crontab()
{
    sadm_write "\n"
    sadm_write "${BOLD}Check SADMIN client '$SADM_USER' crontab & System monitor config file ...${NORMAL}\n"     
    ccron_file="/etc/cron.d/sadm_client"                                # Default crontab file name


    # Setup crontab filename under linux
    if [ "$(sadm_get_ostype)" == "LINUX" ]                              # Under Linux
       then ccron_file="/etc/cron.d/sadm_client"                        # Client Crontab File Name
            if [ ! -d "/etc/cron.d" ]                                   # Test if Dir. Exist
                then sadm_writelog "  - Crontab Directory /etc/cron.d doesn't exist ?"
                     sadm_writelog "  - Send log ($SADM_LOG) and submit problem to support@sadmin.ca"
                     return 1                                           # Return to Caller with Err.
            fi 
    fi
    # Setup crontab filename under Aix    
    if [ "$(sadm_get_ostype)" == "AIX" ]                                # Under Aix
       then ccron_file="/var/spool/cron/crontabs/${SADM_USER}"          # Client Crontab File Name
            if [ ! -d "/var/spool/cron/crontabs" ]                      # Test if Dir. Exist
                then sadm_writelog "  - Crontab Directory /var/spool/cron/crontabs doesn't exist ?"
                     sadm_writelog "  - Send log ($SADM_LOG) and submit problem to support@sadmin.ca"
                     return 1                                           # Return to Caller with Err.
            fi
    fi
    # Setup crontab filename under MacOS
    if [ "$(sadm_get_ostype)" == "DARWIN" ]                             # Under MacOS
       then ccron_file="/var/at/tabs/${SADM_USER}"                      # Client Crontab Name
            if [ ! -d "/var/at/tabs" ]                                  # Test if Dir. Exist
                then sadm_writelog "  - Crontab Directory /var/spool/cron/crontabs doesn't exist ?"
                     sadm_writelog "  - Send log ($SADM_LOG) and submit problem to support@sadmin.ca"
                     return 1                                           # Return to Caller with Err.
            fi
    fi

    # Grep crontab for new Python sadm_nmon_watcher, if not in there, add it to cron file.
    sadm_writelog "  - Make sure sadm_client crontab ($ccron_file) have 'sadm_nmon_watcher.py' line."
    if [ -f "$ccron_file" ]                                             # Do we have crontab file ?
       then grep -q "sadm_nmon_watcher.py" "$ccron_file"                # grep for watcher script
            if [ $? -ne 0 ]                                             # If watcher not there
               then echo "# " >> "$ccron_file"                          # Add to crontab
                    echo "# Every 45 Min, make sure 'nmon' performance collector is running." >> "$ccron_file"
                    echo "*/45 * * * *  $SADM_USER sudo \${SADMIN}/bin/sadm_nmon_watcher.py >/dev/null 2>&1" >> "$ccron_file"
                    echo "# " >> $ccron_file
                    echo "# " >> $ccron_file 
                    sadm_writelog "  - Crontab ($ccron_file) was updated with 'sadm_nmon_watcher.py' line." 
               else sadm_writelog "  - Yes, crontab ($ccron_file) already got 'sadm_nmon_watcher.py' line." 
            fi
       else sadm_writelog "  - There were no crontab file ($ccron_file) present on system ?" 
            return 1
    fi

    # Remove line in System monitor file, that ran a script 'swatch_nmon.sh' to check/restart nmon
    nmon_file="${SADMIN}/cfg/${SADM_HOSTNAME}.smon"
    sadm_writelog "  - Making sure that "script:swatch_nmon.sh" is no longer in $nmon_file" 
    if [ -f "$nmon_file" ] 
       then grep -q "^script:swatch_nmon.sh" $nmon_file
            if [ $? -eq 0 ] 
                then if [ "$(sadm_get_ostype)" == "DARWIN" ]            # Under MacOS
                        then grep -v "script:swatch_nmon.sh" $nmon_file >temp2 && mv temp2 $nmon_file
                        else sed -i '/^script:swatch_nmon.sh/d' $nmon_file
                     fi 
            fi
            grep -q "^# SADMIN Script Don" $nmon_file
            if [ $? -eq 0 ] 
                then if [ "$(sadm_get_ostype)" == "DARWIN" ]            # Under MacOS
                        then grep -v "# SADMIN Script Don" $nmon_file >temp2 && mv temp2 $nmon_file
                        else sed -i '/^# SADMIN Script Don/d' $nmon_file
                     fi 
            fi            
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
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}."               # Display Debug Level
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
    return 
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Only 'root' user can run this script.\n"       # Advise User Message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi
    #
    check_sadmin_user                                                   # Check SADMIN Usr & Grp
    dir_housekeeping                                                    # Do Dir HouseKeeping
    DIR_ERROR=$?                                                        # ReturnCode = Nb. of Errors
    file_housekeeping                                                   # Do File HouseKeeping
    FILE_ERROR=$?                                                       # ReturnCode = Nb. of Errors
    check_sadmin_account                                                # SADMIN User Account Lock ?
    ACC_ERROR=$?                                                        # Return 1 if Locked 
    check_sadm_client_crontab                                           # crontab have nmon watcher
    CRON_ERROR=$?                                                       # Return 1 if crontab error 
    set_new_nmon_watcher                                                # Update sadm_client cron 
    #
    SADM_EXIT_CODE=$(($DIR_ERROR+$FILE_ERROR+$ACC_ERROR+$CRON_ERROR))   # Error= DIR+File+Lock Func.
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
