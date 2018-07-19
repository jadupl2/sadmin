#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rsync_sadmin.sh
#   Synopsis : .
#   Version  :  1.0
#   Date     :  6 September 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_rsync_sadmin.sh 1.0 2015.09.06
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
#
# Change Log
# 2017_02_04  V1.8 Don't rsync /sadmin/cfg entirely just template.smon file for now    
# 2017_06_03  V1.9 Added the /sadmin/sys to rsync processing
# 2017_09_23  V2.0 All rewritten for performance/flexibility improvement and command line Switch for debug
# 2017_12_30  V2.1 Change name of sysmon.std to template.smon (System Monitor Template)
# 2018_01_20  V2.2 Minor Adjustments
# 2018_02_10  V2.3 Change SQL Statement to remove SADMIN server from rsync process
# 2018_05_31  V2.4 Added ".backup_list.txt" & ".backup_exclude.txt" to rsync list 
# 2018_06_04  V2.5 Change $SADMIN/jac/bin to $SADM_UBIN_DIR 
# 2018_07_15  V2.6 Use Client Install Directory Location from Database instead of assuming /sadmin.
# 2018_07_19  V2.7 Now include Sysmon Template, nmon & service restart (srestart,sh) script
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
    export SADM_VER='2.7'                               # Current Script Version
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




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose


# --------------------------------------------------------------------------------------------------
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (0-9 Debug Level)"
    echo "             -h   (Display this help message)"
    echo " "
}



# --------------------------------------------------------------------------------------------------
#                      Create Remote Directory - If it does not exist
# --------------------------------------------------------------------------------------------------
create_remote_dir()
{
    # Parameters received should always by two - If not write error to log and return to caller
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters"
             sadm_writelog "Function received $* and that isn't valid"
             sadm_writelog "Should received 'ServerName' and 'Remote Directory'"
             return 1
    fi
    REM_SERVER=$1                                                       # Remote server Name FQDN
    REM_DIR=$2                                                          # Dir that should exist 

    # List Directory Received on the remote server
    if [ $DEBUG_LEVEL -gt 8 ]                                           # If Debug is Activated
        then sadm_writelog "ssh -n ${REM_SERVER} ls -l ${REM_DIR}"
    fi
    ssh -n ${REM_SERVER} ls -l ${REM_DIR} >/dev/null 2>&1
    RC=$? 
    
    # If SSH Connection is OK and Directory exist on server, then OK
    if [ $RC -eq 0 ]
        then sadm_writelog "[ OK ] Directory ${REM_DIR} exist on ${REM_SERVER}"
             return 0
    fi 

    # If SSH Connection is OK and BUT Directory doesn't exist on server, then create it
    if [ $RC -eq 2 ]
        then ssh ${REM_SERVER} "mkdir -p ${REM_DIR}" >/dev/null 2>&1
             if [ $RC -eq 0 ] || [ $RC -eq 2 ]
                then sadm_writelog "[ OK ] Directory ${REM_DIR} exist on ${REM_SERVER}"
                     RC=0
                     return 0
                else sadm_writelog "[ ERROR $RC ] Couldn't create directory ${REM_DIR} on ${REM_SERVER}"
                     return 1
             fi
    fi 
    
    sadm_writelog "[ ERROR ] Couldn't check existance of ${REM_DIR} on ${REM_SERVER}"
    return 1
}




# --------------------------------------------------------------------------------------------------
#                      Process servers O/S selected by parameter received (aix/linux)
# --------------------------------------------------------------------------------------------------
process_servers()
{
    WOSTYPE=$1                                                          # Should be aix or linux
    sadm_writelog " "
    sadm_writelog "${SADM_FIFTY_DASH}"
    sadm_writelog "Processing all active server(s)"
    sadm_writelog " "

    # Select From Database Active Servers & output result in $SADM_TMP_FILE
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_sadmin_dir"
    SQL="${SQL} from server"
    SQL="${SQL} where srv_active = True and srv_name <> '$SADM_HOSTNAME' "
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
   
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;                                            # Reset Server/Error Counter
    if [ -s "$SADM_TMP_FILE1" ]                                         # File has non zero length?
       then while read wline                                            # Then Read Line by Line
              do
              xcount=`expr $xcount + 1`                                 # Server Counter
              server_name=`    echo $wline|awk -F, '{ print $1 }'`      # Extract Server Name
              server_os=`      echo $wline|awk -F, '{ print $2 }'`      # Extract O/S (linux/aix)
              server_domain=`  echo $wline|awk -F, '{ print $3 }'`      # Extract Domain of Server
              server_monitor=` echo $wline|awk -F, '{ print $4 }'`      # Monitor  t=True f=False
              server_sporadic=`echo $wline|awk -F, '{ print $5 }'`      # Sporadic t=True f=False
              server_dir=`     echo $wline|awk -F, '{ print $6 }'`      # Client SADMIN Install Dir.
              server_fqdn=`echo ${server_name}.${server_domain}`        # Create FQN Server Name
              sadm_writelog " " ; sadm_writelog " "                     # Two Blank Lines
              sadm_writelog "${SADM_TEN_DASH}"
              sadm_writelog "Processing ($xcount) $server_fqdn"
              
              # In Debug Mode Display SSH Monitoring and Sporadic Setting
              if [ $DEBUG_LEVEL -gt 3 ]                                 # If Debug is Activated
                then if [ "$server_sporadic" == "1" ]
                            then sadm_writelog "Server defined as sporadically available"
                            else sadm_writelog "Server always available (Not Sporadic)"
                     fi
              fi

              # If server name can't be resolved - Signal Error and Continue with next server.
              if ! host $server_fqdn >/dev/null 2>&1
                 then SMSG="[ ERROR ] Can't process '$server_fqdn', hostname can't be resolved"
                      sadm_writelog "$SMSG"                             # Advise user
                      echo "$SMSG" >> $SADM_ELOG                        # Log Err. to Email Log
                      ERROR_COUNT=$(($ERROR_COUNT+1))                   # Consider Error -Incr Cntr
                      if [ $ERROR_COUNT -ne 0 ]
                         then sadm_writelog "Total Error(s) now at $ERROR_COUNT"
                      fi
                      continue                                          # skip this server
              fi

              # Test SSH to Server
              $SADM_SSH_CMD $server_fqdn date > /dev/null 2>&1          # SSH to Server for date
              RC=$?                                                     # Save Error Number

              # If SSH to server failed & it's a sporadic server = warning & next server
              if [ $RC -ne 0 ] &&  [ "$server_sporadic" == "1" ]        # SSH don't work & Sporadic
                 then sadm_writelog "[ WARNING ] Can't SSH to sporadic server $server_fqdn"
                      continue                                          # Go process next server
              fi

              # If first SSH failed, try again 3 times to prevent false Error
              if [ $RC -ne 0 ]   
                then RETRY=0                                            # Set Retry counter to zero
                     while [ $RETRY -lt 3 ]                             # Retry rsync 3 times
                        do
                        let RETRY=RETRY+1                               # Incr Retry counter
                        $SADM_SSH_CMD $server_fqdn date >/dev/null 2>&1 # SSH to Server for date
                        RC=$?                                           # Save Error Number
                        if [ $RC -ne 0 ]                                # If Error doing ssh
                            then if [ $RETRY -lt 3 ]                    # If less than 3 retry
                                    then MSG="[ RETRY $RETRY ] $SADM_SSH_CMD $server_fqdn date"
                                         sadm_writelog "$MSG"
                                    else break
                                 fi
                            else sadm_writelog "[ OK ] $SADM_SSH_CMD $server_fqdn date"
                                 break
                        fi
                        done
              fi

              # IF ALL SSH TEST FAILED, ISSUE ERROR MESSAGE AND CONTINUE WITH NEXT SERVER
              if [ $RC -ne 0 ]   
                 then SMSG="[ ERROR ] Can't SSH to server '${server_fqdn}'"  
                      sadm_writelog "$SMSG"                             # Display Error Msg
                      echo "$SMSG" >> $SADM_ELOG                        # Log Err. to Email Log
                      echo "COMMAND : $SADM_SSH_CMD $server_fqdn date" >> $SADM_ELOG
                      echo "----------" >> $SADM_ELOG
                      ERROR_COUNT=$(($ERROR_COUNT+1))                   # Consider Error -Incr Cntr
                      continue                                          # Continue with next server
              fi
              sadm_writelog "[ OK ] SSH to $server_fqdn"                # Good SSH Work


              # ARRAY OF DIRECTORY THAT WILL BE CREATED IF THEY DON'T EXIST ON THE SADM CLIENT
              rem_dir_to_create=( ${server_dir}/bin ${server_dir}/sys ${server_dir}/usr/bin 
                                  ${server_dir}/pkg ${server_dir}/lib ${server_dir}/cfg 
                                  ${server_dir}/dat ${server_dir}/log ${server_dir}/tmp 
                                  ${server_dir}/usr/mon )

              # CREATE REMOTE DIRECTORY ON CLIENT IF THE DON'T EXIST
              for WDIR in "${rem_dir_to_create[@]}"
                do
    	        create_remote_dir "${server_fqdn}" "${WDIR}"            # If ! Exist create Rem Dir.
                if [ $? -ne 0 ]                                         # If were not able
                   then sadm_writelog "[ ERROR ] Creating Dir. ${WDIR} on ${server_fqdn}"
                fi
                done             
 

              # ARRAY OF IMPORTANT DIRECTORIES TO RSYNC TO SADM CLIENT
              rem_dir_to_rsync=( bin sys usr/bin pkg lib )

              # RSYNC ARRAY OF IMPORTANT DIRECTORIES TO SADM CLIENT
              for WDIR in "${rem_dir_to_rsync[@]}"
                do
                if [ $DEBUG_LEVEL -gt 5 ]                               # If Debug is Activated
                    then sadm_writelog "rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/"
                fi
                rsync -ar --delete  ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/
                RC=$? 
                if [ $RC -ne 0 ]
                   then sadm_writelog "[ ERROR ] rsync error($RC) for ${server_fqdn}:${server_dir}/${WDIR}/"
                        ERROR_COUNT=$(($ERROR_COUNT+1))                 # Increase Error Counter
                   else sadm_writelog "[ OK ] rsync for ${server_fqdn}:${server_dir}/${WDIR}" 
                fi
                done             

              # Rsync Template files Array to SADM client
              rem_files_to_rsync=( cfg/.template.smon cfg/.release cfg/.sadmin.cfg cfg/.sadmin.rc 
                                   cfg/.sadmin.service 
                                   cfg/.backup_exclude.txt  cfg/.backup_list.txt 
                                   usr/mon/sadm_nmon_watcher.sh usr/mon/sysmon_template.sh 
                                   usr/mon/srestart.sh ) 

              # Rsync local files on client
              for WFILE in "${rem_files_to_rsync[@]}"
                do
                if [ $DEBUG_LEVEL -gt 5 ]                               # If Debug is Activated
                    then sadm_writelog "rsync -ar  --delete ${SADM_BASE_DIR}/${WFILE} ${server_fqdn}:${server_dir}/${WFILE}"
                fi
                rsync -ar  --delete ${SADM_BASE_DIR}/${WFILE} ${server_fqdn}:${server_dir}/${WFILE}
                RC=$?
                if [ $RC -ne 0 ]
                    then sadm_writelog "[ ERROR ] rsync error($RC) for ${server_fqdn}:${server_dir}/${WFILE}"
                         ERROR_COUNT=$(($ERROR_COUNT+1))
                    else sadm_writelog "[ OK ] rsync for ${server_fqdn}:${server_dir}/${WFILE}" 
                fi
                done             

              if [ "$ERROR_COUNT" -ne 0 ] 
                 then sadm_writelog "Total Error Count after ${server_fqdn} is ${ERROR_COUNT}."
              fi
              done < $SADM_TMP_FILE1
    fi
    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN Server
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
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

    process_servers                                                     # Process Active Servers
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
