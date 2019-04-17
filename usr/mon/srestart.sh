#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   srestart.sh
#   Synopsis    :   Script executed to restart service(s) (called by SADMIN System Monitor)
#   Version     :   1.0
#   Date        :   July 2018
#   Requires    :   sh 
#   Description :   This is a script that is called by the SADMIN System Monitor, when a
#                   service isn't running. This script will attempt to restart it, by calling the 
#                   SystemV (service command) or SystemD (systemctl command). The Status code
#                   returned will be zero (0) if it succeeded and one (1) if it didn't.
#                   Parameter Receive is the service(s) to restart.
#                       If more than one service name is received, it must be comma seperated.
#                       Example: $SADMIN/usr/mon/srestart.sh "cron,crond"
#
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_07_11    v1.0 - Initial Version
# 2018_07_12    v1.1 - First Production release
#@2019_04_17 Fix: v1.2 Bug fix that prevent some services to restart and Log reformat.
#
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
VER='1.2'                                   ; export VER                # Script Version No.
INST=`echo "$PN" | awk -F\. '{ print $1 }'` ; export INST               # Script name without ext.
WDATE=`date "+%C%y.%m.%d;%H:%M:%S"`         ; export WDATE              # Today Date and Time
DASH=`printf %80s |tr ' ' '-'`              ; export DASH               # 80 dashes
TMPFILE='/tmp/${PN}_$$.tmp'                 ; export TMPFILE            # Temp FileName
SYSTEMD="Y"                                 ; export SYSTEMD            # Using SystemD Default
DEBUG_LEVEL=5                               ; export DEBUG_LEVEL        # Level of Debug Info
SRVNAME="atd"                               ; export SRVNAME            # Service name to restart

#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    # Show Script Name, Version and starting Date/Time.
    printf "\n\n${DASH}\nStarting script $PN on ${HOSTNAME} `date`"     # Print Script Header
    if [ "$SRV_NAME" != "" ]                                            # Service Name to restart
       then printf "\nService name to restart : $SRV_NAME"              # SHow User we receive it
       else printf "\nNo Service name received - Script aborted"        # SHow User we abort
            return 1                                                    # Return Error to Caller    
    fi

    # Test if running on Systemd system
    which systemctl >/dev/null 2>&1                                     # Cmd systemctl on system ?
    if [ $? -eq 0 ]                                                     # If systemctl cmd is found
        then SYSTEMD="Y"                                                # Set systemd to Yes
             printf "\nSystem is using 'systemd'."                      # Show user using Systemd
        else SYSTEMD="N"                                                # Set Systemd to No
             printf "\nSystem is using 'SystemV Init'."                 # Show use using SystemV 
        fi                                                              # Use Systemd or SysV Init

    # Restart Each Service name received (Comma delimited)
    STARTED="N"                                                         # No Restart Worked Default 
    for i in $(echo $SRV_NAME | sed "s/,/ /g")                          # For every Serv. comma del.
        do     
        if [ "$SYSTEMD" = "Y" ]                                         # If System using SystemD
            then systemctl restart $i >/dev/null 2>&1                   # Restart using systemctl
                 if [ $? -eq 0 ]                                        # If restart worked
                    then STARTED="Y"                                    # At least one restart work
                         printf "\nService '$i' Started ..."            # Show user Service Started
                 fi                                                     
            else service $i restart >/dev/null 2>&1                     # Restart using service cmd
                 if [ $? -eq 0 ]                                        # If restart worked
                    then STARTED="Y"                                    # At least one restart work
                         printf "\nService '$i' Started ..."            # Show user Service Started
                 fi                                                     
        fi
        done
    
    # If One Service was Started successfully thenn Return 0 else 1.
    if [ "$STARTED" != "Y" ]                                            # At least 1 service started
        then RC=1                                                       # Error Return Code is 1
             printf "\n[ERROR] None of the service (${SRV_NAME}) is installed."
        else RC=0                                                       # OK Return Code is 0
    fi               # Set Return Code
    return $RC                                                          # Return Status to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    
    SRV_NAME=$1                                                         # Service Name to Restart
    main_process                                                        # Call Main Process Function
    SADM_EXIT_CODE=$?                                                   # Save Return Code 
    printf "\nReturn code : $RC"                                        # Print Script return code
    printf "\nEnd of script $PN on ${HOSTNAME} `date`\n${DASH}\n"       # Print Script Footer
    exit $SADM_EXIT_CODE                                                # Exit With Return Code 
