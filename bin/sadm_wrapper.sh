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
# 2018_01_09 V1.5 New Version - Script Restructure, Usage Instructions & Work with new Library
# 2018_09_19 V1.6 Update for Alert Group and new LIbrary
#
# ==================================================================================================
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x

#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    if [ -z "$SADMIN" ]                                 # Test If SADMIN Environment Var. is present
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN Shell Library not readable ?
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # You can use variable below BUT DON'T CHANGE THEM - They are used by SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name with Domain Name

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.6'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#---------------------------------------------------------------------------------------------------
# Value for these variables are taken from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# But they can be overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                  # AlertGroup Used for Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # At end of script Trim log to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage:\n${SADM_PN} 'name-of-script-to-run' ['parameter(s) to your script']"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
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
       then     echo "[ERROR] The script $SCRIPT doesn't exist" 
                show_usage 
                echo "Job aborted"
                return 1
    fi

    # The Script Name must executable
    if [ ! -x "$SCRIPT" ]
       then     echo "[ERROR] script $SCRIPT is not executable ?" 
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
        else SCRIPT="$1" ; export SCRIPT                                # Script uith pathname
             shift                                                      # Keep only argument(if any)    
             SADM_PN=`basename "$SCRIPT"`                               # Keep Script without Path
             SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`                 # Script name without ext.
             source ${SADMIN}/lib/sadmlib_std.sh                        # Load SADMIN Std Library
             SADM_ALERT_TYPE=1           ; export SADM_ALERT_TYPE       # 0=No 1=OnErr 2=OnOK  3=All
             SADM_ALERT_GROUP='default'  ; export SADM_ALERT_GROUP      # Alert Group to Alert
    fi
    
    check_script                                                        # Validate param. received
    if [ $? -ne 0 ] ; then exit 1 ;fi                                   # Exit if Problem  
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    # If normal user can run your script, put the lines below in comment
    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi
    sadm_writelog "  "                                                  # Write white line to log
    sadm_writelog "Executing $SCRIPT $@"                                # Write script name to log
    sadm_writelog "  "                                                  # Write white line to log
    $SCRIPT "$@" >> $SADM_LOG 2>&1                                      # Run selected user script
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
