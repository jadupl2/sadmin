#! /usr/bin/env sh
#############################################################################################
# Title      :  sadm_create_sar_perfdata.sh
# Description:  Create daily linux performance data file used to generate performance graphs.
#               Added Logic for Aix - JAn 2017
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
# --------------------------------------------------------------------------------------------------
#  2.1 Added Basic Logic for Aix - JAn 2017
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_VER='2.1'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis 
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
DAY=`date +%d`                                                          # Date Day Number
DATE=`date +%Y%m%d`                                                     # Year Month Day
CLEANUP=true                                                            # Default clean output dir.
#
# Input Directory
SAR_DIR=/var/log/sa                                                     # Where sar report are store
if [ "$(sadm_get_osname)" = "AIX" ]  ; then SAR_DIR=/var/adm/sa ;fi     # Where sar report are store
#
# Input File
SAR_FILE=$SAR_DIR/sa${DAY}                                              # Name of today filename
#
# Output File
OUT_PREFIX="sadm"                                                       # Output file prefix
OUT_FILE="${SADM_SAR_DIR}/$(sadm_get_hostname)_${DATE}.sar"             # Name of the output file
OUT_MAX_FILES=30                                                        # Number Output files to keep



# ==================================================================================================
#                           S T A R T   O F   M A I N    P R O G R A M
# ==================================================================================================
#
    sadm_start                                                          # Make sure Dir Struc. exist
#
# If Parameter (filename) was/wasn't specified.
# --------------------------------------------------------------------------------------------------
if [ "$1" != "" ]
    then  SAR_FILE=$1                                                   # Input file specified
          OUT_FILE=                                                     # Output is stdout
          CLEANUP=false                                                 # No cleanup
    else >$OUT_FILE                                                     # Reset output file
#         exec 1>/dev/null                                              # Get rid of stdout
fi

# Generate CPU statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:CPU" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -u -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -u | tee -a $OUT_FILE
fi

# Generate memory usage statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:MEM_USAGE" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -r -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -r | tee -a $OUT_FILE
fi

# Generate memory demand statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:MEM_STATS" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -R -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -R | tee -a $OUT_FILE
fi

# Generate paging statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:PAGING" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -B -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -B | tee -a $OUT_FILE
fi

# Generate swapping statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:SWAPPING" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -W -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -W | tee -a $OUT_FILE
fi

# Generate disk transfer statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:DISK" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -b -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -b | tee -a $OUT_FILE
fi

# Generate run queue statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:RUNQUEUE" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -q -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -q | tee -a $OUT_FILE
fi

# Generate network usage statistics
# --------------------------------------------------------------------------------------------------
echo "PERFDATA:NETWORK" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -n DEV -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -n DEV | tee -a $OUT_FILE
fi


# Clean Stat. Directory CLEANUP DONE BY HOUSEKEEPING CLIENT SCRIPT
# --------------------------------------------------------------------------------------------------
#sadm_writelog "CleanUp is $CLEANUP"
#
#if [ "$CLEANUP" = "true" ]
#   then FILE_COUNT=`ls -lr $SADM_SAR_DIR/$OUT_PREFIX* | wc -l`
#        sadm_writelog "Number of file in $SADM_SAR_DIR is $FILE_COUNT and we keep max $OUT_MAX_FILES files"
#        if [ "$FILE_COUNT" -gt "$OUT_MAX_FILES" ]
#            then TAIL_COUNT=`expr $FILE_COUNT - $OUT_MAX_FILES`
#                 sadm_writelog "So we do a tail ${TAIL_COUNT}"
#                 if [ "$TAIL_COUNT" -gt 0 ]
#                   then ls -1r $SADM_SAR_DIR/$OUT_PREFIX* 2>/dev/null | tail -${TAIL_COUNT} | while read file
#                        do
#                        rm -f $file
#                         done
#                fi
#            else sadm_writelog "No Cleanup to do" 
#        fi
#fi

#---------------------------------------------------------------------------------------------------
    SADM_EXIT_CODE=0
    sadm_stop $SADM_EXIT_CODE
    exit $SADM_EXIT_CODE
    
