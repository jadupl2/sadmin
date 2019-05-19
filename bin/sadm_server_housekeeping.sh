#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_server_housekeeping.sh
#   Synopsis :  Set Owner/Group, Priv/Protection on www sub-directories and cleanup www/tmp/perf dir.
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
#@2019_05_19    v2.4 Add server crontab file to housekeeping
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.4'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                   # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT            # Error Counter
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL            # Set Debug Level
yellow=$(tput setaf 3)                      ; export yellow                 # Yellow color
white=$(tput setaf 7)                       ; export white                  # White color

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
#                               General Directories Housekeeping Function
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    #sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "${yellow}Server Directories HouseKeeping.${white}"
    #sadm_writelog " "

    # Reset privilege on WWW Directory files
    if [ -d "$SADM_WWW_DIR" ]
        then sadm_writelog "find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \;"
             find $SADM_WWW_DIR -type d -exec chmod -R 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_WWW_DIR -exec chown -R ${SADM_WWW_USER}:${SADM_WWW_GROUP} {} \;"
             find $SADM_WWW_DIR  -exec chown -R ${SADM_WWW_USER}:${SADM_WWW_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
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
    #sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog " "
    sadm_writelog "${yellow}Server Files HouseKeeping.${white}"

    # Make sure crontab for SADMIN server have proper permission and owner
    afile="/etc/cron.d/sadm_server"
    if [ -f "$afile" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Make sure crontab for SADMIN server have proper permission and owner"
             sadm_writelog "chmod 0644 $afile"
             chmod 0644 $afile
             sadm_writelog "chown root:root $afile"
             chown root:root $afile
             lsline=`ls -l $afile`
             sadm_writelog "$lsline"
    fi

    # Make sure crontab for O/S Update have proper permission and owner
    afile="/etc/cron.d/sadm_osupdate"
    if [ -f "$afile" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Make sure crontab for O/S Update have proper permission and owner"
             sadm_writelog "chmod 0644 $afile"
             chmod 0644 $afile
             sadm_writelog "chown root:root $afile"
             chown root:root $afile
             lsline=`ls -l $afile`
             sadm_writelog "$lsline"
    fi

    # Make sure crontab for Backup have proper permission and owner
    afile="/etc/cron.d/sadm_backup"
    if [ -f "$afile" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Make sure crontab for Backup have proper permission and owner"
             sadm_writelog "chmod 0644 $afile"
             chmod 0644 $afile
             sadm_writelog "chown root:root $afile"
             chown root:root $afile
             lsline=`ls -l $afile`
             sadm_writelog "$lsline"
    fi

    # Set Permission on all files in the images directory.
    sadm_writelog " " 
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \;"
    find $SADM_WWW_IMG_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "Error occured on the last operation."
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "OK"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.php files 
    sadm_writelog "find $SADM_WWW_DIR -type f -name *.php -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.php -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "Error occured on the last operation."
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "OK"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.css files 
    sadm_writelog "find $SADM_WWW_DIR -type f -name *.css -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.css -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "Error occured on the last operation."
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "OK"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.js files 
    sadm_writelog "find $SADM_WWW_DIR -type f -name *.js -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.js -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "Error occured on the last operation."
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "OK"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.rrd files 
    sadm_writelog "find $SADM_WWW_DIR -type f -name *.rrd -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.rrd -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "Error occured on the last operation."
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "OK"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all *.txt files 
    sadm_writelog "find $SADM_WWW_DIR -type f -name *.txt -exec chmod 664 {} \;"
    find $SADM_WWW_DIR -type f -name *.txt -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "Error occured on the last operation."
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "OK"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Set Permission on all files in www/dat directories.
    sadm_writelog "find $SADM_WWW_DAT_DIR -type f -exec chmod 664 {} \;"
    find $SADM_WWW_DAT_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
       then sadm_writelog "Error occured on the last operation."
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else sadm_writelog "OK"
            if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
    fi

    # Delete performance graph (*.png) generated by web interface older than 5 days.
    if [ -d "$SADM_WWW_PERF_DIR" ]
        then sadm_writelog " " 
             sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Find any *.png files older than 5 days in $SADM_WWW_PERF_DIR and delete them."
             sadm_writelog "List of files that will be remove."
             find $SADM_WWW_PERF_DIR -type f -mtime +5 -name "*.png" -exec ls -l {} \; | tee -a $SADM_LOG
             find $SADM_WWW_PERF_DIR -type f -mtime +5 -name "*.png" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on remove process."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
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

    dir_housekeeping                                                    # Do Dir HouseKeeping
    file_housekeeping                                                   # Do File HouseKeeping
    SADM_EXIT_CODE=$ERROR_COUNT                                         # Error COunt = Exit Code
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
