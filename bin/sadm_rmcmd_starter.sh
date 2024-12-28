#! /usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rmcmd_starter.sh
#   Synopsis :  Execute a script on a remote system.
#   Version  :  1.0
#   Date     :  8 Dec 2020  
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_rmcmd_starter.sh 1.0 2020/12/08
#   
# sadm_rmcmd_starter.sh [-d Level] [-h] [-v] [-s scriptName] [-n systemName]
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
# SADMIN=/opt/sadmin
# BSCRIPT=$SADMIN/bin/sadm_vm_backup.sh
#
# 0 14 6,21 * * root $SADMIN/bin/sadm_rmcmd_starter.sh -lu 'jacques' -n borg -s "$BSCRIPT -yn rhel8"
#
# --------------------------------------------------------------------------------------------------
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
# 2023_05_06 cmdline v1.9 Reduce ping wait time to speed up processing.
# 2023_11_05 cmdline v2.0 Add option to ssh command '-o ConnectTimeout=10 -o BatchMode=yes'.
#@2024_04_02 cmdline v2.1 Same of remote system is now added, so we can see where script is run .
#@2024_06_13 cmdline v2.2 Include name of remote host in the log and rch file name.
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
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


# ----------
# SPECIAL DEROGATION TO INSERT THE HOSTNAME IN THE FILE NAME OF THE LOG AND THE RCH FILE.
for i in "$@" ; do : ; done                                # Get last Parameter (portable version)
export SYSTEM_NAME="$i"                                    # Save last parameter on cmdline
export SADM_EXT=$(echo "$SADM_PN" | cut -d'.' -f2)         # Save Script extension (sh, py, php,.)
export SADM_INST="${SADM_INST}_${SYSTEM_NAME}"             # Insert VMName to export in rch & log
export SADM_HOSTNAME="$SYSTEM_NAME"                        # SystemName that we are going to update
export SADM_PN="${SADM_INST}.${SADM_EXT}"                  # Script name(with extension)
# ----------


# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.2'                                      # Current Script Version
export SADM_PDESC="Execute an existing script on a remote system." 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
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
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------




# --------------------------------------------------------------------------------------------------
#                               Script environment variables
# --------------------------------------------------------------------------------------------------
#
# Script variables needed to run the script on the remote client.
export SCRIPT=""                                                        # Script to execute 
export SERVER=""                                                        # System where execute script
export LOCK="N"                                                         # Lock=No Monitor during run
export SUSER=""                                                         # UserName used to run script
export ERROR_COUNT=0                                                    # Nb. of update failed





# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${BOLD}${SADM_PN} [-d level] [-h] [-v] [-l] [-u username] [-s scriptName] [-n remote_hostname]${NORMAL}" 
    printf "\n\t${BOLD}-d${NORMAL}   (Debug level [0-9])"
    printf "\n\t${BOLD}-h${NORMAL}   (Display this help message)."
    printf "\n\t${BOLD}-v${NORMAL}   (Show script version info)."
    printf "\n\t${BOLD}-n${NORMAL}   (Remote system name where script reside)."
    printf "\n\t${BOLD}-l${NORMAL}   (System name to lock while script is running)."
    printf "\n\t${BOLD}-s${NORMAL}   (Script name and parameter(s) (if needed) to execute)."
    printf "\n\t${BOLD}-u${NORMAL}   (User name use by ssh to log on remote system)."
    printf "\n\t${BOLD}-p${NORMAL}   (Prefix script name with path of $SADMIN on remote system)."
    printf "\n\n" 
}




# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
rmcmd_start()
{

    # Construct the SQL to get info about remote system in Database
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_update_auto, "
    SQL2="srv_update_reboot, srv_sporadic, srv_active, srv_sadmin_dir,srv_ssh_port from server "
    SQL3="where srv_name = '$SERVER' ;"                                 # Select server to rmcmd
    SQL="${SQL1}${SQL2}${SQL3}"                                         # Build Final SQL Statement 

    # Execute the SQL and write the output to $SADM_TMP_FILE1
    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL'"        # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "${CMDLINE}" ; fi    # Debug = Write command Line
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
   
    # If resulting file ($SADM_TMP_FILE1) is not readable or is empty.
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write_err "[ ERROR ] The remote system '$SERVER' wasn't found in Database."
             return 1                                                   # Return Error to Caller
    fi 
    
    # Process the server
    while read wline
        do

        # Extract field we may need
        server_name=$(          echo $wline|awk -F\; '{ print $1 }')
        server_os=$(            echo $wline|awk -F\; '{ print $2 }')
        server_domain=$(        echo $wline|awk -F\; '{ print $3 }')
        server_update_auto=$(   echo $wline|awk -F\; '{ print $4 }')
        server_update_reboot=$( echo $wline|awk -F\; '{ print $5 }')
        server_sporadic=$(      echo $wline|awk -F\; '{ print $6 }')
        server_sadmin_dir=$(    echo $wline|awk -F\; '{ print $8 }')
        server_ssh_port=$(      echo $wline|awk -F\; '{ print $9 }')
        fqdn_server=$(echo $server_name.$server_domain)                 # Create FQN System Name

        # Check if the remote system is currently lock (Abort execution)
        sadm_check_system_lock "$SERVER"                               # Check if node is lock
        if [ $? -eq 1 ]                                                 # If node is lock
           then sadm_write_err "[ ERROR ] The system '$SNAME' is currently lock."
                return 1                                                # Return Error to caller
        fi 

        # Ping the remote system - Test if it is alive
        ping -c2 -W2 $fqdn_server >> /dev/null 2>&1
        if [ $? -ne 0 ]
            then sadm_write_err "[ ERROR ] Can't ping '$fqdn_server'."
                 return 1                                              
            else sadm_write_log "[ OK ] Remote system '$fqdn_server' is alive."
        fi

        # If prefix requested (-p), add the $SADMIN PATH before the script name.
        if [ "$PREFIX" = "Y" ]                                          # Script Path Prefix added ?
           then SCRIPT="$server_sadmin_dir/bin/$SCRIPT"                 # Add $SADMIN System to Name
                sadm_write_log "[ OK ] The SADMIN path added to script name, now changed to '$SCRIPT'." 
        fi

        # Lock the remote system while the script is executed (-l) 
        if [ "$LOCK" = "Y" ]                                            # cmdline option lock system
           then sadm_lock_system "$SERVER"                              # Create System Lock File
                if [ $? -ne 0 ]                                         # Unable to Lock Node
                   then sadm_write_log "[ ERROR ] Aborting, could not lock to system '$LOCKNODE'."
                        return 1                                        # Return Error to caller 
                fi
        fi
        
        # Time to run the requested $SCRIPT on remote system
        sadm_write_log " "
        sadm_write_log "Starting '$SCRIPT' on '${server_name}'."
        #ssh -o ConnectTimeout=10 -o BatchMode=yes raspi5 ; echo $?

        sadm_write_log "$SADM_SSH -qnp $server_ssh_port -o ConnectTimeout=10 -o BatchMode=yes ${SUSER}\@${fqdn_server} '${SCRIPT}'"
        #$SADM_SSH -qnp $server_ssh_port -o ConnectTimeout=10 -o BatchMode=yes ${SUSER}\@${fqdn_server} ${SCRIPT} >>$SADM_LOG 2>&1 
        RC=$? 
        if [ $RC -ne 0 ]                                                # Update went Successfully ?
           then sadm_write_err "[ ERROR ] Script completed with error no.$RC on '$SERVER'."
           else sadm_write_log "[ OK ] Script completed successfully on '$SERVER'."
        fi

        # If the lock file exist, then time to remove it.
        if [ "$LOCK" = "Y" ] ;then sadm_unlock_system "$SERVER" ;fi     # Remove the lock file

        done < $SADM_TMP_FILE1

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
    while getopts "hvlpd:u:n:s:" opt ; do 
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
            n) SERVER=$OPTARG                                           # Remote system name
               printf "Server:${SERVER}\n"
               ;;
            s) SCRIPT=$OPTARG                                           # Remote script to execute
               printf "Script:${SCRIPT}\n"
               ;;
            u) SUSER=$OPTARG                                            # User executing the script
               printf "User:${SUSER}\n"
               ;;
            l) LOCK="Y"                                                 # Create lockfile for remote
               ;;
            p) PREFIX="Y"                                               # Prefix the ScriptName with 
               ;;                                                       # $SADMIN Path on RemoteSys.
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $SADM_DEBUG -gt 4 ] 
        then printf "Script:${SCRIPT} Server:${SERVER} User:${SUSER}\n"
             printf "Current User id: $(id)\n"
    fi
    return      
}



#===================================================================================================
# MAIN CODE START HERE
#===================================================================================================
    cmd_options "$@"                                                    # Check command-line Options



    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    rmcmd_start                                                          # Go Run Remote Script
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)