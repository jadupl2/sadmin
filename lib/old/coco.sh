#! /bin/sh

#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY THE SADM_LIB.SH SCRIPT.
#
#   CALLING THE sadm_lib.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $BASE_DIR/lib/sadm_lib.txt FOR A DESCRIPTION OF EACH VARIABLES AND
#   FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -f ${BASE_DIR}/lib/sadm_lib.sh ] && . ${BASE_DIR}/lib/sadm_lib.sh     # Load sadm functions & Var
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
#ADM_MAIL_TYPE=1                                ; export ADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
source $BASE_DIR/lib/sadm_lib_os.sh


    tput clear
    # --------------------------------------------------------------------------------------------------
#                    Return The IP of the current Hostname
# --------------------------------------------------------------------------------------------------
sadm_server_ip() {
    echo "sadm_server_ip=getent hosts ${sadm_hostname).${sadm_domainname} | awk '{ print $1 }'"
    sadm_server_ip=`getent hosts ${sadm_hostname}.${sadm_domainname} | awk '{ print $1 }'`
    echo "$sadm_server_ip"
}


    echo "-----"
    sadm_server_ip
