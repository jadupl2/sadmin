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
#
#
#***************************************************************************************************
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP SECTION
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_*.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $SADM_BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH
#   VARIABLES AND FUNCTIONS AVAILABLE TO YOU AS A SCRIPT DEVELOPPER.
#
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # Script Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
#
# Define and Load  SADMIN Shell Script Library
SADM_LIB_STD="${SADM_BASE_DIR}/lib/sadm_lib_std.sh"                     # Location & Name of Std Lib
SADM_LIB_SERVER="${SADM_BASE_DIR}/lib/sadm_lib_server.sh"               # Loc. & Name of Server Lib
SADM_LIB_SCREEN="${SADM_BASE_DIR}/lib/sadm_lib_screen.sh"               # Loc. & Name of Screen Lib
[ -r "$SADM_LIB_STD" ]    && source "$SADM_LIB_STD"                     # Load Standard Libray
[ -r "$SADM_LIB_SERVER" ] && source "$SADM_LIB_SERVER"                  # Load Server Info Library
#[ -r "$SADM_LIB_SCREEN" ] && source "$SADM_LIB_SCREEN"                  # Load Screen Related Lib.
#
#
# --------------------------------------------------------------------------------------------------
# GLOBAL VARIABLES THAT CAN BE OVERIDDEN PER SCRIPT (DEFAULT ARE IN $SADM_BASE_DIR/cfg/sadmin.cfg)
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export ADM_MAIL_ADDR        # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                          ; export SADM_MAIL_TYPE       # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME        # Company Name
#SADM_USER="sadmin"                        ; export SADM_USER            # sadmin user account
#SADM_GROUP="sadmin"                       ; export SADM_GROUP           # sadmin group account
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE     # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE      # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=40                      ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
# 
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#***************************************************************************************************
#***************************************************************************************************
#





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
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
    sadm_logger "Client Directories HouseKeeping Starting"
    sadm_logger " "

    # Reset privilege on SADMIN Base Directory
    if [ -d "$SADM_BASE_DIR" ]                                                  
        then sadm_logger "find $SADM_BASE_DIR -type d -exec chmod -R 2775 {} \;"      
             find $SADM_BASE_DIR -type d -exec chmod -R 2775 {} \; >/dev/null 2>&1    
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
             sadm_logger "find $SADM_BASE_DIR -exec chown sadmin.sadmin {} \;"    
             find $SADM_BASE_DIR -exec chown sadmin.sadmin {} \; >/dev/null 2>&1  
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
    fi 
    
    # Set the $SADM_TMP_DIR directory so everyone can write to it.
    if [ -d "$SADM_TMP_DIR" ]
        then sadm_logger "chmod 1777 $SADM_TMP_DIR"
             chmod 1777 $SADM_TMP_DIR
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
    fi 

    # $SADM_BASE_DIR is a filesystem - Put back lost+found to root
    if [ -d "$SADM_BASE_DIR/lost+found" ]
        then sadm_logger "chown root.root $SADM_BASE_DIR/lost+found"        # Special tmp Privilege
             chown root.root $SADM_BASE_DIR/lost+found >/dev/null 2>&1      # Make Lost+Found root Priv.
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
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_logger " " ; sadm_logger "${SADM_TEN_DASH}"
    sadm_logger "Client Files HouseKeeping Starting"
    sadm_logger " "
    
    # Reset privilege on SADMIN Bin Directory files
    if [ -d "$SADM_BIN_DIR" ]
        then sadm_logger "find $SADM_BIN_DIR -type f -exec chmod -R 770 {} \;"       # Change Files Privilege
             find $SADM_BIN_DIR -type f -exec chmod -R 770 {} \; >/dev/null 2>&1     # Change Files Privilege
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
    fi
    
    # Reset privilege on SADMIN Bin Directory files
    if [ -d "$SADM_LIB_DIR" ]
        then sadm_logger "find $SADM_LIB_DIR -type f -exec chmod -R 770 {} \;"     
             find $SADM_LIB_DIR -type f -exec chmod -R 770 {} \; >/dev/null 2>&1   
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Remove files older than 7 days in SADMIN TEMP Directory 
    if [ -d "$SADM_TMP_DIR" ]
        then sadm_logger "find $SADM_TMP_DIR -type f -mtime +7 -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -mtime +7 -exec ls -l {} \; | tee -a $SADM_LOG
             find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
    fi
    
    # Remove *.rch (Return Code History) files older than $LIMIT_DAYS days in SADMIN/DAT/RCH Dir.
    if [ -d "${SADM_RCH_DIR}" ]
        then sadm_logger "Find any *.rch file older than ${LIMIT_DAYS} days in ${SADM_RCH_DIR} and delete them"
             find ${SADM_RCH_DIR} -type f -mtime +${LIMIT_DAYS} -name "*.rch" -exec ls -l {} \; | tee -a $SADM_LOG
             find ${SADM_RCH_DIR} -type f -mtime +${LIMIT_DAYS} -name "*.rch" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_logger "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_logger "OK"
                     sadm_logger "Total Error Count at $ERROR_COUNT"
             fi
    fi
    
    # Remove any *.log in SADMIN LOG Directory older than ${LIMIT_DAYS} days
    if [ -d "${SADM_LOG_DIR}" ]
        then sadm_logger "Find any *.log file older than ${LIMIT_DAYS} days in ${SADM_LOG_DIR} and delete them"
             find ${SADM_LOG_DIR} -type f -mtime +${LIMIT_DAYS} -name "*.log" -exec ls -l {} \; | tee -a $SADM_LOG
             find ${SADM_LOG_DIR} -type f -mtime +${LIMIT_DAYS} -name "*.log" -exec rm -f {} \; | tee -a $SADM_LOG
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
    
