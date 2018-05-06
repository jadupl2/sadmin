#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_fetch_servers.sh
#   Synopsis :  Rsync all rch/log/rpt files from servers farm to SADMIN Server
#   Version  :  1.0
#   Date     :  December 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_fetch_servers.sh 1.0 2015.09.06
# --------------------------------------------------------------------------------------------------
#  History
#   V1.6  Dec 2016    Major changes to include ssh test to each server and alert when not working
#                       Logic was redone , almost rewritten
#                       now include -d[1-9] switch to be more verbose during execution
#   V1.8  Feb 2017    Change Script name and change SADM server default crontab
#   V1.9  April 2017  Cosmetic - Remove blank lines inside processing servers
#   V2.0  July 2017   Remove Ping before doing the SSH to each server (Not really needed)
#   V2.1  July 2017   When Error Detected - The Error is included at the top of Email (Simplify Diag)
#   2017_08_03 JDuplessis - V2.2 Minor Bug Fix
#   2017_08_24 JDuplessis - V2.3 Rewrote section of code & Message more concise
#   2017_08_29 JDuplessis - V2.4 Bug Fix - Corrected problem when retrying rsync when failed
#   2017_08_30 JDuplessis - V2.5 If SSH test to server fail, try a second time (Prevent false Error)
#   2017_12_17 JDuplessis - V2.6 Modify to use MySQL instead of PostGres
#   2018_02_08 JDuplessis 
#       V2.8 Fix compatibility problem with 'dash' shell
#   2018_02_10 JDuplessis 
#       V2.9 Rsync on SADMIN server (locally) is not using ssh
#   2018_04_05 JDuplessis 
#       V2.10 Do not copy web Interface crontab from backup unless file exist
#   2018_05_06 JDuplessis 
#       V2.11 Remove URL from Email when Error are detecting while fetching data
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
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='2.11'                            ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================



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



#===================================================================================================
#                Function use to rsync remote SADM client with local directories
#===================================================================================================
rsync_function()
{
    # Parameters received should always by two - If not write error to log and return to caller
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters"
             sadm_writelog "Function received $* and this isn't valid"
             return 1
    fi

    # Save rsync information
    REMOTE_DIR=$1                                                       # user@host:remote directory
    LOCAL_DIR=$2                                                        # Local Directory

    # If Local directory doesn't exist create it 
    if [ ! -d "${LOCAL_DIR}" ] ; then mkdir -p ${LOCAL_DIR} ; chmod 2775 ${LOCAL_DIR} ; fi

    # Rsync remote directory on local directory - On error try 3 times before signaling error
    RETRY=0                                                             # Set Retry counter to zero
    while [ $RETRY -lt 3 ]                                              # Retry rsync 3 times
        do
        let RETRY=RETRY+1                                               # Incr Retry counter
        rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR} >/dev/null 2>&1  # rsync selected directory
        RC=$?                                                           # save error number

        # Consider Error 24 as none critical (Partial transfer due to vanished source files)
        if [ $RC -eq 24 ] ; then RC=0 ; fi                              # Source File Gone is OK

        if [ $RC -ne 0 ]                                                # If Error doing rsync
           then if [ $RETRY -lt 3 ]                                     # If less than 3 retry
                   then sadm_writelog "[ RETRY $RETRY ] rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                   else sadm_writelog "[ ERROR $RETRY ] rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                        break
                fi
           else sadm_writelog "[ OK ] rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                break
        fi
    done
    #sadm_writelog "chmod 664 ${LOCAL_DIR}*" 
    chmod 664 ${LOCAL_DIR}*
    return $RC
}


# --------------------------------------------------------------------------------------------------
#                      Process servers O/S selected by parameter received (aix/linux)
# --------------------------------------------------------------------------------------------------
process_servers()
{
    WOSTYPE=$1                                                          # Should be aix or linux
    sadm_writelog " "
    sadm_writelog "Processing active $WOSTYPE server(s)"                # Display/Log O/S type
    sadm_writelog " "

    # Select From Database Active Servers with selected O/s & output result in $SADM_TMP_FILE1
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active"
    SQL="${SQL} from server"
    SQL="${SQL} where srv_ostype = '${WOSTYPE}' and srv_active = True "
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    # If File was not created or has a zero lenght then No Actives Servers were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_writelog "No Active Server were found."               # Not ACtive Server MSG
             return 0                                                   # Return Error to Caller
    fi 
    
    xcount=0; ERROR_COUNT=0;
    while read wline                                                    # Data in File then read it
        do                                                              # Line by Line
        xcount=`expr $xcount + 1`                                       # Incr Server Counter Var.
        server_name=`    echo $wline|awk -F, '{ print $1 }'`            # Extract Server Name
        server_os=`      echo $wline|awk -F, '{ print $2 }'`            # Extract O/S (linux/aix)
        server_domain=`  echo $wline|awk -F, '{ print $3 }'`            # Extract Domain of Server
        server_monitor=` echo $wline|awk -F, '{ print $4 }'`            # Monitor t=True f=False
        server_sporadic=`echo $wline|awk -F, '{ print $5 }'`            # Sporadic t=True f=False
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQN Server Name
        sadm_writelog "${SADM_TEN_DASH}"                                # Print 10 Dash line
        sadm_writelog "Processing ($xcount) ${fqdn_server}"             # Print Counter/Server Name

        # IN DEBUG MODE - SHOW IF SERVER MONITORING AND SPORADIC OPTIONS ARE ON/OFF
        if [ $DEBUG_LEVEL -gt 0 ]                                       # If Debug Activated
           then if [ "$server_monitor" = "1" ]                         # Monitor Flag is at True
                      then sadm_writelog "Monitoring is ON for $fqdn_server"
                      else sadm_writelog "Monitoring is OFF for $fqdn_server"
                fi
                if [ "$server_sporadic" = "1" ]                        # Sporadic Flag is at True
                      then sadm_writelog "Sporadic server is ON for $fqdn_server"
                      else sadm_writelog "Sporadic server is OFF for $fqdn_server"
                fi
        fi

        # IF SERVER NAME CAN'T BE RESOLVED - SIGNAL ERROR AND CONTINUE WITH NEXT SERVER
        if ! host  $fqdn_server >/dev/null 2>&1
           then SMSG="[ ERROR ] Can't process '$fqdn_server', hostname can't be resolved"
                sadm_writelog "$SMSG"                                   # Advise user
                echo "$SMSG" >> $SADM_ELOG                              # Log Err. to Email Log
                ERROR_COUNT=$(($ERROR_COUNT+1))                         # Consider Error -Incr Cntr
                if [ $ERROR_COUNT -ne 0 ]
                   then sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT"
                fi
                continue                                                # skip this server
        fi

        # TEST SSH TO SERVER
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH
            then $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1       # SSH to Server for date
                 RC=$?                                                  # Save Error Number
                 if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]      # SSH don't work & Sporadic
                    then sadm_writelog "[ WARNING ] Can't SSH to sporadic server $fqdn_server"
                         continue                                       # Go process next server
                 fi
                 if [ $RC -ne 0 ] &&  [ "$server_monitor" = "0" ]       # SSH don't work/Monitor OFF
                    then sadm_writelog "[ WARNING ] Can't SSH to $fqdn_server - Monitoring SSH is OFF"
                         continue                                       # Go process next server
                 fi
                RETRY=0                                                 # Set Retry counter to zero
                while [ $RETRY -lt 3 ]                                  # Retry rsync 3 times
                    do
                    let RETRY=RETRY+1                                   # Incr Retry counter
                    $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1    # SSH to Server for date
                    RC=$?                                               # Save Error Number
                    if [ $RC -ne 0 ]                                    # If Error doing ssh
                        then if [ $RETRY -lt 3 ]                        # If less than 3 retry
                                then sadm_writelog "[ RETRY $RETRY ] $SADM_SSH_CMD $fqdn_server date"
                                else sadm_writelog "[ ERROR $RETRY ] $SADM_SSH_CMD $fqdn_server date"
                                     ERROR_COUNT=$(($ERROR_COUNT+1))    # Consider Error -Incr Cntr
                                     sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT"
                                     SMSG="[ ERROR ] Can't SSH to server '${fqdn_server}'"  
                                     sadm_writelog "$SMSG"              # Display Error Msg
                                     echo "$SMSG" >> $SADM_ELOG         # Log Err. to Email Log
                                     echo "COMMAND : $SADM_SSH_CMD $fqdn_server date" >> $SADM_ELOG
                                     echo "----------" >> $SADM_ELOG 
                                     continue
                             fi
                        else sadm_writelog "[ OK ] $SADM_SSH_CMD $fqdn_server date"
                             break
                    fi
                    done
        fi

        # MAKE SURE RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/rch"                   # Local Receiving Dir.
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${SADM_RCH_DIR}/" "${WDIR}/"
            else rsync_function "${SADM_RCH_DIR}/" "${WDIR}/"           # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi

        # MAKE SURE RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/log"                   # Local Receiving Dir.
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${SADM_LOG_DIR}/" "${WDIR}/"
            else rsync_function "${SADM_LOG_DIR}/" "${WDIR}/"
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi

        # MAKE SURE RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        WDIR="$SADM_WWW_DAT_DIR/${server_name}/rpt"                     # Local www Receiving Dir.
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${SADM_RPT_DIR}/" "${WDIR}/"
            else rsync_function "${SADM_RPT_DIR}/" "${WDIR}/"
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi

        # IF ERROR OCCURED DISPLAY NUMBER OF ERROR
        if [ $ERROR_COUNT -ne 0 ]
           then sadm_writelog " "                                       # Separation Blank Line
                sadm_writelog "** Total ${WOSTYPE} error(s) is now $ERROR_COUNT"
        fi
              
        done < $SADM_TMP_FILE1

    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    return $ERROR_COUNT                                                 # Return Total Error Count
}






# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN Server
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

    # Create File that will include only Error message that will be sent to user if requested
    echo "----------" > $SADM_ELOG
    echo "Date/Time  : `date`"     >> $SADM_ELOG
    echo "Script Name: ${SADM_PN}" >> $SADM_ELOG
    echo "Hostname   : $HOSTNAME " >> $SADM_ELOG
    echo "----------" >> $SADM_ELOG

    # Process All Active Linux/Aix servers
    LINUX_ERROR=0; AIX_ERROR=0                                          # Init. Error count to 0
    process_servers "linux"                                             # Process Active Linux
    LINUX_ERROR=$?                                                      # Save Nb. Errors in process
    process_servers "aix"                                               # Process Active Aix
    AIX_ERROR=$?                                                        # Save Nb. Errors in process

    # Print Total Script Errors
    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                         # Exit Code=AIX+Linux Errors
    sadm_writelog "Total Linux error(s)  : ${LINUX_ERROR}"              # Display Total Linux Errors
    sadm_writelog "Total Aix error(s)    : ${AIX_ERROR}"                # Display Total Aix Errors
    sadm_writelog "Script Total Error(s) : ${SADM_EXIT_CODE}"           # Display Total Script Error
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    sadm_writelog " "                                                   # Separation Blank Line

    if [ "$SADM_EXIT_CODE" -ne 0 ]
        then sadm_writelog "Writing Error Encountered at the top of the log"
             echo "----------" >> $SADM_ELOG
             cat $SADM_ELOG $SADM_LOG > $SADM_TMP_FILE3 2>&1
             cp $SADM_TMP_FILE3 $SADM_LOG
             #cp $SADM_ELOG $SADM_LOG
             #alert_user "M" "E" "$_server" ""  "`cat $SADM_ELOG`"         # Email User

    fi

    # Being root can update o/s update crontab - Can't while in web interface
    if [ -f ${SADM_CRON_FILE} ]                                         # If Web Interface Crontab
        then cp ${SADM_CRON_FILE} ${SADM_CRONTAB}                       # Put in place Final Crontab
             chmod 600 $SADM_CRONTAB ; chown root.root ${SADM_CRONTAB}  # Set Permission on crontab
    fi

    # Gracefully Exit the script
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Error code (0/1)
