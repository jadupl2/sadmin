#! /bin/sh
####################################################################################################
# Title      :  sadm_daily_data_collection.sh
# Description:  Get hardware Info & Performance Datafrom all active servers
# Version    :  2.4
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) sys_daily_data_collection.sh 1.4 21-04/2010
####################################################################################################
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2015 - Restructure and redesign for modularity - Jacques Duplessus
# 2017_12_17 J.Duplessis
#   V2.0    Restructure using one function for AIx and Linux
######################################################################################&&&&&&&#######
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



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
SADM_VER='2.0'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  

#
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
#===================================================================================================
#






# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
HW_DIR="$SADM_DAT_DIR/hw"	                     ; export HW_DIR        # Hardware Data collected
ERROR_COUNT=0                                    ; export ERROR_COUNT   # Global Error Counter
TOTAL_AIX=0                                      ; export TOTAL_AIX     # Nb Error in Aix Function
TOTAL_LINUX=0                                    ; export TOTAL_LINUX   # Nb Error in Linux Function
SADM_STAR=`printf %80s |tr " " "*"`              ; export SADM_STAR     # 80 * line
DEBUG_LEVEL=0                                    ; export DEBUG_LEVEL   # 0=NoDebug Higher=+Verbose




####################################################################################################
#    Get all actives Linux servers from the SADMIN Database and retrieve information files
####################################################################################################
#
get_config_files()
{
    sadm_writelog "${SADM_DASH}"
    sadm_writelog "Starting to process servers ..."

    sadm_writelog "Producing a list of all active servers"
    SQL1="SELECT srv_name,srv_ostype,srv_domain,srv_active,srv_sporadic from server "
    SQL2="where srv_active = True "
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1
    
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
            do
            xcount=`expr $xcount + 1`
            server=`  echo $wline|awk -F, '{ print $1 }'`
            domain=`echo $wline|awk -F, '{ print $3 }'`
            server_sporadic=` echo $wline|awk -F, '{ print $5 }'`


            # Test pinging the server - if doesn t work then skip server & Log error
            #-------------------------------------------------------------------------------------------
            sadm_writelog " " ; sadm_writelog " " ; sadm_writelog "${SADM_DASH}"
            sadm_writelog "Starting to process the server : ${server}.${domain}"
            sadm_writelog "ping -c 2 ${server}.${domain}"
            ping -c 2 ${server}.${domain} >/dev/null 2>/dev/null
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "Could not ping server ${server_name}.${server_domain} ..."
                    if [ "$server_sporadic" == "1" ]
                        then sadm_writelog "*** SERVER CLASS IS SPORADIC - NOT CONSIDER AS AN ERROR"
                             sadm_writelog "*** WILL CONTINUE PROCESSING WITH NEXT SERVER"
                             sadm_writelog "RETURN CODE IS 0 - OK"
                             continue
                        else sadm_writelog "*** ERROR : Will not be able to process that server."
                             sadm_writelog "*** WILL CONSIDER THAT AN ERROR (SERVER IS NOT DEFINE AS SPORADIC)"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                    fi
            fi
            if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count is now at $ERROR_COUNT" ;fi


            # CREATE LOCAL RECEIVING DIR
            # Making sure the $SADMIN/dat/$server exist on Local SADMIN server
            #-------------------------------------------------------------------------------------------
            sadm_writelog " " 
            sadm_writelog "Make sure the directory ${SADM_WWW_DAT_DIR}/${server} Exist"
            if [ ! -d "${SADM_WWW_DAT_DIR}/${server}" ]
                then sadm_writelog "Creating ${SADM_WWW_DAT_DIR}/${server} directory"
                     mkdir -p "${SADM_WWW_DAT_DIR}/${server}"
                     chmod 2775 "${SADM_WWW_DAT_DIR}/${server}"
                else sadm_writelog "Perfect ${SADM_WWW_DAT_DIR}/${server} directory already exist"
            fi

    
            # DR INFO FILES
            # Transfer $SADMIN/dat/disaster_recovery_info from Remote to $SADMIN/www/dat/$server/dr  Dir
            #-------------------------------------------------------------------------------------------
            WDIR="${SADM_WWW_DAT_DIR}/${server}/dr"                     # Local Receiving Dir.
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/ >>$SADM_LOG 2>&1
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "[ERROR] $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "[OK] Rsync Success"
            fi
            if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count is now at $ERROR_COUNT" ;fi


            # NMON FILES
            # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server/nmon  Dir
            #-------------------------------------------------------------------------------------------
            WDIR="${SADM_WWW_DAT_DIR}/${server}/nmon"                     # Local Receiving Dir.
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/ >>$SADM_LOG 2>&1
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "[ERROR] $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "[OK] Rsync Success"
            fi
            if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count is now at $ERROR_COUNT" ;fi


            # SAR PERF FILES
            # Transfer Remote $SADMIN/dat/performance_data files to local $SADMIN/www/dat/$server/sar 
            #-------------------------------------------------------------------------------------------
            WDIR="${SADM_WWW_DAT_DIR}/${server}/sar"                     # Local Receiving Dir.
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_SAR_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_SAR_DIR}/ $WDIR/ >>$SADM_LOG 2>&1
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "[ERROR] $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "[OK] Rsync Success"
            fi
            if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count is now at $ERROR_COUNT" ;fi
            done < $SADM_TMP_FILE1
    fi
    sadm_writelog " "
    sadm_writelog "FINAL number of Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Init Log & Dir. 
  
    # This Script should only be run on the SADMIN Server
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ] # Only run on SADM Server
        then sadm_writelog "Script can be run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # This Script Should only be run by the user 'root'
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # Get Statistics and Configuration files from AIX and Linux Servers
    get_config_files                                                    # Collect Files from Linux Servers
    if [ "$?"  -ne 0 ]
        then SADM_EXIT_CODE=1
        else SADM_EXIT_CODE=0
    fi
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Error code (0/1)
