#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   srestart_atd.sh
#   Synopsis    :   Script executed to restart the 'at' service (called by SADMIN System Monitor)
#   Version     :   1.0
#   Date        :   July 2018
#   Requires    :   sh 
#   Description :   This is a script that will be called by the SADMIN System Monitor, when the 
#                   service isn't running. This script will attempt to restart it, by calling the 
#                   SystemV (service command) or SystemD (systemctl command). The Status code
#                   returned will be zero (0) if it succeeded and one (1) if it didn't.
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_07_11    v1.0 - Initial Version
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
VER='1.0'                                   ; export VER                # Script Version No.
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
    echo -e "\n\n${DASH}\nStarting script $PN on ${HOSTNAME} `date`"    # Print Script Header

    # Test if running on Systemd system
    which systemctl >/dev/null 2>&1                                     # Cmd systemctl on system ?
    if [ $? -eq 0 ] ; then SYSTEMD="Y" ; else SYSTEMD="N" ; fi          # Use Systemd or SysV Init
    if [ $DEBUG_LEVEL -gt 4 ] ;then echo "System use Systemd ? $SYSTEMD" ; fi

    if [ "$SYSTEMD" == "Y" ]                                            # If System using SystemD
        then systemctl restart $SRVNAME                                 # Restart using systemctl
             RC=$?                                                      # Save Return Code
        else service $SRVNAME restart                                   # Restart using service cmd
             RC=$?                                                      # Save Return Code
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
