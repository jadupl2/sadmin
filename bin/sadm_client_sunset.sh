#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_client_sunset.sh
#   Synopsis :  This script must be run once a day at the end of the day.
#               It run multiple script that collect information's about server.
#   Version  :  1.0
#   Date     :  3 December 2016
#   Requires :  sh
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
# 2017_01_02 client v1.1 Cosmetic Log Output change
# 2017_12_28 client v1.2 Adapted to MacOS to show Message non availability of nmon on OSX. 
# 2018_01_05 client v1.3 Add MySQL Database Backup in execution sequence
# 2018_01_06 client v1.4 Create Function fork the multiple script run by this one
# 2018_01_10 client v1.5 Database Backup - Compress Backup now
# 2018_01_10 client v1.6 Database Backup was not taken when compress (-c) was used.
# 2018_01_23 client v1.7 Added the script to read all nmon files and create/update the proper RRD.
# 2018_01_24 client v1.8 Pgm Restructure and add check to run rrd_update only on sadm server.
# 2018_01_25 client v1.9 Remove rrd_update and move it to sadm_sod_server.sh (start of day script)
# 2018_02_04 client v2.0 Remove MySql Backup & Change Script name from sadm_eod_client.sh to sadm_client_sunset.sh
# 2018_04_05 client v2.1 Remove execution of sadm_create_sar_perfdata.sh not needed anymore
# 2018_06_03 client v2.2 Adapt to new version of Shell Library and small ameliorations
# 2018_06_09 client v2.3 Change & Standardize scripts name called by this script & Change Startup Order
# 2018_09_16 client v2.4 Added Default Alert Group
# 2018_11_13 client v2.5 Adapted for MacOS (Don't run Aix/Linux scripts)
# 2020_02_23 client v2.6 Produce an alert only if one of the executed scripts isn't executable.
# 2020_04_01 client v2.7 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2020_04_05 client v2.8 Remove one call to sadm_start (Was there twice)
# 2020_05_08 client v2.9 Minor Comment changes.
# 2020_11_24 client v2.10 Minor log adjustment.
# 2022_08_25 client v2.11 Updated with new SADMIN SECTION V1.52.
#@2024_07_09 client v2.12 Minor update to standardize the code. 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x



# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ; fi # LastChance defining SADMIN
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
export SADM_VER='2.12'                                     # Script version number
export SADM_PDESC="At the end of day, run multiple scripts to collect information about the system."
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
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
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------



#===================================================================================================
# Scripts Variables 
#===================================================================================================





# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" "$(basename "$0")" "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}


#===================================================================================================
#                  Run the script received as parameter (Return 0=Success 1= Error)
#===================================================================================================
run_script()
{
    SCRIPT=$1                                                           # Shell Script Name to Run
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${CMDLINE}"                                   # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                             # If SCript doesn't exist
        then sadm_write_err "[ ERROR ] Script '$SCMD' not executable or doesn't exist."
             return 1                                                   # Return Error to Caller
    fi 

    sadm_write_log " " 
    sadm_write_log " " 
    sadm_write_log " " 
    sadm_write_log "Running '${SADM_BIN_DIR}/${SCRIPT}' ... " "NOLF"
    $SCMD  >>$SADM_LOG 2>&1                                             # Run the Script
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_write_err "[ ERROR ] Encounter while running '${SCRIPT}'."   
             sadm_write_err "  - Verify the log file : ${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log"  
             return 1
        else sadm_write_log "[ SUCCESS ] '${SCRIPT}' terminated with success."     
    fi
    return 0                                                            # Return Success to Caller
}


#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    SADM_EXIT_CODE=0                                                    # Reset Error counter

    # On Every Client (including SADMIN Server) we prune some files & check file owner & Permission
    run_script "sadm_client_housekeeping.sh"                           # Client HouseKeeping Script
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE++)) ;fi    # Increase Error Counter

    # Save Filesystem Information of current filesystem ($SADMIN/dat/dr/hostname_fs_save_info.dat)
    if [ "$(sadm_get_ostype)" != "DARWIN" ]                            # If Not on MacOS 
        then run_script "sadm_dr_savefs.sh"                            # Client Save LVM FS Info
             if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi  # Incr. Error Counter
    fi

    # Collect System Information and store it in $SADMIN/dat/dr (Used for Disaster Recovery)
    run_script "sadm_create_sysinfo.sh"                                # Create Client Sysinfo file
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE++)) ;fi    # Increase Error Counter

    # Create HTML file containing System Info.(files,hardware,software) $SADMIN/dat/dr/hostname.html
    if [ "$(sadm_get_ostype)" != "DARWIN" ]                             # If Not on MacOS 
        then run_script "sadm_cfg2html.sh"                             # Produce cfg2html html file
             if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE++)) ;fi    # Increase Error Counter
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



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
