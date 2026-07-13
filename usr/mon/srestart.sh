#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
#   Author        : Jacques Duplessis
#   Script Name   : srestart.sh
#   Creation Date : 2018/07/11
#   Requires      : sh and SADMIN Shell Library
#   Description   : Use to restart a service, executed by sysmon.pl when a service isn't running.
#
# Note : All scripts (Shell,Python,Perl,php), configuration files and screen output are formatted to 
#        have and use a 100 characters per line. Comments in all scripts always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#   The SADMIN tools are free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
# 
#   Description :   This is a script that is called by the SADMIN System Monitor, when a
#                   service isn't running. This script will attempt to restart it, by calling the 
#                   SystemV (service command) or SystemD (systemctl command). The Status code
#                   returned will be zero (0) if it succeeded and one (1) if it didn't.
#                   Parameter Receive is the service(s) to restart.
#                       If more than one service name is received, it must be comma seperated.
#                       Example: $SADMIN/usr/mon/srestart.sh "cron,crond"
#
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_07_11 mon v1.00 Initial Version
# 2018_07_12 mon v1.01 First Production release
# 2019_04_17 mon v1.02 Bug fix that prevent some services to restart and Log reformat.
# 2019_04_19 mon v1.03 Error Message can be written to txt file which is use afterward by sysmon.
#@2020_12_01 mon v1.04 Include Date & Time of event in message.
#@2026_05_02 mon v1.05 Include Status of Service after restart & with more descriptive messsage.
# --------------------------------------------------------------------------------------------------
# Add trap to catch ^C and stop script gracefully.
trap 'sadm_stop 1; exit 1' 2                                        
#set -x
     




# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup Global Variables and load the SADMIN standard library $SADMIN/lib/sadmlib_std.sh.
#       - To use SADMIN scripting tools, this section MUST be present near the top of your code.    


# Make sure environment variable 'SADMIN' is defined.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\nSet 'SADMIN' environment variable to the install directory." 
        printf "\nAdd a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 
fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\nSADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 
fi 

# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.05'                                     # Script version number
export SADM_DESC="Use to restart a service, it's call by sysmon.pl when a service isn't running." 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_QUIET="N"                                      # N=Show Err.Msg Y=ReturnErrorCode No Msg
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoLogHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeLogFooter N=NoLogFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_TMP_FILE1=$(mktemp -q "$SADMIN/tmp/${SADM_INST}1_XXX") # WorkFile, remove by sadm_stop()
export SADM_TMP_FILE2=$(mktemp -q "$SADMIN/tmp/${SADM_INST}2_XXX") # WorkFile, remove by sadm_stop()
export SADM_TMP_FILE3=$(mktemp -q "$SADMIN/tmp/${SADM_INST}3_XXX") # WorkFile, remove by sadm_stop()

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VARIABLES DEFINE BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).export SADM_WARNING_GRP="default"
#export SADM_ALERT_GROUP="default"                          # Error Group Define in alert_group.cfg
#export SADM_WARNING_GROUP="default"                        # Warning alert Group (alert_group.cfg)   
#export SADM_INFO_GROUP="default"                           # Info alert Group (in alert_group.cfg)
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=400                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------




#===================================================================================================
#                               Script environment variables
#===================================================================================================
export DASH=$(printf %80s |tr ' ' '-')                                  # 80 dashes
export SYSTEMD="Y"                                                      # Default to systemd
export SRVNAME=""                                                       # Service name to restart
export SADM_UMON_DIR="${SADMIN}/usr/mon"                                # SysMon User Script Dir.
export SRVNAME=""                                                       # Service name to restart




# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    byellow="${BOLD}${YELLOW}" ; bcyan="${BOLD}${CYAN}"; bgreen="${BOLD}${GREEN}"; reset="${NORMAL}"
    
    printf "\n${byellow}${SADM_PN} v${SADM_VER} - Hostname '${SADM_HOSTNAME}'"
    printf "\n${byellow}${SADM_DESC}${reset}\n"
    printf "\nUsage: %s%s%s%s [options] [serviceName]" "$bcyan" "$(basename "$0")" "${reset}"
    printf "\n\n${bgreen}Options:${reset}"
    printf "\n  ${byellow}[-d 0-9]${reset}\tSet Debug verbose Level."
    printf "\n  ${byellow}[-h]${reset}\t\tShow this help message."
    printf "\n  ${byellow}[-v]${reset}\t\tShow script version and information."
    printf "\n\n"
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# -d[0-9] Set Debug Level  
# -h) Show Help Usage, 
# -v) Show Script Version,  
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
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
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    # Show Script Name, Version and starting Date/Time.
    sadm_write_log "Service name to restart : ${SRV_NAME}"              # SHow User we receive it

    # Test if running on Systemd system or SysVinit
    if [ -d /run/systemd/system ] 
        then sadm_write_log "This system is using 'systemd'."
             SYSTEMD="Y" 
        else sadm_write_log "This system is using 'SysVinit'."
             SYSTEMD="N"
    fi 


    # Try to restart each Service name received (Could be comma delimited).
    STARTED="N"                                                         # No Restart Worked Default 
    for service in $(echo $SRV_NAME | sed "s/,/ /g")                    # For every Serv. comma del.
        do     
        sadm_write_log "Validating service '$service.service'."          # Show User we are testing

        # Systemd System - Use systemctl to restart and check status of service
        if [ "$SYSTEMD" = "Y" ]                                         # If System using SystemD
            then systemctl list-units --all --type=service --no-pager | awk '{print $1}' | grep -q "^$service.service"                 
                 #systemctl list-units --all --type=service --no-pager | grep -q "${service}.service"
                 if [ $? -ne  0 ]                                       # If Service down't exist
                    then sadm_write_log "Service '$service.service' doesn't exist." 
                         continue                                       # Skip to next service
                    else sadm_write_log "Service '$service.service' exist." 
                 fi
                 systemctl restart $service >>$SADM_LOG 2>&1            # Restart using systemctl
                 if [ $? -eq 0 ]                                        # If restart worked
                    then STARTED="Y"                                    # At least one restart work
                         sadm_write_log "[ SUCCESS ] Restarting service '$service'." 
                    else sadm_write_log "[ ERROR ] Failed to restart service '$service'." 
                 fi 
                 systemctl is-active $service >/dev/null 2>&1
                 if [ $? -eq 0 ]                                        # If service is active
                    then sadm_write_log "Service '$service' is active after restart."
                    else sadm_write_log "[ ERROR ] Service '$service' is NOT active after restart." 
                 fi

            # SystemV System - Use service to restart and check status of service
            else sadm_write_log "Validating service '$service'."        # Show User we are testing
                 if [ ! -f /etc/init.d/$service ]                       # If Service down't exist
                    then sadm_write_log "Service '$service' not found in '/etc/init.d'." 
                         continue                                       # Skip to next service
                    else sadm_write_log "Service '$service' exist." 
                 fi
                 sadm_write_log "Restarting service '$service'."
                 service $service restart  >>$SADM_LOG 2>&1             # Restart using service cmd
                 if [ $? -eq 0 ]                                        # If restart worked
                    then STARTED="Y"                                    # At least one restart work
                         sadm_write_log "[ SUCCESS ] Restarting service '$service'." 
                    else sadm_write_log "[ ERROR ] Failed to restart service '$service'."
                 fi 
                 /etc/init.d/$service status >>$SADM_LOG 2>&1
                 if [ $? -eq 0 ]                                        # If service is active
                    then sadm_write_log "Service '$service' is active after restart."
                    else sadm_write_log "[ ERROR ] Service '$service' is NOT active after restart." 
                 fi                                                    
        fi
        done
    
    # If Service was started successfully then Return 0 else 1.
    EFILE="${SADM_UMON_DIR}/${INST}_${SRV_NAME}.txt"                    # Script Error Mess File
    if [ "$STARTED" = "Y" ]                                             # At least 1 service started
        then RC=0                                                       # OK Return Code is 0
             rm -f $EFILE >/dev/null 2>&1                               # Remove Error File when OK
        else RC=1                                                       # Error Return Code is 1
             EMSG="Couldn't start service '$SRV_NAME'."                 # Error Message file Test
             echo "$EMSG" > $EFILE                                      # Write to Error Msg File
             sadm_write_log "[ ERROR ] ${EMSG}"
    fi              
    return $RC                                                          # Return Status to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    # Parameter received should always be 1 string - If not write to error log and exit 1
    if [ $# -eq 1 ]
        then SRV_NAME=$1                                                # Service Name to Restart
        else sadm_write_err " " 
             sadm_write_err "[ ERROR ] Script should receive the name of the service to restart as a parameter."
             sadm_write_err "   - Received '$*' and this isn't valid." 
             sadm_write_err "   - Service may have different name across distribution."
             sadm_write_err "   - If more than one service name is received, it must be comma separated."
             sadm_write_err "   - Example: $SADMIN/usr/mon/srestart.sh \"cron,crond\""
             sadm_write_err "   - On RedHat/CentOS the service name is 'crond' and on Debian/Ubuntu it's 'cron'."
             exit 1
    fi

    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Won't come back if error
    main_process                                                        # Your PGM Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)