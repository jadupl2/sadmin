#! /usr/bin/env sh
# ==================================================================================================
# Title      :  sadm_Wrapper
# Version    :  1.6
# Author     :  Jacques Duplessis
# Date       :  2015-11-14
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sadm_wrapper.sh - J.Duplessis
#
# ==================================================================================================
#

#set -x
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH VARIABLES AND
#   FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#
#

# ==================================================================================================
#                           V A R I A B L E S      D E F I N I T I O N S
# ==================================================================================================
SCRIPT="$1"					                        ; export SCRIPT         # Script with pathname
USAGE="Usage : sadm_wrapper path-name/script-name"  ; export USAGE          # Script Usage

# Get rid of script name and keep only arguments (if any)
shift



# --------------------------------------------------------------------------------------------------
#     Validation function before starting executing the script
# --------------------------------------------------------------------------------------------------
#
validate_parameter()
{
    sadm_logger " "
    sadm_logger "Validate Parameter(s) ..."

    # The Script Name to run must be specified on the command line
    if [ -z "$SCRIPT" ]
        then    sadm_logger "ERROR : Script to execute must be specified" 
                sadm_logger "$USAGE" 
                sadm_logger "Job aborted"
                return 1
    fi

    # The script specified must exist in path specified
    if [ ! -e "$SCRIPT" ]
       then     sadm_logger "ERROR : The script $SCRIPT doesn't exist" 
                sadm_logger "$USAGE" 
                sadm_logger "Job aborted"
                return 1
    fi

    # The Script Name must executable
    if [ ! -x "$SCRIPT" ]
       then     sadm_logger "ERROR : script $SCRIPT is not executable ?" 
                sadm_logger "$USAGE" 
                return 1
    fi

    sadm_logger "Pass validation ..."
    sadm_logger " "
    return 0 
}




# ==================================================================================================
#                           P R O G R A M    S T A R T    H E R E
# ==================================================================================================
    sadm_start                                                          # Init Env. Dir & RC/Log File
    
    validate_parameter                                                  # Validate param. received
    GLOBAL_ERROR=$?                                                     # Save Function Return code
    if [ $GLOBAL_ERROR -ne 0 ]                                          # Wrong Parameter = Exit
        then sadm_stop $GLOBAL_ERROR                                    # Upd. RC & Trim Log & Set RC
             exit 1
    fi
#    
    sadm_logger "  "                                                      # Write white line to log
    sadm_logger "Executing $SCRIPT $@"                                    # Write script name to log
    $SCRIPT "$@" >>$LOG 2>&1                                            # Run selected user script
    GLOBAL_ERROR=$?                                                     # Capture Return Code

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $GLOBAL_ERROR                                             # Upd. RCH File & Trim Log 
    exit $GLOBAL_ERROR                                                  # Exit With Global Err (0/1)                                      # Exit With Global Error code (0/1)
