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
#
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_05_10  v1.0  Initial Version - Script example that we can run from sadm system monitor 
#                   (sadm_sysmon.pl)
# 2018_07_21  v1.1  Remove SADM Library dependance for Performance.
# --------------------------------------------------------------------------------------------------
trap 'exit 0' 2                                                         # INTERCEPT The Control-C
#set -x


#===================================================================================================
#                               Script environment variables
#===================================================================================================
HOSTNAME=`hostname -s`                      ; export HOSTNAME           # Hostname Without domain
OSNAME=`uname -s | tr "[A-Z]" "[a-z]"`      ; export OSNAME             # (linux or aix)
PN=${0##*/}                                 ; export PN                 # Script name
VER='1.1'                                   ; export VER                # Script Version No.
INST=`echo "$PN" | awk -F\. '{ print $1 }'` ; export INST               # Script name without ext.
WDATE=`date "+%C%y.%m.%d;%H:%M:%S"`         ; export WDATE              # Today Date and Time
DASH=`printf %80s |tr ' ' '-'`              ; export DASH               # 80 dashes
FILENAME='/tmp/sysmon.tmp'                  ; export FILENAME           # FileName to test Existence



#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    # Show Script Name, Versrion and starting Date/Time.
    echo -e "\n\n${DASH}\nStarting script $PN on ${HOSTNAME} `date`"    # Print Script Header

    # Check if file exist
    echo -e "\nTest if file $FILENAME exist ..."
    if [ -r $FILENAME ] 
        then echo -e "File $FILENAME exist"
             RC=0
        else echo -e "File $FILENAME doesn't exist"
             RC=1
    fi
    #
    return $RC                                                          # Return Status to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    main_process                                                        # Call Main Process Function
    EXIT_CODE=$?                                                        # Save Return Code 
    echo -e "\nReturn code : $EXIT_CODE"                                # Print Script return code
    echo -e "End of script $PN on ${HOSTNAME} `date`\n${DASH}\n"        # Print Script Footer
    exit $EXIT_CODE                                                     # Exit With Return Code                                             # Exit With Global Error code (0/1)
