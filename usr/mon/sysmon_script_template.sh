#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Title       :   sysm_script.sh
#   Synopsis    :   Script executed by SADM System Monitor (sadm_sysmon.pl)
#   Version     :   1.0
#   Date        :   May  2018
#   Requires    :   sh 
#   Description :   This is a script template that can be called by sadm_sysmon.pl,
#                   to do whatever your want to check and.or react to something not running ...
#
#                   It is recommended that the execution time a this type of script MUST be kept
#                   to a minimal time since sadm_sysmon.pl is scheduled to run at regular interval.
#
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_05_10 JDuplessis V1.0 - Initial Version
#   v1.0 Initail Version - Script example that we can run from sadm system monitor (sadm_sysmon.pl)
# --------------------------------------------------------------------------------------------------
trap 'exit 0' 2                                                         # INTERCEPT The Control-C
#set -x
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"    ;exit 1 ;fi


#===================================================================================================
#                               Script environment variables
#===================================================================================================
HOSTNAME=`hostname -s`                      ; export HOSTNAME           # Hostname Without domain
OSNAME=`uname -s | tr "[A-Z]" "[a-z]"`      ; export OSNAME             # (linux or aix)
PN=${0##*/}                                 ; export PN                 # Script name
VER='1.0'                                   ; export VER                # Script Version No.
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
    if [ -r $FILENAME ] 
        then echo -e "\nFile $FILENAME exist"
             RC=0
        else echo -e "\nFile $FILENAME doesn't exist"
             RC=1
    fi
    #
    return $RC                                                          # Return Status to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    main_process                                                        # Call Main Process Function
    SADM_EXIT_CODE=$?                                                   # Save Return Code 
    echo -e "\nReturn code : $RC"                                       # Print Script return code
    echo -e "End of script $PN on ${HOSTNAME} `date`\n${DASH}\n"        # Print Script Footer
    exit $SADM_EXIT_CODE                                                # Exit With Return Code                                             # Exit With Global Error code (0/1)
