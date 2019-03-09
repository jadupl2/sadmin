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
# 2018_03_27 V1.1 Initial Version - Make sure python 3 is installed and then execute sadm_setup.py
# 2018_04_03 V1.4 Bug Fixes and add detail to log for support purpose 
# 2018_05_01 V1.5 Show Full O/S Version in Log
# 2018_06_29 V1.6 Change Log File Name & Appearance Changes 
# 2019_01_27 V1.7 Change: v1.7 Make sure /etc/hosts contains the IP and FQDN of current server
# 2019_01_28 V1.8 Fix: v1.8 Fix crash problem related to EPEL repository installation.
# 2019_01_28 Fix: v1.9 problem installing EPEL Repo on CentOS/RHEL. 
#@2019_03_01 Updated: v2.0 Updated for RHEL/CensOS 8 
#@2019_03_04 Updated: v2.1 More changes for RHEL/CensOS 8 
#@2019_03_08 Updated: v2.2 Always Add EPEL repository When installing RHEL or CENTOS
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x


#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
SADM_VER='2.2'                              ; export SADM_VER           # Your Script Version
SADM_PN=${0##*/}                            ; export SADM_PN            # Script name
SADM_HOSTNAME=`hostname -s`                 ; export SADM_HOSTNAME      # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`  ; export SADM_INST          # Script name without ext.
SADM_TPID="$$"                              ; export SADM_TPID          # Script PID
SADM_EXIT_CODE=0                            ; export SADM_EXIT_CODE     # Script Exit Return Code
SCRIPT="$(dirname "$0")/bin/sadm_setup.py"  ; export SCRIPT             # Main Setup SCRIPT Next
SLOGDIR="$(dirname "$0")/log"               ; export SLOGDIR            # Log Directory
if [ ! -d ${SLOGDIR} ] ; then mkdir $SLOGDIR ; fi                       # If Don't exist create dir
SLOG="${SLOGDIR}/sadm_pre_setup.log"        ; export SLOG               # Script Log Name
SADM_OSNAME=""                              ; export SADM_OSNAME        # Operating System Name 
SADM_OSVERSION=""                           ; export SADM_OSVERSION     # O/S System Major Version#

# Screen related variable
clr=$(tput clear)                               ; export clr            # clear the screen
blink=$(tput blink)                             ; export blink          # turn blinking on
reset=$(tput sgr0)                              ; export reset          # Screen Reset Attribute

# Foreground Color
black=$(tput setaf 0)                           ; export black          # Black color
red=$(tput setaf 1)                             ; export red            # Red color
green=$(tput setaf 2)                           ; export green          # Green color
yellow=$(tput setaf 3)                          ; export yellow         # Yellow color
blue=$(tput setaf 4)                            ; export blue           # Blue color
magenta=$(tput setaf 5)                         ; export magenta        # Magenta color
cyan=$(tput setaf 6)                            ; export cyan           # Cyan color
white=$(tput setaf 7)                           ; export white          # White color


#===================================================================================================
#  Install EPEL Repository for Redhat / CentOS
#===================================================================================================
add_epel_repo()
{


    # Add EPEL Repository on Redhat / CentOS 6 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 6 ] 
        then echo "Adding CentOS/Redhat V6 EPEL repository (Disabled by default) ..." |tee -a $SLOG
             yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm >>$SLOG 2>&1
             if [ $? -ne 0 ]
                then echo "${yellow}Couldn't add EPEL repository for version $SADM_OSVERSION${reset}" | tee -a $SLOG
                     return 1
             fi 
             echo "${yellow}Disabling EPEL Repository, will activate it only when needed" |tee -a $SLOG
             yum-config-manager --disable epel >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "${yellow}Couldn't disable EPEL for version $SADM_OSVERSION${reset}" | tee -a $SLOG
                     return 1
             fi 
             return 0
    fi

    # Add EPEL Repository on Redhat / CentOS 7 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 7 ] 
        then echo "Adding CentOS/Redhat V7 EPEL repository (Disabled by default) ..." |tee -a $SLOG
             yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm >>$SLOG 2>&1
             if [ $? -ne 0 ]
                then echo "${yellow}Couldn't add EPEL repository for version $SADM_OSVERSION${reset}" | tee -a $SLOG
                     return 1
             fi 
             echo "Disabling EPEL Repository, will activate it only when needed" |tee -a $SLOG
             yum-config-manager --disable epel >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "${yellow}Couldn't disable EPEL for version $SADM_OSVERSION" | tee -a $SLOG
                     return 1
             fi 
             return 0
    fi

    # Add EPEL Repository on Redhat / CentOS 8 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 8 ] 
        then echo "Adding CentOS/Redhat V8 EPEL repository (Disabled by default) ..." |tee -a $SLOG
             yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >>$SLOG 2>&1
             if [ $? -ne 0 ]
                then echo "${yellow}Couldn't add EPEL repository for version $SADM_OSVERSION${reset}" | tee -a $SLOG
                     return 1
             fi 
             #
             rpm -qi dnf-utils >/dev/null 2>&1                          # Check if dns-utils is install
             if [ $? -ne 0 ] 
                then echo "Installing dnf-utils" | tee -a $LOG
                     dnf install -y dnf-utils >>$SLOG 2>&1
             fi
             #
             echo "Disabling EPEL Repository, will activate it only when needed" |tee -a $SLOG
             dnf config-manager --set-disabled epel >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "${yellow}Couldn't disable EPEL for version $SADM_OSVERSION${reset}" | tee -a $SLOG
                     return 1
             fi 
    fi
    return 0 
}

#===================================================================================================
# Check if python 3 is installed, if not install it 
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
                then yum --enablerepo=epel -y install python34 python34-setuptools python34-pip >>$SLOG 2>&1
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
check_hostname()
{
    echo -n "Making sure server is defined in /etc/hosts ... " | tee -a $SLOG

    # Get current IP Address of Server
    S_IPADDR=`ip addr show | grep global | head -1 | awk '{ print $2 }' |awk -F/ '{ print $1 }'`

    # Get Hostname as per name resolution of IP Address
    S_HOSTNAME=`host $S_IPADDR | head -1 | awk '{ print $NF }' | cut -d. -f1` 

    # Get Domain Name f IP Address
    S_DOMAIN=`host $S_IPADDR |head -1 |awk '{ print $NF }' |awk -F\. '{printf "%s.%s\n", $2, $3}'` 

    # Insert Server into /etc/hosts (If not already there)
    grep -Eiv "^${S_IPADDR}|${S_HOSTNAME}" /etc/hosts > /tmp/hosts.$$
    echo "$S_IPADDR    ${S_HOSTNAME}.${S_DOMAIN}    ${S_HOSTNAME}" >> /tmp/hosts.$$

    # Make Backup of /etc/hosts in /etc/host.org (If not already exist)
    if [ ! -f /etc/hosts.org ] ; then cp /etc/hosts /etc/hosts.org ; fi

    # Put New /etc/hosts in Place.
    cp /tmp/hosts.$$ /etc/hosts ; chmod 644 /etc/hosts ; chown root:root /etc/hosts 
    rm -f /tmp/hosts.$$
    
    echo " Done " | tee -a $SLOG
}

#===================================================================================================
#     Check if lsb_release command is installed, if not install it, if can't then abort script 
#===================================================================================================
check_lsb_release()
{
    if [ "$SADM_OSTYPE" != LINUX ] ; then return 1 ; fi                 # Only available on Linux

    # Make sure lsb_release is installed
    echo -n "Checking if 'lsb_release' is installed ... " | tee -a $SLOG
    which lsb_release > /dev/null 2>&1
    if [ $? -eq 0 ] ; then echo " Done " | tee -a $SLOG ; return ; fi 

    echo " " | tee -a $SLOG
    echo -n "Installing lsb_release ... " | tee -a $SLOG
    
    which yum >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then echo "Running 'yum -y install redhat-lsb-core' ..." >>$SLOG
             yum -y install redhat-lsb-core >>$SLOG  2>&1 
    fi 
    which dnf >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then echo "Running 'dnf-y install redhat-lsb-core' ..." >>$SLOG
             dnf-y install redhat-lsb-core >>$SLOG  2>&1
    fi 
    which apt-get >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then echo "Running 'apt-get update'" >> $SLOG
             apt-get update >/dev/null 2>&1
             echo "Running apt-get -y install lsb-release'" >>$SLOG
             apt-get -y install lsb-release >>$SLOG 2>&1
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
    return 0
}



#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
#
    # Only Supported on Linux for the moment
    SADM_OSTYPE=`uname -s | tr '[:lower:]' '[:upper:]'`                 # OS(AIX/LINUX/DARWIN/SUNOS)
    if [ "$SADM_OSTYPE" != LINUX ] 
        then echo "SADMIN is only supported on Linux for the moment ($SADM_OSNAME)" | tee -a $SLOG
             exit 1
    fi

    # Script must be run by root
    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then echo "Script can only be run user 'root'" | tee -a $SLOG   # Advise User should be root
             echo "Process aborted"  | tee -a $SLOG                     # Abort advise message
             exit 1                                                     # Exit To O/S
    fi

    tput clear 
    cat << EOF
     ____    _    ____  __  __ ___ _   _ 
    / ___|  / \  |  _ \|  \/  |_ _| \ | |
    \___ \ / _ \ | | | | |\/| || ||  \| |
     ___) / ___ \| |_| | |  | || || |\  |
    |____/_/   \_\____/|_|  |_|___|_| \_|
                                     
EOF

    # Display OS Name and Version
    echo " " > $SLOG                                                    # Init the Log File
    echo "SADMIN Pre-installation verification v${SADM_VER}" | tee -a $SLOG
    echo "---------------------------------------------------------------------------"| tee -a $SLOG
    #echo "SLOGDIR = $SLOGDIR & Log file is $SLOG" | tee -a $SLOG 

    # Make sure lsb_release exist, if not install it
    if [ "$SADM_OSTYPE" == LINUX ]                                      # Under Linux install lsb_release
        then check_lsb_release                                          # lsb_release must be found
             if [ $? -ne 0 ]                                            # Error installing lsb_release
                then echo "Was unable to install lsb_release"           # Inform user
                     exit 1                                             # Abort setup
             fi
    fi 


    # Get O/S Name and O/S Major Number
    SADM_OSNAME=`lsb_release -si | tr '[:lower:]' '[:upper:]'`          # O/S Name (REDHAT,UBUNTU,CENTOS,...)
    if [ "$SADM_OSNAME" = "REDHATENTERPRISESERVER" ] ; then SADM_OSNAME="REDHAT" ; fi
    if [ "$SADM_OSNAME" = "REDHATENTERPRISEAS" ]     ; then SADM_OSNAME="REDHAT" ; fi
    if [ "$SADM_OSNAME" = "REDHATENTERPRISE" ]       ; then SADM_OSNAME="REDHAT" ; fi
    SADM_OSFULLVER=`lsb_release -sr| tr -d ' '`                         # Get O/S Full Version No.
    SADM_OSVERSION=`lsb_release -sr |awk -F. '{ print $1 }'| tr -d ' '` # Use lsb_release 2 Get Ver
    echo "Your System is running $SADM_OSNAME Version $SADM_OSVERSION ..." >> $SLOG
    

    # # Support only Redhat/CentOS or Debian/Ubuntu
    # if [ "${SADM_OSNAME}" == "REDHAT" ] || [ "${SADM_OSNAME}" == "CENTOS" ]
    #     then if [ "${SADM_OSVERSION}" -lt "6" ]
    #             then echo "O/S Version ${SADM_OSNAME} too low - upport Version 6 and up" | tee -a $SLOG
    #                  exit 1
    #          fi
    # fi 
    # if [ "$SADM_OSNAME" == "DEBIAN" ] || [ "$SADM_OSNAME" == "UBUNTU" ] 
    #     then if [ "${SADM_OSVERSION}" -lt "8" ]
    #             then echo "O/S Version ${SADM_OSNAME} too low - Support Version 8 and up" | tee -a $SLOG
    #                  exit 1
    #          fi
    # fi 

    # Add EPEL Repository on RedHat, CentOS 
    if [ "${SADM_OSNAME}" == "REDHAT" ] || [ "${SADM_OSNAME}" == "CENTOS" ]
        then add_epel_repo
    fi 


    # Make sure python3 is on the system, if not install it
    check_python                                                        # python3 must be found

    # Check name resolution for this host
    check_hostname

    # Ok Python3 and lsb_release command are installed - Proceeed with Main Setup Script
    echo "We will now proceed with main setup program ($SCRIPT)" >> $SLOG 
    echo "All Verifications Pass ..."
    echo -e "\n" | tee -a $SLOG                                         # Blank Lines
    $SCRIPT 

