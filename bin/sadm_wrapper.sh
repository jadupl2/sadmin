#! /usr/bin/env sh
# ==================================================================================================
# Title      :  sadm_Wrapper
# Version    :  1.6
# Author     :  Jacques Duplessis
# Date       :  2015-11-14
# Requires   :  bash shell
# ==================================================================================================
#

#
#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
#===================================================================================================

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib


# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
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
 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#===================================================================================================
#


#

# ==================================================================================================
#                           V A R I A B L E S      D E F I N I T I O N S
# ==================================================================================================
SCRIPT="$1"             	                        ; export SCRIPT         # Script with pathname
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
    SADM_EXIT_CODE=$?                                                   # Save Function Return code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # Wrong Parameter = Exit
        then sadm_stop $SADM_EXIT_CODE                                  # Upd. RC & Trim Log & Set RC
             exit 1
    fi
#    
    sadm_logger "  "                                                    # Write white line to log
    sadm_logger "Executing $SCRIPT $@"                                  # Write script name to log
    $SCRIPT "$@" >>$SADM_LOG 2>&1                                       # Run selected user script
    SADM_EXIT_CODE=$?                                                   # Capture Return Code

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                      # Exit With Global Error code (0/1)
