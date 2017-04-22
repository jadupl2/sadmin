#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Linux O/S Update script 
#   Synopsis:   This script is used to update the Linux OS Platform 
#               Support Redhat/Centos v3,4,5,6,7 - Ubuntu - Debian V7,8 - Raspbian V7,8 - Fedora
#   Update  :   March 2015 -  J.Duplessis
#
# --------------------------------------------------------------------------------------------------
# Version 2.6 - Nov 2016 
#       Insert Logic to Reboot the server after a successfull update
#        (If Specified in Server information in the Database)
#        The script receive a Y or N (Uppercase) as the first command line parameter to 
#        indicate if a reboot is requested.
# Version 2.7 - Nov 2016
#       Script Return code (SADM_EXIT_CODE) was set to 0 even if Error were detected when checking 
#       if update were available. Now Script return an error (1) when checking for update.
# Version 2.8 - Dec 2016
#       Correction minor bug with shutdown reboot command on Raspberry Pi
#       Now Checking if Script is running of SADMIN server at the beginning
#           - No automatic reboot on the SADMIN server while it is use to start update on client
# Version 2.9 - April 2017 
#       Added Support for Linux Mint 
# Version 3.0 - April 2017 
#       Not detecting Error correctly on Debian Family update
#       Add Error Message in the Log
# --------------------------------------------------------------------------------------------------
#

#set -x
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='3.1'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  
# -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  

#
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Default is in sadmin.cfg
SADM_MAIL_TYPE=3                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
#SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
#SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=60                        ; export SADM_SAR_KEEPDAYS  # Days to keep old *.sar
#SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
#SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log
#SADM_PGUSER="postgres"                      ; export SADM_PGUSER        # PostGres User Name
#SADM_PGGROUP="postgres"                     ; export SADM_PGGROUP       # PostGres Group Name
#SADM_PGDB=""                                ; export SADM_PGDB          # PostGres DataBase Name
#SADM_PGSCHEMA=""                            ; export SADM_PGSCHEMA      # PostGres DataBase Schema
#SADM_PGHOST=""                              ; export SADM_PGHOST        # PostGres DataBase Host
#SADM_PGPORT=5432                            ; export SADM_PGPORT        # PostGres Listening Port
#SADM_RW_PGUSER=""                           ; export SADM_RW_PGUSER     # Postgres Read/Write User 
#SADM_RW_PGPWD=""                            ; export SADM_RW_PGPWD      # PostGres Read/Write Passwd
#SADM_RO_PGUSER=""                           ; export SADM_RO_PGUSER     # Postgres Read Only User 
#SADM_RO_PGPWD=""                            ; export SADM_RO_PGPWD      # PostGres Read Only Passwd
#SADM_SERVER=""                              ; export SADM_SERVER        # Server FQN Name
#SADM_DOMAIN=""                              ; export SADM_DOMAIN        # Default Domain Name

#===================================================================================================
#

# --------------------------------------------------------------------------------------------------
#                               Script Variables definition
# --------------------------------------------------------------------------------------------------

# Command to issue the shutdown / Reboot after the update if requested
REBOOT_CMD="/sbin/shutdown -r now"           ; export REBOOT_CMD         # Reboot Command

# Default to no reboot after an update
WREBOOT="N"                                 ; export WREBOOT             # No reboot after update




# --------------------------------------------------------------------------------------------------
#               Function to check update available before beginning update
# Function Return
# - 0 IF UPDATE ARE AVAILABLE
# - 1 IF NO UPDATE ARE AVAILABLE
# - 2 IF PROBLEM CHECKING FOR UPDATE
# --------------------------------------------------------------------------------------------------
check_available_update()
{
    sadm_writelog "Checking update for $(sadm_get_osname) version $(sadm_get_osmajorversion) ..."
    
    # RedHat/CentOS/Fedora Base Update 
    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] || 
       [ "$(sadm_get_osname)" = "FEDORA" ]
        then case "$(sadm_get_osmajorversion)" in
                [3-4]) sadm_writelog "Running \"up2date -l\""           # Update the Log
                       up2date -l >> $SADM_LOG 2>&1                     # List update available
                       rc=$?                                            # Save Exit code
                       sadm_writelog "Return Code after up2date -l is $rc" # Exit code to log
                       case $rc in
                          0) UpdateStatus=0                             # Update Exist
                             sadm_writelog "Update are available ..."   # Update log update avail.
                             ;;
                          *) UpdateStatus=2                             # Problem Abort Update
                             sadm_writelog "NO UPDATE AVAILABLE"        # Update the log
                             ;;
                       esac
                       ;;
              [5-7])   sadm_writelog "Running \"yum check-update\""     # Update the log
                       yum check-update >> $SADM_LOG 2>&1               # List Available update
                       rc=$?                                            # Save Exit Code
                       sadm_writelog "Return Code after \"yum check-update\" is $rc" # Exit code to log
                       case $rc in
                         100) UpdateStatus=0                            # Update Exist
                              sadm_writelog "Update are available"      # Update the log
                              ;;
                           0) UpdateStatus=1                            # No Update available
                              sadm_writelog "No Update available"
                              ;;
                           *) UpdateStatus=2                            # Problem Abort Update
                              sadm_writelog "Error Encountered - Update aborted"  # Update the log
                              sadm_writelog "For more information check the log $SADM_LOG"
                              ;;
                        esac
                        ;;
             esac
    fi
    
    if [ "$(sadm_get_osname)" = "UBUNTU" ]   || [ "$(sadm_get_osname)" = "DEBIAN" ] ||
       [ "$(sadm_get_osname)" = "RASPBIAN" ] || [ "$(sadm_get_osname)" = "LINUXMINT" ] 
        then sadm_writelog "Resynchronize package index files from their sources via Internet"
             sadm_writelog "Running \"apt-get update\""                 # Msg Get package list 
             apt-get update  >> $SADM_LOG 2>&1                          # Get Package List From Repo
             rc=$?                                                      # Save Exit Code
             if [ "$rc" -ne 0 ]
                then UpdateStatus=2
                     sadm_writelog "We had problem running the \"apt-get update\" command" 
                     sadm_writelog "We had a return code $rc" 
                     sadm_writelog "For more information check the log $SADM_LOG"
                else sadm_writelog "Return Code of apt-get update: $rc" # Show  Return Code
                     sadm_writelog "Querying list of package that will be updated"
                     NB_UPD=`apt-get -s dist-upgrade |awk '/^Inst/ { print $2 }' |wc -l |tr -d ' '`
                     apt-get -s dist-upgrade |awk '/^Inst/ { print $2 }'
                     if [ "$NB_UPD" -ne 0 ]
                        then UpdateStatus=0
                             sadm_writelog "${NB_UPD} Updates are available"
                        else UpdateStatus=1
                             sadm_writelog "No Update available"
                     fi
             fi
    fi         
    sadm_writelog " "
    return $UpdateStatus                                                # 0=UpdExist 1=NoUpd 2=Abort
    
}




# --------------------------------------------------------------------------------------------------
#             Function to update the server with up2date command (RHEL3 and RHEL4)
# --------------------------------------------------------------------------------------------------
run_up2date()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Starting the $(sadm_get_osname) update  process ..."
    sadm_writelog "Running \"up2date --nox -u\""
    up2date --nox -u >>$SADM_LOG 2>&1
    rc=$?
    sadm_writelog "Return Code after up2date -u is $rc"
    if [ $rc -ne 0 ]
       then sadm_writelog "Problem getting list of the update"
            sadm_writelog "Update not performed - Processing aborted"
       else sadm_writelog "Return Code = 0"
    fi
    sadm_writelog "${SADM_TEN_DASH}"
    return $rc

}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with yum command
# --------------------------------------------------------------------------------------------------
run_yum()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Starting the $(sadm_get_osname) update process ..."
    sadm_writelog "Running : yum -y update"
    yum -y update  >>$SADM_LOG 2>&1
    rc=$?
    sadm_writelog "Return Code after yum program update is $rc"
    sadm_writelog "${SADM_TEN_DASH}"
    return $rc
}


# --------------------------------------------------------------------------------------------------
#                 Function to update the server with apt-get command
# --------------------------------------------------------------------------------------------------
run_apt_get()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Starting the $(sadm_get_osname) update process ..."
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Running : apt-get -y -o Dpkg::Options::='--force-confdef -o Dpkg::Options::='--force-confold' upgrade" 
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ] 
       then sadm_writelog "Return Code of \"apt-get -y upgrade\" is $RC" 
            return $RC
    fi
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Running : apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade" 
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ] 
        then sadm_writelog "Return Code of \"apt-get -y dist-upgrade\" is $RC" 
             return $RC
    fi
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Success execution of apt-get upgrade & apt-get dist-upgrade"
    return 0
}




# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#

    sadm_start                                                          # Make sure Dir. Struc. exist     
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi


    # If Parameter #1 received is "Y", then server will reboot after update (Default No Reboot)
    if [ $# -eq 1 ]                                                     # If one Param. Recv.
        then WREBOOT=`sadm_toupper $1`                                  # Make sure it is UpperCase
             if [ "$WREBOOT" = "Y" ]                                    # Unless Recv. Param #1=Y
                then sadm_writelog "A Reboot is requested after a successfull update" 
                     WREBOOT="Y" 
                else sadm_writelog "Reboot is not requested after the update"
             fi
    fi

    # Check if Actual Server is the Main SADMIN server - No automatic Reboot for that server
    SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'`         # Need a No FQDM of SADM Srv
    if [ "$HOSTNAME" = "$SADM_SRV_NAME" ]
        then sadm_writelog "Automatic reboot cancelled for this server"
             sadm_writelog "No Automatic reboot on the SADMIN Main server ($SADM_SERVER)"
             WREBOOT="N"
    fi         


    UPDATE_AVAILABLE=0                                                  # Assume no Upd. Available
    check_available_update                                              # Check if Update is Avail.
    RC=$?                                                               # 0=UpdAvail 1=NoUpd 2=Error
    if [ $RC -eq 0 ]                                                    # If Update are Available
       then UPDATE_AVAILABLE=1                                          # Set Upd to be done Flag ON
            case "$(sadm_get_osname)" in                                # Test OS Name
                "REDHAT"|"CENTOS" )         
                        if [ $(sadm_get_osmajorversion) -lt 5 ]   
                            then    run_up2date                         # Version 3 or 4 use up2date
                                    SADM_EXIT_CODE=$?                   # Save Return Code
                            else    run_yum                             # V 5 and above use yum cmd
                                    SADM_EXIT_CODE=$?                   # Save Return Code
                        fi
                        ;; 
                                
                "FEDORA" ) 
                        run_yum
                        SADM_EXIT_CODE=$?
                        ;;
                                
                "UBUNTU"|"DEBIAN"|"RASPBIAN"|"LINUXMINT" )     
                        run_apt_get
                        SADM_EXIT_CODE=$?
                        ;;

                *)   
                        sadm_writelog "This OS ($(sadm_get_osname)) is not yet supported"
                        sadm_writelog "Please report it to SADMIN Web Site at this email :"
                        sadm_writelog "webadmin@sadmin.ca"
                        ;;
            esac
       else if [ $RC -eq 1 ]                                            # If No Update Avail
                then SADM_EXIT_CODE=0                                   # No Update Final Code to 0
                else SADM_EXIT_CODE=1                                   # Error Encountered set to 1
            fi
    fi

    # If server Reboot was requested and update was available and Applied successfully, then reboot
    SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'`         # Need a No FQDM of SADM Srv
    if [ "$WREBOOT" = "Y" ]                                             # If Reboot was requested
       then if [ $UPDATE_AVAILABLE -eq 0 ]                              # If Update was Applied
               then sadm_writelog "No need to reboot since no update were applied" 
               else if [ "$SADM_EXIT_CODE" -eq 0 ]                      # If Update was a success
                       then sadm_writelog "Update was successfull, server will reboot in 1 Minute"
                            sadm_writelog "Running \"${REBOOT_CMD}\" in 1 Minute" 
                            echo "${REBOOT_CMD}" | at now + 1 Minute 
                       else sadm_writelog "Update unsuccessfull, no reboot performed"
                    fi
                    sadm_writelog "${SADM_DASH}"
            fi
    fi
    
    sadm_stop "$SADM_EXIT_CODE"                                         # End Process with exit Code
    exit  "$SADM_EXIT_CODE"                                             # Exit script
