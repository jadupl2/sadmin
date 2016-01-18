#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_template.sh
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
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  

# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export ADM_MAIL_ADDR        # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                          ; export SADM_MAIL_TYPE       # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME        # Company Name
#SADM_USER="sadmin"                        ; export SADM_USER            # sadmin user account
#SADM_GROUP="sadmin"                       ; export SADM_GROUP           # sadmin group account
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE     # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE      # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=40                      ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#===================================================================================================
#






# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
MUSER="query"                                   ; export MUSER          # MySql User
MPASS="query"                                   ; export MPASS          # MySql Password
MHOST="sysinfo.maison.ca"                       ; export MHOST          # Mysql Host
MYSQL="$(which mysql)"                          ; export MYSQL          # Location of mysql program
#






# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    SQL3="where server_doc_only=0 and server_active=1 and server_os='Linux' order by server_name;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=`expr $xcount + 1`
              server_name=`  echo $wline|awk '{ print $1 }'`
              server_os=`    echo $wline|awk '{ print $2 }'`
              server_domain=`echo $wline|awk '{ print $3 }'`
              server_type=`  echo $wline|awk '{ print $4 }'`
              sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              sadm_logger "${SADM_DASH}"
              # PROCESS GOES HERE
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for $server"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
              fi
              done < $SADM_TMP_FILE1
    fi
    return $ERROR_COUNT
}




# --------------------------------------------------------------------------------------------------
#                      Process Aix servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    SQL3="where server_doc_only=0 and server_active=1 and server_os='Aix' order by server_name;"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$SADM_TMP_FILE1

    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
              do
              xcount=$(($xcount+1))
              server_name=`  echo $wline|awk '{ print $1 }'`
              server_os=`    echo $wline|awk '{ print $2 }'`
              server_domain=`echo $wline|awk '{ print $3 }'`
              server_type=`  echo $wline|awk '{ print $4 }'`
              sadm_logger "Processing ($xcount) ${server_os} ${server_type} server : ${server_name}.${server_domain}"
              sadm_logger "${SADM_DASH}"
              # PROCESS GOES HERE
              RC=$? ; RC=0
              if [ $RC -ne 0 ]
                 then sadm_logger "ERROR NUMBER $RC for $server"
                      ERROR_COUNT=$(($ERROR_COUNT+1))
                 else sadm_logger "RETURN CODE IS 0 - OK"
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
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
        then sadm_logger "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T HAVE TO BE RUN BY THE ROOT USER, THEN YOU CAN REMOVE
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi


#####  YOU CAN USE THIS CODE IF YOU WANT TO USE MENU IN YOUR SCRIPT #####
    while :
        do
        sadm_display_heading "Your Menu Heading Here"
        menu_array=("Your Menu Item 1" "Your Menu Item 2" "Your Menu Item 3" "Your Menu Item 4" \
                    "Your Menu Item 5"  )
        sadm_display_menu "${menu_array[@]}"
        sadm_choice=$?
        #echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy
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
            5) # Option 5 - 
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
    

##### OR USE THIS PART OF THE CODE TO PROCESS YOUR LINUX OR AIX ACTIVE SERVER #####
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    process_linux_servers                                               # Process Active Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting
    process_aix_servers                                                 # Process Active Aix Servers
    AIX_ERROR=$?                                                        # Set Nb. Errors while processing
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                        # Total = AIX+Linux Errors

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                          # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                               # Exit With Global Err (0/1)

