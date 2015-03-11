#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      time_dig.sh
#   Date:       15 Fevrier 2014
#   Synopsis:   This script is used to time gig access to selected web sites.
# --------------------------------------------------------------------------------------------------
#set -x 

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN 	        # Program name
VER='1.6'                                           ; export VER            # Program version
SYSADMIN="duplessis.jacques@gmail.com"              ; export SYSADMIN	    # Sysadmin email
DASH=`printf %100s |tr " " "="`                     ; export DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST           # Get Current script name
HOSTNAME=`hostname -s`                              ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`        ; export OSNAME         # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                         ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                         ; export CUR_TIME       # Current Time
#
BASE_DIR="/sadmin"                                  ; export BASE_DIR       # Script Root Base Directory
BIN_DIR="$BASE_DIR/bin"                             ; export BIN_DIR        # Script Root binary directory
TMP_DIR="$BASE_DIR/tmp"                             ; export TMP_DIR        # Script Temp  directory
LOG_DIR="$BASE_DIR/log"	                            ; export LOG_DIR	    # Script log directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"                 ; export TMP_FILE1      # Script Tmp File1 
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"                 ; export TMP_FILE2      # Script Tmp File2
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"                 ; export TMP_FILE3      # Script Tmp File3 
LOG_FILE="${LOG_DIR}/${HOSTNAME}_${INST}.log"       ; export LOG_FILE       # Script Log file
LOG_STAT="${LOG_DIR}/${HOSTNAME}_${INST}_stat.log"  ; export LOG_STAT       # Script Log Statistic file
GLOBAL_ERROR=0                                      ; export GLOBAL_ERROR   # Global Error Return Code
#
www1="www.standardlife.com"
www2="www.ibm.com"
www3="www.linux.com"
www4="www.microsoft.com"
www5="www.mcgill.ca"

# --------------------------------------------------------------------------
#                         Write infornation into the log                        
# --------------------------------------------------------------------------
write_log()
{
  echo -e "`date` - $1" >> $LOG
}



# --------------------------------------------------------------------------
# 		S T A R T   O F   M A I N    P R O G R A M 
# --------------------------------------------------------------------------
#
for w in $www1 $www2 $www3 $www4 $www5
do
    #echo "$w"
    wtime=`dig $w  +trace | grep 'bytes' | awk '{ total += $8 }; END { print total }'`
    echo "`date` - $wtime - $w"
done
