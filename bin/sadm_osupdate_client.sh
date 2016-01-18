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
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib

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

#

#
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
    sadm_logger "Checking if update are available for $(sadm_os_name) version $(sadm_os_version) ..."
    
    if [ "$(sadm_os_name)" = "REDHAT" ] || [ "$(sadm_os_name)" = "CENTOS" ]
        then case "$(sadm_os_major_version)" in
                [3|4] )   sadm_logger "Running \"up2date -l\""          # Update the Log
                          sadm_logger "${SADM_DASH}"
                          up2date -l >> $SADM_LOG 2>&1                       # List update available
                          rc=$?                                         # Save Exit code
                          sadm_logger "${SADM_DASH}"
                          sadm_logger "Return Code after up2date -l is $rc" # Write exit code to log
                          case $rc in
                             0) UpdateStatus=0                          # Update Exist
                                sadm_logger "Update are available ..."  # Update log update avail.
                                ;;
                             *) UpdateStatus=2                          # Problem Abort Update
                                sadm_logger "NO UPDATE AVAILABLE"       # Update the log
                                ;;
                          esac
                          ;;
              [5|6|7])   sadm_logger "Running \"yum check-update\""     # Update the log
                         sadm_logger "${SADM_DASH}"
                         yum check-update >> $SADM_LOG 2>&1                  # List Available update
                         rc=$?                                          # Save Exit Code
                         sadm_logger "${SADM_DASH}"
                         sadm_logger "Return Code after yum check-update is $rc" # Write Exit code to log
                         case $rc in
                           100) UpdateStatus=0                          # Update Exist
                                sadm_logger "Update are available"      # Update the log
                                ;;
                             0) UpdateStatus=1                          # No Update available
                                sadm_logger "No Update available"
                                ;;
                             *) UpdateStatus=2                          # Problem Abort Update
                                sadm_logger "Error Encountered - Update aborted"  # Update the log
                                ;;
                          esac
                         ;;
             esac
    fi
    
    if [ "$(sadm_os_name)" = "UBUNTU" ] || [ "$(sadm_os_name)" = "DEBIAN" ]
        then sadm_logger "Resynchronize package index files from their sources via Internet"
             sadm_logger "Running \"apt-get update\""                   # Msg Get package list 
             apt-get update > /dev/null 2>&1                            # Get Package List From Repo
             rc=$?                                                      # Save Exit Code
             if [ "$rc" -ne 0 ]
                then UpdateStats=2
                     sadm_logger "We had problem running the \"apt-get update\" command" 
                     sadm_logger "We had a return code $rc" 
                else sadm_logger "Return Code after apt-get update is $rc"      # Show  Return Code
                     sadm_logger "Querying list of package that will be updated"
                     NB_UPD=`apt-get -s dist-upgrade |awk '/^Inst/ { print $2 }' |wc -l |tr -d ' '`
                     apt-get -s dist-upgrade |awk '/^Inst/ { print $2 }'
                     if [ "$NB_UPD" -ne 0 ]
                        then UpdateStatus=0
                             sadm_logger "${NB_UPD} Updates are available"
                        else UpdateStatus=1
                             sadm_logger "No Update available"
                     fi
             fi
    fi         
    sadm_logger " "
    return $UpdateStatus                                                # 0=UpdExist 1=NoUpd 2=Abort
}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with up2date command
# --------------------------------------------------------------------------------------------------
run_up2date()
{
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting the $(sadm_os_name) update  process ..."
    sadm_logger "Running \"up2date --nox -u\""
    up2date --nox -u >>$SADM_LOG 2>&1
    rc=$?
    sadm_logger "Return Code after up2date -u is $rc"
    if [ $rc -ne 0 ]
       then sadm_logger "Problem getting list of the update"
            sadm_logger "Update not performed - Processing aborted"
       else sadm_logger "Return Code = 0"
    fi
    sadm_logger "${SADM_DASH}"
    return $rc

}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with yum command
# --------------------------------------------------------------------------------------------------
run_yum()
{
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting the $(sadm_os_name) update  process ..."
    sadm_logger "Running : yum -y update"
    yum -y update  >>$SADM_LOG 2>&1
    rc=$?
    sadm_logger "Return Code after yum program update is $rc"
    sadm_logger "${SADM_DASH}"
    return $rc
}


# --------------------------------------------------------------------------------------------------
#                 Function to update the server with apt-get command
# --------------------------------------------------------------------------------------------------
run_apt_get()
{
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting the $(sadm_os_name) update process ..."

    sadm_logger "${TEN_DASH}"
    sadm_logger "Running : apt-get -y upgrade"
    apt-get -y upgrade | tee -a $SADM_LOG 2>&1
    rc1=$?
    sadm_logger "Return Code after \"apt-get -y upgrade\" is $rc1"      # Write Exit code to log

    sadm_logger "${TEN_DASH}"
    sadm_logger "Running : apt-get -y dist-upgrade "
    apt-get -y dist-upgrade | tee -a $SADM_LOG 2>&1
    rc2=$?
    sadm_logger "Return Code after \"apt-get -y upgrade\" is $rc2"      # Write Exit code to log
    RC=$(($rc1+$rc2))
    
    sadm_logger "${TEN_DASH}"
    sadm_logger "Return Code after apt-get upgrade and apt-get dist-upgrade is $RC"
    return $RC
}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Make sure Dir. Struc. exist     
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    check_available_update                                              # Check if avail. Update
    if [ $? -ne 0 ] ; then sadm_stop 0 ; exit 0 ; fi                    # If No Update Close the Shop

    case "$(sadm_os_name)" in                                           # Test OS Name
        "REDHAT"|"CENTOS" )     if [ $(sadm_os_major_version) -lt 5 ]   
                                    then run_up2date                    # Version 4 Run up2date
                                         SADM_EXIT_CODE=$?              # Save Return Code
                                    else run_yum                        # V 5 and above Run yum cmd
                                         SADM_EXIT_CODE=$?              # Save Return Code
                                fi     
                                ;; 
        "FEDORA"          )     run_yum
                                SADM_EXIT_CODE=$?
                                ;;
        "UBUNTU"|"DEBIAN" )     run_apt_get
                                SADM_EXIT_CODE=$?
                                ;;
        *)                      sadm_logger "This OS ($(sadm_os_name)) is not yet supported"
                                sadm_logger "Please report it to SADMIN Web Site"
                                ;;
    esac
   
    sadm_stop "$SADM_EXIT_CODE"                                         # End Process with exit Code
    exit  "$SADM_EXIT_CODE"                                             # Exit script
