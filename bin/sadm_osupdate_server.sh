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
# Version 2.6 - Nov 2016 
#       Insert Logic to Pass a parameter (Y or N) to sadm_osupdate_client.sh to Reboot ot not
#       the server after a successfull update. Reboot is specified in the Database (Web Interface)
#       on a server by server basis.
# --------------------------------------------------------------------------------------------------
# Version 2.7 - Nov 2016
#       Log will now be cumulative (Not clear every time the script in run)
# --------------------------------------------------------------------------------------------------
#
#



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
SADM_VER='2.7'                             ; export SADM_VER            # Script Version
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
ERROR_COUNT=0                               ; export ERROR_COUNT        # Nb. of update failed
WARNING_COUNT=0                             ; export WARNING_COUNT      # Nb. of warning failed
STAR_LINE=`printf %80s |tr " " "*"`         ; export STAR_LINE          # 80 equals sign line

# Script That is run on every client to update the Operating System
USCRIPT="${SADM_BIN_DIR}/sadm_osupdate_client.sh" ; export USCRIPT      # Script to execute on nodes


# --------------------------------------------------------------------------------------------------
#               Update Last O/S Update Date and Result in Server Table in sadm Database
# --------------------------------------------------------------------------------------------------
update_server_db()
{
    WSERVER=$1                                                          # Save Server name Recv.
    WSTATUS=$2                                                          # Save Server Update Status
    WCURDAT=`date "+%C%y.%m.%d %H:%M:%S"`                               # Get & Format Update Date
    sadm_writelog "Update $WSERVER row in DataBase" 
    SQL1="UPDATE sadm.server SET " 
    SQL2="srv_last_update = '${WCURDAT}', "
    SQL3="srv_osupdate_status = '${WSTATUS}' "
    SQL4="where srv_name = '${WSERVER}' ;"
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"
    if [ $DEBUG_LEVEL -gt 5 ] 
       then sadm_writelog "$SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RW_PGUSER -c $SQL" 
            sadm_writelog "PGPASSFILE = $PGPASSFILE" 
    fi
    $SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RW_PGUSER -c "$SQL" >> $SADM_LOG 2>&1
    if [ $? -ne 0 ]
        then sadm_writelog "Error updating the row of $WSERVER in Database" 
             RCU=1
        else sadm_writelog "Last O/S Update date and status is updated for $WSERVER" 
             RCU=0
    fi
    return $RCU
}





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
    #$PSQL -A -F , -t -h $PGHOST sadmin -U $PGUSER -c "$SQL" >$SADM_TMP_FILE1
    if [ $DEBUG_LEVEL -gt 5 ] 
       then sadm_writelog "$SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c $SQL" 
    fi
    $SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c "$SQL" >$SADM_TMP_FILE1
   
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
            
            # Ping Server to check if it is network reachable.
            sadm_writelog "Ping the selected host ${server_name}.${server_domain}"
            ping -c2 ${server_name}.${server_domain} >> /dev/null 2>&1
            if [ $? -ne 0 ]
              then sadm_writelog "Error trying to ping the server ${server_name}.${server_domain}"
                   if [ "$server_sporadic" == "t" ]
                       then sadm_writelog "*** SERVER CLASS IS SPORADIC - NOT CONSIDER AS AN ERROR"
                            sadm_writelog "*** WILL CONTINUE UPDATE WITH NEXT SERVER"
                            if [ "$SADM_MAIL_TYPE" == "3" ]
                                then wsubject="SADM: WARNING O/S Update - Server $server_name (OFFLINE)" 
                                     echo "Server $server was OFFLINE at `date`"  | mail -s "$wsubject" $SADM_MAIL_ADDR
                            fi
                       else sadm_writelog "Update of server ${server_name}.${server_domain} Aborted"
                            WARNING_COUNT=$(($WARNING_COUNT+1))
                   fi
                   sadm_writelog "Total error count is at $ERROR_COUNT and warning at $WARNING_COUNT"
                   continue
              else sadm_writelog "Ping went OK"
            fi


            # If Server is network reachable, but the O/S Update field is OFF in DB Skip Update
            if [ "$server_osupdate" == "f" ]
                then sadm_writelog "*** O/S UPDATE IS OFF FOR THIS SERVER"
                     sadm_writelog "*** NO O/S UPDATE WILL BE PERFORM - CONTINUE WITH NEXT SERVER"
                     if [ "$SADM_MAIL_TYPE" == "3" ]
                         then wsubject="SADM: WARNING O/S Update - Server $server_name (O/S Update OFF)" 
                              echo "Server O/S Update is OFF"  | mail -s "$wsubject" $SADM_MAIL_ADDR
                     fi
                else WREBOOT=" N"                                       # Default is no reboot
                     if [ "$server_osupdate_reboot" == "t" ]            # If Requested in Database
                        then WREBOOT="Y"                                # Set Reboot flag to ON
                     fi                                                 # This reboot after Update
                     sadm_writelog "Starting $USCRIPT on ${server_name}.${server_domain}"
                     sadm_writelog "$SADM_SSH_CMD ${server_name}.${server_domain} $USCRIPT $WREBOOT"
                     $SADM_SSH_CMD ${server_name}.${server_domain} $USCRIPT $WREBOOT
                     if [ $? -ne 0 ]
                        then sadm_writelog "Error starting $USCRIPT on ${server_name}.${server_domain}"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                             update_server_db "${server_name}" "F"  
                        else sadm_writelog "Script was submitted with no error."
                             update_server_db "${server_name}" "S"  
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
