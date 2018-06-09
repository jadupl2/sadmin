#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_dev_housekeeping.sh
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
# 2017_01_27    v1.6 Cosmetic Changes to improve log Details
# 2017_10_02    v1.7 Added housekeeping for sadmin.ca web site under wsadmin directory
# 2018_06_04    v1.8 Change $SADMIN/jac sub-directory to $SADMIN/usr
# 2018_06_07    v1.9 Remove some chrome files left over when chrome die unexpectedly
#                   Give chown error
#                   http://www.eupcs.org/wiki/Google_Chrome
#                   rm -f ~/.config/google-chrome/SingletonCookie > /dev/null 2>&1
#                   rm -f ~/.config/google-chrome/SingletonLock >/dev/null 2>&1
#                   rm -f ~/.config/google-chrome/SingletonSocket  > /dev/null 2>&1
# 2018_06_08    v2.0 Don't show error counter when zero and small corrections
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.0'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================






# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose

# This is a counter that is incremented each time an error occured
ERROR=0                               ; export ERROR        # Error Counter

# Number of days to keep unmodified *.rch and *.log file - After that time they are deleted
LIMIT_DAYS=60                               ; export LIMIT_DAYS         # RCH+LOG Delete after

# Development Local sadmin.ca Web Site Directory 
WSADMIN="/wsadmin" 



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
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR";fi
            fi
    fi

    if [ -d "/mystuff" ]
        then sadm_writelog " "
             sadm_writelog "MyStuff Accessibility"
             sadm_writelog "find /mystuff -exec chown jacques.${jgroup} {} \;"
             find /mystuff -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR";fi
            fi
    fi

    if [ -d "/home/jacques" ]
        then sadm_writelog " "
             # Remove these files when Chrome is closed unexpectedly - Give backup error
             # http://www.eupcs.org/wiki/Google_Chrome
             rm -f ~/.config/google-chrome/SingletonCookie > /dev/null 2>&1
             rm -f ~/.config/google-chrome/SingletonLock >/dev/null 2>&1
             rm -f ~/.config/google-chrome/SingletonSocket  > /dev/null 2>&1
             sadm_writelog "Jacques Home Directory"
             sadm_writelog "find /home/jacques -exec chown jacques.${jgroup} {} \;"
             find /home/jacques -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             # Ignore chown error for my home dir.
             #if [ $? -ne 0 ]
             #   then sadm_writelog "Error occured on the last operation."
             #        ERROR=$(($ERROR+1))
             #   else sadm_writelog "OK"
             #        sadm_writelog "Total Error Count at $ERROR"
             #fi
    fi

    if [ -d "/install" ]
        then sadm_writelog " "
             sadm_writelog "/install Directory"
             sadm_writelog "find /install -exec chown jacques.${jgroup} {} \;"
             find /install -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
            fi
    fi

    if [ -d "/os" ]
        then sadm_writelog " "
             sadm_writelog "Linux ISO Accessibility"
             sadm_writelog "find /os -exec chown jacques.${jgroup} {} \;"
             find /os -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
             sadm_writelog "find /os -exec chmod 775 {} \;"
             find /os -exec chmod 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error occured on the last operation."
                      ERROR=$(($ERROR+1))
                 else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
    fi

    if [ -d "/sysadmin" ]
        then sadm_writelog " "
             sadm_writelog "SysAdmin Accessibility by Jacques"
             sadm_writelog "find /sysadmin -exec chown jacques.${jgroup} {} \;"
             find /sysadmin -exec chown jacques.${jgroup} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
    fi

    if [ -d "/wsadmin" ]
        then sadm_writelog " "
             sadm_writelog "/wsadmin - sadmin.ca development web site " 
             sadm_writelog "find /wsadmin -exec chown apache.apache {} \;"
             find /wsadmin -exec chown apache.apache {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
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
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR";fi
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
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR";fi
             fi
    fi


    # Make sure ${SADM_USR_DIR} directory have right permission and privilege
    if [ -d "$SADM_USR_DIR" ]
        then sadm_writelog " "
             sadm_writelog "Make sure ${SADM_USR_DIR} have right owner"
             sadm_writelog "chown ${SADM_USER}.${SADM_GROUP} ${SADM_USR_DIR}"
             chown ${SADM_USER}.${SADM_GROUP} ${SADM_USR_DIR}
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on chown ${SADM_USR_DIR}"
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR";fi
              fi
             sadm_writelog " "
             sadm_writelog "Make sure ${SADM_USR_DIR} have right permission"
             sadm_writelog "chmod 0775 ${SADM_USR_DIR}"
             chmod 0775 ${SADM_USR_DIR}
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
    fi

    # Set Privilege and Permission on /sadmin/usr ${SADM_USR_DIR} subdirectories
    if [ -d "${SADM_USR_DIR}" ]
        then sadm_writelog " "
             sadm_writelog "find ${SADM_USR_DIR} -type d -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find ${SADM_USR_DIR} -type d -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
             sadm_writelog " "
             sadm_writelog "find ${SADM_USR_DIR} -type d -exec chmod 775 {} \;"       # Change Dir.
             find ${SADM_USR_DIR} -type d -exec chmod 775 {} \; >/dev/null 2>&1     # Change Dir.
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
    fi
    return $ERROR
}



# --------------------------------------------------------------------------------------------------
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_writelog " " ;
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "FILES HOUSEKEEPING STARTING"
    sadm_writelog "${SADM_TEN_DASH}"

    # Set Owner and Group on directory /sadmin/usr ${SADM_USR_DIR} 
    if [ -d "${SADM_USR_DIR}" ]
        then sadm_writelog " "
             sadm_writelog "find ${SADM_USR_DIR} -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find ${SADM_USR_DIR} -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
    fi

    # Set Permission on /sadmin/usr/cfg directories
    if [ -d "${SADM_USR_DIR}/cfg" ]
        then sadm_writelog " "
             sadm_writelog "find ${SADM_USR_DIR}/cfg -type f -exec chmod -R 664 {} \;"
             find ${SADM_USR_DIR}/cfg -type f -exec chmod -R 664 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
    fi

    # Set privilege on /sadmin/usr/bin files
    if [ -d "${SADM_UBIN_DIR}" ]
        then sadm_writelog " "
             sadm_writelog "find ${SADM_UBIN_DIR} -type f -exec chmod -R 770 {} \;"    # Advise user
             find ${SADM_UBIN_DIR} -type f -exec chmod -R 774 {} \; >/dev/null 2>&1  # Script Priv.
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
             fi
    fi

    # Remove logwatch from sending an email every morning
    if [ -f /etc/cron.daily/0logwatch ]
       then sadm_writelog " "
            sadm_writelog "Removing /etc/cron.daily/0logwatch"          # Advise user
            rm -f /etc/cron.daily/0logwatch >/dev/null 2>&1             # Red Hat / CentOS 5 an Up
            if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
            fi
    fi

    # Remove logwatch from sending an email every morning
    if [ -f /etc/cron.daily/00-logwatch ]
       then sadm_writelog " "
            sadm_writelog "Removing /etc/cron.daily/00-logwatch"        # Advise user
            rm -f /etc/cron.daily/00-logwatch >/dev/null 2>&1           # Red Hat 4 and below
            if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR=$(($ERROR+1))
                else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
            fi
    fi

    return $ERROR
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
    sadm_writelog "Delete files in /tmp that have not been modified for 35 days"
    sadm_writelog "find /tmp -type f -mtime +35 -exec rm -f {} \\;"
    find /tmp -type f -mtime +35 -exec rm -f {} \; >/dev/null 2>&1
    if [ $? -ne 0 ]
        then sadm_writelog "Error occured on the last operation."
             ERROR=$(($ERROR+1))
        else sadm_writelog "OK"
                     if [ "$ERROR" -ne 0 ] ;then sadm_writelog "Total Error at $ERROR" ;fi
    fi
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File

    
    # If you want this script to be run only by 'root'.
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo %s" "${0##*/}"                          # Suggest using sudo
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S with error
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

    SADM_EXIT_CODE=$ERROR                                         # Error COunt = Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
