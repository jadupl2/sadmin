#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_uninstall.sh
#   Date        :   2019/-3/23
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Uninstall SADMIN from system.
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <sadmlinux@gmail.com>.
#   Developer Web Site : http://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# Version Change Log 
#
# 2019_03_23 New: v1.0 Beta - Test Initial version.
# 2019_03_26 New: v1.1 Beta - Ready to Test 
# 2019_04_06 New: v1.2 Version after testing client removal.
# 2019_04_07 New: v1.3 Uninstall script production release.
# 2019_04_08 Update: v1.4 Remove 'sadmin' line in /etc/hosts, only when uninstalling SADMIN server.
# 2019_04_11 Update: v1.5 Show if we are uninstalling a 'client' or a 'server' on confirmation msg.
# 2019_04_14 Fix: v1.6 Don't show password when entering it, correct problem dropping database.
# 2019_04_14 Fix: v1.7 Remove user before dropping database
# 2019_04_17 Update: v1.8 When quitting script, remove pid file and print abort message.
# 2019_06_25 Update: v1.9 Minor code update (use SADM_DEBUG instead of DEBUG_LEVEL).
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # INTERCEPTE LE ^C
#set -x
     



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.50
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null 
         if [ $? -eq 0 ]                                   # Found SADMIN in /etc/env.
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.9'                                      # Script Version
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy ?
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. LockFile
export SADM_USE_RCH="Y"                                    # Update RCH HistoryFile 
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # LOAD SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Server
# ---------------------------------------------------------------------------------------


  

#===================================================================================================
# Scripts Variables 
#===================================================================================================
export DRYRUN=1                                                         # default Dry run activated  
export TMP_FILE1="$(mktemp /tmp/sadm_uninstall.XXXXXXXXX)"              # Temp File 1
export TMP_FILE2="$(mktemp /tmp/sadm_uninstall.XXXXXXXXX)"              # Temp File 2
export ROOTPWD=""                                                       # MySQL Root Password
#
command -v systemctl > /dev/null 2>&1                                   # Using sysinit or systemd ?
if [ $? -eq 0 ] ; then SYSTEMD=1 ; else SYSTEMD=0 ; fi                  # Set SYSTEMD Accordingly
export SYSTEMD                                                          # Export Result        
#



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-y   (Really remove SADMIN from this system)"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}



#---------------------------------------------------------------------------------------------------
#  ASK USER THE QUESTION RECEIVED  -  RETURN 0 (FOR NO) OR  1 (FOR YES)
#---------------------------------------------------------------------------------------------------
ask_user()
{
    wmess="$1 [y,n] ? "                                                 # Save MEssage Received
    wreturn=0                                                           # Function Default Value
    while :
        do
        echo -n "$wmess"                                                # Write mess rcv + [ Y/N ] ?
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;;
           n|N ) wreturn=0                                              # No = Return Value of 0
                 break                                                  # Break of the loop
                 ;;
             * ) ;;                                                     # Other stay in the loop
         esac
    done
   return $wreturn                                                      # Return 0=No 1=Yes
}



#---------------------------------------------------------------------------------------------------
#  Accept and validate MySQL Root Database access.
#---------------------------------------------------------------------------------------------------
validate_root_access()
{
    while :
        do
        printf "\nEnter MySQL root password (to delete sadmin database or 'q' to Quit) : "
        stty -echo                                                      # Hide Char Input
        read ROOTPWD                                                    # Enter MySQL root Password 
        stty echo                                                       # Show Char Input
        if [ "$ROOTPWD" = "" ]  ; then continue ; fi                    # No blank password
        if [ "$ROOTPWD" = "q" ] || [ "$ROOTPWD" = "Q" ]                 # Abort Script if 'q' input
            then printf "\nUninstall aborted ...\n\n"                   
                 rm -f $SADM_PID_FILE >/dev/null 2>&1                   # Remove PID FIle
                 exit 1 
        fi                                                              

        SQL="show databases;"
        CMDLINE="$SADM_MYSQL -uroot -p$ROOTPWD -h $SADM_DBHOST"
        printf "\nVerifying access to Database ... "
        if [ $SADM_DEBUG -gt 0 ] ; then printf "\n$CMDLINE -Ne 'show databases ;'\n" ; fi
        $CMDLINE -Ne 'show databases ;' >/dev/null 2>&1                 # Try SQL see if access work
        if [ $? -ne 0 ]
            then printf "\nAccess to database with the password given, don't work."
                 printf "\nPlease try again."
                 continue
            else printf "\nDatabase access confirmed ..." 
                 break
        fi
        done
    return 0
}



#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    # Show what type of SADMIN we are removing 
    if [ "$SADM_HOST_TYPE" = "S" ] 
        then printf "\n${BOLD}${CYAN}Uninstalling a SADMIN server.${NORMAL}"
             validate_root_access
        else printf "\n${BOLD}${CYAN}Uninstalling a SADMIN client.${NORMAL}"
    fi

    # Remove Backup crontab file in /etc/cron.d
    cfile="/etc/cron.d/sadm_backup" ; 
    if [ -f "$cfile" ]   
        then printf "\nRemoving backup crontab file $cfile ..." 
             if [ "$DRYRUN" -ne 1 ] ; then rm -f $cfile >/dev/null 2>&1 ; fi 
    fi

    # Remove Client crontab file in /etc/cron.d
    cfile="/etc/cron.d/sadm_client" ; 
    if [ -f "$cfile" ]   
        then printf "\nRemoving client crontab file $cfile ..." 
             if [ "$DRYRUN" -ne 1 ] ; then rm -f $cfile >/dev/null 2>&1 ; fi 
    fi

    # Remove Server crontab file in /etc/cron.d
    cfile="/etc/cron.d/sadm_server" ; 
    if [ -f "$cfile" ]   
        then printf "\nRemoving server crontab file $cfile ..." 
             if [ "$DRYRUN" -ne 1 ] ; then rm -f $cfile >/dev/null 2>&1 ; fi 
    fi

    # Remove Server OSupdate file in /etc/cron.d
    cfile="/etc/cron.d/sadm_osupdate" ; 
    if [ -f "$cfile" ]   
        then printf "\nRemoving osupdate crontab file $cfile ..." 
             if [ "$DRYRUN" -ne 1 ] ; then rm -f $cfile >/dev/null 2>&1 ; fi 
    fi

    # Remove Login SADMIN environment script
    cfile="/etc/profile.d/sadmin.sh" ; 
    if [ -f "$cfile" ]   
        then printf "\nRemoving profile script $cfile ..." 
             if [ "$DRYRUN" -ne 1 ] ; then rm -f $cfile >/dev/null 2>&1 ; fi 
    fi

    # Remove sadmin user sudo file
    cfile="/etc/sudoers.d/033_${SADM_USER}-nopasswd" ; 
    if [ -f "$cfile" ]   
        then printf "\nRemoving '${SADM_USER}' user sudo file $cfile ..." 
             if [ "$DRYRUN" -ne 1 ] ; then rm -f $cfile >/dev/null 2>&1 ; fi 
    fi


    # Remove sadmin user $SADM_USER
    id "$SADM_USER" >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then printf "\nRemoving sadmin user '$SADM_USER' ..." 
             if [ "$DRYRUN" -ne 1 ] ; then userdel -r $SADM_USER >/dev/null 2>&1 ; fi
    fi

     # Remove sadmin Group $SADM_GROUP
    id -g "$SADM_GROUP" >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then printf "\nRemoving sadmin group '$SADM_GROUP' ..." 
             if [ "$DRYRUN" -ne 1 ] ; then groupdel -r $SADM_GROUP >/dev/null 2>&1 ; fi
    fi

    # Make sure Database is accessible before trying to drop SADMIN database
    if [ "$SADM_HOST_TYPE" = "S" ] 
        then printf "\nMaking sure database is up ..." 
             RC=0
             if [ "$DRYRUN" -ne 1 ] ; then 
                if [ $SYSTEMD -eq 1 ]                                   # Using systemd not Sysinit
                    then systemctl restart mariadb.service >/dev/null 2>&1 # Systemd Restart MariaDB
                         RC=$?                                          # Save Return Code
                    else /etc/init.d/mysql restart >/dev/null 2>&1      # SystemV Restart MariabDB
                         RC=$?                                          # Save Return Code
                fi
             fi
             if [ $RC -eq 0 ] 
                then printf "\nRemoving database user '$SADM_RO_DBUSER' ..."
                     SQL="delete from mysql.user where user = '$SADM_RO_DBUSER';" 
                     if [ $SADM_DEBUG -gt 0 ] 
                        then printf "\n$CMDLINE $SADM_DBNAME -Ne $SQL"
                     fi
                     if [ "$DRYRUN" -ne 1 ] ;then $CMDLINE $SADM_DBNAME -Ne "$SQL" ;fi
                     
                     printf "\nRemoving database user '$SADM_RW_DBUSER' ..."
                     SQL="delete from mysql.user where user = '$SADM_RW_DBUSER';" 
                     if [ $SADM_DEBUG -gt 0 ] 
                        then printf "\n$CMDLINE $SADM_DBNAME -Ne $SQL"
                     fi
                     if [ "$DRYRUN" -ne 1 ] ;then $CMDLINE $SADM_DBNAME -Ne "$SQL" ;fi
                     
                     SQL="drop database sadmin;" 
                     CMDLINE="$SADM_MYSQL -u root  -p$ROOTPWD -h $SADM_DBHOST "
                     if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi  
                     printf "\nDropping 'sadmin' database ..." 
                     if [ $SADM_DEBUG -gt 0 ] 
                        then printf "\n$CMDLINE -Ne $SQL"
                     fi
                     if [ "$DRYRUN" -ne 1 ] ; then $CMDLINE -Ne "$SQL" ; fi
                     #
                     #printf "\nRemoving database user '$SADM_RW_DBUSER' ..."
                     #SQL="DELETE FROM mysql.user WHERE user = '$SADM_RW_DBUSER';"
                     #$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
                     #
             fi

            # Remove SADMIN line in /etc/hosts
             if [ -f /etc/hosts ] 
                then printf "\nRemoving 'SADMIN' line in /etc/hosts" 
                     grep -iv "sadmin" /etc/hosts > $TMP_FILE2
                     if [ "$DRYRUN" -ne 1 ] ; then cp $TMP_FILE2 /etc/hosts ; fi
             fi
    fi
    
    # Remove SADMIN line in /etc/environment
    if [ -f /etc/environment ] 
        then printf "\nRemoving 'SADMIN' line in /etc/environment ..." 
             grep -iv "sadmin" /etc/environment > $TMP_FILE2
             if [ "$DRYRUN" -ne 1 ] ; then cp $TMP_FILE2 /etc/environment ; fi
    fi

   # Remove Directory structure 'rm -fr $SADMIN'
   if [ -r "$SADMIN/lib/sadmlib_std.sh" ]                   # SADMIN Shell Library readable ?
        then cd /
             printf "\nRemoving directory structure $SADMIN ..."
             if [ "$DRYRUN" -ne 1 ] ; then rm -fr "$SADMIN" >/dev/null 2>&1 ; fi
    fi

    if [ "$SADM_HOST_TYPE" = "S" ] 
        then printf "\n${BOLD}${CYAN}Uninstall of SADMIN server completed.${NORMAL}"
        else printf "\n${BOLD}${CYAN}Uninstall of SADMIN client completed.${NORMAL}"
    fi
    printf "\n\n"                                                         # Blank line separation
    return 0                                                            # Return ErrorCode to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvyd:" opt ; do                                      # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            y) DRYRUN=0                                                 # DeActivate DryRun
               ;;                                                       # No stop after each page
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
    if [ $SADM_DEBUG -gt 0 ]   ; then printf "\nDebug activated, Level ${SADM_DEBUG}\n" ; fi


    # Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    
    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    if [ $DRYRUN -eq 1 ]                                                # Dry Run Activated
        then printf "${BOLD}${YELLOW}Dry Run activated"       # Inform User
             printf "\nUse '-y' to really remove 'SADMIN' from this system${NORMAL}\n"
        else if [ "$SADM_HOST_TYPE" = "S" ] ;then STYPE="Server" ;else STYPE="Client" ;fi
             ask_user "This will remove 'SADMIN ${STYPE}' from this system, Are you sure" # Not DryRun
             if [ $? -eq 0 ]                                            # don't want to Del SADMIN
                then sadm_stop 0                                        # Close log,rch - rm tmp&pid
                     exit $SADM_EXIT_CODE                               # Exit to O/S
             fi
    fi 

    # MAIN SCRIPT PROCESS HERE ---------------------------------------------------------------------
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    
    if [ $DRYRUN -eq 1 ]                                                # Dry Run Activated
        then sadm_stop $SADM_EXIT_CODE                                  # Only in DryMode Else Error
    fi
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    