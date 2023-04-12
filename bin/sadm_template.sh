#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author        : Your Name 
#   Script Name   : XXXXXXXX.sh
#   Creation Date : 2022/MM/DD
#   Requires      : sh and SADMIN Shell Library
#   Description   : Template for starting a new shell script
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
#
# ---CHANGE LOG---
#---------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.55
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]     # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
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
export SADM_VER='4.3'                                      # Script version number
export SADM_PDESC="SADMIN template shell script"           # Script Optional Desc.(Not use if empty)
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
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
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# ---------------------------------------------------------------------------------------


  

#===================================================================================================
# Script global variables definitions
#===================================================================================================
#





# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}




#===================================================================================================
# Process all your active(s) server(s) found in Database 
# Modify SQL statement to your needs.
#===================================================================================================
process_servers()
{
    sadm_write "${BOLD}${YELLOW}Processing All Active(s) Server(s) ...${NORMAL}\n"

    # Put the rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir" 
    SQL="${SQL},srv_backup,srv_img_backup,srv_ssh_port "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "${CMDLINE}\n" ; fi  # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write_log "$SADM_WARNING No Active Server were found" # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    
    xcount=0; ERROR_COUNT=0;                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        ((xcount++))                                                    # Increase Server Counter                       # Increase Error Counter
        server_name=$(      echo $wline|awk -F\; '{print $1}')          # Extract Server Name
        server_os=$(        echo $wline|awk -F\; '{print $2}')          # O/S (linux/aix/darwin)
        server_domain=$(    echo $wline|awk -F\; '{print $3}')          # Extract Domain of Server
        server_monitor=$(   echo $wline|awk -F\; '{print $4}')          # Monitor  1=True 0=False
        server_sporadic=$(  echo $wline|awk -F\; '{print $5}')          # Sporadic 1=True 0=False
        server_rootdir=$(   echo $wline|awk -F\; '{print $7}')          # Client SADMIN Root Dir.
        server_backup=$(    echo $wline|awk -F\; '{print $8}')          # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $9}')          # ReaR Sched. 1=True 0=False
        server_ssh_port=$(  echo $wline|awk -F\; '{print $10}')         # SSH port no. to System
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        sadm_write_log "\n${SADM_TEN_DASH}"                             # Ten Dashes Line    
        sadm_write_log "Processing ($xcount) ${fqdn_server}."           # Server Count & FQDN Name 

        # Check if server name can be resolve - If not, we won't be able to SSH to it.
        host  $fqdn_server >/dev/null 2>&1                              # Try to resolve Hostname
        if (( $? ))                                                     # If hostname not resolvable
            then SMSG="$SADM_ERROR Can't process '$fqdn_server', hostname can't be resolved."
                 sadm_write_err "${SMSG}"                               # Advise user & Feed log
                 ((ERROR_COUNT++))                                      # Increase Error Counter                        # Increase Error Counter
                 sadm_write_err "Total error(s) : ${ERROR_COUNT}"       # Show Total Error Count
                 continue                                               # Continue with next Server
        fi

        # Try a SSH to system
        if [ $SADM_DEBUG -gt 0 ] 
            then sadm_write_log "$SADM_SSH -qnp $server_ssh_port $fqdn_server date" 
        fi 
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Server
            then $SADM_SSH -qnp $server_ssh_port $fqdn_server date > /dev/null 2>&1 # SSH to system
                 RC=$?                                                  # Save Return Code Number
            else RC=0                                                   # No SSH to SADMIN Server
        fi
        if [ $SADM_DEBUG -gt 0 ] ;then sadm_write_log "Return Code: ${RC}\n" ;fi

        # If SSH failed and it's a Sporadic Server, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
            then sadm_write_err "[ WARNING ] Can't SSH to sporadic system ${fqdn_server}."
                 sadm_write_err "Continuing with next system"           # Not Error if Sporadic Srv. 
                 continue                                               # Continue with next system
        fi

        # If SSH Failed & Monitoring is Off, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_monitor" = "0" ]                # SSH don't work/Monitor OFF
            then sadm_write_err "[ WARNING ] Can't SSH to $fqdn_server - Monitoring is OFF"
                 sadm_write_err "Continuing with next system\n"         # Not Error if don't Monitor
                 continue                                               # Continue with next system
        fi

        # If All SSH test failed, Issue Error Message and continue with next system
        if (( $RC ))                                                    # If SSH to Server Failed
            then SMSG="$SADM_ERROR Can't SSH to '${fqdn_server}'"       # Problem with SSH
                 sadm_write_err "${SMSG}"                               # Show/Log Error Msg
                 ((ERROR_COUNT++))                                      # Increase Error Counter                        # Increase Error Counter
                 sadm_write_err "Continuing with next system\n"         # Not Error if don't Monitor
                 sadm_write_err "Total error(s) : ${ERROR_COUNT}"       # Show Total Error Count
                 continue                                               # Continue with next system
        fi
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If not on SADMIN Server
            then sadm_write_log "[ OK ] SSH to ${fqdn_server} work"     # Good SSH Work on Client
            else sadm_write_log "[ OK ] No SSH using 'root' on the SADMIN Server ($SADM_SERVER)"
        fi

        # PROCESSING CAN BE PUT HERE
        # ........
        # ........

        done < $SADM_TMP_FILE1                                          # Read SQL Result file
    return $ERROR_COUNT                                                 # Return Err Count to caller
}



#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    sadm_write_log "Starting Main Process ..."                          # Starting processing Mess.

    # PROCESSING CAN BE PUT HERE
    # If Error occurred, set SADM_EXIT_CODE to 1 before returning to caller, else return 0 (default)
    # ........
    sadm_sleep 10 2                                                     # Sleep 10Sec, 2sec interval
    sadm_write_log " "                                                  # Write an empty line
    
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
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
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
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
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Won't come back if error
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong    
    main_process                                                        # Your PGM Main Process
    #process_servers                                                     # ssh to all actives clients
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
