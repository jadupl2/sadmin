#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_housekeeping.sh
#   Synopsis : .Make some general housekeeping that we run once daily to get things running smoothly
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh

#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tool are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
# --------------------------------------------------------------------------------------------------
# 1.6   
#
#
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
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT (DEFAULT CAN BE CHANGED IN $SADM_BASE_DIR/cfg/sadmin.cfg)
#SADM_MAIL_ADDR="your_email@domain.com"         ; export ADM_MAIL_ADDR    # Default is in sadmin.cfg
SADM_DEBUG_LEVEl=5                             ; export SADM_DEBUG_LEVEL # 0=NoDebug Higher=+Verbose
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE   # 0=No 1=Err 2=Succes 3=All
SADM_MAX_LOGLINE=5000                          ; export SADM_MAX_LOGLINE # Max Nb. Lines in LOG )
SADM_MAX_RCLINE=100                            ; export SADM_MAX_RCLINE  # Max Nb. Lines in RCH file
# 
#***************************************************************************************************
trap 'sadm_stop 0; exit 0' 2   # INTERCEPTE LE ^C
#
#



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
#
# This is a counter that is incremented each time an error occured
ERROR_COUNT=0                               ; export ERROR_COUNT            # Error Counter

# Number of days to keep unmodified *.rch and *.log file - After that time they are deleted
LIMIT_DAYS=60                               ; export LIMIT_DAYS             # RCH+LOG Delete after




# --------------------------------------------------------------------------------------------------
#                               General Directories Housekeeping Function
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_logger " " ; sadm_logger "${SADM_TEN_DASH}"
    sadm_logger "Server Directories HouseKeeping Starting"
    sadm_logger " "


    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_logger " " ; sadm_logger "${SADM_TEN_DASH}"
    sadm_logger "Server Files HouseKeeping Starting"
    sadm_logger " "
    
    if [ -d "${SADM_WWW_DIR}/dat" ]
        then sadm_logger "Find any *.rch file older than ${LIMIT_DAYS} days in ${SADM_WWW_DIR}/dat and delete them"
             find ${SADM_WWW_DIR}/dat -type f -mtime +${LIMIT_DAYS} -name "*.rch" -exec ls -l {} \; | tee -a $LOG
             find ${SADM_WWW_DIR}/dat -type f -mtime +${LIMIT_DAYS} -name "*.rch" -exec rm -f {} \; | tee -a $LOG
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
    fi
    
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]       # Only run on SADMIN Server
        then sadm_logger "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    dir_housekeeping                                                    # Do Dir HouseKeeping
    file_housekeeping                                                   # Do File HouseKeeping
    SADM_EXIT_CODE=$ERROR_COUNT                                         # Error COunt = Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)


