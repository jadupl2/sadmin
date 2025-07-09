#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_vm_lib.sh
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
#   If not, see <https://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# Version Change Log 
#
# 2020_07_20 virtualbox v1.0 Initial Version
# 2020_07_22 virtualbox v1.1 Add -l to list VM with their status
# 2020_12_12 virtualbox v1.2 Add display of the backup files at the end of the backup.
#@2021_01_02 virtualbox v1.3 VM location on disk, use snapshot location instead of config file.
#@2021_01_05 virtualbox v1.4 Show more info at the end of the backup.
#@2022_11_27 virtualbox v1.5 Add export & clean export function of virtual box vm
#@2022_12_13 virtualbox v1.6 Change from 3 to 2 the number of exports to keep.
#@2022_12_29 virtualbox v1.7 Fix purge of old exports
#@2023_02_05 virtualbox v1.8 Chmod of .ova (664) file after the export
#@2023_03_09 virtualbox v2.1 New Library dedicated for administrating VirtualBox Environment.
#@2024_04_02 virtualbox v2.2 Documents each functions available in this library.
#@2024_04_04 virtualbox v2.3 Small bug fixes.
#@2024_04_19 virtualbox v2.4 Replace 'sadm_write' by 'sadm_write_log' and 'sadm_write_err'. 
#@2024_10_01 virtualbox v2.5 Total free mem is now (free mem + avail mem) on total vm line.
#@2024_11_11 virtualbox v2.6 Do not start an VM export if the system is lock.
#@2024_11_26 virtualbox v2.7 Do not start an VM export if the system is lock.
#@2024_11_17 virtualbox v2.8 Minor changes
#@2025_03_25 virtualbox v2.9 Was not showing the current VirtualBox Guest addition version.
#@2025_04_09 virtualbox v3.0 Minor changes.
#@2025_07_09 virtualbox v3.1 Minor adjustment in heading & Change total calculation
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     




# Global Variables
# --------------------------------------------------------------------------------------------------
export VMLIBVER="3.1"                                                   # This Library version
export VMLIB_DEBUG="N"                                                  # Activate Debug output Y/N
export VMLIST="$(mktemp "$SADMIN/tmp/${SADM_INST}vm_list1_XXX")"        # List of all VM in VBox
export VMRUNLIST="$(mktemp "$SADMIN/tmp/${SADM_INST}vm_runlist_XXX")"   # Tmp File to list RunningVM 
export VBOXMANAGE=""                                                    # /usr/bin/VBoxManage
#
# SADMIN VM Start Exclude List and Template
export START_EXCLUDE_FILE="$SADM_CFG_DIR/sadm_vm_exclude_start_${SADM_HOSTNAME}.txt" # VM Start Excl
export START_EXCLUDE_INIT="$SADM_CFG_DIR/.sadm_vm_exclude_start.txt"    # VM Start Exclude Template

# These variables are loaded by sadmlib_std.sh - You change them in $SADMIN/cfg/sadmin.cfg).
# SADM_VM_EXPORT_NFS_SERVER    = batnas.maison.ca
# SADM_VM_EXPORT_MOUNT_POINT   = /volume1/backup_vm/virtualbox_exports
# SADM_VM_EXPORT_TO_KEEP       = 2
# SADM_VM_EXPORT_INTERVAL      = 14 
# SADM_VM_EXPORT_ALERT         = Y 
# SADM_VM_USER                 = jacques
# SADM_VM_STOP_TIMEOUT         = 120
# SADM_VM_START_INTERVAL       = 30
# SADM_VM_EXPORT_DIF           = 25



#===================================================================================================
#""" sadm_vm_running 
### Synopsys:
#   sadm_vm_running [vmName]
#
### Description:
#   Test if the VM is Up (Power on) or Down (Power off).
#   
### Args: 
#   String: Contain the name of the virtual machine to verify.
#
### Return: 
#   Integer: Return '1', when power is off on the VM.
#            Return ´0', when power is on.
### Example: 
#       sadm_vm_running "$VM"                                 # Test if VM is running
#       if [ $? -ne 0 ] ; then sadm_vm_stop "$VM" ; fi        # If running, stop the VM 
#
#```bash
#$ VBoxManage list runningvms
#"fedora" {63f30e5f-ae97-468b-82c3-d895ead5151f}
#"ubuntu2204" {87ff06ea-3a16-424a-b4f6-cf9f4418e06d}
#"debian12" {de6be8ac-9508-45ce-8931-0833d3310d2b}
#"rhel9" {24e7f86c-9282-4ac7-9b20-69b8236157e6}
#
# sudo -H -u robert vboxmanage list runningvms | cut -d " " -f1  | sed -e 's/^.//' -e 's/.$//'
#    holmes
#    centos8
#    debian11
#    ubuntu2004
#    ubuntu2204
#    rhel8
#```
#"""
#===================================================================================================
sadm_vm_running()
{
    VM=$1                                               
    if [ "$VMLIB_DEBUG" = "Y" ] ; then sadm_write_log "Verifying if '$VM' VM is running." ; fi
    
    VBoxManage  list runningvms | awk -F\" '{ print $2 }' | grep -q "^${VM}" 
    if [ $? -eq 0 ] 
       then if [ "$VMLIB_DEBUG" = "Y" ] 
                then sadm_write_log "${SADM_INFO} Virtual Machine '$VM' is running."
            fi 
            RC=0
       else if  [ "$VMLIB_DEBUG" = "Y" ] 
                then sadm_write_log "${SADM_INFO} Virtual Machine '$VM' is not running."
            fi 
            RC=1
    fi 
    return $RC
}



#===================================================================================================
#""" sadm_vm_start [VNName]
#
# Synopsys:
#   sadm_vm_start [vmName]
#
# Description:
#   Start the specified VM.
#   
# Args: 
#   String: Contain the name of the virtual machine to start.
#
# Return: 
#   Integer: Return '1' if the VM could not be started.
#            Return ´0' if the VM is successfully started.
# Example: 
#   sadm_vm_start "$VM"                                         # Start the specified VM 
#   if [ $? -ne 0 ] 
#      then sadm_write_err "[ ERROR ] The '$VM' VM could not be started."
#      else sadm_write_log "[ OK ] The '$VM' VM have been started."
#   fi 
#"""
#===================================================================================================
sadm_vm_start()
{
    VM=$1 
    sadm_write_log "Starting '$VM' virtual machine."
    sadm_write_log "$VBOXMANAGE startvm --type headless '$VM'"

    $VBOXMANAGE startvm --type headless "$VM" >> $SADM_LOG 2>&1
    if [ $? -eq 0 ] 
       then sadm_write_log "[ OK ] The virtual machine '$VM' is started."
            RC=0
       else sadm_write_err "[ ERROR ] The virtual machine '$VM' could not be started."
            RC=1
    fi 
    if [ "$VMLIB_DEBUG" = "Y" ] 
        then sadm_write_log " " 
             sadm_write_log "List of running VM :"
             nl $VMRUNLIST 
    fi 
    return $RC
}



#===================================================================================================
#"""
# Synopsys:
#   sadm_vm_stop "$vmName"
#
# Description:
#   Stop the specified VM.
#   
# Args: 
#   String: Contain the name of the virtual machine to stop.
#
# Return: 
#   Integer: Return '1' if could not stop the VM.
#            Return ´0' if the VM is successfully stop.
# Example: 
#   sadm_vm_stop "$VM"                                         # Start the specified VM 
#   if [ $? -ne 0 ] 
#      then sadm_write_err "[ ERROR ] The '$VM' VM could not be stopped."
#      else sadm_write_log "[ OK ] The '$VM' VM was successfully stop."
#   fi 
#"""
#===================================================================================================
sadm_vm_stop() 
{
    VM=$1 
    WAIT_BETWEEN_RETRY=10                                               # Sec. sleep Between ReCheck 
    ELAPSE="$SADM_VM_STOP_TIMEOUT"                                 # Sec. since acpi shutdown 
    POWEROFF="N"                                                        # Change to Y when PowerOFF

    sadm_write_log "Stopping virtual machine '$VM'."
    sadm_write_log "$VBOXMANAGE controlvm '$VM' acpipowerbutton"
    sadm_write_log "We give $SADM_VM_STOP_TIMEOUT seconds to bring down the virtual machine."
    sadm_write_log "This value is taken from SADMIN configuration file 'sadmin.cfg' as 'SADM_VM_STOP_TIMEOUT'."
    $VBOXMANAGE controlvm "$VM" acpipowerbutton >> $SADM_LOG 2>&1

    # Wait for the shutdown to complete, wait for "$SADM_VM_STOP_TIMEOUT" sec, then power off.
    while [ $ELAPSE -ge 0 ]                                             # loop till sec. down to 0 
        do
        #printf "${ELAPSE}..."  | tee -a $SADM_LOG                       # Indicate Sec. ELAPSE
        printf "${ELAPSE}..."                                           # Indicate Sec. ELAPSE
        sleep $WAIT_BETWEEN_RETRY                                       # Wait Shutdown to End
        sadm_vm_running "$VM"                                           # Test if VM still running
        if [ $? -ne 0 ] ; then POWEROFF="Y" ; break ; fi                # If PowerOFF, Set Y & break 
        ELAPSE=$(( $ELAPSE - $WAIT_BETWEEN_RETRY ))                     # Decr. elapse by sleep time
        done
    
    # If was able to shutdown VM using 'acpi power button' command, advise user & return to caller.
    sadm_write_log " " 
    if [ "$POWEROFF" = "Y" ]
        then sadm_write_log "[ OK ] Virtual Machine '$VM' is now powered off." 
             return 0  
        else sadm_write_log "The $SADM_VM_STOP_TIMEOUT sec. given for a shutdown is exceeded."
    fi 
    #sadm_write_log " " 

    # OK we waited more than $SADM_VM_STOP_TIMEOUT sec. for the ACPI shutdown to complete,
    # Now we force poweroff the VM
    sadm_write_log "$VBOXMANAGE controlvm '$VM' poweroff"
    $VBOXMANAGE controlvm "$VM" poweroff

    # Check if it stop after power off command 
    sleep 5                                                             # Sleep 5 Seconds
    sadm_vm_running "$VM"                                               # Check if VM is running 
    if [ $? -eq 0 ]                                                     # VM is Still Running
       then sadm_write_err "[ ERROR ] The Virtual Machine $VM could not be stopped."
            return 1
       else sadm_write_log "[ OK ] Virtual Machine $VM is now poweroff." 
            return 0  
    fi 
}




#===================================================================================================
#"""
# Synopsys:
#   sadm_vm_exist "$vmName"
#
# Description:
#   Check if virtual machine name is a registered machine.
#   
# Args: 
#   vmName(String): Contain the name of the virtual machine to check existence.
#
# Return: 
#   Integer: Return '1' If the VM doesn't exist.
#            Return ´0' If the VM exist.
# Example: 
#   sadm_vm_exist "$VM"
#   if [ $? -ne 0 ] 
#      then sadm_write_err "[ ERROR ] The '$VM' VM does not exist."
#      else sadm_write_log "[ OK ] The '$VM' VM does exist."
#   fi 
#"""
#===================================================================================================
sadm_vm_exist()
{
    VM=$1                                                               # Save Virtual Machine Name
    if [ "$VMLIB_DEBUG" = "Y" ] ;then sadm_write_log "Check if the Virtual Machine '$VM' exist." ;fi
    $VBOXMANAGE list vms | awk -F\" '{ print $2 }' | grep -q "^${VM}"   # Produce List of Running VM
    if [ $? -ne 0 ]                                                     # Not it's not
       then if [ "$VMLIB_DEBUG" = "Y" ]                                 # Under Debug show Result
                then sadm_write_err "[ ERROR ] Virtual Machine '$VM' is not registered."
            fi 
            return 1                                                    # Return doesn't exist = 1
       else if [ "$VMLIB_DEBUG" = "Y" ]                                    # Under Debug show Result
                then sadm_write_log "[ OK ] '$VM' Virtual Machine registered."
            fi 
            return 0                                                    # Return does exist = 0 
    fi 
}



#===================================================================================================
#"""
# Synopsys:
#   sadm_list_vm() 
#
# Description:
#   Create a file ('$VMLIST') containing the list on running VMs.
#   
# Args: 
#   No argument needed.
#
# Return: 
#   Integer: 1 = Error producing list of registered VM
#            0 = The list in produced successfully in ${VMLIST}.
#
# Example: 
#   sadm_list_vm                                            # Refresh List of machine in $VMLIST
#   sadm_write_log "List of registered virtual machine(s):"
#   sort $VMLIST | nl | while read wline ; do sadm_write_log "${wline}"; done
#"""
#===================================================================================================
sadm_list_vm()
{
    if [ "$VMLIB_DEBUG" = "Y" ] 
        then sadm_write_log "$VBOXMANAGE list vms | awk -F\" '{ print $2 }'" 
    fi
    $VBOXMANAGE list vms | awk -F\" '{ print $2 }' > $VMLIST
    if [ $? -ne 0 ]
       then sadm_write_err "[ ERROR ] Unable to produce the vm list.\n" 
            return 1 
    fi 
    sadm_write_log " " 
    sadm_write_log "List of registered virtual machine(s)"
    sort $VMLIST | nl | while read wline ; do sadm_write_log "${wline}"; done
    return 0
}




#===================================================================================================
#"""
# Synopsys:
#   sadm_list_vm_running() 
#
# Description:
#   Create a file ('$VMRUNLIST') containing the list on running VMs.
#   
# Args: 
#   No argument needed.
#
# Return: 
#   Integer: 1 = Error creating a file ('VMRUNLIST') containing a list of running VMs.
#            0 = Running VMs name are listed in file ('VMRUNLIST'). 
#
# Example: 
#   sadm_write_log "Creating a list of all running Virtual machines:"
#   sadm_list_vm_running                                    # Refresh List running VMs in $VMRUNLIST
#   sort $VMRUNLIST | nl | while read wline ; do sadm_write_log "${wline}"; done
#"""
#===================================================================================================
sadm_list_vm_running()
{
    if [ "$VMLIB_DEBUG" = "Y" ] 
        then sadm_write_log "$VBOXMANAGE list runningvms | awk -F\" '{ print $2 }'" 
    fi
    $VBOXMANAGE list runningvms | awk -F\" '{ print $2 }' > $VMRUNLIST
    if [ $? -ne 0 ]
       then sadm_write_log "[ ERROR ] Unable to produce the running vm list." 
            return 1 
    fi 
    sadm_write_log " "
    sadm_write_log "List of running virtual machine(s)"
    sort $VMRUNLIST | nl | while read wline ; do sadm_write_log "${wline}"; done
    return 0
}




#===================================================================================================
#"""
# Synopsys:
#   sadm_list_vm_status()
#
# Description:
#   List summarized information of all VirtualBox guest machines.
#   Status include: 
#       - Name, Status, Guest Extension ver., Memory allocated, Nb. CPU, VM IP, VirtualDesktop Port
#   
# Args: 
#   No argument needed.
#
# Return: 
#   Integer: #  1 = Error producing list 
#               0 = The list was produced successfully 
#
# Example: 
#   sadm_write_log "List summarized information about each Virtual machine.
#   sadm_list_vm_status                                    # List Detail Info of all VMs
#
# Example of output : 
#```
# ================================================================================
# No Name               State   Ext.Ver   Memory  CPU   VM IP           VRDE Port
# ================================================================================
# 01 centos8            poweron   7.0.12  2048MB   2    192.168.1.141   50028
# 02 centos9            poweron   7.0.12  2048MB   1    192.168.1.151   Disable
# 03 debian11           poweron   7.0.12  2048MB   2    192.168.1.144   Disable
# 04 debian12           poweron   7.0.12  2048MB   2    192.168.1.148   Disable
# 05 fedora             poweron   7.0.12  2048MB   2    192.168.1.53    50032
# 06 mwindows10         poweroff          2048MB   2    10.0.2.15       Disable
# 07 rhel8              poweron   7.0.12  2048MB   2    192.168.1.142   50008
# 08 rhel9              poweron   7.0.12  2048MB   2    192.168.1.143   Disable
# 09 rocky9             poweron   7.0.12  2048MB   2    192.168.1.147   Disable
# 10 sherlock           poweron   7.0.12  4096MB   2                    Disable
# 11 ubuntu2004         poweroff          1536MB   2    192.168.1.145   50020
# 12 ubuntu2204         poweron   7.0.12  2048MB   2    192.168.1.35    2104
# ================================================================================
# Running VM allocated memory : 22528 MB         Total Server Free Memory : 712 MB
# Total PowerON VM : 10                                      Total PowerOFF VM : 2
# Swap Used: 0 - Swap Size: 8191 
# Using 0 MB (0.0%) out of the 8191 MB Swap space.
# ================================================================================
#```
#"""
#===================================================================================================
sadm_list_vm_status()
{
    # We will use two temp file, make sure they don't exist
    VMTMP1=$(mktemp -u) 
    VMTMP2=$(mktemp -u) 

    # Create a list of ALL vm registered in Virtual Box ($VMTMP2).
    sadm_write_log " "
    $VBOXMANAGE list vms > $VMTMP2                                      # Create vmname & id list
    if [ $? -ne 0 ]                                                     # If Error creating vm list
       then sadm_write_err "[ ERROR ] Unable to produce the VMs list." 
            return 1 
    fi 

    # Add a third field for the state of the VM (Default is power off), for now they are power off.
    sort $VMTMP2 | while read wline
       do 
       #echo "vmline : $wline"
       vm_name=$(echo $wline | awk -F\" '{ print $2 }')                 # Name of the VM
       vm_uuid=$(echo $wline | awk      '{ print $2 }')                 # ID of the VM
       vm_stat="poweroff"                                               # Default value "poweroff" 
       if [ "$VMLIB_DEBUG" = "Y" ] ; then echo "Poweroff line: ${vm_name},${vm_uuid},${vm_stat}" ;fi
       echo "${vm_name},${vm_uuid},${vm_stat}" >>$VMTMP1
       done

    if [ "$VMLIB_DEBUG" = "Y" ] 
        then sadm_write_log " " 
             sadm_write_log "Should all have power off, as first field"
             cat $VMTMP1 | while read wline ; do sadm_write_log "${wline}"; done
             sadm_write_log " " 
    fi 

    # Create a List of running VMs.
    $VBOXMANAGE list runningvms | sort > $VMRUNLIST
    if [ $? -ne 0 ]
       then sadm_write_err "[ ERROR ] Unable to produce the running VMs list.\n" 
            return 1 
    fi 

    # Here we establish the state of each VMs (Is it power on or power off ?).
    # Output file is $VMTMP2
    rm -f "$VMTMP2" > /dev/null 2>&1                                    # Will need an empty file  
    if [ -s "$VMRUNLIST" ]                                              # Anything in VM_RunningList
        then cat $VMTMP1 | while read wline                             # Read Line by Line
                do 
                #if [ "$VMLIB_DEBUG" = "Y" ] ; then echo "Line before checking state: $wline" ; fi
                vm_name=$(echo $wline | awk -F, '{ print $1 }')         # Name of the VM
                vm_uuid=$(echo $wline | awk -F, '{ print $2 }')         # VM ID
                vm_stat=$(echo $wline | awk -F, '{ print $3 }')         # Status (Power on/off)
                sadm_vm_running "$vm_name"                              # Is the VM Running ?
                if [ $? -eq 0 ]                                         # Yes it is 
                   then echo "${vm_name},${vm_uuid},poweron"  >>$VMTMP2 # Set State of VM poweron
                   else echo "${vm_name},${vm_uuid},poweroff" >>$VMTMP2 # Set State of VM poweroff
                fi 
                done
        else cp $VMTMP1 $VMTMP2                                         # No running VM,VMs are Down
    fi 
    if [ "$VMLIB_DEBUG" = "Y" ] 
        then sadm_write_log " " 
             sadm_write_log "Lines after checking state: "
             cat $VMTMP2 | while read wline ; do sadm_write_log "${wline}"; done
    fi 

    # Virtual Box machine list header
    printf "${SADM_80_DASH}\n" | tee -a $SADM_LOG
    printf "%-3s%-17s%-8s%-14s%-8s%-6s%-15s%-s\n" "No" "Name" "State" "Additions" "Memory" "CPU" "VM IP" "VRDE Port" | tee -a $SADM_LOG
    printf "${SADM_80_DASH}\n" | tee -a $SADM_LOG

    # Initialize Total Variables.
    lineno=0                                                            # Reset to 0 Line Counter
    tpoweron=0                                                          # Reset Total PowerOn 
    tpoweroff=0                                                         # Reset Total PowerOff
    tmemory=0                                                           # Reset Total Memory Alloc.
    
    # Now we have a file that contain alls VMs info, one vm per line.
    # Read that file and get Nb.CPU, Memory assigned to VM, Ip Address, Remote Desktop Port & state.
    IFS=$'\n'                                                           # set Internal Field Separator
    for wline in $(cat "$VMTMP2")
        do 
        lineno=$((lineno + 1))                                          # Add 1 to Line Counter
        vm_name=$(echo $wline | awk -F, '{ print $1 }' | tr -d "\"")    # VM Name, without "
        vm_uuid=$(echo $wline | awk -F, '{ print $2 }')                 # VM ID
        vm_stat=$(echo $wline | awk -F, '{ print $3 }')                 # Power on or Power off
        #echo "before guestproperty : ${vm_name},${vm_uuid},${vm_stat}"
        # Set Power State
        if [ "$vm_stat" = "poweron" ]  ; then tpoweron=$((tpoweron + 1))   ; fi
        if [ "$vm_stat" = "poweroff" ] ; then tpoweroff=$((tpoweroff + 1)) ; fi

        # Get VM IP
        #printf "guestproperty\n"
        vm_ip=$(VBoxManage guestproperty enumerate $vm_name | grep '/VirtualBox/GuestInfo/Net/0/V4/IP' | awk -F= '{print $2}' |awk '{print $1}'|tr -d "\'") 
        if [ "$vm_ip" = 'value' ] ; then vm_ip='Not available' ; fi

        # Get Memory size
        #printf "memory\n"
        vm_mem=$($VBOXMANAGE showvminfo $vm_name |grep 'Memory size' | awk '{print $3}')
        vm_num_mem=$(echo "$vm_mem" | sed 's/[A-Za-z]*//g')             # Remove size unit

        # Add memory to total
        if [ "$vm_stat" = "poweron" ]  ; then tmemory=$((tmemory + vm_num_mem)) ; fi

        # Get number of CPU
        vm_cpu=$($VBOXMANAGE showvminfo $vm_name |grep 'Number of CPU' |awk '{print $4}' |tr -d ' ')

        # Get Virtual Box Guest extension version
        #vm_verext=$($VBOXMANAGE guestproperty enumerate $vm_name |grep '/VirtualBox/HostInfo/VBoxVerExt' |awk '{print $3}' |tr -d "\'")
        vm_verext=$($VBOXMANAGE showvminfo $vm_name |grep 'Additions version' |awk -F: '{print $2}' |tr -d ' ')

        # Remote Desktop State
        #printf "vrde\n"
        vrde_state=$($VBOXMANAGE showvminfo $vm_name |grep 'VRDE:'     | awk '{print $2}')
        if [ "$vrde_state" = "enabled" ]
            then vrde_port=$($VBOXMANAGE showvminfo $vm_name |grep 'VRDE:' |awk '{print $6}' |tr -d ',')
            else vrde_port='Disable'
        fi 
        printf  "%02d %-15s %-8s %-13s %-8s %-4s %-15s %-s\n" "$lineno" "$vm_name" "$vm_stat" "$vm_verext" "$vm_mem" "$vm_cpu" "$vm_ip" "$vrde_port" | tee -a $SADM_LOG
        done

    # Show Total Lines.
    printf "${SADM_80_DASH}\n" | tee -a $SADM_LOG
    #
    part1=$(printf "Running VM allocated memory : ${tmemory} MB")
    freemem=$(free -m  | grep 'Mem:' | awk '{ print $4 }')
    availmem=$(free -m | grep 'Mem:' | awk '{ print $7 }') 
    part2=$(printf "Memory available for VM  : $(free -hl | awk '/Mem:/ {print $NF}')")
    printf "%-40s%40s\n" "$part1" "$part2" | tee -a $SADM_LOG
    #
    printf "%-40s%40s\n" "Total PowerON VM : ${tpoweron}" "Total PowerOFF VM : ${tpoweroff}" | tee -a $SADM_LOG
    swap_size=$(free -m | grep "Swap" | awk '{ print $2 }')
    swap_used=$(free -m | grep "Swap" | awk '{ print $3 }')
    #echo "Swap Used: $swap_used - Swap Size: $swap_size "
    swap_pct=$( echo "$swap_used / $swap_size * 100" | bc -l)
    swap_pct=$(printf "%3.1f" "$swap_pct")
    printf "Using %s (%s%%) of the %s allocated for swap space.\n" "$(free -hl | awk '/Swap:/ {print $3}')" "$swap_pct" "$(free -hl | awk '/Swap:/ {print $2}')" | tee -a $SADM_LOG
    printf "${SADM_80_DASH}\n" | tee -a $SADM_LOG
    return 0
}




#===================================================================================================
# Backup Virtual Machine function 
#   - Parameter Received is the name of the VirtualBox machine name to backup 
#   - Returned value : 
#       1 = Error performing the backup.
#       0 = Backup was done with success
#===================================================================================================
sadm_backup_vm()
{
    VM="$1"
    sadm_write_log " "
    sadm_write_log "----------"
    sadm_write_log "Starting backup of virtual machine '$VM' to ${SADM_VM_EXPORT_NFS_SERVER}."
    VM_DIR=$($VBOXMANAGE showvminfo $VM |grep -i snapshot |awk -F: '{print $2}'|tr -d ' '|xargs dirname)

    sadm_write_log "rsync -e 'ssh' -hi -var --no-p --no-g --no-o --delete ${VM_DIR}/ ${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT}/${VM}/"
    rsync -e 'ssh' -hi -var --no-p --no-g --no-o --delete ${VM_DIR}/ ${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT}/${VM}/ >>$SADM_LOG 2>&1   
    if [ $? -ne 0 ]                                                     # If Error Occurred 
       then sadm_write_log "[ FAILED ] doing backup of '${VM}'"      # Advise user of Error
            RC=1                                                        # Return Error 1 to caller
       else sadm_write_log "[ SUCCESS ]Backup of the virtual machine '${VM}'"
            RC=0                                                        # Return Success 0 to caller
    fi 

    # Mount NFS Backup Dir.
    #sadm_write_log "id=`id`"
    if [ ! -d ${NFS_DIR} ] ; then sudo mkdir ${NFS_DIR} ; sudo chmod 775 ${NFS_DIR} ; fi
    sudo umount ${NFS_DIR} > /dev/null 2>&1                             # Make sure it is unmounted 
    sudo mount ${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT} ${NFS_DIR} >>$SADM_LOG 2>&1     # Mount Dest. NFS Dir 
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_err "[ ERROR ] mount ${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT} ${NFS_DIR}"      
             sudo umount ${NFS_DIR} > /dev/null 2>&1                    # Ensure Dest. Dir Unmounted
             return 1                                                   # Set RC to One (Standard)
        else RC=0                                                       # NFS Worked Return Code=0
             sadm_write_log "[ OK ] mount ${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT} ${NFS_DIR}" 
    fi

    sadm_write_log " " 
    sadm_write_log "List content of $VM backup directory:"
    ls -lhR ${NFS_DIR}/${VM} | while read wline ; do sadm_write_log "${wline}"; done

    sudo umount ${NFS_DIR} >>$SADM_LOG 2>&1  
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_err "[ ERROR ] umount ${NFS_DIR}"      
        else sadm_write_log "[ OK ] umount ${NFS_DIR}" 
    fi
    rm -fr ${NFS_DIR} >>$SADM_LOG 2>&1 
    sadm_write_log " " 
    return $RC
}



#===================================================================================================
#"""
# Synopsys:
#   sadm_ping "hostname"
#
# Description:
#   Do a ping to hostname received as a paraneter.
#   
# Args: 
#   String:     The hostname to ping.
#
# Return: 
#   Integer: #  1 = Ping failed.
#               0 = Ping Succeeded.
#
# Example: 
#    sadm_ping "$SADM_VM_EXPORT_NFS_SERVER" 
#    if [ $? -ne 0 ]                                                     
#       then sadm_write_err "Ping failed."
#       else sadm_write_log "Ping succeeded."
#    fi    
#
#"""
# --------------------------------------------------------------------------------------------------
# Ping Backup server received as $1 - If it failed Return (1) error to caller
# --------------------------------------------------------------------------------------------------
sadm_ping()
{
    WSERVER=$1
    ping -c 2 -W 2 $WSERVER >/dev/null 2>/dev/null                      # Ping the Server
    RC=$?  
    if [ $RC -ne 0 ] 
        then sadm_write_err "[ ERROR ] Ping to system '$WSERVER' failed."
             sadm_write_err "  - Can't proceed, aborting script."
             RC=1                                                       # Make sure RC is 1 or 0 
        else sadm_write_log "[ OK ] System '$WSERVER' is alive."
             RC=0
    fi
    return $RC
}


#===================================================================================================
#"""
### Synopsys:
#   sadm_export_vm()
#
### Description:
#   Do an export of the specified VM on the NFS server mentionned in $SADMIN/cfg/sadmin.cfg
#   
### Arguments: 
#   String:     The name of the VM to export.
#
### Return: 
#   Integer: #  1 = Error producing the export of the VM.
#               0 = The export was produced successfully 
#
### Example: 
# ```bash
#    sadm_export_vm "$VMNAME"
#    if [ $? -eq 0 ] ; then echo "Success" ; else echo "Failed" ; fi 
#```

#"""
# 
#===================================================================================================
sadm_export_vm()
{
    VM="$1"                                                             # Save VM Name
    export MOUNT_POINT="/tmp/${SADM_INST}.tmp"                          # Create Temp Dir in /tmp
    if [ ! -d "$MOUNT_POINT" ]                                          # Today export Dir. Exist?
        then sudo mkdir -p "$MOUNT_POINT" 
    fi 

    EXPORT_DIR="${MOUNT_POINT}/${VM}"                                   # Actual Export Directory
    EXP_CUR_PWD=$(pwd)                                                  # Save Current Working Dir.
    EXPDIR="${MOUNT_POINT}/${VM}/$(date "+%C%y_%m_%d")"                 # Export Today Export Dir.
    EXPOVA="${EXPDIR}/${VM}_$(date +%Y_%m_%d_%H_%M_%S).ova"             # Export OVA File Name

    # Check if the VM exist
    sadm_vm_exist "$VM"                                                 # Does the VM exist ?                                 
    if [ $? -ne 0 ]                                                     
       then sadm_write_err "${SADM_ERROR} '$VM' is not a valid registered virtual machine on host." 
            return 1                                                    # Return Error to Caller
    fi    

    # Check if System is Locked.
    sadm_lock_status "$VM"                                        # Check lock file status
    if [ $? -ne 0 ]                                                     # The system is lock
        then sadm_write_err "[ ERROR ] System is lock, VM export is not allowed."
             return 1                                                   # Return Error to caller
    fi 

    # Create lock file while VM export is running 
    # This prevent the SADMIN server from starting a script on the remote system.
    # A system Lock also turn off monitoring of remote system.
    #sadm_lock_status "$VM"                                              # Lock system while export
    #if [ $? -ne 0 ]                                                     # If lock system failed
    #   then sadm_write_err "[ ERROR ] Couldn't create the lock file for '$VM'." 
    #        return 1 
    #fi

    # NFS Server is available ?
    sadm_ping "$SADM_VM_EXPORT_NFS_SERVER"                              # NFS Server Alive ?
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Return Error to caller

     # Save current VM State (Running or Power Off), if it's running then shutdown the VM.
    sadm_vm_running "$VM"                                               # Check if it is running
    if [ $? -eq 0 ]                                                     # If it's still running
        then sadm_write_log " "
             sadm_write_log "The Virtual machine '$VM' is currently running."
             INITIAL_STATE="RUNNING"                                    # Save VM Init State Running
             sadm_vm_stop "$VM"                                         # Then Stop it
             if [ $? -ne 0 ] ; then return 1 ; fi                       # Error if can't stop it 
        else sadm_write_log "The Virtual machine '$VM' is currently power off."
             INITIAL_STATE="POWEROFF"                                   # Save VM InitState PowerOFF
    fi 
    
    # Get the name of the directory where the VM exist
    sadm_write_log " "
    VM_DIR=$($VBOXMANAGE showvminfo $VM |grep -i snapshot |awk -F: '{print $2}'|tr -d ' '|xargs dirname |head -1)
    sadm_write_log "The VM '$VM' is located in '${VM_DIR}' on '${SADM_HOSTNAME}'."

    # Show User Mount command
    SHORT_NFS="${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT}"
    sadm_write_log "sudo mount $SHORT_NFS $MOUNT_POINT"
    sudo mount $SHORT_NFS ${MOUNT_POINT} >>$SADM_LOG 2>&1
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_err "[ ERROR ] mount $SHORT_NFS ${MOUNT_POINT}"      
             sudo umount ${MOUNT_POINT} > /dev/null 2>&1                # Ensure Dest. Dir Unmounted
             sadm_unlock_system "$VM"                                   # Go remove the lock file
             return 1                                                   # Set RC to One (Standard)
        else sadm_write_log "[ OK ] NFS mount succeeded."
    fi


    # Make sure the System Export directory exist on the NFS server.
    if [ ! -d "${MOUNT_POINT}/${VM}" ] 
        then sudo mkdir -p "${MOUNT_POINT}/${VM}"  
             if [ "$?" -ne 0 ]                                          # If Error creating Dir.
                then sadm_write_err "[ ERROR ] Wasn't able to create nfs mount point directory '${MOUNT_POINT}/${VM}'."
                     sudo umount ${MOUNT_POINT} >>$SADM_LOG 2>&1  
                     sadm_unlock_system "$VM"                           # Go remove the lock file
                     return 1
                else sadm_write_log "[ OK ] Today export directory created '${MOUNT_POINT}/${VM}'."
             fi 
    fi
    sudo chmod 777 "${MOUNT_POINT}/${VM}" > /dev/null 2>&1


    # Make sure export directory for today exist
    if [ ! -d "$EXPDIR" ]                                               # Today export Dir. Exist?
        then sudo mkdir -p "$EXPDIR" >/dev/null 2>&1
             if [ "$?" -ne 0 ]                                          # If Error creating Dir.
                then sadm_write_err "[ ERROR ] Wasn't able to create directory '$EXPDIR'."
                     sudo umount ${MOUNT_POINT} >>$SADM_LOG 2>&1  
                     sadm_unlock_system "$VM"                           # Go remove the lock file
                     return 1
                else sadm_write_log "[ OK ] New export directory is created '$EXPDIR'."
             fi 
    fi       
    sudo chmod 6777 "$EXPDIR" > /dev/null 2>&1
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then if [ "$VMLIB_DEBUG" = "Y" ] 
                then sadm_write_err "[ ERROR ] 'sudo chmod 6777 $EXPDIR' didn't work."
                else sadm_write_log "[ OK ] 'sudo chmod 6777 $EXPDIR'." 
             fi
    fi    
    
    # Make sure export directory exist, if not create it.
    if [ ! -d "$EXPDIR" ]                                               # Today export Dir. Exist?
        then sudo mkdir -p "$EXPDIR" 
             sadm_write_log "Output directory ${EXPDIR} created."
    fi       
    sudo chmod 6777 "$EXPDIR" > /dev/null 2>&1
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then if [ "$VMLIB_DEBUG" = "Y" ] 
                then sadm_write_err "[ ERROR ] The 'sudo chmod 6777 $EXPDIR' didn't work."
                else sadm_write_log "[ OK ] The 'sudo chmod 6777 $EXPDIR' did work." 
             fi
    fi
    sadm_write_log " "
    sadm_write_log "Starting the export of virtual machine '$VM' to '${SADM_VM_EXPORT_NFS_SERVER}'."
    #sadm_write_log "Export directory is: '$EXPDIR'." 
    sadm_write_log "Export OVA file is : '$EXPOVA'."
    #find "${EXPDIR}" -type d | tee -a $SADM_LOG 

    # Export the selected VM
    #sadm_write_log " "
    sadm_write_log "VBoxManage export '$VM' -o '${EXPOVA}'."
    VBoxManage export $VM -o ${EXPOVA} >>  $SADM_LOG 2>&1 
    if [ $? -ne 0 ]                                                     # If Error Occurred 
       then sadm_write_err "[ ERROR ] doing export of '${VM}' in '$EXPDIR'" 
            RC=1                                                        # Return Error 1 to caller
       else sudo chmod 664 ${EXPOVA} >>$SADM_LOG 2>&1
            if [ "$?" -ne 0 ]                                                   # If Error during mount 
                then sadm_write_err "[ ERROR ] 'sudo chmod 664 ${EXPOVA}' didn't work."
                else sadm_write_log "[ OK ] 'sudo chmod 664 ${EXPOVA}'." 
            fi
            sadm_write_log "[ SUCCESS ] Export of the virtual machine '${VM}'"
            RC=0                                                        # Return Success 0 to caller
    fi 


    # Delete old exports, according to the number of export to keep.
    sadm_write_log " "
    sadm_vm_export_housekeeping "$VM" "${MOUNT_POINT}/${VM}"                # VMName & Dir. to Purge
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_log " "
             sadm_write_err "[ ERROR ] Some error occurred while doing the export cleanup."      
        else sadm_write_log " "
             sadm_write_log "[ OK ] Cleanup done with success." 
    fi

    # Unmount NFS export directory
    cd "$EXP_CUR_PWD"                                                   # Backup Origin Dir.
    sudo umount ${MOUNT_POINT} >>$SADM_LOG 2>&1  
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_err "[ ERROR ] Unmount ${EXPORT_DIR}"      
        else sadm_write_log "[ OK ] Unmount ${EXPORT_DIR}" 
    fi
    
    # Delete temporary dir.
    sadm_write_log "Remove temporary mount point '${MOUNT_POINT}'." 
    sudo rm -fr ${MOUNT_POINT} >>$SADM_LOG 2>&1 
    sadm_write_log " " 

    # If VM was initially running, then power on the VM.
    if [ "$INITIAL_STATE" = "RUNNING" ]                                 # VM Running before export ?
        then sadm_vm_start "$VMNAME"                                    # Yes, then Restart the VM
             if [ $? -ne 0 ] 
                then sadm_unlock_system "$VM"                           # Go remove the lock file
                     return 1                                           # Error Ocurred Set ExitCode
             fi
    fi             
    sleep 4                                                             # Time For last VM to Start
    #sadm_unlock_system "$VM"                                            # Go remove the lock file
    return $RC
}




#===================================================================================================
#
#""" sadm_vm_export_housekeeping
#
#
## sadm_vm_export_housekeeping()
#
#---
#
#
### Synopsys
#`sadm_vm_export_housekeeping [VMName] [export_directory]`
#
### Description
#The [VMName] indicate the virtual machine name and [export_directory] the location of the export directory.
#The value of '**SADM_VM_EXPORT_TO_KEEP**' field is define in the $SADMIN/cfg/sadmin.cfg file.
#It indicate the number of export (date) to keep for the corresponding VM.
#
#
### Argument(s)
#- [1] [vmName] (String)
#       - Contain the name of the virtual machine to export (Required).
#
#- [2] [Export Dir. Name]  (String) (Required)
#       - Specify the name of the export directory.   
#
#
### Value returned
#| Integer | Desciption                            |
#|:-------:|:------------------------------------- |
#| 1       | Error occured when doing the cleanup. |
#| 0       | Cleanup was done with success.        |
#
#   
### Example  
#
#```bash
#Build NFS mount point with data from SADMIN configuration file. 
#LOCAL_DIR="/tmp/nfs.$$"
#NFS_DIR="${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT}"
#   
#sudo mount "$NFS_DIR" "$LOCAL_DIR"
#if [ "$?" -ne 0 ]
#    then sadm_write_err "[ ERROR ] mount $NFS_MOUNT $NFS_DIR"
#         sudo umount "${NFS_DIR}" >/dev/null 2>&1 
#         return 1  
#    else sadm_write_log "[ OK ] NFS Mount worked."
#fi   
#    
#sadm_vm_export_housekeeping "$VM" "${NFS_DIR}/${VM}"    
#if [ "$?" -ne 0 ]                            
#    then sadm_write_err "[ ERROR ] Error doing the export housekeeping of '$VM'."
#    else sadm_write_log "[ SUCCESS ] Export housekeeping of '$VM' done successfully."
#fi   
#
#```
##### Included in "$SADMIN/lib/$SADM_PN"
#   
#"""
#===================================================================================================
sadm_vm_export_housekeeping()
{
    VM=$1                                                               # Name of the VM
    EXPORT_DIR=$2                                                       # Dir. where epuration done

    sadm_write_log " "
    sadm_write_log "Applying chosen retention policy to '$VM' export directory."
    sadm_write_log "Current export directory to clean is $EXPORT_DIR."
    CUR_PWD=$(pwd)                                                      # Save Current Working Dir.
    cd "${EXPORT_DIR}"                                                  # Change Dir. To Export Dir.
    
    #ls -ltrh | while read wline ; do sadm_write_log "${wline}"; done
    #sadm_write_log " "
    #sadm_write_log "We will keep the last $SADM_VM_EXPORT_TO_KEEP date directories of each VM." 
    
    # List Current exports we have and Count Nb. how many we need to delete
    sadm_write_log "List of export currently on disk:"
    #sudo chmod -Rv 664 *.ova
    du -h . | grep -v '@eaDir' | while read ln ;do sadm_write_log "${ln}" ;done

    export_count=$(ls -1| grep -v '@eaDir' | awk -F'-' '{ print $1 }' |sort -r |uniq |wc -l)
    day2del=$(($export_count-$SADM_VM_EXPORT_TO_KEEP))                  # Calc. Nb. Days to remove
    sadm_write_log " "
    sadm_write_log "You specified to keep only the last $SADM_VM_EXPORT_TO_KEEP export(s) of each VM."
    sadm_write_log "You can change this choice by modifying 'SADM_VM_EXPORT_TO_KEEP' in sadmin.cfg."
    sadm_write_log "You currently have $export_count export(s)."        # Show Nb. Backup Days


    # If current number of exports on disk is greater than nb. of export to keep, then cleanup.
    if [ "$export_count" -gt "$SADM_VM_EXPORT_TO_KEEP" ]
        then sadm_write_log "So we need to delete $day2del date directories."
             ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |tail -$day2del > $SADM_TMP_FILE3
             cat $SADM_TMP_FILE3 |while read ln 
                do  sadm_write_log "Deleting ${ln}" 
                    sudo rm -fr ${ln}
                done
             sadm_write_log " "
             sadm_write_log "List of export currently on disk:"
             #ls -1|awk -F'-' '{ print $1 }' |sort -r |uniq |while read ln ;do sadm_write_log "${ln}" ;done
             du -h . | grep -v '@eaDir' | while read ln ;do sadm_write_log "${ln}" ;done
        else sadm_write_log "No clean up needed"
    fi

    # List *.ova in backup directory of the system
    #sadm_write_log " "
    #sadm_write_log "ls -ltrh ${EXPORT_DIR}"
    #ls -ltrh ${EXPORT_DIR} | while read wline ; do sadm_write_log "${wline}"; done

    # Create Line that is used by 'Daily Backup Status' web page to show size of last 2 backup.
    most_recent=$(du -h . | grep -v '@eaDir' | grep "20" | sort -r -k2 | head -1 | awk '{print $1}')
    previous=$(du -h .    | grep -v '@eaDir' | grep "20" | sort -r -k2 | head -2 | tail -1 | awk '{print $1}')
    sadm_write_log " "
    sadm_write_log "current export size  : $most_recent"
    sadm_write_log "previous export size : $previous"

    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    return 0                                                            # Return to caller
}



# --------------------------------------------------------------------------------------------------
# Things to do when first called
# --------------------------------------------------------------------------------------------------

    # If current user is not the VM Owner, exit to O/S with error code 1
    if [ "$(whoami)" != "$SADM_VM_USER" ]                               # If user is not a vbox user 
        then sadm_start 
             sadm_write_err " "
             sadm_write_err "[ ERROR ] Script can only be run by '$SADM_VM_USER' user, not '$(whoami)'."
             sadm_write_err "Process aborted."
             sadm_write_err " "
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Make sure that the VBoxManage is installed on the system.
    which VBoxManage >/dev/null 2>&1
    if [ $? -ne 0 ] 
       then sadm_start 
            sadm_write_err " "
            sadm_write_err "[ ERROR ] It's seem that VirtualBox is not installed on this system." 
            sadm_write_err "[ ERROR ] Could not locate 'VBoxManage' - Process aborted."  
            sadm_write_err " "
            exit 1   
       else export VBOXMANAGE=$(which VBoxManage)                       # Usually /usr/bin/VBoxManage
    fi 
