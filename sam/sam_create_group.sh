#!/bin/bash
#=============================================================================
# Title      :  sam_create_group
# Version    :  1.5
# Author     :  Jacques Duplessis
# Date       :  2008-01-05
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam.init 1.5 5-Jan-2008
#
#=============================================================================
#
# Description
#   Script is used to create group across our linux systems with the same GID
#
#=============================================================================
trap 'exit 0' 2   # INTERCEPTE LE ^C




#=============================================================================
#                  V A R I A B L E S      D E F I N I T I O N S
#=============================================================================
rhosts=/install/storix/.rhosts
rhosts=/sysadmin/cfg/linux_servers.txt
wfile="/tmp/create.$$"
NEXT_GID=0                          # contain the next GID available
CURRENT_GID=0                       # contain the current group GID if exist

# Declare Host to create group array
declare -a host_array



#=============================================================================
#            scans all machines for the next available gid
#        output: 0 if success, 1 if unable to contact all machines
#=============================================================================
get_next_id()
{
	echo "Establishing the next GID available"

# Initialize Host Array - Assume no for all hosts
    windex=0
	for host in `cat $rhosts | awk '{print $1}'`
     	do
        host_array[$windex]="${host},N"
        let "windex+=1"
	    done

	NEXT_GID=0  ; largest_gid=0 ;
    
	for host in `cat $rhosts|awk '{print $1}'`
    	do
		PORT=32
		echo -n "."
		#echo "Getting biggest Group ID from $host on port $PORT" 

		#echo "ssh -p $PORT $host grep -v 65534 /etc/group 2>/dev/null | awk -F: '{ print \$3 }' | sort -n | tail -1"
		WGID=`ssh -p $PORT $host grep -v nobody /etc/group 2>/dev/null |awk -F: '{ print $3 }' |sort -n |tail -1`
		#echo "LARGEST on $host is $WGID" 

		if [ -z $WGID ]
		   then echo "Unable to get largest gid from host ($host)"
		        WGID=1
		fi

		if [ $WGID -gt 10000 ] ; then WGID=1 ; fi
		if [ $WGID -gt $NEXT_GID ] ; then NEXT_GID=$WGID ; fi
	    done
	    
	let NEXT_GID=NEXT_GID+1
    echo -e "\nThe next system group ID available is \"${bold}${NEXT_GID}${nrm}\"."
	return 0
}



#=============================================================================
# check for a group on all hosts - return 0 found, 1 not found
#=============================================================================
check_for_group()
{
# Set the group to check
	grp=$1
	echo "Searching for system group \"${bold}${grp}${nrm}\" in the linux farm"

# Set array index to 0
    windex=0

# Assume the group was not found on any server
    ret_val=0

# Loop and grep /etc/group on every servers in the farm
	for host in `awk '{print $1}' $rhosts`
    	do
		PORT=32 
		echo -n "."
		CURRENT_GID=`ssh -p ${PORT} ${host} grep -i "^${grp}:" /etc/group 2>/dev/null | awk -F: '{ print $3 }'`
		if [ ! -z "$CURRENT_GID" ]   # Group exist
		   then NEXT_GID=$CURRENT_GID
                host_array[$windex]="${host},X"
			    ret_val=1
           else host_array[$windex]="${host},N"
		fi
        let "windex+=1"
	    done
	
	# Advise user that the system group was not found
	if [ $ret_val -eq 0 ]
	   then echo -e "\nSystem group $group was not found on any systems."
	   else echo -e "\nSystem group $group exist on some system(s) and have the \"${bold}${NEXT_GID}${nrm}\"."
	fi
	return $ret_val
}



#=============================================================================
# Create the group on the selected server
#=============================================================================
create_group()
{
	grp=$1
	gid=$2
    windex=0

   while [ $windex -lt ${#host_array[@]} ]
      do
      WHOST=`echo "${host_array[$windex]}"|awk -F, '{ print $1 }'|awk -F'.' '{ print $1 }'`
      WACTION=`echo "${host_array[$windex]}"| awk -F, '{ print $2 }'`
      if [ "$WACTION" = "Y" ] 
         then PORT=32 
		      echo -n "ssh -p $PORT $WHOST /usr/sbin/groupadd -g $gid $grp " 
		      ssh -p $PORT $WHOST "/usr/sbin/groupadd -g $gid $group"
              if [ $? -ne 0 ] 
                 then echo " ERROR"
                      mess "Error creating group $group on $WHOST." 
                 else echo " OK"
              fi 
      fi
      let "windex+=1"
      done
      mess "Group is now created on the host(s)."
}


#=============================================================================
# Display Host Array
#=============================================================================
display_host_array()
{
    windex=0 ; wcount=0
    while [ $windex -lt ${#host_array[@]} ]
      do
      WHOST=`echo "${host_array[$windex]}"|awk -F, '{ print $1 }'|awk -F'.' '{ print $1 }'`
	  WACTION=`echo "${host_array[$windex]}"| awk -F, '{ print $2 }'`
	  printf "%02d %-011s %1s  | " ${windex} ${WHOST} ${WACTION}
	  let "windex+=1"; let "wcount+=1"
	  if [ $wcount -eq 4 ] ; then wcount=0; printf "\n" ; fi
	  done
}



#=============================================================================
# Group creation function
#=============================================================================
edit_host_array()
{

# Edit Host Array
    max_index=`expr ${#host_array[@]} - 1`
    while :
        do
        dline="${rvs}No Hostname   Y/N | No Hostname   Y/N | No Hostname   Y/N | No Hostname   Y/N | ${nrm}" 
        writexy 10 01 "$clreos" ; echo "$dline" 
        display_host_array
        echo -en  "\n${rvs}Enter number of the node you wish to create the group (q=quit, p=proceed) : ${nrm}"
        read ans
	    if [ "$ans" = "q"  -o  "$ans" = "Q" ] ; then retval=0; break ; fi
	    if [ "$ans" = "p"  -o  "$ans" = "P" ] ; then retval=1; break ; fi
        if [ "$ans" -gt $max_index ] 
           then mess "Number specified is invalid" 
           else WHOST=`  echo "${host_array[$ans]}"| awk -F, '{ print $1 }'| awk -F'.' '{ print $1 }'`
                WACTION=`echo "${host_array[$ans]}"| awk -F, '{ print $2 }'`
                if [ "$WACTION" = "X" ] 
                   then mess "Group already created on that $WHOST server" 
                   else if [ "$WACTION" = "N"  ]
                           then host_array[$ans]="${WHOST},Y"
                           else host_array[$ans]="${WHOST},N"
                        fi
                fi
        fi
        done
    return $retval
}





#=============================================================================
# This is where the program begins
#=============================================================================

# Verify that system .rhost file exist - If not terminate the script
    #if [ ! -r /install/storix/.rhosts ] 
    if [ ! -r /sysadmin/cfg/linux_servers.txt ] 
       then mess "Process Aborted - The file $rhosts is not found !"
            return
    fi

# This script can only be run from the linux management server (lxmq0007)
    if [ `hostname` != "$CREATE_GROUP_NODE" ] 
       then mess "The System Group creation can only be run from $CREATE_GROUP_NODE" 
            return
    fi


# Loop until Quit is choosen
    group=""
    while :
    	do
        display_entete "Group Creation Screen"
        writexy 05 08 "1- Name of the group to create ....: $group"
        writexy 10 08 "P- Proceed with group creation......"
        writexy 11 08 "Q- Quit this menu..................."
        writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        writexy 21 38 " "
        read option
        case $option in
            1 ) accept_data 05 45 30 A $group
                group=$WDATA
                ;;
              
          p|P ) if [ -z $group ] 
                   then mess "You need to specify the system group first"
                   else messok 22 01 "Proceed with server scanning for next GID"
                        if [ "$?" = "1" ]
                           then display_entete "System Group Process"
                                check_for_group $group
                                RC=$?                # 1=found 0=not found
                                if [ "$RC" -eq 1 ]   # Group was found
                                   then edit_host_array 
                                        RC=$?    # 0=Quit 1=Proceed
                                        if [ "$RC" -eq 1 ] ; then create_group $group $NEXT_GID ;fi
                                   else get_next_id
								        let NEXT_GID=NEXT_GID+1
                                        #echo "waiting for enter GID = $NEXT_GID"  ; read dummy
                                        edit_host_array
                                        RC=$?    # 0=Quit 1=Proceed
										 
                                        if [ "$RC" -eq 1 ] ; then create_group $group $NEXT_GID ;fi
        	                    fi 
                        fi
                fi
                ;;

          q|Q ) break
                ;;
        esac
        done
