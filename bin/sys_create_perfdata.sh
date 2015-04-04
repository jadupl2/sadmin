#! /bin/sh
#############################################################################################
# Title      :  sys_create_perfdata.sh
# Description:  Create daily linux performance data file used to generate performance graphs.
# Version    :  1.4
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) daily_data_collection.sh 1.4 21-04/2010
#############################################################################################
#
# FOR DAILY LINUX PERF. DATA:
#
#   This script should be run by cron at 23h55. It will process the
#   file /var/log/sa/saXX where "XX" is the current day of the month
#   as printed by "date +'%d'".
#
# FOR INTERACTIVE USE:
#
#   Usage: create_linux_perfdata [ sar_data_file ]
#
#   When the SAR_FILE is specified, the output is sent to standard output.
#
#############################################################################################
#set -x

# --------------------------------------------------------------------------------------------------
# These variables got to be defined prior to calling the initialize (sadm_init.sh) script
# These variables are use and needed by the sadm_init.sh script.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='3.0'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Output 0=log 1=Screen+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Of Line in RCLOG (Trim)

# --------------------------------------------------------------------------------------------------
# Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -x ${BASE_DIR}/lib/sadm_init.sh ] && . ${BASE_DIR}/lib/sadm_init.sh   # Init Var. & Load sadm functions


# --------------------------------------------------------------------------------------------------
# Script Variables definition
# --------------------------------------------------------------------------------------------------
#
DAY=`date +%d`                                                          # Date Day Number
DATE=`date +%y%m%d`                                                     # Year Month Day
CLEANUP=true                                                            # Default clean output dir.
#
# Input File
SAR_DIR=/var/log/sa                                                     # Where sar report are stored
SAR_FILE=$SAR_DIR/sa${DAY}                                              # Name of today filename
#
# Output File
OUT_DIR=/etc/perf                                                       # Output Directory
OUT_PREFIX="perfdata"                                                   # Output file prefix
OUT_FILE=$OUT_DIR/$OUT_PREFIX.${DATE}                                   # Name of the output file
OUT_MAX_FILES=30                                                        # Number Output files to keep

# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Make sure Dir. Struc. exist
#
# If Parameter (filename) was/wasn't specified.
# --------------------------------------------------------------------------------------------------
if [ "$1" != "" ]
    then SAR_FILE=$1                                                    # Input file specified
         OUT_FILE=                                                      # Output is stdout
         CLEANUP=false                                                  # No cleanup
    else >$OUT_FILE                                                     # Reset output file
         exec 1>/dev/null                                               # Get rid of stdout
fi

# Generate CPU statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:CPU" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -u -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -u | tee -a $OUT_FILE
fi

# Generate memory usage statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:MEM_USAGE" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -r -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -r | tee -a $OUT_FILE
fi

# Generate memory demand statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:MEM_STATS" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -R -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -R | tee -a $OUT_FILE
fi

# Generate paging statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:PAGING" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -B -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -B | tee -a $OUT_FILE
fi

# Generate swapping statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:SWAPPING" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -W -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -W | tee -a $OUT_FILE
fi

# Generate disk transfer statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:DISK" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -b -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -b | tee -a $OUT_FILE
fi

# Generate run queue statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:RUNQUEUE" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -q -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -q | tee -a $OUT_FILE
fi

# Generate network usage statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:NETWORK" | tee -a $OUT_FILE
if [ $OSVERSION -lt 5 ]
   then sar -n DEV -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -n DEV | tee -a $OUT_FILE
fi


# Clean Stat. Directory
# --------------------------------------------------------------------------------------------------
if [ $CLEANUP = "true" ]
   then FILE_COUNT=`ls -lr $OUT_DIR/$OUT_PREFIX* | wc -l`
        echo "Number of file in $OUT_DIR is $FILE_COUNT and we keep only $OUT_MAX_FILES"
        TAIL_COUNT=`expr $FILE_COUNT - $OUT_MAX_FILES`
        echo "So we do a tail ${TAIL_COUNT}"
        if [ $TAIL_COUNT -gt 0 ]
            then ls -1r $OUT_DIR/$OUT_PREFIX* 2>/dev/null | tail -${TAIL_COUNT} | while read file
                do
                rm -f $file
                done
fi

# --------------------------------------------------------------------------------------------------
    sadm_stop $RC                                                       # End Process with exit Code
    write_log "The exist code is set to $RC"                            # Advise user that RC set to 1
    exit $RC                                                            # Exit script

