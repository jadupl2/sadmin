#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rsync_rch.sh
#   Synopsis : .Bring all rch files from server farm to SADMIN Server
#   Version  :  1.0
#   Date     :  December 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_rsync_sadmin.sh 1.0 2015.09.06
#  History
#  1.1 
# --------------------------------------------------------------------------------------------------
#set -x

#
#
#***************************************************************************************************
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP SECTION
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_*.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $SADM_BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH
#   VARIABLES AND FUNCTIONS AVAILABLE TO YOU AS A SCRIPT DEVELOPPER.
#
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # Script Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
#
# Define and Load  SADMIN Shell Script Library
SADM_LIB_STD="${SADM_BASE_DIR}/lib/sadm_lib_std.sh"                     # Location & Name of Std Lib
SADM_LIB_SERVER="${SADM_BASE_DIR}/lib/sadm_lib_server.sh"               # Loc. & Name of Server Lib
SADM_LIB_SCREEN="${SADM_BASE_DIR}/lib/sadm_lib_screen.sh"               # Loc. & Name of Screen Lib
[ -r "$SADM_LIB_STD" ]    && source "$SADM_LIB_STD"                     # Load Standard Libray
[ -r "$SADM_LIB_SERVER" ] && source "$SADM_LIB_SERVER"                  # Load Server Info Library
#[ -r "$SADM_LIB_SCREEN" ] && source "$SADM_LIB_SCREEN"                  # Load Screen Related Lib.
#
#
# --------------------------------------------------------------------------------------------------
# GLOBAL VARIABLES THAT CAN BE OVERIDDEN PER SCRIPT (DEFAULT ARE IN $SADM_BASE_DIR/cfg/sadmin.cfg)
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
# 
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#***************************************************************************************************
#***************************************************************************************************
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
    sadm_logger "$SADM_DASH" 
    sadm_logger "Processing active Linux Servers"
    sadm_logger " "
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    SQL3="where server_doc_only=0 and server_active=1 and server_os='Linux' order by server_name;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk '{ print $1 }'`
              server_os=`    echo $wline|awk '{ print $2 }'`
              server_domain=`echo $wline|awk '{ print $3 }'`
              server_type=`  echo $wline|awk '{ print $4 }'`
              sadm_logger " "
              sadm_logger "${SADM_TEN_DASH}"
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
              

              # RCH (Return Code History Files
              # Transfer Remote $SADMIN/log/*.rch to local $SADMIN/www/dat/$server/rch  
              #-------------------------------------------------------------------------------------------
              WDIR="${SADM_WWW_DIR_DAT}/${server_name}/rch"                           # Local Receiving Dir.
              sadm_logger " " 
              sadm_logger "Make sure the directory $WDIR Exist"
              if [ ! -d "${WDIR}" ]
                  then sadm_logger "Creating ${WDIR} directory"
                       mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                  else sadm_logger "Perfect ${WDIR} directory already exist"
              fi
              
              sadm_logger " " 
              sadm_logger "rsync -ar --delete ${server_name}.${server_domain}:${SADM_RCH_DIR}/ ${WDIR}/ "
              rsync -ar --delete ${server_name}.${server_domain}:${SADM_RCH_DIR}/ ${WDIR}/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
                                                                
              done < $SADM_TMP_FILE1
    fi
    sadm_logger " "
    sadm_logger "${SADM_TEN_DASH}"
    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
#                      Process Aix servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    sadm_logger " "
    sadm_logger "$SADM_DASH" 
    sadm_logger "Processing active Aix Servers" 
    sadm_logger " "
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    SQL3="where server_doc_only=0 and server_active=1 and server_os='Aix' order by server_name;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk '{ print $1 }'`
              server_os=`    echo $wline|awk '{ print $2 }'`
              server_domain=`echo $wline|awk '{ print $3 }'`
              server_type=`  echo $wline|awk '{ print $4 }'`
              sadm_logger " "
              sadm_logger "${SADM_TEN_DASH}"
              sadm_logger "Processing $xcount ${server_os} ${server_type} server : ${server_name}.${server_domain}"

              # Ping the server - Server or Laptop may be unplugged
              sadm_logger "ping -c 2 ${server_name}.${server_domain}"
              ping -c 2 ${server_name}.${server_domain} >/dev/null 2>/dev/null
              RC=$?
              if [ $RC -ne 0 ]
                 then sadm_logger "Could not ping server ${server_name}.${server_domain} ..."
                      sadm_logger "Will not be able to process server ${server_name}"
                      sadm_logger "Will consider that is ok \(May be a Laptop unplugged\) - RETURN CODE IS 0 - OK"
                      continue
              fi              

              # RCH (Return Code History Files
              # Transfer Remote $SADMIN/log/*.rch to local $SADMIN/www/dat/$server/rch  
              #-------------------------------------------------------------------------------------------
              WDIR="${SADM_WWW_DIR_DAT}/${server_name}/rch"                           # Local Receiving Dir.
              sadm_logger " " 
              sadm_logger "Make sure the directory $WDIR Exist"
              if [ ! -d "${WDIR}" ]
                  then sadm_logger "Creating ${WDIR} directory"
                       mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                  else sadm_logger "Perfect ${WDIR} directory already exist"
              fi
              
              sadm_logger " " 
              sadm_logger "rsync -var --delete ${server_name}.${server_domain}:${SADM_RCH_DIR}/ ${WDIR}/ "
              rsync -var --delete ${server_name}.${server_domain}:${SADM_RCH_DIR}/ ${WDIR}/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi

              done < $SADM_TMP_FILE1
        else  sadm_logger "No Aix Server defined in Sysinfo"
    fi
    sadm_logger " "
    sadm_logger "${SADM_TEN_DASH}"
    return $ERROR_COUNT
}





# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
        
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
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
    
    LINUX_ERROR=0; AIX_ERROR=0                                          # Initialize Error count to 0
    
    process_linux_servers                                               # Process all Active Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    sadm_logger "We had $LINUX_ERROR error(s) while processing Linux servers"

    process_aix_servers                                                 # Process all Active Aix Servers
    AIX_ERROR=$?                                                        # Set Nb. Errors while processing
    sadm_logger "We had $AIX_ERROR error(s) while processing Aix servers"
    
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                         # Total = AIX+Linux Errors
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC to or 0
    
    WDIR=`echo $SADM_SERVER | awk -F. '{ print $1 }'`                   # Remove Doman from SADM Server
    echo "cp $RCHLOG ${SADM_WWW_DIR_DAT}/${WDIR}/rch"                    # Copy finalize RCH For Summary
    cp $RCHLOG ${SADM_WWW_DIR_DAT}/${WDIR}/rch                           # Copy finalize RCH For Summary
    exit $SADM_EXIT_CODE                                                # Exit With Global Error code (0/1)
