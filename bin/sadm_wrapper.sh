#! /bin/bash
# ==================================================================================================
# Title      :  sadm_Wrapper
# Version    :  1.6
# Author     :  Jacques Duplessis
# Date       :  2014-03-23
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sadm_wrapper.sh - J.Duplessis
#
# ==================================================================================================
#set -x


# ==================================================================================================
#                           V A R I A B L E S      D E F I N I T I O N S
# ==================================================================================================
#set -x
PN=${0##*/}                                         ; export PN             # Program name
VER='1.4'					                        ; export VER            # jwrapper version
SCRIPT="$1"					                        ; export SCRIPT         # Script with pathname
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST           # Get script name
MAIL_ID="duplessis.jacques@gmail.com"               ; export MAIL_ID        # Sysadmin email
HOSTNAME=`hostname -s`                              ; export HOSTNAME       # Name of server
BASE_DIR=${SADMIN:="/sadmin"}                       ; export BASE_DIR       # Script Root Base Directory
BIN_DIR="$BASE_DIR/bin"                             ; export BIN_DIR        # Script Root binary dir.
TMP_DIR="$BASE_DIR/tmp"                             ; export TMP_DIR        # Script Temp  dir.
LOG_DIR="$BASE_DIR/log"	                            ; export LOG_DIR	    # Script log dir.
LOG_FILE="${LOG_DIR}/${HOSTNAME}_${INST}.log"       ; export LOG_FILE       # Script Log file
LOG_STAT="${LOG_DIR}/rc.${HOSTNAME}_${INST}.log"    ; export LOG_STAT       # Script Log Stat. file
USAGE="Usage : sadm_wrapper path-name/script-name"  ; export USAGE          # Script Usage
DASH=`printf %60s |tr " " "="`                      ; export DASH           # 100 dashes line

# Get rid of script name and keep only arguments (if any)
shift

# The Script Name to run must be specified on the command line
if [ -z "$SCRIPT" ]
   then echo "ERROR : script to execute must be specified" >> $LOG_FILE 2>&1
        echo "$USAGE" >> $LOG_FILE 2>&1
		exit 1
fi

# The script specified must exist in path specified
if [ ! -e "$SCRIPT" ]
   then echo "ERROR : The script $SCRIPT doesn't exist"  >> $LOG_FILE 2>&1
        echo "$USAGE"  >> $LOG_FILE 2>&1
        exit 1
fi


# The Script Name must executable
if [ ! -x "$SCRIPT" ]
   then echo "ERROR : script $SCRIPT is not executable ?"  >> $LOG_FILE 2>&1
        echo "$USAGE"  >> $LOG_FILE 2>&1
        exit 1
fi




# ==================================================================================================
#                           P R O G R A M    S T A R T    H E R E
# ==================================================================================================
    start=`date "+%C%y.%m.%d %H:%M:%S"`
    echo "$HOSTNAME $start ........ $INST 2" >>$LOG_STAT

    echo " "  >>$LOG_FILE 2>&1
    echo "${DASH}"  >>$LOG_FILE 2>&1
    echo "Starting the script $PN on ${HOSTNAME} - ${start}"   >>$LOG_FILE 2>&1
    echo "${DASH}"  >>$LOG_FILE 2>&1
    echo "Executing $SCRIPT $@"   >> $LOG_FILE 2>&1

    # Execute the script and save return code
    $SCRIPT "$@" >>$LOG_FILE 2>&1
    rc=$?

    # Make sure Error code is 1 (Failed) or 0 (Completed)
    if [ $rc -ne 0 ]
       then rc=1
        tail -150 $LOG_FILE | mail -s "Error: $INST failed on $HOSTNAME at $end" $MAIL_ID
       else rc=0
    fi

    end=`date "+%H:%M:%S"`
    echo "$HOSTNAME $start $end $INST $rc" >>$LOG_STAT

    # Maintain RC File to reasonnable size (125 Records = ~ 2 months)
    tail -125 $LOG_STAT > $LOG_STAT.$$
    rm -f $LOG_STAT > /dev/null
    mv $LOG_STAT.$$ $LOG_STAT

    # Maintain Script log to reasonnable size (5000 Records)
    tail -5000 $LOG_FILE > $LOG_FILE.$$
    rm -f $LOG_FILE > /dev/null
    mv $LOG_FILE.$$ $LOG_FILE

    # Return Error Code to Caller
    exit $rc
