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

#


# --------------------------------------------------------------------------------------------------
#                           Script Variables Definitions
# --------------------------------------------------------------------------------------------------
#
MUSER="query"                                   ; export MUSER          # MySql User
MPASS="query"                                   ; export MPASS          # MySql Password
MHOST="sysinfo.maison.ca"                       ; export MHOST          # Mysql Host
MYSQL="$(which mysql)"                          ; export MYSQL          # Location of mysql program
USCRIPT="${SADM_BIN_DIR}/sadm_osupdate_client.sh" ; export USCRIPT      # Script to execute on nodes
REMOTE_SSH="/usr/bin/ssh -qnp 32"               ; export REMOTE_SSH     # SSH command for remote node
ERROR_COUNT=0                                   ; export ERROR_COUNT    # Nb. of update failed
WARNING_COUNT=0                                 ; export WARNING_COUNT  # Nb. of warning failed




# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers where "
    SQL3="server_doc_only=0 and server_active=1 and server_os_update='1' and server_os='Linux' ;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$SADM_TMP_FILE1

    xcount=0;
    while read wline
        do
        xcount=`expr $xcount + 1`
        server_name=`  echo $wline|awk '{ print $1 }'`
        server_os=`    echo $wline|awk '{ print $2 }'`
        server_domain=`echo $wline|awk '{ print $3 }'`
        server_type=`  echo $wline|awk '{ print $4 }'`
        sadm_logger " " ; sadm_logger "${SADM_TEN_DASH}"
        sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
        sadm_logger "${SADM_TEN_DASH}"
        sadm_logger "Ping the selected host ${server_name}.${server_domain}"

        ping -c2 ${server_name}.${server_domain} >> /dev/null 2>&1
        if [ $? -ne 0 ]
            then sadm_logger "Error trying to ping the server ${server_name}.${server_domain}"
                 sadm_logger "Update of server ${server_name}.${server_domain} Aborted"
                 WARNING_COUNT=$(($WARNING_COUNT+1))
                 sadm_logger "Total Error is $ERROR_COUNT and Warning at $WARNING_COUNT"
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
        sadm_logger "Total Error is $ERROR_COUNT and Warning at $WARNING_COUNT"
        done < $SADM_TMP_FILE1
    sadm_logger " "
    sadm_logger "${SADM_TEN_DASH}"
    sadm_logger "Total Error is $ERROR_COUNT and Warning at $WARNING_COUNT"
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start
    
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
        then sadm_logger "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    process_linux_servers
    rc=$? ; export rc                                                   # Save Return Code
    sadm_stop $rc
    exit $SADM_EXIT_CODE


