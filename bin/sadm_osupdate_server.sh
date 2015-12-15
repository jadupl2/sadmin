#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_osupdate_server.sh
#   Synopsis : .
#   Version  :  1.0
#   Date     :  9 March 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_osupdate_server.sh 1.0 2015/03/10
# --------------------------------------------------------------------------------------------------
# 2.2 Correction in end_process function (April 2014)
#
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


# --------------------------------------------------------------------------------------------------
#                           Script Variables Definitions
# --------------------------------------------------------------------------------------------------
#
MUSER="query"                                   ; export MUSER          # MySql User
MPASS="query"                                   ; export MPASS          # MySql Password
MHOST="sysinfo.maison.ca"                       ; export MHOST          # Mysql Host
MYSQL="$(which mysql)"                          ; export MYSQL          # Location of mysql program
USCRIPT="${BIN_DIR}/sadm_osupdate_client.sh"    ; export USCRIPT        # Script to execute on nodes
REMOTE_SSH="/usr/bin/ssh -qnp 32"               ; export REMOTE_SSH     # SSH command for remote node
ERROR_COUNT=0                                   ; export ERROR_COUNT    # Nb. of update failed




# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers where "
    SQL3="server_doc_only=0 and server_active=1 and server_os_update='1' and server_os='Linux' ;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE1

    xcount=0;
    while read wline
        do
        xcount=`expr $xcount + 1`
        server_name=`  echo $wline|awk '{ print $1 }'`
        server_os=`    echo $wline|awk '{ print $2 }'`
        server_domain=`echo $wline|awk '{ print $3 }'`
        server_type=`  echo $wline|awk '{ print $4 }'`
        sadm_logger " " ; sadm_logger "${SA_LINE}"
        sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
        sadm_logger "${SA_LINE}"
        sadm_logger "Ping the selected host ${server_name}.${server_domain}"

        ping -c3 ${server_name}.${server_domain} >> /dev/null 2>&1
        if [ $? -ne 0 ]
            then sadm_logger "Error trying to ping the server ${server_name}.${server_domain}"
                 sadm_logger "Update of server ${server_name}.${server_domain} Aborted"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 sadm_logger "Total Error Count is at $ERROR_COUNT"
                 continue
            else sadm_logger "Ping went OK"
        fi

        sadm_logger "Starting $USCRIPT on ${server_name}.${server_domain}"
        sadm_logger "$REMOTE_SSH ${server_name}.${server_domain} $USCRIPT"
        $REMOTE_SSH ${server_name}.${server_domain} $USCRIPT
	    if [ $? -ne 0 ]
            then sadm_logger "Error starting $USCRIPT on ${server_name}.${server_domain}"
	             ERROR_COUNT=$(($ERROR_COUNT+1))
            else sadm_logger "Script was submitted with no error."
        fi
        sadm_logger "Total Error Count is at $ERROR_COUNT"

        done < $TMP_FILE1
    sadm_logger " "
    sadm_logger "${SA_LINE}"
    sadm_logger "Final Error Count is at $ERROR_COUNT"
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start
    process_linux_servers
    rc=$? ; export rc                                                   # Save Return Code
    sadm_stop $rc
    exit $GLOBAL_ERROR


