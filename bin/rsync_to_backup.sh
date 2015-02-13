#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Sync files from main server to backup server
#   Date:       15 Fevrier 2014
#   Synopsis:   This script is used to create a copy of the files needed
#	        for this server to become the proxy in case 1616 is down.
#               All filesystems needed to be replicated are done in
#               this script.
# --------------------------------------------------------------------------------------------------
#set -x 

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN 	        # Program name
VER='1.8'                                           ; export VER            # Program version
SYSADMIN="duplessis.jacques@gmail.com"              ; export SYSADMIN	    # Sysadmin email
BACK_SERVER="raspi.maison.ca"                       ; export BACK_SERVER    # Remoote Backup Name
DASH=`printf %100s |tr " " "="`                     ; export DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST           # Get Current script name
HOSTNAME=`hostname -s`                              ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`        ; export OSNAME         # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                         ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                         ; export CUR_TIME       # Current Time
TOTAL_ERROR=0                                       ; export TOTAL_ERROR    # Total Rsync Error 
#
REM_BASE_DIR="/backup"                              ; export REM_BASE_DIR   # Backup Server Base Dir. 
BASE_DIR="/sadmin"                                  ; export BASE_DIR       # Script Root Base Directory
BIN_DIR="$BASE_DIR/bin"                             ; export BIN_DIR        # Script Root binary directory
TMP_DIR="$BASE_DIR/tmp"                             ; export TMP_DIR        # Script Temp  directory
LOG_DIR="$BASE_DIR/log"	                            ; export LOG_DIR	    # Script log directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"                 ; export TMP_FILE1      # Script Tmp File1 
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"                 ; export TMP_FILE2      # Script Tmp File2
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"                 ; export TMP_FILE3      # Script Tmp File3 
LOG_FILE="${LOG_DIR}/${HOSTNAME}_${INST}.log"       ; export LOG_FILE       # Script Log file
LOG_STAT="${LOG_DIR}/${HOSTNAME}_${INST}_stat.log"  ; export LOG_STAT       # Script Log Statistic file

# List of Directories to Backup
BACKUP_DIR="/cadmin /sadmin /home /storix /sysadmin /sysinfo /aix_data /archive"
BACKUP_DIR="$BACKUP_DIR /os /www /scom /slam /install /linternux /useradmin /svn /stbackups"
BACKUP_DIR="$BACKUP_DIR /etc /var /boot" 
export BACKUP_DIR

# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log                        
# --------------------------------------------------------------------------------------------------
write_log()
{
  echo -e "`date` - $1" >> $LOG_FILE
}


# --------------------------------------------------------------------------------------------------
#                                   Rsync Directory Function 
# --------------------------------------------------------------------------------------------------
rsync_dir()
{

# Need to received Remote Input Directory and Local Output Directory
    if [ $# -ne 2 ] 
      then write_log "rsync_dir function need 2 parameters !!!!" 
           write_log "Received only $# - Need input and output dir" 
           write_log "Values received are $*" 
           return 1
    fi

    IDIR=$1  # Input Directory on local system
    ODIR=$2  # Output Directory on remote system

    write_log " "
    write_log " "
    write_log "${DASH}" 
    write_log "Syncing Directories ${IDIR} to ${ODIR} ..."
    write_log "${DASH}" 
    #CMD="rsync -vrOltD --stats --delete  ${IDIR}/ ${BACK_SERVER}:${ODIR}/ "
    CMD="rsync -vrOltD --delete  ${IDIR}/ ${BACK_SERVER}:${ODIR}/ "
    write_log "$CMD"  

    $CMD  >>$LOG_FILE 2>&1
    RC=$?
    if [ $RC -ne 0 ]
         then    write_log "ERROR $RC - Doing $IDIR rsync" 
                 RC=1
         else    write_log "rsync $IDIR to $ODIR - OK"
                 RC=0
     fi
    TOTAL_ERROR=`echo $TOTAL_ERROR + $RC | bc `
    write_log "Total of Error is $TOTAL_ERROR"
    return $RC
}


# --------------------------------------------------------------------------------------------------
#              Ping Backup Server to determine it is online or not
# --------------------------------------------------------------------------------------------------
backup_server_is_up()
{
   write_log "ping ${BACK_SERVER} ..." 
   ping -c2 $BACK_SERVER >> /dev/null 2>&1 
   STAT=$?
   write_log "Return Code after ping is $STAT"
   if [ $STAT -ne 0 ] 
      then write_log "Ping to $BACK_SERVER Failed" 
           write_log "Update not performed - Processing aborted" 
           write_log "${DASH}" 
   fi 
   return $STAT
}



# --------------------------------------------------------------------------------------------------
#        Get DNS FILE FROM MASTER DNS AND PUT THEM IN /ETC/NAMED.MASTER
# --------------------------------------------------------------------------------------------------
sync_server()
{
    write_log " "
    write_log "${DASH}" 
    write_log "RSYNC Directories"
    write_log "${DASH}" 
    
    # Rsync the Directories specified in BACKUP_DIR on the remote server
    for WDIR in $BACKUP_DIR
        do
           DDIR="${REM_BASE_DIR}/${HOSTNAME}${WDIR}"                        # Destination Dir.
           rsync_dir $WDIR $DDIR                                            # Let's Sync Dir.
        done
        
    write_log " "
    write_log "${DASH}" 
    write_log "sync_server function total error is $TOTAL_ERROR" 
    return $TOTAL_ERROR
}


# --------------------------------------------------------------------------------------------------
#              Initialize Function - Execute before doing anything
# --------------------------------------------------------------------------------------------------
initialization()
{

    # Make sure Base Directories Exist
    if [ ! -d "$BIN_DIR" ] ; then mkdir -p ${BIN_DIR} ; chmod 750 ${BIN_DIR} ; fi
    if [ ! -d "$TMP_DIR" ] ; then mkdir -p ${TMP_DIR} ; chmod 750 ${TMP_DIR} ; fi
    if [ ! -d "$LOG_DIR" ] ; then mkdir -p ${LOG_DIR} ; chmod 750 ${LOG_DIR} ; fi

    # Feed SLAM about Linux Update Started
    start=`date "+%C%y.%m.%d %H:%M:%S"`
    echo "$HOSTNAME $start ........ $INST 2" >>$LOG_STAT
    write_log " " 
    write_log " " 
    write_log "${DASH}" 
    write_log "Starting the script $PN on - ${MYHOST} - ${start}"  
    write_log " " 
    write_log "${DASH}" 
}




# --------------------------------------------------------------------------------------------------
#                           End of Process Function
# --------------------------------------------------------------------------------------------------
end_of_process()
{
   RC=$1

   # Maintain Backup RC File log at a reasonnable size (100 Records)
   write_log "${DASH}" 
   write_log "${DASH}" 
   write_log "Trimming rc log $LOG_STAT"
   tail -100 $LOG_STAT > $LOG_STAT.$$
   rm -f $LOG_STAT > /dev/null
   mv $LOG_STAT.$$ $LOG_STAT
   chmod 666 $LOG_STAT

   # Maintain Script log at a reasonnable size (1000 Records)
   write_log "Trimming log $LOG_FILE" 
   tail -5000 $LOG_FILE > $LOG_FILE.$$
   rm -f $LOG_FILE > /dev/null
   cp $LOG_FILE.$$  $LOG_FILE
   rm -f $LOG_FILE.$$ > /dev/null 2>&1

   # Feed Operator Backup Monitor - Backup Failed or completed
   end=`date "+%H:%M:%S"`
   echo "$HOSTNAME $start $end $INST $RC" >>$LOG_STAT
   write_log "Ended at ${end}" 
   write_log "${DASH}" 

#    if [ $RC -eq 0 ] 
#        then cat $LOG | mail -s "$INST Script on $HOSTNAME Ran OK"         $SYSADMIN
#        else cat $LOG | mail -s "$INST Script on $HOSTNAME Ran with Error" $SYSADMIN
#    fi
}

# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M 
# --------------------------------------------------------------------------------------------------
#
    initialization			                                                # Update Slam Event log 
    backup_server_is_up                                                     # ping succeed to remote server ?
    if [ $? -eq 0 ]                                                         # If Server respond to ping sync it
        then sync_server		                                            # Sync with Backup server
             RC=$?                                                          # Sync Function Error code
    fi  
    if [ $RC -ne 0 ] ; then RC=1  ;fi                                       # Make sure error is 0 or 1
    end_of_process $RC			                                            # Trim Log and Update SLAM event Log	

