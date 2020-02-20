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
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # Is 'SADMIN' environment variable defined ?. If not try to use /etc/environment SADMIN value.
    if [ -z $SADMIN ] || [ "$SADMIN" = "" ]                             # If SADMIN EnvVar not right
        then missetc="Missing /etc/environment file, create it and add 'SADMIN=/InstallDir' line." 
             if [ ! -e /etc/environment ] ; then printf "${missetc}\n" ; exit 1 ; fi
             missenv="Please set 'SADMIN' environment variable to the install directory."
             grep "^SADMIN" /etc/environment >/dev/null 2>&1            # SADMIN line in /etc/env.? 
             if [ $? -eq 0 ]                                            # Yes use SADMIN definition
                 then export SADMIN=`grep "^SADMIN" /etc/environment | awk -F\= '{ print $2 }'` 
                      misstmp="Temporarily setting 'SADMIN' environment variable to '${SADMIN}'."
                      missvar="Add 'SADMIN=${SADMIN}' in /etc/environment to suppress this message."
                      if [ ! -e /bin/launchctl ] ; then printf "${missvar}" ; fi 
                      printf "\n${missenv}\n${misstmp}\n\n"
                 else missvar="Add 'SADMIN=/InstallDir' in /etc/environment to remove this message."
                      printf "\n${missenv}\n$missvar\n"                 # Recommendation to user    
                      exit 1                                            # Back to shell with Error
             fi
    fi 
        
    # Check if the SADMIN Shell Library is accessible, if not advise user and exit with error.
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                            # Shell Library not readable
        then missenv="Please set 'SADMIN' environment variable to the install directory."
             printf "${missenv}\nSADMIN library ($SADMIN/lib/sadmlib_std.sh) can't be located\n"     
             exit 1                                                     # Exit to Shell with Error
    fi

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='2.5'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library
    export SADM_OS_NAME=$(sadm_get_osname)              # Uppercase, REDHAT,CENTOS,UBUNTU,AIX,DEBIAN
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
    sadm_writelog "${yellow}Archive Alert older than $ARC_DAYS days.${white}"

    # If History archive doesn't exist, create it.
    if [ ! -f "$SADM_ALERT_ARCHIVE" ]                                   # If Archive don't exist
        then cp $SADM_ALERT_ARCINI $SADM_ALERT_ARC                      # Create Initial Archive
             chmod 664 $SADM_ALERT_ARC 
             chown $SADM_USER:$SADM_GROUP $SADM_ALERT_ARC
    fi 

    # Create Initial New Purge History File
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
                 sadm_writelog "Archiving: $ldate $ltime $lhost $lmess"
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
    sadm_writelog " "
    sadm_writelog "${yellow}Server Directories HouseKeeping.${white}"

    # Reset privilege on WWW Directory files
    if [ -d "$SADM_WWW_DIR" ]
        then CMD="find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \;"
             find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "[ ERROR ] running $CMD"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "[ OK ] $CMD"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             CMD="find $SADM_WWW_DIR -exec chown -R ${SADM_WWW_USER}:${SADM_WWW_GROUP} {} \;"
             find $SADM_WWW_DIR  -exec chown -R ${SADM_WWW_USER}:${SADM_WWW_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "[ ERROR ] running $CMD"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "[ OK ] $CMD"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_writelog " "
    sadm_writelog "${yellow}Server Files HouseKeeping.${white}"

    # Make sure crontab for SADMIN server have proper permission and owner
    sadm_writelog "Make sure SADMIN crontab file have proper permission and owner"
    afile="/etc/cron.d/sadm_server"
    if [ -f "$afile" ]
        then CMD="chmod 0644 $afile && chown root:root $afile"
             chmod 0644 $afile && chown root:root $afile 
             if [ $? -ne 0 ]
                then sadm_writelog "[ ERROR ] running $CMD"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "[ OK ] running $CMD"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Make sure crontab for O/S Update have proper permission and owner
    afile="/etc/cron.d/sadm_osupdate"
    if [ -f "$afile" ]
        then CMD="chmod 0644 $afile && chown root:root $afile"
             chmod 0644 $afile && chown root:root $afile 
             if [ $? -ne 0 ]
                then sadm_writelog "[ ERROR ] running $CMD"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "[ OK ] running $CMD"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Make sure crontab for Backup have proper permission and owner
    afile="/etc/cron.d/sadm_backup"
    if [ -f "$afile" ]
        then CMD="chmod 0644 $afile && chown root:root $afile"
             chmod 0644 $afile && chown root:root $afile 
             if [ $? -ne 0 ]
                then sadm_writelog "[ ERROR ] running $CMD"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "[ OK ] running $CMD"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Set Permission on all files in the images directory.
    sadm_writelog " "
    sadm_writelog "Setting permissions in the website directories."
    CMD="find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \;"
    find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "[ ERROR ] running $CMD"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "[ OK ] running $CMD"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.php files 
    CMD="find $SADM_WWW_DIR -type f -name *.php -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.php -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "[ ERROR ] running $CMD"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "[ OK ] running $CMD"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.css files 
    CMD="find $SADM_WWW_DIR -type f -name *.css -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.css -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "[ ERROR ] running $CMD"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "[ OK ] running $CMD"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.js files 
    CMD="find $SADM_WWW_DIR -type f -name *.js -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.js -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "[ ERROR ] running $CMD"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "[ OK ] running $CMD"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.rrd files 
    CMD="find $SADM_WWW_DIR -type f -name *.rrd -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.rrd -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "[ ERROR ] running $CMD"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "[ OK ] running $CMD"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.pdf files 
    CMD="find $SADM_WWW_DIR -type f -name *.pdf -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.pdf -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "[ ERROR ] running $CMD"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "[ OK ] running $CMD"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all files in www/dat directories.
    CMD="find $SADM_WWW_DAT_DIR -type f -exec chmod 664 {} \;"
    find $SADM_WWW_DAT_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "[ ERROR ] running $CMD"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "[ OK ] running $CMD"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Delete performance graph (*.png) generated by web interface older than 5 days.
    if [ -d "$SADM_WWW_PERF_DIR" ]
        then sadm_writelog " " 
             sadm_writelog "Delete any *.png files older than 5 days in ${SADM_WWW_PERF_DIR}."
             CMD="find $SADM_WWW_PERF_DIR -type f -mtime +5 -name '*.png' -exec rm -f {} \;"
             find $SADM_WWW_PERF_DIR -type f -mtime +5 -name "*.png" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_writelog "[ ERROR ] running $CMD"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "[ OK ] running $CMD"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi


    return $ERROR_COUNT
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
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

# If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Del PID
             exit 1                                                     # Exit To O/S with error
    fi

    alert_housekeeping                                                  # Prune Alert History File
    if [ $? -eq 0 ]
       then sadm_writelog "[ OK ] Alert archiving done."
       else sadm_writelog "[ ERROR ] while archiving alert."
            ERROR_COUNT=$(($ERROR_COUNT+1))
    fi 
    dir_housekeeping                                                    # Do Dir HouseKeeping
    file_housekeeping                                                   # Do File HouseKeeping

    if [ $ERROR_COUNT -ne 0 ] ; then SADM_EXIT_CODE=1 ; else SADM_EXIT_CODE=0 ; fi
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
