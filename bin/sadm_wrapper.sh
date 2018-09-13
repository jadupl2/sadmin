#! /usr/bin/env sh
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
#                       # $SADMIN/bin/sadm_wrapper.sh "$SADMIN/bin/test.sh"
#
#                   After execution of your script you could check the log generated :
#
#                       # $SADMIN/log/server1_sadm_test.log
#
#                   Also you could see if your script succeeded and see starting, ending 
#                     and execution time 
#
#                       # cat $SADMIN/dat/rch/server1_sadm_test.rch
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
# 2018_01_09 JDuplessis
#    V1.5 New Version - Script Restructure, Usage Instructions & Work with new Library
#
# ==================================================================================================
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi


#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                              ; export DEBUG_LEVEL         # 0=NoDebug Higher=+Verbose
SADM_VER='1.5'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
USAGE="Usage: $SADMIN/bin/sadm_wrapper path-name/script-name ['parameter(s) to your script']"



#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
#===================================================================================================
help()
{
    echo " "
    echo "${SADM_PN} 'name-of-script-to-run' ['parameter(s) to your script'] usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
    echo " "
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
                echo "$USAGE" 
                echo "Job aborted"
                return 1
    fi

    # The script specified must exist in path specified
    if [ ! -e "$SCRIPT" ]
       then     echo "[ERROR] The script $SCRIPT doesn't exist" 
                echo "$USAGE" 
                echo "Job aborted"
                return 1
    fi

    # The Script Name must executable
    if [ ! -x "$SCRIPT" ]
       then     echo "[ERROR] script $SCRIPT is not executable ?" 
                echo "$USAGE" 
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
             echo $USAGE                                                # Show Script Usage
             exit 1                                                     # Exit Script with Error
        else SCRIPT="$1" ; export SCRIPT                                # Script uith pathname
             shift                                                      # Keep only argument(if any)    
             SADM_PN=`basename "$SCRIPT"`                               # Keep Script without Path
             SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`                 # Script name without ext.
             source ${SADMIN}/lib/sadmlib_std.sh                        # Load SADMIN Std Library
             SADM_ALERT_TYPE=1  ; export SADM_ALERT_TYPE                  # 0=No 1=OnErr 2=OnOK  3=All
    fi
    
    check_script                                                        # Validate param. received
    if [ $? -ne 0 ] ; then exit 1 ;fi                                   # Exit if Problem  

    # If normal user can run your script, put the lines below in comment
    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi
    
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    sadm_writelog "  "                                                  # Write white line to log
    sadm_writelog "Executing $SCRIPT $@"                                # Write script name to log
    sadm_writelog "  "                                                  # Write white line to log
    $SCRIPT "$@" >> $SADM_LOG 2>&1                                       # Run selected user script
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
