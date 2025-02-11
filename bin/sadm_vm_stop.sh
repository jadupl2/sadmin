#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_stop.sh
#   Date        :   2020/07/18
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Script used to stop one or all the virtualbox vm(s).
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
#@2024_03_19 vmtools v1.5 Script to stop a VirtualBox virtual machine.
#@2024_03_20 vmtools v1.6 Type correction missing double quote ('PDESC').
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
export SADM_VER='1.6'                                      # Script version number
export SADM_PDESC="Script to stop a VirtualBox virtual machine."
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
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
export SADM_MAX_LOGLINE=150                                 # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------



  
#===================================================================================================
# Load SADM Virtual Box Library Functions.
#===================================================================================================
. ${SADM_LIB_DIR}/sadmlib_vbox.sh                                       # Load VM functions Tool Lib

export VMNAME="NOVM"                                                    # No VM to Stop by Default 
export CONFIRM="Y"                                                      # Ask Confirmation (Default)




# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" "$(basename "$0")" "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n   ${BOLD}${YELLOW}[-n VMName]${NORMAL}\t\t(Stop the specified VM name)"
    printf "\n   ${BOLD}${YELLOW}[-a]${NORMAL}\t\t\t(Stop all running VM)"
    printf "\n   ${BOLD}${YELLOW}[-y]${NORMAL}\t\t\t(Don't ask confirmation before starting VMs)"
    printf "\n   ${BOLD}${YELLOW}[-l]${NORMAL}\t\t\t(List status of all VMs)"
    printf "\n\n" 
}
 



#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    # If did not specify cmdline option -a or -n
    if [ "$VMNAME" = "NOVM" ]                       
       then sadm_write_err "[ ERROR ] Use [-a] (All VMs) or [-n VMNAME] to indicate the VM to stop."
            show_usage
            sadm_stop 1
            exit 1
    fi 

    # If specified to stop one VM [-n VMName], check if it's already running.
    if [ "$VMNAME" != "" ]                                              # Is a VMName specified.
       then sadm_vm_exist "$VMNAME"                                     # Check if VM exist
            if [ $? -eq 1 ] 
                then sadm_write_err "'$VMNAME' is not a registered VM." 
                     return 1 
            fi 
            sadm_vm_running "$VMNAME"                                   # Does the VM Running
            if [ $? -eq 1 ] 
                then sadm_write_err "We didn't stop the VM '$VMNAME' since it's already power off." 
                     return 0 
            fi 
    fi        

    if [ "$VMNAME" = "" ] 
       then sadm_write_log "This will stop ALL virtual machine(s)."
       else sadm_write_log "Will stop '$VMNAME' virtual machine."
    fi

    # Ask Confirmation before Starting VM.
    if [ "$CONFIRM" = "Y" ]                                             # if [-y] cmd line used ?
       then sadm_ask "Still want to proceed"                            # Wait for user Answer (y/n)
            if [ "$?" -eq 0 ] ; then return 0 ; fi                      # 0=No, Do not proceed
    fi 

    # When VMNAME is blank Stop ALL Virtual Machine.
    # If $VMNAME isn't blank, then it contain the name of the vm to stop.
    scount=0 ; ecount=0                                                 # Stop and Error Count
    if [ "$VMNAME" = "" ] 
       then sadm_write_log "Producing a list of all running virtual machines." 
            $VBOXMANAGE list runningvms | awk -F\" '{ print $2 }' | sort > $VMRUNLIST
            if [ $? -ne 0 ]                                             # If no problem making list
               then sadm_write_err " "
                    sadm_write_err "[ ERROR ] Running '$VBOXMANAGE list vms."
                    sadm_write_err " "
                    return 1
            fi
            for vm in $(cat $VMRUNLIST) 
                 do 
                 sadm_write_log " "
                 sadm_write_log "----------"
                 sadm_vm_stop "$vm"                                     # Stop the VM 
                 if [ $? -ne 0 ]                                        # If error Stopping VM
                    then ecount=$(expr $ecount + 1)                     # Error Stopping vm count
                    else scount=$(expr $scount + 1)                     # Stopping VM Count
                 fi 
                 done
            sadm_write_log " "
            if [ "$ecount" -eq 0 ]
               then sadm_write_log "[ OK ] Stopped $scount vm(s) successfully."
                    SADM_EXIT_CODE=0
               else sadm_write_log "[ ERROR ] Stopped $scount vm(s) and $ecount error(s) occurred."
                    SADM_EXIT_CODE=1
            fi 
       else sadm_vm_stop "$VMNAME" 
            if [ $? -eq 0 ] 
                then SADM_EXIT_CODE=0 
                     sadm_write_log "[ OK ] VM '$VMNAME' already poweroff."
                else SADM_EXIT_CODE=1 
                     sadm_write_err "[ ERROR ] VM '$VMNAME´ doesn't exist."
            fi 
    fi 
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
    VMNAME=""                                                           # VM name to Backup 
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
            n) VMNAME=$OPTARG                                           # Save VM Name to Stop
               ;;                                                       
            a) VMNAME=""                                                # Stop ALL vm
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
    
