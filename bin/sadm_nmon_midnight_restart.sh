#!/usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Title    : sadm_nmon_midnight_restart.sh 
#   Author   : Jacques Duplessis 
#   Synopsis :  1) Restart nmon daemon at midnight every day, so that it finish at 23:55
#               MAKE SURE THIS SCRIPT RUN JUST BEFORE midnight
#   Version  :  1.0
#   Date     :  August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) sys_nmon_recycle.sh 1.0 2013/08/02
# --------------------------------------------------------------------------------------------------
# 1.7   March 2015
#       Add clean up Process - Jacques Duplessis
# --------------------------------------------------------------------------------------------------
# 1.8   Nov 2016
#       Enhance checking for nmon existence and add some message for user.
#       ReTested in AIX
# --------------------------------------------------------------------------------------------------
# 1.9   Dec 2016
#       Correction to make it work on AIX 7.x - (topas_nmon now)
#       ReTested in AIX - Nmon Now part of Aix (as of 6.1)
# --------------------------------------------------------------------------------------------------
# 2.0   Jan 2017 - Cosmetic Message change
#
# 2017_12_30 JDuplessis
#   V2.1 Display Message when run on macOS - Script not supported - 'nmon' not available on OSX
# 2018_01_06 JDuplessis
#   V2.1a Minor Esthetics Changes
#
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
SADM_VER='2.1a'                            ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     # sadm std Lib

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





# --------------------------------------------------------------------------------------------------
#     - Set command path used of nmon executable in the script 
#           (Some path are different on some RHEL Version)
#     - Check if Input exist and is readable
# --------------------------------------------------------------------------------------------------
#
pre_validation()
{
    sadm_writelog "Verifying if nmon is accessible"
    
    # Check if the nmon program can be found
    NMON=`which nmon >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then NMON=`which nmon`
             export NMON
             sadm_writelog "Yes it's at $NMON"
        else sadm_writelog "[ERROR] The command 'nmon' was not found"
             sadm_writelog "        I will not be able to restart nmon daemon." 
             return 1
    fi

    # Check if nmon has execute permission
    if [ ! -x $NMON ]
       then sadm_writelog "The nmon executable ($NMON) doesn't have execution permission"
            return 1
    fi
    return 0
}



# --------------------------------------------------------------------------------------------------
#    - Stop / Start nmon Daemon once a day at 23:55
# --------------------------------------------------------------------------------------------------
#
restart_nmon()
{
    if [ $(sadm_get_ostype) = "AIX" ]
        then ${SADM_WHICH} topas_nmon >/dev/null 2>&1
             if [ $? -eq 0 ]
                then TOPAS_NMON=`${SADM_WHICH} topas_nmon`
                     WSEARCH="${SADM_NMON}|${TOPAS_NMON}"
                else WSEARCH=$SADM_NMON
             fi
        else WSEARCH=$SADM_NMON
    fi
    
    
    # Display Current Running Number of nmon process
    sadm_writelog " "
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process actually running"
    ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG


    # Kill Process to start the new day (New nmon File)
    sadm_writelog " "
    if [ $nmon_count -gt 0 ]
       then sadm_writelog "Killing nmon Process"
            #ps -ef | grep nmon |grep -v grep |grep s300 | tee -a $SADM_LOG 2>&1
            ps -ef | grep nmon |grep -v grep |grep s300 | awk '{ print $2 }' | xargs kill -9
    fi

    # Display Current Running Number of nmon process
    sadm_writelog " "
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process running after killing it"
    ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG

    # Start new Process
    sadm_writelog " "
    sadm_writelog "Restarting nmon daemon ..."
    sadm_writelog "$SADM_NMON -s300 -c288 -t -m $SADM_NMON_DIR -f "
    $SADM_NMON -s300 -c288 -t -m $SADM_NMON_DIR -f  >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_writelog "Error while starting nmon - Not Started !" ; return 1 ; fi

    # Display Process Info after starting nmon
    sadm_writelog " "
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process running after restarting it"
    ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG
    return 0   
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    if [ "$(sadm_get_ostype)" = "DARWIN" ]                              # No nmon on OSX
        then sadm_writelog "Script not supported on MacOS - Command 'nmon' not available"
             sadm_stop 0                                                # Clean Stop 
             exit 0                                                     # Exit with no error
    fi
    
    pre_validation                                                      # Is nmon executable present
    if [ $? -ne 0 ]                                                     # If not there
        then sadm_stop 1                                                # Upd. RC/Trim Log/Set RC
             exit 1                                                     # Exit Program
    fi                             

    restart_nmon                                                        # nmon not running start it
    SADM_EXIT_CODE=$?                                                   # Recuperate error code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # if error occured
        then sadm_writelog "Problem starting nmon"                      # Advise User
    fi     

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC/Trim Log/Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
