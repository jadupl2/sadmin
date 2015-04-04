#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  template.sh
#   Synopsis : .
#   Version  :  1.0
#   Date     :  14 August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) template.sh 2.0 2013/08/14
# --------------------------------------------------------------------------------------------------
# 2.2 Correction in end_process function (April 2014)
#
#set -x

# --------------------------------------------------------------------------------------------------
# These variables got to be defined prior to calling the initialize (sadm_init.sh) script
# These variables are use and needed by the sadm_init.sh script.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='2.9'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Output 0=log 1=Screen+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Of Line in RCLOG (Trim)

# --------------------------------------------------------------------------------------------------
# Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -x ${BASE_DIR}/lib/sadm_init.sh ] && . ${BASE_DIR}/lib/sadm_init.sh   # Init Var. & Load sadm functions


# --------------------------------------------------------------------------------------------------
# Script Variables definition
# --------------------------------------------------------------------------------------------------
#
MUSER="query"                                   ; export MUSER          # MySql User
MPASS="query"                                   ; export MPASS          # MySql Password
MHOST="sysinfo.maison.ca"                       ; export MHOST          # Mysql Host
MYSQL="$(which mysql)"                          ; export MYSQL          # Location of mysql program
#






# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    SQL3="where server_doc_only=0 and server_active=1 and server_os='Linux' order by server_name;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk '{ print $1 }'`
              server_os=`    echo $wline|awk '{ print $2 }'`
              server_domain=`echo $wline|awk '{ print $3 }'`
              server_type=`  echo $wline|awk '{ print $4 }'`
              write_log "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              write_log "${DASH}"
              # PROCESS GOES HERE
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then write_log "ERROR NUMBER $RC for $server"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else write_log "RETURN CODE IS 0 - OK"
              fi
              done < $TMP_FILE1
    fi
    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
#                      Process Aix servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    SQL3="where server_doc_only=0 and server_active=1 and server_os='Aix' order by server_name;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk '{ print $1 }'`
              server_os=`    echo $wline|awk '{ print $2 }'`
              server_domain=`echo $wline|awk '{ print $3 }'`
              server_type=`  echo $wline|awk '{ print $4 }'`
              write_log "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              write_log "${DASH}"
              # PROCESS GOES HERE
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then write_log "ERROR NUMBER $RC for $server"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else write_log "RETURN CODE IS 0 - OK"
              fi
              done < $TMP_FILE1
    fi
    return $ERROR_COUNT
}





# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File

    process_linux_servers                                               # Process all Active Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    process_aix_servers                                                 # Process all Active Aix Servers
    AIX_ERROR=$?                                                        # Set Nb. Errors while processing

    GLOBAL_ERROR=$(($AIX_ERROR+$LINUX_ERROR))                           # Total = AIX+Linux Errors
    sadm_stop $GLOBAL_ERROR                                             # Upd. RC & Trim Log & Set RC to or 0
    exit $GLOBAL_ERROR                                                  # Exit With Global Error code (0/1)


