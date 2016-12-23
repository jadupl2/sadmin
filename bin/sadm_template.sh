#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_template_servers.sh
#   Synopsis : .
#   Version  :  1.6
#   Date     :  14 November 2015
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
# Enhancements/Corrections Version Log
# 1.6   
# 
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
SADM_VER='1.6'                             ; export SADM_VER            # Script Version
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
    sadm_writelog "$SADM_PSQL -A -F , -t -h holmes.maison.ca $SADM_PGDB -U $SADM_RO_PGUSER -c $SQL" 
    #$SADM_PSQL -A -F , -t -h $PGHOST sadmin -U $PGUSER -c "$SQL" >$SADM_TMP_FILE1
    $SADM_PSQL -A -F , -t -h holmes.maison.ca $SADM_PGDB -U $SADM_RO_PGUSER -c "$SQL" >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`                                 # Server Counter
              server_name=`    echo $wline|awk -F, '{ print $1 }'`      # Extract Server Name
              server_os=`      echo $wline|awk -F, '{ print $2 }'`      # Extract O/S (linux/aix)
              server_domain=`  echo $wline|awk -F, '{ print $3 }'`      # Extract Domain of Server
              server_monitor=` echo $wline|awk -F, '{ print $4 }'`      # Monitor t=True f=False
              server_sporadic=`echo $wline|awk -F, '{ print $5 }'`      # Sporadic t=True f=False
              fqdn_server=`echo ${server_name}.${server_domain}`        # Create FQN Server Name
              sadm_writelog " " ; sadm_writelog " "
              sadm_writelog "${SADM_TEN_DASH}"
              info_line="Processing ($xcount) $fqdn_server"
              sadm_writelog "$info_line"
              if [ "$server_monitor" == "t" ]
                    then sadm_writelog "Monitoring is ON for $fqdn_server"
                    else sadm_writelog "Monitoring is OFF for $fqdn_server"
              fi
              if [ "$server_sporadic" == "t" ]
                    then sadm_writelog "Sporadic server is ON for $fqdn_server"
                    else sadm_writelog "Sporadic server is OFF for $fqdn_server"
              fi
              
              # PROCESS GOES HERE
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_writelog "ERROR NUMBER $RC for $server"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_writelog "RETURN CODE IS 0 - OK"
              fi
              done < $SADM_TMP_FILE1
    fi
    return $ERROR_COUNT
}






# --------------------------------------------------------------------------------------------------
#                      S c r i p t    M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    
    return 0                                                            # Return Default return code
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # Optional Command line switches    
    PAGER="ON" ; MAIL_ONLY="OFF" ; SERVER_NAME=""                       # Set Switch Default Value
    while getopts "pmhs:" opt ; do                                      # Loop to process Switch
        case $opt in
            p) PAGER="OFF"                                              # Display Continiously    
               ;;                                                       # No stop after each page
            m) MAIL_ONLY="ON"                                           # Output goes to sysadmin
               PAGER="OFF"                                              # Mail need pager to be off
               ;;                                       
            h) help                                                     # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;
            s) SERVER_NAME="$OPTARG"                                    # Display Only Server Name
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               help                                                     # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done  
    
    #main_process                                                        # Main Process
    #SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    LINUX_ERROR=0; AIX_ERROR=0                                          # Init. Error count to 0
    
    process_servers "linux"                                             # Process Active Linux 
    LINUX_ERROR=$?                                                      # Save Nb. Errors in process
    sadm_writelog "We had $LINUX_ERROR error(s) while processing Linux servers"

    process_servers "aix"                                               # Process Active Aix
    AIX_ERROR=$?                                                        # Save Nb. Errors in process
    sadm_writelog "We had $AIX_ERROR error(s) while processing Aix servers"
    
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                         # Total = AIX+Linux Errors

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
