#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Compress directories choosen to backup to /backup in compress tar files (tgz)
#   Date:       28 August 2015
#   Synopsis:   This script is used to create a tgz file of all directories speciied in the 
#		        variable $BACKUP_DIR to $ARCHIVE_DIR .
#	            Only $NB_VER copy of each tgz files will be kept
# --------------------------------------------------------------------------------------------------
#set -x

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN             # Program name
VER='2.1'                                           ; export VER            # Program version
SYSADMIN="duplessis.jacques@gmail.com"              ; export SYSADMIN	    # Sysadmin email
BACK_SERVER="ds410.maison.ca"                       ; export BACK_SERVER    # Remoote Backup Name
SADM_DASH=`printf %60s |tr " " "="`                 ; export SADM_DASH      # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST           # Get script name
HOSTNAME=`hostname -s`                              ; export HOSTNAME       # Current Host name
CUR_DATE=`date +"%Y_%m_%d"`                         ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                         ; export CUR_TIME       # Current Time
TOTAL_ERROR=0                                       ; export TOTAL_ERROR    # Total Rsync Error
NB_VER=7                                            ; export NB_VER         # Nb Version to keep
#
REM_BASE_DIR="/volume1/linux"                       ; export REM_BASE_DIR   # Remote Base Dir.
BASE_DIR="/sadmin"                                  ; export BASE_DIR       # Script Root Base Dir
BIN_DIR="$BASE_DIR/bin"                             ; export BIN_DIR        # Script Root Bin Dir
TMP_DIR="$BASE_DIR/tmp"                             ; export TMP_DIR        # Script Temp Dir
LOG_DIR="$BASE_DIR/log"	                            ; export LOG_DIR	    # Script log directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"                 ; export TMP_FILE1      # Script Tmp File1
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"                 ; export TMP_FILE2      # Script Tmp File2
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"                 ; export TMP_FILE3      # Script Tmp File3
LOG_FILE="${LOG_DIR}/${HOSTNAME}_${INST}.log"       ; export LOG_FILE       # Script Log file
LOG_STAT="${LOG_DIR}/${HOSTNAME}_${INST}.rch"       ; export LOG_STAT       # Script Log Statistic file

# List of Directories to Backup
BACKUP_DIR="/cadmin /sadmin /home /storix /sysadmin /sysinfo /aix_data /gitrepo "
BACKUP_DIR="$BACKUP_DIR /os /www /scom /slam /install /linternux /useradmin /svn /stbackups "
BACKUP_DIR="$BACKUP_DIR /etc /var/adsmlog /var/named /var/www /var/ftp /var/lib/mysql /var/spool/cron "
export BACKUP_DIR

# Directory where the backup files will reside
ARCHIVE_DIR="/linux"                                ; export ARCHIVE_DIR

# Local Mount point for NFS
LOCAL_DIR="/linux"                                  ; export LOCAL_DIR


# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log
# --------------------------------------------------------------------------------------------------
sadm_logger()
{
  echo -e $(date "+%C%y.%m.%d %H:%M:%S") - "$@" >> $LOG_FILE
}




# --------------------------------------------------------------------------------------------------
#        Create Backup Files Main Function - Loop for each file specified in $BACKUP_DIR
# --------------------------------------------------------------------------------------------------
create_backup()
{
    sadm_logger " "
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting the Backup Process"
    sadm_logger "${SADM_DASH}"

    # Save Current Working Directory
    CUR_PWD=`pwd`
    
    for WDIR in $BACKUP_DIR
        do
            if [ -d ${WDIR} ]
            then    cd $WDIR
                    BASE_NAME=`echo "$WDIR" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' `
                    TIME_STAMP=`date "+%C%y_%m_%d_%H_%M_%S"`
                    TGZ_FILE="${BASE_NAME}_${TIME_STAMP}.tgz"
                    sadm_logger "${SADM_DASH}"
                    sadm_logger "Current directory is `pwd`"
                    sadm_logger "tar -cvzf ${ARCHIVE_DIR}/${HOSTNAME}/${TGZ_FILE} ."
                    tar -cvzf ${ARCHIVE_DIR}/${HOSTNAME}/${TGZ_FILE} . >/dev/null 2>&1
                    RC=$?
                    if [ $RC -ne 0 ]
                         then    sadm_logger "RESULT : Error $RC While creating $TGZ_FILE"
                                 RC=1
                         else    sadm_logger "RESULT : Creation of $TGZ_FILE went OK"
                                 RC=0
                    fi
                    TOTAL_ERROR=$(($TOTAL_ERROR+$RC))                   # Total = AIX+Linux Errors
                    sadm_logger "Total of Error is $TOTAL_ERROR"
            else    sadm_logger "Directory ${WDIR} does not exist on $HOSTNAME - Skipped"
            fi
        done
    
    # Restore Current working Directory
    cd $CUR_PWD
    
    sadm_logger " "
    sadm_logger "${SADM_DASH}"
    sadm_logger "Total error(s) while creating the backup are $TOTAL_ERROR"
    return $TOTAL_ERROR
}


# --------------------------------------------------------------------------------------------------
#              Keep only the number of copies specied in $NB_VER
# --------------------------------------------------------------------------------------------------
clean_backup_dir()
{
    sadm_logger " "; sadm_logger " " ; sadm_logger "${SADM_DASH}"
    sadm_logger "Keep only the last $NB_VER copies of each backup in ${ARCHIVE_DIR}/${HOSTNAME}"
    sadm_logger "${SADM_DASH}"    
    TOTAL_ERROR=0
    
    # Save Current Working Directory and Move to Backup Directory
    CUR_PWD=`pwd`
    cd ${ARCHIVE_DIR}/${HOSTNAME}
    sadm_logger "The Current directory is `pwd`"
    sadm_logger " "
    
    for WDIR in $BACKUP_DIR
        do
            if [ -d ${WDIR} ]
                then 
                    BASE_NAME=`echo "$WDIR" | sed -e 's/^\///'| sed -e 's#/$##'| tr -s '/' '_' `
                    TIME_STAMP=`date "+%C%y_%m_%d_%H_%M_%S"`
                    TGZ_FILE="${BASE_NAME}_${TIME_STAMP}.tgz"

                    FILE_COUNT=`ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${NB_VER}d" | wc -l`
                    sadm_logger "${SADM_DASH}"
                    sadm_logger "Number of file(s) to delete in ${WDIR} is $FILE_COUNT"
                    #sadm_logger "${SADM_DASH}"
                    
                    sadm_logger "Here is a list of $BASE_NAME before the cleanup ..."
                    ls -t1 ${BASE_NAME}*.tgz | sort -r | nl >> $LOG_FILE

                    if [ "$FILE_COUNT" -ne 0 ]
                        then    sadm_logger "File(s) Deleted are :"
                                ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${NB_VER}d" >>$LOG_FILE

                                ls -t1 ${BASE_NAME}*.tgz | sort -r | sed "1,${NB_VER}d" | xargs rm -f >> $LOG_FILE 2>&1
                                RC=$?
                                if [ $RC -ne 0 ]
                                     then    sadm_logger "RESULT : Error $RC returned while cleaning up ${BASE_NAME} files"
                                             RC=1
                                     else    sadm_logger "RESULT : Clean up of ${BASE_NAME} went OK"
                                             RC=0
                                fi
                        else    RC=0
                                sadm_logger "RESULT : No file(s) to delete - OK"
                    fi 
                    sadm_logger "Here is a list of $BASE_NAME after the cleanup ..."
                    ls -t1 ${BASE_NAME}*.tgz | sort -r | nl >> $LOG_FILE
                
                    TOTAL_ERROR=`echo $TOTAL_ERROR + $RC | bc `
                    sadm_logger "Total of Error is $TOTAL_ERROR"
            fi
        done
    
    # Restore Current working Directory
    cd $CUR_PWD
    sadm_logger "${SADM_DASH}"    
    sadm_logger "Grand Total of Error is $TOTAL_ERROR"
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
    
    # Empty the log and start writing to it
    > $LOG_FILE                                                         # Start a new log
    sadm_logger " "
    sadm_logger " "
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting the script $PN on - ${MYHOST} - ${start}"
    sadm_logger " "
    sadm_logger "${SADM_DASH}"
    
     
    # Make sure Local mount point exist
    if [ ! -d ${LOCAL_DIR} ]
        then mkdir ${LOCAL_DIR}
             chmod 775 ${LOCAL_DIR}
    fi
    
    # Mount the NFS Drive - Where the TGZ File will reside
    sadm_logger "Mounting NFS Drive on $BACK_SERVER"
    sadm_logger "mount ${BACK_SERVER}:${REM_BASE_DIR} ${ARCHIVE_DIR}"
    umount ${ARCHIVE_DIR} > /dev/null 2>&1
    mount ${BACK_SERVER}:${REM_BASE_DIR} ${ARCHIVE_DIR} >>$LOG_FILE 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then RC=1
             sadm_logger "Mount NFS Failed Proces Aborted"
             return 1
    fi
    
    # Make sure Host directory exist on NFS Drive
    if [ ! -d ${ARCHIVE_DIR}/${HOSTNAME} ]
        then mkdir ${ARCHIVE_DIR}/${HOSTNAME}
             chmod 775 ${ARCHIVE_DIR}/${HOSTNAME}
    fi
    return 0 
}


# --------------------------------------------------------------------------------------------------
#                           End of Process Function
# --------------------------------------------------------------------------------------------------
end_of_process()
{
   RC=$1
   sadm_logger "Unmounting NFS mount directory"
   umount ${ARCHIVE_DIR} >> $LOG_FILE 2>&1
   
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

# Go and create the tgz file in $BACKUP_DIR
    create_backup
    RC=$?
    if [ $RC -ne 0 ] ; then RC=1  ;fi                                   # Make sure error is 0 or 1

# If there were no Errors reported then clean $BACKUP_DIR to Keep only $NB_VER copies of tgz
    #if [ $RC -eq 0 ] ; then clean_backup_dir ; fi
    clean_backup_dir
    
# Trim log to 5000 lines and update the script result file
    end_of_process $RC			                                        # Trim Log & Upd. event Log
    
# Send and email to report Success or failure to sysadmin
    if [ $RC -eq 0 ] 
       then cat $LOG_FILE | mail -s "SADM: SUCCESS of $INST on $HOSTNAME" $SYSADMIN
       else cat $LOG_FILE | mail -s "SADM: ERROR with $INST on $HOSTNAME" $SYSADMIN
    fi

