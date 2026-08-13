#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Title       :   stemplate.sh
#   Synopsis    :   Template of a script executed by SADM System Monitor (sadm_sysmon.pl)
#   Version     :   1.0
#   Date        :   May  2018
#   Requires    :   sh 
#   Description :   This is a script template that can be called by sadm_sysmon.pl,
#                   to do whatever your want to check and/or react to something not running ...
#
#                   It is recommended that the execution time a this type of script MUST be kept
#                   to a minimal time since sadm_sysmon.pl is scheduled to run at regular interval.
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_05_10 template v01.01.00 Example that we can run from sadm system monitor (sadm_sysmon.pl)
# 2018_07_21 template v01.01.01 Remove SADMIN Library dependance for Performance.
#@2019_04_19 template v01.02.01 Now can have customize error message use by System Monitor.
#@2026_08_13 template v01.02.02 Added more comments ,refine the code.
# --------------------------------------------------------------------------------------------------
trap 'exit 0' 2                                                         # INTERCEPT The Control-C
#set -x
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"    ;exit 1 ;fi




# Script environment variables
#===================================================================================================
HOSTNAME=`hostname -s`                                                  # Hostname Without domain
OSNAME=`uname -s | tr "[A-Z]" "[a-z]"`                                  # (linux or aix) lowercase
PN=${0##*/}                                                             # Script name
VER='1.2'                                                               # Script Version No.
INST=`echo "$PN" | awk -F\. '{ print $1 }'`                             # Script name without ext.
WDATE=`date "+%C%y.%m.%d;%H:%M:%S"`                                     # Today Date and Time
DASH=`printf %80s |tr ' ' '-'`                                          # 80 dashes
SADM_UMON_DIR="${SADMIN}/usr/mon"                                       # SysMon User Script Dir.





# S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    # Show Script Name, Version and starting Date/Time.
    echo -e "\n${DASH}" 
    echo "Starting script $PN on ${HOSTNAME} `date`"                    # Print Script Header

    # Example : As a place holder, for this template, check if file exist
    FILENAME="/tmp/${INST}.tmp"                                         # Example FileName to test 
    touch "$FILENAME"                                                   # Create/Update empty file
    echo -e "Test if file $FILENAME exist ..."                          # Inform user and log 
    if [ -r $FILENAME ]                                                 # If file readable
        then echo "File $FILENAME exist"                                # Inform user and log 
             ls -l $FILENAME | tee -a $SADM_LOG                         # Proove it exist
             RC=0                                                       # ReturnCode = 0
        else echo "File $FILENAME doesn't exist"                        # Inform user and log 
             RC=1                                                       # ReturnCode = 1
             EFILE="${SADM_UMON_DIR}/${INST}.txt"                       # Custom Error Message File
             EMSG="File $FILENAME doesn't exist - Running $PN."         # Error Message to file 
             echo "$EMSG" > $EFILE                                      # Message to Error Msg File
    fi

    return $RC                                                          # Return Status to Caller
}


# Script Start HERE
#===================================================================================================
    main_process                                                        # Call Main Process Function
    EXIT_CODE=$?                                                        # Save Return Code 
    echo -e "End of script $PN on ${HOSTNAME} - Exit Code : $EXIT_CODE - `date`\n" 
    exit $EXIT_CODE                                                     # Exit With Return Code                                             # Exit With Global Error code (0/1)
