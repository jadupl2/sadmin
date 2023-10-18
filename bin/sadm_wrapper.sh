#! /usr/bin/env bash
# ==================================================================================================
# Title         :  sadm_wrapper.sh
# Version       :  1.6
# Author        :  Jacques Duplessis
# Date          :  2018_01_10
# Requires      :  sh and SADMIN Library
# Description   :  If you want to use SADM Tools but don't want to modify your script, then this
#                  script is for you.
#                  You will need to run this script and pass as a parameter the fully qualify path
#                    name of your script.
#
#                  Example : 
#                  Let's say you are on host 'server1' and you want to run a script name 'test.sh' 
#                  located in $SADMIN/bin you would run it like this:
#
#                       # $SADMIN/bin/sadm_wrapper.sh "$SADMIN/usr/bin/sadm_test.sh"
#
#                   After execution of your script you could check the log generated :
#
#                       # cat $SADMIN/log/${ServerName}_sadm_test.log
#
#                   Also you could see if your script succeeded and see starting, ending 
#                     and execution time 
#
#                       # cat $SADMIN/dat/rch/${ServerName}_sadm_test.rch
#                           server1 2018.01.07 22:30:03 .......... ........ ........ test 2
#                           server1 2018.01.07 22:30:03 2018.01.07 22:39:03 00:09:00 test 0
#       
#                       Every time you run a script with the SADM Tools two lines are written the
#                       'rch' (Return Code History) file. One line when the script is started and
#                       one line when it terminate. The Status code at the end of the line indicate
#                       that :
#                           0 = You Script as terminated with success.
#                           1 = Your Script as terminated with Error
#                           2 = Your Script is running.
#                      
#                       By looking at the last line of the 'rch' file we can see that the script
#                       ran on 'server1', started on the 7th January 2018 at 22:30:03, finished 
#                       on the 7th January 2018 at 22:39:03, total execution time is 9 seconds,
#                       the script name is 'test' and that it terminate with success (Return an
#                       exit code of 0 to sadm_wrapper.sh).
#
# ==================================================================================================
# Changelog
# 2018_01_09 lib v1.5 New Version - Script Restructure, Usage Instructions & Work with new Library
# 2018_09_19 lib v1.6 Update for Alert Group and new LIbrary
# 2020_04_02 lib v1.7 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2023_07_14 lib v1.7 Update with latest SADMIN section(v1.56).
# ==================================================================================================
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
export SADM_VER='1.7'                                      # Script version number
export SADM_PDESC="Want to use SADM Tools but don't want to modify your script, this is for you."
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




#===================================================================================================
# Scripts Variables 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s 'name-of-script-to-run' ['parameter(s) to your script']" "${BOLD}" "${CYAN}" "$(basename "$0")" "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}







# --------------------------------------------------------------------------------------------------
#                   Validation function before starting executing the script
# --------------------------------------------------------------------------------------------------
#
check_script()
{
    # The Script Name to run must be specified on the command line
    if [ -z "$SCRIPT" ]
        then    echo "[ERROR] Script to execute must be specified" 
                show_usage 
                echo "Job aborted"
                return 1
    fi

    # The script specified must exist in path specified
    if [ ! -e "$SCRIPT" ]
       then     echo "[ERROR] The script '$SCRIPT' doesn't exist" 
                show_usage 
                echo "Job aborted"
                return 1
    fi

    # The Script Name must executable
    if [ ! -x "$SCRIPT" ]
       then     echo "[ERROR] script '$SCRIPT' is not executable ?" 
                show_usage 
                echo "Job aborted"
                return 1
    fi
    return 0 
}




# ==================================================================================================
#                           P R O G R A M    S T A R T    H E R E
# ==================================================================================================
    if [ $# -eq 0 ]                                                     # If no Parameter received
        then echo "No arguments provided"                               # Advise User
             show_usage                                                 # Show Script Usage
             exit 1                                                     # Exit Script with Error
        else export SCRIPT="$1"                                         # Script uith pathname
             shift                                                      # Keep only argument(if any)    
             SADM_PN=$(basename "$SCRIPT")                              # Keep Script without Path
             SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)                # Script name without ext.
             source ${SADMIN}/lib/sadmlib_std.sh                        # Load SADMIN Std Library
             SADM_ALERT_TYPE=1           ; export SADM_ALERT_TYPE       # 0=No 1=OnErr 2=OnOK  3=All
             SADM_ALERT_GROUP='default'  ; export SADM_ALERT_GROUP      # Alert Group to Alert
    fi
    
    check_script                                                        # Validate param. received
    if [ $? -ne 0 ] ; then exit 1 ;fi                                   # Exit if Problem  
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    sadm_write "\nExecuting $SCRIPT $@ \n"                              # Write script name to log
    $SCRIPT "$@" >> $SADM_LOG 2>&1                                      # Run selected user script
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
