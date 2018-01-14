#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Title       :   sadm_XXXXXXXX.sh
#   Synopsis    :   .
#   Version     :   1.0
#   Date        :   5 January 2018
#   Requires    :   sh and SADMIN Library
#   Description :
#
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2017_07_07 JDuplessis V1.0 - Initial Version
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.0'                             ; export SADM_VER            # Your Script Version
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
#




#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose






#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
#===================================================================================================
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
    echo " "
}


#===================================================================================================
#                                   Process All Actives Servers 
#===================================================================================================
process_servers()
{
    sadm_writelog "Processing All Actives Server(s)"

    # Select Active Server From Database & output result in CSV Format to $SADM_TMP_FILE1 work file
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active"
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    CMDLINE1="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "        # MySQL & Use Read Only User  
    CMDLINE2="-h $SADM_DBHOST $SADM_DBNAME -Ne '$SQL' |tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ]                                           # If Debug Level > 5 
        then sadm_writelog "$CMDLINE1 $CMDLINE2"                        # Debug = Write SQL CMD Line
    fi

    # Execute SQL Query to Create CSV Work File - $SADM_TMP_FILE1
    $CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    # If File was not created or has a zero lenght then No Actives Servers were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_writelog "No Active Server were found."               # Not ACtive Server MSG
             return 1                                                   # Return Error to Caller
    fi 
    
    xcount=0; ERROR_COUNT=0;                                            # Reset Server/Error Counter
    while read wline                                                    # Then Read Line by Line
        do
        xcount=`expr $xcount + 1`                                       # Server Counter
        server_name=`    echo $wline|awk -F, '{ print $1 }'`            # Extract Server Name
        server_os=`      echo $wline|awk -F, '{ print $2 }'`            # Extract O/S (linux/aix)
        server_domain=`  echo $wline|awk -F, '{ print $3 }'`            # Extract Domain of Server
        server_monitor=` echo $wline|awk -F, '{ print $4 }'`            # Monitor  t=True f=False
        server_sporadic=`echo $wline|awk -F, '{ print $5 }'`            # Sporadic t=True f=False
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQN Server Name
        #
        sadm_writelog " "                                               # Blank Line
        sadm_writelog "${SADM_TEN_DASH}"                                # Ten Dashes Line    
        sadm_writelog "Processing ($xcount) $fqdn_server"               # Show Current System 
        
        if [ $DEBUG_LEVEL -gt 0 ]                                       # If Debug Activated
            then if [ "$server_monitor" == "1" ]                        # Monitor Flag is at True
                    then sadm_writelog "Monitoring is ON for $fqdn_server"
                    else sadm_writelog "Monitoring is OFF for $fqdn_server"
                 fi
                 if [ "$server_sporadic" == "1" ]                       # Sporadic Flag is at True
                    then sadm_writelog "Sporadic system is ON for $fqdn_server"
                    else sadm_writelog "Sporadic system is OFF for $fqdn_server"
                 fi
        fi

        # If Server Name can't be resolved - Signal Error to user and continue with next system.
        if ! host  $fqdn_server >/dev/null 2>&1
            then SMSG="[ ERROR ] Can't process '$fqdn_server', hostname can't be resolved"
                 sadm_writelog "$SMSG"                                  # Advise user
                 echo "$SMSG" >> $SADM_ELOG                             # Log Err. to Email Log
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 if [ $ERROR_COUNT -ne 0 ]                              # If Error count not at zero
                    then sadm_writelog "Total error(s) : $ERROR_COUNT"  # Show Total Error Count
                 fi
                 continue                                               # Continue with next Server
        fi

        # Try a SSH to the Server
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_writelog "$SADM_SSH_CMD $fqdn_server date" ; fi 
        $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1                # SSH to Server for date
        RC=$?                                                           # Save Return Code Number
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_writelog "Return Code is $RC" ;fi 

        # If SSH failed and it's a Sporadic Server, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
            then sadm_writelog "[ WARNING ] Can't SSH to sporadic system $fqdn_server"
                 sadm_writelog "            Continuing with next system"
                 continue                                               # Go process next system
        fi

        # If SSH Failed & Monitoring is Off, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_monitor" = "0" ]                # SSH don't work/Monitor OFF
            then sadm_writelog "[ WARNING ] Can't SSH to $fqdn_server - Monitoring is OFF"
                 sadm_writelog "            Continuing with next system"
                 continue                                               # Go process next system
        fi

        # If SSH Failed - Retry 3 Times before declaring an Error
        if [ $RC -ne 0 ] 
            then RETRY=0                                                # Set Retry counter to zero
                 while [ $RETRY -lt 3 ]                                 # Retry 3 times ?
                    do
                    let RETRY=RETRY+1                                   # Increase Retry counter
                    $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1    # SSH to Server for date
                    RC=$?                                               # Save Error Number
                    if [ $RC -ne 0 ] &&  [ $RETRY -gt 3 ] ;then break ;fi # Error More than 3 Times
                    sadm_writelog "[ RETRY $RETRY ] $SADM_SSH_CMD $fqdn_server date"
                    done
        fi

        # If All SSH test failed, Issue Error Message and continue with next system
        if [ $RC -ne 0 ]   
            then SMSG="[ ERROR ] Can't SSH to system '${fqdn_server}'"  
                 sadm_writelog "$SMSG"                                  # Display Error Msg
                 echo "$SMSG" >> $SADM_ELOG                             # Log Err. to Email Log
                 echo "COMMAND : $SADM_SSH_CMD $fqdn_server date" >> $SADM_ELOG
                 echo "----------" >> $SADM_ELOG
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Consider Error -Incr Cntr
                 continue                                               # Continue with next system
        fi
        sadm_writelog "[ OK ] SSH to $fqdn_server work"                 # Good SSH Work

        # PROCESS GOES HERE
        # ........
        # ........
        done < $SADM_TMP_FILE1
    return $ERROR_COUNT                                                 # Return Error Count
}






#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    sadm_writelog "Main Process as started ..."

    return 0                                                            # Return No Error to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN Server
        then sadm_writelog "Script only run on SADMIN system (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9]) ---------------------------------
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

    # MAIN SCRIPT PROCESS HERE ---------------------------------------------------------------------
    # main_process                                                      # Main Process
    # OR
    process_servers                                                     # Process Active Servers

    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
