#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_start.sh
#   Date        :   2020/07/17
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Script used to start one or all the virtualbox vm(s).
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
#@2020_07_23 Update: v1.1 Remove header, Footer and cleanup code.
#@2020_09_12 Update: v1.2 Don't start any VM included in the VM Start exclude file.
#@2020_12_12 Fix: v1.3 Change location of the exclude/include vm files.
#@2021_01_25 Fix: v1.4 Startup Exclude list was not working 
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
    export SADM_VER='1.4'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writ#set -x
    export SADM_LOG_APPEND="Y"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
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
export CONFIRM="Y"                                                      # Default Ask Confirmation
export VMNAME="NOVM"                                                    # No VM to Start Default 
export STOP_TIMEOUT=120                                                 # acpipowerbutton wait sec
export START_INTERVAL=120                                               # Sleep time between StartVM
#
export START_EXCLUDE_FILE="$SA/cfg/sadm_vm_exclude_start_${SADM_HOSTNAME}.txt" # VM Start Excl. File
export START_EXCLUDE_INIT="$SA/cfg/.sadm_vm_exclude_start.txt"          # VM Start Exclude Template
# 
# Verify that VBoxManage is available on this system, else abort script.
which VBoxManage >/dev/null 2>&1                                        # VBoxManage on system ?
if [ $? -ne 0 ]                                                         # If not present on system
    then printf "\n${RED}'VBoxManage' is needed and it's not available on this system.${NORMAL}\n" 
         printf "Process aborted.\n\n"                                  # Advise user
         exit 1                                                         # Exit with Error 
    else export VBOXMANAGE=$(which VBoxManage)                          # Path to $VBOXMANAGE
fi 

#source ${SADM_ULIB_DIR}/sadmlib_vbox.sh 


# Load SADM VirtualBox functions 
export TOOLS_DIR=$(dirname $(realpath "$0"))                            # Dir. Where VM Scripts are
source ${TOOLS_DIR}/sadm_vm_lib.sh                                      # Load VM functions Tool Lib



# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\t-n   (Start the specified VM name)"
    printf "\n\t-a   (Start all Power off VM)"
    printf "\n\t-y   (Don't ask confirmation before starting VMs)"
    printf "\n\t-l   (List status of all VMs)"
    printf "\n\n" 
}





#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    # Make sure that an exclude list file ($START_EXCLUDE_FILE) exist.
    # If not copy exclude list template ($START_EXCLUDE_INIT) to exclude list.
    # If none of these files exist, create an empty exclude list file.
    if [ ! -r "$START_EXCLUDE_FILE" ]                                   # Start Exclude list Exist ?
       then if [ -f "$START_EXCLUDE_INIT" ]                             # Start Exclude Template
               then sadm_write "Create initial VM start exclude file ($START_EXCLUDE_FILE).\n" 
                    cp $START_EXCLUDE_INIT $START_EXCLUDE_FILE          # Template become Excl. List
               else sadm_write "Create an empty VM start exclude file.\n"
                    touch $START_EXCLUDE_FILE                           # Or Create empty Excl. List
            fi 
    fi 
    #chmod 664 $START_EXCLUDE_FILE                                       # Set perm, on exclude list

    if [ "$VMNAME" = "NOVM" ] 
       then printf "\nPlease use '-a' (All VMs) or '-n' (Name of VM) to indicate the VM to Start.\n"
            show_usage
            sadm_stop 1
            exit 1
    fi 

    # If Specified to start one VM, check if it's already running.
    if [ "$VMNAME" != "" ] 
       then sadm_vm_exist "$VMNAME" 
            if [ $? -ne 0 ] ; then sadm_write "'$VMNAME' is not a registered VM.\n" ;return 1 ;fi 
            sadm_vm_running "$VMNAME"
            if [ $? -eq 0 ] ; then sadm_write "VM '$VMNAME' is already running.\n" ;return 0 ;fi 
    fi        

    scount=0 ; ecount=0                                                 # Started, Error Count Reset
    if [ "$VMNAME" = "" ] 
       then sadm_write "${SADM_BOLD}${SADM_YELLOW}Will start ALL Virtual Machine(s).${SADM_RESET}\n"
       else sadm_write "${SADM_BOLD}${SADM_YELLOW}Will start '$VMNAME' Virtual Machine.${SADM_RESET}\n"
    fi

    # Ask Confirmation before Starting VM.
    if [ "$CONFIRM" = "Y" ]
       then sadm_ask "Still want to proceed"                            # Wait for user Answer (y/n)
            if [ "$?" -eq 0 ] ; then return 0 ; fi                      # 0=No, Do not proceed
    fi 

    # When VMNAME is blank Start ALL Virtual Machine.
    # If $VMNAME isn't blank, than it contain the name of the vm to start
    #sadm_write "\n" 
    if [ "$VMNAME" = "" ] 
       then sadm_writelog "Producing a list of virtual machines." 
            $VBOXMANAGE list vms | awk -F\" '{ print $2 }' > $VMLIST
            if [ $? -ne 0 ] 
               then sadm_write "${SADM_ERROR} Running '$VBOXMANAGE list vms.\n"
                    sadm_write "Backup can't be done, process aborted.\n" 
                    return 1
            fi
            for vm in $(cat $VMLIST) 
                 do sadm_writelog " "
                    sadm_writelog "----------"
                    sadm_writelog "Is $vm in the startup exclude list ($START_EXCLUDE_FILE)."
                    grep -qi "^$vm" $START_EXCLUDE_FILE                 # VM in the exclude file ?
                    if [ $? -ne 0 ]                                     # If VM not in exclude list
                       then sadm_writelog "The VM $vm is not in the exclude list."
                            sadm_vm_running "$vm"                       # Go Check if VM is running
                            if [ $? -eq 0 ]                             # Yes VM is already running
                                then sadm_writelog "The VM '$vm' is already running." 
                                     continue                           # Proceed with next VM
                                else sadm_vm_start "$vm"                # Start the VM 
                                     if [ $? -ne 0 ]                    # If error starting VM
                                        then ecount=`expr $ecount + 1`  # Error Starting vm count
                                        else scount=`expr $scount + 1`  # Started VM Count
                                     fi 
                                     sadm_writelog "Let's give $START_INTERVAL seconds for the VM to start."
                                     sadm_sleep $START_INTERVAL 15      # Sleep time between Start
                            fi
                       else sadm_writelog "${SADM_WARNING} Skipping '$vm' because it's in the exclude list." 
                    fi
                    sadm_writelog " "
                 done
                 sadm_write "\n"
                 if [ "$ecount" -eq 0 ]
                    then sadm_write "Started $scount vm(s) successfully.\n"
                         SADM_EXIT_CODE=0
                    else sadm_write "Encountered $ecount errors and started $scount vm(s).\n"
                         SADM_EXIT_CODE=1
                 fi 
       else sadm_vm_exist "$VMNAME"  
            if [ $? -eq 0 ] 
                then sadm_vm_running "$VMNAME" 
                     if [ $? -ne 0 ] 
                        then sadm_vm_start "$VMNAME" 
                             if [ $? -eq 0 ] ; then SADM_EXIT_CODE=0 ; else SADM_EXIT_CODE=1 ; fi 
                        else SADM_EXIT_CODE=0   
                     fi           
                else SADM_EXIT_CODE=1
            fi 
    fi 

    sleep 4
    sadm_list_vm_status
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    VMNAME="NOVM"                                                       # No VM to Start Default 
    while getopts "d:hvayln:" opt ; do                                  # Loop to process Switch
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
            n) VMNAME=$OPTARG                                           # Save VM Name to Start
               ;;                                                       
            a) VMNAME=""                                                # Start ALL vm
               ;;                                                       
            y) CONFIRM="N"                                              # No confirmation needed
               ;;                                                       
            l) sadm_list_vm_status                                      # List VM Status
               sadm_stop 0
               exit 0
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
    
