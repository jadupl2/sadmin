#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_export.sh
#   Date        :   2020/07/19
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Script used to export one of the virtualbox vm to NAS Server.
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
#@2023_01_06 vmtools v1.7 fix bug when exporting multiple vm
#@2023_02_13 vmtools v1.8 Insert $VMNAME in the rch and log file name, instead of all in 1 file.
#@2023_06_13 vmtools v1.9 Move setting of VMName at the beginning of the script
#@2023_10_31 vmtools v2.0 Adaptation to use the VMTools configuration file (vmtools.cfg).
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x


# --------------------------------- VirtualBox Common Section  -------------------------------------

# Script accept only one parameter, it's the name of the VM you want to export.
if [ $# -eq 1 ] 
    then export VMNAME=$1                                               # Save VM Name to export
    else printf "\n[ ERROR ] You must specify the name of the VM to export.\n\n"
         show_usage
         exit 1 
fi

# Verify that VBoxManage is available on this system, else abort script.
which VBoxManage >/dev/null 2>&1                                        # VBoxManage on system ?
if [ $? -ne 0 ]                                                         # If not present on system
    then printf "\n${RED}'VBoxManage' command is not available on this system.${NORMAL}\n" 
         printf "Process aborted.\n\n"                                  # Advise user
         exit 1                                                         # Exit with Error 
    else export VBOXMANAGE=$(which VBoxManage)                          # Path to $VBOXMANAGE
fi 





# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
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

# ---

# SPECIAL DEROGATION TO INSERT THE EXPORTED VM NAME IN THE FILENAME OF THE LOG AND RCH FILE.
export SADM_INST="${SADM_INST}_${VMNAME}"                  # Insert VMName to export in rch & log
export SADM_EXT=$(echo "$SADM_PN" | cut -d'.' -f2)         # Save Script extension (sh, py, php,.)
export SADM_PN="${SADM_INST}.${SADM_EXT}"                  # Script name(with extension)
export SADM_HOSTNAME="$VMNAME"                             # VM Name that we are going to export

# ---

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.10'                                     # Script version number
export SADM_PDESC="Export the specified VirtualBox machine."      
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
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
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------


  

#===================================================================================================
# Global Scripts Variables 
#===================================================================================================
export VBOX_HOST="lestrade.maison.ca"                                   # VirtualBox Host Server
export VMUSER="jacques"                                                 # User part of vboxusers
export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List
export VM_INITIAL_STATE=0                                               # 0=OFF 1=ON 
export STOP_TIMEOUT=120                                                 # acpi power button wait sec
export STARTUP_TIME=240                                                 # Sec given for Startup App.
#
if [ ! -v "$SA" ] || [ "$SA" = "" ] ; then export SA="/opt/sa" ; fi     # Default If $SA Not set
# 


# Load SADM VirtualBox Library functions 
export TOOLS_DIR=$(dirname $(realpath "$0"))                            # Dir. Where VM Scripts are
source ${TOOLS_DIR}/sadm_vm_lib.sh                                      # Load VM functions Tool Lib

export VBOX_HOST="lestrade.maison.ca"                                       # VirtualBox Host Server
export NAS_SERVER="batnas.maison.ca"                                    # Export Server HostName
export NAS_DIR="/volume1/backup_vm/virtualbox_exports"                  # Export VM Dir. on NAS 
export NFS_DIR="/mnt/nfstmp_$$"                                         # NFS Mount Tmp Dir.




# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [VM_Name]" "${BOLD}" "${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
# Ping Backup server receive as $1 - If it failed abort script with error.
# --------------------------------------------------------------------------------------------------
ping_nas_server()
{
    WSERVER=$1
    sadm_write "ping -c 2 ${WSERVER} " 
    ping -c 2 -W 2 $WSERVER >/dev/null 2>/dev/null                      # Ping the Server
    RC=$?                                                               # Save Return Code
    if [ $RC -ne 0 ] 
        then sadm_write "${SADM_ERROR} Can't Ping the backup server ${WSERVER}\n"
             sadm_write "Can't proceed, aborting script.\n"
             RC=1                                                       # Make sure RC is 1 or 0 
        else sadm_write "${SADM_OK}\n"
             RC=0
    fi
    return $RC
}




#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{

# If current user is not the VM Owner, exit to O/S with error code 1
    if [ "$(whoami)" != "$VMUSER" ]                                     # If user is not a vbox user 
        then sadm_write "Script can only be run by '$VMUSER' user, not '$(whoami)', process aborted.\n"
             show_usage
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

# If we are not on the VirtualBox Server, exit to O/S with error code 1
    if [ "$(sadm_get_fqdn)" != "$VBOX_HOST" ]                           # Run only VirtualBox Server 
        then sadm_write "Script can only be run on (${VBOX_HOST}), process aborted.\n"
             show_usage
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

# Check if the VM exist
    sadm_vm_exist "$VMNAME"                                             # In Lib sadm_vm_lib.sh                                   
    if [ $? -ne 0 ]                                                     
       then sadm_write_err "${SADM_ERROR} '$VMNAME' is not a valid registered VM." 
            return 1                                                    # Return Error to Caller
    fi        

# Show Export Option chosen by user.
    TITLE="${SADM_BOLD}${SADM_YELLOW}Export '$VMNAME' Virtual Machine.${SADM_RESET}"
    sadm_write_log "${TITLE}"                                           # Show Backup Chosen

# NAS Server is available ?
    ping_nas_server "$NAS_SERVER"                                       # NAS Server Alive ?
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Return Error to caller

# Save current VM State (Running or Stop), if it's running then shutdown the VM.
    sadm_vm_running "$VMNAME"                                           # Check if it is running
    if [ $? -eq 0 ]                                                     # If it's still running
        then sadm_write_log " "
             sadm_write_log "The Virtual machine is currently running."
             VM_STATE="RUNNING"                                         # Save VM Init State Running
             sadm_vm_stop "$VMNAME"                                     # Then Stop it
             if [ $? -ne 0 ] ; then return 1 ; fi                       # Error if can't stop it 
        else sadm_write_log "The Virtual machine is currently power off."
             VM_STATE="POWEROFF"                                        # Save VM InitState PowerOFF
    fi 

# Export the VM stopped VM.
    sadm_export_vm "$VMNAME"                                            # Then Export VM
    if [ $? -eq 0 ] ; then SADM_EXIT_CODE=0 ; else SADM_EXIT_CODE=1 ; fi 
    

# If VM was initially running, then power on the VM.
    if [ "$VM_STATE" = "RUNNING" ]                                      # VM Running before export ?
        then sadm_vm_start "$VMNAME"                                    # Yes, then Restart the VM
             if [ $? -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi               # Error Ocurred Set ExitCode
             sadm_write_log "Sleep $STARTUP_TIME sec. - Give time to become available."
             sadm_sleep $STARTUP_TIME 30
    fi             
    sleep 4                                                             # Time For last VM to Start

# List the status of all VMs
    sadm_list_vm_status                                                 # List Status of ALL VMs
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}




#===================================================================================================
# MAIN CODE START HERE
#===================================================================================================


    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
