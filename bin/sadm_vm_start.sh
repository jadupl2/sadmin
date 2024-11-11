#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_start.sh
#   Date        :   2020/07/17
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Script to start one or all the VirtualBox Virtual machines.
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
# 2020_07_17 vmtools v1.0 Initial Version
#@2020_07_23 vmtools v1.1 Remove header, Footer and cleanup code.
#@2020_09_12 vmtools v1.2 Don't start any VM included in the VM Start exclude file.
#@2020_12_12 vmtools v1.3 Change location of the exclude/include vm files.
#@2021_01_25 vmtools v1.4 Startup Exclude list was not working 
#@2024_03_19 vmtools v1.5 New script to start a VirtualBox virtual machine.
#@2024_04_19 vmtools v1.6 Remove 'chmod' of 'vm_start_exclude_list'.
#@2024_11_11 vmtools v1.7 Standardize messages to users
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
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
export SADM_VER='1.7'                                      # Script version number
export SADM_PDESC="Script to start one or all the VirtualBox Virtual machines" 
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
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


  
#===================================================================================================
# Load SADM Virtual Box Library Functions.
#===================================================================================================
. ${SADM_LIB_DIR}/sadmlib_vbox.sh                                       # Load VM functions Tool Lib

export CONFIRM="Y"                                                      # Default Ask Confirmation
export VMNAME="NOVM"                                                    # No VM to Start Default 






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
    printf "\n\t-a   (Start all VMs)"
    printf "\n\t-y   (Don't ask confirmation before starting VMs)"
    printf "\n\t-l   (List status of all VMs)"
    printf "\n\n" 
}





#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    # Make sure that an exclude list file ($START_EXCLUDE_FILE define in sadmlib_vbox.sh)
    # START_EXCLUDE_FILE="$SADM_CFG_DIR/sadm_vm_exclude_start_${SADM_HOSTNAME}.txt" # VM Start Excl.
    #
    # If not, copy exclude template ($START_EXCLUDE_INIT define in sadmlib_vbox.sh) to exclude list.
    # START_EXCLUDE_INIT="$SADM_CFG_DIR/.sadm_vm_exclude_start.txt"     # VM Start Exclude Template
    #
    # If none of these files exist, create an empty exclude list file.
    if [ ! -r "$START_EXCLUDE_FILE" ]                                   # Start Exclude list Exist ?
       then if [ -f "$START_EXCLUDE_INIT" ]                             # Start Exclude Template
               then sadm_write_log "VM start exclude file '$START_EXCLUDE_FILE' not found." 
                    sadm_write_log "Create one from the template file '$START_EXCLUDE_INIT'."
                    sadm_write_log "cp $START_EXCLUDE_INIT $START_EXCLUDE_FILE"
                    cp $START_EXCLUDE_INIT $START_EXCLUDE_FILE          # Template become Excl. List
               else sadm_write_log "VM start exclude file '$START_EXCLUDE_FILE' not found." 
                    sadm_write_log "VM start exclude template file '$START_EXCLUDE_INIT' not found." 
                    sadm_write_log "Create an empty VM start exclude file."
                    touch $START_EXCLUDE_FILE                           # Or Create empty Excl. List
            fi 
    fi 
    #

    # If no VNName is specified (-n), or All VMs is specified (-a).
    if [ "$VMNAME" = "NOVM" ] 
       then sadm_write_err "Please use '-a' (All VMs) or '-n' (Name of VM) to specify VM to start."
            show_usage
            sadm_stop 1
            exit 1
    fi 

    # If Specified to start one VM [-n VMName], check if it's already running.
    if [ "$VMNAME" != "" ] 
       then sadm_vm_exist "$VMNAME" 
            if [ $? -ne 0 ] ; then sadm_write_err "VM '$VMNAME' is not registered."  ;return 1 ;fi 
            sadm_vm_running "$VMNAME"
            if [ $? -eq 0 ] ; then sadm_write_log "VM '$VMNAME' is already running." ;return 0 ;fi 
    fi        

    # Advide user what we will do if confirm.
    if [ "$VMNAME" = "" ]                                               # If Starting ALL VMs
       then sadm_write_log "This will start ALL Virtual Machine(s)."
       else sadm_write_log "This will start '$VMNAME' Virtual Machine."
    fi

    # Ask Confirmation before Starting VM, if [-y] was not use.
    if [ "$CONFIRM" = "Y" ]
       then sadm_ask "Still want to proceed"                            # Wait for user Answer (y/n)
            if [ "$?" -eq 0 ] ; then return 0 ; fi                      # 0=No, Do not proceed
    fi 

    # When VMNAME is blank Start ALL Virtual Machine.
    # If $VMNAME isn't blank, then it contain the name of the vm to start
    scount=0 ; ecount=0                                                 # Started & Error Count = 0
    if [ "$VMNAME" = "" ]                                               # if want to start ALL VM
       then sadm_writelog "Producing list of virtual machines." 
            $VBOXMANAGE list vms | awk -F\" '{ print $2 }' > $VMLIST    # Create a VM list.
            if [ $? -ne 0 ]                                             # If no problem making list
               then sadm_write_err " "
                    sadm_write_err "[ ERROR ] Running '$VBOXMANAGE list vms."
                    sadm_write_err " "
                    return 1
            fi
            for vm in $(cat $VMLIST)                                    # Process each VMs
                 do sadm_write_log " "
                    sadm_write_log "----------"
                    sadm_write_log "Is '$vm' in the startup exclude list ($START_EXCLUDE_FILE)."
                    grep -qi "^$vm" $START_EXCLUDE_FILE                 # VM in the exclude file ?
                    if [ $? -ne 0 ]                                     # If VM not in exclude list
                       then sadm_write_log "The VM $vm is not in the exclude list."
                            sadm_vm_running "$vm"                       # Go Check if VM is running
                            if [ $? -eq 0 ]                             # Yes VM is already running
                                then sadm_write_log "VM '$vm' already running." 
                                     continue                           # Proceed with next VM
                                else sadm_vm_start "$vm"                # Start the VM 
                                     if [ $? -ne 0 ]                    # If error starting VM
                                        then ecount=$(expr $ecount + 1) # Error starting vm count
                                        else scount=$(expr $scount + 1) # VM started VM Count
                                     fi 
                                     sadm_write_log "You asked for an interval of $SADM_VM_START_INTERVAL seconds between VM start." 
                                     sadm_sleep $SADM_VM_START_INTERVAL 15 # Sleep between Start
                            fi
                       else sadm_write_log "[ INFO ] Skipping '$vm' because it's in the exclude list." 
                    fi
                    sadm_write_log " "
                 done
            sadm_write_log " "
            if [ "$ecount" -eq 0 ]
               then sadm_write_log "[ OK ] Started $scount vm(s) successfully."
                    SADM_EXIT_CODE=0
               else sadm_write_log "[ ERROR ] Started $scount vm(s) and $ecount error(s) occurred."
                    SADM_EXIT_CODE=1
            fi 
       else sadm_vm_exist "$VMNAME"                                     # Start One VM
            if [ $? -eq 0 ]                                             # If VM exist ?
                then sadm_vm_running "$VMNAME"                          # Check if VM Running
                     if [ $? -ne 0 ]                                    # Yes VM is Running
                        then sadm_vm_start "$VMNAME"                    # Start the VM
                             if [ $? -eq 0 ] 
                                then sadm_write_log "[ OK ] VM '$VMNAME' started successfully."
                                     SADM_EXIT_CODE=0 
                                else sadm_write_err "[ ERROR ] Couldn't start the VM '$VMNAME´."
                                     SADM_EXIT_CODE=1 
                             fi 
                        else sadm_write_log "[ OK ] VM '$VMNAME' already running."
                             SADM_EXIT_CODE=0                           # Started VM
                     fi           
                else sadm_write_err "[ ERROR ] VM '$VMNAME´ doesn't exist."
                     SADM_EXIT_CODE=1                                   # Return error to caller
            fi 
    fi 
    sadm_list_vm_status                                                 # List All VMs Status
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# [-n VNName] : VMName to Start.
# [-a]        : Start all VMs.
# [-y]        : Don't ask confirmation before starting operation.
# [-l]        : List Status of all VMs.
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    VMNAME="NOVM"                                                       # No VM to Start Default 
    while getopts "d:hvayln:" opt ; do                                  # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=$(echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$) # Valid is Level is Numeric
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
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    