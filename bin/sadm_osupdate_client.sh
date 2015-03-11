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

# --------------------------------------------------------------------------------------------------
# These variables got to be defined prior to calling the initialize (sadm_init.sh) script                                    Script Variables Definitions
# --------------------------------------------------------------------------------------------------
#
PN=${0##*/}                                    ; export PN              # Current Script name
VER='2.9'                                      ; export VER             # Program version
DEBUG=0                                        ; export DEBUG           # Debug ON (1) or OFF (0)
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
RC_MAX_LINES=100                               ; export RC_MAX_LINES    # Max Nb. Of Line in RCLOG (Trim)
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code

# --------------------------------------------------------------------------------------------------
# Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -f ${BASE_DIR}/bin/sadm_init.sh ] && . ${BASE_DIR}/bin/sadm_init.sh   # Init Var. & Load sadm functions


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
    write_log "Checking if update are available for version $OSVERSION ..."
    case "$OSVERSION" in
      [34] ) write_log "Running \"up2date -l\""                         # Update the Log
             write_log "${DASH}"
             up2date -l >> $LOG 2>&1                                    # List update available
             rc=$?                                                      # Save Exit code
             write_log "${DASH}"
             write_log "Return Code after up2date -l is $rc"            # Write exit code to log
             case $rc in
                0) UpdateStatus=0                                       # Update Exist
                   write_log "Update are available ..."                 # Update log update avail.
                   ;;
                *) UpdateStatus=2                                       # Problem Abort Update
                   write_log "NO UPDATE AVAILABLE"                      # Update the log
                   ;;
             esac
             ;;
     [567] ) write_log "Running \"yum check-update\""                   # Update the log
             write_log "${DASH}"
             yum check-update >> $LOG 2>&1                              # List Available update
             rc=$?                                                      # Save Exit Code
             write_log "${DASH}"
             write_log "Return Code after yum check-update is $rc"      # Write Exit code to log
             case $rc in
              100) UpdateStatus=0                                       # Update Exist
                   write_log "Update are available"                     # Update the log
                   ;;
                0) UpdateStatus=1                                       # No Update available
                   write_log "NO UPDATE AVAILABLE"                      # Update the log
                   ;;
                *) UpdateStatus=2                                       # Problem Abort Update
                   write_log "Error Encountered - Update aborted"       # Update the log
                   ;;
             esac
             ;;
    esac
    write_log "${DASH}"
    return $UpdateStatus                                                # 0=UpdExist 1=NoUpd 2=Abort
}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with up2date command
# --------------------------------------------------------------------------------------------------
run_up2date()
{
    write_log "${DASH}"
    write_log "Running Update."
    write_log "Running \"up2date --nox -u\""
    up2date --nox -u >>$LOG 2>&1
    rc=$?
    write_log "Return Code after up2date -u is $rc"
    if [ $rc -ne 0 ]
       then write_log "Problem getting list of the update"
            write_log "Update not performed - Processing aborted"
       else write_log "Return Code = 0"
    fi
    write_log "${DASH}"
    return $rc

}




# --------------------------------------------------------------------------------------------------
#                 Function to update the server with yum command
# --------------------------------------------------------------------------------------------------
run_yum()
{
    write_log "${DASH}"
    write_log "Starting yum update process ..."
    write_log "Running : yum -y update"
    yum -y update  >>$LOG 2>&1
    rc=$?
    write_log "Return Code after yum program update is $rc"
    write_log "${DASH}"
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
    write_log "SELinux is ${SELINUX}."
    if [ "$USING_SELINUX" == "Y" ]                                      # If SELinux is Activated
        then write_log "Disabling SELinux while the update is running." # Advise user
             setenforce 0 >> $LOG 2>&1                                  # Disable SELinux
             getenforce   >> $LOG 2>&1                                  # Display SELinux Status
    fi

    # Run the OS Update
    if [ $OSVERSION -lt 5 ]  ; then run_up2date ; else run_yum ; fi     # Update the Server
    rc=$? ; export rc                                                   # Save Return Code

    # Reactivate SELINUX if it was de-activated at the beginning
    if [ "$USING_SELINUX" == "Y" ]
        then write_log "Re-enabling SELinux ... "
             setenforce 1 >> $LOG 2>&1
             getenforce >> $LOG 2>&1
    fi

    # Update and close Logs
    sadm_stop $rc                                                       # End Process with exit Code
    exit $rc                                                            # Exit script
