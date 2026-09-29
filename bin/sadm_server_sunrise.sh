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
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2016_12_12 server v01.06.00 Cosmetics and Refresh changes 
# 2016_12_14 server v01.07.00 Added execution of MySQL Database Python Update
# 2018_01_25 server v01.08.00 Added update of Performance RRD based on nmon content of each server
# 2018_02_04 server v01.09.00 Add Mysql Backup
# 2018_02_11 server v01.01.10 Change message when succeeded to run script
# 2018_06_06 server v02.00.00 Restructure Code, Added Comments & Change for New SADMIN Libr.
# 2018_06_09 server v02.01.00 Change all the scripts name executed by this script (Prefix sadm_server)
# 2018_06_11 server v02.02.00 Backtrack change v2.1
# 2018_06_19 server v02.03.00 Change Backup DB Command line (Default compress)
# 2018_09_14 server v02.04.00 Was reporting Error, even when all scripts ran ok.
# 2019_05_01 server v02.05.00 Log name now showed to help user diagnostic problem when an error occurs.
# 2019_05_23 server v02.06.00 Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
# 2020_02_23 server v02.07.00 Produce an alert only if one of the executed scripts isn't executable.
# 2020_06_03 server v02.08.00 Update code section and minor update while writing new documentation
# 2023_12_29 server v02.09.00 Minor enhancements and update SADMIN section to v1.56.
##2026_09_29 server v03.00.00 Minor update (update sadmin section to 1.60).
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTS LE ^C
#set -x



                                                                                         
# ---------   S T A R T   O F   S A D M I N   R E Q U I R E D   C O D E   S E C T I O N  -----------
# v1.60 - Setup Global Variables and load the SADMIN standard library $SADMIN/lib/sadmlib_std.sh.
#       - To use SADMIN scripting tools, this section MUST be present near the top of your code.    
#
# Make sure environment variable 'SADMIN' is defined, if it's not, exit with error message.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\n[ ERROR ] Set 'SADMIN' environment variable to the install directory." 
        printf "\n  - Add a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 
fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\n[ ERROR ] SADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 
fi 


# SADMIN Section of your program that is shared with SADMIN Bash Library.
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s|tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.
export SADM_DEBUG=0                                        # Debug Level(0-9), 0 = NoDebug
export SADM_EXIT_CODE=0                                    # Pgm. Default Exit Code
export SADM_PN=$(basename "$0")                            # Script name(with extension)
export SADM_INST="${SADM_PN%.*}"                           # Script name(without extension)

export SADM_VER='3.0'                                      # Script Version
export SADM_DESC="Early morning script, that retrieve data from active system & Update DB & NetInfo."
export SADM_ROOT_ONLY="Y"                                  # Pgm. run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Pgm. run only on SADMIN server? [Y]/[N]
export SADM_GROUP_ONLY='N'                                 # Pgm. run only if usr part of SADMIN Grp
export SADM_MULTIPLE_EXEC="N"                              # Can Run Simultaneous copy of script Y/N
export SADM_QUIET="N"                                      # Y=HideMsg & Error#  N=Show Msg & Error#
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Append log ? Y=AppendLog,N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y = ProduceLogHeader, N = NoLogHeader
export SADM_LOG_FOOTER="Y"                                 # Y = ProduceLogFooter, N = NoLogFooter
export SADM_USE_RCH="Y"                                    # Update the RCH History File (Y/N)
export SADM_ERRMSG=""                                      # Error Message returned by Library 
export SADM_ERRNO=0                                        # Error number (0=OK) returned by Library
export SADM_PID_TIMEOUT=7200                               # Sec. before PID file is remove,7200=2hr
export SADM_LOCK_TIMEOUT=3600                              # Sec. before System LockFile is Del, 1hr
export SADM_DB_USED="N"                                    # Use or Not, Got to be on SADMIN server
export SADM_DB_NAME="sadmin"                               # Database Name SADM_DBNAME in sadmin.cfg
export SADM_TMP_FILE1=$(mktemp -q "$SADMIN/tmp/sadm_tmp1_XXX") # Make tmpfile1, rm in sadm_stop()
export SADM_TMP_FILE2=$(mktemp -q "$SADMIN/tmp/sadm_tmp2_XXX") # Make tmpfile2, rm in sadm_stop()
export SADM_TMP_FILE3=$(mktemp -q "$SADMIN/tmp/sadm_tmp3_XXX") # Make tmpfile3, rm in sadm_stop()

# Load SADMIN Bash Shell Library, ready to  be used.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Init SADMIN tools, load cfg files

# Example of some functions and variable you can use.
export SADM_OS_NAME=$(sadm_get_osname)                     # REDHAT,ROCKY,ALMA,CENTOS,DEBIAN,UBUNTU.
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# Variables Below Are Taken From SADMIN Configuration File (sadmin.cfg) when the Library is loaded.
# You Can Overridde them On A Per Program Basis (If Needed).
#export SADM_ALERT_TYPE=1                                   # 0=NoAlert 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Error Group Define in alert_group.cfg
#export SADM_WARNING_GROUP="default"                        # Warning Alert Group (alert_group.cfg)   
#export SADM_INFO_GROUP="default"                           # Info Alert Group (in alert_group.cfg)
#export SADM_ALERT_REPEAT=0                                 # 0=No Alert Repeat, Sec. between Repeat
#export SADM_MAIL_ADDR="your_email@domain.com"              # Send email to...default in sadmin.cfg
#export SADM_MAX_LOGLINE=400                                # Nb of Lines to trim (0=NoTrim)
#export SADM_MAX_RCHLINE=35                                 # Nb of Lines to trim (0=NoTrim)
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------



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
# -h) Show Help Usage, -v) Show Script Version,  -d0-9] Set Debug Level  -X=Delete PID file.
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hvX" opt ; do                                      # Loop to process Switch
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
            X) /usr/bin/rm -f "${SADMIN}/tmp/${SADM_INST}.pid" >/dev/null 2>&1
               printf "\n${BOLD}${BLINK}${YELLOW}The PID File ("${SADMIN}/tmp/${SADM_INST}.pid") is now removed.${NORMAL}\n" 
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
    main_process                                                        # Your PGM Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)

