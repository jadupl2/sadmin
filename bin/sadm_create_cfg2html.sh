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
VER='2.2'                                      ; export VER             # Program version
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

    # Make sure that cfg2html is accessible on the server
    CFG2HTML=`which cfg2html >/dev/null 2>&1`                           # Locate cfg2html
    if [ $? -eq 0 ]                                                     # if found
        then CFG2HTML=`which cfg2html`                                  # Save cfg2html path
        else sadm_logger "Error : The command 'cfg2html' was not found"   # Not Found inform user
             sadm_logger "   Install it and re-run this script"      # Not Found inform user
             sadm_logger "   For Ubuntu/Debian : sudo dpkg -i ${PKG_DIR}/cfg2html-linux.deb "
             sadm_logger "   For RedHat/CentOS/Fedora : rpm -Uvh {PKG_DIR}/rpm/${sadm_os_major_version}/cfg2html.rpm"
             sadm_stop 1                                                # Upd. RC & Trim Log 
             exit 1                                                     # Exit With Error 
    fi
    export CFG2HTML                                                     
    if [ $Debug ] ; then sadm_logger "COMMAND CFG2HTML : $CFG2HTML" ; fi  # Display Path if Debug
    
    # Run CFG2HTML
    sadm_logger "Running : $CFG2HTML -H -o $DR_DIR"
    $CFG2HTML -H -o $DR_DIR >>$LOG 2>&1
    GLOBAL_ERROR=$?

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $GLOBAL_ERROR                                             # Upd. RCH File & Trim Log 
    exit $GLOBAL_ERROR                                                  # Exit With Global Error (0/1)


