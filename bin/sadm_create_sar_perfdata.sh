#! /usr/bin/env sh
#############################################################################################
# Title      :  sadm_create_sar_perfdata.sh
# Description:  Create daily linux performance data file used to generate performance graphs.
# Version    :  1.4
# Author     :  Jacques Duplessis
# Date       :  2015-04-21
# Requires   :  sh
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
#

#set -x
#
#
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $SADM_BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH
#   VARIABLES AND FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                               ; export SADM_PN         # Current Script name
SADM_VER='1.5'                                 ; export SADM_VER        # This Script Version
SADM_INST=`echo "$SADM_PN" |awk -F\. '{print $1}'` ; export SADM_INST   # Script name without ext.
SADM_TPID="$$"                                 ; export SADM_TPID       # Script PID
SADM_EXIT_CODE=0                               ; export SADM_EXIT_CODE  # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}             ; export SADM_BASE_DIR   # Script Root Base Directory
SADM_LOG_TYPE="B"                              ; export SADM_LOG_TYPE   # 4Logger S=Scr L=Log B=Both
#
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT (DEFAULT CAN BE CHANGED IN $SADM_BASE_DIR/cfg/sadmin.cfg)
#SADM_MAIL_ADDR="your_email@domain.com"        ; export ADM_MAIL_ADDR    # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE   # 0=No 1=Err 2=Succes 3=All
SADM_MAX_LOGLINE=5000                          ; export SADM_MAX_LOGLINE # Max Nb. Lines in LOG )
SADM_MAX_RCLINE=100                            ; export SADM_MAX_RCLINE  # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#

# --------------------------------------------------------------------------------------------------
# Script Variables definition
# --------------------------------------------------------------------------------------------------
#
DAY=`date +%d`                                                          # Date Day Number
DATE=`date +%Y%m%d`                                                     # Year Month Day
CLEANUP=true                                                            # Default clean output dir.
#
# Input File
SAR_DIR=/var/log/sa                                                     # Where sar report are stored
SAR_FILE=$SAR_DIR/sa${DAY}                                              # Name of today filename
#
# Output File
OUT_PREFIX="sadm"                                                       # Output file prefix
OUT_FILE=${SADM_PERF_DIR}/${OUT_PREFIX}_${DATE}.sar                         # Name of the output file
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
#         exec 1>/dev/null                                               # Get rid of stdout
fi

# Generate CPU statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:CPU" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -u -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -u | tee -a $OUT_FILE
fi

# Generate memory usage statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:MEM_USAGE" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -r -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -r | tee -a $OUT_FILE
fi

# Generate memory demand statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:MEM_STATS" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -R -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -R | tee -a $OUT_FILE
fi

# Generate paging statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:PAGING" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -B -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -B | tee -a $OUT_FILE
fi

# Generate swapping statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:SWAPPING" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -W -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -W | tee -a $OUT_FILE
fi

# Generate disk transfer statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:DISK" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -b -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -b | tee -a $OUT_FILE
fi

# Generate run queue statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:RUNQUEUE" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -q -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -q | tee -a $OUT_FILE
fi

# Generate network usage statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:NETWORK" | tee -a $OUT_FILE
if [ $(sadm_os_major_version) -lt 5 ]
   then sar -n DEV -h -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -n DEV | tee -a $OUT_FILE
fi


# Clean Stat. Directory
# --------------------------------------------------------------------------------------------------
sadm_logger "CleanUp is $CLEANUP"

if [ "$CLEANUP" = "true" ]
   then FILE_COUNT=`ls -lr $SADM_PERF_DIR/$OUT_PREFIX* | wc -l`
        sadm_logger "Number of file in $SADM_PERF_DIR is $FILE_COUNT and we keep max $OUT_MAX_FILES files"
        if [ "$FILE_COUNT" -gt "$OUT_MAX_FILES" ]
            then TAIL_COUNT=`expr $FILE_COUNT - $OUT_MAX_FILES`
                 sadm_logger "So we do a tail ${TAIL_COUNT}"
                 if [ "$TAIL_COUNT" -gt 0 ]
                   then ls -1r $SADM_PERF_DIR/$OUT_PREFIX* 2>/dev/null | tail -${TAIL_COUNT} | while read file
                        do
                        rm -f $file
                         done
                fi
            else sadm_logger "No Cleanup to do" 
        fi
fi

#---------------------------------------------------------------------------------------------------
    SADM_EXIT_CODE=0
    sadm_stop $SADM_EXIT_CODE
    exit $SADM_EXIT_CODE
    
