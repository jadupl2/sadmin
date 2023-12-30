#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :  Jacques Duplessis
#   Title       :  sadm_server_sunrise.sh
#   Synopsis    :  Daily early morning script, that retrieve data from servers & Update/Backup DB & NetInfo
#   Description :  Run Once Daily early around 5-6 am, it run multiple scripts before you start 
#                  your working day.
#                       Run Multiple Scripts :
#                           1)  housekeeping_server
#                           2)  daily_data_collection
#                           3)  database_update
#                           4)  nmon_rrd_update
#                           5)  subnet_lookup
#                           6)  backupdb
#   Version     :  1.6
#   Date        :  11 December 2016
#   Requires    :  sh & sadmlib.sh 
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
#
# 2016_12_12 v1.6 Cosmetics and Refresh changes 
# 2016_12_14 v1.7 Added execution of MySQL Database Python Update
# 2018_01_25 v1.8 Added update of Performance RRD based on nmon content of each server
#                 Change name from sadm_sod_server.sh to sadm_server_start_of_day.sh
# 2018_02_04 v1.9 Add Mysql Backup
#                    Change name from sadm_server_start_of_day.sh to sadm_server_sunrise.sh
# 2018_02_11 server v1.10 Change message when succeeded to run script
# 2018_06_06 server v2.0 Restructure Code, Added Comments & Change for New SADMIN Libr.
# 2018_06_09 server v2.1 Change all the scripts name executed by this script (Prefix sadm_server)
# 2018_06_11 server v2.2 Backtrack change v2.1
# 2018_06_19 server v2.3 Change Backup DB Command line (Default compress)
# 2018_09_14 server v2.4 Was reporting Error, even when all scripts ran ok.
# 2019_05_01 server v2.5 Log name now showed to help user diagnostic problem when an error occurs.
# 2019_05_23 server v2.6 Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
# 2020_02_23 server v2.7 Produce an alert only if one of the executed scripts isn't executable.
# 2020_06_03 server v2.8 Update code section and minor update while writing new documentation
#@2022_12_29 server v2.9 Update SADMIN code section to 1.56
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTS LE ^C
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
export SADM_VER='2.9'                                      # Script Version
export SADM_PDESC="Early morning script, that retrieve data from active system & Update DB & NetInfo."
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
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
#export SADM_MAX_LOGLINE=400                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------




# --------------------------------------------------------------------------------------------------
# Show Script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]\n" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}


#===================================================================================================
#                  Run the script received as parameter (Return 0=Success 1= Error)
#===================================================================================================
exec_script()
{
    RC=0                                                                # Set Error Flag at OFF
    SCRIPT="$*"                                                         # Name of Script to execute
    SCMD="${SADM_BIN_DIR}/${SCRIPT}"                                    # Script full path name
    FLOG=$(echo $SCRIPT | awk -F\. '{print $1}')                        # Log name without extension
    SLOG="${SADM_LOG_DIR}/${SADM_HOSTNAME}_${FLOG}.log"                 # Log Name full path
    if [ ! -x $SCMD ]                                                   # Script not executable
        then sadm_write_err "[ ERROR ] Script $SCMD not executable or doesn't exist."
             RC=1                                                       # Raise Error Flag 
        else sadm_write_log "Running $SCMD ..."                          # Show Running Script Name
             $SCMD >/dev/null 2>&1                                      # Run the Script
             if [ $? -ne 0 ]                                            # If Error was encounter
                then sadm_write_log "[ WARNING ] Encounter while running $SCRIPT"   
                     sadm_write_log "For detail consult the log ($SLOG)" # Log for more detail
                else sadm_write_log "[ SUCCESS ] Running $SCMD"          # Advise user it's OK
             fi
    fi    
    return $RC
}




#===================================================================================================
# Main Process (Used to run script on current server)
#===================================================================================================
main_process()
{
    ERROR_COUNT=0                                                       # Clear Error Counter

    # Once a day - Delete old rch and log files & chown+chmod on SADMIN Server
    exec_script "sadm_server_housekeeping.sh"                           # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count
    
    # Collect from all servers Hardware info, Perf. Stat, ((nmon and sar)
    exec_script "sadm_daily_farm_fetch.sh"                              # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Daily DataBase Update with the Data Collected
    exec_script "sadm_database_update.py"                               # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # With all the nmon collect from the server farm update respective host rrd performace database
    exec_script "sadm_nmon_rrd_update.sh"                               # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Scan the Subnet Selected - Inventory IP Address Avail.
    exec_script "sadm_subnet_lookup.py"                                 # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Once a day we Backup the MySQL Database
    exec_script "sadm_backupdb.sh"                                      # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Set SADM_EXIT_CODE according to Error Counter (Return 1 or 0)
    if [ "$ERROR_COUNT" -gt 0 ]                                         # If some error occured
        then SADM_EXIT_CODE=1                                           # Error Set exit code to 1
        else SADM_EXIT_CODE=0                                           # Succes Set exit code to 0
    fi

    return $SADM_EXIT_CODE                                              # Return No Error to Caller
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
# Main Code Start Here
#===================================================================================================
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Won't come back if error
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong    
    main_process                                                        # Your PGM Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)

