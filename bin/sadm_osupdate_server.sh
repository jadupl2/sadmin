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

# --------------------------------------------------------------------------------------------------
# These variables got to be defined prior to calling the initialize (sadm_init.sh) script
# These variables are use and needed by the sadm_init.sh script.
# --------------------------------------------------------------------------------------------------
#
PN=${0##*/}                                    ; export PN              # Current Script name
VER='3.0'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Output to log=0 1=Screen+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Of Line in RCLOG (Trim)
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code

# --------------------------------------------------------------------------------------------------
# Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -f ${BASE_DIR}/lib/sadm_init.sh ] && . ${BASE_DIR}/lib/sadm_init.sh   # Init Var. & Load sadm functions


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
        write_log " " ; write_log "${SA_LINE}"
        write_log "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
        write_log "${SA_LINE}"
        write_log "Ping the selected host ${server_name}.${server_domain}"

        ping -c3 ${server_name}.${server_domain} >> /dev/null 2>&1
        if [ $? -ne 0 ]
            then write_log "Error trying to ping the server ${server_name}.${server_domain}"
                 write_log "Update of server ${server_name}.${server_domain} Aborted"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 write_log "Total Error Count is at $ERROR_COUNT"
                 continue
            else write_log "Ping went OK"
        fi

        write_log "Starting $USCRIPT on ${server_name}.${server_domain}"
        write_log "$REMOTE_SSH ${server_name}.${server_domain} $USCRIPT"
        $REMOTE_SSH ${server_name}.${server_domain} $USCRIPT
	    if [ $? -ne 0 ]
            then write_log "Error starting $USCRIPT on ${server_name}.${server_domain}"
	             ERROR_COUNT=$(($ERROR_COUNT+1))
            else write_log "Script was submitted with no error."
        fi
        write_log "Total Error Count is at $ERROR_COUNT"

        done < $TMP_FILE1
    write_log " "
    write_log "${SA_LINE}"
    write_log "Final Error Count is at $ERROR_COUNT"
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


