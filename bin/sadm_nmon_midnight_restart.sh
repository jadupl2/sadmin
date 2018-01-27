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
# 2018_01_26 JDuplessis
#   V2.2 Update SADM Env. - Minor Corrections 
# 2018_01_27 JDuplessis
#   V2.3 Add lot of comments - Code Review - List two newest nmon files (watch rotate)
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set +x



#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='2.2'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------





# --------------------------------------------------------------------------------------------------
#  Check availibility of 'nmon' and permmission
# --------------------------------------------------------------------------------------------------
#
nmon_exist()
{
    NMON=`which nmon >/dev/null 2>&1`                                   # Is nmon executable Avail.?
    if [ $? -eq 0 ]                                                     # If it is, Save Full Path 
        then NMON=`which nmon`                                          # Save 'nmon' location 
             export NMON                                                # Make Avail. to SubProcess
             sadm_writelog "[OK] Yes, 'nmon' is available ($NMON)"      # Show user result OK
        else sadm_writelog "[ERROR] The command 'nmon' was not found"   # Show User Error
             return 1                                                   # Return error to caller
    fi
    if [ ! -x $NMON ]                                                   # Is nmon executable ?
       then sadm_writelog "'nmon' ($NMON) missing execution permission" # Advise User of error
            return 1                                                    # Return Error to Caller
    fi
    return 0                                                            # Return to Caller No Error
}



# --------------------------------------------------------------------------------------------------
#                       Stop / Start nmon Daemon once a day at midnight
# --------------------------------------------------------------------------------------------------
#
restart_nmon()
{
    # On Aix we might be running 'nmon' (older aix) or 'topas_nmon' (latest Aix)
    if [ $(sadm_get_ostype) = "AIX" ]                                   # If Server is running Aix
        then ${SADM_WHICH} topas_nmon >/dev/null 2>&1                   # Lastest Aix use topas_nmon
             if [ $? -eq 0 ]                                            # topas_nmon on system ?
                then TOPAS_NMON=`${SADM_WHICH} topas_nmon`              # Save Path to topas_nmon
                     WSEARCH="${SADM_NMON}|${TOPAS_NMON}"               # Will search for both nmon
                else WSEARCH=$SADM_NMON                                 # Will search for nmon only
                     TOPAS_NMON=""                                      # topas_nmon path not found
             fi
        else WSEARCH=$SADM_NMON                                         # Linux search for nmon only
    fi
    
    
    # Search Process Status (ps) and display number of nmon process running currently
    sadm_writelog " "                                                   # Blank line in log
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process actually running"  # Show Nb. nmon Running
    ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG


    # Kill Process to start the new day (New nmon File)
    sadm_writelog " "                                                   # Blank line in log
    if [ $nmon_count -gt 0 ]                                            # if running nmon process
       then sadm_writelog "Killing nmon Process"                        # SHow what were doing
            #ps -ef | grep nmon |grep -v grep |grep s300 | tee -a $SADM_LOG 2>&1
            ps -ef | grep nmon |grep -v grep |grep s300 | awk '{ print $2 }' | xargs kill -9
    fi

    # Search Process Status (ps) and display number of nmon process running currently
    sadm_writelog " "                                                   # Blank line in log
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process running after killing it"
    ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG

    # Start new Process
    sadm_writelog " "                                                   # Blank line in log
    sadm_writelog "Restarting nmon daemon ..."                          # SHow what were doing
    sadm_writelog "$SADM_NMON -f -s300 -c288 -t -m $SADM_NMON_DIR "
    $SADM_NMON -f -s300 -c288 -t -m $SADM_NMON_DIR >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_writelog "Error while starting nmon - Not Started !" ; return 1 ; fi

    # Search Process Status (ps) and display number of nmon process running currently
    sadm_writelog " "                                                   # Blank line in log
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s300 |wc -l |tr -d ' '`
    sadm_writelog "There is $nmon_count nmon process running after restarting it"
    ps -ef | grep -E "$WSEARCH" | grep 's300' | grep -v grep | nl | tee -a $SADM_LOG

    # Display Last two nmon files created
    sadm_writelog " "                                                   # Blank line in log
    sadm_writelog "Last two nmon files created"                         # SHow what were doing
    ls -ltr $SADM_NMON_DIR | tail -2 |  while read wline ; do sadm_writelog "$wline"; done
    sadm_writelog " "                                                   # Blank line in log

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
    
    nmon_exist                                                          # Is nmon executable present
    if [ $? -ne 0 ]                                                     # nmon not found 
        then sadm_stop 1                                                # Close sadm log & rch 
             exit 1                                                     # Exit Program
    fi                             

    restart_nmon                                                        # nmon not running start it
    SADM_EXIT_CODE=$?                                                   # Recuperate error code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # if error occured
        then sadm_writelog "Problem starting nmon"                      # Advise User
    fi     

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC/Trim Log/Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
