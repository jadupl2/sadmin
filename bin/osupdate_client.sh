#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Linux OS Update script
#   Synopsis:   This script is used to update the Linux OS
#   Update  :   March 2015 -  J.Duplessis
#
# --------------------------------------------------------------------------------------------------
#set -x
#
# --------------------------------------------------------------------------------------------------
#                          Script Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='2.9'                                      ; export VER             # Program version
DEBUG=1                                        ; export DEBUG           # Debug ON (1) or OFF (0)
DASH=`printf %100s |tr " " "="`                ; export DASH            # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
RC=0                                           ; export RC              # Set default Return Code
HOSTNAME=`hostname -s`                         ; export HOSTNAME        # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`   ; export OSNAME          # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                    ; export CUR_DATE        # Current Date
CUR_TIME=`date +"%H_%M_%S"`                    ; export CUR_TIME        # Current Time
CPWD=`pwd`                                     ; export CPWD            # Save Current Working Dir.
#
BASE_DIR="/sadmin"                             ; export BASE_DIR        # Script Root Base Directory
BIN_DIR="$BASE_DIR/bin"                        ; export BIN_DIR         # Script Root binary directory
TMP_DIR="$BASE_DIR/tmp"                        ; export TMP_DIR         # Script Temp directory
LIB_DIR="$BASE_DIR/lib"                        ; export LIB_DIR         # Script Lib directory
LOG_DIR="$BASE_DIR/log"	                       ; export LOG_DIR         # Script log directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"            ; export TMP_FILE1       # Script Tmp File1
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"            ; export TMP_FILE2       # Script Tmp File2
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"            ; export TMP_FILE3       # Script Tmp File3
LOG="${LOG_DIR}/${INST}.log"                   ; export LOG             # Script LOG filename
RCLOG="${LOG_DIR}/rc.${HOSTNAME}.${INST}.log"  ; export RCLOG           # Script Return code filename
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
#
# Determine the Linux Release Version
OSVERSION=7                                                             # Default OS Version to 7
kver=`uname -r| awk -F"." '{ print $1 $2 $3 }'|awk -F"-" '{ print $1 }'` # Get Kernel Version
if [ $kver -eq 3100 ] ; then OSVERSION=7 ; fi                           # OSVersion base on Kernel Ver
if [ $kver -eq 2632 ] ; then OSVERSION=6 ; fi                           # OSVersion base on Kernel Ver
if [ $kver -eq 2618 ] ; then OSVERSION=5 ; fi                           # OSVersion base on Kernel Ver
if [ $kver -eq 269  ] ; then OSVERSION=4 ; fi                           # OSVersion base on Kernel Ver
if [ $kver -eq 2421 ] ; then OSVERSION=3 ; fi                           # OSVersion base on Kernel Ver
if [ $kver -eq 249  ] ; then OSVERSION=2 ; fi                           # OSVersion base on Kernel Ver
export OSVERSION                                                        # Export OS Version

#lsb_release -a | grep -i 'Release:' | awk -F: '{ print $2 }' | awk -F\. '{ print $1 }' | tr -d '\t'

if [ $OSVERSION -gt 4 ] ; then YUM=1 ; else YUM=0 ; fi ; export YUM     # Use yum or up2date ?

SELINUX=`getenforce`                                                    # Get SELINUX Status
if [ "$SELINUX" == "Enforcing" ]
   then USING_SELINUX="Y"
   else USING_SELINUX="N"
fi
export SELINUX USING_SELINUX                                        # Export SELINUX Status


# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log
# --------------------------------------------------------------------------------------------------
write_log()
{
    echo -e "${HOSTNAME} - `date` - $1" >> $LOG
}





# --------------------------------------------------------------------------------------------------
#               Function to list update available before beginning update
# --------------------------------------------------------------------------------------------------
list_available_update()
{
    write_log "Running Listing Available Update before starting it."

    if [ $YUM -eq 0 ]                                               # If not using yum command

        # RHEL 3 & 4 Use up2date
        then write_log "Running \"up2date -l\""
             up2date -l >> $LOG 2>&1                                # List update available
             rc=$?
             write_log "Return Code after up2date -l is $rc"
             case $rc in
                0) UpdateStatus=0                                   # Update Exist
                   write_log "Update may be available (Beside kernel)"
                   ;;
                *) UpdateStatus=2                                   # Problem Abort Update
                   write_log "Error Encountered - Update process aborted"
                   ;;
             esac

        # RHEL 5 and Up Use yum
        else write_log "Running \"yum check-update\""
             yum check-update >> $LOG 2>&1
             rc=$?
             write_log "Return Code after yum check-update is $rc"
             case $rc in
              100) UpdateStatus=0                                   # Update Exist
                   write_log "Update are available"
                   ;;
                0) UpdateStatus=1                                   # No Update available
                   write_log "No Update are available (Beside Kernel)"
                   ;;
                *) UpdateStatus=2                                   # Problem Abort Update
                   write_log "Error Encountered - Update process aborted"
                   ;;
             esac
    fi
    write_log "${DASH}"

    # Return 0=UpdateExist 1=NoUpdate 2=AbortProcess
    return $UpdateStatus
}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with up2date command
# --------------------------------------------------------------------------------------------------
run_up2date()
{
    write_log "Running Update."
    write_log "Running \"up2date --nox -u\""
    up2date --nox -u >>$LOG 2>&1
    rc=$?
    write_log "Return Code after up2date -u is $rc"
    if [ $rc -ne 0 ]
       then write_log "Problem getting list of the update from Satellite server"
            write_log "Update not performed - Processing aborted"
       else write_log "Return Code = 0"
    fi
    write_log "${DASH}"
    return $rc

}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with yum command
# --------------------------------------------------------------------------------------------------
run_yum()
{

    # Make sure kernel update are included in the update process
    grep "^exclude" /etc/yum.conf | grep -i kernel >/dev/null 2>&1
    if [ $? -eq 0 ]
        then    grep -iv "exclude=kernel" /etc/yum.conf > /tmp/yum.$$
                cp /tmp/yum.$$ /etc/yum.conf
                rm -f /tmp/yum.$$
    fi


    # Update yum Command
    write_log "Make sure we have the latest version on yum program"
    write_log "`date`"
    write_log "Running : yum -y update yum"
    # -e0=ErrorLevel -R5=MaxMinute to wait before running (Random)
    yum -y update yum  >>$LOG 2>&1
    rc=$?
    write_log "`date`"
    write_log "Return Code after yum program update is $rc"
    if [ $rc -ne 0 ]
        then    write_log "Processing aborted"
                write_log "${DASH}"
                return $rc
    fi

    # Update server with yum Command
    write_log "`date`"
    write_log  "Running : yum -y update"
    # -e0=ErrorLevel -R10=MaxMinute to wait before running (Random)
    yum -y update  >>$LOG 2>&1
    rc=$?
    write_log "`date`"
    write_log "Return Code after yum program update is $rc"
    write_log "${DASH}"
    return $rc
}




# --------------------------------------------------------------------------------------------------
#                   Initialize Function - Execute before doing anything
# --------------------------------------------------------------------------------------------------
initialization()
{

    # If log Directory doesn't exist, create it.
    if [ ! -d "$LOG_DIR" ]  ; then mkdir -p $LOG_DIR ; chmod 2775 $LOG_DIR ; export LOG_DIR ; fi

    # If TMP Directory doesn't exist, create it.
    if [ ! -d "$TMP_DIR" ]  ; then mkdir -p $TMP_DIR ; chmod 1777 $TMP_DIR ; export TMP_DIR ; fi

    # If LIB Directory doesn't exist, create it.
    if [ ! -d "$LIB_DIR" ]  ; then mkdir -p $LIB_DIR ; chmod 2775 $LIB_DIR ; export LIB_DIR ; fi

    # If log doesn't exist, Create it and Make sure it is writable and that it is empty on startup
    if [ ! -e "$LOG" ]      ; then touch $LOG  ;chmod 664 $LOG  ; export LOG  ;fi
    > $LOG

    # If Return Log doesn't exist, Create it and Make sure it have right permission
    if [ ! -e "$RCLOG" ]    ; then touch $RCLOG ;chmod 664 $RCLOG ; export RCLOG ;fi

    # Write Starting Info in the Log
    write_log "${DASH}"
    write_log "Starting $PN $VER - `date`"
    write_log "${DASH}"

    # Update the Return Code File
    start=`date "+%C%y.%m.%d %H:%M:%S"`
    echo "${HOSTNAME} ${start} ........ ${INST} 2" >>$RCLOG



    write_log "Before starting the Update SELinux is $SELINUX"
    if [ "$USING_SELINUX" == "Y" ]
        then write_log "Disabling the SELInux while the update is going on"
             setenforce 0 >> $LOG 2>&1
             getenforce   >> $LOG 2>&1
    fi

}




# --------------------------------------------------------------------------------------------------
#                                   End of Process Function
# --------------------------------------------------------------------------------------------------
end_of_process()
{
    GLOBAL_ERROR=$1

    # Reactivate SELINUX if it was deactivate at the beginning
    if [ "$USING_SELINUX" == "Y" ]
        then write_log "Enabling SELInux ... "
             setenforce 1 >> $LOG 2>&1
             getenforce >> $LOG 2>&1
    fi



    # Maintain Backup RC File log at a reasonnable size.
    RC_MAX_LINES=100
    write_log "Trimming the rc log file $RCLOG to ${RC_MAX_LINES} lines."
    tail -100 $RCLOG > $RCLOG.$$
    rm -f $RCLOG > /dev/null
    mv $RCLOG.$$ $RCLOG
    chmod 666 $RCLOG

    # Making Sure the return code is 1 or 0 only.
    if [ $GLOBAL_ERROR -ne 0 ] ; then GLOBAL_ERROR=1 ; fi

    # Update the Return Code File
    end=`date "+%H:%M:%S"`
    echo "${HOSTNAME} $start $end $INST $GLOBAL_ERROR" >>$RCLOG

    write_log "${PN} ended at ${end}"
    write_log "${DASH}\n\n\n\n"

    # Maintain Script log at a reasonnable size (5000 Records)
    cat $LOG >> $LOG.$$
    tail -5000 $LOG > $LOG.$$
    rm -f $LOG > /dev/null
    mv $LOG.$$ $LOG

    # Inform by Email if error
    if [ $RC -ne 0 ]
      then cat $LOG | mail -s "${PN} FAILED on ${HOSTNAME} at $end" $SYSADMIN
    fi

    # Delete Temproray files used
    if [ -e "$TMP_FILE1" ] ; then rm -f $TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE2" ] ; then rm -f $TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE3" ] ; then rm -f $TMP_FILE3 >/dev/null 2>&1 ; fi

}

# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    # Inform Slam that we are starting
    initialization

    # Sleep a ramdom number of second to update don't run at exact same time.
    #if ! [ -t ]                             # If not running from terminal
    #   then RANGE=1200 ; SLEEP=$RANDOM ; let "SLEEP %= $RANGE"
    #    echo "Random number less than $RANGE - Sleep $SLEEP seconds"|tee -a $LOG
    #    sleep $SLEEP
    #else echo "Update was launch from command line"|tee -a $LOG
    #fi


    # List update about to take place (Check Connection)
    list_available_update
    if [ $? -ne 0 ]                                                 # No update available
        then    end_of_process 0                                    # Update rc file
                exit 0
    fi

    # Update the Server
    if [ $YUM -eq 0 ] ; then run_up2date ; else run_yum ; fi
    RC=$rc ; export RC

    # Inform SLAM about the ending
    end_of_process $RC

    # Inform UnixAdmin By Email
    if [ $RC -eq 0 ]
        then cat $LOG | mail -s "SUCCESS - Linux OS Updated on $HOSTNAME" $SYSADMIN
        else cat $LOG | mail -s "FAILED - Linux OS Updated on $HOSTNAME"  $SYSADMIN
        #qpage -f $HOSTNAME sysadmin "Linux Update Failed on $HOSTNAME"
    fi
    exit $RC
