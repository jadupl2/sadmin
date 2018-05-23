#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_template_menu.sh
#   Synopsis : .
#   Version  :  1.0
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
# 1.6   
trap 'sadm_stop 0; exit 0' 2                                            # ctrl-c exit gracefully
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
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     

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
#                               Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    sadm_writelog ""
    sadm_writelog ""
    sadm_writelog "${SADM_DASH}"
    sadm_writelog "PROCESS LINUX SERVERS"

    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_active from sadm.server  "
    SQL2="where srv_ostype = 'linux' and srv_active = True "
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk -F, '{ print $1 }'`
              server_os=`    echo $wline|awk -F, '{ print $2 }'`
              server_domain=`echo $wline|awk -F, '{ print $3 }'`
              sadm_writelog "${SADM_DASH}"
              sadm_writelog "Processing ($xcount) os:${server_os} - server:${server_name}.${server_domain}"
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
#                               Process Aix servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    sadm_writelog ""
    sadm_writelog ""
    sadm_writelog "${SADM_DASH}"
    sadm_writelog "PROCESS AIX SERVERS"

    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_active from sadm.server  "
    SQL2="where srv_ostype = 'aix' and srv_active = True "
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk -F, '{ print $1 }'`
              server_os=`    echo $wline|awk -F, '{ print $2 }'`
              server_domain=`echo $wline|awk -F, '{ print $3 }'`
              sadm_writelog "${SADM_DASH}"
              sadm_writelog "Processing ($xcount) os:${server_os} - server:${server_name}.${server_domain}"
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
    sadm_start                                                          # Init Env. Dir & RC/Log File
    
    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T NEED TO RUN ON THE SADMIN MAIN SERVER, THEN REMOVE
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
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

    # Display Main Menu     
    while :
        do
        sadm_display_heading "Your Menu Heading Here"
        menu_array=("Your Menu Item 1" "Your Menu Item 2" \
                    "Your Menu Item 3" "Your Menu Item 4" )
        sadm_display_menu "${menu_array[@]}"
        sadm_choice=$?
        case $sadm_choice in
            1) # Option 1 - 
               # Put your code HERE
               ;;
            2) # Option 2 - 
               # Put your code HERE
               ;;
            3) # Option 3 - 
               # Put your code HERE
               ;;
            4) # Option 4 - 
               # Put your code HERE
               ;;
           99) # Option Quit -
               # Put your code HERE 
               break 
               ;;
            *) # Invalid Option #
               mess "\'($sadm_choice)\' is an invalid option"
               ;;
        esac
        done
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)

