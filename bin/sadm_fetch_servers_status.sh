#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_fetch_servers_status.sh
#   Synopsis :  Rsync all rch/log/rpt files from servers farm to SADMIN Server
#   Version  :  1.0
#   Date     :  December 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_fetch_servers_status.sh 1.0 2015.09.06
# --------------------------------------------------------------------------------------------------
#  History
#  1.6  Dec 2016    Major changes to include ssh test to each server and alert when not working
#                   Logic was redone , almost rewritten
#                   now include -d[1-9] switch to be more verbose during execution
#  1.8  Feb 2017    Change Script name and change SADM server default crontab 
# --------------------------------------------------------------------------------------------------
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
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
#SADM_SSH_CMD="${SADM_SSH} -o 'ConnectTimeout 10' -qnp ${SADM_SSH_PORT} " ; export SADM_SSH_CMD  
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " ; export SADM_SSH_CMD  
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


#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N 
#===================================================================================================
help_usage()
{
    sadm_writelog "${SADM_PN} usage : " 
    sadm_writelog "    -d [Debug Level]"
    sadm_writelog "    -h Help usage"
}




# --------------------------------------------------------------------------------------------------
#                      Process servers O/S selected by parameter received (aix/linux)
# --------------------------------------------------------------------------------------------------
process_servers()
{
    WOSTYPE=$1                                                           # Should be aix or linux
    sadm_writelog " "
    sadm_writelog "$SADM_DASH" 
    sadm_writelog "Processing active $WOSTYPE server(s)"
    sadm_writelog " "

    # Select From Database Linux Active Servers and output result in $SADM_TMP_FILE
    SQL1="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active " 
    SQL2="from sadm.server "
    SQL3="where srv_ostype = '${WOSTYPE}' and srv_active = True "
    SQL4="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"
    if [ $DEBUG_LEVEL -gt 5 ] 
       then sadm_writelog "$SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c $SQL" 
    fi
    $SADM_PSQL -AF , -t -h $SADM_PGHOST $SADM_PGDB -U $SADM_RO_PGUSER -c "$SQL" >$SADM_TMP_FILE1


    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]                                         # File has a non zero len ?
       then while read wline                                            # Data in File then read it
              do                                                        # Line by Line
              xcount=`expr $xcount + 1`                                 # Incr Server Counter Var.
              server_name=`    echo $wline|awk -F, '{ print $1 }'`      # Extract Server Name
              server_os=`      echo $wline|awk -F, '{ print $2 }'`      # Extract O/S (linux/aix)
              server_domain=`  echo $wline|awk -F, '{ print $3 }'`      # Extract Domain of Server
              server_monitor=` echo $wline|awk -F, '{ print $4 }'`      # Monitor t=True f=False
              server_sporadic=`echo $wline|awk -F, '{ print $5 }'`      # Sporadic t=True f=False
              fqdn_server=`echo ${server_name}.${server_domain}`        # Create FQN Server Name
              sadm_writelog " " ; sadm_writelog " "                     # Blank Lines between server
              sadm_writelog "${SADM_TEN_DASH}"                          # Print 10 Dash line
              sadm_writelog "Processing ($xcount) ${fqdn_server}"       # Print Counter/Server Name

              # IF DEBUG_LEVEL > 0 - DISPLAY SERVER MONITORING AND SPORADIC OPTIONS ARE ON OR OFF
              if [ $DEBUG_LEVEL -gt 0 ]                            # If Debug Activated
                 then if [ "$server_monitor" == "t" ]                   # Monitor Flag is at True
                            then sadm_writelog "Monitoring is ON for $fqdn_server"
                            else sadm_writelog "Monitoring is OFF for $fqdn_server"
                      fi
                      if [ "$server_sporadic" == "t" ]                  # Monitor Flag is at True
                            then sadm_writelog "Sporadic server is ON for $fqdn_server"
                            else sadm_writelog "Sporadic server is OFF for $fqdn_server"
                      fi
              fi


              # TEST IF THE SERVER NAME CAN BE RESOLVED - IF NOT NO USE TRYING TO PING SERVER
              # SIGNAL ERROR AND CONTINUE WITH NEXT SERVER
              #-------------------------------------------------------------------------------------
              if ! host  $fqdn_server >/dev/null 2>&1 
                 then SMSG="Can't process server '$fqdn_server' because name can't be resolved"
                      sadm_writelog "ERROR : $SMSG"                     # Advise user
                      ERROR_COUNT=$(($ERROR_COUNT+1))                   # Consider Error -Incr Cntr
                      sadm_writelog " "                                 # Separation Blank Line
                      sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT" 
                      sadm_writelog "Sending email to $SADM_MAIL_ADDR"
                      SMSG="$SMSG in $SADM_PN"
                      alert_user "M" "E" "$_server" ""  "$SMSG"         # Email User
                      sadm_writelog "Continuing with the next server"  
                      continue                                          # No need 2 rsync/Nxt Server
              fi

              # PING THE SERVER - SERVER OR LAPTOP MAY BE UNPLUGGED
              #-------------------------------------------------------------------------------------
              # SPORADIC SERVER ARE SERVER THAT CAN'T ALWAYS BE ONLINE (LAPTOP OR TEST SERVER)
              # IF PING DON'T WORK ON A SPORADIC SERVER, ADVISE USER AND SKIP RSYNC & CONTINUE 
              #-------------------------------------------------------------------------------------
              # IF MONITORING IS TRUE  AND SERVER DOESN'T RESPOND TO PING, THEN ALERT USER
              # IF MONITORING IS FALSE AND SERVER DOESN'T RESPOND TO PING, CONTINUE TO NEXT SERVER
              #-------------------------------------------------------------------------------------
              sadm_writelog "Let's try to ping the server $fqdn_server"
              ping -w1 $fqdn_server >/dev/null 2>&1                     # Ping Server one time
              #ping -w 3 $fqdn_server >>$SADM_LOG 2>&1                    # Ping Server one time
              if [ $? -ne 0 ]                                           # If server doesn't respond
                 then if [ "$server_sporadic" == "t" ]                  # If it's a sporadic server
                         then sadm_writelog "WARNING : Can't ping sporadic server $fqdn_server"
                              sadm_writelog "Will consider that it's OK (System down or unplugged)"
                              sadm_writelog "Continuing with the next server"  
                              continue                                  # Continue with Next Server
                         else SMSG="Server '$fqdn_server' doesn't respond to ping request"
                              sadm_writelog "ERROR : $SMSG"             # Advise use ping don't work
                              if [ "$server_monitor" = "t" ]            # Is Monitoring to True 
                                  then sadm_writelog "Sending email to $SADM_MAIL_ADDR"
                                       SMSG="$SMSG in $SADM_PN"
                                       alert_user "M" "E" "$_server" ""  "$SMSG"  # Email User
                              fi
                              ERROR_COUNT=$(($ERROR_COUNT+1))           # Consider Error -Incr Cntr
                              sadm_writelog " "                         # Separation Blank Line
                              sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT" 
                              sadm_writelog "Continuing with the next server"  
                              continue                                  # No need 2 rsync/Nxt Server
                      fi
                 else sadm_writelog "Ping went OK ..."                  # Server responded to ping
              fi
                

              # NOW THAT WE KNOW WE CAN PING THE SERVER, LET'S TRY SSH TO SERVER
              # IF MONITOR IS ON  AND SSH DOESN'T WORK, INCREASE ERROR COUNTER & ALERT USER (EMAIL)
              # IF MONITOR IS OFF AND SSH DOESN'T WORK, ADVISE USER AND CONTINUE WITH NEXT SERVER
              #-------------------------------------------------------------------------------------
              sadm_writelog "Testing SSH to server $fqdn_server"
              if [ $DEBUG_LEVEL -gt 4 ]                                 # If Debug Activated
                    then sadm_writelog "$SADM_SSH_CMD $fqdn_server date" # Show SSH Command use  
              fi
              $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1          # SSH to Server for date
              if [ $? -ne 0 ]                                           # If SSH did not work
                 then SMSG="Can't SSH to server '${fqdn_server}'"       # Construct Error Msg
                      sadm_writelog "ERROR : $SMSG"                     # Display Error Msg
                      if [ $server_monitor = 't' ]                      # If monitoring is ON
                         then sadm_writelog "Sending email to $SADM_MAIL_ADDR" # Send email Msg
                              SMSG="$SMSG in $SADM_PN"
                              alert_user "M" "E" "$fqdn_server" "" "$SMSG"        
                              ERROR_COUNT=$(($ERROR_COUNT+1))           # Consider Error -Incr Cntr
                              sadm_writelog " "                         # Separation Blank Line
                              sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT" 
                      fi 
                      continue                                          # Continue with next server
                 else sadm_writelog "SSH went OK ..."                   # Good SSH Work
              fi
                                   



              # MAKE SURE THE RCH RECEIVING DIRECTORY ON THIS SERVER EXIST BEFORE WE POPULATE IT
              #-------------------------------------------------------------------------------------
              sadm_writelog " "                                         # Separation Blank Line
              WDIR="${SADM_WWW_DAT_DIR}/${server_name}/rch"             # Local Receiving Dir.
              if [ ! -d "${WDIR}" ] ; then mkdir -p ${WDIR} ; chmod 2775 ${WDIR} ; fi # Create Dir.

              # GET THE RCH (RETURN CODE HISTORY) FILES FROM REMOTE SERVER
              # RSYNC REMOTE $SADMIN/DAT/RCH/*.RCH TO LOCAL $SADMIN/WWW/DAT/$SERVER/RCH  
              #-------------------------------------------------------------------------------------
              sadm_writelog "rsync -var --delete ${fqdn_server}:${SADM_RCH_DIR}/ ${WDIR}/ "
              rsync -var --delete ${fqdn_server}:${SADM_RCH_DIR}/ ${WDIR}/ >/dev/null 2>&1
              RC=$?                                                     # Save error number
              if [ $RC -eq 24 ] ; then RC=0 ; fi                        # Source File Gone is OK 
              if [ $RC -ne 0 ]                                          # If Error doing rch rsync
                 then sadm_writelog "RSYNC ERROR $RC for $fqdn_server"  # Inform User
                      ERROR_COUNT=$(($ERROR_COUNT+1))                   # Increase Error Counter
                 else sadm_writelog "The [R]eturn [C]ode [H]istory Files are now in sync - OK ..."
              fi




              # MAKE SURE THE RECEIVING LOG DIRECTORY EXIST ON THIS SERVER  BEFORE WE POPULATE IT
              #-------------------------------------------------------------------------------------
              sadm_writelog " "                                         # Separation Blank Line
              WDIR="${SADM_WWW_DAT_DIR}/${server_name}/log"             # Local Receiving Dir.
              if [ ! -d "${WDIR}" ] ; then mkdir -p ${WDIR} ; chmod 2775 ${WDIR} ; fi # Create Dir.

              # GET THE SERVER LOG FILE 
              # TRANSFER REMOTE LOG FILE(S) $SADMIN/LOG/*.LOG TO LOCAL $SADMIN/WWW/DAT/$SERVER/LOG
              #-------------------------------------------------------------------------------------
              sadm_writelog "rsync -var --delete ${fqdn_server}:${SADM_LOG_DIR}/ ${WDIR}/ "
              rsync -var --delete ${fqdn_server}:${SADM_LOG_DIR}/ ${WDIR}/ >/dev/null 2>&1
              RC=$?                                                     # Save error number
              if [ $RC -eq 24 ] ; then RC=0 ; fi                        # Source File Gone is OK 
              if [ $RC -ne 0 ]                                          # If Error doing rch rsync
                 then sadm_writelog "RSYNC ERROR $RC for $fqdn_server"  # Inform User
                      ERROR_COUNT=$(($ERROR_COUNT+1))                   # Increase Error Counter
                 else sadm_writelog "The Log files are now in sync - OK ..."
              fi




              # MAKE SURE THE RECEIVING RPT DIRECTORY EXIST ON THIS SERVER BEFORE WE POPULATE IT
              #-------------------------------------------------------------------------------------
              sadm_writelog " "                                         # Separation Blank Line
              WDIR="$SADM_WWW_DAT_DIR/${server_name}/rpt"               # Local www Receiving Dir.
              if [ ! -d "${WDIR}" ] ; then mkdir -p ${WDIR} ; chmod 2775 ${WDIR} ; fi # Create Dir.

              # GET THE SERVER SYSMON REPORT FILE 
              # TRANSFER REMOTE REPORT FILE(S) $SADMIN/RPT/*.RPT TO LOCAL $SADMIN/WWW/DAT/$SERVER/RPT
              #-------------------------------------------------------------------------------------
              sadm_writelog "rsync -var --delete ${fqdn_server}:${SADM_RPT_DIR}/ ${WDIR}/ "
              rsync -var --delete ${fqdn_server}:${SADM_RPT_DIR}/ ${WDIR}/ >/dev/null 2>&1
              RC=$?                                                     # Save error number
              if [ $RC -eq 24 ] ; then RC=0 ; fi                        # Source File Gone is OK 
              if [ $RC -ne 0 ]                                          # If Error doing rch rsync
                 then sadm_writelog "RSYNC ERROR $RC for $fqdn_server"  # Inform User
                      ERROR_COUNT=$(($ERROR_COUNT+1))                   # Increase Error Counter
                 else sadm_writelog "The Log files are now in sync - OK ..."
              fi



              sadm_writelog " "                                         # Separation Blank Line
              sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT" 
              done < $SADM_TMP_FILE1                            
    fi
    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    return $ERROR_COUNT                                                 # Return Total Error Count
}






# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir. & RC/Log 
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi
    
    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9])
    while getopts "hd:" opt ; do                                        # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) help_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;
           \?) sadm_writelog "Invalid option: -$OPTARG"                 # Invalid Option Message
               help_usage                                               # Display Help Usage
               sadm_stop 1                                              # Close the shop
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ]                                           # If Debug is Activated
        then sadm_writelog "Debug activated, Level ${DEBUG_LEVEL}"      # Display Debug Level
    fi


    # Process All Active Linux/Aix servers
    LINUX_ERROR=0; AIX_ERROR=0                                          # Init. Error count to 0
    process_servers "linux"                                             # Process Active Linux 
    LINUX_ERROR=$?                                                      # Save Nb. Errors in process
    sadm_writelog "Total Linux error(s) : ${LINUX_ERROR}"               # Display Total Linux Errors
    process_servers "aix"                                               # Process Active Aix
    AIX_ERROR=$?                                                        # Save Nb. Errors in process
    sadm_writelog "Total Aix error(s) : ${AIX_ERROR}"                   # Display Total Aix Errors
    
    # Being root can update o/s update crontab - Can't while in web interface
    cp ${SADM_CRON_FILE} ${SADM_CRONTAB}                                # Put in place Final Crontab
    chmod 600 ${SADM_CRONTAB} ; chown root.root ${SADM_CRONTAB}         # Set Permission on crontab

    # Print Total Script Errors
    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                         # Exit Code=AIX+Linux Errors
    sadm_writelog "Script Total Error(s) : ${SADM_EXIT_CODE}"           # Display Total Script Error

    # Gracefully Exit the script    
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Error code (0/1)
