#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      rsync Storix Backup from DS410 to Raspi Server
#   Date:       28 August 2015
#   Synopsis:   Once a MOnth Make a copy of current Storix Backup on DS410 to Raspi
# --------------------------------------------------------------------------------------------------
#set -x

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN             # Program name
VER='2.1'                                           ; export VER            # Program version
SYSADMIN="duplessis.jacques@gmail.com"              ; export SYSADMIN       # Sysadmin email
FROM_SERVER="ds410.maison.ca"                       ; export FROM_SERVER    # Source Remote Server
TO_SERVER="raspi.maison.ca"                         ; export TO_SERVER      # Destination Remote Server
SADM_DASH=`printf %60s |tr " " "="`                      ; export SADM_DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST           # Get script name
HOSTNAME=`hostname -s`                              ; export HOSTNAME       # Current Host name
OSTYPE=`uname -s|tr '[:lower:]' '[:upper:]'`        ; export OSTYPE         # Get OS Name AIX/LINUX
CUR_DATE=`date +"%Y_%m_%d"`                         ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                         ; export CUR_TIME       # Current Time
TOTAL_ERROR=0                                       ; export TOTAL_ERROR    # Total Rsync Error
NB_VER=2                                            ; export NB_VER         # Nb Version to keep
#
FROM_BASE_DIR="/volume1/storix"                     ; export FROM_BASE_DIR  # Source Remote Base Dir.
TO_BASE_DIR="/backup/storix"                        ; export TO_BASE_DIR    # Destination Remote Base Dir.
BASE_DIR="/sadmin"                                  ; export BASE_DIR       # Script Root Base Dir
BIN_DIR="$BASE_DIR/bin"                             ; export BIN_DIR        # Script Root Bin Dir
TMP_DIR="$BASE_DIR/tmp"                             ; export TMP_DIR        # Script Temp Dir
LOG_DIR="$BASE_DIR/log"	                            ; export LOG_DIR	    # Script log directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"                 ; export TMP_FILE1      # Script Tmp File1
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"                 ; export TMP_FILE2      # Script Tmp File2
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"                 ; export TMP_FILE3      # Script Tmp File3
LOG_FILE="${LOG_DIR}/${HOSTNAME}_${INST}.log"       ; export LOG_FILE       # Script Log file
LOG_STAT="${LOG_DIR}/rc.${HOSTNAME}_${INST}.log"    ; export LOG_STAT       # Script Log Statistic file

# Local Mount point for NFS
LOCAL_DIR1="/mnt/storix1"                           ; export LOCAL_DIR1
LOCAL_DIR2="/mnt/storix2"                           ; export LOCAL_DIR2


# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log
# --------------------------------------------------------------------------------------------------
sadm_logger()
{
  echo -e $(date "+%C%y.%m.%d %H:%M:%S") - "$@" >> $LOG_FILE
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
    
    # Empty the log and start writing to it
    > $LOG_FILE                                                         # Start a new log
    sadm_logger " "
    sadm_logger " "
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting the script $PN on - ${HOSTNAME}"
    sadm_logger " "
    sadm_logger "${SADM_DASH}"
    
     
    # Make sure Local mount point exist
    if [ ! -d ${LOCAL_DIR1} ] ; then mkdir ${LOCAL_DIR1} ; chmod 775 ${LOCAL_DIR1} ; fi
    if [ ! -d ${LOCAL_DIR2} ] ; then mkdir ${LOCAL_DIR2} ; chmod 775 ${LOCAL_DIR2} ; fi
    
    # Mount the FROM NFS Drive (Source)
    sadm_logger "Mounting the source NFS Drive on $FROM_SERVER"
    sadm_logger "mount ${FROM_SERVER}:${FROM_BASE_DIR} ${LOCAL_DIR1}"
    umount ${LOCAL_DIR1} > /dev/null 2>&1
    mount ${FROM_SERVER}:${FROM_BASE_DIR} ${LOCAL_DIR1} >>$LOG_FILE 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then RC=1
             sadm_logger "Mount NFS Failed from $FROM_SERVER Proces Aborted"
             return 1
    fi
    
    # Mount the TO NFS Drive (Destination)
    sadm_logger "Mounting the destination NFS Drive on $TO_SERVER"
    sadm_logger "mount ${TO_SERVER}:${TO_BASE_DIR} ${LOCAL_DIR2}"
    umount ${LOCAL_DIR2} > /dev/null 2>&1
    mount ${TO_SERVER}:${TO_BASE_DIR} ${LOCAL_DIR2} >>$LOG_FILE 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then RC=1
             sadm_logger "Mount NFS Failed from $TO_SERVER Proces Aborted"
             return 1
    fi
    
    return 0 
}


# --------------------------------------------------------------------------------------------------
#                           End of Process Function
# --------------------------------------------------------------------------------------------------
end_of_process()
{
   RC=$1
   sadm_logger "Unmounting NFS mount directories"
   sadm_logger "umount ${LOCAL_DIR1}"
   umount ${LOCAL_DIR1} >> $LOG_FILE 2>&1
   sadm_logger "umount ${LOCAL_DIR2}"   
   umount ${LOCAL_DIR2} >> $LOG_FILE 2>&1
   
   # Maintain Backup RC File log at a reasonnable size (100 Records)
   sadm_logger " "
   sadm_logger "${SADM_DASH}"
   sadm_logger "Trimming rc log $LOG_STAT"
   tail -100 $LOG_STAT > $LOG_STAT.$$
   rm -f $LOG_STAT > /dev/null
   mv $LOG_STAT.$$ $LOG_STAT
   chmod 666 $LOG_STAT

   # Maintain Script log at a reasonnable size (1000 Records)
   #sadm_logger "Trimming log $LOG_FILE"
   #tail -30000 $LOG_FILE > $LOG_FILE.$$
   #rm -f $LOG_FILE > /dev/null
   #cp $LOG_FILE.$$  $LOG_FILE
   #rm -f $LOG_FILE.$$ > /dev/null 2>&1



   # Feed Operator Backup Monitor - Backup Failed or completed
   end=`date "+%H:%M:%S"`
   echo "$HOSTNAME $start $end $INST $RC" >>$LOG_STAT
   sadm_logger "Ended at ${end}"
   sadm_logger "${SADM_DASH}"
   
   return 
}

# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
# Create log and update result code file
    initialization			            
    if [ $? -ne 0 ] ; then end_of_process 1 ; exit 1 ;fi                # Exit if NFS Problem 

    
# Do the Rsync
    sadm_logger "rsync -var ${LOCAL_DIR1}/ ${LOCAL_DIR2}/"
    #rsync -var ${LOCAL_DIR1}/ ${LOCAL_DIR2}/ >>$LOG_FILE 2>&1
    rsync -vDdLHlr ${LOCAL_DIR1}/ ${LOCAL_DIR2}/ >>$LOG_FILE 2>&1
    RC=$? 
    if [ $RC -ne 0 ]
       then sadm_logger "ERROR NUMBER $RC on rsync "
            RC=1
    fi

    
    # Trim log to 5000 lines and update the script result file
    end_of_process $RC			                                        # Trim Log & Upd. event Log
    
# Send and email to report Success or failure to sysadmin
    if [ $RC -eq 0 ] 
       then cat $LOG_FILE | mail -s "SADM: SUCCESS of $INST on $HOSTNAME" $SYSADMIN
       else cat $LOG_FILE | mail -s "SADM: ERROR with $INST on $HOSTNAME" $SYSADMIN
    fi

