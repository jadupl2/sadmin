#! /bin/sh
#############################################################################################
# Title      :  sys_daily_data_collection.sh
# Description:  Get hardware Info & Performance Datafrom all active servers
# Version    :  2.4
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) sys_daily_data_collection.sh 1.4 21-04/2010
#############################################################################################
# Description
# 2015 - Restructure and redesign for modularity - Jacques Duplessus
#############################################################################################
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
#


#
#
                                                                     
# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# Script Variables definition
# --------------------------------------------------------------------------------------------------
#
HW_DIR="$SADM_DAT_DIR/hw"	                	   ; export HW_DIR          # Hardware Data collected
#
MUSER="query"                                  ; export MUSER           # MySql User
MPASS="query"                                  ; export MPASS           # MySql Password
MHOST="sysinfo.maison.ca"                      ; export MHOST           # Mysql Host
MYSQL="$(which mysql)"                         ; export MYSQL           # Location of mysql program
#
ERROR_COUNT=0                                  ; export ERROR_COUNT     # Global Error Counter
TOTAL_AIX=0                                    ; export TOTAL_AIX       # Nb Error in Aix Function
TOTAL_LINUX=0                                  ; export TOTAL_LINUX     # Nb Error in Linux Function


# --------------------------------------------------------------------------------------------------
#                           Produce a List of all actives AIX Servers
# --------------------------------------------------------------------------------------------------
#
get_aix_files()
{
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting to process AIX Servers ..."

    sadm_logger "Producing a list of all AIX active servers"
    SQL1="use sysinfo; SELECT server_name, server_domain FROM servers where server_os='AIX' "
    SQL2="and server_active=1 and server_doc_only=0 ;"
    SQL="${SQL1} ${SQL2}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$SADM_TMP_FILE1

    # If no file to process
    if [ ! -s "$SADM_SADM_TMP_FILE1" ]
        then sadm_logger "No AIX server to process ..."
    fi
    
    # Loop through the AIX actives file list just produce
    while read wline
        do
        server=`echo $wline|awk '{ print $1 }'`
        domain=`echo $wline|awk '{ print $2 }'`

        # Test pinging the server - if doesn t work then skip server & Log error
        #-------------------------------------------------------------------------------------------
        sadm_logger " " ; sadm_logger " " ; sadm_logger "${SADM_DASH}"
        sadm_logger "Starting to process the AIX server : ${server}.${domain}"
        sadm_logger "ping -c 2 ${server}.${domain}"
        ping -c 2 ${server}.${domain} >/dev/null 2>/dev/null
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "Could not ping server ${server_name}.${server_domain} ..."
                sadm_logger " - Will not be able to process that server."
                sadm_logger " - WILL CONSIDER THAT IS OK (MAY BE POWEROFF OR AN UNPLUGGED LAPTOP)."
                sadm_logger "RETURN CODE IS 0 - OK"
                continue
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "Linux Total Error Count is now at $ERROR_COUNT"


        # CREATE LOCAL RECEIVING DIR
        # Making sure the $SADMIN/dat/$server exist on Local SADMIN server
        #-------------------------------------------------------------------------------------------
        sadm_logger " " 
        sadm_logger "Make sure the directory ${SADM_SADM_WWW_DIR_DAT}/${server} Exist"
        if [ ! -d "${SADM_WWW_DIR_DAT}/${server}" ]
            then sadm_logger "Creating ${SADM_WWW_DIR_DAT}/${server} directory"
                 mkdir -p "${SADM_WWW_DIR_DAT}/${server}"
                 chmod 2775 "${SADM_WWW_DIR_DAT}/${server}"
            else sadm_logger "Perfect ${SADM_WWW_DIR_DAT}/${server} directory already exist"
        fi

    


        # DR INFO FILES
        # Transfer $SADMIN/dat/disaster_recovery_info from Remote to $SADMIN/www/dat/$server/dr  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DIR_DAT}/${server}/dr"
        sadm_logger " " 
        sadm_logger "Make sure the directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_logger "Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_logger "Perfect ${WDIR} directory already exist"
        fi
        sadm_logger "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/"
        rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "ERROR NUMBER $RC for $server"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "AIX Total Error Count is now at $ERROR_COUNT"


        # NMON FILES
        # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server/nmon  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DIR_DAT}/${server}/nmon"                            # Local Receiving Dir.
        sadm_logger " " 
        sadm_logger "Make sure the directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_logger "Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_logger "Perfect ${WDIR} directory already exist"
        fi
        sadm_logger "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/"
        rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "ERROR NUMBER $RC for $server"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "AIX Total Error Count is now at $ERROR_COUNT"


        # SAR PERF FILES
        # Transfer Remote $SADMIN/dat/performance_data files to local $SADMIN/www/dat/$server/nmon  
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DIR_DAT}/${server}/sar"                             # Local Receiving Dir.
        sadm_logger " " 
        sadm_logger "Make sure the directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_logger "Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_logger "Perfect ${WDIR} directory already exist"
        fi
        sadm_logger "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_PERF_DIR}/ $WDIR/"
        rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_PERF_DIR}/ $WDIR/
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "ERROR NUMBER $RC for $server"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "AIX Total Error Count is now at $ERROR_COUNT"
    done < $SADM_TMP_FILE1

    sadm_logger " "
    sadm_logger "FINAL number of AIX Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT
}



####################################################################################################
#    Get all actives Linux servers from the SADMIN Database and retrieve information files
####################################################################################################
#
get_linux_files()
{
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting to process Linux Servers ..."

    sadm_logger "Producing a list of all Linux active servers"
    SQL1="use sysinfo; SELECT server_name, server_domain FROM servers where server_os='Linux' "
    SQL2="and server_active=1 and server_doc_only=0 ;"
    SQL="${SQL1} ${SQL2}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$SADM_TMP_FILE1

    # Loop through the linux actives file list just produce
    while read wline
        do
        server=`echo $wline|awk '{ print $1 }'`
        domain=`echo $wline|awk '{ print $2 }'`

        # Test pinging the server - if doesn t work then skip server & Log error
        #-------------------------------------------------------------------------------------------
        sadm_logger " " ; sadm_logger " " ; sadm_logger "${SADM_DASH}"
        sadm_logger "Starting to process the Linux server : ${server}.${domain}"
        sadm_logger "ping -c 2 ${server}.${domain}"
        ping -c 2 ${server}.${domain} >/dev/null 2>/dev/null
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "Could not ping server ${server}.${server_domain} ..."
                sadm_logger " - Will not be able to process that server."
                sadm_logger " - WILL CONSIDER THAT IS OK (MAY BE POWEROFF OR AN UNPLUGGED LAPTOP)."
                sadm_logger "RETURN CODE IS 0 - OK"
                continue
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "Linux Total Error Count is now at $ERROR_COUNT"


        # CREATE LOCAL RECEIVING DIR
        # Making sure the $SADMIN/dat/$server exist on Local SADMIN server
        #-------------------------------------------------------------------------------------------
        sadm_logger " " 
        sadm_logger "Make sure the directory ${SADM_WWW_DIR_DAT}/${server} Exist"
        if [ ! -d "${SADM_WWW_DIR_DAT}/${server}" ]
            then sadm_logger "Creating ${SADM_WWW_DIR_DAT}/${server} directory"
                 mkdir -p "${SADM_WWW_DIR_DAT}/${server}"
                 chmod 2775 "${SADM_WWW_DIR_DAT}/${server}"
            else sadm_logger "Perfect ${SADM_WWW_DIR_DAT}/${server} directory already exist"
        fi


        # DR INFO FILES
        # Transfer $SADMIN/dat/disaster_recovery_info from Remote to $SADMIN/www/dat/$server/dr  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DIR_DAT}/${server}/dr"
        sadm_logger " " 
        sadm_logger "Make sure the directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_logger "Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_logger "Perfect ${WDIR} directory already exist"
        fi
        sadm_logger "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/"
        rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "ERROR NUMBER $RC for $server"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "Linux Total Error Count is now at $ERROR_COUNT"


        # NMON FILES
        # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server/nmon  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DIR_DAT}/${server}/nmon"                            # Local Receiving Dir.
        sadm_logger " " 
        sadm_logger "Make sure the directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_logger "Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_logger "Perfect ${WDIR} directory already exist"
        fi
        sadm_logger "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/"
        rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "ERROR NUMBER $RC for $server"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "Linux Total Error Count is now at $ERROR_COUNT"


        # SAR PERF FILES
        # Transfer Remote $SADMIN/dat/performance_data files to local $SADMIN/www/dat/$server/nmon  
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DIR_DAT}/${server}/sar"                             # Local Receiving Dir.
        sadm_logger " " 
        sadm_logger "Make sure the directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_logger "Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_logger "Perfect ${WDIR} directory already exist"
        fi
        sadm_logger "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_PERF_DIR}/ $WDIR/"
        rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_PERF_DIR}/ $WDIR/
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_logger "ERROR NUMBER $RC for $server"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_logger "RETURN CODE IS 0 - OK"
        fi
        sadm_logger "Linux Total Error Count is now at $ERROR_COUNT"
    done < $SADM_TMP_FILE1

    sadm_logger " "
    sadm_logger "FINAL number of LINUX Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#

    sadm_start                                                          # Make sure Dir. Struc. exist
    
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
    get_aix_files                                                       # Collect Files from AIX Servers
    AIX_ERROR=$?                                                        # AIX Nb. Errors while collecting
    get_linux_files                                                     # Collect Files from Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                           # Set Total AIX+Linux Errors
    sadm_logger " " ; sadm_logger " " ;                                 # Insert Blank lines in log
    sadm_logger "${SADM_DASH}"; sadm_logger "END OF PROCESSING"              # Advise user - End of Processing
    sadm_logger "${SADM_DASH}"                                               # Advise user that we are finish
    sadm_logger "Final Global Error count is at $SADM_EXIT_CODE"          # Advise nb. total errors.
    sadm_logger "${SADM_DASH}"                                               # Advise user that we are finish
    sadm_stop $SADM_EXIT_CODE                                             # End Process with exit Code
    exit $SADM_EXIT_CODE                                                  # Exit script
