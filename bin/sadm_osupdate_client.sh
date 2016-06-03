#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Linux OS Update script
#   Synopsis:   This script is used to update the Linux OS
#   Update  :   March 2015 -  J.Duplessis
#
# --------------------------------------------------------------------------------------------------
#set -x
#

#

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='2.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

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



# --------------------------------------------------------------------------------------------------
#               Function to check update available before beginning update
# Function Return
# - 0 IF UPDATE ARE AVAILABLE
# - 1 IF NO UPDATE ARE AVAILABLE
# - 2 IF PROBLEM CHECKING FOR UPDATE
# --------------------------------------------------------------------------------------------------
check_available_update()
{
    sadm_writelog "Checking update for $(sadm_get_osname) version $(sadm_get_osversion) ..."
    
    # RedHat/CentOS/Fedora Base Update 
    if [ "$(sadm_get_osname)" = "REDHAT" ] || 
       [ "$(sadm_get_osname)" = "CENTOS" ] || 
       [ "$(sadm_get_osname)" = "FEDORA" ]
        then case "$(sadm_get_osmajorversion)" in
                [3|4]) sadm_writelog "Running \"up2date -l\""           # Update the Log
                       sadm_writelog "${SADM_TEN_DASH}"
                       up2date -l >> $SADM_LOG 2>&1                     # List update available
                       rc=$?                                            # Save Exit code
                       sadm_writelog "${SADM_TEN_DASH}"
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
              [5|6|7]) sadm_writelog "Running \"yum check-update\""     # Update the log
                       sadm_writelog "${SADM_TEN_DASH}"
                       yum check-update >> $SADM_LOG 2>&1               # List Available update
                       rc=$?                                            # Save Exit Code
                       sadm_writelog "${SADM_TEN_DASH}"
                       sadm_writelog "Return Code after yum check-update is $rc" # Exit code to log
                       case $rc in
                         100) UpdateStatus=0                            # Update Exist
                              sadm_writelog "Update are available"      # Update the log
                              ;;
                           0) UpdateStatus=1                            # No Update available
                              sadm_writelog "No Update available"
                              ;;
                           *) UpdateStatus=2                            # Problem Abort Update
                              sadm_writelog "Error Encountered - Update aborted"  # Update the log
                              ;;
                        esac
                        ;;
             esac
    fi
    
    if [ "$(sadm_get_osname)" = "UBUNTU" ] || 
       [ "$(sadm_get_osname)" = "DEBIAN" ] ||
       [ "$(sadm_get_osname)" = "RASPBIAN" ]
        then sadm_writelog "Resynchronize package index files from their sources via Internet"
             sadm_writelog "Running \"apt-get update\""                 # Msg Get package list 
             apt-get update > /dev/null 2>&1                            # Get Package List From Repo
             rc=$?                                                      # Save Exit Code
             if [ "$rc" -ne 0 ]
                then UpdateStats=2
                     sadm_writelog "We had problem running the \"apt-get update\" command" 
                     sadm_writelog "We had a return code $rc" 
                else sadm_writelog "Return Code after apt-get update is $rc"  # Show  Return Code
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
    sadm_writelog "Running : apt-get -y upgrade"
    apt-get -y upgrade | tee -a $SADM_LOG 2>&1
    rc1=$?
    sadm_writelog "Return Code after \"apt-get -y upgrade\" is $rc1"    # Write Exit code to log

    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Running : apt-get -y dist-upgrade "
    apt-get -y dist-upgrade | tee -a $SADM_LOG 2>&1
    rc2=$?
    sadm_writelog "Return Code after \"apt-get -y upgrade\" is $rc2"    # Write Exit code to log
    RC=$(($rc1+$rc2))
    
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Return Code after apt-get upgrade and apt-get dist-upgrade is $RC"
    return $RC
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
    
    check_available_update                                              # Check if avail. Update
    if [ $? -ne 0 ] ; then sadm_stop 0 ; exit 0 ; fi                    # No Update Close the Shop

    case "$(sadm_get_osname)" in                                        # Test OS Name
        "REDHAT"|"CENTOS" )     
                                if [ $(sadm_get_osmajorversion) -lt 5 ]   
                                    then run_up2date                    # Version 3 or 4 use up2date
                                         SADM_EXIT_CODE=$?              # Save Return Code
                                    else run_yum                        # V 5 and above use yum cmd
                                         SADM_EXIT_CODE=$?              # Save Return Code
                                fi     
                                ;; 
                                
        "FEDORA"          )         
                                run_yum
                                SADM_EXIT_CODE=$?
                                ;;
                                
        "UBUNTU"|"DEBIAN"|"RASPBIAN" )     
                                run_apt_get
                                SADM_EXIT_CODE=$?
                                ;;
        *)                      sadm_writelog "This OS ($(sadm_get_osname)) is not yet supported"
                                sadm_writelog "Please report it to SADMIN Web Site at this email :"
                                sadm_writelog "webadmin@sadmin.ca"
                                ;;
    esac
   
    sadm_stop "$SADM_EXIT_CODE"                                         # End Process with exit Code
    exit  "$SADM_EXIT_CODE"                                             # Exit script
