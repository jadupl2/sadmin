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
SADM_VER='2.4'                             ; export SADM_VER            # This Script Version
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
SADM_MAIL_TYPE=3                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
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
#



# --------------------------------------------------------------------------------------------------
#                           Script Variables Definitions
# --------------------------------------------------------------------------------------------------
#
PGUSER="squery"                                  ; export PGUSER        # Postgres Database User
PGHOST="holmes.maison.ca"                        ; export PGHOST        # Postgres Database Host
PSQL="$(which psql)"                             ; export PSQL          # Location of psql program
PGPASSFILE=/sadmin/cfg/.pgpass                   ; export PGPASSFILE    
USCRIPT="${SADM_BIN_DIR}/sadm_osupdate_client.sh" ; export USCRIPT      # Script to execute on nodes
REMOTE_SSH="/usr/bin/ssh -qnp 32"               ; export REMOTE_SSH     # SSH command for remote node
ERROR_COUNT=0                                   ; export ERROR_COUNT    # Nb. of update failed
WARNING_COUNT=0                                 ; export WARNING_COUNT  # Nb. of warning failed
STAR_LINE=`printf %80s |tr " " "*"`             ; export STAR_LINE      # 80 equals sign line




# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    sadm_writelog ""
    sadm_writelog ""
    sadm_writelog "${SADM_DASH}"
    sadm_writelog "PROCESS LINUX SERVERS"

    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_osupdate, srv_osupdate_reboot, "
    SQL2="srv_osupdate_day, srv_osupdate_period, srv_sporadic, srv_active from sadm.server "
    SQL3="where srv_ostype = 'linux' and srv_active = True "
    SQL4="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"
    $PSQL -A -F , -t -h $PGHOST sadmin -U $PGUSER -c "$SQL" >$SADM_TMP_FILE1
    
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
            do
            xcount=`expr $xcount + 1`
            server_name=`               echo $wline|awk -F, '{ print $1 }'`
            server_os=`                 echo $wline|awk -F, '{ print $2 }'`
            server_domain=`             echo $wline|awk -F, '{ print $3 }'`
            server_osupdate=`           echo $wline|awk -F, '{ print $4 }'`
            server_osupdate_reboot=`    echo $wline|awk -F, '{ print $5 }'`
            server_osupdate_day=`       echo $wline|awk -F, '{ print $6 }'`
            server_osupdate_period=`    echo $wline|awk -F, '{ print $7 }'`
            server_sporadic=`           echo $wline|awk -F, '{ print $8 }'`
            sadm_writelog " "
            sadm_writelog "${STAR_LINE}"
            sadm_writelog "${STAR_LINE}"
            info_line="Processing ($xcount) ${server_name}.${server_domain} - "
            info_line="${info_line}os:${server_os}"
            sadm_writelog "$info_line"
            
            sadm_writelog "Ping the selected host ${server_name}.${server_domain}"
            ping -c2 ${server_name}.${server_domain} >> /dev/null 2>&1
            if [ $? -ne 0 ]
              then sadm_writelog "Error trying to ping the server ${server_name}.${server_domain}"
                   if [ "$server_sporadic" == "t" ]
                       then sadm_writelog "*** SERVER CLASS IS SPORADIC - NOT CONSIDER AS AN ERROR"
                            sadm_writelog "*** WILL CONTINUE UPDATE WITH NEXT SERVER"
                            if [ "$SADM_MAIL_TYPE" == "3" ]
                                then wsubject="SADM: WARNING O/S Update - Server $server_name (OFFLINE)" 
                                     echo "Server was OFFLINE"  | mail -s "$wsubject" $SADM_MAIL_ADDR
                            fi
                       else sadm_writelog "Update of server ${server_name}.${server_domain} Aborted"
                            WARNING_COUNT=$(($WARNING_COUNT+1))
                   fi
                   sadm_writelog "Total error count is at $ERROR_COUNT and warning at $WARNING_COUNT"
                   continue
              else sadm_writelog "Ping went OK"
            fi

            if [ "$server_osupdate" == "f" ]
                then sadm_writelog "*** O/S UPDATE IS OFF FOR THIS SERVER"
                     sadm_writelog "*** NO O/S UPDATE WILL BE PERFORM - CONTINUE WITH NEXT SERVER"
                     if [ "$SADM_MAIL_TYPE" == "3" ]
                         then wsubject="SADM: WARNING O/S Update - Server $server_name (O/S Update OFF)" 
                              echo "Server O/S Update is OFF"  | mail -s "$wsubject" $SADM_MAIL_ADDR
                     fi
                else sadm_writelog "Starting $USCRIPT on ${server_name}.${server_domain}"
                     sadm_writelog "$REMOTE_SSH ${server_name}.${server_domain} $USCRIPT"
                     $REMOTE_SSH ${server_name}.${server_domain} $USCRIPT
                     if [ $? -ne 0 ]
                        then sadm_writelog "Error starting $USCRIPT on ${server_name}.${server_domain}"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                        else sadm_writelog "Script was submitted with no error."
                     fi
            fi
            sadm_writelog "Total Error is $ERROR_COUNT and Warning at $WARNING_COUNT"
            sadm_writelog " "
            done < $SADM_TMP_FILE1
    fi
    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Total Error is $ERROR_COUNT and Warning at $WARNING_COUNT"
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    
    # RUN ON THE SADMIN MAIN SERVER ONLY
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ] # Only run on SADMIN 
        then sadm_writelog "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # TO BE RUN BY THE ROOT USER
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    process_linux_servers                                               # Go Update Linux Servers
    SADM_EXIT_CODE=$?                                                   # Save Exit Code

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
