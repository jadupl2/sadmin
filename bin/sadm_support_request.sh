#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_support_request.sh
#   Synopsis    :   Run this script to create a log file used to debug installation problem
#   Version     :   1.0
#   Date        :   30 March 2018 
#   Requires    :   sh 
#   Description :   Collect logs, and files modified during installation for debugging.
#                   If problem detectied during installation, run this script an send the
#                   resulting log (setup_result.log) to support at support@sadmin.ca
#
#   This code was originally written by Jacques Duplessis <duplessis.jacques@gmail.com>,
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_03_30 JDuplessis
#   V1.0 Initial Version
# 2018_04_04 JDuplessis
#   V1.1 Bug Fixes
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x

#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
SADM_VER='1.1'                              ; export SADM_VER           # Your Script Version
SADM_PN=${0##*/}                            ; export SADM_PN            # Script name
SADM_HOSTNAME=`hostname -s`                 ; export SADM_HOSTNAME      # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`  ; export SADM_INST          # Script name without ext.
SADM_TPID="$$"                              ; export SADM_TPID          # Script PID
SADM_EXIT_CODE=0                            ; export SADM_EXIT_CODE     # Script Exit Return Code

# SADMIN Base Dir. 
SDIR=`grep "^SADMIN=" /etc/profile.d/sadmin.sh| awk -F= '{ print $2 }'` ; export SDIR 
SLOG="${SDIR}/log/${SADM_INST}.log"         ; export SLOG               # Script resulting log

# Display OS Name and Version
tput clear 
#echo "---------------------------------------------------------------------------"| tee -a $SLOG
#echo "SADMIN $SADM_PN - Version $SADM_VER" | tee -a $SLOG


# Only Supported on Linux
SADM_OSTYPE=`uname -s | tr '[:lower:]' '[:upper:]'`                     # OS(AIX/LINUX/DARWIN/SUNOS)           
if [ "$SADM_OSTYPE" != LINUX ] 
    then echo "SADMIN Tools only supported on Linux (Not on $SADM_OSNAME)"
         exit 1
fi

# Get O/S Name (in Uppercave) and O/S Major Number 
SADM_OSNAME=`lsb_release -si | tr '[:lower:]' '[:upper:]'`
if [ "$SADM_OSNAME" = "REDHATENTERPRISESERVER" ] ; then SADM_OSNAME="REDHAT" ; fi
if [ "$SADM_OSNAME" = "REDHATENTERPRISEAS" ]     ; then SADM_OSNAME="REDHAT" ; fi
SADM_OSVERSION=`lsb_release -sr | awk -F. '{ print $1 }'| tr -d ' '`    # Use lsb_release to Get Ver


#===================================================================================================
#                              Print File received as parameter
#===================================================================================================
print_file()
{
    wfile=$1
    if [ ! -r $wfile ] ; then return 1 ; fi 

    echo "Adding $wfile to $SLOG ..."
    echo " " >> $SLOG
    echo " " >> $SLOG
    echo "---------------------------------------------------------------------------" >>$SLOG
    echo "Content of $wfile" >> $SLOG
    echo "--------------------------------------------------------" >> $SLOG
    cat $wfile >> $SLOG
    return 0                                                            # Return No Error to Caller
}

#===================================================================================================
#                                       Main Process 
#===================================================================================================
main_process()
{
    print_file "$SDIR/setup/log/sadm_setup.log"
    print_file "/etc/profile.d/sadmin.sh" 
    print_file "$SDIR/cfg/sadmin.cfg"
    print_file "/etc/sudoers.d/033_sadmin-nopasswd"
    print_file "/etc/cron.d/sadm_server"
    print_file "/etc/cron.d/sadm_client"
    print_file "/etc/selinux/config"
    print_file "/etc/hosts"
    print_file "/etc/httpd/conf.d/sadmin.conf"
    print_file "$SDIR/log/sadmin_error.log"
    return 0
}



#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
#
    if [ -f "$SLOG" ] ; then rm -f $SLOG >/dev/null 2>&1 ; fi           # Remove log if exist
    echo "---------------------------------------------------------------------------"| tee -a $SLOG
    echo "SADMIN $SADM_PN - Version $SADM_VER"                                        | tee -a $SLOG
    echo "`date`"                                                                     | tee -a $SLOG
    echo "---------------------------------------------------------------------------"| tee -a $SLOG
    echo "System is running $SADM_OSNAME Ver.$SADM_OSVERSION ..."                     | tee -a $SLOG
    echo "SADMIN Base Directory is $SDIR"                                             | tee -a $SLOG
    echo "---------------------------------------------------------------------------"| tee -a $SLOG
    echo " " >> $SLOG
    echo " " >> $SLOG


    # Script must be run by root
    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then echo "Script can only be run user 'root'"                  # Advise User should be root
             echo "Process aborted"                                     # Abort advise message
             exit 1                                                     # Exit To O/S
    fi

    # Support only Redhat/CentOS or Debian/Ubuntu
    if [ "${OS_NAME}" == "REDHAT" ] || [ "${OS_NAME}" == "CENTOS" ]
        then if [ "${SADM_OSVERSION}" -lt "6" ]
                then echo "Version of ${OS_NAME} is too low - Support Version 6 and up"| tee -a $SLOG
                     exit 1
             fi
    fi 
    if [ "${OS_NAME}" == "DEBIAN" ] || [ "${OS_NAME}" == "UBUNTU" ]
        then if [ "${SADM_OSVERSION}" -lt "8" ]
                then echo "Version of ${OS_NAME} is too low - Support Version 8 and up"| tee -a $SLOG
                     exit 1
             fi
    fi 

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    echo "---------------------------------------------------------------------------"| tee -a $SLOG
    echo -e "\nInformation collected\nSend the log ($SLOG) to support@sadmin.ca"
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)

