#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_fetch_servers.sh
#   Synopsis :  Rsync all *.rch/*.log/*.rpt files from all active SADMIN client to the SADMIN Server
#   Version  :  1.0
#   Date     :  December 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_fetch_servers.sh 1.0 2015.09.06
# --------------------------------------------------------------------------------------------------
#  Change Log
#   2016_12_12  v1.6 Major changes to include ssh test to each server and alert when not working
#   2017_02_09  v1.8 Change Script name and change SADM server default crontab
#   2017_04_04  v1.9 Cosmetic - Remove blank lines inside processing servers
#   2017_07_07  v2.0 Remove Ping before doing the SSH to each server (Not really needed)
#   2017_07_20  v2.1 When Error Detected - The Error is included at the top of Email (Simplify Diag)
#   2017_08_03  v2.2 Minor Bug Fix
#   2017_08_24  v2.3 Rewrote section of code & Message more concise
#   2017_08_29  v2.4 Bug Fix - Corrected problem when retrying rsync when failed
#   2017_08_30  v2.5 If SSH test to server fail, try a second time (Prevent false Error)
#   2017_12_17  v2.6 Modify to use MySQL instead of PostGres
#   2018_02_08  v2.8 Fix compatibility problem with 'dash' shell
#   2018_02_10  v2.9 Rsync on SADMIN server (locally) is not using ssh
#   2018_04_05  v2.10 Do not copy web Interface crontab from backup unless file exist
#   2018_05_06  v2.11 Remove URL from Email when Error are detecting while fetching data
#   2018_05_06  v2.12 Small Modification for New Libr Version
#   2018_06_29  v2.13 Use Root SADMIN Client Dir in Database instead of assuming /sadmin as root dir
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
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.13'                              # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose




# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
    printf "\n\n" 
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
        xcount=`expr $RETRY + 1`                                        # Incr Retry counter.
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
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir "
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
        then sadm_writelog "No Active $WOSTYPE server were found."      # Not ACtive Server MSG
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
        server_dir=`     echo $wline|awk -F, '{ print $7 }'`            # SADMIN Dir on Client 
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
                sadm_writelog "SADMIN root directory on $fqdn_server is $server_dir"
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

        # MAKE SURE RCH RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/rch"                   # Local Receiving Dir.
        RDIR="${server_dir}/dat/rch"                                    # Remote RCH Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr

        # MAKE SURE LOG RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/log"                   # Local Receiving Dir.
        RDIR="${server_dir}/log"                                        # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr

        # MAKE SURE RPT RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        LDIR="$SADM_WWW_DAT_DIR/${server_name}/rpt"                     # Local www Receiving Dir.
        RDIR="${server_dir}/dat/rpt"                                    # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr

        # IF ERROR OCCURED DISPLAY NUMBER OF ERROR
        if [ $ERROR_COUNT -ne 0 ]                                       # If at Least 1 Error
           then sadm_writelog " "                                       # Separation Blank Line
                sadm_writelog "** Total ${WOSTYPE} error(s) is now $ERROR_COUNT" # Show Err. Count
        fi
              
        done < $SADM_TMP_FILE1

    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    return $ERROR_COUNT                                                 # Return Total Error Count
}






# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------
    # If you want this script to be run only by 'root'.
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo %s" "${0##*/}"                          # Suggest using sudo
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S with error
    fi

    sadm_start                                                          # Start Using SADM Tools
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init

    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN Server
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9])
    while getopts "vhd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
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
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory
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
             chmod 600 $SADM_CRONTAB ; chown root:root ${SADM_CRONTAB}  # Set Permission on crontab
    fi

    # Gracefully Exit the script
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Error code (0/1)
