#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadmlib_vbox.sh
#   Date        :   2020/07/20
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Library of functions to ease management of Virtual machines under VirtualBox.
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
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# Version Change Log 
#
# 2020_07_20 New: v1.0 Initial Version
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     


#===================================================================================================
# Global Scripts Variables 
#===================================================================================================
#export VMUSER="jacques"                                                 # User part of vboxusers
#export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
#export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List
#export VMNAME=""                                                        # VM Name to Backup 
#export VBOXMANAGE=$(which VBoxManage)                                   # Path to $VBOXMANAGE
#export VBOX_HOST="borg.maison.ca"                                       # VirtualBox Host Server
#export NAS_SERVER="batnas.maison.ca"                                    # Backup Server HostName
#export NAS_DIR="/volume1/backup_vm/virtualbox"                          # Backup VM Dir. on NAS 
#export VM_DIR="/vm"                                                     # Where Real vm Reside





#===================================================================================================
# Check if VM is running 
# (Return 1=Not Running, 0=VM is Running)
#===================================================================================================
sadm_vmrunning()
{
    VM=$1 
    #sadm_write "Verifying Virtual Machine '$VM' status.\n"
    $VBOXMANAGE list runningvms | awk -F\" '{ print $2 }' > $VMRUNLIST
    grep "^${VM}" $VMRUNLIST > /dev/null 2>&1 
    if [ $? -eq 0 ] 
       then sadm_write "${SADM_INFO} Virtual Machine '$VM' is running.\n"
            RC=0
       else sadm_write "${SADM_INFO} Virtual Machine '$VM' isn't running.\n"
            RC=1
    fi 
    if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "\nList of running VM :\n" ;nl $VMRUNLIST ; fi 
    return $RC
}



#===================================================================================================
# Start the vm received as parameter.
# Returned value : 
#   1 = Error starting vm (vm not started)
#   0 = The vm is started.
#===================================================================================================
sadm_startvm()
{
    VM=$1 
    sadm_write "Starting '$VM' virtual machine.\n"
    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write "Running: $VBOXMANAGE startvm --type headless '$VM'\n"
    fi 
    $VBOXMANAGE startvm --type headless "$VM" >> $SADM_LOG 2>&1
    if [ $? -eq 0 ] 
       then sadm_write "${SADM_OK} The VM '$VM' is now started.\n"
            RC=0
       else sadm_write "${SADM_ERROR} The VM '$VM' could not be started.\n"
            RC=1
    fi 
    if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "\nList of running VM :\n" ;nl $VMRUNLIST ; fi 
    return $RC
}



#===================================================================================================
# Stop the vm received as parameter.
# Returned value : 
#   1 = Error stopping vm
#   0 = The vm was stop.
#===================================================================================================
sadm_stopvm()
{
    VM=$1 
    sadm_write "Stopping '$VM' virtual machine.\n"
    sadm_write "Running: $VBOXMANAGE controlvm '$VM' acpipowerbutton\n"
    $VBOXMANAGE controlvm "$VM" acpipowerbutton >> $SADM_LOG 2>&1

    # Sleep 5 seconds and check if VM is still running.
    sleep 15                     
    sadm_vmrunning "$VM" 
    if [ $? -eq 0 ] 
       then sadm_write "${SADM_WARNING} Virtual Machine is still running.\n" 
            sadm_write "Have to do a Powering OFF ${VM}.\n"
            $VBOXMANAGE controlvm "$VM" poweroff
            sadm_write "Running: $VBOXMANAGE controlvm '$VM' poweroff\n"
       else sadm_write "${SADM_OK} The Virtual Machine $VM is now poweroff.\n"
            return 0 
    fi 

    # Check if it stop after poweroff command 
    sleep 5                     
    sadm_vmrunning "$VM" 
    if [ $? -eq 0 ] 
       then sadm_write "${SADM_ERROR} The Virtual Machine $VM could not be stopped.\n"
            return 1
       else sadm_write "${SADM_OK} Virtual Machine $VM is now poweroff." 
            return 0  
    fi 
}




#===================================================================================================
# Check if Virtual Machine Name in in the list of registered machine.
# Returned value : 
#   1 = Error producing list of registered VM
#   0 = The list was produced successfully
#===================================================================================================
sadm_vmexist()
{
    #sadm_write "Verifying if Virtual Machine '$VMNAME' exist.\n"
    $VBOXMANAGE list vms | awk -F\" '{ print $2 }' > $VMLIST

    grep "^${VMNAME}" $VMLIST > /dev/null 2>&1 
    if [ $? -ne 0 ] 
       then sadm_write "${SADM_ERROR} Virtual Machine '$VMNAME' is not registered.\n"
            return 1
       else sadm_write "${SADM_OK} '$VMNAME' Virtual Machine registered.\n"
            return 0 
    fi 
}


#===================================================================================================
# List the registered VM into file $VMLIST
# Returned value : 
#   1 = Error producing list of registered VM
#   0 = The list was produced successfully
#===================================================================================================
sadm_listvm()
{
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_write "$VBOXMANAGE list vms | awk -F\" '{ print $2 }'" ;fi
    $VBOXMANAGE list vms | awk -F\" '{ print $2 }' > $VMLIST
    if [ $? -ne 0 ]
       then sadm_write "${SADM_ERROR} Unable to produce the vm list.\n" 
            return 1 
    fi 
    sadm_write "\n${SADM_BOLD}${SADM_YELLOW}List of registered Virtual machine(s)${SADM_RESET}\n"
    nl $VMLIST | while read wline ; do sadm_write "${wline}\n"; done
    return 0
}




#===================================================================================================
# List the running VM into file $VMRUNLIST
# Returned value : 
#   1 = Error producing list of registered VM
#   0 = The list was produced successfully
#===================================================================================================
sadm_listrunningvm()
{
    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write "$VBOXMANAGE list runningvms | awk -F\" '{ print $2 }'" 
    fi
    $VBOXMANAGE list runningvms | awk -F\" '{ print $2 }' > $VMRUNLIST
    if [ $? -ne 0 ]
       then sadm_write "${SADM_ERROR} Unable to produce the running vm list.\n" 
            return 1 
    fi 
    sadm_write "\n${SADM_BOLD}${SADM_YELLOW}List of running Virtual machine(s)${SADM_RESET}\n"
    nl $VMRUNLIST | while read wline ; do sadm_write "${wline}\n"; done
    return 0
}


