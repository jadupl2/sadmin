#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_startup.sh 
#   Date:       25 October 2015
#   Synopsis:   This script is run when the sadmin.service is started on server boot.
#               Called by /etc/systemd/system/sadmin.service
# --------------------------------------------------------------------------------------------------
#set -x

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN             # Program name
VER='2.1'                                           ; export VER            # Program version
DASH=`printf %60s |tr " " "="`                      ; export DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST           # Get script name
HOSTNAME=`hostname -s`                              ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`        ; export OSNAME         # Get OS Name AIX/LINUX
CUR_DATE=`date +"%Y_%m_%d"`                         ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                         ; export CUR_TIME       # Current Time
BASE_DIR="/sadmin"                                  ; export BASE_DIR       # Script Root Base Dir
SYS_DIR="$BASE_DIR/sys"                             ; export BIN_DIR        # Startup/Shutdown Dir
TMP_DIR="$BASE_DIR/tmp"                             ; export TMP_DIR        # Script Temp Dir
LOG_DIR="$SYS_DIR"	                                ; export LOG_DIR	    # Script log directory
LOG_FILE="${LOG_DIR}/${INST}.log"                   ; export LOG_FILE       # Script Log file

# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log
# --------------------------------------------------------------------------------------------------
write_log()
{
  echo -e $(date "+%C%y.%m.%d %H:%M:%S") - "$@" >> $LOG_FILE
}



# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    write_log " "
    write_log "${DASH}"
    write_log "Starting the script $PN on - ${HOSTNAME}"
    write_log "${DASH}"

    # Put Server startup commands below

 
    # Indicate the startup is finished is the log
    write_log " "
    write_log "Startup script: $PN Version: ${VER} is finished on ${HOSTNAME}!"

