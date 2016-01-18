#!/usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   : Jacques Duplessis
#   Synopsis :  1) Restart nmon daemon at midnight every day, so that it finish at 23:55
#               2) Clean up of old nmon files
#   Version  :  1.0
#   Date     :  August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) sys_nmon_recycle.sh 1.0 2013/08/02
# --------------------------------------------------------------------------------------------------
# Modified in March 2015 - Add clean up Process - Jacques Duplessis
# --------------------------------------------------------------------------------------------------
#set +x
#
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





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
NMON_2_KEEP=90                                  ; export NMON_2_KEEP    # NB nmon log 2 Keep

    
# --------------------------------------------------------------------------------------------------
#     - Set command path used in the script (Some path are different on some RHEL Version)
#     - Check if Input exist and is readable
# --------------------------------------------------------------------------------------------------
#
pre_validation()
{
    sadm_logger "Verifying if nmon is accessible"
    NMON=`which nmon >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then NMON=`which nmon`
        else sadm_logger "Error : The command 'nmon' was not found" ; return 1
    fi
    export NMON
    sadm_logger "Yes it is at $NMON"
}



# --------------------------------------------------------------------------------------------------
#    - Stop / Start nmon Daemon once a day at 23:55
# --------------------------------------------------------------------------------------------------
#
restart_nmon()
{
 
    # Display Current Running Number of nmon process
    sadm_logger " "
    nmon_count=`ps -ef | grep 'nmon' | grep 's300' | grep -v grep | wc -l`
    sadm_logger "There are $nmon_count nmon process actually running"
    ps -ef | grep 'nmon' | grep 's300' | grep -v grep | nl


    # Kill Process to start the new day (New nmon File)
    if [ $nmon_count -gt 0 ]
       then NMON_ID=`ps -ef | grep -v grep | grep "$NMON" | grep 's300' | awk '{ print $2 }'`
            sadm_logger "Killing Process $NMON_ID"
            ps -ef | grep -v grep | grep "$NMON" | grep 's300' | awk '{ print $2 }' | xargs kill -9
    fi

    # Start new Process
    sadm_logger " "
    sadm_logger "Starting nmon daemon ..."
    sadm_logger "$NMON -s300 -c288 -t -m $SADM_NMON_DIR -f "
    $NMON -s300 -c288 -t -m $SADM_NMON_DIR -f  >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_logger "Error while starting - Not Started !" ; return 1 ; fi

    # Display Process Info after starting nmon
    nmon_count=`ps -ef | grep $NMON | grep -v grep | wc -l`
    sadm_logger " "
    sadm_logger "The number of nmon process running after restarting it is : $nmon_count"
    ps -ef | grep $NMON | grep -v grep | nl

    return 0   
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    pre_validation                                                      # nmon Cmd present ?
    if [ $? -ne 0 ]                                                     # If not there
        then sadm_stop 1                                                # Upd. RC & Trim Log & Set RC
             exit 1                                                     # Abort Program
    fi                             
    restart_nmon                                                        # nmon not running start it
    SADM_EXIT_CODE=$?                                                     # Recuperate error code
    if [ $SADM_EXIT_CODE -ne 0 ]                                          # if error occured
        then sadm_logger "Problem starting nmon"                          # Advise User
    fi     
    
    # Keep on 90 Days of LOG Accessible
    sadm_logger " "
    sadm_logger "List of nmon file that will be deleted"
    sadm_logger "find $SADM_NMON_DIR -mtime +${NMON_2_KEEP} -type f -name *.nmon -exec ls -l {} \;" 
    find $SADM_NMON_DIR -mtime +${NMON_2_KEEP} -type f -name "*.nmon" -exec ls -l {} \; >> $SADM_LOG 2>&1
    find $SADM_NMON_DIR -mtime +${NMON_2_KEEP} -type f -name "*.nmon" -exec rm {} \; >/dev/null 2>&1

    sadm_stop $SADM_EXIT_CODE                                             # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                  # Exit Glob. Err.Code (0/1)


#
