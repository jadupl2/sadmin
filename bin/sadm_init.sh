#! /bin/bash
#===================================================================================================
# Title      :  sam.init - sam initialization script
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  2005-01-06
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sadm.init 1.0 March 2015
#===================================================================================================
#
# Description
# This file is not a stand-alone shell script; it provides functions
# to sadm scripts that source it.
# --------------------------------------------------------------------------------------------------
#
#===================================================================================================
trap 'exit 0' 2   # INTERCEPTE LE ^C

#set -x


# --------------------------------------------------------------------------------------------------
#                             V A R I A B L E S      D E F I N I T I O N S
# --------------------------------------------------------------------------------------------------
SYSADMIN="duplessis.jacques@gmail.com"          ; export SYSADMIN       # sysadmin email
HOSTNAME=`hostname -s`                          ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`    ; export OSNAME         # Get OS Name (AIX or LINUX)
DASH=`printf %60s |tr " " "="`                  ; export DASH           # 60 dashes line
#
BIN_DIR="$BASE_DIR/bin"                         ; export BIN_DIR        # Script Root binary directory
TMP_DIR="$BASE_DIR/tmp"                         ; export TMP_DIR        # Script Temp  directory
LIB_DIR="$BASE_DIR/lib"                         ; export LIB_DIR        # Script Lib directory
LOG_DIR="$BASE_DIR/log"	                        ; export LOG_DIR	    # Script log directory
EPOCH="${BASE_DIR}/bin/sadm_epoch"              ; export EPOCH          # Location of epoch pgm.
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"             ; export TMP_FILE1      # Script Tmp File1 for processing
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"             ; export TMP_FILE2      # Script Tmp File2 for processing
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"             ; export TMP_FILE3      # Script Tmp File3 for processing
LOG="${LOG_DIR}/${INST}.log"                    ; export LOG            # Script Output LOG filename
ELOG="${LOG_DIR}/${INST}_error.log"             ; export ELOG           # Script Error  LOG filename
RCLOG="${LOG_DIR}/rc.${HOSTNAME}.${INST}.log"   ; export RCLOG          # Script Return code filename
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



# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log
# --------------------------------------------------------------------------------------------------
#
write_log()
{
    case "$OUTPUT2" in
      [0] )     echo -e $(date "+%C%y.%m.%d %H:%M:%S") - "$@" >> $LOG
                ;;
      [1] )     echo -e $(date "+%C%y.%m.%d %H:%M:%S") - "$@" >> $LOG
                echo -e $(date "+%C%y.%m.%d %H:%M:%S") - "$@"
                ;;
    esac
}


# --------------------------------------------------------------------------------------------------
#                        Convert String Received to Uppercase
# --------------------------------------------------------------------------------------------------
#
toupper()
{
    echo $1 | tr  "[:lower:]" "[:upper:]"
}


# --------------------------------------------------------------------------------------------------
#                       Convert String Received to lowercase
# --------------------------------------------------------------------------------------------------
#
tolower()
{
    echo $1 | tr  "[:upper:]" "[:lower:]"
}



# --------------------------------------------------------------------------------------------------
#                   SADM Initialize Function - Execute before doing anything
# --------------------------------------------------------------------------------------------------
#
sadm_start()
{
    # If log Directory doesn't exist, create it.
    if [ ! -d "$LOG_DIR" ]  ; then mkdir -p $LOG_DIR ; chmod 2775 $LOG_DIR ; export LOG_DIR ; fi

    # If TMP Directory doesn't exist, create it.
    if [ ! -d "$TMP_DIR" ]  ; then mkdir -p $TMP_DIR ; chmod 1777 $TMP_DIR ; export TMP_DIR ; fi

    # If LIB Directory doesn't exist, create it.
    if [ ! -d "$LIB_DIR" ]  ; then mkdir -p $LIB_DIR ; chmod 2775 $LIB_DIR ; export LIB_DIR ; fi

    # If log doesn't exist, Create it and Make it writable and that it is empty on startup
    if [ ! -e "$LOG" ]      ; then touch $LOG  ;chmod 664 $LOG  ;fi
    > $LOG

    # If Error log doesn't exist, Create it & Make it writable and that it is empty on startup
    if [ ! -e "$ELOG" ]     ; then touch $ELOG  ;chmod 664 $ELOG  ; fi
    > $ELOG

    # If Return Log doesn't exist, Create it and Make sure it have right permission
    if [ ! -e "$RCLOG" ]    ; then touch $RCLOG ;chmod 664 $RCLOG ; export RCLOG ;fi

    if [ -e "${TMP_DIR}/${INST}" ]
       then write_log "Script is already running ..."
            write_log "PID File ${TMP_DIR}/${INST} exist ..."
            exit 1
       else echo "$TPID" > ${TMP_DIR}/${INST}.pid
    fi

    # Write Starting Info in the Log
    write_log "${DASH}"
    write_log "Starting ${PN} version ${VER} on ${HOSTNAME} ..."
    write_log "${DASH}"

    start=`date "+%C%y.%m.%d %H:%M:%S"`
    echo "${HOSTNAME} ${start} ........ ${INST} 2" >>$RCLOG


}




# --------------------------------------------------------------------------------------------------
#                                  SADM End of Process Function
# --------------------------------------------------------------------------------------------------
#
sadm_stop()
{
    GLOBAL_ERROR=$1
    if [ $GLOBAL_ERROR -ne 0 ] ; then GLOBAL_ERROR=1 ; fi               # Making Sure code is 1 or 0

    # Maintain Backup RC File log at a reasonnable size.
    write_log "${DASH}"
    write_log "Trimming $RCLOG to ${RC_MAX_LINES} lines."
    tail -${RC_MAX_LINES} $RCLOG > $RCLOG.$$
    rm -f $RCLOG > /dev/null
    mv $RCLOG.$$ $RCLOG
    chmod 666 $RCLOG

    # Update the Return Code File
    end=`date "+%H:%M:%S"`
    echo "${HOSTNAME} $start $end $INST $GLOBAL_ERROR" >>$RCLOG

    # Maintain Script log at a reasonnable size specified in ${MAX_LOGLINE}
    write_log "Trimming $LOG to ${MAX_LOGLINE} lines."
    cat $LOG >> $LOG.$$
    tail -${MAX_LOGLINE} $LOG > $LOG.$$
    rm -f $LOG > /dev/null
    mv $LOG.$$ $LOG

    write_log "${PN} just ended ..."
    write_log "${DASH}"

    # Inform UnixAdmin By Email
    if [ $GLOBAL_ERROR -eq 0 ]
        then cat $LOG | mail -s "SADMIN : SUCCESS of $PN on $HOSTNAME" $SYSADMIN
        else cat $LOG | mail -s "SADMIN : ERROR of $PN on $HOSTNAME"  $SYSADMIN
    fi

    # Delete PID File
    rm -f  ${TMP_DIR}/${INST}.pid > /dev/null 2>&1

    # Delete Temproray files used
    rm -f  ${TMP_DIR}/${INST} > /dev/null 2>&1
    if [ -e "$TMP_FILE1" ] ; then rm -f $TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE2" ] ; then rm -f $TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE3" ] ; then rm -f $TMP_FILE3 >/dev/null 2>&1 ; fi
}

