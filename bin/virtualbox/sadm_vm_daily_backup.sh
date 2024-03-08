#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_daily_backup.sh
#   Date        :   2020/12/05
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Perform a backup of a selected virtual machine.
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
#@2022_08_25 nolog v1.1 Updated with new SADMIN SECTION V1.52.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.52
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] # SADMIN defined ? SADMIN Libr. exist   
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi # Last chance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.1'                                      # Script version number
export SADM_PDESC="Perform a backup of a selected virtual machine."      
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
export SADM_ALERT_TYPE=3                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
# ---------------------------------------------------------------------------------------


  

#===================================================================================================
# Global Scripts Variables 
#===================================================================================================
export VBOX_HOST="lestrade.maison.ca"                                       # VirtualBox Host Server
export VMUSER="jacques"                                                 # User part of vboxusers
export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List
export TOOLS_DIR=$(dirname $(realpath "$0"))                            # Dir Where SA VM Tools Live
export TOOLS_LIB="${TOOLS_DIR}/sadm_vm_lib.sh"                          # SA VM Tools Function Libr.
export OPT_VMNAME=""                                                    # VM Name to Backup
export OPT_BACKUP=false                                                 # True if backup all VMs


# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d  Debug Level [0-9]."
    printf "\n\t-h  Display this help message."
    printf "\n\t-v  Show Script Version Info."
    printf "\n\t-n  Specify Virtual Machines Name to backup." 
    printf "\n\t-b  Backup all virtual machines, unless '-n' is used to specify the vm to backup"
    printf "\n\n" 
}






#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    if [ "$OPT_VMNAME" != "" ]                                          # If a VM Name Specified
       then ${TOOLS_DIR}/sadm_vm_backup.sh -yn $OPT_VMNAME              # Backup One VM
       else ${TOOLS_DIR}/sadm_vm_backup.sh -ya                          # Backup ALL VM 
    fi 
    SADM_EXIT_CODE=$?                                                   # Save Return Code
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# Command line options : -d [0-9] -h -v 
#     -d   (Debug Level [0-9])"
#     -h   (Display this help message)"
#     -v   (Show Script Version Info)"
#     -n   (Specify the Virtual Machines Name to act upon (backup,Stop,Start))" 
#     -a   (Backup All Virtual machines)"
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

    # Verify that VBoxManage is available on this system, else abort script.
    which VBoxManage >/dev/null 2>&1                                    # VBoxManage on system ?
    if [ $? -ne 0 ]                                                     # If not present on system
       then sadm_write "\n${RED}'VBoxManage' is needed and it's not on this system.${NORMAL}\n" 
            sadm_write "Process aborted.\n\n"                           # Advise user
            sadm_stop 1                                                 # Close and Trim Log
            exit 1                                                      # Exit with Error 
        else export VBOXMANAGE=$(which VBoxManage)                      # Path to $VBOXMANAGE
    fi 

    # Load SADM VirtualBox functions 
    if [ ! -x "$TOOLS_LIB" ]
       then sadm_write "\n${RED}'$TOOLS_LIB' is needed and it's not present on system.${NORMAL}\n" 
            sadm_write "Process aborted.\n\n"                           # Advise user
            sadm_stop 1                                                 # Close and Trim Log
            exit 1                                                      # Exit with Error 
       else source ${TOOLS_DIR}/sadm_vm_lib.sh                          # Load VM functions Tool Lib
    fi 

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
