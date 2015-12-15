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

#set -x
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH VARIABLES AND
#   FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#
#


# --------------------------------------------------------------------------------------------------
# Script Variables definition
# --------------------------------------------------------------------------------------------------
SELINUX=`getenforce`                                                    # Get SELINUX Status
if [ "$SELINUX" == "Enforcing" ] ; then USING_SELINUX="Y" ; else USING_SELINUX="N" ; fi
export SELINUX USING_SELINUX                                            # Export SELINUX Status




# --------------------------------------------------------------------------------------------------
#               Function to check update available before beginning update
# --------------------------------------------------------------------------------------------------
check_available_update()
{
    sadm_logger "Checking if update are available for version $(sadm_os_version) ..."
    case "$(sadm_os_version)" in
      [34] ) sadm_logger "Running \"up2date -l\""                         # Update the Log
             sadm_logger "${DASH}"
             up2date -l >> $LOG 2>&1                                    # List update available
             rc=$?                                                      # Save Exit code
             sadm_logger "${DASH}"
             sadm_logger "Return Code after up2date -l is $rc"            # Write exit code to log
             case $rc in
                0) UpdateStatus=0                                       # Update Exist
                   sadm_logger "Update are available ..."                 # Update log update avail.
                   ;;
                *) UpdateStatus=2                                       # Problem Abort Update
                   sadm_logger "NO UPDATE AVAILABLE"                      # Update the log
                   ;;
             esac
             ;;
     [567] ) sadm_logger "Running \"yum check-update\""                   # Update the log
             sadm_logger "${DASH}"
             yum check-update >> $LOG 2>&1                              # List Available update
             rc=$?                                                      # Save Exit Code
             sadm_logger "${DASH}"
             sadm_logger "Return Code after yum check-update is $rc"      # Write Exit code to log
             case $rc in
              100) UpdateStatus=0                                       # Update Exist
                   sadm_logger "Update are available"                     # Update the log
                   ;;
                0) UpdateStatus=1                                       # No Update available
                   sadm_logger "NO UPDATE AVAILABLE"                      # Update the log
                   ;;
                *) UpdateStatus=2                                       # Problem Abort Update
                   sadm_logger "Error Encountered - Update aborted"       # Update the log
                   ;;
             esac
             ;;
    esac
    sadm_logger "${DASH}"
    return $UpdateStatus                                                # 0=UpdExist 1=NoUpd 2=Abort
}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with up2date command
# --------------------------------------------------------------------------------------------------
run_up2date()
{
    sadm_logger "${DASH}"
    sadm_logger "Running Update."
    sadm_logger "Running \"up2date --nox -u\""
    up2date --nox -u >>$LOG 2>&1
    rc=$?
    sadm_logger "Return Code after up2date -u is $rc"
    if [ $rc -ne 0 ]
       then sadm_logger "Problem getting list of the update"
            sadm_logger "Update not performed - Processing aborted"
       else sadm_logger "Return Code = 0"
    fi
    sadm_logger "${DASH}"
    return $rc

}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with yum command
# --------------------------------------------------------------------------------------------------
run_yum()
{
    sadm_logger "${DASH}"
    sadm_logger "Starting yum update process ..."
    sadm_logger "Running : yum -y update"
    yum -y update  >>$LOG 2>&1
    rc=$?
    sadm_logger "Return Code after yum program update is $rc"
    sadm_logger "${DASH}"
    return $rc
}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Make sure Dir. Struc. exist
    check_available_update                                              # Check if avail. Update
    if [ $? -ne 0 ]                                                     # No update available - Exit
        then sadm_stop 0                                                # Update rc file
             exit 0                                                     # Exit with 0 = normal
    fi

    # If SELinux is ON - We need to turn it off while updating O/S
    sadm_logger "SELinux is ${SELINUX}."
    if [ "$USING_SELINUX" == "Y" ]                                      # If SELinux is Activated
        then sadm_logger "Disabling SELinux while the update is running." # Advise user
             setenforce 0 >> $LOG 2>&1                                  # Disable SELinux
             getenforce   >> $LOG 2>&1                                  # Display SELinux Status
    fi

    # Run the OS Update
    if [ $(sadm_os_version) -lt 5 ]  ; then run_up2date ; else run_yum ; fi     # Update the Server
    rc=$? ; export rc                                                   # Save Return Code

    # Reactivate SELINUX if it was de-activated at the beginning
    if [ "$USING_SELINUX" == "Y" ]
        then sadm_logger "Re-enabling SELinux ... "
             setenforce 1 >> $LOG 2>&1
             getenforce >> $LOG 2>&1
    fi

    # Update and close Logs
    sadm_stop $rc                                                       # End Process with exit Code
    exit $rc                                                            # Exit script
