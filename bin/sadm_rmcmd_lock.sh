#! /usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rmcmd_lock.sh
#   Synopsis :  Execute a script on a remote system and locking that system.
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
#@2025_01_09 cmdline v2.3 Execute a script on remote system, while creating a specified lock file.
#@2025_01_24 cmdline v2.4 Bug fixes concerning lock & remote execution while updating logs
#@2025_05_19 cmdline v2.5 Correct rpt file problem.
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
for i in "$@" ; do : ; done                                # Get last Parameter (-a)
export SYSTEM_NAME="$i"                                    # Save last parameter on cmdline
export SADM_EXT=$(echo "$SADM_PN" | cut -d'.' -f2)         # Save Script extension (sh, py, php,.)
export SADM_INST="${SADM_INST}_${SYSTEM_NAME}"             # Insert remote hostname in rch & log
export SADM_HOSTNAME="$SYSTEM_NAME"                        # SystemName that we are going to update
export SADM_PN="${SADM_INST}.${SADM_EXT}"                  # Script name(with extension)
# ----------


# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.5'                                      # Current Script Version
export SADM_PDESC="Execute a script on a remote system and locking that system." 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=5                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

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
export REM_SCRIPT=""                                    # Remote script name to execute 
export REM_SCRIPT_ARGS=""                               # Remote script argument(s)
export REM_SERVER=""                                    # Remote system where script exist
export REM_LOCK="N"                                     # cmdline -l used, Need to lock a System Y/N
export REM_LOCK_SYSTEM=""                               # Remote system name to lock
export REM_USER=""                                      # Remote User that will run script
export LOCK_FILENAME=""                                 # when -l and -n is use, the -l name is use.
export RPT_LOCAL=""                                     # SADMIN Server Local RPT
export RPT_GLOBAL=""                                    # SADMIN Server Global RPT


# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${BOLD}${SADM_PN} v$SADM_VER"
    printf "\n$SADM_PDESC \n"
    printf "\n$SADM_PN}.sh  [-d level] [-h] [-v] [-l system to lock name] [-s scriptname] [-a script arguments] "
    printf "[-u username] [-n remote_hostname]${NORMAL}" 
    printf "\n\t${BOLD}-d${NORMAL}   (Debug level [0-9])"
    printf "\n\t${BOLD}-h${NORMAL}   (Display this help message)."
    printf "\n\t${BOLD}-v${NORMAL}   (Show script version info)."
    printf "\n\t${BOLD}-l${NORMAL}   (System name to lock, if different than remote system (-n)."
    #printf "\n\t${BOLD}-p${NORMAL}   (Prefix script name with path of $SADMIN on remote system)."
    printf "\n\t${BOLD}-s${NORMAL}   (Script name to execute on remote system."
    printf "\n\t${BOLD}-a${NORMAL}   (Script argument(s) use with -s)"
    printf "\n\t${BOLD}-u${NORMAL}   (User name use by ssh to log on remote system)."
    printf "\n\t${BOLD}-n${NORMAL}   (Remote system name where script reside)."
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
# update_rpt_file()
#
# Update the host SysMon report (rpt) 
#
# Input Parameters :
#   1) State of the report line (1 Char - Lower or Upper case).
#       'I' = Information line
#       'W' = Warning line
#       'E' = Error line
#       'S' = Script 
#   2) System Host Name
#   3) Operating System (LINUX,DARWIN or AIX)
#   4) SubModule (One of these ; NETWORK,SCRIPT,HTTP,HTTPS,DAEMON,SERVICE)
#   5) Message concerning the event (String)
#   6) Warning Alert Group Name (String)
#   7) Error Alert Group Name (String)
# 
# The rpt file is created ans the formatted rpt line is output to the filee.
# Fields in this file are ';' delimited.
#
# Example of rpt line: 
#  Warning;sherlock;2025.01.19;11:43;linux;FILESYSTEM;Filesystem /data at 92% >= 90%;default;default
# --------------------------------------------------------------------------------------------------
update_rpt_file()
{
    if [ $# -ne 7 ]
        then sadm_write_log "Invalid number of argument received by function ${FUNCNAME}."
             sadm_write_log "Should be 7, but we received $# : $* "     # Show what received
             return 1                                                   # Return Error to caller
    fi
    
    RPT_STAT="$1"                                                       # Report Status (E,W,I,S)       
    RPT_HOST="$2"                                                       # Hostname of the system
    RPT_OSNAME=$(sadm_capitalize "$3")                                  # O/S LINUX,AIX,DARWIN
    RPT_MODULE="$4"                           # SubModule (NETWORK,SCRIPT,HTTP,HTTPS,DAEMON,SERVICE)             
    RPT_MSG="$5"                                                        # Mess. concerning the event   
    RPT_WGRP="$6"                                                       # Warning Alert Group Name    
    RPT_EGRP="$7"                                                       # Error Alert Group Name

    if [ "$SADM_DEBUG" -gt 2 ] 
        then sadm_write_log "[ DEBUG ] In function ${FUNCNAME}."
             sadm_write_log "[ DEBUG ] RPT_STAT=$RPT_STAT"
             sadm_write_log "[ DEBUG ] RPT_HOST=$RPT_HOST"
             sadm_write_log "[ DEBUG ] RPT_OSNAME=$RPT_OSNAME"
             sadm_write_log "[ DEBUG ] RPT_MODULE=$RPT_MODULE"
             sadm_write_log "[ DEBUG ] RPT_MSG=$RPT_MSG"
             sadm_write_log "[ DEBUG ] RPT_WGRP=$RPT_WGRP"
             sadm_write_log "[ DEBUG ] RPT_EGRP=$RPT_EGRP"
    fi 

    # Set Event Type 
    case "$RPT_STAT" in
        E|e)    RPT_STAT="Error"
                ;;  
        W|w)    RPT_STAT="Warning" 
                ;;  
        I|i)    RPT_STAT="Info"
                ;;  
        S|s)    RPT_STAT="Script" 
                ;;  
        *)      RPT_STAT="Invalid status type '$1' "
                sadm_write_log "[ ERROR ] Invalid status type '$1' received by function ${FUNCNAME}."
                return 1                                                   # Return Error to caller 
                ;;
    esac

    RPT_DATE=$(date "+%Y.%m.%d")                                        # Report Date in YYYY.MM.DD                              
    RPT_TIME=$(date "+%H:%M")                                           # Report Time in HH:MM
    RPTLINE="${RPT_STAT};${RPT_HOST};${RPT_DATE};${RPT_TIME};${RPT_OSNAME}"  # Build Report Line
    RPTLINE="${RPTLINE};${RPT_MODULE};${RPT_MSG};${RPT_WGRP};${RPT_EGRP};"   # Build Report Line
    if [ "$SADM_DEBUG" -gt 2 ] 
        then sadm_write_log "[ DEBUG ] In function $FUNCNAME, RPTLINE=$RPTLINE"
    fi

    # Update the Local & Global RTP files.
    RPT_LOCAL="${SADM_RPT_DIR}/${RPT_HOST}_rmcmd_lock.rpt"              # SADMIN Server Local RPT
    RPT_GLOBAL="${SADM_WWW_DAT_DIR}/${RPT_HOST}/rpt/${RPT_HOST}_rmcmd_lock.rpt" 
    echo "$RPTLINE" >> "$RPT_LOCAL"                                     # $SADMIN/dat/rpt rpt
    echo "$RPTLINE" >> "$RPT_GLOBAL"                                    # $SADMIN/www/dat/hostname/rpt

    if [ "$SADM_DEBUG" -gt 2 ] 
        then sadm_write_log "[ DEBUG ] In function $FUNCNAME, line added to $RPT_LOCAL ."
             sadm_write_log "[ DEBUG ] $RPTLINE" 
    fi 
    return 0 
}



# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
rmcmd_start()
{
    # Check if the remote system is currently lock (Abort execution)        
    sadm_lock_status "$REM_SERVER"                                  # Check if node is lock
    if [ $? -ne 0 ]                                                 # If node is lock
       then sadm_write_err "[ ERROR ] System '$REM_SERVER' is currently lock."
            sadm_write_err "$(sadm_show_lock "$REM_SERVER")"        # Show lock file content
            return 1                                                # Return Error to caller
    fi 


    # Construct the SQL to get info about remote system in Database
    SQL1="SELECT srv_name, srv_domain, srv_sporadic, "
    SQL2="srv_active, srv_sadmin_dir, srv_ssh_port, srv_vm_host, srv_ostype "
    SQL3="from server where srv_name = '$REM_SERVER' and srv_active = True ;"       
    SQL="${SQL1}${SQL2}${SQL3}"                                         # Build Final SQL Statement 

    # Execute the SQL and write the output to $SADM_TMP_FILE1
    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL'"        # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "${CMDLINE}" ; fi    # Debug = Write command Line
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
   
    # If resulting file ($SADM_TMP_FILE1) is not readable or is empty.
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write_err "[ ERROR ] System '$REM_SERVER' wasn't found in Database or not active."
             return 1                                                   # Return Error to Caller
    fi 
    

    # Process the server
    while read wline
        do
        server_name=$(          echo $wline|awk -F\; '{ print $1 }')    # Extract system host name
        server_domain=$(        echo $wline|awk -F\; '{ print $2 }')    # Extract system domain
        server_sporadic=$(      echo $wline|awk -F\; '{ print $3 }')
        server_sadmin_dir=$(    echo $wline|awk -F\; '{ print $5 }')    # Extract $SADMIN on remote
        server_ssh_port=$(      echo $wline|awk -F\; '{ print $6 }')    # Extract SSH port of remote
        server_vm_host=$(       echo $wline|awk -F\; '{ print $7 }')    # Extract SSH port of remote
        server_ostype=$(        echo $wline|awk -F\; '{ print $8 }')    # LINUX,AIX,DARWIN,SUNOS
        fqdn_server=$(echo $server_name.$server_domain)                 # Create FQN System Name

        # Determine the server name used to create the lock file.
        #  - If cmdline '-l' system name specified, use that name to create the lock file.
        #  - If cmdline '-l' IS NOT USE, system name specified by the (-n) is use in lock file name.
        if [ "$REM_LOCK" = "Y" ]                                        # When cmdline '-l' used
           then LOCK_FILENAME="$REM_LOCK_SYSTEM"                        # Used '-l' system to lock
           else LOCK_FILENAME="$REM_SERVER"                             # Used '-n' system to lock
        fi    


        # Ping the remote system - Test if it is alive
        ping -c2 -W2 $REM_SERVER >> /dev/null 2>&1                      # Ping 2 times,timeout 2 Sec
        if [ $? -ne 0 ]
            then sadm_write_err "[ ERROR ] System '$REM_SERVER' don't respond to ping."
                 return 1                                              
            else sadm_write_log "[ OK ] Remote system '$REM_SERVER' is alive."
        fi


        # Lock the remote system while the script is executed (-l) 
        sadm_lock_system "$LOCK_FILENAME" "$REM_SCRIPT $REM_SCRIPT_ARGS"
        if [ $? -ne 0 ]                                                 # Unable to Lock Node
           then sadm_write_log "[ ERROR ] Couldn't lock system '$LOCK_FILENAME'."
                return 1
        fi
        
        # Get reason of the lock (in the lock file) and update sherlock_rmcmd_lock.rpt 
        RPT_MSG="$(sadm_show_lock "$LOCK_FILENAME")"                    # Get the lock file content  
        RPT_OS="$server_ostype"                                         # Get the O/S type of remote

        # Update SADMIN server Global RPT File.
        update_rpt_file "I" "$LOCK_FILENAME" "$RPT_OS" "SCRIPT" "$RPT_MSG" "$SADM_ALERT_GROUP" "$SADM_ALERT_GROUP"


        # Time to run the requested $SCRIPT on remote system
        sadm_write_log "[ OK ] Starting '$REM_SCRIPT' on '$REM_SERVER'."
        CMD="$SADM_SSH -qnp $server_ssh_port -o BatchMode=yes ${REM_USER}\@$REM_SERVER "
        CMD="$CMD $REM_SCRIPT $REM_SCRIPT_ARGS"
        if [ "$SADM_DEBUG" -gt 0 ] 
            then sadm_write_log "$CMD" ; sadm_write_log " " ; sadm_write_log " "
        fi 
        eval "$CMD"
        RC=$? 
        if [ $RC -ne 0 ]
           then sadm_write_err "[ ERROR ] Script completed with error no.$RC on '$REM_SERVER'."
                sadm_unlock_system "$LOCK_FILENAME"                  # Remove the lock file
                return 1 
           else sadm_write_log "[ OK ] Script '$REM_SCRIPT' completed successfully on '$REM_SERVER'."
        fi

        # Remove the system lock file
        sadm_unlock_system "$LOCK_FILENAME"                          # Remove the lock file
        RPT_LOCAL="${SADM_RPT_DIR}/${RPT_HOST}_rmcmd_lock.rpt"     # SADMIN Server Local RPT
        RPT_GLOBAL="${SADM_WWW_DAT_DIR}/${RPT_HOST}/rpt/${RPT_HOST}_rmcmd_lock.rpt" 
        done < $SADM_TMP_FILE1

    return 0
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default : (-h) Show Help Usage, (-v) Show Script Version,  (-d[0-9]) Set Debug Level 
#              (-s) Name of script to execute,       (-p) Script Arguments
#              (-n) System name where script reside, (-u) UserName used to ssh,             
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "hvl:d:u:n:s:a:" opt ; do 
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
            s) REM_SCRIPT=$OPTARG                                       # Remote REM_SCRIPT to execute
               ;;
            a) REM_SCRIPT_ARGS=$OPTARG                                  # Remote REM_SCRIPT arguments
               ;;
            n) REM_SERVER=$OPTARG                                       # Remote system name
               ;;
            u) REM_USER=$OPTARG                                         # User executing the REM_SCRIPT
               ;;
            l) REM_LOCK="Y"                                             # Create lockfile for remote
               REM_LOCK_SYSTEM=$OPTARG                                  # Name of system to lock
               ;;
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $SADM_DEBUG -gt 4 ] 
        then printf "\nREM_SERVER:$REM_SERVER     REM_USER:$REM_USER  "
             printf "\nREM_SCRIPT:$REM_SCRIPT     REM_SCRIPT_ARGS:$REM_SCRIPT_ARGS  " 
             printf "\nREM_LOCK  :$REM_LOCK       REM_LOCK_SYSTEM=$REM_LOCK_SYSTEM\n"
    fi
    return      
}



#===================================================================================================
# MAIN CODE START HERE
#===================================================================================================
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    rmcmd_start                                                         # Go Run Remote REM_SCRIPT
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
