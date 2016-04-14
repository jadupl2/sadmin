#! /bin/sh
#############################################################################################
# Title      :  sadm_daily_data_collection.sh
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
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
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
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

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
#SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
#SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
#SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=60                        ; export SADM_SAR_KEEPDAYS  # Days to keep old *.sar
#SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
#SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log
#SADM_PGUSER="postgres"                      ; export SADM_PGUSER        # PostGres User Name
#SADM_PGGROUP="postgres"                     ; export SADM_PGGROUP       # PostGres Group Name
#SADM_PGDB=""                                ; export SADM_PGDB          # PostGres DataBase Name
#SADM_PGSCHEMA=""                            ; export SADM_PGSCHEMA      # PostGres DataBase Schema
#SADM_PGHOST=""                              ; export SADM_PGHOST        # PostGres DataBase Host
#SADM_PGPORT=5432                            ; export SADM_PGPORT        # PostGres Listening Port
#SADM_RW_PGUSER=""                           ; export SADM_RW_PGUSER     # Postgres Read/Write User 
#SADM_RW_PGPWD=""                            ; export SADM_RW_PGPWD      # PostGres Read/Write Passwd
#SADM_RO_PGUSER=""                           ; export SADM_RO_PGUSER     # Postgres Read Only User 
#SADM_RO_PGPWD=""                            ; export SADM_RO_PGPWD      # PostGres Read Only Passwd
#SADM_SERVER=""                              ; export SADM_SERVER        # Server FQN Name
#SADM_DOMAIN=""                              ; export SADM_DOMAIN        # Default Domain Name

#===================================================================================================
#






# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
PGUSER="squery"                                  ; export PGUSER        # Postgres Database User
PGHOST="holmes.maison.ca"                        ; export PGHOST        # Postgres Database Host
PSQL="$(which psql)"                             ; export PSQL          # Location of psql program
PGPASSFILE=/sadmin/cfg/.pgpass                   ; export PGPASSFILE    
HW_DIR="$SADM_DAT_DIR/hw"	                     ; export HW_DIR        # Hardware Data collected
ERROR_COUNT=0                                    ; export ERROR_COUNT   # Global Error Counter
TOTAL_AIX=0                                      ; export TOTAL_AIX     # Nb Error in Aix Function
TOTAL_LINUX=0                                    ; export TOTAL_LINUX   # Nb Error in Linux Function
SADM_STAR=`printf %80s |tr " " "*"`              ; export SADM_STAR     # 80 * line


# --------------------------------------------------------------------------------------------------
#                           Produce a List of all actives AIX Servers
# --------------------------------------------------------------------------------------------------
#
get_aix_files()
{
    sadm_writelog "${SADM_DASH}"
    sadm_writelog "Starting to process AIX Servers ..."

    sadm_writelog "Producing a list of all Linux active servers"
    SQL1="SELECT srv_name,srv_ostype,srv_domain,srv_type,srv_active,srv_sporadic from sadm.server "
    SQL2="where srv_ostype = 'aix' and srv_active = True "
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    $PSQL -A -F , -t -h $PGHOST sadmin -U $PGUSER -c "$SQL" >$SADM_TMP_FILE1
    
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
            do
            xcount=`expr $xcount + 1`
            server=`  echo $wline|awk -F, '{ print $1 }'`
            domain=`echo $wline|awk -F, '{ print $3 }'`
            server_sporadic=` echo $wline|awk -F, '{ print $6 }'`


            # Test pinging the server - if doesn t work then skip server & Log error
            #-------------------------------------------------------------------------------------------
            sadm_writelog " " ; sadm_writelog " " ; sadm_writelog "${SADM_DASH}"
            sadm_writelog "Starting to process the AIX server : ${server}.${domain}"
            sadm_writelog "ping -c 2 ${server}.${domain}"
            ping -c 2 ${server}.${domain} >/dev/null 2>/dev/null
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "Could not ping server ${server_name}.${server_domain} ..."
                    if [ "$server_sporadic" == "t" ]
                        then sadm_writelog "*** SERVER CLASS IS SPORADIC - NOT CONSIDER AS AN ERROR"
                             sadm_writelog "*** WILL CONTINUE PROCESSING WITH NEXT SERVER"
                             sadm_writelog "RETURN CODE IS 0 - OK"
                             continue
                        else sadm_writelog "*** ERROR : Will not be able to process that server."
                             sadm_writelog "*** WILL CONSIDER THAT AN ERROR (SERVER IS NOT DEFINE AS SPORADIC)"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                    fi
            fi
            sadm_writelog "Linux Total Error Count is now at $ERROR_COUNT"
    
    
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
            WDIR="$SADM_WWW_DR_DIR"
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "ERROR NUMBER $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "RETURN CODE IS 0 - OK"
            fi
            sadm_writelog "AIX Total Error Count is now at $ERROR_COUNT"
    

            # NMON FILES
            # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server/nmon  Dir
            #-------------------------------------------------------------------------------------------
            WDIR="$SADM_WWW_NMON_DIR"                            # Local Receiving Dir.
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "ERROR NUMBER $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "RETURN CODE IS 0 - OK"
            fi
            sadm_writelog "AIX Total Error Count is now at $ERROR_COUNT"


            # SAR PERF FILES
            # Transfer Remote $SADMIN/dat/performance_data files to local $SADMIN/www/dat/$server/nmon  
            #-------------------------------------------------------------------------------------------
            WDIR="$SADM_WWW_SAR_DIR"                             # Local Receiving Dir.
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_SAR_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_SAR_DIR}/ $WDIR/
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "ERROR NUMBER $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "RETURN CODE IS 0 - OK"
            fi
            sadm_writelog "AIX Total Error Count is now at $ERROR_COUNT"
            done < $SADM_TMP_FILE1
    fi
    
    sadm_writelog " "
    sadm_writelog "FINAL number of AIX Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT
}



####################################################################################################
#    Get all actives Linux servers from the SADMIN Database and retrieve information files
####################################################################################################
#
get_linux_files()
{
    sadm_writelog "${SADM_DASH}"
    sadm_writelog "Starting to process Linux Servers ..."

    sadm_writelog "Producing a list of all Linux active servers"
    SQL1="SELECT srv_name,srv_ostype,srv_domain,srv_type,srv_active,srv_sporadic from sadm.server "
    SQL2="where srv_ostype = 'linux' and srv_active = True "
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    $PSQL -A -F , -t -h $PGHOST sadmin -U $PGUSER -c "$SQL" >$SADM_TMP_FILE1
    
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
            do
            xcount=`expr $xcount + 1`
            server=`  echo $wline|awk -F, '{ print $1 }'`
            domain=`echo $wline|awk -F, '{ print $3 }'`
            server_sporadic=` echo $wline|awk -F, '{ print $6 }'`


            # Test pinging the server - if doesn t work then skip server & Log error
            #-------------------------------------------------------------------------------------------
            sadm_writelog " " ; sadm_writelog " " ; sadm_writelog "${SADM_DASH}"
            sadm_writelog "Starting to process the AIX server : ${server}.${domain}"
            sadm_writelog "ping -c 2 ${server}.${domain}"
            ping -c 2 ${server}.${domain} >/dev/null 2>/dev/null
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "Could not ping server ${server_name}.${server_domain} ..."
                    if [ "$server_sporadic" == "t" ]
                        then sadm_writelog "*** SERVER CLASS IS SPORADIC - NOT CONSIDER AS AN ERROR"
                             sadm_writelog "*** WILL CONTINUE PROCESSING WITH NEXT SERVER"
                             sadm_writelog "RETURN CODE IS 0 - OK"
                             continue
                        else sadm_writelog "*** ERROR : Will not be able to process that server."
                             sadm_writelog "*** WILL CONSIDER THAT AN ERROR (SERVER IS NOT DEFINE AS SPORADIC)"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                    fi
            fi
            sadm_writelog "Linux Total Error Count is now at $ERROR_COUNT"


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
            WDIR="$SADM_WWW_DR_DIR"
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_DR_DIR}/ $WDIR/
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "ERROR NUMBER $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "RETURN CODE IS 0 - OK"
            fi
            sadm_writelog "Linux Total Error Count is now at $ERROR_COUNT"


            # NMON FILES
            # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server/nmon  Dir
            #-------------------------------------------------------------------------------------------
            WDIR="$SADM_WWW_NMON_DIR"                            # Local Receiving Dir.
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_NMON_DIR}/ $WDIR/
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "ERROR NUMBER $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "RETURN CODE IS 0 - OK"
            fi
            sadm_writelog "Linux Total Error Count is now at $ERROR_COUNT"


            # SAR PERF FILES
            # Transfer Remote $SADMIN/dat/performance_data files to local $SADMIN/www/dat/$server/nmon  
            #-------------------------------------------------------------------------------------------
            WDIR="$SADM_WWW_SAR_DIR"                             # Local Receiving Dir.
            sadm_writelog " " 
            sadm_writelog "Make sure the directory $WDIR Exist"
            if [ ! -d "${WDIR}" ]
                then sadm_writelog "Creating ${WDIR} directory"
                     mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
                else sadm_writelog "Perfect ${WDIR} directory already exist"
            fi
            sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_SAR_DIR}/ $WDIR/"
            rsync -var --delete -e 'ssh -qp32' ${server}:${SADM_SAR_DIR}/ $WDIR/
            RC=$?
            if [ $RC -ne 0 ]
               then sadm_writelog "ERROR NUMBER $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else sadm_writelog "RETURN CODE IS 0 - OK"
            fi
            sadm_writelog "Linux Total Error Count is now at $ERROR_COUNT"
            done < $SADM_TMP_FILE1
    fi
    sadm_writelog " "
    sadm_writelog "FINAL number of LINUX Error(s) detected is $ERROR_COUNT"
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
    get_aix_files                                                       # Collect Files from AIX Servers
    AIX_ERROR=$?                                                        # AIX Nb. Errors while collecting
    get_linux_files                                                     # Collect Files from Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                         # Set Total AIX+Linux Errors

    sadm_stop $SADM_EXIT_CODE                                           # End Process with exit Code
    exit $SADM_EXIT_CODE                                                # Exit script
