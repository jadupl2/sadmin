#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_support_request.sh
#   Synopsis    :   Collect SADMIN information to help debugging a problem
#   Version     :   1.0
#   Date        :   30 March 2018 
#   Requires    :   sh 
#   Description :   Collect logs, and files modified during installation for debugging.
#                   If problem detected during installation, run this script an send the
#                   resulting log (setup_result.log) to support at sadmlinux@gmail.com
#
#   This code was originally written by Jacques Duplessis <sadmlinux@gmail.com>,
#    2016-2018 Jacques Duplessis <sadmlinux@gmail.com> - https://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_03_30 v1.0 Initial Version
# 2018_04_04 V1.1 Bug Fixes
# 2018_04_27 V1.2 Change Default Shell to Bash for running this script
# 2018_08_10 v1.3 Remove O/S Version Restriction and added /etc/environment printing.
# 2018_11_16 v1.4 Restructure for performance and flexibility.
# 2018_11_21 v1.5 Output file include content of log directory.
# 2018_12_11 v1.6 Include Shell and Python Library Demo output in log and SADM_USER info.
# 2018_12_31 Added: sadm_support_request.sh v1.7 - Include system information files from dat/dr dir.
# 2018_12_31 Added: sadm_support_request.sh v1.8 - Remove blank line & Comment Line (#) from output.
# 2019_06_10 Updated: v1.9 Add /etc/postfix/main.cf to support request output.
# 2019_06_11 Updated: V2.0 Code Revision and performance improvement.
# 2019_11_28 Updated: V2.1 When run on SADM server, will include crontab (osupdate,backup,rear).
# 2019_12_02 Updated: V2.2 Add execution of sadm_check_requirement.
#@2025_02_22 Updated: V2.3 Code optimization & restructure.
#
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x



# --------------------------  S A D M I N   C O D E    S E C T I O N  ------------------------------
# v1.56 - Setup for Global variables and load the SADMIN standard library.
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
export SADM_VER='2.3'                                      # Script version number
export SADM_PDESC="Collect SADMIN information to help debugging a problem"
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VARIABLES DEFINE BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
export SADM_MAX_LOGLINE=5000                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------





  

#===================================================================================================
# Scripts Variables 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
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
#                              Print File received as parameter
#===================================================================================================
print_file()
{
    wfile=$1                                                            # Save FileName to Print
    sadm_write_log " "
    sadm_write_log " "
    sadm_write_log "$SADM_TEN_DASH"  
    
    if [ -r $wfile ]                                                    # If File is Readable
       then sadm_write_log "Adding $wfile to support request log ..."
            sadm_write_log "Content of ${wfile}" 
            grep -Ev "^#|^[[:space:]]*$" $wfile  | tee -a $SADM_LOG
            sadm_write_log "$SADM_TEN_DASH"  
            sadm_write_log " " 
            return 0  
       else sadm_write_log "Could not print, file not found : $wfile" 
            sadm_write_log "$SADM_TEN_DASH"     
            sadm_write_log " " 
            return 1 
    fi
    return
}


#===================================================================================================
#                  Run the script received if parameter (Return 0=Success 1= Error)
#===================================================================================================
run_command()
{
    SCRIPT="$1"                                                         # Shell Script Name to Run
    CMDLOG="$2"                                                         # Log Generated by Script
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${SCRIPT}"                                    # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                             # If SCript do not exist
        then sadm_write_err "[ERROR] ${SADM_BIN_DIR}/${SCRIPT} Don't exist or can't execute" 
             sadm_write_err " "
             return 1                                                   # Return Error to Callerr
    fi 

    sadm_write_log "Running $SCMD ..."                                  # Show Command about to run
    $SCMD | tee -a ${SADM_LOG} 2>&1                                     # Run Script Collect output
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_write_err "[ERROR] $SCRIPT Terminate with Error"      # Signal Error in Log
             sadm_write_err "Check Log for further detail about Error"  # Show user where to look
             sadm_write_err "${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log" # Show Log Name    
             return 1                                                   # Return Error to Callerr
        else sadm_write_log "[SUCCESS] Script $SCRIPT terminated."        # Advise user it's OK
    fi
    return 0                                                            # Return Success to Caller
}

#===================================================================================================
#                                       Main Process 
#===================================================================================================
main_process()
{
    print_file "/etc/environment" 
    print_file "/etc/profile.d/sadmin.sh" 
    print_file "$SADM_CFG_FILE"
    if [ -f "/etc/sudoers.d/033_sadmin-nopasswd" ] 
        then print_file "/etc/sudoers.d/033_sadmin-nopasswd" 
    fi 
    if [ -f "/etc/sudoers.d/033_sadmin" ] 
        then print_file "/etc/sudoers.d/033_sadmin"
    fi 
    print_file "/etc/cron.d/sadm_client"

    # Files that appears only on the SADMIN server.
    if [ $SADM_ON_SADMIN_SERVER = "Y" ] 
        then print_file "/etc/cron.d/sadm_server"
             print_file "/etc/cron.d/sadm_osupdate"
             print_file "/etc/cron.d/sadm_backup"
             print_file "/etc/cron.d/sadm_rear_backup"
    fi    
    print_file "/etc/selinux/config"
    print_file "/etc/postfix/main.cf"
    print_file "/etc/hosts"
    print_file "${SADM_DR_DIR}/${SADM_HOSTNAME}_system.txt"
    print_file "${SADM_DR_DIR}/${SADM_HOSTNAME}_sysinfo.txt"
    print_file "/etc/httpd/conf.d/sadmin.conf"

    # Copy the setup log (if exist) to SADMIN normal log directory,
    if [ -f "$SADM_SETUP_DIR/log/sadm_pre_setup.log" ] 
        then print_file $SADM_SETUP_DIR/log/sadm_pre_setup.log 
    fi 

    # Run the Shell Library Demo 
    sadm_write_log " "                                                  # Blank LIne
    CMD="sadmlib_std_demo"                                              # Script Name to execute
    run_command "${CMD}.sh"                                             # Run Shell Library Demo

    # Run the Python Library Demo 
    sadm_write_log " "                                                  # Blank LIne
    CMD="sadmlib_std_demo"                                              # Script Name to execute
    run_command "${CMD}.py"                                             # Run Python Library Demo

    # Run the check requirement script.
    sadm_write_log " "                                                  # Blank LIne
    CMD="sadm_requirements.sh"                                          # Script Name to execute
    run_command "${CMD}"                                                # Run Check Requirement

    # Include result of command "chage -l $SADM_USER", to see if password is expire
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # If Current O/S is Linux 
        then CMD="chage -l $SADM_USER"                                  # Command Name to execute
             sadm_write_log " "
             sadm_write_log "Running $CMD ..."                          # Show Command about to run
             $CMD | tee -a $SADM_LOG 2>&1                               # Exec Command
    fi

    # Create file with SADMIN tree in it
    command -v tree >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then sadm_write_log " "
             sadm_write_log "Recording $SADMIN tree structure list in $TLOG ..."
             tree $SADMIN | tee -a $SADM_LOG
    fi
    
    # List of files in SADMIN
    sadm_write_log " "
    sadm_write_log "Creating a listing of all files in $SADMIN ..."
    find $SADMIN -exec ls -l {} \; >> $SADM_LOG 2>&1

    # Print if all requirements are met.
    sadm_write_log "Print SADMIN requirements ...¨
    $SADMIN/bin/sadm_requirements.sh >>$SADM_LOG 2>&1

    # Create & Compress Support File
    BACDIR=$(pwd)
    cd "$SADM_LOG_DIR"
    SRQ_FILE="${SADM_TMP_DIR}/${SADM_HOSTNAME}_${SADM_INST}.tgz"
    tar -cvzf $SRQ_FILE $(basename "$SADM_LOG")

    # What to include in the email.
    sadm_write_log " "
    sadm_write_log "${YELLOW}Send this file '$SRQ_FILE' to sadmlinux@gmail.com.${NORMAL}"
    sadm_write_log "The email should include a description of the problem your having."
    sadm_write_log "We will get back to you as soon as possible."
    sadm_write_log " "
    cd $BACDIR

    return 0
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
    exit $SADM_EXIT_CODE 
