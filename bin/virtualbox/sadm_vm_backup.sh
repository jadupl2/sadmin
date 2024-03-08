#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_backup.sh
#   Date        :   2020/07/19
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Script used to backup one or all the virtualbox vm(s) onto the NAS Server.
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
# 2020_07_19 New: v1.0 Initial Version
#@2020_07_22 Update: v1.1 Change Backup Directory on NAS
#@2020_07_24 Update: v1.2 Good working version
#@2020_12_12 Fix: v1.3 Fix location of vm exclude files.
#@2021_02_13 Update: v1.4 Don't list VM prior to backup, Set $SA if not done.
#@2021_03_17 Update: v1.5 Add 4 Min. (Sleep) to Start System & App. after starting VM after backup 
#@2021_03_21 Update: v1.6 Startup wait time code missing when starting 1 vm only.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     

#===================================================================================================
# SADMIN SECTION v1.5 - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # If SADMIN EnvVar not right
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null          # SADMIN in /etc/environment
         if [ $? -eq 0 ]                                                # Found SADMIN in /etc/env..
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                 # Current Script filename(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`       # Current Script filename(without extension)
export SADM_TPID="$$"                                   # Current Script Process ID.
export SADM_HOSTNAME=`hostname -s`                      # Current Host name without Domain Name
export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Std Library).
export SADM_VER='1.6'                                   # Current Script Version
export SADM_EXIT_CODE=0                                 # Current Script Default Exit Return Code
export SADM_LOG_TYPE="B"                                # Write log to [S]creen [L]ogFile [B]oth
export SADM_LOG_APPEND="Y"                              # [Y]=Append Existing Log [N]=Create New Log
export SADM_LOG_HEADER="Y"                              # [Y]=Include Log Header  [N]=No log Header
export SADM_LOG_FOOTER="Y"                              # [Y]=Include Log Footer  [N]=No log Footer
export SADM_MULTIPLE_EXEC="Y"                           # Allow running multiple copy at same time ?
export SADM_PID_TIMEOUT=7200                            # Nb Sec PID file can block script execution
export SADM_LOCK_TIMEOUT=3600                           # Nb Sec before System Lock File get deleted
export SADM_USE_RCH="Y"                                 # Update HistoryFile [R]esult[C]ode[H]istory 
export SADM_DEBUG=0                                     # Debug Level - 0=NoDebug Higher=+Verbose
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$" # Temp File Name 1 available for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$" # Temp File Name 2 available for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$" # Temp File Name 3 available for you to use

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                          # LOAD SADMIN Standard Shell Libr. Functions
export SADM_OS_NAME=$(sadm_get_osname)                  # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
export SADM_OS_VERSION=$(sadm_get_osversion)            # O/S Full Version Number  (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)      # O/S Major Version Number (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/CFG/SADMIN.CFG FILE).
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
export SADM_ALERT_TYPE=3                               # 0=None 1=AlertOnError 2=AlertOnOK 3=Always
#export SADM_ALERT_GROUP="default"                      # Alert Group to advise (alert_group.cfg)
#export SADM_MAIL_ADDR="your_email@domain.com"          # Email to send log (Override sadmin.cfg)
#export SADM_MAX_LOGLINE=500                            # At the end Trim log to 500 Lines(0=NoTrim)
#export SADM_MAX_RCLINE=35                              # At the end Trim rch to 35 Lines (0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Global Scripts Variables 
#===================================================================================================
export VBOX_HOST="lestrade.maison.ca"                                       # VirtualBox Host Server
export VMUSER="jacques"                                                 # User part of vboxusers
export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List
export VM_INITIAL_STATE=0                                               # 0=OFF 1=ON 
export CONFIRM="Y"                                                      # Default Ask Confirmation
export VMNAME="NOVM"                                                    # No VM to Start Default 
export STOP_TIMEOUT=120                                                 # acpipowerbutton wait sec
export STARTUP_TIME=480                                                 # Sec given for Startup App.
#
if [ ! -v "$SA" ] || [ "$SA" = "" ] ; then export SA="/opt/sa" ; fi     # Default If $SA Not set
export BACKUP_EXCLUDE_FILE="$SA/cfg/sadm_vm_exclude_backup_${SADM_HOSTNAME}.txt" # Host Backup Excl.
export BACKUP_EXCLUDE_INIT="$SA/cfg/.sadm_vm_exclude_backup.txt"        # VM Backup Exclude Template
# 
# Verify that VBoxManage is available on this system, else abort script.
which VBoxManage >/dev/null 2>&1                                        # VBoxManage on system ?
if [ $? -ne 0 ]                                                         # If not present on system
    then printf "\n${RED}'VBoxManage' is needed and it's not available on this system.${NORMAL}\n" 
         printf "Process aborted.\n\n"                                  # Advise user
         exit 1                                                         # Exit with Error 
    else export VBOXMANAGE=$(which VBoxManage)                          # Path to $VBOXMANAGE
fi 

# Load SADM VirtualBox Library functions 
export TOOLS_DIR=$(dirname $(realpath "$0"))                            # Dir. Where VM Scripts are
source ${TOOLS_DIR}/sadm_vm_lib.sh                                      # Load VM functions Tool Lib

export VBOX_HOST="lestrade.maison.ca"                                       # VirtualBox Host Server
export NAS_SERVER="batnas.maison.ca"                                    # Backup Server HostName
export NAS_DIR="/volume1/backup_vm/virtualbox/vbox_server"              # Backup VM Dir. on NAS 
export NFS_DIR="${SADMIN}/tmp/vm_backup_tmp_$$"                               # NFS Mount Tmp Dir.



# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\t-n   (Backup the specified VM name)"
    printf "\n\t-a   (Backup ALL )"
    printf "\n\t-y   (Don't ask confirmation before backing up VMs)"
    printf "\n\t-l   (List status of all VMs)"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
# Ping Backup server receive as $1 - If it failed abort script with error.
# --------------------------------------------------------------------------------------------------
ping_nas_server()
{
    WSERVER=$1
    sadm_write_log "ping -c 2 ${WSERVER} " 
    ping -c 2 -W 2 $WSERVER >/dev/null 2>/dev/null                      # Ping the Server
    RC=$?                                                               # Save Return Code
    if [ $RC -ne 0 ] 
        then sadm_write_err "[ ERROR ] Can't ping the backup server ${WSERVER}"
             sadm_write_err "Can't proceed, aborting script."
             RC=1           _log                                            # Make sure RC is 1 or 0 
        else sadm_write_log "${SADM_OK}\n"
             RC=0
    fi
    return $RC
}




#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    # Make sure that an exclude list exist ($BACKUP_EXCLUDE_FILE)
    #   - If not copy exclude template ($BACKUP_EXCLUDE_INIT) as an initial exclude file.
    #   - If none of these files exist, create an empty backup exclude list file.
    if [ ! -r "$BACKUP_EXCLUDE_FILE" ]                                  # Backup Excl. Not Exist 
       then if [ -f "$BACKUP_EXCLUDE_INIT" ]                            # Backup Excl. Default Exist
               then sadm_write "Create initial VM backup exclude file '$BACKUP_EXCLUDE_FILE'.\n" 
                    cp $BACKUP_EXCLUDE_INIT $BACKUP_EXCLUDE_FILE        # Put Def. Excl. in place
               else sadm_write "Creating empty VM backup exclude file.\n"
                    touch $BACKUP_EXCLUDE_FILE                          # Create empty Excl. List
            fi 
    fi 

    # User MUST specify at least the '-a' or '-n' options, else we return Error code to caller.
    if [ "$VMNAME" = "NOVM" ]                                           # Must use -a or -n 
       then sadm_write "Please use '-a' (All VMs) or '-n' (Name of VM).\n"
            show_usage                                                  # Show Help Usage
            return 1                                                    # Return Error to Caller
    fi 

    # If Specified to backup one VM, Check if the VM exist
    if [ "$VMNAME" != "" ] 
       then sadm_vm_exist "$VMNAME"                                     # Check if VM Exist
            if [ $? -ne 0 ]                                             # If don't exist
                then sadm_write "${SADM_ERROR} '$VMNAME' is not a registered VM.\n" 
                     return 1                                           # Return Error to Caller
            fi 
    fi        

    # Show Backup Option chosen by user.
    if [ "$VMNAME" = "" ] 
       then TITLE="${SADM_BOLD}${SADM_YELLOW}Backup ALL Virtual Machine(s).${SADM_RESET}"
       else TITLE="${SADM_BOLD}${SADM_YELLOW}Backup '$VMNAME' Virtual Machine.${SADM_RESET}"
    fi
    sadm_write "${TITLE}\n"                                             # Show Backup Chosen

    # Ask Confirmation before Starting VM.
    if [ "$CONFIRM" = "Y" ]                                             # If Want User Confirmation
       then sadm_ask "Still want to proceed"                            # Wait for user Answer (y/n)
            if [ $? -eq 0 ] ; then return 0 ; fi                        # 0=No, Do not proceed
    fi 

    # NAS Server is available ?
    ping_nas_server "$NAS_SERVER"                                       # NAS Server Alive ?
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Return Error to caller

    # If chosen to backup one Virtual machine ($VMNAME not empty).
    #sadm_list_vm_status                                                 # List Status of ALL VMs
    bcount=0 ; ecount=0                                                 # Backup & Error Count Reset
    if [ "$VMNAME" != "" ]                                              # Name of VM To Backup Spec. 
       then sadm_vm_running "$VMNAME"                                   # Check if it is running
            if [ $? -eq 0 ]                                             # If it's still running
                then sadm_writelog "The Virtual machine is currently running."
                     VM_STATE="RUNNING"                                 # Save VM Init State Running
                     sadm_vm_stop "$VMNAME"                             # Then Stop it
                     if [ $? -ne 0 ] ; then return 1 ; fi               # Error if can't stop it 
                else sadm_writelog "The Virtual machine is currently power off."
                     VM_STATE="POWEROFF"                                # Save VM InitState PowerOFF
            fi 
            sadm_backup_vm "$VMNAME"                                     # Then Backup VM
            if [ $? -eq 0 ] ; then SADM_EXIT_CODE=0 ; else SADM_EXIT_CODE=1 ; fi 
            if [ "$VM_STATE" = "RUNNING" ]                              # Running Initially ?
               then sadm_vm_start "$VMNAME"                             # Yes, then Restart the VM
                    if [ $? -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi        # Error Ocurred Set ExitCode
                    sadm_writelog "Sleep $STARTUP_TIME sec. - Give time to become available."
                    sadm_sleep $STARTUP_TIME 30
            fi             
            sadm_list_vm_status                                         # List Status of ALL VMs
            return $SADM_EXIT_CODE
    fi 


    # User Choose to Backup ALL Virtual Machine ($VM is empty) - Produce a list of ALL VMs.
    sadm_write "Producing a list of all virtual machines."              # Starting Backup Process
    $VBOXMANAGE list vms | awk -F\" '{ print $2 }' | sort > $VMLIST     # Create List of All VMs
    if [ $? -ne 0 ]                                                     # Error when creating list
       then sadm_write "${SADM_ERROR} Running '$VBOXMANAGE list vms.\n" # Advise User
            sadm_write "Backup can't be done, process aborted.\n"       # Backup Aborted
            return 1                                                    # Return Error to Caller
       else sadm_write "${SADM_OK}\n"                                   # Inform user it went ok
    fi 

    # Process every servers present in the list of VMs ($VMLIST).
    bcount=0 ; ecount=0                                                 # Started, Error Count Reset
    while read vm                                                       # For each VM in the List
        do grep -qi "^${vm}$" $BACKUP_EXCLUDE_FILE                      # VM in the exclude file ?
           if [ $? -eq 0 ]                                              # If VM IS in exclude list
               then sadm_write "${SADM_WARNING} Skipping '$vm' because it's in the exclude file." 
                    continue                                            # Continue with next VM
           fi 
           # Stop the VM if it's running
           sadm_vm_running "$vm"                                        # Go Check if VM is running
           if [ $? -eq 0 ]                                              # If it's still running
               then VM_STATE="RUNNING"                                  # Save VM Init State Running
                    sadm_vm_stop "$vm"                                  # Then Stop it
                    if [ $? -ne 0 ]                                     # If Error stopping the VM
                       then sadm_write "${SADM_ERROR} Unable to stop '$VM', continue with next VM."
                            ecount=$(( $ecount + 1 ))                   # Incr. Error Counter
                            continue                                    # Continue with next VM
                    fi 
               else VM_STATE="POWEROFF"                                 # Save VM Init State PowerOFF
           fi
           # Backup the VM
           sadm_backup_vm "$vm"                                         # Backup VM
           if [ $? -eq 0 ]                                              # If Backup Went OK
              then bcount=$(( $bcount + 1 ))                            # Incr. Backup OK Counter
              else ecount=$(( $ecount + 1 ))                            # Incr. Error Counter
           fi 
           # Restart the VM, if it was running before the backup.
           if [ "$VM_STATE" = "RUNNING" ]                               # VM was Running Initially ?
              then sadm_vm_start "$vm"                                  # Yes, then Restart the VM
                   if [ $? -ne 0 ]                                      # If Error starting VM
                      then ecount=`expr $ecount + 1`                    # Incr. Error Counter
                   fi       
                   sadm_writelog "Sleep $STARTUP_TIME sec. - Give time to become available."
                   sadm_sleep $STARTUP_TIME 30
           fi             
        done < $VMLIST

    # After finishing taking the backup of ALL VMs.
    sadm_writelog " "; sadm_writelog "$SADM_80_DASH" ; sadm_writelog " "
    if [ "$ecount" -eq 0 ]                                              # If Error count at zero
       then sadm_write "$bcount VirtualBox machines were backup successfully.\n" # User Summary
            SADM_EXIT_CODE=0                                            # Global Exit Code is Good
       else sadm_write "Encountered $ecount errors and backup $bcount VirtualBox machines.\n"
            SADM_EXIT_CODE=1                                            # Global Exit Code Error 
    fi 

    sleep 4                                                             # Time For last VM to Start
    sadm_list_vm_status                                                 # List Status of ALL VMs
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
               SADM_LOG_FOOTER="N"                                      # No footer with this option
               sadm_stop 0                                              # Update RCH, Close Logs,...
               exit 0                                                   # Backup to the O/S
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
    