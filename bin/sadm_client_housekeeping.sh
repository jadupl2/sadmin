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
# --------------------------------------------------------------------------------------------------
# 2017_08_08    v1.7 Add /sadmin/jac in the housekeeping and change 600 to 644 for configuration file
# 2017-10-10    v1.8 Remove deletion of release file on sadm client in /sadmin/cfg
# 2018-01-02    v1.9 Delete file not needed anymore
# 2018_05_14    v1.10 Correct problem on MacOS with change owner/group command
# 2018_06_04    v1.11 Add User Directories, Database Backup Directory, New Backup Cfg Files
# 2018_06_05    v1.12 Enhance Ouput Display - Add Missing Setup Dir, Review Purge Commands
# 2018_06_09    v1.13 Add Help and Version Function - Change Startup Order
# 2018_06_13    v1.14 Change all files in $SADMIN/cfg to 664.
# 2018_07_30    v1.15 Make sure sadmin crontab files in /etc/cron.d have proper owner & permission.
# 2018_09_16    v1.16 Include Cleaning of alert files needed only on SADMIN server.
# 2018_09_28    v1.17 Code Optimize and Cleanup
# 2018_10_27    v1.18 Remove old dir. not use anymore (if exist)
# 2018_11_02    v1.19 Code Maint. & Comment
# 2018_11_23    v1.20 An error is signal when the 'sadmin' account is lock, preventing cron to run.
# 2018_11_24    v1.21 Check SADM_USER status, give more precise explanation & corrective cmd if lock.
# 2018_12_15    v1.22 Fix Error Message on MacOS trying to find SADMIN User in /etc/passwd.
# 2018_12_18    v1.23 Don't delete SADMIN server directories if SADM_HOST_TYPE='D' in sadmin.cfg
# 2018_12_19    v1.24 Fix typo Error & Enhance log output
# 2018_12_22    v1.25 Minor change - More Debug info.
# 2019_01_28 Change: v1.26 Add readme.pdf and readme.html to housekeeping
# 2019_03_03 Change: v1.27 Make sure .gitkeep files exist in important directories
# 2019_04_17 Update: v1.28 Make 'sadmin' account & password never expire (Solve Acc. & sudo Lock)
# 2019_05_19 Update: v1.29 Change for lowercase readme.md,license,changelog.md files and bug fixes.
# 2019_06_03 Update: v1.30 Include logic to convert RCH file format to the new one, if not done.
# 2019_07_14 Update: v1.31 Add creation of Directory /preserve/mnt if it doesn't exist (Mac Only)
# 2019_07_23 Update: v1.32 Remove utilization of history sequence number file.
# 2019_08_19 Update: v1.33 Check /etc/cron.d/sadm_rear_backup permission & remove /etc/cron.d/rear
#@2019_11_25 Fix: v1.34 Remove deletion of $SADMIN/www on SADMIN client.
#@2020_01_21 Update: v1.35 Remove alert_group.cfg and alert_slack.cfg, if present in $SADMIN/cfg
#@2020_04_01 Update: v1.36 Code rewrite for better performance and maintenance. 
#@2020_04_04 Update: v1.37 Fix minor bugs & Restructure log presentation
#@2020_04_28 Update: v1.38 Update readme file permission from 0644 to 0664
#@2020_05_08 Update: v1.39 Update Change permission change on $SADMIN/usr/bin from 0755 to 775.
#@2020_07_10 Update: v1.40 If no password have been assigned to 'sadmin' a temporary one is assigned. 
#@2020_07_20 Update: v1.41 Change permission of log and rch to allow normal user to run script.
#@2020_09_10 Update: v1.42 Make sure permission are ok in user library directory ($SADMIN/usr/lib).
#@2020_09_12 Update: v1.43 Make sure that "${SADM_UCFG_DIR}/.gitkeep" exist to be part of git clone.
#@2020_09_20 Update: v1.44 Minor adjustments to log entries.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # INTERCEPT The ^C
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
    export SADM_VER='1.44'                              # Your Current Script Version
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
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT        # Error Counter
LIMIT_DAYS=14                               ; export LIMIT_DAYS         # RCH+LOG Delete after
DIR_ERROR=0                                 ; export DIR_ERROR          # ReturnCode = Nb. of Errors
FILE_ERROR=0                                ; export FILE_ERROR         # ReturnCode = Nb. of Errors



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
# If the RCH files have lines that contains 9 fields the lines are converted to 10 fields.
# The Extra field added (just before the last one) indicate the alert type (1 will be inserted).
# 0=No Alert,  1=Alert On Error, 2=Alert On Success, 3=Always Alert.
#
# Line Before (9 fields):
# raspi6 2019.06.02 01:00:07 2019.06.02 01:00:46 00:00:39 sadm_osupdate default 0       
#
# Line After (10 fields): 
# raspi6 2019.06.03 01:00:06 2019.06.03 01:00:49 00:00:43 sadm_osupdate default 1 0     
#
# --------------------------------------------------------------------------------------------------
rch_conversion()
{

    #sadm_write "\n"
    if [ ! -f "${SADM_CFG_DIR}/.rch_conversion_done" ]
        then sadm_write "\nConversion of RCH files need to be done, please wait ...\n" 
             ls -l ${SADM_CFG_DIR}/.rch_conversion_done
        else return 0 
    fi 

    sadm_write "Creating a list of all *.rch files in $SADM_RCH_DIR.\n"
    find $SADM_RCH_DIR -type f -name '*.rch' >$SADM_TMP_FILE1 2>&1      # Build list all RCH Files

    if [ -s "$SADM_TMP_FILE1" ]                                         # If File Not Zero in Size
        then cat $SADM_TMP_FILE1 | while read filename                  # Read Each RCH Filename
                do                
                if [ $SADM_DEBUG -gt 5 ]                                # Under Debug
                    then sadm_write "\nProcessing file: ${filename}\n"  # Print Filename in progress
                fi
                if [ -e "$SADM_TMP_FILE2" ]                             # If Temp file exist ?
                    then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1          # Delete it if exist 
                fi
                
                cat $filename | while read rchline                      # Read each line in RCH file
                    do
                    nbfield=`echo $rchline | awk '{ print NF }'`        # Get Nb of fields on line
                    if [ "$nbfield" -ne 9 ]                             # Line don't have 9 fields
                        then echo "$rchline"  >> $SADM_TMP_FILE2        # Add Actual line to TMP file
                             continue                                   # Continue with next line
                    fi       
                    if [ $SADM_DEBUG -gt 0 ]                            # Under Debug Print Line
                        then sadm_write "Line Before : $rchline ($nbfield)\n" 
                    fi

                    # Extract each field on the RCH Line
                    ehost=`   echo $rchline   | awk '{ print $1 }'`     # Get Hostname for Event
                    sdate=`   echo $rchline   | awk '{ print $2 }'`     # Get Starting Date 
                    stime=`   echo $rchline   | awk '{ print $3 }' `    # Get Starting Time 
                    edate=`   echo $rchline   | awk '{ print $4 }'`     # Get Script Ending Date 
                    etime=`   echo $rchline   | awk '{ print $5 }' `    # Get Script Ending Time 
                    elapse=`  echo $rchline   | awk '{ print $6 }' `    # Get Elapse Time 
                    escript=` echo $rchline   | awk '{ print $7 }'`     # Get Script Name 
                    egname=`  echo $rchline   | awk '{ print $8 }'`     # Get Alert Group Name
                    ecode=`   echo $rchline   | awk '{ print $9 }'`     # Get Result Code (0,1,2) 
                    egtype="1"                                          # Set Alert Group Type
                    
                    # Reformat RCH line and output to TMP file
                    cline="$ehost $sdate $stime $edate $etime" 
                    cline="$cline $elapse $escript $egname $egtype $ecode"
                    echo $cline >> $SADM_TMP_FILE2                      # Write converted line
                    nbf=`echo $cline | awk '{ print NF }'`              # Nb of fields on New line
                    if [ $SADM_DEBUG -gt 0 ]                            # Under Debug Print Line
                        then sadm_write "Line After  : $cline ($nbf)\n"
                    fi
                    done

                # Replace Actual RCH File with new TMP Converted file.
                rm -f $filename >/dev/null 2>&1                         # Del original rch file
                if [ $? -ne 0 ] ; then sadm_write "Error deleting $filename \n" ; fi
                cp $SADM_TMP_FILE2 $filename                            # Tmp become new rch file
                if [ $? -ne 0 ] ; then sadm_write "Error copying $SADM_TMP_FILE2 $filename \n" ; fi
                done 

        else sadm_write  "No error rch files were found.\n" 
    fi

    sadm_write "Conversion of RCH file is now done.\n\n\n"
    touch ${SADM_CFG_DIR}/.rch_conversion_done                  # State that conversion done
    ls -l ${SADM_CFG_DIR}/.rch_conversion_done
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
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write "${SADM_OK}\n"
             fi
             sadm_write "  - chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR "
             chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On 'chown' operation for ${VALDIR}.\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
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
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write "${SADM_OK}\n"
             fi
             sadm_write "  - find $VAL_DIR -type f -exec chmod $VAL_OCTAL{} \; "
             find $VAL_DIR -type f -exec chmod $VAL_OCTAL {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On 'chmod' operation of ${VALDIR}.\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
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

    # Path is needed to perform NFS Backup (It doesn't exist by default on Mac)
    if [ "$SADM_OS_TYPE" = "DARWIN" ] && [ ! -d "/preserve/nfs" ]  # NFS Mount Point not exist
        then mkdir -p /preserve/nfs && chmod 775 /preserve/nfs          # Create NFS mount point
    fi

    set_dir "$SADM_BASE_DIR"      "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN Base Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_BIN_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN BIN Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_CFG_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN CFG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_DAT_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN DAT Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_DOC_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LIB Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_LIB_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LIB Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_LOG_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LOG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_PKG_DIR"        "775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN PKG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_SETUP_DIR"        "775" "$SADM_USER" "$SADM_GROUP"   # set Priv on setup Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_SYS_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN SYS Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_TMP_DIR"       "1777" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN TMP Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_USR_DIR"  "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User  Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_UBIN_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User bin Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_ULIB_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User lib Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_UDOC_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User Doc Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_UMON_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set SysMon Script User Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    # Subdirectories of $SADMIN/dat
    set_dir "$SADM_NMON_DIR"      "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN NMON Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_DR_DIR"        "0775" "$SADM_USER" "$SADM_GROUP"     # set Disaster Recovery Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_RCH_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set SADMIN RCH Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_DBB_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # Database Backup Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    set_dir "$SADM_NET_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set SADMIN Network Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_write "Total Error Count at ${ERROR_COUNT}.\n" ;fi

    # Taking care of lost+found directory (If present) in AIX and Linux.
    if [ -d "$SADM_BASE_DIR/lost+found" ]
        then if [ "$SADM_OS_TYPE" = "AIX" ]
                then set_dir "$SADM_BASE_DIR/lost+found" "4775" "root" "system"     # set SADMIN Network Dir
                else set_dir "$SADM_BASE_DIR/lost+found" "4775" "root" "root"     # set SADMIN Network Dir
             fi
    fi


#    # Remove Directory that should only be there on the SADMIN Server not the client.
#    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]
#       then sadm_write "\nRemove useless directories on client (if any) ...\n"
#            #
#            # Remove Database Backup Directory on SADMIN Client if it exist
#            if [ -d "$SADM_DBB_DIR" ] && [ "$SADM_HOST_TYPE" = "C" ]
#                then sadm_write "Directory $SADM_DBB_DIR should exist only on SADMIN server.\n"
#                     sadm_write "I am deleting it now.\n"
#                     rm -fr $SADM_DBB_DIR
#            fi
#            # Remove Network Scan Directory on SADMIN Client if it exist
#            if [ -d "$SADM_NET_DIR" ] && [ "$SADM_HOST_TYPE" = "C" ]
#                then sadm_write "Directory $SADM_NET_DIR should exist only on SADMIN server.\n"
#                     sadm_write "I am deleting it now.\n"
#                     rm -fr $SADM_NET_DIR
#            fi
#            # Remove Web Site Directory on SADMIN Client if it exist
#            #if [ -d "$SADM_WWW_DIR" ] && [ "$SADM_HOST_TYPE" = "C" ]
#            #    then sadm_write "Directory $SADM_WWW_DIR should exist only on SADMIN server.\n"
#            #         sadm_write "I am deleting it now.\n"
#            #         rm -fr $SADM_WWW_DIR
#            #fi
#            sadm_write "${SADM_TEN_DASH}\n"
#    fi
#
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
                then sadm_write "${SADM_ERROR} On 'chmod' operation on ${VAL_FILE}.\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write "${SADM_OK}\n"
             fi
             sadm_write "  - chown ${VAL_OWNER}:${VAL_GROUP} ${VAL_FILE} "
             chown ${VAL_OWNER}:${VAL_GROUP} ${VAL_FILE}
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On 'chown' operation on ${VAL_FILE}.\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
                else sadm_write "${SADM_OK}\n"
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
    
    # Remove files that should only be there on the SADMIN Server not the client.
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]
       then afile="$SADM_WWW_LIB_DIR/.crontab.txt"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            #afile="$SADM_CFG_DIR/alert_group.cfg"
            #if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            #afile="$SADM_CFG_DIR/alert_slack.cfg"
            #if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            afile="$SADM_CFG_DIR/.dbpass"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            #afile="$SADM_CFG_DIR/.alert_history.txt"
            #if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            afile="$SADM_CFG_DIR/.rch_conversion_done"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            #afile="$SADM_CFG_DIR/alert_history.txt"
            #if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
    fi

    # Remove default crontab job - We want to run the ReaR Backup from the sadm_rear_backup crontab.
    if [ -r /etc/cron.d/rear ] ; then rm -f /etc/cron.d/rear >/dev/null 2>&1; fi

    # Make sure some files have proper permission and owner
    set_file "/etc/cron.d/sadm_client"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_server"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_osupdate"     "0644" "root" "root"
    set_file "/etc/cron.d/sadm_backup"       "0644" "root" "root"
    set_file "/etc/cron.d/sadm_rear_backup"  "0644" "root" "root"

    # SADMIN Readme, changelog and license file.
    set_file "${SADM_BASE_DIR}/readme.md"    "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/readme.html"  "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/readme.pdf"   "0644" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/LICENSE"      "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/license"      "0664" "${SADM_USER}" "${SADM_GROUP}" 
    set_file "${SADM_BASE_DIR}/changelog.md" "0664" "${SADM_USER}" "${SADM_GROUP}" 
    

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


    sadm_write "\n"
    sadm_write "${BOLD}SADMIN Files Pruning.${NORMAL}\n"

    # Remove files older than 7 days in SADMIN TMP Directory
    if [ -d "$SADM_TMP_DIR" ]
        then sadm_write "  - Remove any unmodified file(s) for more than 7 days in ${SADM_TMP_DIR}.\n"
             sadm_write "    - find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -mtime +7 -exec ls -l {} \; >> $SADM_LOG
             find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write " ${SADM_ERROR} On last pruning operation.\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write " ${SADM_OK}\n"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
             fi
             sadm_write "  - Remove all pid files once a day - This prevent script from not running.\n"
             sadm_write "    - find $SADM_TMP_DIR  -type f -name '*.pid' -exec rm -f {} \; "
             #find $SADM_TMP_DIR  -type f -name "*.pid" -exec ls -l {} \; >> $SADM_LOG
             find $SADM_TMP_DIR  -type f -name "*.pid" -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_write "${SADM_ERROR} On last pruning operation.\n"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
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
                     ERROR_COUNT=$(($ERROR_COUNT+1))
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
                     ERROR_COUNT=$(($ERROR_COUNT+1))
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
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_write "${SADM_OK}\n"
             fi
             if [ $ERROR_COUNT -ne 0 ] ;then sadm_write "Total Error at ${ERROR_COUNT}\n" ;fi
    fi

    return $ERROR_COUNT
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

    # Check if 'sadmin' group exist - If not create it.
    if [ "$SADM_OS_TYPE" != "DARWIN" ]                                  # If not on MacOS
        then grep "^${SADM_GROUP}:"  /etc/group >/dev/null 2>&1         # $SADMIN Group Defined ?
             if [ $? -ne 0 ]                                            # SADM_GROUP not Defined
                then sadm_write "Group ${SADM_GROUP} not present.\."    # Advise user will create
                     sadm_write "Create group or change 'SADM_GROUP' value in $SADMIN/sadmin.cfg\m"
                     #sadm_write "Creating the ${SADM_GROUP} group\n"   # Advise user will create
                     #groupadd ${SADM_GROUP}                            # Create SADM_GROUP
                     #if [ $? -ne 0 ]                                   # Error creating Group
                     #   then sadm_write "Error when creating group ${SADM_GROUP}.\n"
                     sadm_write "Process Aborted.\n"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
                    #fi
             fi
    fi

    # Check is 'sadmin' user exist user - if not create it and make it part of 'sadmin' group.
    if [ "$SADM_OS_TYPE" != "DARWIN" ]                                  # If not on MacOS
        then grep "^${SADM_USER}:" /etc/passwd >/dev/null 2>&1          # $SADMIN User Defined ?
             if [ $? -ne 0 ]                                            # NO Not There
                then sadm_write "User $SADM_USER not present.\n"        # usr in sadmin.cfg not found
                     sadm_write "Create user or change 'SADM_USER' value in $SADMIN/sadmin.cfg\n"
                     #sadm_write"The user will now be created.\n"       # Advise user will create
                     #useradd -d '/sadmin' -c 'SADMIN user' -g $SADM_GROUP -e '' $SADM_USER
                     #if [ $? -ne 0 ]                                   # Error creating user
                     #   then sadm_write "Error when creating user ${SADM_USER}.\n"
                     sadm_write "Process Aborted.\n"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
                     #fi
             fi
    fi

    # Convert all local RCH file from 9 fields to 10 fields (New format), if not already done
    rch_conversion                                                      # Convert RCH Format to new

    #sadm_write "FQDN = $(sadm_get_fqdn) - SADM_SERVER = ${SADM_SERVER}\n"
    dir_housekeeping                                                    # Do Dir HouseKeeping
    DIR_ERROR=$?                                                        # ReturnCode = Nb. of Errors
    file_housekeeping                                                   # Do File HouseKeeping
    FILE_ERROR=$?                                                       # ReturnCode = Nb. of Errors
    check_sadmin_account                                                # Check sadmin Acc. if Lock
    ACC_ERROR=$?                                                        # Return 1 if Locked 

    SADM_EXIT_CODE=$(($DIR_ERROR+$FILE_ERROR+$ACC_ERROR))               # Error= DIR+File+Lock Func.
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
