#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_check_ip_change.sh
#   Synopsis :  Script check current internet IP and send email when it change.
#   Version  :  1.5
#   Date     :  November 2016
#   Requires :  sh
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
# Change Log
# 2017_07_04    v1.6 Don't send email when can't get current IP, instead Log it in IPMIS log.
# 2018_06_04    v1.7 Change Data Dir. from $SADMIN/jac/dat to $SADM_USR_DIR/dat
# --------------------------------------------------------------------------------------------------
#
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
    export SADM_VER='1.7'                               # Current Script Version
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
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
IPFILE="${SADM_USR_DIR}/dat/current_ip.txt"         ; export IPFILE         # Last execution IP
IPLOG="${SADM_USR_DIR}/dat/current_ip.log"          ; export IPLOG          # Log when IP Change
IPMIS="${SADM_USR_DIR}/dat/current_ip_mis.log"      ; export IPMIS          # Log Cannot Get Cur. IP
PREVIOUS_IP=""                                      ; export PREVIOUS_IP    # Last execution IP
CURRENT_IP=""                                       ; export CURRENT_IP     # Current IP
IP_NAME="batcave.ydns.eu"                           ; export IP_NAME        # Dynamic DNS Name





# --------------------------------------------------------------------------------------------------
#                             S c r i p t    M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    # Get the last IP we had at previous execution
    if [ -r $IPFILE ]
        then PREVIOUS_IP=`cat $IPFILE`
        else rm -f $IPFILE >/dev/null 2>&1
             PREVIOUS_IP=""
    fi

    # Get our current IP 
    CURRENT_IP=`getent hosts $IP_NAME | awk '{ print $1 }'`             # Save Current IP

    # Check if IP could be obtained - If not Exit
    if [ "$CURRENT_IP" = "" ] 
        then sadm_writelog "Cannot get the current Internet IP Address of $IP_NAME" 
             sadm_writelog "Skipping execution - Still at $PREVIOUS_IP"
             echo "`date` - Can't get IP Address of $IP_NAME Current $PREVIOUS_IP" >> $IPMIS 2>&1
             #
             #WSUBJECT="SADM : WARNING Internet IP for $IP_NAME could not be obtained at the moment"
             #MAIL_MSG="At last execution IP for $IP_NAME was ..${PREVIOUS_IP}.. - Skipping execution" 
             #echo "`date` - $MAIL_MSG" | $SADM_MAIL -s "$WSUBJECT" $SADM_MAIL_ADDR              
             return 0
    fi

    # Construct Email Message
    MAIL_MSG="Last time IP for ${IP_NAME} was '${PREVIOUS_IP}' now it's '${CURRENT_IP}'" 
    sadm_writelog "$MAIL_MSG" 
    
    # Check if IP Change - I so inform user
    if [ "$CURRENT_IP" != "$PREVIOUS_IP" ]
       then WSUBJECT="SADM : WARNING Internet IP for ..${IP_NAME}.. changed to ..${CURRENT_IP}.."
            sadm_writelog "The Internet IP Address of $IP_NAME just changed to $CURRENT_IP"
            echo "`date` - $MAIL_MSG" | $SADM_MAIL -s "$WSUBJECT" $SADM_MAIL_ADDR 
            sadm_writelog "Warning Email is sent to $SADM_MAIL_ADDR"
            echo "`date` - IP for $IP_NAME was $PREVIOUS_IP now it's $CURRENT_IP" >> $IPLOG
       else sadm_writelog "No change of IP"  
    fi

    # Save Current IP to $IPFILE
    echo $CURRENT_IP > $IPFILE                                          # Save Current IP
    return 0                                                            # Return Default return code
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    
    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T NEED TO RUN ON THE SADMIN MAIN SERVER, THEN REMOVE
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ] # Only run on SADMIN 
        then sadm_writelog "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T HAVE TO BE RUN BY THE ROOT USER, THEN YOU CAN REMOVE
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
