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
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     


#===================================================================================================
# Global Scripts Variables 
#===================================================================================================

# VMTOOLS Configuration file v1.1
# --------------------------------------------------------------------------------------------------
export VMHOST_FILE="$(hostname -s)_vmserver.txt"                        # if exist = VBox Server 
if [ -f "$VMHOST_FILE" ]                                                # Server File exist = VM Use
    then export VBOX_HOST="$(hostname)"                                 # Set VirtualBox Host Name
    else printf "\n${RED}[ ERROR ] This system is not a valid Virtual Box for 'vmtools'${NORMAL}" 
         printf "\nFile '$VMHOST_FILE' don't exist.\n"
         printf "Process aborted.\n\n"                                  # Advise user
         exit 1   
fi 
export VMUSER="jacques"                                                 # User part of vboxusers
export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List

# Default Command Line option variables
export OPT_CONFIRM=true                                                 # No confirmation needed
export OPT_VMNAME=""                                                    # Save VM Name 
export OPT_BACKUP=false                                                 # List VMs Option
export OPT_RUNLIST=false                                                # List Running VMs
export OPT_LIST=false                                                   # List VMs Option
export OPT_START=false                                                  # Start VM Option  
export OPT_STOP=false                                                   # Stop VM Option


# Verify that VBoxManage is available on this system, else abort script.

# Load SADM VirtualBox functions 
export TOOLS_DIR=$(dirname $(realpath "$0"))                            # Dir. Where VM Scripts are
source ${TOOLS_DIR}/sadm_vm_lib.sh                                      # Load VM functions Tool Lib



#export VMUSER="jacques"                                                 # User part of vboxusers
#export VMLIST="$SADM_TMP_FILE1"                                         # List of VM in Virtual Box
#export VMRUNLIST="$SADM_TMP_FILE2"                                      # Running VM List
#export VMNAME=""                                                        # VM Name to Backup 
#export VBOXMANAGE=$(which VBoxManage)                                   # Path to $VBOXMANAGE
#export VBOX_HOST="lestrade.maison.ca"                                       # VirtualBox Host Server
#export NAS_SERVER="batnas.maison.ca"                                    # Backup Server HostName
#export NAS_DIR="/volume1/backup_vm/virtualbox"                          # Backup VM Dir. on NAS 

export CUR_DATE=`date "+%C%y_%m_%d"`                                     # Date Format 2018_05_27
export SADM_VM_EXPORT_TO_KEEP=2                                          # Nb export each VM keep
export VMLIBVER="1.8"




#===================================================================================================
# Check if VM is running 
# (Return 1=Not Running, 0=VM is Running)
#===================================================================================================
sadm_vm_running()
{
    VM=$1 
    if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "Verifying Virtual Machine '$VM' status.\n" ; fi
    $VBOXMANAGE list runningvms | awk -F\" '{ print $2 }' > $VMRUNLIST
    grep "^${VM}" $VMRUNLIST > /dev/null 2>&1 
    if [ $? -eq 0 ] 
       then if [ $SADM_DEBUG -gt 0 ] 
                then sadm_write "${SADM_INFO} Virtual Machine '$VM' is running.\n"
            fi 
            RC=0
       else if [ $SADM_DEBUG -gt 0 ] 
                then sadm_write "${SADM_INFO} Virtual Machine '$VM' isn't running.\n"
            fi 
            RC=1
    fi 
    if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "\nList of running VM :\n" | nl $VMRUNLIST ; fi 
    return $RC
}



#===================================================================================================
# Start the vm received as parameter.
# Returned value : 
#   1 = Error starting vm (vm not started)
#   0 = The vm is started.
#===================================================================================================
sadm_vm_start()
{
    VM=$1 
    sadm_write_log "Starting '$VM' virtual machine "
    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write "Running: $VBOXMANAGE startvm --type headless '$VM'\n"
    fi 
    $VBOXMANAGE startvm --type headless "$VM" >> $SADM_LOG 2>&1
    if [ $? -eq 0 ] 
       then sadm_write_log "The virtual machine is started."
            RC=0
       else sadm_write_log "The virtual machine '$VM' could not be started."
            RC=1
    fi 
    if [ $SADM_DEBUG -gt 0 ] ;then sadm_write_log "\nList of running VM :" ;nl $VMRUNLIST ; fi 
    return $RC
}



#===================================================================================================
# Stop the vm received as parameter.
# Returned value : 
#   1 = Error stopping vm
#   0 = The vm was stop.
#===================================================================================================
sadm_vm_stop()
{
    VM=$1 
    sadm_write "Stopping '$VM' virtual machine.\n"
    sadm_write "Running: $VBOXMANAGE controlvm '$VM' acpipowerbutton\n"
    $VBOXMANAGE controlvm "$VM" acpipowerbutton >> $SADM_LOG 2>&1

    RETRYSEC=15                                                         # Sec. Between Check Running
    POWEROFF="N"                                                        # Change to Y when PowerOFF
    waited=0                                                            # Sec Waited before powerOFF

    # Wait for the shutdown (Poweroff) to complete, wait for $STOP_TIMEOUT sec, then poweroff
    while [ $STOP_TIMEOUT -gt $waited ]                                 # Loop Until Exhaust TimeOut
        do
        printf "${waited}..."  | tee -a $SADM_LOG                       # Indicate Sec. waited
        #sadm_write "${waited}..."                                       # Indicate Sec. waited
        sleep $RETRYSEC                                                 # Wait Shutdown to End
        sadm_vm_running "$VM"                                           # Test if still running
        if [ $? -ne 0 ] ; then POWEROFF="Y" ; break ; fi                # If PowerOFF, Set Y & break 
        waited=$(( $waited + $RETRYSEC ))                               # Inc. Wait Time by RetrySec
        done
    
    # If was able to shutdown VM using 'acpi power button' command, advise user & return to caller.
    if [ "$POWEROFF" = "Y" ]
        then sadm_write_log " " 
             sadm_write_log "[ OK ] Virtual Machine $VM is now poweroff." 
             return 0  
        else sadm_write "\n$STOP_TIMEOUT seconds timeout exceeded.\n"
    fi 

    # OK we waited more than $STOP_TIMEOUT sec. for the shutown to complete, now we poweroff the VM
    sadm_write "Running: $VBOXMANAGE controlvm '$VM' poweroff\n"
    $VBOXMANAGE controlvm "$VM" poweroff

    # Check if it stop after poweroff command 
    sleep 5                     
    sadm_vm_running "$VM"                                               # Check if VM is running 
    if [ $? -eq 0 ]                                                     # VM is Still Running
       then sadm_write "[ ERROR ] The Virtual Machine $VM could not be stopped.\n"
            return 1
       else sadm_write "[ OK ] Virtual Machine $VM is now poweroff.\n" 
            return 0  
    fi 
}




#===================================================================================================
# Check if Virtual Machine Name in in the list of registered machine.
# Returned value : 
#   1 = If VM Doesn't Exist
#   0 = If VM Exist
#===================================================================================================
sadm_vm_exist()
{
    VM=$1                                                               # Save Virtual Machine Name
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_write "Verifying if Virtual Machine '$VM' exist.\n" ;fi
    $VBOXMANAGE list vms | awk -F\" '{ print $2 }' > $VMLIST            # Produce List of Running VM
    grep "^${VM}" $VMLIST > /dev/null 2>&1                              # Is it Part of running VM 
    if [ $? -ne 0 ]                                                     # NOt it's not
       then if [ $SADM_DEBUG -gt 0 ]                                    # Under Debug show Result
                then sadm_write "[ ERROR ] Virtual Machine '$VM' is not registered.\n"
            fi 
            return 1                                                    # Return doesn't exist = 1
       else if [ $SADM_DEBUG -gt 0 ]                                    # Under Debug show Result
                then sadm_write "[ OK ] '$VM' Virtual Machine registered.\n"
            fi 
            return 0                                                    # Return does exist = 0 
    fi 
}



#===================================================================================================
# List the registered VM into file $VMLIST
# Returned value : 
#   1 = Error producing list of registered VM
#   0 = The list was produced successfully
#===================================================================================================
sadm_list_vm()
{
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_write "$VBOXMANAGE list vms | awk -F\" '{ print $2 }'" ;fi
    $VBOXMANAGE list vms | awk -F\" '{ print $2 }' > $VMLIST
    if [ $? -ne 0 ]
       then sadm_write "[ ERROR ] Unable to produce the vm list.\n" 
            return 1 
    fi 
    sadm_write "\n${SADM_BOLD}${SADM_YELLOW}List of registered Virtual machine(s)${SADM_RESET}\n"
    sort $VMLIST | nl | while read wline ; do sadm_write "${wline}\n"; done
    return 0
}




#===================================================================================================
# List the running VM into file $VMRUNLIST
# Returned value : 
#   1 = Error producing list of registered VM
#   0 = The list was produced successfully
#===================================================================================================
sadm_list_vm_running()
{
    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write "$VBOXMANAGE list runningvms | awk -F\" '{ print $2 }'" 
    fi
    $VBOXMANAGE list runningvms | awk -F\" '{ print $2 }' > $VMRUNLIST
    if [ $? -ne 0 ]
       then sadm_write "[ ERROR ] Unable to produce the running vm list.\n" 
            return 1 
    fi 
    sadm_write "\n${SADM_BOLD}${SADM_YELLOW}List of running Virtual machine(s)${SADM_RESET}\n"
    sort $VMRUNLIST | nl | while read wline ; do sadm_write "${wline}\n"; done
    return 0
}




#===================================================================================================
# List Status of the Virtual Box Virtual Machine (Name, Status, UUID)
# Returned value : 
#   1 = Error producing list 
#   0 = The list was produced successfully
#===================================================================================================
sadm_list_vm_status()
{
    # We will use two temp file, make sure they don't exist
    VMTMP1=$(mktemp -u) 
    VMTMP2=$(mktemp -u) 

    sadm_write "\n" 
    $VBOXMANAGE list vms > $VMLIST
    if [ $? -ne 0 ]
       then sadm_write "[ ERROR ] Unable to produce the vm list.\n" 
            return 1 
    fi 

    sort $VMLIST | while read wline
       do 
       #echo "vmline : $wline"
       vm_name=`echo $wline | awk -F\" '{ print $2 }'` 
       vm_uuid=`echo $wline | awk  '{ print $2 }'` 
       vm_stat="poweroff" 
       #echo "newline=${vm_name},${vm_uuid},${vm_stat}"
       echo "${vm_name},${vm_uuid},${vm_stat}" >>$VMTMP1
       done
    
    $VBOXMANAGE list runningvms | sort > $VMRUNLIST
    if [ $? -ne 0 ]
       then sadm_write "[ ERROR ] Unable to produce the running vm list.\n" 
            return 1 
    fi 

    if [ -s "$VMRUNLIST" ] 
        then cat $VMTMP1 | while read wline
                 do 
                 #echo "vmline : $wline"
                 vm_name=`echo $wline | awk -F, '{ print $1 }'` 
                 vm_uuid=`echo $wline | awk -F, '{ print $2 }'` 
                 vm_stat=`echo $wline | awk -F, '{ print $3 }'` 
                 sadm_vm_running "$vm_name"  
                 if [ $? -eq 0 ] 
                    then echo "${vm_name},${vm_uuid},poweron"  >>$VMTMP2
                    else echo "${vm_name},${vm_uuid},poweroff" >>$VMTMP2
                 fi 
                 done
    fi 
    if [ ! -s "$VMTMP2" ] ; then cp $VMTMP1 $VMTMP2 ; fi 

    # Print List Header
    printf "%s" "${SADM_BOLD}${SADM_YELLOW}"                            # Header color (Yellow/Bold)
    printf "%80s\n" |tr " " "="                                         # 80 Dashes Line
    printf "%-4s%-19s%-13s%-8s%-6s%-16s%-s\n" "No" "Name" "State" "Memory" "CPU" "VM IP" "VRDE Port" 
    printf "%80s\n" |tr " " "="                                         # 80 Dashes Line
    printf "%s" "${SADM_RESET}"                                         # Reset Color to Normal
    lineno=0                                                            # Reset to 0 Line Counter
    tpoweron=0                                                          # Reset Total PowerOn 
    tpoweroff=0                                                         # Reset Total PowerOff
    tmemory=0                                                           # Reset Total Memory Alloc.
    while read wline
        do 
        lineno=$((lineno + 1))                                          # Add 1 to Line Counter
        vm_name=`echo $wline | awk -F, '{ print $1 }'` 
        vm_uuid=`echo $wline | awk -F, '{ print $2 }'` 
        vm_stat=`echo $wline | awk -F, '{ print $3 }'` 
        if [ "$vm_stat" = "poweron" ]  ; then tpoweron=$((tpoweron + 1)) ; fi
        if [ "$vm_stat" = "poweroff" ] ; then tpoweroff=$((tpoweroff + 1)) ; fi
        vm_ip=`$VBOXMANAGE guestproperty get "$vm_name" '/VirtualBox/GuestInfo/Net/0/V4/IP' |awk '{print $2}'`
        if [ "$vm_ip" = 'value' ] ; then vm_ip='Not available' ; fi
        vm_mem=`$VBOXMANAGE showvminfo $vm_name |grep 'Memory size'   | awk '{print $3}'`
        vm_num_mem=$(echo "$vm_mem" | sed 's/[A-Za-z]*//g') 
        if [ "$vm_stat" = "poweron" ]  ; then tmemory=$((tmemory + vm_num_mem)) ; fi
        vm_cpu=`$VBOXMANAGE showvminfo $vm_name |grep 'Number of CPU' | awk '{print $4}' | tr -d ' '`
        vrde_state=`$VBOXMANAGE showvminfo $vm_name |grep 'VRDE:'     | awk '{print $2}'`
        if [ "$vrde_state" = "enabled" ]
            then vrde_port=`$VBOXMANAGE showvminfo $vm_name |grep 'VRDE:' |awk '{print $6}' |tr -d ','` 
            else vrde_port='Not enable'
        fi 
        #echo -e "${vm_name}\t\t${vm_stat}\t\t${vm_uuid}"
        printf "%02d  %-18s %-12s %-8s %-4s %-15s %-s\n" "$lineno" "$vm_name" "$vm_stat" "$vm_mem" "$vm_cpu" "$vm_ip" "$vrde_port"
        done < $VMTMP2 

    # Show Total Lines.
    printf "%80s\n" |tr " " "="                                         # 80 Dashes Line
    part1=$(printf "Running VM allocated memory : ${tmemory} MB")
    freemem=$(free -m | grep 'Mem:' | awk '{ print $4 }')
    part2=$(printf "Total Server Free Memory : ${freemem} MB")
    printf "%-40s%40s\n" "$part1" "$part2" 
    printf "%-40s%40s\n" "Total PowerON VM : ${tpoweron}" "Total PowerOFF VM : ${tpoweroff}"
    swap_size=$(free -m | grep "Swap" | awk '{ print $2 }')
    swap_used=$(free -m | grep "Swap" | awk '{ print $3 }')
    swap_pct=$( echo "$swap_used / $swap_size * 100" | bc -l)
    swap_pct=$(printf "%3.1f" "$swap_pct")
    printf "Using %s MB (%s%%) out of the %s MB Swap space.\n" "$swap_used" "$swap_pct" "$swap_size"
    printf "%80s\n" |tr " " "="                                         # 80 Dashes Line
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
    sadm_write_log "Backup of virtual machine '$VM' to ${NAS_SERVER} in progress."
    VM_DIR=$($VBOXMANAGE showvminfo $VM |grep -i snapshot |awk -F: '{print $2}'|tr -d ' '|xargs dirname)

    sadm_write_log "rsync -e 'ssh' -hi -var --no-p --no-g --no-o --delete ${VM_DIR}/ ${NAS_SERVER}:${NAS_DIR}/${VM}/"
    rsync -e 'ssh' -hi -var --no-p --no-g --no-o --delete ${VM_DIR}/ ${NAS_SERVER}:${NAS_DIR}/${VM}/ >>$SADM_LOG 2>&1   
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
    sudo mount ${NAS_SERVER}:${NAS_DIR} ${NFS_DIR} >>$SADM_LOG 2>&1     # Mount Dest. NFS Dir 
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_err "[ ERROR ] mount ${NAS_SERVER}:${NAS_DIR} ${NFS_DIR}"      
             sudo umount ${NFS_DIR} > /dev/null 2>&1                    # Ensure Dest. Dir Unmounted
             return 1                                                   # Set RC to One (Standard)
        else RC=0                                                       # NFS Worked Return Code=0
             sadm_write_log "[ OK ] mount ${NAS_SERVER}:${NAS_DIR} ${NFS_DIR}" 
    fi

    sadm_write_log " " 
    sadm_write_log "List content of $VM backup directory:"
    ls -lhR ${NFS_DIR}/${VM} | while read wline ; do sadm_write "${wline}\n"; done

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
# Export Virtual Machine function 
#   - Parameter received is the name of the VirtualBox machine name to backup 
#   - Returned value : 
#       1 = Error performing the export
#       0 = Export was done with success
#===================================================================================================
sadm_export_vm()
{
    VM="$1"
    sadm_write_log " "
    sadm_write_log "----------"

# Get the name of the directory where the VM exist
    VM_DIR=$($VBOXMANAGE showvminfo $VM |grep -i snapshot |awk -F: '{print $2}'|tr -d ' '|xargs dirname)
    sadm_write_log "The VM '$VM' is currently located in ${VM_DIR} on ${VBOX_HOST}."

# Create export Directory
    if [ ! -d ${NFS_DIR} ] ; then sudo mkdir ${NFS_DIR} ; sudo chmod 777 ${NFS_DIR} ; fi
    sudo umount ${NFS_DIR} > /dev/null 2>&1                             # Make sure it is unmounted 
    
 # Show Usr Mount Dest. Dir 
    if [ $SADM_DEBUG -gt 0 ] ;then sadm_write_log "sudo mount ${NAS_SERVER}:${NAS_DIR} ${NFS_DIR}";fi   
    sudo mount ${NAS_SERVER}:${NAS_DIR} ${NFS_DIR} >>$SADM_LOG 2>&1     # Mount Dest. NFS Dir 
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_err "[ ERROR ] mount ${NAS_SERVER}:${NAS_DIR} ${NFS_DIR}"      
             sudo umount ${NFS_DIR} > /dev/null 2>&1                    # Ensure Dest. Dir Unmounted
             return 1                                                   # Set RC to One (Standard)
        else RC=0                                                       # NFS Worked Return Code=0
             sadm_write_log "[ OK ] mount ${NAS_SERVER}:${NAS_DIR} ${NFS_DIR}" 
    fi

# Make sure the Export directory exist for the server on the NAS
    if [ ! -d "${NFS_DIR}/${VM}" ] ; then sudo mkdir -p "${NFS_DIR}/${VM}"  ; fi
    sudo chmod 777 "${NFS_DIR}/${VM}" > /dev/null 2>&1

# Make sure export directory for today exist
    EXPDIR="${NFS_DIR}/${VM}/${CUR_DATE}"
    EXPOVA="${EXPDIR}/${VM}_$(date +%Y_%m_%d_%H_%M_%S).ova"
    sadm_write_log " "
    sadm_write_log " "
    sadm_write_log "Starting the export of virtual machine '$VM' to ${NAS_SERVER}."
    sadm_write_log "Export file name will be '${EXPOVA}'."
    
    if [ ! -d "$EXPDIR"] ]   ;then sudo mkdir -p "$EXPDIR"  ; fi
    sudo chmod 6777 "$EXPDIR" > /dev/null 2>&1
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then if [ $SADM_DEBUG -gt 0 ] 
                then sadm_write_err "[ ERROR ] The 'sudo chmod 6777 $EXPDIR' didn't work."
                else sadm_write_log "[ OK ] The 'sudo chmod 6777 $EXPDIR' did work." 
             fi
    fi
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_write_log "Output directory ${EXPDIR} created." ; fi
    ls -ld ${EXPDIR} | tee -a $SADM_LOG 

# Export the selected VM
    sadm_write_log " "
    sadm_write_log " "
    sadm_write_log "VBoxManage export $VM -o ${EXPOVA}"
    VBoxManage export $VM -o ${EXPOVA} | tee -a $SADM_LOG 
    if [ $? -ne 0 ]                                                     # If Error Occurred 
       then sadm_write_err "[ ERROR ] doing export of '${VM}' in '$EXPDIR'" 
            RC=1                                                        # Return Error 1 to caller
       else sadm_write_log "[ SUCCESS ] Export of the virtual machine '${VM}'"
            RC=0                                                        # Return Success 0 to caller
    fi 

# Change permission on the .ova created.
    sadm_write_log "sudo chmod 666 ${EXPOVA}"
    sudo chmod 666 ${EXPOVA} >>$SADM_LOG 2>&1
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then if [ $SADM_DEBUG -gt 0 ] 
                then sadm_write_err "[ ERROR ] The 'sudo chmod 664 ${EXPOVA}' didn't work."
                else sadm_write_log "[ OK ] The 'sudo chmod 664 ${EXPOVA}' did work." 
             fi
    fi
    sadm_write_log " "
    sadm_write_log " "

# Delete old exports, according to the number of backup to keep.
    clean_export_dir "$VM"                                              # Purge old exports

# Unmount NFS export directory
    sudo umount ${NFS_DIR} >>$SADM_LOG 2>&1  
    if [ "$?" -ne 0 ]                                                   # If Error during mount 
        then sadm_write_err "[ ERROR ] Unmount ${NFS_DIR}"      
        else sadm_write_log "[ OK ] Unmount ${NFS_DIR}" 
    fi
    
    sudo rm -fr ${NFS_DIR} >>$SADM_LOG 2>&1 
    sadm_write_log " " 
    return $RC
}




# --------------------------------------------------------------------------------------------------
# Keep only the number of export copies specified in $SADM_VM_EXPORT_TO_KEEP
# --------------------------------------------------------------------------------------------------
clean_export_dir()
{
    VM=$1
    EXPORT_DIR="${NFS_DIR}/${VM}"
    TOTAL_ERROR=0                                                       # Reset Total of error
    sadm_write_log " "
    sadm_write_log "Applying chosen retention policy to '$VM' export directory."
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.
    
    ls -ltrh ${EXPORT_DIR} | while read wline ; do sadm_write_log "${wline}"; done
    
    sadm_write_log "We will keep the last $SADM_VM_EXPORT_TO_KEEP date directories of each VM." 
    
    # List Current exports we have and Count Nb. how many we need to delete
    sadm_write_log "List of export currently on disk:"
    cd ${EXPORT_DIR}                                                    # Change Dir. To Export Dir.
    #sudo chmod -Rv 664 *.ova
    du -h . | grep -v '@eaDir' | while read ln ;do sadm_write_log "${ln}" ;done
    export_count=`ls -1| grep -v '@eaDir' | awk -F'-' '{ print $1 }' |sort -r |uniq |wc -l`
    day2del=$(($export_count-$SADM_VM_EXPORT_TO_KEEP))                  # Calc. Nb. Days to remove
    sadm_write_log " "
    sadm_write_log "You have decided to keep only the last $SADM_VM_EXPORT_TO_KEEP export date."
    sadm_write_log "You can change this choice by changing 'SADM_VM_EXPORT_TO_KEEP' in this script."
    sadm_write_log "You now have $export_count export(s)."              # Show Nb. Backup Days

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
    sadm_write_log " "
    sadm_write_log " "
    sadm_write_log "ls -ltrh ${EXPORT_DIR}"
    ls -ltrh ${EXPORT_DIR} | while read wline ; do sadm_write_log "${wline}"; done
    sadm_write_log " "
    sadm_write_log " "

# Create Line that is used by 'Daily Backup Status' web page to show size of last 2 backup.
    most_recent=`du -h . | grep -v '@eaDir' | grep "20" | sort -r -k2 | head -1 | awk '{print $1}'`
    previous=`du -h . | grep -v '@eaDir' | grep "20" | sort -r -k2 | head -2 | tail -1 | awk '{print $1}'`
    sadm_write_log " "
    sadm_write_log "${BID}current backup size : $most_recent"
    sadm_write_log "${BID}previous backup size : $previous"

    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    return 0                                                            # Return to caller
}


