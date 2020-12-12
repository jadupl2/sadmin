#! /usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rmcmd_starter.sh
#   Synopsis :  Remote Script Starter 
#   Version  :  1.0
#   Date     :  8 Dec 2020  
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_rmcmd_starter.sh 1.0 2020/12/08
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
# Change Log
# 2020_12_12 New: v1.0 Initial version.
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x




#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================

# MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # If SADMIN EnvVar not right
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null          # SADMIN in /etc/environment
         if [ $? -eq 0 ]                                                # Yes it is 
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' Environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                 # Current Script filename(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`       # Current Script filename(without extension)
export SADM_TPID="$$"                                   # Current Script Process ID.
export SADM_HOSTNAME=`hostname -s`                      # Current Host name without Domain Name
export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Std Libr.).
export SADM_VER='1.0'                                   # Current Script Version
export SADM_EXIT_CODE=0                                 # Current Script Default Exit Return Code
export SADM_LOG_TYPE="B"                                # writelog go to [S]creen [L]ogFile [B]oth
export SADM_LOG_APPEND="Y"                              # [Y]=Append Existing Log [N]=Create New One
export SADM_LOG_HEADER="Y"                              # [Y]=Include Log Header  [N]=No log Header
export SADM_LOG_FOOTER="Y"                              # [Y]=Include Log Footer  [N]=No log Footer
export SADM_MULTIPLE_EXEC="Y"                           # Allow running multiple copy at same time ?
export SADM_USE_RCH="Y"                                 # Gen. History Entry in ResultCodeHistory 
export SADM_DEBUG=0                                     # Debug Level - 0=NoDebug Higher=+Verbose
export SADM_TMP_FILE1=""                                # Tmp File1 you can use, Libr. will set name
export SADM_TMP_FILE2=""                                # Tmp File2 you can use, Libr. will set name
export SADM_TMP_FILE3=""                                # Tmp File3 you can use, Libr. will set name

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                          # LOAD SADMIN Standard Shell Libr. Functions
export SADM_OS_NAME=$(sadm_get_osname)                  # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
export SADM_OS_VERSION=$(sadm_get_osversion)            # O/S Full Version Number  (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)      # O/S Major Version Number (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/CFG/SADMIN.CFG FILE).
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                               # 0=None 1=AlertOnError 2=AlertOnOK 3=Always
#export SADM_ALERT_GROUP="default"                      # Alert Group to advise (alert_group.cfg)
#export SADM_MAIL_ADDR="your_email@domain.com"          # Email to send log (Override sadmin.cfg)
export SADM_MAX_LOGLINE=5000                           # At the end Trim log to 500 Lines(0=NoTrim)
export SADM_MAX_RCLINE=60                              # At the end Trim rch to 35 Lines (0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT        # Nb. of update failed
WARNING_COUNT=0                             ; export WARNING_COUNT      # Nb. of warning failed
STAR_LINE=`printf %80s |tr " " "*"`         ; export STAR_LINE          # 80 equals sign line

# Script That is to be run on remote client.
export SCRIPT=""                                                        # Script to execute 
export SERVER=""                                                        # Server Where script reside
export LOCK="N"                                                         # Lock=No Monitor during run



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${BOLD}${SADM_PN} [-d Level] [-h] [-v] [-s scriptName] [-n systemName]${NORMAL}" 
    printf "\n\t${BOLD}-d${NORMAL}   (Debug Level [0-9])"
    printf "\n\t${BOLD}-h${NORMAL}   (Display this help message)"
    printf "\n\t${BOLD}-v${NORMAL}   (Show Script Version Info)"
    printf "\n\t${BOLD}-s${NORMAL}   (Script Name to execute)"
    printf "\n\t${BOLD}-n${NORMAL}   (System Name where script reside)"
    printf "\n\t${BOLD}-l${NORMAL}   (Lock System (no monitoring) while script is running)"
    printf "\n\t${BOLD}-p${NORMAL}   (Prefix script Name with path of $SADMIN on remote system)"
    printf "\n\n" 
}






# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
rcmd_osupdate()
{

    # Get info about server in Database
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_update_auto, "
    SQL2="srv_update_reboot, srv_sporadic, srv_active, srv_sadmin_dir from server "
    SQL3="where srv_active = True and srv_name = '$SERVER' ;"           # Select server to rmcmd
    SQL="${SQL1}${SQL2}${SQL3}"                                         # Build Final SQL Statement 
    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL'"        # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
   
    # Result file not readable or is empty = Server Name not found in Database
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "${SADM_ERROR} The system '$SERVER' wasn't found is Database.\n"
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
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQN Server Name

        # Ping to server - Test if it is alive
        ping -c2 $fqdn_server >> /dev/null 2>&1
        if [ $? -ne 0 ]
            then sadm_write "${SADM_ERROR} Can't ping $fqdn_server.\n"
                 return 1                                               # Return to Caller
            else sadm_write "${SADM_OK} Ping host $fqdn_server.\n"
        fi

        # If prefix requested (-p), Add the $SADMIN PATH before the script name.
        if [ "$PREFIX" = "Y" ]
           then SCRIPT="${server_sadmin_dir}/${SCRIPT}"                 # Add $SADMIN System to Name
                sadm_write "${SADM_OK} SADMIN Path added to script name, now changed to $SCRIPT'.\n" 
        fi

        # Check Existence of script on remote server and that it is executable.
        pgm="${SCRIPT}"
        response=$($SADM_SSH_CMD $fqdn_server "if [ -x $pgm ] ;then echo 'ok' ;else echo 'error' ;fi")
        if [ "$response" != "ok" ]
            then sadm_write "${SADM_ERROR} '$pgm' don't exist or not executable on $fqdn_server.\n"
                 sadm_write "No O/S Update will be perform.\n"
                 return 1
            else sadm_write "${SADM_OK} '$pgm' exist & executable on $fqdn_server.\n"
        fi 

        # If requested (-l), created a server lock file, to prevent generation monitoring error.
        if [ "$LOCK" = "Y" ]
           then LOCK_FILE="${SADM_TMP_DIR}/${SERVER}.lock"              # Prevent Monitor lock file    
                sadm_write "Creating system '${SERVER}' lock file (${LOCK_FILE}).\n"
                echo "$SADM_INST - $(date)" > ${LOCK_FILE}              # Create Lock File
                if [ $? -eq 0 ]                                         # If Touch went OK
                   then sadm_write "${SADM_OK} Suspend monitoring while script is running.\n"  
                   else sadm_write "${SADM_ERROR} Creating '$SERVER' lock file '${LOCK_FILE}'\n" 
                fi
        fi
        
        sadm_writelog " "
        sadm_writelog "${BOLD}Starting $SCRIPT on '${server_name}'.${NORMAL}"
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If not on SADMIN Server
            then sadm_write "$SADM_SSH_CMD $fqdn_server '${SCRIPT}'\n\n"
                 $SADM_SSH_CMD $fqdn_server ${server_sadmin_dir}/bin/$USCRIPT $WREBOOT
                 RC=$? 
            else sadm_write "Starting execution of ${server_sadmin_dir}/bin/$USCRIPT \n"
                 ${server_sadmin_dir}/bin/$USCRIPT                       # Run Locally when on SADMIN
                 RC=$?
        fi                             
        if [ $RC -ne 0 ]                                                # Update went Successfully ?
           then sadm_writelog "${SADM_ERROR} O/S Update completed with error on '${server_name}'."
                ERROR_COUNT=$(($ERROR_COUNT+1))                         # Increment Error Counter
                update_server_db "${server_name}" "F"                   # Update Status False in DB
           else sadm_writelog "${SADM_OK} O/S Update completed successfully on '${server_name}'."
                update_server_db "${server_name}" "S"                   # Update Status Success in DB
        fi
        if [ -f "$LOCK_FILE" ] ;then rm -f $LOCK_FILE >/dev/null 2>&1 ;fi # Remove host Lock File    
        done < $SADM_TMP_FILE1

    if [ "$ERROR_COUNT" -ne 0 ] || [ "$WARNING_COUNT" -ne 0 ] 
       then sadm_writelog "Total Error is $ERROR_COUNT and Warning at ${WARNING_COUNT}"
    fi 
    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d[0-9]) Set Debug Level 
# (-s)=Script name to execute, (-n)=system name where script reside
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hvs:n:lp" opt ; do                                 # Loop to process Switch
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
            s) SCRIPT=$OPTARG                                           # Script to execute
               ;;
            n) SERVER=$OPTARG                                           # Server where script reside 
               ;;
            l) LOCK="Y"                                                 # No Monitor while running
               ;;                                                       # the script.
            p) PREFIX="Y"                                               # Prefix the ScriptName with 
               ;;                                                       # $SADMIN Path on RemoteSys.
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



#===================================================================================================
# MAIN CODE START HERE
#===================================================================================================
#
    cmd_options "$@"                                                    # Check command-line Options

    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user, process aborted.\n"
             sadm_write "Try sudo %s" "${0##*/}\n"                      # Suggest using sudo
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_write "Script can only be run on (${SADM_SERVER}), process aborted.\n"
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Get the server Name to Update, Else exit with Error.
    if [ $# -ne 1 ]
        then sadm_write "\n${SADM_ERROR} Please specify the system name.\n"
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
        else ONE_SERVER=$1                                              # Save Server Name to Update
    fi 

    rcmd_osupdate                                                       # Go Update Server
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
