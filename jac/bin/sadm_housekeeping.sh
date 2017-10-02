#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_housekeeping.sh
#   Synopsis : .Make some general housekeeping that we run once daily to get things running smoothly
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh

#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tool are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
# --------------------------------------------------------------------------------------------------
# 1.6 - 2017_01_27 - Cosmetic Changes to improve log Details

# 2017_10_02 - JDuplessis
#   V1.7 Added housekeeping for sadmin.ca web site under wsadmin directory

# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_VER='1.7'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose

# This is a counter that is incremented each time an error occured
ERROR_COUNT=0                               ; export ERROR_COUNT        # Error Counter

# Number of days to keep unmodified *.rch and *.log file - After that time they are deleted
LIMIT_DAYS=60                               ; export LIMIT_DAYS         # RCH+LOG Delete after

# Development Local sadmin.ca Web Site Directory 
WSADMIN = "/wsadmin" 



# --------------------------------------------------------------------------------------------------
#                               General Directories Housekeeping Function
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "MY DIRECTORIES HOUSEKEEPING STARTING"
    sadm_writelog "${SADM_TEN_DASH}"
    jgroup=`id -gn jacques`                                           # Get Jacques's Group

    if [ -d "/stbackups" ]
        then sadm_writelog " "
             sadm_writelog "Storix ISO Accessibility"
             sadm_writelog "find /stbackups -exec chown jacques.${jgroup} {} \;"
             find /stbackups -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
            fi
    fi

    if [ -d "/mystuff" ]
        then sadm_writelog " "
             sadm_writelog "MyStuff Accessibility"
             sadm_writelog "find /mystuff -exec chown jacques.${jgroup} {} \;"
             find /mystuff -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
            fi
    fi

    if [ -d "/home/jacques" ]
        then sadm_writelog " "
             sadm_writelog "Jacques Home Directory"
             sadm_writelog "find /home/jacques -exec chown jacques.${jgroup} {} \;"
             find /home/jacques -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
            fi
    fi

    if [ -d "/install" ]
        then sadm_writelog " "
             sadm_writelog "/install Directory"
             sadm_writelog "find /install -exec chown jacques.${jgroup} {} \;"
             find /install -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
            fi
    fi

    if [ -d "/os" ]
        then sadm_writelog " "
             sadm_writelog "Linux ISO Accessibility"
             sadm_writelog "find /os -exec chown jacques.${jgroup} {} \;"
             find /os -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find /os -exec chmod 775 {} \;"
             find /os -exec chmod 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error occured on the last operation."
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "OK"
                      sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    if [ -d "/sysadmin" ]
        then sadm_writelog " "
             sadm_writelog "SysAdmin Accessibility by Jacques"
             sadm_writelog "find /sysadmin -exec chown jacques.${jgroup} {} \;"
             find /sysadmin -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    if [ -d "/wsadmin" ]
        then sadm_writelog " "
             sadm_writelog "/wsadmin - sadmin.ca development web site " "
             sadm_writelog "find /wsadmin -exec chown apache.apache {} \;"
             find /wsadmin -exec chown apache.apache {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Keep only 60 days of puppet reports online
    if [ -d "/var/lib/puppet/reports" ]
        then sadm_writelog " "
             sadm_writelog "Keep only 60 days of puppet reports online"
             sadm_writelog "find /var/lib/puppet/reports -type f -mtime +60 -name "*.yaml" -exec rm -f {} \;"
             find /var/lib/puppet/reports -type f -mtime +60 -name "*.yaml" -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi


    # Make sure directory exist - Contains Storix Custom Scripts Distributed by sadm_rsync_sadmin.sh
    if [ ! -d "/storix/custom" ]
        then sadm_writelog " "
             sadm_writelog "Creating /storix/custom"
             sadm_writelog "mkdir -p /storix/custom"
             mkdir -p /storix/custom > /dev/null
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi


    # Make sure directory exist - Contains Storix Custom Scripts Distributed by sadm_rsync_sadmin.sh
    if [ -d "/sadmin/jac" ]
        then sadm_writelog " "
             sadm_writelog "Make sure /sadmin/jac have right owner"
             sadm_writelog "chown ${SADM_USER}.${SADM_GROUP} /sadmin/jac"
             chown ${SADM_USER}.${SADM_GROUP} /sadmin/jac
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
              fi
             sadm_writelog " "
             sadm_writelog "Make sure /sadmin/jac have right permission"
             sadm_writelog "chmod 0775 /sadmin/jac"
             chmod 0775 /sadmin/jac
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog " "
             sadm_writelog "Make sure /sadmin/jac have right permission"
             sadm_writelog "chmod g-s /sadmin/jac"
             chmod g-s /sadmin/jac
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

     # Reset privilege on directory in /sadmin/jac
    if [ -d "$SADM_BASE_DIR/jac" ]
        then sadm_writelog " "
             sadm_writelog "find $SADM_BASE_DIR/jac -type d -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"       # Change Dir.
             find $SADM_BASE_DIR/jac -type d -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1     # Change Dir.
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog " "
             sadm_writelog "find $SADM_BASE_DIR/jac -type d -exec chmod 775 {} \;"       # Change Dir.
             find $SADM_BASE_DIR/jac -type d -exec chmod 775 {} \; >/dev/null 2>&1     # Change Dir.
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_writelog " " ;
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "MY FILES HOUSEKEEPING STARTING"
    sadm_writelog "${SADM_TEN_DASH}"

    # Reset privilege on directory /sadmin/jac
    if [ -d "$SADM_BASE_DIR/jac" ]
        then sadm_writelog " "
             sadm_writelog "find $SADM_BASE_DIR/jac -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $SADM_BASE_DIR/jac -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi


    # Reset privilege on notes directories
    if [ -d "$SADM_BASE_DIR/jac/notes" ]
        then sadm_writelog " "
             sadm_writelog "find $SADM_BASE_DIR/jac/notes -type f -exec chmod -R 664 {} \;"
             find $SADM_BASE_DIR/jac/notes -type f -exec chmod -R 664 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Reset privilege on /sadmin/jac/cfg directories
    if [ -d "$SADM_BASE_DIR/jac/cfg" ]
        then sadm_writelog " "
             sadm_writelog "find $SADM_BASE_DIR/jac/cfg -type f -exec chmod -R 664 {} \;"
             find $SADM_BASE_DIR/jac/cfg -type f -exec chmod -R 664 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Reset privilege on /sadmin files
    if [ -d "${SADM_BASE_DIR}/jac/bin" ]
        then sadm_writelog " "
             sadm_writelog "find ${SADM_BASE_DIR}/jac/bin -type f -exec chmod -R 770 {} \;"    # Advise user
             find ${SADM_BASE_DIR}/jac/bin -type f -exec chmod -R 774 {} \; >/dev/null 2>&1  # Script Priv.
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Remove logwatch from sending an email every morning
    if [ -f /etc/cron.daily/0logwatch ]
       then sadm_writelog " "
            sadm_writelog "Removing /etc/cron.daily/0logwatch"          # Advise user
            rm -f /etc/cron.daily/0logwatch >/dev/null 2>&1             # Red Hat / CentOS 5 an Up
            if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
            fi
    fi

    # Remove logwatch from sending an email every morning
    if [ -f /etc/cron.daily/00-logwatch ]
       then sadm_writelog " "
            sadm_writelog "Removing /etc/cron.daily/00-logwatch"        # Advise user
            rm -f /etc/cron.daily/00-logwatch >/dev/null 2>&1           # Red Hat 4 and below
            if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
            fi
    fi

    return $ERROR_COUNT
}

# --------------------------------------------------------------------------------------------------
#                               Special Housekeeping Function
# --------------------------------------------------------------------------------------------------
special_housekeeping()
{
    sadm_writelog " " ;
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "SPECIAL HOUSEKEEPING STARTING"
    sadm_writelog "${SADM_TEN_DASH}"

    rm -f ${SADM_DR_DIR}/*lsblk.txt  > /dev/null 2>&1

    # Once a day - Delete files in /tmp that have not been modified for 35 days
    sadm_writelog " "
    sadm_writelog "Once a day - Delete files in /tmp that have not been modified for 35 days"
    sadm_writelog "find /tmp -type f -mtime +35 -exec rm -f {} \\;"
    find /tmp -type f -mtime +35 -exec rm -f {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
        then sadm_writelog "Error occured on the last operation."
             ERROR_COUNT=$(($ERROR_COUNT+1))
        else sadm_writelog "OK"
             sadm_writelog "Total Error Count at $ERROR_COUNT"
    fi
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File

    # Insure that this script can only be run by the user root
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # If jacques user is not created - Let's created it and put user is sadmin group
    grep "^jacques:" /etc/passwd >/dev/null 2>&1                        # jacques User Defined ?
    if [ $? -ne 0 ]                                                     # NO Not There
        then sadm_writelog "User 'jacques' not present"                 # Advise user will create
             sadm_writelog "The user will now be created"               # Advise user will create
             useradd -c 'Jacques Duplessis' -g $SADM_GROUP -e '' jacques
             if [ $? -ne 0 ]                                            # Error creating user
                then sadm_writelog "Error when creating user 'jacques'"
                     sadm_writelog "Process Aborted"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
                else sadm_writelog "User 'jacques' now created"
             fi
    fi

    # Check and Change Owner and Group and Permission on Directories
    dir_housekeeping                                                    # Do Dir HouseKeeping

    # Check and Change Owner and Group and Permission on files
    file_housekeeping                                                   # Do File HouseKeeping

    # On time shot housekeeping or Special HouseKeeping
    special_housekeeping                                                # Correct Historical Change

    SADM_EXIT_CODE=$ERROR_COUNT                                         # Error COunt = Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
