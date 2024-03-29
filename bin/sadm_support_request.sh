#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_support_request.sh
#   Synopsis    :   Create a log file used to submit problem.
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
# 2019_12_02 Updated: V2.2 Add execution of sadm_check_requirenent.
#
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
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
    export SADM_VER='2.2'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#---------------------------------------------------------------------------------------------------
# Value for these variables are taken from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# But they can be overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                  # AlertGroup Used for Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    export SADM_MAX_LOGLINE=5000                       # At end of script Trim log to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Scripts Variables 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}





#===================================================================================================
#                              Print File received as parameter
#===================================================================================================
print_file()
{
    wfile=$1                                                            # Save FileName to Print
    echo " " >> $SADM_LOG                                               # Insert Blank Line in Log
    
    if [ -r $wfile ]                                                    # If File is Readable
       then echo "Adding $wfile to support request log ..."
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            echo "Content of $wfile"    >> $SADM_LOG
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            grep -Ev "^#|^[[:space:]]*$" $wfile >> $SADM_LOG
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
            return 0                                                    # Return No Error to Caller
       else echo " "                    >> $SADM_LOG                    # Insert Blank Line
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            echo "Could not print, file not found : $wfile" >> $SADM_LOG
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
    fi
    return 1
}


#===================================================================================================
#                  Run the script received if parameter (Return 0=Success 1= Error)
#===================================================================================================
run_command()
{
    SCRIPT=$1                                                           # Shell Script Name to Run
    CMDLOG=$2                                                           # Log Generated by Script
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${SCRIPT}"                                    # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                             # If SCript do not exist
        then sadm_write "[ERROR] ${SADM_BIN_DIR}/${SCRIPT} Don't exist or can't execute\n\n" 
             return 1                                                   # Return Error to Callerr
    fi 

    sadm_write "Running $SCMD ...\n"                                    # Show Command about to run
    $SCMD >${CMDLOG} 2>&1                                               # Run Script Collect output
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_write "[ERROR] $SCRIPT Terminate with Error\n"        # Signal Error in Log
             sadm_write "Check Log for further detail about Error\n"    # Show user where to look
             sadm_write "${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log\n" # Show Log Name    
             return 1                                                   # Return Error to Callerr
        else sadm_write "[SUCCESS] Script $SCRIPT terminated.\n"        # Advise user it's OK
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
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]                          # If Running on SADM Server
        then print_file "/etc/cron.d/sadm_server"
             print_file "/etc/cron.d/sadm_osupdate"
             print_file "/etc/cron.d/sadm_backup"
             print_file "/etc/cron.d/sadm_rear_backup"
    fi    
    print_file "/etc/selinux/config"
    print_file "/etc/postfix/main.cf"
    print_file "/etc/hosts"
    #print_file "${SADM_DR_DIR}/${SADM_HOSTNAME}_system.txt"
    print_file "${SADM_DR_DIR}/${SADM_HOSTNAME}_sysinfo.txt"
    print_file "/etc/httpd/conf.d/sadmin.conf"

    # Copy the setup log (if exist) to SADMIN normal log directory,
    if [ -f "$SADM_SETUP_DIR/log/sadm_setup.log" ] 
        then cp $SADM_SETUP_DIR/log/sadm_setup.log $SADM_LOG_DIR >/dev/null 2>&1
    fi 

    # Run the Shell Library Demo 
    sadm_write "\n"                                                     # Blank LIne
    CMD="sadmlib_std_demo"                                              # Script Name to execute
    CMDLOG="${SADM_TMP_DIR}/${SADM_HOSTNAME}_${CMD}.log"                # Script Log file Name
    run_command "${CMD}.sh" "$CMDLOG"                                   # Run Shell Library Demo
    print_file "${CMDLOG}"                                              # Print log 
    if [ -r "${CMDLOG}" ] ; then rm -f ${CMDLOG} >/dev/null 2>&1 ; fi   # Remove log

    # Run the Python Library Demo 
    sadm_write "\n"                                                     # Blank LIne
    CMD="sadmlib_std_demo"                                              # Script Name to execute
    CMDLOG="${SADM_TMP_DIR}/${SADM_HOSTNAME}_${CMD}.log"                # Script Log file Name
    run_command "${CMD}.py" "$CMDLOG"                                   # Run Python Library Demo
    print_file "${CMDLOG}"                                              # Print tmp log 
    if [ -r "${CMDLOG}" ] ; then rm -f ${CMDLOG} >/dev/null 2>&1 ; fi   # Remove tmp log

    # Run the check requirement script.
    sadm_write "\n"                                                     # Blank LIne
    CMD="sadm_requirements.sh"                                          # Script Name to execute
    CMDLOG="${SADM_TMP_DIR}/${SADM_HOSTNAME}_${CMD}.log"                # Script Log file Name
    run_command "${CMD}" "$CMDLOG"                                      # Run Check Requirement
    print_file "${CMDLOG}"                                              # Print tmp log 
    if [ -r "${CMDLOG}" ] ; then rm -f ${CMDLOG} >/dev/null 2>&1 ; fi   # Remove tmp log

    # Include result of command "chage -l $SADM_USER", to see if password is expire
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # If Current O/S is Linux 
        then CMD="chage -l $SADM_USER"                                  # Command Name to execute
             CMDLOG="${SADM_TMP_DIR}/${SADM_HOSTNAME}_chage.log"        # Command Log file Name
             sadm_write "\nRunning $CMD ...\n"                          # Show Command about to run
             $CMD > $CMDLOG                                             # Exec Command
             print_file "${CMDLOG}"                                     # Print tmp log 
             if [ -r "${CMDLOG}" ] ; then rm -f ${CMDLOG} >/dev/null 2>&1 ; fi   # Remove log
    fi

    # Create file with SADMIN tree in it
    which tree >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then TLOG="${SADM_LOG_DIR}/${SADM_HOSTNAME}_sadm_support_tree.log"
             sadm_write "Recording $SADMIN tree structure list in $TLOG ...\n"
             tree > $TLOG
    fi
    
    # List of files in SADMIN
    LLOG="$SADM_LOG_DIR/${SADM_HOSTNAME}_sadm_support_files_list.log" 
    sadm_write "Creating a listing of all files in $SADMIN to $LLOG ...\n"
    find $SADMIN -ls > $LLOG

    return 0
}

#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    # Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    # Evaluate Command Line Switch Options Upfront
    # By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $SADM_DEBUG -gt 0 ] ; then printf "\nDebug activated, Level ${SADM_DEBUG}\n" ; fi


    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

    # SADMIN Closing procedure - Close/Trim log and rch file, Remove PID File, Remove TMP files ...
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID

    # Compress Support File
    BACDIR=`pwd`
    SRQ_FILE="${SADM_TMP_DIR}/${SADM_HOSTNAME}_${SADM_INST}.tgz"
    cd $SADM_BASE_DIR
    if [ $SADM_DEBUG -gt 0 ] 
        then echo "tar -cvzf ${SADM_TMP_DIR}/${SADM_INST}.tgz ${SADM_LOG}"
    fi
    tar -cvzf $SRQ_FILE log >/dev/null 2>&1
    echo "Please send the file '$SRQ_FILE' to sadmlinux@gmail.com."
    echo "We will get back to you as soon as possible."
    echo " "                                                            # Insert Blank Line
    cd $BACDIR

    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
