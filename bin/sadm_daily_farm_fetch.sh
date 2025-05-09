#! /usr/bin/env bash
####################################################################################################
# Title      :  sadm_daily_farm_fetch.sh
# Description:  Collect Hardware/Software/Performance Info Data from all actives servers
# Version    :  1.8
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) sadm_daily_farm_fetch.sh 1.4 21-04/2010
####################################################################################################
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
#
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
# CHANGE LOG
#
# 2015_10_10 server v1.9 Restructure and redesign for modularity
# 2017_12_17 server v2.0 Restructure for combining Aix and Linux
# 2017_12_23 server v2.1 Modifications for using MySQL and logic Enhancements
# 2018_01_08 server v2.2 Update SADM Library insertion section & Minor correction
# 2018_02_02 server v2.3 Added Operation Separator in log 
# 2018_02_08 server v2.4 Fix compatibility problem with 'dash' shell
# 2018_02_11 server v2.5 Rsync locally for SADMN Server
# 2018_05_01 server v2.6 Don't return an error if no active server are found & remove unnecessary msg
# 2018_06_03 server v2.7 Minor Corrections & Adapt to New SADM Shell Library.
# 2018_06_09 server v2.8 Change Script Name & Add Help and Version Function & Change Startup Order
# 2018_06_11 server v2.9 Change name for sadm_daily_farm_fetch.sh
# 2018_06_30 server v3.0 Get /etc/environment from client to know where SADMIN is install for rsync
# 2018_07_16 server v3.1 Remove verbose when doing rsync
# 2018_08_24 server v3.2 If couldn't get /etc/environment from client, change Email format.
# 2018_09_16 server v3.3 Added Default Alert Group
# 2019_02_27 server v3.4 Change error message when ping to system don't work
# 2019_05_07 server v3.5 Add 'W 5' ping option, should produce less false alert
# 2020_02_25 server v3.6 Fix intermittent problem getting SADMIN value from /etc/environment.
# 2020_03_21 server v3.7 Show Error Total only at the end of each system processed.
# 2020_04_05 server v3.8 Replace function sadm_writelog() with NL incl. by sadm_write() No NL Incl.
# 2020_04_21 server v3.9 Minor Error Message Alignment,
# 2020_04_24 server v4.0 Show rsync status & solve problem if duplicate entry in /etc/environment.
# 2020_05_06 server v4.1 Modification to log structure
# 2020_05_23 server v4.2 No longer report an error, if a system is rebooting because of O/S update.
# 2020_10_29 server v4.3 If comma was used in server description, it cause delimiter problem.
# 2020_11_05 server v4.4 Change msg written to log & no alert while o/s update is running.
# 2020_12_12 server v4.5 Add and use SADM_PID_TIMEOUT and SADM_LOCK_TIMEOUT Variables.
# 2021_02_13 server v4.5 Change for log appearance.
# 2021_06_03 nolog  v4.6 Update SADMIN section and minor code update
# 2022_05_24 server v4.7 Updated to use the library 'check_lock_file()' function.
# 2022_08_17 server v4.8 Update SADMIN section 2.2 and use error log when problem encountered.
# 2022_09_23 server v4.9 Use SSH port specify per server & update SADMIN section to v1.52.
# 2023_04_29 server v4.10 Increase speed of files copy from clients to SADMIN server.
# 2023_05_24 server v4.11 Remove repeating error count in the error log.
# 2023_07_18 server v4.12 Fix problem when not using the standard ssh port (22).
# 2023_09_18 server v4.13 When syncing to the SADMIN server, don't use SSH to rsync .
# 2023_12_14 server v4.14 'SADM_HOST_TYPE' in 'sadmin.cfg', decide if system is a client or a server.
# 2023_12_30 server v4.15 Now using new function "Bug fix on files synchronization.
#@2025_01_29 server v4.16 Remove Escape character from logs 
#@2025_04_13 server v4.17 Remove some uneeded lines from the error log.
#@2025_04_22 server v4.18 Remove some messages that was not suppose to be written to the rror log.
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.56
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='4.18'                                     # Script version number
export SADM_PDESC="Collect hardware,software,performance info data from all active systems."
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
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]

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
# ---------------------------------------------------------------------------------------






# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
export HW_DIR="$SADM_DAT_DIR/hw"	                                    # Hardware Data collected
export ERROR_COUNT=0                                                    # Global Error Counter
export TOTAL_AIX=0                                                      # Nb Error in Aix Function
export TOTAL_LINUX=0                                                    # Nb Error in Linux Function
export SADM_STAR=$(printf %80s |tr " " "*")                             # 80 * line
export DEBUG_LEVEL=0                                                    # 0=NoDebug Higher=+Verbose
export ETCENV="/etc/environment"                                




# --------------------------------------------------------------------------------------------------
# Show Script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}





# --------------------------------------------------------------------------------------------------
#                                   Process All Actives Servers 
# --------------------------------------------------------------------------------------------------
process_servers()
{
    sadm_write_log "${BOLD}Processing All Actives Server(s)${NORMAL}"

    # BUILD THE SELECT STATEMENT FOR ACTIVE SERVER & OUTPUT RESULT IN CSV FORMAT TO $SADM_TMP_FILE1
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_ssh_port,srv_osname"
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName

    # RUN THE SELECT STATEMENT
    CMDLINE1="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "        # MySQL & Use Read Only User  
    if [ $DEBUG_LEVEL -gt 5 ]                                           # If Debug Level > 5 
        then sadm_write_log "$CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' |tr '/\t/' '/,/'"
    fi
    $CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1

    # IF FILE WAS NOT CREATED OR HAS A ZERO LENGTH THEN NO ACTIVES SERVERS WERE FOUND
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_write_log "${BOLD}No Active Server were found.${NORMAL}" 
             return 0 
    fi 

    # PROCESS EACH SYSTEM PRESENT IN THE FILE CREATED BY THE SELECT STATEMENT
    xcount=0; ERROR_COUNT=0; warning_count=0                            # Reset Server/Error Counter
    while read wline                                                    # Then Read Line by Line
        do
        ((xcount++))
        server_name=$(echo $wline|awk -F\; '{ print $1 }')              # Extract Server Name
        server_os=$(echo $wline|awk -F\; '{ print $2 }')                # Extract O/S (linux/aix)
        server_domain=$(echo $wline|awk -F\; '{ print $3 }')            # Extract Domain of Server
        server_monitor=$(echo $wline|awk -F\; '{ print $4 }')           # Monitor  t=True f=False
        server_sporadic=$(echo $wline|awk -F\; '{ print $5 }')          # Sporadic t=True f=False
        server_ssh_port=$(echo $wline|awk -F\; '{ print $6 }')          # Server SSH Port to connect
        server_osname=$(echo $wline|awk -F\; '{ print $7 }')            # Server O/S Name
        fqdn_server=$(echo ${server_name}.${server_domain})             # Create FQN Server Name
        sadm_write_log "  "
        #sadm_write_log "${BOLD}Processing [$xcount ($server_os)] ${fqdn_server}${NORMAL}"
        sadm_write_log "Processing [ $xcount ($server_osname) ] ${fqdn_server}"
        
        # IF SERVER NAME CAN'T BE RESOLVED - SIGNAL ERROR TO USER AND CONTINUE WITH NEXT SYSTEM.
        if ! host $fqdn_server >/dev/null 2>&1
            then SMSG="[ ERROR ] Can't process '$fqdn_server', hostname can't be resolved."
                 sadm_write_err "${SMSG}"                               # Advise user
                 ((ERROR_COUNT++))                                      # Increase Error Counter
                 sadm_write_log "Error Count is now at $ERROR_COUNT"
                 continue                                               # Continue with next Server
        fi

        # Check if System is Locked.
        sadm_lock_status "$server_name"                              # Check lock file status
        if [ $? -eq 1 ] 
            then sadm_write_err "[ WARNING ] System $server_name is currently lock."
                 sadm_write_err "Continue with next system."
                 ((warning_count++))                                    # Increase Warning Counter
                 continue
        fi                                                              # System Lock, Nxt Server

        # TEST SSH TO SERVER (IF NOT ON SADMIN SERVER)
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] 
            then $SADM_SSH -qnp "$server_ssh_port" "$fqdn_server" date > /dev/null 2>&1
                 RC=$?                                                  # Save Error Number
            else RC=0                                                   # RC=0 no SSH on SADMIN Srv
        fi 

        if [ $RC -ne 0 ]                                                # If SSH failed
           then if [ "$server_sporadic" = "1" ]                         # If Error on Sporadic Host
                   then sadm_write_err "[ WARNING ]  Can't SSH to ${fqdn_server} (Sporadic System)."
                        sadm_write_log "Continuing with next system"    # Not Error if Sporadic Srv. 
                        ((warning_count++))                             # Increase Warning Counter
                        continue
                fi 
                if [ "$server_monitor" = "0" ]                          # If Error & Monitor is OFF
                   then sadm_write_err "[ WARNING ] Can't SSH to ${fqdn_server} (Monitoring is OFF)."
                        sadm_write_log "Continuing with next system"    # Not Error Monitoring Off
                        ((warning_count++))                             # Increase Warning Counter
                        continue
                fi 
                if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_write_log "Return Code is $RC" ;fi 
                sadm_write_err "[ ERROR ] Can't SSH to ${fqdn_server} on port $server_ssh_port."
                ((ERROR_COUNT++))
                sadm_write_log "Error Count is now at $ERROR_COUNT"
                continue
        fi                                                              # OK SSH Worked the 1st time

        # MAKING SURE THE $SADMIN/DAT/$SERVER_NAME EXIST ON LOCAL SADMIN SERVER
        if [ ! -d "${SADM_WWW_DAT_DIR}/${server_name}" ]
            then sadm_writelog "Creating ${SADM_WWW_DAT_DIR}/${server_name} directory"
                 mkdir -p "${SADM_WWW_DAT_DIR}/${server_name}"
                 chmod 2775 "${SADM_WWW_DAT_DIR}/${server_name}"
        fi

        # Get the remote /etc/environment file to determine where SADMIN is install on remote
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}"
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
        #if [ "$SADM_HOST_TYPE" != "S" ]
            then scp -CqP "$server_ssh_port" "${server_name}:${ETCENV}" "${WDIR}" >/dev/null 2>&1
            else cp "$ETCENV" "${WDIR}" >/dev/null 2>&1
        fi
        if [ $? -eq 0 ]                                                 # If file was transferred
            then RDIR=$(grep "SADMIN=" $WDIR/environment |sed 's/export //g' |awk -F= '{print $2}'|tail -1)
                 if [ "$RDIR" != "" ]                                   # No Remote Dir. Set
                    then sadm_writelog "[ OK ] SADMIN installed in ${RDIR} on ${server_name}."
                    else sadm_write_err "[ WARNING } Couldn't get $ETCENV."
                         if [ "$server_sporadic" = "1" ]                # SSH don't work & Sporadic
                            then sadm_write_log "${server_name} is a sporadic system."
                            else ((ERROR_COUNT++))                      # Add 1 to Error Count
                                 sadm_write_log "Error Count is now at $ERROR_COUNT"
                         fi
                         sadm_write_log "Continuing with next system."  # Advise we are skipping srv
                         ((warning_count++))                            # Increase Warning Counter
                         continue                                       # Go process next system
                 fi 
            else sadm_write_err "[ ERROR ] Couldn't get $ETCENV on ${server_name}."
                 ((ERROR_COUNT++))                                      # Add 1 to Error Count
                 sadm_write_log "Error count is now at $ERROR_COUNT "
                 sadm_write_log "Continuing with next system."          # Advise we are skipping srv
                 continue                                               # Go process next system
        fi
    


        # DR (Disaster Recovery) Information Files
        # Transfer $SADMIN/dat/dr (Disaster Recovery) from Remote to $SADMIN/www/dat/$server/dr Dir.
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/dr"                    # Local Receiving Dir.
        #sadm_write_log "Make sure local directory $WDIR exist."
        if [ ! -d "${WDIR}" ]
            then sadm_write_log "  - Creating ${WDIR} directory."
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
        fi

        REMDIR="${RDIR}/dat/dr" 
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
            then rcmd="rsync -ar -e ssh -p $server_ssh_port --delete ${server_name}:${REMDIR}/ $WDIR/ "
                 rsync -ar -e "ssh -p $server_ssh_port" --delete "${server_name}:${REMDIR}/" "$WDIR/" >>"$SADM_LOG" 2>&1
                 RC=$?
            else rcmd="rsync -ar --delete  ${REMDIR}/ $WDIR/ "
                 rsync -ar --delete "${REMDIR}/" "$WDIR/" >>"$SADM_LOG" 2>&1
                 RC=$?
        fi
        if [ $RC -ne 0 ]
            then sadm_write_err "[ ERROR ] ($RC) ${rcmd}"
                 ((ERROR_COUNT++))
                 sadm_write_log "Error Count is now at $ERROR_COUNT"
            else sadm_writelog "[ OK ] ${rcmd}"
        fi
 

        # NMON FILES
        # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server_name/nmon  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/nmon"                     # Local Receiving Dir.
        if [ ! -d "${WDIR}" ]
            then sadm_write_log "  - Creating ${WDIR} directory."
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
        fi

        REMDIR="${RDIR}/dat/nmon" 
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
            then rcmd="rsync -ar -e ssh -p $server_ssh_port --delete ${server_name}:${REMDIR}/ $WDIR/ "
                 rsync -ar -e "ssh -p $server_ssh_port" --delete ${server_name}:${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
                 RC=$?
            else rcmd="rsync -ar --delete ${REMDIR}/ $WDIR/ "
                 rsync -ar -delete ${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
                 RC=$?
        fi
        if [ $RC -ne 0 ]
            then sadm_write_err "[ ERROR ] #($RC) ${rcmd}"
                 ((ERROR_COUNT++))
            else sadm_write_log "[ OK ] ${rcmd}" 
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_write_err "Error Count is now at $ERROR_COUNT" ;fi

        done < $SADM_TMP_FILE1

# Show Total Error Count After Processing Each Server
    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Total Error(s) count   : ${ERROR_COUNT}"
    sadm_writelog "Total Warning(s) count : ${warning_count}"
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog " "
    sadm_write_log " "
    return $ERROR_COUNT
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
               num=$(echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$)  # Valid is Level is Numeric
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
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ; fi                    # Exit if Problem 
    process_servers                                                     # Collect Files from Servers
    SADM_EXIT_CODE=$?                                                   # Return Code = Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
