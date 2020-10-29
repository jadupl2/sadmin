#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      : Jacques Duplessis
#   Title       : sadm_rear_initiator.sh
#   Synopsis    : Get total of servers to backup with Rear & run them at regular interval within MAX_HOURS given
#   Description : Run Backup Read All Active servers, check if today is the day you selected to run rear.
#                 If it's today, then the rear backup is initiated. Backup will not be run all at once.
#                 Will first check how many backup need to run today and how many hours we 
#                 got (MAX_HOURS) to run them.
#                 Will run 'at' command so that each rear backup run within the MAX_HOURS Limit.
#   Version     :  1.6
#   Date        :  14 November 2015
#   Requires    :  sh & sadmlib.sh
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# Enhancements/Corrections Version Log
# 2018_02_08    v1.8 Fix Compatibility problem with 'sadh' shell (If statement)
# 2018_06_06    v1.9 Adapt to New SADMIN Shell Library
#@2020_10_29 Fix: v1.10 If comma was used in server description, it cause delimiter problem.
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
    export SADM_VER='1.10'                               # Current Script Version
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
    #export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
DOW=`date '+%u'`                            ; export DOW                # Day of Week 1=Mon 7=Sunday
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
MAX_HOURS=6                                 ; export MAX_HOURS          # Nb. Hrs to do Today Backup
ONE_SERVER=" "                              ; export ONE_SERVER         # Server 2 Backup if not all
DB_DOW=0                                    ; export DB_DOW             # Database Day of Week No.

# Name & Location of Client backup script
BACKUP_SCRIPT="$SADM_BIN_DIR/sadm_rear_backup.sh"   ; export BACKUP_SCRIPT 


#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N 
#===================================================================================================
help_usage()
{
    echo " "
    echo "sadm_rear_initiator.sh usage :"
    echo " "
    echo "sadm_rear_initiator.sh -d[0-9] -t[1-9] -s[server_name] -h[elp] :"
    echo " "
    echo "     Set Debug Level (Default is 0)                       :  -d [0-9] "
    echo "     Perform ReaR Backup of server specified              :  -s [ServerName]"
    echo "       (If not specified, All Active servers scheduled " 
    echo "        for today will be backup when this script is run) "
    echo "     Nb. of Hour allowed to run today Backup (Default 6)  :  -t [1-9] "
    echo "        (Use when option -s not used)"
    echo "     To display this help message                         :  -h help"
    echo " "
}


# --------------------------------------------------------------------------------------------------
#               Go launch backup on Linux server, if it is schedule to run on this day
# --------------------------------------------------------------------------------------------------
perform_backup()
{
    
   if [ "$ONE_SERVER" = " " ]                                           # More than 1 Server to do
      then  DOW=`date '+%u'`                                            # Day of Week (0=Sun,6=Sat)
            # Match Current Day Number with Number in Database (0=Nobackup 1=Monday and 7 Sunday)
            if [ $DOW -eq 0 ] ; then DOWSTR="We will do backup scheduled for Sunday"    ;DB_DOW=7;fi
            if [ $DOW -eq 1 ] ; then DOWSTR="We will do backup scheduled for Monday"    ;DB_DOW=1;fi
            if [ $DOW -eq 2 ] ; then DOWSTR="We will do backup scheduled for Tuesday"   ;DB_DOW=2;fi
            if [ $DOW -eq 3 ] ; then DOWSTR="We will do backup scheduled for Wednesday" ;DB_DOW=3;fi
            if [ $DOW -eq 4 ] ; then DOWSTR="We will do backup scheduled for Thursday"  ;DB_DOW=4;fi
            if [ $DOW -eq 5 ] ; then DOWSTR="We will do backup scheduled for Friday"    ;DB_DOW=5;fi
            if [ $DOW -eq 6 ] ; then DOWSTR="We will do backup scheduled for Saturday"  ;DB_DOW=6;fi
            sadm_writelog "$DOWSTR"                                     # Display Today Backup Name
    fi


    # Perform SQL to Select Server to Backup Today
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active "
    SQL="${SQL} from sadm.server "
    if [ "$ONE_SERVER" = " " ]
       then SQL="${SQL}where srv_ostype = 'linux' and srv_active = True and "
            SQL="${SQL}srv_backup = ${DB_DOW}"
       else SQL="${SQL}where srv_ostype = 'linux' and srv_active = True and " 
            SQL="${SQL}srv_name = '${ONE_SERVER}'"
    fi
    SQL="${SQL} order by srv_name; "
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/;/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1

    # Display Execution repartition in time if more than one server
    if [ "$ONE_SERVER" = " " ]
        then # Display Number of server(s) to Backup with Rear
             NB_SERVER=`wc -l $SADM_TMP_FILE1 | awk '{ print $1 }' | tr -d ' ' `
             sadm_writelog "We have $NB_SERVER server(s) to backup in $MAX_HOURS hours."
             #
             WSECONDS=`echo "$MAX_HOURS * 3600" | bc`
             sadm_writelog "This means we want to backup $NB_SERVER server within $WSECONDS seconds"
             W_INT_SEC=`echo "$WSECONDS / $NB_SERVER" | bc`
             W_INT_MIN=`echo "$W_INT_SEC / 60"| bc `
             sadm_writelog "So we laucnh a backup every $W_INT_MIN minutes"
             WCUR_DATE=$(date "+%C%y.%m.%d %H:%M:%S")
             WCUR_EPOCH=$(sadm_date_to_epoch "$WCUR_DATE")
             sadm_writelog "The current epoch time for $WCUR_DATE is $WCUR_EPOCH"
             sadm_writelog "Processing each server(s) that are scheduled to be backup today"
    fi

    # Read the SQL Result file and process server(s)
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              server_name=`    echo $wline|awk -F\; '{ print $1 }'`      # Extract Server Name
              server_os=`      echo $wline|awk -F\; '{ print $2 }'`      # Extract O/S (linux/aix)
              server_domain=`  echo $wline|awk -F\; '{ print $3 }'`      # Extract Domain of Server
              server_monitor=` echo $wline|awk -F\; '{ print $4 }'`      # Monitor t=True f=False
              server_sporadic=`echo $wline|awk -F\; '{ print $5 }'`      # Sporadic t=True f=False
              fqdn_server=`echo ${server_name}.${server_domain}`        # Create FQN Server Name
                      
              # Display Server Monitoring and Sporadic Options are ON or OFF in Debug Mode
              if [ $DEBUG_LEVEL -gt 0 ]                                 # If Debug Activated
                 then if [ "$server_monitor" = "t" ]                    # Monitor Flag is at True
                            then sadm_writelog "Monitoring is ON for $fqdn_server"
                            else sadm_writelog "Monitoring is OFF for $fqdn_server"
                      fi
                      if [ "$server_sporadic"  = "t" ]                  # Sporadic Flag is at True
                            then sadm_writelog "Sporadic server is ON for $fqdn_server"
                            else sadm_writelog "Sporadic server is OFF for $fqdn_server"
                      fi
              fi              
              
              # Let's try SSH to Server
              sadm_writelog " " 
              sadm_writelog "Testing SSH to server $fqdn_server"
              if [ $DEBUG_LEVEL -gt 4 ]                                 # If Debug Activated
                    then sadm_writelog "$SADM_SSH_CMD $fqdn_server date" # Show SSH Command use  
              fi
              $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1          # SSH to Server for date
              if [ $? -ne 0 ]                                           # If SSH did not work
                 then SMSG="ERROR : Can't SSH to server ${fqdn_server}" # Construct Error Msg
                      sadm_writelog "$SMSG"                             # Display Error Msg
                      ERROR_COUNT=$(($ERROR_COUNT+1))                   # Consider Error -Incr Cntr
                      continue                                          # Continue with next server
                 else sadm_writelog "SSH went OK ..."                   # Good SSH Work
              fi
              xcount=`expr $xcount + 1`
                  
              # Perform the One server backup
              if [ "$ONE_SERVER" != " " ]
                 then CMD="echo \"$SADM_SSH_CMD $fqdn_server $BACKUP_SCRIPT\" "
                      sadm_writelog "Starting backup on server $fqdn_server :"
                      sadm_writelog "$CMD" ; sadm_writelog " "
                      $SADM_SSH_CMD $fqdn_server $BACKUP_SCRIPT 
                      RC=$?
                      sadm_writelog "Error code returned by the backup script $BACKUP_SCRIPT is $RC"
                      if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi
                      continue
              fi

              # Perform the server backup when running multiple server option
              # Display the Date & Time the backup will start for this server
              if [ $xcount -eq 1 ]
                    then W_START_EPOCH=`echo "$WCUR_EPOCH + 120" | bc`  # Current time + 2 Min.
                    else W_START_EPOCH=`echo "$WCUR_EPOCH + ( ($xcount-1) * $W_INT_SEC) " | bc`
              fi 
              W_START_DATE=$(sadm_epoch_to_date "$W_START_EPOCH")  
              sadm_writelog "($xcount) ${fqdn_server} - Backup start around ${W_START_DATE}"

              # Display and run the 'at' Command to launch th eReaR Backup Script
              if [ $xcount -eq 1 ]
                    then CMD="echo \"$SADM_SSH_CMD $fqdn_server $BACKUP_SCRIPT\" | at now +2 min"
                         sadm_writelog "Running command : $CMD"
                         echo "$SADM_SSH_CMD $fqdn_server $BACKUP_SCRIPT" | at now +2 min
                    else WMIN=`echo "$W_INT_MIN * ($xcount - 1)" | bc`
                         CMD="echo \"$SADM_SSH_CMD $fqdn_server $BACKUP_SCRIPT\" | at now +${WMIN} min"
                         sadm_writelog "Running command : $CMD"
                         echo "$SADM_SSH_CMD $fqdn_server $BACKUP_SCRIPT" | at now +${WMIN} min
              fi
              done < $SADM_TMP_FILE1
    fi
    return $ERROR_COUNT
}







# --------------------------------------------------------------------------------------------------
#                                   Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # Switch for Help Usage (-h), Activate Debug Level (-d[1-9]), Nb hours to do backup (-t[1-9])
    while getopts "hd:t:s:" opt ; do                                    # Loop to process Switch
        case $opt in
            s) ONE_SERVER="$OPTARG"                                     # Backup only One server
               ;;
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            t) MAX_HOURS=$OPTARG                                        # Nb Hours to do the backups 
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
             if [ "$ONE_SERVER"  = " " ]
                then sadm_writelog "Nb. of hours given to do all today backup is ${MAX_HOURS}"
                else sadm_writelog "One Server to backup (${ONE_SERVER})"
             fi
    fi
    
    perform_backup                                                      # Go Launch ReaR Backup 
    SADM_EXIT_CODE=$?                                                   # 0=NoError else Error 
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
