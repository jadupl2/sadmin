#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Sync files from main server to this server
#   Script :    rsync_pull_from_master.sh
#   Date:       15 Fevrier 2014
#   Synopsis:   This script is used to Sync Directory on this server with the MASTER server.
# --------------------------------------------------------------------------------------------------
#
#set -x 

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN 	        # Program name
VER='2.1'                                           ; export VER            # Program version
SYSADMIN="jack.duplessis@standardlife.ca"           ; export SYSADMIN	    # Sysadmin email
MASTER="lxmq0007"                                   ; export MASTER         # Remote Backup Name
DASH=`printf %100s |tr " " "="`                     ; export DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST           # Get Current script name
HOSTNAME=`hostname -s`                              ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`        ; export OSNAME         # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                         ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                         ; export CUR_TIME       # Current Time
TOT_ERR_DIR=0                                       ; export TOT_ERR_DIR    # Total Sync Dir Error 
TOT_ERR_FILE=0                                      ; export TOT_ERR_FILE   # Total Sync File Error 
#
BASE_DIR="/sysadmin"                                ; export BASE_DIR       # Script Root Base Directory
BIN_DIR="$BASE_DIR/bin"                             ; export BIN_DIR        # Script Root binary directory
TMP_DIR="$BASE_DIR/tmp"                             ; export TMP_DIR        # Script Temp  directory
LOG_DIR="/var/adsmlog"	                            ; export LOG_DIR	    # Script log directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"                 ; export TMP_FILE1      # Script Tmp File1 
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"                 ; export TMP_FILE2      # Script Tmp File2
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"                 ; export TMP_FILE3      # Script Tmp File3 
LOG_FILE="${LOG_DIR}/${INST}.log"                   ; export LOG_FILE       # Script Log file
LOG_STAT="${LOG_DIR}/rc.${HOSTNAME}_${INST}.log"    ; export LOG_STAT       # Script Log Statistic file


# Remote Directories on the Master that we need to rsync to Local Directories
# Remote Directory Name and Local Directory Name are separated by a ":"  (Can be Different)
# --------------------------------------------------------------------------------------------------
RSYNC_DIR="/home:/home /os:/os /scom:/scom /storix:/storix /opt:/opt /opt/NAI:/opt/NAI "
RSYNC_DIR="$RSYNC_DIR /sysinfo:/sysinfo /etc/perf:/etc/perf /sysadmin:/sysadmin"
RSYNC_DIR="$RSYNC_DIR /opt/McAfee:/opt/McAfee /install:/install "
#RSYNC_DIR="$RSYNC_DIR /var/adsmlog:/var/adsmlog "
export RSYNC_DIR

# Remote File Name on the Master that we need to rsync to this server
# Remote File Name and Local Directory Name are separated by a ":"  (Can be Different - see crontab)
# --------------------------------------------------------------------------------------------------
RSYNC_FILE="/etc/passwd:/etc/passwd /etc/passwd-:/etc/passwd- "
RSYNC_FILE="$RSYNC_FILE /etc/group:/etc/group    /etc/group-:/etc/group- "
RSYNC_FILE="$RSYNC_FILE /etc/shadow:/etc/shadow  /etc/shadow-:/etc/shadow- "
RSYNC_FILE="$RSYNC_FILE /var/spool/cron/root:/var/spool/cron/root.${MASTER}"        
export RSYNC_FILE


# Base Local Directory 
#   - If Remote Directories will rsync on the same location on this server, then leave it blank
#   - If Remote Directories will rsync not in the location  on this server, then define Root Dir. 
#     Example : If Remote Dir. will be rsync below /backup on this server, then LOCAL_ROOT="/backup"
# --------------------------------------------------------------------------------------------------
LOCAL_ROOT=""                                       ; export LOCAL_ROOT     # Local Root Sync Dir.
LOCAL_ROOT="/backup"                                ; export LOCAL_ROOT     # Local Root Sync Dir.





# --------------------------------------------------------------------------------------------------
#                         Write information into the log                        
# --------------------------------------------------------------------------------------------------
write_log()
{
  echo -e "`date` - $1" >> $LOG_FILE
}


# --------------------------------------------------------------------------------------------------
#             Rsync Local Directory With the one on the Remote (MASTER) Server Function 
# --------------------------------------------------------------------------------------------------
rsync_dir()
{

    # Need to received Remote Input Directory and Local Output Directory
    if [ $# -ne 2 ] 
      then write_log "rsync_dir function need 2 parameters !!!!" 
           write_log "Received only $# - Need Remote Input and Local Output dir" 
           write_log "Values received are $*" 
           return 1
    fi

    IDIR=$1                                                                 # Input Dir. on Remote
    ODIR=$2                                                                 # Output Dir. on Local 

    write_log " " ; write_log " " ;  write_log "${DASH}" 
    write_log "Syncing Directories ${MASTER}:${IDIR} to ${ODIR} ..."
    write_log "${DASH}" 
    CMD="rsync -avrOltD --delete ${MASTER}:${IDIR}/  ${ODIR}/"
    write_log "$CMD"  

    $CMD  >>$LOG_FILE 2>&1
    RC=$?
    if [ $RC -ne 0 ]
         then    write_log "ERROR $RC - Doing $IDIR rsync" 
                 RC=1
         else    write_log "rsync ${MASTER}:$IDIR to $ODIR - OK"
                 RC=0
     fi
    TOT_ERR_DIR=`echo $TOT_ERR_DIR + $RC | bc `                             # Cumulate Error Code
    write_log "Total of Error is $TOT_ERR_DIR"                              # Print out Nb Error
    return $RC                                                              # Return Last Error Code
}


# --------------------------------------------------------------------------------------------------
#             Rsync Local files With the one on the Remote (MASTER) Server Function 
# --------------------------------------------------------------------------------------------------
rsync_file()
{

    # Need to received Remote Input Filename and Local Output FileName
    if [ $# -ne 2 ] 
      then write_log "rsync_file function need 2 parameters !!!!" 
           write_log "Received only $# - Need Remote Input and Local Output filename" 
           write_log "Values received are $*" 
           return 1
    fi

    IFILE=$1                                                                 # Input file on Remote
    OFILE=$2                                                                 # Output file on Local 

    write_log " " ; write_log " " ;  write_log "${DASH}" 
    write_log "Syncing File ${MASTER}:${IFILE} to ${OFILE} ..."
    write_log "${DASH}" 
    CMD="rsync -avrOltD --delete ${MASTER}:${IFILE}  ${OFILE}"
    write_log "$CMD"  

    $CMD  >>$LOG_FILE 2>&1
    RC=$?
    if [ $RC -ne 0 ]
         then    write_log "ERROR $RC - Doing $IFILE rsync" 
                 RC=1
         else    write_log "rsync ${MASTER}:$IFILE to $OFILE - OK"
                 RC=0
     fi
    TOT_ERR_FILE=`echo $TOT_ERR_FILE + $RC | bc `                           # Cumulate Error Code
    write_log "Total of Error is $TOT_ERR_FILE"                             # Print out Nb Error
    return $RC                                                              # Return Last Error Code
}




# --------------------------------------------------------------------------------------------------
#        Perform the rsync with all the directories specified in the RSYNC_DIR Variable
# --------------------------------------------------------------------------------------------------
sync_dir()
{
    write_log " " ; write_log "${DASH}" 
    #write_log "Starting to RSYNC Directories" ; write_log "${DASH}" 
    
    # Rsync the Directories specified in RSYNC_DIR on the remote server
    for WDIR in $RSYNC_DIR                                                 # For every Dir Specified
        do
            REM_DIR=`echo $WDIR | awk -F: '{ print $1 }'`                   # Remote Dir. Name
            LOC_DIR=`echo $WDIR | awk -F: '{ print $2 }'`                   # Local Dir. Name
            rsync_dir "$REM_DIR" "$LOC_DIR"                                 # Let's Sync Dir.
        done
        
    write_log " " ; write_log "${DASH}" 
    write_log "sync_server function total error is $TOT_ERR_DIR" 
    return $TOT_ERR_DIR
}



# --------------------------------------------------------------------------------------------------
#        Perform the rsync with all the files specified in the RSYNC_FILE Variable
# --------------------------------------------------------------------------------------------------
sync_file()
{
    write_log " " ; write_log "${DASH}" 
    #write_log "Starting to RSYNC Files" ; write_log "${DASH}" 
    
    # Rsync the Filename specified in RSYNC_FILE on the remote server
    for WFILE in $RSYNC_FILE                                                # For every Dir Specified
        do
            REM_FILE=`echo $WFILE | awk -F: '{ print $1 }'`                 # Remote Dir. Name
            LOC_FILE=`echo $WFILE | awk -F: '{ print $2 }'`                 # Local Dir. Name
            rsync_file "$REM_FILE" "$LOC_FILE"                              # Let's Sync Dir.
        done
        
    write_log " " ; write_log "${DASH}" 
    write_log "sync_file function total error is $TOT_ERR_DIR" 
    return $TOT_ERR_FILE
}



# --------------------------------------------------------------------------------------------------
#              Ping Master Server to determine it is on-line or not
# --------------------------------------------------------------------------------------------------
check_if_master_is_up()
{
   write_log "ping ${MASTER} ..." 
   ping -c2 $MASTER >> /dev/null 2>&1 
   STAT=$?
   write_log "Return Code after ping is $STAT"
   if [ $STAT -ne 0 ] 
      then write_log "Ping to $MASTER Failed" 
           write_log "Update not performed - Processing aborted" 
           write_log "${DASH}" 
   fi 
   return $STAT
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
    write_log "${DASH}" 
}




# --------------------------------------------------------------------------------------------------
#                           End of Process Function
# --------------------------------------------------------------------------------------------------
end_of_process()
{
   RC=$1
   if [ $RC -gt 0 ] ; then RC=1 ; fi
    
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

   if [ $RC -eq 0 ] 
        then cat $LOG_FILE | mail -s "$INST Script on $HOSTNAME Ran OK"         $SYSADMIN
        else cat $LOG_FILE | mail -s "$INST Script on $HOSTNAME Ran with Error" $SYSADMIN
   fi
}

# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M 
# --------------------------------------------------------------------------------------------------
#
    initialization			                                # Initialize script log 
    check_if_master_is_up                                   # ping succeed to remote server ?
    if [ $? -ne 0 ] ; then exit 1 ; fi                      # Server doesn't respond to ping Abort
    
    sync_dir   		                                        # Sync Directories with Master server
    if [ $? -ne 0 ]                                         # If Error while doing the rsync
        then write_log "Error while syncing Directories"    # Inform User
             RC_DIR=1                                       # Set Rsync Dir Error Flag
        else RC_DIR=0                                       # UnSet Rsync Dir Error Flag    
    fi                      
    
    sync_file  		                                        # Sync files with Master server
    if [ $? -ne 0 ]                                         # If Error while doing the rsync
        then write_log "Error while syncing Files"          # Inform User
             RC_FILE=1                                      # Set Rsync Dir Error Flag
        else RC_FILE=0                                      # UnSet Rsync Dir Error Flag    
    fi                      

    TOTAL_RC=`echo $RC_DIR + $RC_FILE | bc `                # Final Error Code
    end_of_process $TOTAL_RC			                    # Trim Script Log	

