#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Linux OS Update script
#   Synopsis:   This script Read sysinfo file and get the nodename of server that have the
#               O/S Update date equal to the current date.
#               Server got to be active in sysinfo to be considered.
# --------------------------------------------------------------------------------------------------
#set -x




# --------------------------------------------------------------------------------------------------
#                   Program  Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                 ; export PN             # Program name
VER='2.0'                                   ; export VER            # Program version
SYSADMIN="aixteam@standardlife.ca"          ; export SYSADMIN       # sysadmin email
#SYSADMIN="jack.duplessis@standardlife.ca"          ; export SYSADMIN       # sysadmin email
DASH="========================================"                     # 40 dashes
DASH="${DASH}========================================"              # 80 dashes
INST=`echo "$PN" | awk -F\. '{ print $1 }'` ;export INST            # script name
RC=0                                        ; export RC             # Script Return Code
MYHOST=`hostname -s`                        ; export MYHOST         # Host name
LOG="/var/adsmlog/${INST}.log"              ; export LOG            # Script LOG
if [ -w "$LOG" ] ; then touch $LOG ;chmod 664 $LOG ;fi              # Make log writable
RCLOG="/var/adsmlog/rc.${MYHOST}.${INST}.log";export RCLOG          # Slam event log
if [ -w "$RCLOG" ] ; then touch $RCLOG ; chmod 664 $RCLOG ; fi      # Slam event log 
OSNAME=`uname -s`                           ; export OSNAME         # Get OS Name (AIX or Linux)
BASE_DIR="/sysinfo"                         ; export BASE_DIR       # Base Directory of Sysinfo
BASE_BIN="$BASE_DIR/bin"                    ; export BASE_BIN       # BAse binary directory
BASE_LOG="$BASE_DIR/log"                    ; export BASE_LOG       # BAse binary directory
BASE_TMP="$BASE_DIR/tmp"                    ; export BASE_TMP       # BAse Temp  directory
TMP_FILE="${BASE_TMP}/OSUPDATE.$$"          ; export TMP_FILE       # Temp FIle for processing
BIG_LOG="/sysinfo/log/${INST}_big.log"      ; export BIG_LOG        # Script Cumulatvive LOG
EPOCH="${BASE_BIN}/epoch"                   ; export EPOCH          # Epoch Date Calculation Pgm
REMOTE_SSH="/usr/bin/ssh -q "               ; export REMOTE_SSH     # used to start script on node
CUR_DATE=`date +"%Y-%m-%d"`                 ; export CUR_DATE       # Current Date
#CUR_DATE="2013-01-30"                       
MUSER="query"                               ; export MUSER          # MySql User
MPASS="query"                               ; export MPASS          # MySql Password
MHOST="sysinfo.slac.ca"                     ; export MHOST          # Mysql Host
MYSQL="$(which mysql)"                      ; export MYSQL          # Location of mysql program
NODE_NAME=""                                ; export NODE_NAME      # Node Name to process
JOBNAME=""                                  ; export JOBNAME        # Storix JobName
TMP_SAT="$BASE_TMP/SAT.$$"                  ; export TMP_SAT        # Saturday TMP
TMP_SUN="$BASE_TMP/SUN.$$"                  ; export TMP_SUN        # Sunday TMP
MAIL_BODY="$BASE_TMP/BODY.$$"               ; export MAIL_BODY      # MAil body




# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log                        
# --------------------------------------------------------------------------------------------------
write_log()
{
  echo -e "`date` - $1"
  echo -e "`date` - $1" >> $LOG
}



# --------------------------------------------------------------------------------------------------
#        Send email two 2 weeks before the actual update take place
# --------------------------------------------------------------------------------------------------
inform_to_open_changeform()
{
    write_log "Check if update is coming - if so send email"

    # ----------------------------------------------------------------------------------------------
    # Get the Date of the next OS Update Date (Could be a Saturday or Sunday)
    # ----------------------------------------------------------------------------------------------
    SQL1="use sysinfo; SELECT server_os_next_update "
    SQL2="FROM servers where server_os='Linux' and server_active='1' and server_os_update='1' ;"
    SQL="${SQL1}${SQL2}"
    #write_log "Running : $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e $SQL  | sort | uniq | head -1"
    NEXT_UPDATE_DATE1=`$MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL"  | sort | uniq | head -1` 
    
    # Get the Server the will be updated on that DATE
    # ----------------------------------------------------------------------------------------------
    SQL1="use sysinfo; SELECT server_name, server_os_next_update "
    SQL2="FROM servers where server_os_next_update='$NEXT_UPDATE_DATE1' and server_os='Linux' "
    SQL3=" and server_active='1' and server_os_update='1' ;"
    SQL="${SQL1}${SQL2}${SQL3}"
    #write_log "Running : $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e $SQL"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" > $TMP_SAT
    write_log "List of servers that will be update on $NEXT_UPDATE_DATE1"
    cat $TMP_SAT >> $LOG
    
    
    # ----------------------------------------------------------------------------------------------
    # Get the Date of the Second next OS Update Date (Could be a Saturday or a Sunday)
    # ----------------------------------------------------------------------------------------------
    SQL1="use sysinfo; SELECT server_os_next_update "
    SQL2="FROM servers where server_os='Linux' and server_active='1' and server_os_update='1' ;"
    SQL="${SQL1}${SQL2}"
    #write_log "Running : $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e $SQL  | sort | uniq | head -1"
    NEXT_UPDATE_DATE2=`$MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL"  | sort | uniq | head -2 | tail -1` 

    # Get the Server the will be updated on that Saturday
    # ----------------------------------------------------------------------------------------------
    SQL1="use sysinfo; SELECT server_name, server_os_next_update "
    SQL2="FROM servers where server_os_next_update='$NEXT_UPDATE_DATE2' and server_os='Linux' "
    SQL3=" and server_active='1' and server_os_update='1' ;"
    SQL="${SQL1}${SQL2}${SQL3}"
    #write_log "Running : $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e $SQL"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" > $TMP_SUN
    write_log "List of servers that will be update on $NEXT_UPDATE_DATE2"
    cat $TMP_SUN >> $LOG
    
    write_log "The next O/S update will happen on $NEXT_UPDATE_DATE1 and on $NEXT_UPDATE_DATE2"

   
    # Calculate the Epoch of next Update Date
    W1YY=`echo $NEXT_UPDATE_DATE1 | awk -F\- '{ printf "%04d",$1 }'`
    W1MM=`echo $NEXT_UPDATE_DATE1 | awk -F\- '{ printf "%02d",$2 }'` 
    W1DD=`echo $NEXT_UPDATE_DATE1 | awk -F\- '{ printf "%02d",$3 }'`
    W1EPOCH=`$EPOCH "$W1YY $W1MM $W1DD 00 01 00"`
    write_log "The next update on the $NEXT_UPDATE_DATE1 have an epoch time of $W1EPOCH"

    # Date du Lundi MArdi et Mercredi de la semaine avant l'update
    let  "W1EPOCH_MINUS_3DAYS  = $W1EPOCH - 345600"
    MERCREDI1=`$EPOCH -e $W1EPOCH_MINUS_3DAYS -f "%Y-%m-%d"`
    let  "W1EPOCH_MINUS_4DAYS  = $W1EPOCH - 432000"
    MARDI1=`$EPOCH -e $W1EPOCH_MINUS_4DAYS -f "%Y-%m-%d"`
    let  "W1EPOCH_MINUS_5DAYS  = $W1EPOCH - 518400"
    LUNDI1=`$EPOCH -e $W1EPOCH_MINUS_5DAYS -f "%Y-%m-%d"`
    
    # Date du Lundi, Mardi et Mercredi deux semaines avant l'update
    let  "W1EPOCH_MINUS_10DAYS  = $W1EPOCH - 950400"
    MERCREDI2=`$EPOCH -e $W1EPOCH_MINUS_10DAYS -f "%Y-%m-%d"`
    let  "W1EPOCH_MINUS_11DAYS  = $W1EPOCH - 1036800"
    MARDI2=`$EPOCH -e $W1EPOCH_MINUS_11DAYS -f "%Y-%m-%d"`
    let  "W1EPOCH_MINUS_12DAYS  = $W1EPOCH - 1123200"
    LUNDI2=`$EPOCH -e $W1EPOCH_MINUS_12DAYS -f "%Y-%m-%d"`
    
    # Construct the Email that will be sent to SysAdmin
    echo -e "Good Day, " > $MAIL_BODY
    echo -e "\n\tThe next O/S update will happen on the $NEXT_UPDATE_DATE1 and on the ${NEXT_UPDATE_DATE2}." >> $MAIL_BODY
    echo -e "\tThe update process will start at 4am and should finish around noon." >> $MAIL_BODY
    echo -e "\tA new server update is started every 10 minutes." >> $MAIL_BODY
    echo -e  "\tWe Need to open a changeform for the O/S update of the following servers : " >>$MAIL_BODY
    echo -e "\n" >> $MAIL_BODY
    echo  "List of servers that will be updated on $NEXT_UPDATE_DATE1" >>$MAIL_BODY
    cat $TMP_SAT >> $MAIL_BODY
    echo -e "\n" >> $MAIL_BODY
    echo  "List of servers that will be updated on $NEXT_UPDATE_DATE2" >>$MAIL_BODY
    cat $TMP_SUN >> $MAIL_BODY
    echo -e "\nHave a Good Day !" >> $MAIL_BODY
    
    write_log "EPOCH CUR_DATE  = ${CUR_DATE}"
    write_log "EPOCH LUNDI1    = ${LUNDI1}"
    write_log "EPOCH MARDI1    = ${MARDI1}"
    write_log "EPOCH MERCREDI1 = ${MERCREDI1}"
    write_log "EPOCH LUNDI2    = ${LUNDI2}"
    write_log "EPOCH MARDI2    = ${MARDI2}"
    write_log "EPOCH MERCREDI2 = ${MERCREDI2}"
    
    if [ "$CUR_DATE" == "$LUNDI1" ] || [ "$CUR_DATE" == "$MARDI1" ] || [ "$CUR_DATE" == "$MERCREDI1" ] || \
       [ "$CUR_DATE" == "$LUNDI2" ] || [ "$CUR_DATE" == "$MARDI2" ] || [ "$CUR_DATE" == "$MERCREDI2" ] 
        then cat $MAIL_BODY | mail -s "LINUX O/S UPDATE COMING - OPEN CHANGEFORM" $SYSADMIN
    fi
    rm -f $MAIL_BODY $TMP_SAT $TMP_SUN
} 




# --------------------------------------------------------------------------------------------------
#        Checking if node is a Storix Client & if a backup job exist for that client
# --------------------------------------------------------------------------------------------------
check_if_storix_job_exist()
{
    write_log "${DASH}" 

    # Check if Node is a Storix Client
	write_log "Check if $NODE_NAME is defined as a Storix client"
   	write_log "Running \"stclient -l\""
	#stclient -l >> $LOG 2>&1
   	stclient -l | grep -i $NODE_NAME > /dev/null 2>&1
   	if [ $? -ne 0 ] 
       then write_log "Host $NODE_NAME is not a Storix client"
	        write_log "Storix Backup cannot be done - Assume that is it a VM" 
	        return 1
    fi 
   
    # Find the JobName with the Server name in it
	write_log "Listing Storix Job and grepping for $NODE_NAME" 
    write_log "Running \"stjob -l\"" 
    #stjob -l >> $LOG 2>&1
	stjob -l | grep -i $NODE_NAME > /dev/null 2>&1
   	if [ $? -ne 0 ] 
       then write_log "No JobName in Storix with $NODE_NAME in it"
	        write_log "Client is define in Storix - But no Backup Job define - No backup performed"  
	        return 1
    fi 
	JOBNAME=`stjob -l | grep -i $NODE_NAME` 
	write_log "The Storix Job Name Selected is $JOBNAME"
    return $rc
}




# --------------------------------------------------------------------------------------------------
#                   Running the selected Storix Backup for the client
# --------------------------------------------------------------------------------------------------
run_storix_backup()
{

    # Submit Job to Storix
   	write_log "${DASH}"
	write_log "Submitting Job $JOBNAME to Storix"
   	write_log "Running \"stqueue -A $JOBNAME\""
	stqueue -A $JOBNAME  >> $LOG 2>&1
	if [ $? -ne 0 ] 
       then write_log "Error submitting the $JOBNAME Job in Storix"
	        write_log "Storix backup cannot be done ? - Job Aborted"
	        return 1
	   else write_log "Return Code = 0" 
    fi 

    # Display Info about the Job that is running
	write_log "Sleeping 20 seconds to let the Storix Job time to start"
	sleep 20                                                        # Let the job start
	write_log "${DASH}"
	write_log "Listing Job running in Storix"
   	write_log "Running \"stqueue -L\""
	stqueue -L >> $LOG 2>&1
	if [ $? -ne 0 ] 
       then write_log "Error Listing Storix Job in Storix"
	        write_log "Job Aborted" 
	        return 1
	   else write_log "Return Code = 0"
    fi 
    write_log "Storix Job $JOBNAME as Started" 
	write_log "${DASH}"
    return $rc
}



# --------------------------------------------------------------------------------------------------
#                           Monitor rc file until it finished
# --------------------------------------------------------------------------------------------------
wait_until_backup_finished()
{

# Just make sure that the RC is there - It should have been created earlier
	RCFILE="/var/adsmlog/rc.${MYHOST}.${JOBNAME}.log" 
	if [ ! -r $RCFILE ] 
	   then write_log "The Return Code file $RCFILE is not created ?"
	        write_log "Weird ! No choice - Job Aborted" 
	        return 1
	fi 

# Loop Until the Storix Backup is finished
	while : 
	    do
		RCCODE=`tail -1 $RCFILE  | awk '{ print $NF }'`
		if [ $RCCODE -eq 2 ] 
		   then write_log "At `date` the storix backup still running" 
		        write_log "I am sleeping for 1 minute, before checking if backup is finished" 
				sleep 60
		   else write_log "At `date` the storix backup is finished" 
		        break
		fi
		done

	return $RCCODE
}




# --------------------------------------------------------------------------------------------------
#               Initialize Function - Execute before doing anything
# --------------------------------------------------------------------------------------------------
launch_process()
{
    write_log "Check if any O/S Update to be done"
    
    # Prepare SQL to have all Linux servers that are active and that the os_update field is at Yes
    # end that the os_next_update_date is equal to current date
    # ----------------------------------------------------------------------------------------------
    SQL1="use sysinfo; SELECT server_name, server_domain, server_os_next_update "
    SQL2="FROM servers where server_os_next_update='$CUR_DATE' and server_os='Linux' "
    SQL3="and server_active='1' and server_os_update='1' ;"
    SQL="${SQL1}${SQL2}${SQL3}"
    write_log "Running : $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e $SQL >$TMP_FILE"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE

    cat $TMP_FILE | while read wline
        do
        echo "$wline"
        NODE_NAME=`echo $wline|awk '{ print $1 }'`
        wdomain=`echo $wline|awk '{ print $2 }'`
        wdate=`  echo $wline|awk '{ print $3 }'`
        whost="${NODE_NAME}.${wdomain}"
        
        write_log "Processing Node $whost - $wdate"

        # PING THE SERVER - BEFORE DOING ANYTHING
        write_log "Ping the selected host $whost" 
        ping -c3 $whost >> /dev/null 2>&1
        if [ $? -ne 0 ] 
            then write_log "Error trying to ping the server $whost"
                 write_log "Update of server $whost Aborted" 
                 continue
            else write_log "Return Code = 0"
        fi 

        # RUN THE STORIX BACKUP IF NEEDED
        check_if_storix_job_exist                             # If storix Job Exist Return code is 0
        if [ $? -eq 0 ]                                         # Storix Job Exist    
           then run_storix_backup			                    # Start the Storix Backup
                if [ $? -ne 0 ]
                    then write_log "I was uanble to start the Storix backup for $NODE_NAME"
                         write_log "Update of server $NODE_NAME Aborted"
                         continue
         		fi
                wait_until_backup_finished                      # Wait till rc code is not = 2 
        		if [ $? -ne 0 ]                                 # If RC file does not exist, no update
                    then write_log "I was unable to check the rc file for server $NODE_NAME"
                         write_log "Update of server $NODE_NAME Aborted"
                         continue
         		fi
        fi
        
        # START THE OS UPDATE SCRIPT ON THE REMOTE SERVER
        write_log "${DASH}" 
        write_log "Starting the osupdate_client.sh script on $NODE_NAME."
        WPORT=32 
        USCRIPT="/sysadmin/bin/osupdate_client.sh"
        write_log "/usr/bin/ssh -q -p $WPORT $NODE_NAME $USCRIPT"
        echo "/usr/bin/ssh -q -p $WPORT $NODE_NAME $USCRIPT >> $LOG 2>&1" | at now
        if [ $? -ne 0 ] 
           then write_log "Error trying to start the $USCRIPT on $NODE_NAME"
                write_log "Job Aborted" 
                cat $LOG | mail -s "FAILED - Could not launch OS Update on $NODE_NAME from $MYHOST" $SYSADMIN
                #qpage -f $MYHOST sysadmin "Linux Update Failed on $NODE_NAME" 
           else write_log "Return Code = 0" 
        fi
        
        # Sleep 10 minutes before starting another One - Time for Storix Backup (if require) and update.
        write_log "Sleeping 10 minutes betwwen server update ..."
        sleep 600
        done 

    # Feed Operator Backup Monitor - Backup Failed or completed
    end=`date "+%H:%M:%S"`
    echo "$MYHOST $start $end $INST $RC" >>$RCLOG
    write_log "Ended at ${end}"
    write_log "${DASH}" 

    # Maintain Backup RC File log at a reasonnable size (100 Records)
    tail -100 $RCLOG > $RCLOG.$$
    rm -f $RCLOG > /dev/null
    mv $RCLOG.$$ $RCLOG
    chmod 666 $RCLOG
    
    # Maintain Script log at a reasonnable size (5000 Records)
    tail -5000 $LOG > $LOG.$$
    rm -f $LOG > /dev/null
    mv $LOG.$$ $LOG
    rm -f $TMP_FILE
    return 0
}



# --------------------------------------------------------------------------------------------------
# 		            S T A R T   O F   M A I N    P R O G R A M 
# --------------------------------------------------------------------------------------------------
#
    # Feed xSCOM about Linux Update Started
   	start=`date "+%C%y.%m.%d %H:%M:%S"`
   	echo "$MYHOST $start ........ $INST 2" >>$RCLOG
    write_log "\n"
    write_log "${DASH}"
    write_log "$PN $VER - `date`" 
    write_log "${DASH}"

    inform_to_open_changeform
    launch_process
    exit $?
    
