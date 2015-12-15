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
    sadm_logger " "
    sadm_logger "$DASH" 
    sadm_logger "Processing active Linux Servers"
    sadm_logger " "
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
              sadm_logger " "
              sadm_logger "${SA_LINE}"
              sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              
              # Ping the server - Server or Laptop may be unplugged
              sadm_logger "ping -c 2 ${server_name}.${server_domain}"
              ping -c 2 ${server_name}.${server_domain} >/dev/null 2>/dev/null
              RC=$?
              if [ $RC -ne 0 ]
                 then sadm_logger "Could not ping server ${server_name}.${server_domain} ..."
                      sadm_logger "Will not be able to process server ${server_name}"
                      sadm_logger "Will consider that is ok (May be a Laptop unplugged) - RETURN CODE IS 0 - OK"
                      continue
              fi
              
              # Do the Rsync
              sadm_logger "rsync -var --delete /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/"
              rsync -var --delete /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
              
               
              sadm_logger "rsync -var --delete /sadmin/lib/ ${server_name}.${server_domain}:/sadmin/lib/"
              rsync -var --delete /sadmin/lib/ ${server_name}.${server_domain}:/sadmin/lib/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi

               
              sadm_logger "rsync -var /sadmin/cfg/ ${server_name}.${server_domain}:/sadmin/cfg/"
              rsync -var /sadmin/cfg/ ${server_name}.${server_domain}:/sadmin/cfg/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
               
              sadm_logger "rsync -var /sadmin/pkg/ ${server_name}.${server_domain}:/sadmin/pkg/"
              rsync -var /sadmin/cfg/ ${server_name}.${server_domain}:/sadmin/cfg/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
                                                                
              done < $TMP_FILE1
    fi
    sadm_logger " "
    sadm_logger "${SA_LINE}"
    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
#                      Process Aix servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    sadm_logger " "
    sadm_logger "$DASH" 
    sadm_logger "Processing active Aix Servers" 
    sadm_logger " "
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
              sadm_logger " "
              sadm_logger "${SA_LINE}"
              sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"

              # Ping the server - Server or Laptop may be unplugged
              sadm_logger "ping -c 2 ${server_name}.${server_domain}"
              ping -c 2 ${server_name}.${server_domain} >/dev/null 2>/dev/null
              RC=$?
              if [ $RC -ne 0 ]
                 then sadm_logger "Could not ping server ${server_name}.${server_domain} ..."
                      sadm_logger "Will not be able to process server ${server_name}"
                      sadm_logger "Will consider that is ok (May be a Laptop unplugged) - RETURN CODE IS 0 - OK"
                      continue
              fi              

              sadm_logger "rsync -var /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/"
              rsync -var /sadmin/bin/ ${server_name}.${server_domain}:/sadmin/bin/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi

              #sadm_logger "rsh ${server_name}.${server_domain} chmod 750 /sadmin/bin/"
              #rsh ${server_name}.${server_domain} chmod 750 /sadmin/bin/*
              #sadm_logger "rsh ${server_name}.${server_domain} chown jacques.jacques /sadmin/bin/"
              #rsh ${server_name}.${server_domain} chown jacques.jacques /sadmin/bin/*

              sadm_logger "rsync -var /sadmin/lib/ ${server_name}.${server_domain}:/sadmin/lib/"
              rsync -var /sadmin/lib/ ${server_name}.${server_domain}:/sadmin/lib/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
              
               
              sadm_logger "rsync -var /sadmin/cfg/ ${server_name}.${server_domain}:/sadmin/cfg/"
              rsync -var /sadmin/cfg/ ${server_name}.${server_domain}:/sadmin/cfg/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
    
                   
              sadm_logger "rsync -var /sadmin/pkg/ ${server_name}.${server_domain}:/sadmin/pkg/"
              rsync -var /sadmin/cfg/ ${server_name}.${server_domain}:/sadmin/cfg/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
              
              done < $TMP_FILE1
        else  sadm_logger "No Aix Server defined in Sysinfo"
    fi
    sadm_logger " "
    sadm_logger "${SA_LINE}"
    return $ERROR_COUNT
}





# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    LINUX_ERROR=0; AIX_ERROR=0                                          # Initialize Error count to 0
    
    process_linux_servers                                               # Process all Active Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    sadm_logger "We had $LINUX_ERROR error(s) while processing Linux servers"

    process_aix_servers                                                 # Process all Active Aix Servers
    AIX_ERROR=$?                                                        # Set Nb. Errors while processing
    sadm_logger "We had $AIX_ERROR error(s) while processing Aix servers"
    
    GLOBAL_ERROR=$(($AIX_ERROR+$LINUX_ERROR))                           # Total = AIX+Linux Errors
    sadm_stop $GLOBAL_ERROR                                             # Upd. RC & Trim Log & Set RC to or 0
    exit $GLOBAL_ERROR                                                  # Exit With Global Error code (0/1)
