#! /usr/bin/env bash
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
# 2018_04_03 JDuplessis
#   V1.4 Bug Fixes and add detail to log for support purpose 
# 2018_05_01 JDuplessis
#   V1.5 Show Full O/S Version in Log
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x


#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                              ; export DEBUG_LEVEL         # 0=NoDebug Higher=+Verbose
SADM_VER='1.5'                             ; export SADM_VER            # Your Script Version
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SCRIPT="$(dirname "$0")/bin/sadm_setup.py" ; export SCRIPT              # Main Setup SCRIPT Next
SLOGDIR="$(dirname "$0")/log"              ; export SLOGDIR             # Log Directory
if [ ! -d ${SLOGDIR} ] ; then mkdir $SLOGDIR ; fi                       # If Don't exist create dir
SLOG="${SLOGDIR}/sadm_setup.log"           ; export SLOG                # Script Log Name


#===================================================================================================
#                           Install EPEL Repository for Redhat / CentOS
#===================================================================================================
add_epel_repo()
{

    # Add EPEL Repository on Redhat / CentOS 6 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 6 ] 
        then echo "Adding CentOS/Redhat V6 EPEL repository (Disabled) ..." >> $SLOG
             rpm -Uvh http://fedora-epel.mirror.iweb.com/epel-release-latest-6.noarch.rpm >>$SLOG 2>&1
    fi

    # Add EPEL Repository on Redhat / CentOS 7 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 7 ] 
        then echo "Adding CentOS/Redhat V7 EPEL repository (Disabled) ..." >> $SLOG
             rpm -Uvh http://fedora-epel.mirror.iweb.com/epel-release-latest-7.noarch.rpm >>$SLOG 2>&1
    fi

    # Disable the EPEL Repository, Will Activate when needed only.
    echo "Disabling EPEL Repository, will activate it only when needed" >> $SLOG
    yum-config-manager --disable epel >/dev/null 2>&1
}

#===================================================================================================
#                      Check if python 3 is installed, if not install it 
#===================================================================================================
check_python()
{
    # Check if python3 is installed 
    echo -n "Checking if 'python3' is installed ... " | tee -a $SLOG
    which python3 >/dev/null 2>&1
    if [ $? -ne 0 ] 
        then echo -n "Installing python3 ... " | tee -a $SLOG
             which yum >/dev/null 2>&1
             if [ $? -eq 0 ] 
                then add_epel_repo
                     yum --enablerepo=epel -y install python34 python34-setuptools python34-pip >>$SLOG 2>&1
             fi 
             which apt-get >/dev/null 2>&1
             if [ $? -eq 0 ] 
                then echo "Running 'apt-get update'" >> $SLOG
                     apt-get update >> $SLOG 2>&1
                     echo "Running apt-get -y install python3'" >>$SLOG
                     apt-get -y install python3 >>$SLOG 2>&1
             fi 
    fi 
    
    # python3 should now be installed, if not then abort installation
    which python3 > /dev/null 2>&1
    if [ $? -ne 0 ]
        then echo " " | tee -a $SLOG
             echo "----------" | tee -a $SLOG
             echo "We are having problem installing python3" | tee -a $SLOG
             echo "Please install python3 package" | tee -a $SLOG
             echo "Then run this script again." | tee -a $SLOG 
             echo "----------" | tee -a $SLOG
             exit 1
    fi

    echo " Done " | tee -a $SLOG
    return 0                                                            # Return No Error to Caller
}


#===================================================================================================
#     Check if lsb_release command is installed, if not install it, if can't then abort script 
#===================================================================================================
check_lsb_release()
{

    # Make sure lsb_release is installed
    echo -n "Checking if 'lsb_release' is installed ... " | tee -a $SLOG
    which lsb_release > /dev/null 2>&1
    if [ $? -ne 0 ] 
        then echo " " | tee -a $SLOG
             echo -n "Installing lsb_release ... " | tee -a $SLOG
             which yum >/dev/null 2>&1
             if [ $? -eq 0 ] 
                then echo "Running 'yum -y install redhat-lsb-core' ..." >>$SLOG
                     yum -y install redhat-lsb-core >>$SLOG  2>&1 ; fi 
             which apt-get >/dev/null 2>&1
             if [ $? -eq 0 ] 
                then echo "Running 'apt-get update'" >> $SLOG
                     apt-get update >/dev/null 2>&1
                     echo "Running apt-get -y install lsb-release'" >>$SLOG
                     apt-get -y install lsb-release >>$SLOG 2>&1
             fi 
    fi 
    
    # lsb_release should now be installed, if not then abort installation
    which lsb_release > /dev/null 2>&1
    if [ $? -ne 0 ]
        then echo " " | tee -a $SLOG
             echo "----------" | tee -a $SLOG
             echo "We are having problem installing lsb_release command" | tee -a $SLOG
             echo "Please install lsb-release(deb) or redhat-lsb-core(rpm) package" | tee -a $SLOG
             echo "Then run this script again." | tee -a $SLOG 
             echo "----------" | tee -a $SLOG
             exit 1
    fi
    echo " Done " | tee -a $SLOG
}



#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
#

    # Display OS Name and Version
    tput clear 
    echo " " > $SLOG                                                        # Init the Log File
    echo "SADMIN Pre-Installation Verification Version $SADM_VER" | tee -a $SLOG
    echo "---------------------------------------------------------------------------"| tee -a $SLOG
    #echo "SLOGDIR = $SLOGDIR & Log file is $SLOG" | tee -a $SLOG 

    # Only Supported on Linux
    SADM_OSTYPE=`uname -s | tr '[:lower:]' '[:upper:]'`                     # OS(AIX/LINUX/DARWIN/SUNOS)           
    if [ "$SADM_OSTYPE" != LINUX ] 
        then echo "SADMIN Tools only supported on Linux (Not on $SADM_OSNAME)" | tee -a $SLOG
             exit 1
    fi

    # Make sure lsb_release exist, if not install it
    check_lsb_release                                                   # lsb_release must be found

    # Get O/S Name (in Uppercave) and O/S Major Number 
    SADM_OSNAME=`lsb_release -si | tr '[:lower:]' '[:upper:]'`
    if [ "$SADM_OSNAME" = "REDHATENTERPRISESERVER" ] ; then SADM_OSNAME="REDHAT" ; fi
    if [ "$SADM_OSNAME" = "REDHATENTERPRISEAS" ]     ; then SADM_OSNAME="REDHAT" ; fi
    SADM_OSFULLVER=`lsb_release -sr| tr -d ' '`                         # Get O/S Full Version No.
    SADM_OSVERSION=`lsb_release -sr |awk -F. '{ print $1 }'| tr -d ' '` # Use lsb_release 2 Get Ver
    echo "Your System is running $SADM_OSNAME Version $SADM_OSNAME ..." >> $SLOG
    
    # Script must be run by root
    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then echo "Script can only be run user 'root'" | tee -a $SLOG   # Advise User should be root
             echo "Process aborted"  | tee -a $SLOG                     # Abort advise message
             exit 1                                                     # Exit To O/S
    fi

    # Support only Redhat/CentOS or Debian/Ubuntu
    if [ "${SADM_OSNAME}" == "REDHAT" ] || [ "${SADM_OSNAME}" == "CENTOS" ]
        then if [ "${SADM_OSVERSION}" -lt "6" ]
                then echo "O/S Version ${SADM_OSNAME} too low - Support Version 6 and up" | tee -a $SLOG
                     exit 1
             fi
    fi 
    if [ "$SADM_OSNAME" == "DEBIAN" ] || [ "$SADM_OSNAME" == "UBUNTU" ] 
        then if [ "${SADM_OSVERSION}" -lt "8" ]
                then echo "O/S Version ${SADM_OSNAME} too low - Support Version 8 and up" | tee -a $SLOG
                     exit 1
             fi
    fi 

    # Make sure python3 exist, if not install it
    check_python                                                        # python3 must be found

    # Ok Python3 and lsb_release command are installed - Proceeed with Main Setup Script
    echo "We will now proceed with main setup program ($SCRIPT)" >> $SLOG 
    echo "All Verifications Pass ..."
    echo -e "\n" | tee -a $SLOG                                         # Blank Lines
    $SCRIPT 

