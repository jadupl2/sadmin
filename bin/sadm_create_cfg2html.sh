#! /usr/bin/env sh
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_cfg2html.sh1
#   Synopsis :  Run the cfg2html tool & record files .
#   Version  :  1.0
#   Date     :  14 August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) create_cfg2html.sh 2.0 2013/08/14
#===================================================================================================
# 2.2 Correction in end_process function (April 2014)
#
#===================================================================================================
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
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
Debug=true                                      ; export Debug          # Debug increase Verbose




#===================================================================================================
#                                Script Start HERE
#===================================================================================================
    sadm_start                                                          # Init Env. Dir & RC/Log File

    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # Make sure that cfg2html is accessible on the server
    CFG2HTML=`which cfg2html >/dev/null 2>&1`                           # Locate cfg2html
    if [ $? -eq 0 ]                                                     # if found
        then CFG2HTML=`which cfg2html`                                  # Save cfg2html path
        else if [ "$(sadm_os_name)" = "AIX" ]                           # If on AIX & Not Found
                then CFG2HTML="$SADM_PKG_DIR/aix/cfg2html/cfg2html"     # Use then one in /sadmin
                else sadm_logger "Error : The command 'cfg2html' was not found"   # Not Found inform user
                     sadm_logger "   Install it and re-run this script" # Not Found inform user
                     sadm_logger "   For Ubuntu/Debian : sudo dpkg --install ${SADM_PKG_DIR}/deb/cfg2html/cfg2html-linux.deb"
                     sadm_logger "   For RedHat/CentOS/Fedora : rpm -Uvh {SADM_PKG_DIR}/rpm/${sadm_os_major_version}/cfg2html.rpm"
                     sadm_stop 1                                        # Upd. RC & Trim Log 
                     exit 1                                             # Exit With Error
             fi
    fi
    export CFG2HTML                                                     
    if [ $Debug ] ; then sadm_logger "COMMAND CFG2HTML : $CFG2HTML" ; fi  # Display Path if Debug
    
    # Run CFG2HTML
    sadm_logger "Running : $CFG2HTML -H -o $SADM_DR_DIR"
    $CFG2HTML -H -o $SADM_DR_DIR >>$LOG 2>&1
    SADM_EXIT_CODE=$?



    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                             # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                  # Exit With Global Error (0/1)


