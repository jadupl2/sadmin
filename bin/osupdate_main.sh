#!/bin/sh
# --------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Linux OS Update script
#   Synopsis:   This script is used to update the Linux OS 
# --------------------------------------------------------------------------
#set -x 
USAGE="Usage:  osupdate_main.sh nodename"

# Mail Address of Sysadmin
# --------------------------------------------------------------------------
SYSADMIN="aixteam@standardlife.ca"

# Check for the first Parameter was Received
# --------------------------------------------------------------------------
if [ $# -ne 1 ]
   then echo -e "\n$USAGE"
        echo -e "The name of the node to update must be specified" 
		exit 1
   else NODE_NAME=$1
fi

# Save Instance Name
# --------------------------------------------------------------------------
INST="linux_os_update.${NODE_NAME}"

# HostName
# --------------------------------------------------------------------------
MYHOST=`hostname -s`

# Cumulative Log Produced to trace Problem
# --------------------------------------------------------------------------
CUMLOG="/var/adsmlog/${INST}.log"
if [ -w "$CUMLOG" ] ; then touch $CUMLOG ;  chmod 664 $CUMLOG ; fi

# Process Log
# --------------------------------------------------------------------------
LOG="/var/adsmlog/${INST}.log"
rm -f $LOG > /dev/null 2>&1
touch $LOG ;  chmod 664 $LOG 

# Log Produced for Operator Backup Monitor
# --------------------------------------------------------------------------
RCLOG="/var/adsmlog/rc.${MYHOST}.${INST}.log"
if [ -w "$RCLOG" ] ; then touch $RCLOG ; chmod 664 $RCLOG ; fi

# SSH Command used to start script on other node
# --------------------------------------------------------------------------
REMOTE_SSH="/usr/bin/ssh -q "







# --------------------------------------------------------------------------
# Validating and Checking for a JobName for the selected node in Storix
# --------------------------------------------------------------------------
select_storix_job()
{
   	echo -e "${DASH}" | tee -a $LOG

# Check if Node is defined as a Storix Client
	echo -e "Check if $NODE_NAME is defined as a Storix client"| tee -a $LOG
   	echo -e "Running \"stclient -l\"" | tee -a $LOG
	stclient -l | tee -a $LOG
   	stclient -l | grep -i $NODE_NAME > /dev/null 2>&1
   	if [ $? -ne 0 ] 
       then echo -e "\nHost $NODE_NAME is not a Storix client"  | tee -a $LOG
	        echo "Job Aborted"  | tee -a $LOG
	        return 1
    fi 
   
# Find the JobName with the Server name in it
	echo -e "Listing Storix Job and grepping for $NODE_NAME" | tee -a $LOG
    echo -e "Running \"stjob -l\"" | tee -a $LOG
    stjob -l | tee -a $LOG
	stjob -l | grep -i $NODE_NAME > /dev/null 2>&1
   	if [ $? -ne 0 ] 
       then echo -e "\nNo JobName in Storix with $NODE_NAME in it" | tee -a $LOG
	        echo "Job Aborted"  | tee -a $LOG
	        return 1
    fi 
	JOBNAME=`stjob -l | grep -i $NODE_NAME` 
	echo "The Job Name Selected is $JOBNAME"  | tee -a $LOG
    return $rc
}




# --------------------------------------------------------------------------
# Running the selected Storix Backup
# --------------------------------------------------------------------------
run_storix_backup()
{

# Submit Job to Storix
   	echo -e "${DASH}" | tee -a $LOG
	echo -e "Submitting Job $JOBNAME to Storix"| tee -a $LOG
   	echo -e "Running \"stqueue -A $JOBNAME\"" | tee -a $LOG
	stqueue -A $JOBNAME  | tee -a $LOG
	if [ $? -ne 0 ] 
       then echo -e "\nError submitting the JOBNAME Job in Storix"| tee -a $LOG
	        echo "Job Aborted"  | tee -a $LOG
	        return 1
	   else echo "Return Code = 0" | tee -a $LOG
    fi 

# Display Info about the Job that is running
	echo "Sleeping 20 seconds to let the Storix Job time to start" | tee -a $LOG 
	sleep 20 # Let the job start
	echo -e "${DASH}"  | tee -a $LOG 
	echo -e "Listing Job running in Storix" | tee -a $LOG
   	echo -e "Running \"stqueue -L\"" | tee -a $LOG
	stqueue -L | tee -a $LOG
	if [ $? -ne 0 ] 
       then echo -e "\nError Listing Storix JOb in Storix"| tee -a $LOG
	        echo "Job Aborted"  | tee -a $LOG
	        return 1
	   else echo "Return Code = 0" | tee -a $LOG
    fi 
    echo "Storix Job $JOBNAME as Started" 
	echo -e "${DASH}" | tee -a $LOG
    return $rc
}



# --------------------------------------------------------------------------
# Monitor rc file until it finished
# --------------------------------------------------------------------------
wait_until_backup_finished()
{

# Just make sure that the RC is there - It should have been created earlier
	RCFILE="/var/adsmlog/rc.${MYHOST}.${JOBNAME}.log" 
	if [ ! -r $RCFILE ] 
	   then echo -e "\nThe Return Code file $RCFILE is not created ?"
	        echo "Job Aborted"  | tee -a $LOG
	        return 1
	fi 

# Loop Until the Storix Backup is finished
	while : 
	    do
		RCCODE=`tail -1 $RCFILE  | awk '{ print $NF }'`
		if [ $RCCODE -eq 2 ] 
		   then echo "At `date` the storix backup still running" 
		        echo "I am sleeping for 1 minute, before checking if backup is finished" 
				sleep 60
		   else echo "At `date` the storix backup is finished" 
		        break
		fi
		done

	return $RCCODE
}




# --------------------------------------------------------------------------
# Make ISO Bootable File
# --------------------------------------------------------------------------
make_iso()
{
    echo -e "${DASH}" | tee -a $LOG
    echo -e "Making ISO on the Node $NODE_NAME" | tee -a $LOG
    #if [ "$NODE_NAME" = "wonhyo" ] ; then WPORT=20022 ; else WPORT=32 ; fi
    WPORT=32 
    MKISO_SCRIPT="/sysadmin/bin/mkcdiso.sh"

    echo -e "$REMOTE_SSH -p $WPORT $NODE_NAME $MKISO_SCRIPT"  | tee -a $LOG
    $REMOTE_SSH -p $WPORT $NODE_NAME $MKISO_SCRIPT
    if [ $? -ne 0 ] 
       then echo -e "\nError trying to make ISO on $NODE_NAME"| tee -a $LOG
            echo "Job Aborted"  | tee -a $LOG
            return 1
       else sleep 120 
            echo "Return Code = 0" | tee -a $LOG
    fi 

    echo -e "${DASH}"  | tee -a $LOG
    echo -e "Running rsync between $NODE_NAME and $MYHOST." | tee -a $LOG
    echo "rsync -t -e 'ssh -p $WPORT' $NODE_NAME:/storix/iso/${NODE_NAME}.iso /install/storix/iso/${NODE_NAME}.iso" | tee -a $LOG
    rsync -t -e "ssh -p $WPORT"       $NODE_NAME:/storix/iso/${NODE_NAME}.iso /install/storix/iso/${NODE_NAME}.iso 2>/dev/null
    if [ $? -ne 0 ] 
        then echo -e "\nError with rsync the ISO on $NODE_NAME"| tee -a $LOG
             echo "Job Aborted"  | tee -a $LOG
	     return 1
	else echo "Return Code = 0" | tee -a $LOG
    fi 
    return 0
}


# --------------------------------------------------------------------------
# Start the up2date script on the node
# --------------------------------------------------------------------------
start_up2date()
{
	echo -e "${DASH}"  | tee -a $LOG
   	echo -e "Starting the osupdate_client.sh script on $NODE_NAME." | tee -a $LOG
    #if [ "$NODE_NAME" = "wonhyo" ] ; then WPORT=20022 ; else WPORT=32 ; fi
    WPORT=32 
	USCRIPT="/sysadmin/bin/osupdate_client.sh"
    echo -e "$REMOTE_SSH -p $WPORT $NODE_NAME $USCRIPT"  | tee -a $LOG
    $REMOTE_SSH -p $WPORT $NODE_NAME $USCRIPT
	if [ $? -ne 0 ] 
       then echo -e "\nError trying to start the $USCRIPT on $NODE_NAME"| tee -a $LOG
	        echo "Job Aborted"  | tee -a $LOG
	        return 1
	   else echo "Return Code = 0" | tee -a $LOG
    fi 
    return 0
}



# --------------------------------------------------------------------------
# Initialize Function - Execute before doing anything
# --------------------------------------------------------------------------
initialization()
{
   	# Feed SLAM about Linux Update Started
   	start=`date "+%C%y.%m.%d %H:%M:%S"`
   	echo "$MYHOST $start ........ $INST 2" >>$RCLOG

   	DASH="========================================"
   	DASH="${DASH}========================================"
   
   	echo -e "${DASH}" >> $LOG
   	echo -e "STARTING UPDATE on ${MYHOST} for $NODE_NAME - ${start}"|tee -a $LOG

   	echo "Ping the selected host $NODE_NAME" 
   	ping -c3 $NODE_NAME 
	if [ $? -ne 0 ] 
            then echo -e "\nError trying to ping the server $NODE_NAME"| tee -a $LOG
	         echo "Job Aborted"  | tee -a $LOG
	         return 1
	    else echo "Return Code = 0" | tee -a $LOG
        fi 
    return 0

}




# --------------------------------------------------------------------------
# End of Process Function
# --------------------------------------------------------------------------
end_of_process()
{
   # Feed Operator Backup Monitor - Backup Failed or completed
   end=`date "+%H:%M:%S"`
   echo "$MYHOST $start $end $INST $RC" >>$RCLOG
   echo "Ended at ${end}" >> $LOG
   echo -e "${DASH}\n" >> $LOG

   # Maintain Backup RC File log at a reasonnable size (100 Records)
   tail -100 $RCLOG > $RCLOG.$$
   rm -f $RCLOG > /dev/null
   mv $RCLOG.$$ $RCLOG
   chmod 666 $RCLOG

   # Maintain Script log at a reasonnable size (5000 Records)
   cat $LOG >> $CUMLOG
   tail -5000 $CUMLOG > $CUMLOG.$$
   rm -f $CUMLOG > /dev/null
   mv $CUMLOG.$$ $LOG
}

# --------------------------------------------------------------------------
# 		S T A R T   O F   M A I N    P R O G R A M 
# --------------------------------------------------------------------------
#
# Check if we are a Sunday - If not exit - Update on only done on Sunday
WDAY=`date +%w` 
#if [ $WDAY -ne 0 ] && [ $WDAY -ne 6 ]
#    then echo "Only run on Saturday or Sunday"
#         exit 0
#fi


# Inform Slam that we are starting
	initialization				

# Select the Storix Job to Run - No Job Then Assume it is a VM
	select_storix_job
	if [ $? -eq 0 ] 
	   then run_storix_backup			 # Running the Storix Backup
	        if [ $? -ne 0 ] ; then exit 1 ; fi
			wait_until_backup_finished   # Wait for storix backup to finish
			if [ $? -ne 0 ] ; then exit 1 ; fi
			#make_iso					 # Make ISO
			#if [ $? -ne 0 ] ; then exit 1 ; fi
	fi

# Start the up2date program on the node
	start_up2date
	RC=$? 

# Inform SLAM about the ending
	end_of_process			

# Inform Email 
	if [ $RC -eq 0 ] 
   	then 
		cat $LOG | mail -s "SUCCESS - Linux OS Updated on $NODE_NAME from $MYHOST" $SYSADMIN
   	else
		cat $LOG | mail -s "FAILED - Linux OS Updated on $NODE_NAME from $MYHOST" $SYSADMIN
        qpage -f $MYHOST sysadmin "Linux Update Failed on $NODE_NAME" 
	fi

exit $RC
