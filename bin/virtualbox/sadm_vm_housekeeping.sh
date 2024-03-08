#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_housekeeping.sh
#   Date        :   2020/07/19
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Daily script to set/reset permission and owner in VirtualBox Virtual Machines.
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
# 2020_07_22 New: v1.0 Initial Version
#@2020_08_20 Update: v1.1 Added second /vm2 as a second directory to store Virtual machine.
#@2020_12_12 Update: v1.2 Add change permission on /vm2 
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
    export SADM_VER='1.2'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writ#set -x
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
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
export VMUSER="jacques"                                                 # VM Linux User 
export VMGROUP="sadmin"                                                 # VM Linux Group 
export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List
export VMNAME=""                                                        # VM Name to Backup 
export VM_INITIAL_STATE=0                                               # 0=OFF 1=ON 

# Verify that VBoxManage is available on this system, else abort script.
which VBoxManage >/dev/null 2>&1
if [ $? -ne 0 ] 
    then printf "'VBoxManage' is needed and it's not available on this system" 
         printf "Process aborted"
         exit 1 
    else export VBOXMANAGE=$(which VBoxManage)                          # Path to $VBOXMANAGE
fi 

# Load SADM VirtualBox functions 
. $SADMIN/usr/lib/sadmlib_vbox.sh 

export VBOX_HOST="lestrade.maison.ca"                                       # VirtualBox Host Server
export NAS_SERVER="batnas.maison.ca"                                    # Backup Server HostName
export NAS_DIR="/volume1/backup_vm/virtualbox"                          # Backup VM Dir. on NAS 
export VM_DIR1="/vm"                                                    # Where Real vm Reside
export VM_DIR2="/vm2"                                                   # Where Real vm Reside



# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\t-s   (VM name to start)"
    printf "\n\n" 
}



#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    ecount=0                                                            # Error Count Reset
    sadm_write "${SADM_BOLD}${SADM_YELLOW}VirtualBox Virtual Machines Housekeeping${SADM_RESET}\n"

    sadm_write "\n"
    sadm_write "chown -R ${VMUSER}:${VMGROUP} $VM_DIR1 $VM_DIR2 "
    chown -R ${VMUSER}:${VMGROUP} $VM_DIR1 $VMDIR2
    if [ $? -ne 0 ]                                                     # If Error returned
        then sadm_write "${SADM_ERROR} With last command.\n"            # Advise user of Error
             ecount=`expr $ecount + 1`                                  # Incr. Error count                                                     # Make sure RC is 1 or 0 
        else sadm_write "${SADM_OK}\n"                                  # Give Status to user
    fi
    if [ -f "${VM_DIR1}/lost+found" ] ; then chown root:root ${VM_DIR1}/lost+found ; fi 
    if [ -f "${VM_DIR2}/lost+found" ] ; then chown root:root ${VM_DIR2}/lost+found ; fi 

    sadm_write "find /vm -type d -exec chmod 775 {} \; "    
    find /vm -type d -exec chmod 775 {} \;
    if [ $? -ne 0 ]                                                     # If Error returned
        then sadm_write "${SADM_ERROR} With last command.\n"            # Advise user of Error
             ecount=`expr $ecount + 1`                                  # Incr. Error count                                                     # Make sure RC is 1 or 0 
        else sadm_write "${SADM_OK}\n"                                  # Give Status to user
    fi

    sadm_write "find /vm -type f -exec chmod 664 {} \; "
    find /vm -type f -exec chmod 664 {} \;
    if [ $? -ne 0 ]                                                     # If Error returned
        then sadm_write "${SADM_ERROR} With last command.\n"            # Advise user of Error
             ecount=`expr $ecount + 1`                                  # Incr. Error count                                                     # Make sure RC is 1 or 0 
        else sadm_write "${SADM_OK}\n"                                  # Give Status to user
    fi

    sadm_write "find /vm2 -type d -exec chmod 775 {} \; "    
    find /vm2 -type d -exec chmod 775 {} \;
    if [ $? -ne 0 ]                                                     # If Error returned
        then sadm_write "${SADM_ERROR} With last command.\n"            # Advise user of Error
             ecount=`expr $ecount + 1`                                  # Incr. Error count                                                     # Make sure RC is 1 or 0 
        else sadm_write "${SADM_OK}\n"                                  # Give Status to user
    fi

    sadm_write "find /vm2 -type f -exec chmod 664 {} \; "
    find /vm2 -type f -exec chmod 664 {} \;
    if [ $? -ne 0 ]                                                     # If Error returned
        then sadm_write "${SADM_ERROR} With last command.\n"            # Advise user of Error
             ecount=`expr $ecount + 1`                                  # Incr. Error count                                                     # Make sure RC is 1 or 0 
        else sadm_write "${SADM_OK}\n"                                  # Give Status to user
    fi

    sadm_write "\n"
    if [ "$ecount" -eq 0 ]
       then sadm_write "Virtual Machine Housekeeping completed successfully.\n"
            SADM_EXIT_CODE=0
       else sadm_write "Virtual Machine Encountered completed with $ecount errors.\n"
            SADM_EXIT_CODE=1
    fi 

    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
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

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user, process aborted.\n"
             sadm_write "Try sudo %s" "${0##*/}\n"                      # Suggest using sudo
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
    
