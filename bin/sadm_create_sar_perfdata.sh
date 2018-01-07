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
#  2.2 Added More Verbose to output log - Jan 2017
#  2017_12_30   JDuplessis
#   V2.3    Added logic to prevent running on OSX since 'sar' is not available on it.
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.0'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================





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
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    if [ "$(sadm_get_ostype)" == "DARWIN" ]                             # No sar on OSX
        then sadm_writelog "Script not supported on MacOS - Command 'sar' not available"
             sadm_stop 0                                                # Clean Stop 
             exit 0                                                     # Exit with no error
    fi

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
sadm_writelog "PERFDATA:CPU" 
echo "PERFDATA:CPU" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -u -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -u | tee -a $OUT_FILE
fi

# Generate memory usage statistics
# --------------------------------------------------------------------------------------------------
sadm_writelog "PERFDATA:MEM_USAGE" 
echo "PERFDATA:MEM_USAGE" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -r -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -r | tee -a $OUT_FILE
fi

# Generate memory demand statistics
# --------------------------------------------------------------------------------------------------
sadm_writelog "PERFDATA:MEM_STATS" 
echo "PERFDATA:MEM_STATS" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -R -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -R | tee -a $OUT_FILE
fi

# Generate paging statistics
# --------------------------------------------------------------------------------------------------
sadm_writelog "PERFDATA:PAGING" 
echo "PERFDATA:PAGING" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -B -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -B | tee -a $OUT_FILE
fi

# Generate swapping statistics
# --------------------------------------------------------------------------------------------------
sadm_writelog "PERFDATA:SWAPPING" 
echo "PERFDATA:SWAPPING" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -W -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -W | tee -a $OUT_FILE
fi

# Generate disk transfer statistics
# --------------------------------------------------------------------------------------------------
sadm_writelog "PERFDATA:DISK" 
echo "PERFDATA:DISK" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -b -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -b | tee -a $OUT_FILE
fi

# Generate run queue statistics
# --------------------------------------------------------------------------------------------------
sadm_writelog "PERFDATA:RUNQUEUE" 
echo "PERFDATA:RUNQUEUE" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then sar -q -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -q | tee -a $OUT_FILE
fi

# Generate network usage statistics
# --------------------------------------------------------------------------------------------------
sadm_writelog "PERFDATA:NETWORK" 
echo "PERFDATA:NETWORK" | tee -a $OUT_FILE
if [ "$(sadm_get_osname)" = "AIX" ] 
   then echo " " 
        #sar -n DEV -f $SAR_FILE  | tee -a $OUT_FILE
   else sadf -p $SAR_FILE -- -n DEV | tee -a $OUT_FILE
fi

#---------------------------------------------------------------------------------------------------
    SADM_EXIT_CODE=0
    sadm_stop $SADM_EXIT_CODE
    exit $SADM_EXIT_CODE
    
