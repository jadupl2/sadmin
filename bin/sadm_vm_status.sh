#! /usr/bin/env bash

declare -A vm_array                                                     # VM Array
declare -A vm_array=( [centos5]=OFF [centos6]=OFF [centos7]=ON )
export VMLIST="/tmp/vmlist"                                         # List of VM in Virtual Box
export VMRUNLIST="/tmp/vmrunning"                                      # Running VM List

export VMTMP1="/tmp/vm1.tmp"
export VMTMP2="/tmp/vm2.tmp"

VBoxManage list vms | sort > $VMLIST
echo "VMLIST content:"
nl $VMLIST

if [ -f "$VMTMP1" ] ; then rm -f "$VMTMP1" ; fi 
if [ -f "$VMTMP2" ] ; then rm -f "$VMTMP2" ; fi 



cat $VMLIST | while read wline
   do 
   echo "vmline : $wline"
   vm_name=`echo $wline | awk -F\" '{ print $2 }'` 
   vm_uuid=`echo $wline | awk  '{ print $2 }'` 
   vm_stat="poweroff" 
   echo "newline=${vm_name},${vm_uuid},${vm_stat}"
   echo "${vm_name},${vm_uuid},${vm_stat}" >>$VMTMP1
   done

echo "VMTMP1 content:"
nl $VMTMP1




echo ""
echo ""
echo ""
VBoxManage list runningvms | sort > $VMRUNLIST
echo "VMRUNLIST content:"
nl $VMRUNLIST

if [ ! -s "$VMRUNLIST" ] 
    then echo "No VM are running now" 
    else cat $VMTMP1 | while read wline
             do 
             echo "vmline : $wline"
             vm_name=`echo $wline | awk -F, '{ print $1 }'` 
             vm_uuid=`echo $wline | awk -F, '{ print $2 }'` 
             vm_stat=`echo $wline | awk -F, '{ print $3 }'` 
             grep "^\"$vm_name\"" $VMRUNLIST > /dev/null 2>&1
             if [ $? -eq 0 ] 
                then echo "wline=${vm_name},${vm_uuid},poweron"
             fi 
             echo "${vm_line}" >>$VMTMP2
             done
fi 

echo "VMTMP2 content - Status of all vm :"
if [ ! -s "$VMTMP2" ] ; then cp $VMTMP1 $VMTMP2 ; fi 
nl $VMTMP2


#echo "Virtual Box Virtual Machine Status"
printf "%-20s %-12s %-42s\n" "Name" "Status" "VM UUID"
cat $VMTMP1 | while read wline
    do 
    vm_name=`echo $wline | awk -F, '{ print $1 }'` 
    vm_uuid=`echo $wline | awk -F, '{ print $2 }'` 
    vm_stat=`echo $wline | awk -F, '{ print $3 }'` 
    #echo -e "${vm_name}\t\t${vm_stat}\t\t${vm_uuid}"
    printf "%-20s %-12s %-42s\n" "${vm_name}" "${vm_stat}" "${vm_uuid}"
    done


exit 

for vm in `cat $VMLIST`
   do 
   echo "vmname is $vm"
   done

echo "Print all keys"
for key in "${!vm_array[@]}"; do echo $key; done

# print all keys in the same line:
echo " "
echo "All keys on same line : ${!vm_array[@]}"

# printing all the array values at once, you can do so by using the for loop as follows:
echo " "
for val in "${vm_array[@]}"; do echo "Value is : $val" ; done

# The following command will print all values in the same line:
echo " "
echo "${vm_array[@]}"

# print all the key-value pairs at once by using the for loop as follows:
echo " "
for key in "${!vm_array[@]}"; do echo "$key is power ${vm_array[$key]}"; done

# print the number of elements in vm_array
echo " "
echo "Number of elements in the array : ${#vm_array[@]}" 

# Add another VM in the Array
VMNAME=centos8 ; VMSTATUS="OFF"
vm_array+=([${VMNAME}]="$VMSTATUS")

# print all the key-value pairs at once by using the for loop as follows:
echo " "
for key in "${!vm_array[@]}"; do echo "$key is power ${vm_array[$key]}"; done

# print the number of elements in vm_array
echo " "
echo "Number of elements in the array : ${#vm_array[@]}" 

# Delete a key in the Array
#unset vm_array[${VMNAME}]

# Delete the entire Array
#unset vm_array

# Verify if an item is available in Array 
echo " "
if [ ${vm_array[${VMNAME}]+_} ]; then echo "$VMNAME Exists"; else echo "$VMNAME Not available"; fi
VMNAME='centos9'
if [ ${vm_array[${VMNAME}]+_} ]; then echo "$VMNAME Exists"; else echo "$VMNAME Not available"; fi
