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
# Version 1.7
# 2017_02_04    Jacques DUplessis - Don't rsync /sadmin/cfg entirely just sysmon.std file from now on
# Version 1.8
# 2017_06_03    Jacques DUplessis - Added the /sadmin/sys to rsync processing
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_VER='1.8'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis 
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose



# --------------------------------------------------------------------------------------------------
#                      Create Remote Directory - If it does not exist
# --------------------------------------------------------------------------------------------------
create_remote_dir()
{
    # Parameters received should always by two - If not write error to log and return to caller
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters"
             sadm_writelog "Function received $* and this isn't valid"
             sadm_writelog "Should received 'ServerName' and 'Remote Directory'"
             return 1
    fi

    # Save rsync information
    REM_SERVER=$1                                                       # Remote server Name FQDN
    REM_DIR=$2                                                          # Dir that should exist 

    sadm_writelog "ssh -n ${REM_SERVER} ls -l ${REM_DIR}"
    ssh -n ${REM_SERVER} ls -l ${REM_DIR} >/dev/null 2>&1
    RC=$? 
    
    # If SSH Connection is OK and Directory exist on server, then OK
    if [ $RC -eq 0 ]
        then sadm_writelog "[ OK ] Directory ${REM_DIR} exist on ${REM_SERVER}"
             return 0
    fi 

    # If SSH Connection is OK and BUT Directory doesn't exist on server, then create it
    if [ $RC -eq 2 ]
        then ssh ${REM_SERVER} mkdir -p ${REM_DIR} >/dev/null 2>&1
             if [ $RC -eq 0 ] 
                then sadm_writelog "[ OK ] Directory ${REM_DIR} exist on ${REM_SERVER}"
                     return 0
                else sadm_writelog "[ ERROR ] Couldn't create directory ${REM_DIR} on ${REM_SERVER}"
                     return 1
             fi
    fi 
    
    sadm_writelog "[ ERROR ] Couldn't check existance of ${REM_DIR} on ${REM_SERVER}"
    return 1
}



# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    sadm_writelog " "
    sadm_writelog "$SADM_DASH" 
    sadm_writelog "Processing active Linux Servers"

    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_active from sadm.server  "
    SQL2="where srv_ostype = 'linux' and srv_active = True "
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    if [ $DEBUG_LEVEL -gt 5 ] 
       then sadm_writelog "$SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c $SQL" 
    fi
    $SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c "$SQL" >$SADM_TMP_FILE1
 
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk -F, '{ print $1 }'`
              server_os=`    echo $wline|awk -F, '{ print $2 }'`
              server_domain=`echo $wline|awk -F, '{ print $3 }'`
              fqdn_server=`echo ${server_name}.${server_domain}`        # Create FQN Server Name              
              sadm_writelog "" ; sadm_writelog "${SADM_DASH}"
              sadm_writelog "Processing ($xcount) ${fqdn_server} - os:${server_os}"
              
              # Ping the server - Server or Laptop may be unplugged
              sadm_writelog "ping -c 2 ${server_name}.${server_domain}"
              ping -c 2 ${server_name}.${server_domain} >/dev/null 2>/dev/null
              RC=$?
              if [ $RC -ne 0 ]
                 then sadm_writelog "Could not ping server ${server_name}.${server_domain} ..."
                      sadm_writelog "Will not be able to process server ${server_name}"
                      sadm_writelog "Will consider that's ok (May be down or be Laptop unplugged)..."
                      sadm_writelog "Return Code : 0 - OK"
                      continue
                 else sadm_writelog "Good, I have a ping response"
              fi
              
               

              # Test if $SADM_BIN_DIR exist on remote - If not Create it
              create_remote_dir "${server_name}" "${SADM_BIN_DIR}"

              #sadm_writelog "ssh -n ${server_name} ls -l ${SADM_BIN_DIR}"
              #ssh -n ${server_name} ls -l ${SADM_BIN_DIR} >/dev/null 2>&1
              #RC=$? 
              #if [ $RC -ne 0 ]
              #   then sadm_writelog "Creating ${SADM_BIN_DIR} on ${server_name}"
              #        ssh ${server_name} mkdir -p ${SADM_BIN_DIR} >/dev/null 2>&1
              #fi
             
              # Do the Rsync /sadmin/bin
              sadm_writelog "rsync -ar --delete ${SADM_BIN_DIR}/ ${server_name}.${server_domain}:${SADM_BIN_DIR}/"
              rsync -ar --delete ${SADM_BIN_DIR}/ ${server_name}.${server_domain}:${SADM_BIN_DIR}/
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              
              

              # Test if $SADM_SYS_DIR exist on remote - If not Create it
              sadm_writelog "ssh -n ${server_name} ls -l ${SADM_SYS_DIR}"
              ssh -n ${server_name} ls -l ${SADM_SYS_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_SYS_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_SYS_DIR} >/dev/null 2>&1
              fi

              # Do the Rsync /sadmin/jac/bin
              sadm_writelog "rsync -ar --delete ${SADM_SYS_DIR}/ ${server_name}.${server_domain}:${SADM_SYS_DIR}/"
              rsync -ar --delete ${SADM_SYS_DIR}/ ${server_name}.${server_domain}:${SADM_SYS_DIR}/
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              
                             

              # Test if $SADM_BASE_DIR/jac/bin exist on remote - If not Create it
              sadm_writelog "ssh -n ${server_name} ls -l ${SADM_BASE_DIR/jac/bin}"
              ssh -n ${server_name} ls -l ${SADM_BASE_DIR/jac/bin} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_BASE_DIR/jac/bin} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_BASE_DIR/jac/bin} >/dev/null 2>&1
              fi

              # Do the Rsync /sadmin/jac/bin
              sadm_writelog "rsync -ar --delete ${SADM_BASE_DIR}/jac/bin/ ${server_name}.${server_domain}:${SADM_BASE_DIR}/jac/bin/"
              rsync -ar --delete ${SADM_BASE_DIR}/jac/bin/ ${server_name}.${server_domain}:${SADM_BASE_DIR}/jac/bin/
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              
               

              # Test if $SADM_LIB_DIR exist on remote - If not Create it
              sadm_writelog "ssh -n ${server_name} ls -l ${SADM_LIB_DIR}"
              ssh -n ${server_name} ls -l ${SADM_LIB_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_LIB_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_LIB_DIR} >/dev/null 2>&1
              fi

              # Do the Rsync /sadmin/lib
              sadm_writelog "rsync -ar --delete ${SADM_LIB_DIR}/ ${server_name}.${server_domain}:${SADM_LIB_DIR}/"
              rsync -ar --delete ${SADM_LIB_DIR}/ ${server_name}.${server_domain}:${SADM_LIB_DIR}/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi

               
 
              # Test if $SADM_CFG_DIR exist on remote - If not Create it
              sadm_writelog "ssh -n ${server_name} ls -l ${SADM_CFG_DIR}"
              ssh -n ${server_name} ls -l ${SADM_CFG_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_CFG_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_CFG_DIR} >/dev/null 2>&1
              fi

             # Do the Rsync /sadmin/cfg
              sadm_writelog "rsync -ar  --delete ${SADM_CFG_DIR}/sysmon.std ${server_name}.${server_domain}:${SADM_CFG_DIR}/sysmon.std"
              rsync -ar  --delete ${SADM_CFG_DIR}/sysmon.std ${server_name}.${server_domain}:${SADM_CFG_DIR}/sysmon.std
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              sadm_writelog "rsync -ar  --delete ${SADM_CFG_DIR}/sadmin.cfg ${server_name}.${server_domain}:${SADM_CFG_DIR}/sadmin.cfg"
              rsync -ar  --delete ${SADM_CFG_DIR}/sadmin.cfg ${server_name}.${server_domain}:${SADM_CFG_DIR}/sadmin.cfg
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi              
               
              # Do the Rsync /storix/custom
              #sadm_writelog "${server_name}.${server_domain} 'mkdir -p /storix/custom'"
              #ssh ${server_name}.${server_domain} "mkdir -p /storix/custom"
              #
              sadm_writelog "rsync -ar  --delete /storix/custom/ ${server_name}.${server_domain}:/storix/custom/"
              rsync -ar  --delete /storix/custom/ ${server_name}.${server_domain}:/storix/custom/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
               
  
              # Test if $SADM_PKG_DIR exist on remote - If not Create it
              sadm_writelog "ssh -n ${server_name} ls -l ${SADM_PKG_DIR}"
              ssh -n ${server_name} ls -l ${SADM_PKG_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_PKG_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_PKG_DIR} >/dev/null 2>&1
              fi
                             
              # Do the Rsync /sadmin/pkg
              sadm_writelog "rsync -ar  --delete ${SADM_PKG_DIR}/ ${server_name}.${server_domain}:${SADM_PKG_DIR}/"
              rsync -ar  --delete ${SADM_PKG_DIR}/ ${server_name}.${server_domain}:${SADM_PKG_DIR}/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              sadm_writelog "Total Error Count after ${server_name} is ${ERROR_COUNT}."
              done < $SADM_TMP_FILE1
    fi
    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"
    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
#                      Process Aix servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    sadm_writelog " "
    sadm_writelog "$SADM_DASH" 
    sadm_writelog "Processing active Aix Servers" 

    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_active from sadm.server  "
    SQL2="where srv_ostype = 'aix' and srv_active = True "
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    if [ $DEBUG_LEVEL -gt 5 ] 
       then sadm_writelog "$SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c $SQL" 
    fi
    $SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c "$SQL" >$SADM_TMP_FILE1
    
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk -F, '{ print $1 }'`
              server_os=`    echo $wline|awk -F, '{ print $2 }'`
              server_domain=`echo $wline|awk -F, '{ print $3 }'`
              sadm_writelog "${SADM_DASH}"
              info_line="Processing ($xcount) ${server_name}.${server_domain} - "
              info_line="${info_line}os:${server_os}"
              sadm_writelog "$info_line"
              # Ping the server - Server or Laptop may be unplugged
              sadm_writelog "ping -c 2 ${server_name}.${server_domain}"
              ping -c 2 ${server_name}.${server_domain} >/dev/null 2>/dev/null
              RC=$?
              if [ $RC -ne 0 ]
                 then sadm_writelog "Could not ping server ${server_name}.${server_domain} ..."
                      sadm_writelog "Will not be able to process server ${server_name}"
                      sadm_writelog "Will consider that's ok (May be down or be Laptop unplugged)..."
                      sadm_writelog "Return Code : 0 - OK"
                      continue
                 else sadm_writelog "Good, I have a ping response"
              fi
              

              # Test if $SADM_BIN_DIR exist on remote - If not Create it
              sadm_writelog "ssh ${server_name} ls -l ${SADM_BIN_DIR}"
              ssh ${server_name} ls -l ${SADM_BIN_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_BIN_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_BIN_DIR} >/dev/null 2>&1
              fi

              # Do the Rsync /sadmin/bin
              sadm_writelog "rsync -ar --delete ${SADM_BIN_DIR}/ ${server_name}.${server_domain}:${SADM_BIN_DIR}/"
              rsync -ar --delete ${SADM_BIN_DIR}/ ${server_name}.${server_domain}:${SADM_BIN_DIR}/
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              
              
              # Do the Rsync /sadmin/jac/bin
              sadm_writelog "rsync -ar --delete ${SADM_BASE_DIR}/jac/bin/ ${server_name}.${server_domain}:${SADM_BASE_DIR}/jac/bin/"
              rsync -ar --delete ${SADM_BASE_DIR}/jac/bin/ ${server_name}.${server_domain}:${SADM_BASE_DIR}/jac/bin/
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              
 
              # Test if $SADM_SYS_DIR exist on remote - If not Create it
              sadm_writelog "ssh -n ${server_name} ls -l ${SADM_SYS_DIR}"
              ssh -n ${server_name} ls -l ${SADM_SYS_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_SYS_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_SYS_DIR} >/dev/null 2>&1
              fi

              # Do the Rsync /sadmin/jac/bin
              sadm_writelog "rsync -ar --delete ${SADM_SYS_DIR}/ ${server_name}.${server_domain}:${SADM_SYS_DIR}/"
              rsync -ar --delete ${SADM_SYS_DIR}/ ${server_name}.${server_domain}:${SADM_SYS_DIR}/
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
                  

              # Test if $SADM_LIB_DIR exist on remote - If not Create it
              sadm_writelog "ssh ${server_name} ls -l ${SADM_LIB_DIR}"
              ssh ${server_name} ls -l ${SADM_LIB_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_LIB_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_LIB_DIR} >/dev/null 2>&1
              fi

              # Do the Rsync /sadmin/lib
              sadm_writelog "rsync -ar --delete ${SADM_LIB_DIR}/ ${server_name}.${server_domain}:${SADM_LIB_DIR}/"
              rsync -ar --delete ${SADM_LIB_DIR}/ ${server_name}.${server_domain}:${SADM_LIB_DIR}/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi

               
              # Test if $SADM_CFG_DIR exist on remote - If not Create it
              sadm_writelog "ssh ${server_name} ls -l ${SADM_CFG_DIR}"
              ssh ${server_name} ls -l ${SADM_CFG_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_CFG_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_CFG_DIR} >/dev/null 2>&1
              fi

              # Do the Rsync /sadmin/cfg
              sadm_writelog "rsync -ar  --delete ${SADM_CFG_DIR}/sysmon.std ${server_name}.${server_domain}:${SADM_CFG_DIR}/sysmon.std"
              rsync -ar  --delete ${SADM_CFG_DIR}/sysmon.std ${server_name}.${server_domain}:${SADM_CFG_DIR}/sysmon.std
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
               
               
              # Do the Rsync /storix/custom
              sadm_writelog "${server_name}.${server_domain} 'mkdir -p /storix/custom'"
              ssh ${server_name}.${server_domain} "mkdir -p /storix/custom"
              #
              sadm_writelog "rsync -ar  --delete /storix/custom/ ${server_name}.${server_domain}:/storix/custom/"
              rsync -ar  --delete /storix/custom/ ${server_name}.${server_domain}:/storix/custom/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
               
  
              # Test if $SADM_PKG_DIR exist on remote - If not Create it
              sadm_writelog "ssh ${server_name} ls -l ${SADM_PKG_DIR}"
              ssh ${server_name} ls -l ${SADM_PKG_DIR} >/dev/null 2>&1
              RC=$? 
              if [ $RC -ne 0 ]
                 then sadm_writelog "Creating ${SADM_PKG_DIR} on ${server_name}"
                      ssh ${server_name} mkdir -p ${SADM_PKG_DIR} >/dev/null 2>&1
              fi
               
              # Do the Rsync /sadmin/pkg
              sadm_writelog "rsync -ar  --delete ${SADM_PKG_DIR}/ ${server_name}.${server_domain}:${SADM_PKG_DIR}/"
              rsync -ar  --delete ${SADM_PKG_DIR}/ ${server_name}.${server_domain}:${SADM_PKG_DIR}/
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "********** ERROR NUMBER $RC for ${server_name}.${server_domain}"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "Return Code : 0 - OK"
              fi
              sadm_writelog "Total Error Count after ${server_name} is ${ERROR_COUNT}."
              done < $SADM_TMP_FILE1
    fi
    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"
    return $ERROR_COUNT
}





# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
        
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
        then sadm_writelog "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
        
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    LINUX_ERROR=0; AIX_ERROR=0                                          # Initialize Error count to 0
    process_linux_servers                                               # Process all Active Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    process_aix_servers                                                 # Process all Active Aix Servers
    AIX_ERROR=$?                                                        # Set Nb. Errors while processing
    sadm_writelog "WE HAD $LINUX_ERROR ERROR(S) WHILE PROCESSING LINUX SERVERS"
    sadm_writelog "WE HAD $AIX_ERROR ERROR(S) WHILE PROCESSING AIX SERVERS"
    
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                         # Total = AIX+Linux Errors
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC to or 0
    exit $SADM_EXIT_CODE                                                # Exit With Global Error code (0/1)
