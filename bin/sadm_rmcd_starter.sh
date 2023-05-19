#! /usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rmcmd_starter.sh
#   Synopsis :  Execute a defined script on a remote system.
#   Version  :  1.0
#   Date     :  8 Dec 2020  
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_rmcmd_starter.sh 1.0 2020/12/08
#   
# sadm_rmcd_starter.sh [-d Level] [-h] [-v] [-s scriptName] [-n systemName]
#   -d   (Debug Level [0-9])
#   -h   (Display this help message)
#   -v   (Show Script Version Info)
#   -n   (Remote System Name where script reside)
#   -l   (Lock System (no monitoring) while script is running)
#   -s   (Script Name to execute)
#   -u   (User Name use to ssh on remote system)
#   -p   (Prefix script Name with path of /sadmin on remote system)
#
#
# Example of line to put in crontab (/etc/crond/sadm_vm) to start remote backup of a VM
# SADMIN=/sadmin
# BSCRIPT=/opt/sa/bin/virtualbox/sadm_vm_backup.sh
#
# 0 14 6,21 * * root $SADMIN/bin/sadm_rmcd_starter.sh -lu 'jacques' -n borg -s "$BSCRIPT -yn rhel8"
#
# --------------------------------------------------------------------------------------------------
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# Change Log
# 2020_12_12 cmdline v1.0 Initial version.
# 2021_02_13 cmdline v1.1 First production release, added some command line option.
# 2021_02_18 cmdline v1.2 Lock FileName now created with remote node name.
# 2021_02_19 cmdline v1.3 Add -l to Lock system name.
# 2021_08_17 cmdline v1.4 Change to use Library System Lock 
# 2022_05_23 cmdline v1.5 Do not to run remote script on system that are locked.
# 2022_08_17 cmdline v1.6 Include new SADMIN section 1.52
# 2022_09_20 cmdline v1.7 SSH to client is now using the port defined in each system.
# 2022_12_13 cmdline v1.8 Intermittent crash cause by a typo error.
#@2023_05_06 cmdline v1.9 Reduce ping wait time to speed up processing.
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.52
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] # SADMIN defined ? SADMIN Libr. exist   
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi # Last chance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.9'                                      # Current Script Version
export SADM_PDESC="Execute a defined script on a remote system." 
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
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
# ---------------------------------------------------------------------------------------




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT        # Nb. of update failed
STAR_LINE=`printf %80s |tr " " "*"`         ; export STAR_LINE          # 80 equals sign line

# Script Variable needed to run the script on the remote client.
export SCRIPT=""                                                        # Script to execute 
export SERVER=""                                                        # Server Where script reside
export LOCK="N"                                                         # Lock=No Monitor during run
export LOCKNODE=""                                                      # Server name to Lock
export SUSER=""                                                         # UserName Used to SSH Remote





# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${BOLD}${SADM_PN} [-d Level] [-h] [-v] [-l systemName ] [-u username] [-s scriptName] [-n systemName]${NORMAL}" 
    printf "\n\t${BOLD}-d${NORMAL}   (Debug Level [0-9])"
    printf "\n\t${BOLD}-h${NORMAL}   (Display this help message)"
    printf "\n\t${BOLD}-v${NORMAL}   (Show Script Version Info)"
    printf "\n\t${BOLD}-n${NORMAL}   (System Name where script reside)"
    printf "\n\t${BOLD}-l${NORMAL}   (Lock System (no monitoring) while script is running)"
    printf "\n\t${BOLD}-s${NORMAL}   (Script Name to execute)"
    printf "\n\t${BOLD}-u${NORMAL}   (User Name use to ssh on remote system)"
    printf "\n\t${BOLD}-p${NORMAL}   (Prefix script Name with path of $SADMIN on remote system)"
    printf "\n\n" 
}


# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
rmcd_start()
{

    # Get info about server in Database
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_update_auto, "
    SQL2="srv_update_reboot, srv_sporadic, srv_active, srv_sadmin_dir,srv_ssh_port from server "
    SQL3="where srv_name = '$SERVER' ;"                                 # Select server to rmcmd
    SQL="${SQL1}${SQL2}${SQL3}"                                         # Build Final SQL Statement 

    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL'"        # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
   
    # Result file not readable or is empty = Server Name not found in Database
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write_err "${SADM_ERROR} The system '$SERVER' wasn't found is Database."
             return 1                                                   # Return Error to Caller
    fi 
    
    # Process the server
    while read wline
        do
        server_name=`         echo $wline|awk -F\; '{ print $1 }'`
        server_os=`           echo $wline|awk -F\; '{ print $2 }'`
        server_domain=`       echo $wline|awk -F\; '{ print $3 }'`
        server_update_auto=`  echo $wline|awk -F\; '{ print $4 }'`
        server_update_reboot=`echo $wline|awk -F\; '{ print $5 }'`
        server_sporadic=`     echo $wline|awk -F\; '{ print $6 }'`
        server_sadmin_dir=`   echo $wline|awk -F\; '{ print $8 }'`
        server_ssh_port=`     echo $wline|awk -F\; '{ print $9 }'`
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQN Server Name

        # Ping to server - Test if it is alive
        ping -c2 -W2 $fqdn_server >> /dev/null 2>&1
        if [ $? -ne 0 ]
            then sadm_write_err "${SADM_ERROR} Can't ping $fqdn_server."
                 return 1                                               # Return to Caller
            else sadm_writelog "${SADM_OK} Ping host $fqdn_server."
        fi

        # If prefix requested (-p), Add the $SADMIN PATH before the script name.
        if [ "$PREFIX" = "Y" ]
           then SCRIPT="${server_sadmin_dir}/${SCRIPT}"                 # Add $SADMIN System to Name
                sadm_write "${SADM_OK} SADMIN Path added to script name, now changed to $SCRIPT'.\n" 
        fi

        
        # Check if the node is currently lock (Abort execution)
        sadm_check_system_lock "${LOCKNODE}"                            # Check if node is lock
        if [ $? -eq 1 ]                                                 # If node is lock
           then sadm_write_err "The system '${SNAME}' is currently lock."
                sadm_write_err "System normal monitoring will resume in ${sec_left} seconds."
                sadm_write_err "Maximum lock time allowed is ${SADM_LOCK_TIMEOUT} seconds."
                ERROR_COUNT=$(($ERROR_COUNT+1))                             # Increment Error Counter
                return 1                                                    # Return Error to caller
        fi 

        # If requested (-l), created a server lock file, to prevent generation monitoring error.
        if [ "$LOCK" = "Y" ]                                            # cmdline option lock system
           then sadm_lock_system "${LOCKNODE}"                          # Create System Lock File
                if [ $? -ne 0 ]                                         # Unable to Lock Node
                   then ERROR_COUNT=$(($ERROR_COUNT+1))                 # Increment Error Counter
                        sadm_writelog "${SADM_ERROR} Aborting process for '${SERVER}'."
                        return 1                                        # Return Error to caller 
#                   else sadm_write_log "Show lock file" 
#                        ls -l $SADMIN/*.lock
                fi
        fi
        
        # Time to run the requested ${SCRIPT}.
        sadm_write_log " "
        sadm_write_log "${BOLD}Starting '$SCRIPT' on '${server_name}'.${NORMAL}"
        sadm_write_log "$SADM_SSH -p $server_ssh_port ${SUSER}\@${fqdn_server} '${SCRIPT}'"
        $SADM_SSH -qnp $server_ssh_port ${SUSER}\@${fqdn_server} ${SCRIPT} >>$SADM_LOG 2>&1 
        RC=$? 
        if [ $RC -ne 0 ]                                                # Update went Successfully ?
           then sadm_write_err "[ ERROR ] Script completed with error no.$RC on '${server_name}'."
                ERROR_COUNT=$(($ERROR_COUNT+1))                         # Increment Error Counter
           else sadm_write_log "[ OK ] Script completed successfully on '${server_name}'."
        fi

        # If the lock file exist, then time to remove it.
        if [ "$LOCK" = "Y" ] ;then sadm_unlock_system "$LOCKNODE" ;fi # Remove the lock file
        done < $SADM_TMP_FILE1

    if [ "$ERROR_COUNT" -ne 0 ]
       then sadm_writelog "Total Error count is ${ERROR_COUNT}."
    fi 

    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d[0-9]) Set Debug Level 
# (-s)=Script name to execute, (-n)=system name where script reside (-u)=UserName used to ssh
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts ":u:l:n:s:hd:vp" opt; do 
        case "${opt}" in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               printf "\nDEBUG\n"
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
            n) SERVER=$OPTARG                                           # System to backup
               ;;
            s) SCRIPT=$OPTARG                                           # Script to execute on system
               ;;
            u) SUSER=$OPTARG                                            # User use to SSH to system
               ;;
            l) LOCKNODE=$OPTARG                                         # Save System Name to Lock
               LOCK="Y"                                                 # No Monitor while running
               ;;                                                       # the script.
            p) PREFIX="Y"                                               # Prefix the ScriptName with 
               ;;                                                       # $SADMIN Path on RemoteSys.
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $SADM_DEBUG -gt 4 ] 
        then sadm_writelog "Script:${SCRIPT} Server:${SERVER} User:${SUSER}"
             sadm_writelog "Current User id: `id`"
    fi
    return      
}



#===================================================================================================
# MAIN CODE START HERE
#===================================================================================================
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    rmcd_start                                                          # Go Run Remote Script
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
