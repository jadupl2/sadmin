#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_uninstall.sh
#   Date        :   2019/-3/23
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Uninstall SADMIN tools from the system.
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <sadmlinux@gmail.com>.
#   Developer Web Site : https://sadmin.ca
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
# 2019_09_20 install v2.0 Fixes & include new SADMIN section 1.52.
# 2023_12_21 install v2.1 Fix problem removing $SADMIN directories and update SADMIN section to v1.56.
# 2023_12_26 install v2.2 Remove sadmin web configuration and sudoers file.
# 2023_12_29 install v2.3 Add message to user "Removing web site configuration".
# 2024_02_18 install v2.4 Adapt to change done in 'Setup' script.
# 2024_02_18 install v2.5 Was not removing $SADMIN/www directory.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # INTERCEPT LE ^C
#set -x
     



# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.5'                                      # Script Version
export SADM_PDESC="Uninstall SADMIN from the system."      # Script Optional Desc.(Not use if empty)
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="S"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
export SADM_ALERT_TYPE=0                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------



  

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
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-y]${NORMAL}\t\t\tReally remove SADMIN from this system"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
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
        if [ $DRYRUN -eq 1 ]                                            # If Dry Run Activated
            then printf "\nEnter MySQL 'root' password to connect to 'sadmin' database or 'q' to Quit : "
            else printf "\nEnter MySQL 'root' password (to delete 'sadmin' database or 'q' to Quit) : "
        fi 
        stty -echo                                                      # Hide Char Input
        read ROOTPWD                                                    # Enter MySQL root Password 
        stty echo                                                       # Show Char Input
        if [ "$ROOTPWD" = "" ]  ; then continue ; fi                    # No blank password
        if [ "$ROOTPWD" = "q" ] || [ "$ROOTPWD" = "Q" ]                 # Abort Script if 'q' input
            then printf "\nUninstall aborted ...\n\n"                   
                 rm -f $SADM_PID_FILE >/dev/null 2>&1                   # Remove PID FIle
                 exit 1 
        fi                                                              

        SQL="show databases;"                                           # Sql to execute in Database
        CMDLINE="$SADM_MYSQL -uroot -p$ROOTPWD -h $SADM_DBHOST"         # Connect String
        printf "\nVerifying access to database ... "
        if [ $SADM_DEBUG -gt 0 ] ; then printf "\n$CMDLINE -Ne 'show databases ;'\n" ; fi
        $CMDLINE -Ne 'show databases ;' >/dev/null 2>&1                 # Try SQL see if access work
        if [ $? -ne 0 ]
            then printf "\nAccess to database with the given password, don't work."
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

    # Show user we are running in Dry Run mode (If user did not specify '-y' on cli).
    # If '-y' is specified on command line, ask user to confirm that he wish to uninstall SADMIN.
    if [ $DRYRUN -eq 1 ]                                                # Dry Run Activated
        then printf "\n${BOLD}${YELLOW}Running in Dry run mode, no changes will be made." 
             printf "\nUse '-y' to really remove 'SADMIN' from this system.${NORMAL}\n"
        else if [ "$SADM_HOST_TYPE" = "S" ] ;then STYPE="Server" ;else STYPE="Client" ;fi
             ask_user "Sure you want to remove 'SADMIN ${STYPE}' on this system"
             if [ $? -eq 0 ]                                            # don't want to Del SADMIN
                then sadm_stop 0                                        # Close log,rch - rm tmp&pid
                     exit $SADM_EXIT_CODE                               # Exit to O/S
             fi
    fi 

    # Show what type of SADMIN we are removing 
    if [ "$SADM_HOST_TYPE" = "S" ] 
        then printf "\n${BOLD}${CYAN}Uninstalling a SADMIN server.${NORMAL}"
             validate_root_access
        else printf "\n${BOLD}${CYAN}Uninstalling a SADMIN client.${NORMAL}"
    fi

    sservice="httpd"
    if [ "$SADM_OS_NAME" = "DEBIAN" ] || [ "$SADM_OS_NAME" = "UBUNTU" ] ||  
       [ "$SADM_OS_NAME" = "MINT" ]   || [ "$SADM_OS_NAME" = "RASPBIAN" ] 
        then sservice="apache2" 
    fi

    # Remove web sever SADMIN
    if [ "$DRYRUN" -eq 0 ]                                              # 0 = Is Not a dry run 
        then printf "\nStopping web interface '$sservice'."
             systemctl stop $sservice >/dev/null 2>&1
             printf "\nRemove 'sadmin' web site configuration." 
             if [ "$sservice" = "httpd" ] 
                then f="/etc/httpd/conf.d/sadmin.conf" 
                     if [ -r "$f" ]  ; then rm -f "$f"  ; fi
                else f="/etc/apache2/sites-available/sadmin.conf"
                     if [ -r "$f" ]  ; then rm -f "$f"  ; fi
                     f="/etc/apache2/sites-enabled/sadmin.conf"
                     if [ -r "$f" ]  ; then rm -f "$f"  ; fi
             fi
        else printf "\nWould stop the web interface '$sservice'." 
             printf "\nWould remove 'sadmin' web site configuration." 
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

    # Remove sadmin user sudo file
    cfile="/etc/sudoers.d/033_${SADM_USER}" ; 
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
        then cd /tmp
             printf "\nRemoving directory structure $SADMIN ..."
             sadm_stop 0
             if [ "$DRYRUN" -ne 1 ] 
                then rm -fr "$SADMIN" 
             fi
    fi

    if [ "$SADM_HOST_TYPE" = "S" ] 
        then if [ "$DRYRUN" -eq 1 ]
                then printf "\n${BOLD}${CYAN}Uninstall of SADMIN server would have completed.${NORMAL}"
                else printf "\n${BOLD}${CYAN}Uninstall of SADMIN server is now completed.${NORMAL}"
             fi
        else printf "\n${BOLD}${CYAN}Uninstall of SADMIN client completed.${NORMAL}"
    fi
    printf "\n\n"                                                         # Blank line separation
    return 0                                                            # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hvy" opt ; do                                      # Loop to process Switch
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
            y) DRYRUN=0                                                 # DeActivate DryRun
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
    sadm_start                                                          # Won't come back if error
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong   
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Only in DryMode Else Error
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    