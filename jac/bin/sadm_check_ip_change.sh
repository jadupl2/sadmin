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
# Version 1.6 - April 2017 
#       Don't send email when can't get current IP, instead Log it in IPMIS log.
# --------------------------------------------------------------------------------------------------
#
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
SADM_VER='1.6'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="Y"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     


#
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
#SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
#SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
#SADM_WWW_USER="apache"                      ; export SADM_WWW_USER      # /sadmin/www owner 
#SADM_WWW_GROUP="apache"                     ; export SADM_WWW_GROUP     # /sadmin/www group
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=60                        ; export SADM_SAR_KEEPDAYS  # Days to keep old *.sar
#SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
#SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log

#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
IPFILE="${SADM_BASE_DIR}/jac/dat/current_ip.txt"    ; export IPFILE         # Last execution IP
IPLOG="${SADM_BASE_DIR}/jac/dat/current_ip.log"     ; export IPLOG          # Log when IP Change
IPMIS="${SADM_BASE_DIR}/jac/dat/current_ip_mis.log" ; export IPMIS          # Log Cannot Get Cur. IP
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
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
