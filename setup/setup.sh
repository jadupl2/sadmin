#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   setup.sh
#   Synopsis    :   Make sure Python3 is available before running sadm_setup.py (Main Setup Script)
#   Version     :   1.0
#   Date        :   26 March 2018 
#   Requires    :   sh 
#   Description :   Make sure python 3 is installed and then execute sadm_setup.py
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
# 2018_03_27 JDuplessis
#   V1.1 Initial Version - Make sure python 3 is installed and then execute sadm_setup.py
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x


#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                              ; export DEBUG_LEVEL         # 0=NoDebug Higher=+Verbose
SADM_VER='1.1'                             ; export SADM_VER            # Your Script Version
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SCRIPT="$(dirname "$0")/sadm_setup.py"     ; export SCRIPT              # Main Setup SCRIPT Next


# Only Supported on Linux
tput clear 
SADM_OSTYPE=`uname -s | tr '[:lower:]' '[:upper:]'`                     # OS(AIX/LINUX/DARWIN/SUNOS)           
if [ "$SADM_OSTYPE" != LINUX ] 
    then echo "SADMIN Tools only supported on Linux (Not on $SADM_OSNAME)"
         exit 1
fi

# Make sure lsb_release is installed
which lsb_release > /dev/null 2>&1
if [ $? -ne 0 ] 
    then echo "Installing lsb_release command ..."
         yum -y install redhat-lsb-core > /dev/null 2>&1
         apt-get update >/dev/null 2>&1
         apt-get -y install lsb-release >/dev/null 2>&1
         which lsb_release > /dev/null 2>&1
         if [ $? -ne 0 ]
            then echo "Please install lsb-release package, then run this script again."
                 exit 1
         fi
fi

# Get O/S Name (in Uppercave) and O/S Major Number 
SADM_OSNAME=`lsb_release -si | tr '[:lower:]' '[:upper:]'`
if [ "$SADM_OSNAME" = "REDHATENTERPRISESERVER" ] ; then SADM_OSNAME="REDHAT" ; fi
if [ "$SADM_OSNAME" = "REDHATENTERPRISEAS" ]     ; then SADM_OSNAME="REDHAT" ; fi
SADM_OSVERSION=`lsb_release -sr | awk -F. '{ print $1 }'| tr -d ' '`    # Use lsb_release to Get Ver

#===================================================================================================
#                           Install EPEL Repository for Redhat / CentOS
#===================================================================================================
add_epel_repo()
{

    # Add EPEL Repository on Redhat / CentOS 6 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 6 ] 
        then echo "Adding CentOS/Redhat V6 EPEL repository (Disabled) ..."
             rpm -Uvh http://fedora-epel.mirror.iweb.com/epel-release-latest-6.noarch.rpm >/dev/null 2>&1
    fi

    # Add EPEL Repository on Redhat / CentOS 7 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 7 ] 
        then echo "Adding CentOS/Redhat V7 EPEL repository (Disabled) ..."
             rpm -Uvh http://fedora-epel.mirror.iweb.com/epel-release-latest-7.noarch.rpm >/dev/null 2>&1
    fi

    # Disable the EPEL Repository (Will Activate when needed)
    yum-config-manager --disable epel

}

#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    echo "Main Process as started ($SADM_OSNAME Ver.$SADM_OSVERSION) ..."

    # Check if python3 is installed 
    while true : 
        do
        which python3 >/dev/null 2>&1
        if [ $? -ne 0 ] 
            then echo "Python 3 is not installed ..."
                 which apt-get >/dev/null 2>&1
                 if [ $? -eq 0 ] 
                    then echo "Installing python3 ..." 
                         apt-get update >/dev/null 2>&1
                         apt-get -y install python3 >/dev/null 2>&1
                    else add_epel_repo
                         echo "Installing python3 ..." 
                         which dnf >/dev/null 2>&1
                         if [ $? -eq 0 ] 
                            then dnf --enablerepo=epel -y install python34 python34-setuptools python34-pip > /dev/null 2>&1
                            else yum --enablerepo=epel -y install python34 python34-setuptools python34-pip > /dev/null 2>&1
                         fi
                 fi  
            else echo "Setup detected that python3 is installed ... Great !"
                 echo "Let's continue the setup ..."
                 break
        fi
        done

    # Run the Main Setup Script
    $SCRIPT 
    return 0                                                            # Return No Error to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)

su -c 'rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm'

Install a package from the EPEL repository
# yum --enablerepo=epel install zabbix


[EPEL] How to install Python 3.4 on CentOS 6 & 7
sudo yum install -y epel-release
sudo yum install -y python34

# Install pip3
sudo yum install -y python34-setuptools  # install easy_install-3.4
sudo easy_install-3.4 pip