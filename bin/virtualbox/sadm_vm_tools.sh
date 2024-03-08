#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_tools.sh
#   Date        :   2020/07/22
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Command line tools to control the VirtualBox vm(s).
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <jacques.duplessis@sadmin.ca>.
#   Developer Web Site : https://www.sadmin.ca
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
# Version Change Log 
#
# 2020_07_17 New: v1.0 Initial Version
#@2020_10_22 Fix: v1.1 Option -y (No confirmation) was not working.
#@2020_10_23 Fix: v1.2 Option -y (No confirmation) was not working (Typo Error)
#@2021_01_22 Fix: v1.3 Don't wait for a confirmation if option (-l) list is used.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     



#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "\n'SADMIN' Environment variable was temporarily set to ${SADMIN}.\n"
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='1.3'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Write goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="N"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="N"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
    export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
    export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # At the end Trim log to 500 Lines(0=NoTrim)
    #export SADM_MAX_RCLINE=35                          # At the end Trim rch to 35 Lines (0=NoTrim)
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Global Scripts Variables 
#===================================================================================================
export VBOX_HOST="lestrade.maison.ca"                                       # VirtualBox Host Server
export VMUSER="jacques"                                                 # User part of vboxusers
export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List

#
# Default Command Line option variables
export OPT_CONFIRM=true                                                 # No confirmation needed
export OPT_VMNAME=""                                                    # Save VM Name 
export OPT_BACKUP=false                                                 # List VMs Option
export OPT_RUNLIST=false                                                # List Running VMs
export OPT_LIST=false                                                   # List VMs Option
export OPT_START=false                                                  # Start VM Option  
export OPT_STOP=false                                                   # Stop VM Option


# Verify that VBoxManage is available on this system, else abort script.
which VBoxManage >/dev/null 2>&1                                        # VBoxManage on system ?
if [ $? -ne 0 ]                                                         # If not present on system
    then printf "\n${RED}'VBoxManage' is needed and it's not available on this system.${NORMAL}\n" 
         printf "Process aborted.\n\n"                                  # Advise user
         exit 1                                                         # Exit with Error 
    else export VBOXMANAGE=$(which VBoxManage)                          # Path to $VBOXMANAGE
fi 

# Load SADM VirtualBox functions 
export TOOLS_DIR=$(dirname $(realpath "$0"))                            # Dir. Where VM Scripts are
source ${TOOLS_DIR}/sadm_vm_lib.sh                                      # Load VM functions Tool Lib




# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d  Debug Level [0-9]."
    printf "\n\t-h  Display this help message."
    printf "\n\t-v  Show Script Version Info."
    printf "\n\t-l  List Virtual Machines Status."
    printf "\n\t-r  List running virtual machines."
    printf "\n\t-s  Start all virtual machines, unless '-n' is used to specify the vm to start."
    printf "\n\t-e  Stop all virtual machines, unless '-n' is used to specify the vm to stop."
    printf "\n\t-n  Specify Virtual Machines Name to act upon (Backup,Stop,Start)." 
    printf "\n\t-b  Backup all virtual machines, unless '-n' is used to specify the vm to backup"
    printf "\n\t-y  Don't ask confirmation before beginning process."
    printf "\n\n" 
}






#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{

    # List running Virtual Machine (-r, -l assumed)
    if [ "$OPT_RUNLIST" = true ]
        then if [ "$OPT_CONFIRM" = true ]
                then sadm_ask "List running Virtual Machines"           # Wait for user Answer (y/n)
                     if [ "$?" -eq 0 ] ; then return 0 ; fi             # 0=No, Do not proceed
             fi 
             sadm_list_vm_running                                       # List Running VM 
             SADM_EXIT_CODE=$?                                          # Save return code
             return $SADM_EXIT_CODE                                     # Return ErrorCode to Caller
    fi 

    # List VM Status (-l)
    if [ "$OPT_LIST" = true ]                                           # CmdLine Option -l (List)
        then #if [ "$OPT_CONFIRM" = true ]
             #   then sadm_ask "List Virtual Machines status"            # Wait for user Answer (y/n)
             #        if [ "$?" -eq 0 ] ; then return 0 ; fi             # 0=No, Do not proceed
             #fi 
             sadm_list_vm_status                                        # List VM Status
             SADM_EXIT_CODE=$?                                          # Save return code
             return $SADM_EXIT_CODE                                     # Return ErrorCode to Caller
    fi 

    # Start One or All VMs (-s)
    if [ "$OPT_START" = true ]                                          # CmdLine Start VM
        then if [ "$OPT_CONFIRM" = true ]                               # Did ask for a confirmation
                then if [ "$OPT_VMNAME" != "" ]                         # If a VM Name Specified
                        then sadm_ask "Start $OPT_VMNAME Virtual Machine" # Wait user Answer(y/n)
                             if [ "$?" -eq 0 ] ; then return 0 ; fi     # 0=No, Do not proceed
                        else sadm_ask "Start ALL Virtual Machine"       # Wait for user Answer (y/n)   
                             if [ "$?" -eq 0 ] ; then return 0 ; fi     # 0=No, Do not proceed
                     fi 
             fi 
             if [ "$OPT_VMNAME" != "" ]                                 # If a VM Name Specified
                then ${TOOLS_DIR}/sadm_vm_start.sh -yn $OPT_VMNAME      # Stop the VM Specified
                else ${TOOLS_DIR}/sadm_vm_start.sh -ya                  # Stop All VMs
             fi
    fi 

    # Stop One or All VMs (-e) 
    if [ "$OPT_STOP" = true ]                                           # CmdLine Stop VM
        then if [ "$OPT_CONFIRM" = true ]                               # Did ask for a confirmation
                then if [ "$OPT_VMNAME" != "" ]                         # If a VM Name Specified
                        then sadm_ask "Stop $OPT_VMNAME Virtual Machine" # Wait for user Answer(y/n)
                             if [ "$?" -eq 0 ] ; then return 0 ; fi     # 0=No, Do not proceed
                        else sadm_ask "Stop ALL Virtual Machine"        # Wait for user Answer (y/n)   
                             if [ "$?" -eq 0 ] ; then return 0 ; fi     # 0=No, Do not proceed
                     fi 
             fi 
             if [ "$OPT_VMNAME" != "" ]                                 # If a VM Name Specified
                then ${TOOLS_DIR}/sadm_vm_stop.sh -yn $OPT_VMNAME       # Stop the VM Specified
                else ${TOOLS_DIR}/sadm_vm_stop.sh -ya                   # Stop All VMs
             fi
    fi 

    # Backup One or All VMs (-b)
    if [ "$OPT_BACKUP" = true ]                                         # CmdLine Backup VM Switch
        then if [ "$OPT_CONFIRM" = true ]                               # Did ask for a confirmation
                then if [ "$OPT_VMNAME" != "" ]                         # If a VM Name Specified
                        then sadm_ask "Backup $OPT_VMNAME Virtual Machine" # Wait user Answer(y/n)
                             if [ "$?" -eq 0 ] ; then return 0 ; fi     # 0=No, Do not proceed
                        else sadm_ask "Backup ALL Virtual Machine"      # Wait for user Answer (y/n)   
                             if [ "$?" -eq 0 ] ; then return 0 ; fi     # 0=No, Do not proceed
                     fi 
             fi 
             if [ "$OPT_VMNAME" != "" ]                                 # If a VM Name Specified
                then ${TOOLS_DIR}/sadm_vm_backup.sh -yn $OPT_VMNAME     # Stop the VM Specified
                else ${TOOLS_DIR}/sadm_vm_backup.sh -ya                 # Stop All VMs
             fi
    fi 

    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# Command line options : -d [0-9] -h -v 
#     -d   (Debug Level [0-9])"
#     -h   (Display this help message)"
#     -v   (Show Script Version Info)"
#     -l   (List Virtual Machines Status)"
#     -r   (List running virtual machines)"
#     -s   (Start One (-n) or All Virtual machines)"
#     -e   (Stop (End) One (-n) or All Virtual Machines)" 
#     -n   (Specify the Virtual Machines Name to act upon (backup,Stop,Start))" 
#     -y   (Don't ask confirmation before backing up VMs)"
#     -b   (Backup one (-n) or All Virtual machines)"
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hvlresybn:" opt ; do                               # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}."               # Display Debug Level
               ;;                                                       
            y) OPT_CONFIRM=false                                        # No confirmation needed
               ;;                                                                      
            n) OPT_VMNAME=$OPTARG                                       # Save VM Name 
               ;;                                                       
            l) OPT_LIST=true                                            # List VMs Option
               ;;                                                       
            b) OPT_BACKUP=true                                          # List VMs Option
               ;;                                                       
            r) OPT_RUNLIST=true                                         # List Running VMs 
               OPT_LIST=true                                            # List VMs Option
               ;;                                                       
            s) OPT_START=true                                           # Start VM Option  
               ;;                                                       
            e) OPT_STOP=true                                            # Stop VM Option
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: ${OPTARG}\n"                   # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



#===================================================================================================
# MAIN CODE START HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If current user is not the VM Owner, exit to O/S with error code 1
    if [ "$(whoami)" != "$VMUSER" ]                                     # If user is not a vbox user 
        then sadm_write "Script can only be run by '$VMUSER' user, not '$(whoami)', process aborted.\n"
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # If we are not on the VirtualBox Server, exit to O/S with error code 1
    if [ "$(sadm_get_fqdn)" != "$VBOX_HOST" ]                           # Run only VirtualBox Server 
        then sadm_write "Script can only be run on (${VBOX_HOST}), process aborted.\n"
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
