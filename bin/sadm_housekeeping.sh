#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_housekeeping.sh
#   Synopsis : .Make some general housekeeping that we run once daily to get things running smoothly
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh

#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tool are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
# --------------------------------------------------------------------------------------------------
# 1.6   
#
#set -x
#
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
EXIT_CODE=0                                    ; export EXIT_CODE       # Script Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
[ -f ${BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib
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
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
Debug=true                                      ; export Debug          # Debug increase Verbose
#
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
              sadm_logger "${DASH}"
              sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              # PROCESS GOES HERE
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for $server"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
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
              xcount=$(($xcount+1))
              server_name=`  echo $wline|awk '{ print $1 }'`
              server_os=`    echo $wline|awk '{ print $2 }'`
              server_domain=`echo $wline|awk '{ print $3 }'`
              server_type=`  echo $wline|awk '{ print $4 }'`
              sadm_logger "${DASH}"
              sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              # PROCESS GOES HERE
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for $server"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
              done < $TMP_FILE1
    fi
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                      Development  General Housekeeping Function
# --------------------------------------------------------------------------------------------------
dev_housekeeping()
{
    sadm_logger "${DASH}"
    sadm_logger "Development HouseKeeping"
    sadm_logger " "

    # Reset privilege on notes directories
    sadm_logger "find $BASE_DIR/notes -type f -exec chmod -R 664 {} \;"       # Change Dir. 
    find $BASE_DIR/notes -type f -exec chmod -R 664 {} \; >/dev/null 2>&1     # Change Dir. 

}

# --------------------------------------------------------------------------------------------------
#                      Production General Housekeeping Function
# --------------------------------------------------------------------------------------------------
prod_housekeeping()
{
    sadm_logger "${DASH}"
    sadm_logger "Production HouseKeeping"
    sadm_logger " "
    
    
    # Reset privilege on /sadmin files
    sadm_logger "find $BIN_DIR -type f -exec chmod -R 770 {} \;"        # Change Files Privilege
    find $BIN_DIR -type f -exec chmod -R 770 {} \; >/dev/null 2>&1      # Change Files Privilege
    sadm_logger "find $LIB_DIR -type f -exec chmod -R 770 {} \;"        # Change Files Privilege
    find $LIB_DIR -type f -exec chmod -R 770 {} \; >/dev/null 2>&1      # Change Files Privilege

    # Reset privilege on /sadmin directories
    sadm_logger "find $BIN_DIR -type d -exec chmod -R 2775 {} \;"       # Change Dir. 
    find $BIN_DIR -type d -exec chmod -R 2775 {} \; >/dev/null 2>&1     # Change Dir. 

    # Flush files older than 7 days in $TMP_DIR
    sadm_logger "find $TMP_DIR -name \"sadm_*\" -type f -mtime +7 -exec rm -f {} \;"  # Change Dir. 
    find $TMP_DIR -name \"sadm_*\" -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1   # Change Dir. 
    
    # Set the TMP directory so everyone can write to it.
    sadm_logger "chmod -R 1777 $TMP_DIR "                               # Special tmp Privilege
    chmod -R 1777 $TMP_DIR >/dev/null 2>&1                              # Special tmp Privilege
    
    # Change the owner and group of SADMIN Base Directory to sadmin.
    find $BASE_DIR -exec chown sadmin.sadmin {} \; >/dev/null 2>&1      # Change Owner & Group 
    chown root.root $BASE_DIR/lost+found >/dev/null 2>&1                # Make Lost+Found root Priv.
    
    sadm_logger "chmod 2775 $LOG_DIR"                                   # LOGDIR Writable Owner/Group
    chmod 2775 $LOG_DIR                                                 # LOGDIR Writable Owner/Group
    
    
    return 0
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]       # Only run on SADMIN Server
        then sadm_logger "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    process_linux_servers                                               # Process all Active Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    process_aix_servers                                                 # Process all Active Aix Servers
    AIX_ERROR=$?                                                        # Set Nb. Errors while processing
    
    prod_housekeeping
    PCODE=$?
    dev_housekeeping
    DCODE=$?
    
    EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR+$PCODE+$DCODE))                # Total = AIX+Linux Errors

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Return Code History file
    sadm_stop $EXIT_CODE                                                # Upd. RCH File & Trim Log 
    exit $EXIT_CODE                                                     # Exit With Global Err (0/1)



