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
#   This code was originally written by Jacques Duplessis <jacques.duplessis@sadmin.ca>,
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - https://www.sadmin.ca
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
# 2019_03_01 Updated: v2.0 Bug Fix and updated for RHEL/CensOS 8 
# 2019_03_04 Updated: v2.1 More changes for RHEL/CensOS 8 
# 2019_03_08 Updated: v2.2 Add EPEL repository when installing RHEL or CENTOS 8
# 2019_03_17 Fix: v.2.3 Fix O/S detection for Redhat/CentOS
# 2019_03_21 Nolog: v.2.4 Minor typo change.
# 2019_04_19 Update: v2.5 Will now install python 3.6 on CentOS/RedHat 7 instead of 3.4
# 2019_04_19 Fix: v2.6 Solve problem with installing 'pymysql' module.
# 2019_04_19 Fix: v2.7 Solve problem with pip3 on Ubuntu.
# 2019_06_19 Update: v2.8 Update procedure to install CentOS/RHEL repository for version 5,6,7,8
#@2019_12_20 Update: v2.9 Better verification and installation of python3 (If needed)
#@2019_12_27 Update: v3.0 Add recommended EPEL Repos on CentOS/RHEL 8.
#
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x


#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
SADM_VER='3.0'                              ; export SADM_VER           # Your Script Version
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
SADM_OSFULLVER=""                           ; export SADM_OSFULLVER     # O/S Full Version number
SADM_OSTYPE=""                              ; export SADM_OSTYPE        # OS(AIX/LINUX/DARWIN/SUNOS) 
SADM_PACKTYPE=""                            ; export SADM_PACKTYPE      # Package Type use on System

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

    # Add EPEL Repository on Redhat / CentOS 5 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 5 ] 
        then if [ ! -r /etc/yum.repos.d/epel.repo ] 
                then echo "Adding CentOS/Redhat V5 EPEL repository ..." |tee -a $SLOG
                     EPEL="https://archives.fedoraproject.org/pub/archive/epel/epel-release-latest-5.noarch.rpm"
                     yum install -y $EPEL >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then echo "[Error] Adding EPEL repository." |tee -a $SLOG
                             return 1
                     fi
             fi 
             echo "Disabling EPEL Repository, will activate it only when needed" |tee -a $SLOG
             yum-config-manager --disable epel >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "Couldn't disable EPEL for version $SADM_OSVERSION" | tee -a $SLOG
                     return 1
             fi 
             return 0
    fi

    # Add EPEL Repository on Redhat / CentOS 6 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 6 ] 
        then if [ ! -r /etc/yum.repos.d/epel.repo ] 
                then echo "Adding CentOS/Redhat V6 EPEL repository ..." |tee -a $SLOG
                     EPEL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm"
                     yum install -y $EPEL >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then echo "[Error] Adding EPEL repository." |tee -a $SLOG
                             return 1
                     fi
             fi 
             echo "Disabling EPEL Repository, will activate it only when needed" |tee -a $SLOG
             yum-config-manager --disable epel >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "Couldn't disable EPEL for version $SADM_OSVERSION" | tee -a $SLOG
                     return 1
             fi 
             return 0
    fi

    # Add EPEL Repository on Redhat / CentOS 7 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 7 ] 
        then if [ ! -r /etc/yum.repos.d/epel.repo ] 
                then echo "Adding CentOS/Redhat V7 EPEL repository ..." |tee -a $SLOG
                     EPEL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
                     yum install -y $EPEL >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then echo "[Error] Adding EPEL repository." |tee -a $SLOG
                             return 1
                     fi
             fi 
             echo "Disabling EPEL Repository, will activate it only when needed" |tee -a $SLOG
             yum-config-manager --disable epel >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "Couldn't disable EPEL for version $SADM_OSVERSION" | tee -a $SLOG
                     return 1
             fi 
             return 0
    fi

    # Add EPEL Repository on Redhat / CentOS 8 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 8 ] 
        then echo "Adding CentOS/Redhat V8 EPEL repository (Disable by default) ..." |tee -a $SLOG
             EPEL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
             yum install -y $EPEL >>$SLOG 2>&1
             if [ $? -ne 0 ]
                then echo "[Error] Adding EPEL repository." |tee -a $SLOG
                     return 1
             fi
             #
             rpm -qi dnf-utils >/dev/null 2>&1                          # Check dns-utils is install
             if [ $? -ne 0 ] 
                then echo "Installing dnf-utils" | tee -a $LOG
                     dnf install -y dnf-utils >>$SLOG 2>&1
             fi
             #
             echo "Disabling EPEL Repository, will activate it only when needed" |tee -a $SLOG
             dnf config-manager --set-disabled epel >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "Couldn't disable EPEL for version $SADM_OSVERSION" | tee -a $SLOG
                     return 1
             fi 
             #
             # On RHEL 8 it is required to also enable the codeready-builder-for-rhel-8-*-rpms 
             # repository since EPEL packages may depend on packages from it:
             if [ "$SADM_OSNAME" = "REDHAT" ] 
                then echo "On RHEL 8, it's required to also enable codeready-builder ..." 
                     echo "Since EPEL packages may depend on packages from it." 
                     ARCH=$( /bin/arch )
                     subscription-manager repos --enable "codeready-builder-for-rhel-8-${ARCH}-rpms"
             fi
             #
             # On CentOS 8 it is recommended to also enable the PowerTools repository since EPEL 
             # packages may depend on packages from it:
             if [ "$SADM_OSNAME" = "CENTOS" ] 
                then echo "On CentOS 8, it is recommended to also enable the PowerTools ..."  
                     dnf config-manager --set-enabled PowerTools
             fi

    fi

    return 0 
}


#===================================================================================================
# Install python3 on system
#===================================================================================================
install_python3()
{
    echo "Installing python3." | tee -a $SLOG

    if [ "$SADM_PACKTYPE" = "rpm" ] 
        then echo "Running 'yum --enablerepo=epel -y install python36 python36-setuptools python36-pip'" |tee -a $SLOG
             yum --enablerepo=epel -y install python36 python36-setuptools python36-pip >>$SLOG 2>&1
    fi 
    if [ "$SADM_PACKTYPE" = "deb" ] 
        then apt-get update >> $SLOG 2>&1
             echo "Running 'apt-get -y install python3 python3-pip'"| tee -a $SLOG
             apt-get -y install python3 python3-pip >>$SLOG 2>&1
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

}


#===================================================================================================
# Check if python 3 is installed, if not install it 
#===================================================================================================
check_python3()
{
    # Check if python3 is installed 
    echo "Check if python3 is installed ..." | tee -a $SLOG

    # python3 should now be installed, if not then abort installation
    which python3 > /dev/null 2>&1
    if [ $? -eq 0 ]
        then echo "[OK] python3 is installed." | tee -a $SLOG
             echo " " | tee -a $SLOG
        else echo "Python3 is not installed."  | tee -a $SLOG
             install_python3 
             echo "[OK] python3 is installed." | tee -a $SLOG
    fi

    
    # Check if python3 'pymsql' module is installed 
    echo "Check if python3 'pymsql' module is installed ..." | tee -a $SLOG
    python3 -c "import pymysql" > /dev/null 2>&1
    if [ $? -eq 0 ] 
        then echo "[OK] Module already installed." | tee -a $SLOG
             echo " " | tee -a $SLOG
        else echo "Installing python3 'pymsql' module." 
             pip3 install pymysql  > /dev/null 2>&1
             if [ $? -ne 0 ]
                then echo " " | tee -a $SLOG
                     echo "----------" | tee -a $SLOG
                     echo "We have problem installing python module 'pymysql'." | tee -a $SLOG
                     echo "Please install pymysql package (pip3 install pymysql)" | tee -a $SLOG
                     echo "Then run this script again." | tee -a $SLOG 
                     echo "----------" | tee -a $SLOG
                     exit 1
                else echo "[OK] Module installed." | tee -a $SLOG
             fi
    fi
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
    echo -n "Checking if 'lsb_release' is available ... " | tee -a $SLOG
    which lsb_release > /dev/null 2>&1
    if [ $? -eq 0 ] ; then echo " Done " | tee -a $SLOG ; return ; fi 

    echo "[lsb_release] is not installed." | tee -a $SLOG
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
             echo "We are having problem installing lsb_release command." | tee -a $SLOG
             echo "Please install lsb-release(deb) or redhat-lsb-core(rpm) package" | tee -a $SLOG
             echo "Then run this script again." | tee -a $SLOG 
             echo "----------" | tee -a $SLOG
             exit 1
    fi

    return 0
}

#===================================================================================================
# Gather System Information needed for this script
#===================================================================================================
get_sysinfo()
{
    # Get O/S Name (REDHAT,UBUNTU,CENTOS,...) and O/S Major Number
    SADM_OSNAME=`lsb_release -si | tr '[:lower:]' '[:upper:]'`         
    if [ "$SADM_OSNAME" = "REDHATENTERPRISESERVER" ] ; then SADM_OSNAME="REDHAT" ; fi
    if [ "$SADM_OSNAME" = "REDHATENTERPRISEAS" ]     ; then SADM_OSNAME="REDHAT" ; fi
    if [ "$SADM_OSNAME" = "REDHATENTERPRISE" ]       ; then SADM_OSNAME="REDHAT" ; fi

    SADM_OSFULLVER=`lsb_release -sr| tr -d ' '`                         # Get O/S Full Version No.
    SADM_OSVERSION=`lsb_release -sr |awk -F. '{ print $1 }'| tr -d ' '` # Use lsb_release 2 Get Ver
    echo "Your System is running $SADM_OSNAME Version $SADM_OSVERSION ..." >> $SLOG
    
    SADM_OSTYPE=`uname -s | tr '[:lower:]' '[:upper:]'`                 # OS(AIX/LINUX/DARWIN/SUNOS)

    # Determine Package format in use on this system
    SADM_PACKTYPE=""                                                    # Initial Package Type None
    which rpm > /dev/null 2>&1                                          # Is command rpm available 
    if [ $? -eq 0 ] ; then SADM_PACKTYPE="rpm"  ; fi                    # RedHat, CentOS Package
    which dpkg > /dev/null 2>&1                                         # Is command dpkg available 
    if [ $? -eq 0 ] ; then SADM_PACKTYPE="deb"  ; fi                    # Debian,Raspbian,Ubuntu deb  
    which lslpp > /dev/null 2>&1                                        # Is command lslpp available 
    if [ $? -eq 0 ] ; then SADM_PACKTYPE="aix"  ; fi                    # Aix Package Type
    which launchctl > /dev/null 2>&1                                    # Is command launchctl avail 
    if [ $? -eq 0 ] ; then SADM_PACKTYPE="dmg"  ; fi                    # Apple package type
    echo "SADM_PACKTYPE=$SADM_PACKTYPE" >>$SLOG 
}




#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
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
    echo "SLOGDIR = $SLOGDIR & Log file is $SLOG" >> $SLOG 

    check_lsb_release                                                   # lsb_release must be found
    get_sysinfo                                                         # Get OS Name,Version
    if [ "$SADM_OSNAME" = "REDHAT" ] || [ "$SADM_OSNAME" = "CENTOS" ]   # On RedHat & CentOS
        then add_epel_repo                                              # Add EPEL Repository 
    fi 
    check_python3                                                       # Make sure python3 install
    check_hostname                                                      # Update /etc/hosts 

    # Ok Python3 and lsb_release command are installed - Proceeed with Main Setup Script
    echo "We will now proceed with main setup program ($SCRIPT)" >> $SLOG 
    echo "All Verifications done ..." >> $SLOG
    echo -e "\n" | tee -a $SLOG                                         # Blank Lines
    $SCRIPT 

