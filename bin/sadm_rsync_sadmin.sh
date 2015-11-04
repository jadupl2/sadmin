#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rsync_sadmin.sh
#   Synopsis : .
#   Version  :  1.0
#   Date     :  6 September 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_rsync_sadmin.sh 1.0 2015.09.06
#  History
#  1.1 
# --------------------------------------------------------------------------------------------------
#set -x

# --------------------------------------------------------------------------------------------------
#  These variables got to be defined prior to calling the initialize (sadm_init.sh) script
#  These variables are use and needed by the sadm_init.sh script.
#  Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='3.0'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Output to log=0 1=Screen+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Of Line in RCLOG (Trim)
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
#
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -f ${BASE_DIR}/lib/sadm_init.sh ] && . ${BASE_DIR}/lib/sadm_init.sh   # Init Var. & Load sadm functions
#


# --------------------------------------------------------------------------------------------------
# This Script environment variable
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
    write_log " "
    write_log "$DASH" 
    write_log "Processing active Linux Servers"
    write_log " "
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
              write_log "${SA_LINE}"
              write_log "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              
              # Ping the server - Server or Laptop may be unplugged
              write_log "ping -c 2 ${server_name}.${server_domain}"
              ping -c 2 ${server_name}.${server_domain} >/dev/null 2>/dev/null
              RC=$?
              if [ $RC -ne 0 ]
                 then write_log "Could not ping server ${server_name}.${server_domain} ..."
                      write_log "Will not be able to process server ${server_name}"
                      write_log "Will consider that is ok (May be a Laptop unplugged) - RETURN CODE IS 0 - OK"
                      continue
              fi
              
              # Do the Rsync
              write_log "rsync -var /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/"
              rsync -var /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/
              #write_log "rsh ${server_name}.${server_domain} chmod 750 /sadmin/bin/"
              #rsh ${server_name}.${server_domain} chmod 750 /sadmin/bin/*
              #write_log "rsh ${server_name}.${server_domain} chown jacques.jacques /sadmin/bin/"
              #rsh ${server_name}.${server_domain} chown jacques.jacques /sadmin/bin/*
              RC=$? 
              if [ $RC -ne 0 ]
                 then write_log "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else write_log "RETURN CODE IS 0 - OK"
              fi
              done < $TMP_FILE1
    fi
    write_log " "
    write_log "${SA_LINE}"
    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
#                      Process Aix servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    write_log " "
    write_log "$DASH" 
    write_log "Processing active Aix Servers" 
    write_log " "
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
              write_log " "
              write_log "${SA_LINE}"
              write_log "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"

              # Ping the server - Server or Laptop may be unplugged
              write_log "ping -c 2 ${server_name}.${server_domain}"
              ping -c 2 ${server_name}.${server_domain} >/dev/null 2>/dev/null
              RC=$?
              if [ $RC -ne 0 ]
                 then write_log "Could not ping server ${server_name}.${server_domain} ..."
                      write_log "Will not be able to process server ${server_name}"
                      write_log "Will consider that is ok (May be a Laptop unplugged) - RETURN CODE IS 0 - OK"
                      continue
              fi              

              write_log "rsync -var /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/"
              rsync -var /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then write_log "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else write_log "RETURN CODE IS 0 - OK"
              fi
              done < $TMP_FILE1
        else  write_log "No Aix Server defined in Sysinfo"
    fi
    write_log " "
    write_log "${SA_LINE}"
    return $ERROR_COUNT
}





# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    LINUX_ERROR=0; AIX_ERROR=0                                          # Initialize Error count to 0
    
    process_linux_servers                                               # Process all Active Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    write_log "We had $LINUX_ERROR error(s) while processing Linux servers"

    process_aix_servers                                                 # Process all Active Aix Servers
    AIX_ERROR=$?                                                        # Set Nb. Errors while processing
    write_log "We had $AIX_ERROR error(s) while processing Aix servers"
    
    GLOBAL_ERROR=$(($AIX_ERROR+$LINUX_ERROR))                           # Total = AIX+Linux Errors
    sadm_stop $GLOBAL_ERROR                                             # Upd. RC & Trim Log & Set RC to or 0
    exit $GLOBAL_ERROR                                                  # Exit With Global Error code (0/1)
