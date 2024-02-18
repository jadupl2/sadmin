#! /usr/bin/env bash

# ADD apt install bind9-host


# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   setup.sh
#   Synopsis    :   Make sure Python3 is available before running sadm_setup.py (Main Setup Script)
#   Version     :   1.0
#   Date        :   26 March 2018 
#   Requires    :   sh 
#   Description :   Make sure python 3 is installed and then execute sadm_setup.py
#
#   This code was originally written by Jacques Duplessis <sadmlinux@gmail.com>,
#    2016-2018 Jacques Duplessis <sadmlinux@gmail.com> - https://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
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
# 2019_12_20 Update: v2.9 Better verification and installation of python3 (If needed)
# 2019_12_27 Update: v3.0 Add recommended EPEL Repos on CentOS/RHEL 8.
# 2019_12_27 Update: v3.1 On RHEL/CentOS 6/7, revert to Python 3.4 (3.6 Incomplete on EPEL)
# 2020_01_18 Fix: v3.2 Fix problem installing pip3, when running setup.sh script.
# 2020_02_23 Fix: v3.3 Fix some problem installing lsb_release and typo with 'dnf' command..
# 2020_02_23 Fix: v3.3 Fix some problem installing lsb_release and typo with 'dnf' command..
# 2020_04_19 Update: v3.4 Minor logging changes.
# 2020_04_21 Update: v3.5 On RHEL/CENTOS 8 hwinfo package remove from base, use EPEL repo.
# 2020_04_21 Update: v3.6 Change processing display & change installation dnf-utils for yum-utils.
# 2020_04_23 Update: v3.7 Added some more error checking.
# 2020_04_23 Fix: v3.8a Fix after Re-Tested on CentOS/RedHat 8 
# 2020_04_27 Update: v3.9 Install 'getmac' python3 module (for subnet scan).
# 2020_05_05 Update: v3.10 Adjust screen presentation.
# 2020_05_14 Update: v3.11 Remove line feed after "Installing pip3" 
# 2020_12_24 Update: v3.12 CentOSStream return CENTOS.
# 2022_02_10 install v3.13 Correct 'pip3' installation on Fedora 35.
# 2022_04_02 install v3.14 Command 'lsb_release' is gone is RHEL 9, '/etc/os-release file' is use.
# 2022_04_03 install v3.15 Adapted to use EPEL 9 for RedHat, Centos, AlmaLinux and Rocky Linux.
# 2022_04_06 install v3.16 Fix problem verifying and installing Python 3 'pip3' on CentOS v9
# 2022_04_07 install v3.17 Change to support AlmaLinux and Rocky Linux v9.
# 2022_04_11 install v3.18 Fix some problem related to using '/etc/os-release' on AlmaLinux.
# 2022_04_16 install v3.19 Misc. Fixes for CentOS 9, EPEL 9 and change UI a bit.
# 2022_05_06 install v3.20 Fix some issue installing EPEL repositories on AlmaLinux & Rocky v9.
# 2022_05_28 install v3.21 Make sure SELinux is set (temporarily) to Permissive during setup.
# 2022_10_23 install v3.22 Install 'host' command if not present on system.
# 2022_11_27 install v3.23 Correct problem when activating EPEL v9.
# 2023_02_08 install v3.24 Fix problem with GPG Key for EPEL v9.1
# 2023_04_05 install v3.25 Minor fixes
# 2023_04_15 install v3.26 Offer choice to disable SElinux temporarily or permanently during setup.
# 2023_05_19 install v3.27 Resolve problem when asking 'selinux' question.
# 2023_05_20 nolog   v3.28 Typo Error when asking selinux question
# 2023_06_05 install v3.29 Remove the need for 'bind-utils/bind9-dnsutils' package during install.
# 2023_07_09 install v3.30 Changed the way to install 'pymysql' python module (Debian 12).
# 2023_07_14 install v3.31 Hostname lookup, will verify /etc/hosts & DNS (if present).
# 2023_07_16 install v3.32 Cosmetic change to the script log.
# 2023_12_07 install v3.33 Minor adjustments.
# 2024_01_02 install v3.34 Remove requirement for python 'psutil' module.
#@2024_02_12 install v3.35 Make sure 'host' command is installed, (needed for hostname resolution).
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x


 
# Script environment variables
#===================================================================================================
export DEBUG_LEVEL=0                                                    # 0=NoDebug Higher=+Verbose
export SADM_VER='3.35'                                                  # Your Script Version
export SADM_PN="${0##*/}"                                               # Script name
export SADM_HOSTNAME=$(hostname -s)                                     # Current Host name
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)                      # Script name without ext.
export SADM_TPID="$$"                                                   # Script PID
export SADM_EXIT_CODE=0                                                 # Script Exit Return Code
export SCRIPT="$(dirname "$0")/bin/sadm_setup.py"                       # Main Setup SCRIPT Next
export SLOGDIR="$(dirname "$0")/log"                                    # Log Directory
if [ ! -d ${SLOGDIR} ] ; then mkdir $SLOGDIR ; fi                       # If Don't exist create dir
export SLOG="${SLOGDIR}/sadm_pre_setup.log"                             # Script Log Name
export SADM_OSNAME=""                                                   # Operating System Name 
export SADM_OSVERSION=""                                                # O/S System Major Version#
export SADM_OSFULLVER=""                                                # O/S Full Version number
export SADM_OSTYPE=""                                                   # OS(AIX/LINUX/DARWIN/SUNOS) 
export SADM_PACKTYPE=""                                                 # Package Type use on System

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


# ==================================================================================================
# Display Question (Receive as $1) and wait for response from user, Y/y (return 1) or N/n (return 0)
# ==================================================================================================
sadm_ask() {
    wreturn=0
    wmess="$1 [y,n] ? "                                                 # Add Y/N to Mess. Rcv
    while :                                                             # While until good answer
        do
        printf "%s" "$wmess"                                            # Print "Question [Y/N] ?" 
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;;
           n|N ) wreturn=0                                              # No = Return Value of 0
                 break                                                  # Break of the loop
                 ;;
             * ) echo ""                                                # Blank Line
                 ;;                                                     # Other stay in the loop
         esac
    done
    return $wreturn                                                     # Return Answer to caller 
}




#===================================================================================================
#  Install EPEL 7 Repository for Redhat / CentOS / Rocky / Alma Linux / 
#===================================================================================================
add_epel_7_repo()
{

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then rep1=' --enable rhel-*-optional-rpms'
             rep2=' --enable rhel-*-extras-rpms'
             rep3=' --enable rhel-ha-for-rhel-*-server-rpms'
             printf "subscription-manager repos $rep1 $rep2 $rep3"
             subscription-manager repos $rep1 $rep2 $rep3 >>$SLOG 2>&1
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable EPEL repositories." |tee -a $SLOG
                     return 1 
                else echo "[ OK ]" |tee -a $SLOG
             fi 
        else printf "Enable 'yum install epel-release' repository ...\n" |tee -a $SLOG
             printf "    - yum install epel-release " | tee -a $SLOG 
             yum install epel-release   >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'epel-release' repository." | tee -a $SLOG
                     return 1 
                else echo "[ OK ]" |tee -a $SLOG
                     return 0                                           # CentOS nothing more to do
             fi 
    fi 

    if [ ! -r /etc/yum.repos.d/epel.repo ]  
       then printf "Adding CentOS/Redhat V7 EPEL repository ...\n" |tee -a $SLOG
            printf "yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm\n" >>$SLOG 2>&1
            yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm >>$SLOG 2>&1
            if [ $? -ne 0 ]
                then echo "[ ERROR ] Adding EPEL 7 repository." |tee -a $SLOG
                     return 1
            fi
            #printf "Disabling EPEL Repository (yum-config-manager --disable epel) " |tee -a $SLOG
            #yum-config-manager --disable epel >/dev/null 2>&1
            #if [ $? -ne 0 ]
            #   then echo "Couldn't disable EPEL 7 for version $SADM_OSVERSION" | tee -a $SLOG
            #        return 1
            #   else echo "[ OK ]"
            #fi 
            return 0
    fi
}


#===================================================================================================
# Add EPEL Repository on Redhat / CentOS 8 (but do not enable it)
#===================================================================================================
add_epel_8_repo()
{

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then printf "Enable 'codeready-builder' EPEL repository ...\n" |tee -a $SLOG
             printf "subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms " |tee -a $SLOG 
             subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository." |tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
        else printf "Enable 'powertools' repository ...\n" |tee -a $SLOG
             printf "    - dnf config-manager --set-enabled powertools " | tee -a $SLOG 
             dnf config-manager --set-enabled powertools   >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'powertools' repository." | tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
    fi 

    if [ "$SADM_OSNAME" = "REDHAT" ] 
       then printf "dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm\n" >>$SLOG 2>&1
            dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >>$SLOG 2>&1
            if [ $? -ne 0 ]
               then echo "[ WARNING ] Couldn't enable EPEL 8 repository" |tee -a $SLOG
                    return 1
               else echo "[ OK ]" |tee -a $SLOG
            fi 
    fi

    if [ "$SADM_OSNAME" = "CENTOS" ] 
       then printf "dnf -y install dnf install epel-release epel-next-release\n"  >>$SLOG 2>&1
            dnf -y install dnf install epel-release epel-next-release >>$SLOG 2>&1 
            if [ $? -ne 0 ]
               then echo "[ WARNING ] Couldn't enable EPEL 8 repositories" |tee -a $SLOG
                    return 1
               else echo "[ OK ] Enable EPEL 8 repositories" |tee -a $SLOG
            fi 
    fi

    if [ "$SADM_OSNAME" = "ALMA" ] || [ "$SADM_OSNAME" = "ROCKY" ]
       then printf "dnf -y install epel-release"
            dnf -y install epel-release >>$SLOG 2>&1 
            if [ $? -ne 0 ]
               then echo "[ WARNING ] Couldn't enable EPEL 8 repository" |tee -a $SLOG
                    return 1
               else echo "Enable EPEL 8 repository [ OK ]" |tee -a $SLOG
            fi 
    fi

    #printf "Disabling EPEL Repository (yum-config-manager --disable epel) " |tee -a $SLOG
    #dnf config-manager --disable epel >/dev/null 2>&1
    #if [ $? -ne 0 ]
    #   then echo "Couldn't disable EPEL for version $SADM_OSVERSION" | tee -a $SLOG
    #        return 1
    #   else echo "[ OK ]" |tee -a $SLOG
    #fi 
}



#===================================================================================================
# Add EPEL Repository on Redhat / CentOS 9 (but do not enable it)
# Run this function only when on RedHat, Alma, Rocky, CentOS
#===================================================================================================
add_epel_9_repo()
{

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then printf "Enable 'codeready-builder' EPEL repository for $SADM_OSNAME ...\n" |tee -a $SLOG
             printf "subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms " |tee -a $SLOG 
             subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository." |tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
        else printf "Enabling 'crb' repository for $SADM_OSNAME ...\n" |tee -a $SLOG
             printf "    - dnf config-manager --set-enabled crb " | tee -a $SLOG 
             dnf config-manager --set-enabled crb  >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'crb' repository." | tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
    fi 

    if [ "$SADM_OSNAME" = "ROCKY" ] || [ "$SADM_OSNAME" = "ALMA" ] 
        then dnf repolist | grep -q "^epel "
             if [ $? -ne 0 ] 
                then printf "\nInstalling epel-release on $SADM_OSNAME V9 ..." | tee -a $SLOG
                     printf "\n    - dnf -y install epel-release \n" | tee -a $SLOG
                     dnf -y install epel-release >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then echo "[Error] Adding epel-release V9 repository." |tee -a $SLOG
                             return 1 
                        else echo " [ OK ]" |tee -a $SLOG
                     fi
                else printf "\nRepository epel-release is already installed ...\n"  |tee -a $SLOG
             fi
             return 0 
    fi 

    if [ "$SADM_OSNAME" = "CENTOS" ] 
        then ins_count=0
             dnf repolist | grep -q "^epel " 
             if [ $? -ne 0 ] ; then ((ins_count++)) ; fi
             dnf repolist | grep -q "^epel-next "
             if [ $? -ne 0 ] ; then ((ins_count++)) ; fi
             if [ $ins_count -ne 0 ] 
                then printf "\nInstalling epel-release & epel-next-release on $SADM_OSNAME V9 ...\n" |tee -a $SLOG
                     printf "    - dnf -y install dnf install epel-release epel-next-release" |tee -a $SLOG
                     dnf -y install dnf install epel-release epel-next-release  >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then printf "[ ERROR ] Adding epel-release V9 repository.\n" |tee -a $SLOG
                             return 1 
                        else printf " [ OK ]\n" |tee -a $SLOG
                     fi
                else printf "\nRepositories epel-release & epel-next-release are already installed.\n" |tee -a $SLOG
             fi 
    fi  

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then printf "\nImport EPEL 9 GPG Key ...\n" |tee -a $SLOG
             printf "    - rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9 " |tee -a $SLOG 
             rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9
             if [ $? -ne 0 ]
                then printf "[ ERROR ] Importing epel-release V9 GPG Key.\n" |tee -a $SLOG
                     return 1 
                else printf "[ OK ]\n" |tee -a $SLOG
             fi
             dnf repolist | grep -q "^epel "
             if [ $? -ne 0 ] 
                then printf "\nInstalling epel-release CentOS/Redhat V9 ...\n" |tee -a $SLOG
                     printf "    - dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm " |tee -a $SLOG
                     dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then printf "[ ERROR ] Adding epel-release V9 repository.\n" |tee -a $SLOG
                             return 1 
                        else printf "[ OK ]\n" |tee -a $SLOG
                     fi
                else printf "\nRepository epel-release already installed.\n" |tee -a $SLOG
             fi 
    fi 
}



#===================================================================================================
#  Install EPEL Repository for Redhat / CentOS / Rocky / Alma Linux / 
#===================================================================================================
add_epel_repo()
{
    if [ "$SADM_OSVERSION" -eq 7 ] 
       then add_epel_7_repo 
            if [ $? -ne 0 ]
               then echo "[Error] Adding EPEL 7 repository." |tee -a $SLOG
                    return 1
            fi
    fi 
    if [ "$SADM_OSVERSION" -eq 8 ] 
       then add_epel_8_repo 
            if [ $? -ne 0 ]
               then echo "[Error] Adding EPEL 8 repository." |tee -a $SLOG
                    return 1
            fi
    fi 
    if [ "$SADM_OSVERSION" -eq 9 ] 
       then add_epel_9_repo 
            if [ $? -ne 0 ]
               then echo "[Error] Adding EPEL 9 repository." |tee -a $SLOG
                    return 1
            fi
    fi 
    return 0 
}



# Install python3 on system
#===================================================================================================
install_python3()
{

    #sadm_ask "SADMIN require 'python3' to be install, proceed with installation" 
    #if [ $? -eq 1 ]                                                     # Replied Yes
    #   then echo "SADMIN requirement will not be met, then installation aborted." | tee -a $SLOG
    #        exit 0  
    #fi 
    printf "\nInstalling 'python3' requirements." | tee -a $SLOG

    if [ "$SADM_PACKTYPE" = "rpm" ] 
        then  if [ "$SADM_OSVERSION" -lt 8 ]
                 then printf "\n   - Running 'yum -y install python3 python3-setuptools python3-pip python3-PyMySQL'\n" |tee -a $SLOG
                      yum -y install python3 python3-setuptools python3-pip  python3-PyMySQL >> $SLOG 2>&1
                 else printf "\n   - Running 'dnf -y install python3 python3-setuptools python3-pip python3-PyMySQL'\n" |tee -a $SLOG
                      dnf -y install python3 python3-setuptools python3-pip python3-PyMySQL >>$SLOG 2>&1
              fi 
    fi 
    if [ "$SADM_PACKTYPE" = "deb" ] 
        then apt-get update >> $SLOG 2>&1
             printf "\n   - Running 'apt -y install python3 python3-venv python3-pip python3-pymysql'"| tee -a $SLOG
             apt -y install python3 python3-venv python3-pip python3-pymysql >>$SLOG 2>&1
    fi 
    
    # python3 should now be installed, if not then abort installation
    which python3 > /dev/null 2>&1
    if [ $? -ne 0 ]
        then echo " " | tee -a $SLOG
             echo "----------" | tee -a $SLOG
             echo "We had problem installing 'python3' package." | tee -a $SLOG
             echo "Please try to install python3 package" | tee -a $SLOG
             echo "Then run this script again." | tee -a $SLOG 
             echo "----------" | tee -a $SLOG
             exit 1
        else echo " [ OK ]" | tee -a $SLOG
    fi
    
    # pip3 should now be installed, if not then abort installation
    which pip3 > /dev/null 2>&1
    if [ $? -ne 0 ]
        then echo " " | tee -a $SLOG
             echo "----------" | tee -a $SLOG
             echo "We had problem installing 'python3-pip' package." | tee -a $SLOG
             echo "Please try to install 'python-pip3' package" | tee -a $SLOG
             echo "Then run this script again." | tee -a $SLOG 
             echo "----------" | tee -a $SLOG
             exit 1
    fi
}


# Check if 'host' command is installed, if not install it 
#===================================================================================================
check_host_command()
{
    printf "Checking if 'host' command is installed" | tee -a $SLOG

    which host > /dev/null 2>&1                                         # Try getting command path
    if [ $? -eq 0 ]                                                     # If command installed
        then echo " [ OK ]" 
             return 0                                                   # Return to caller
        else echo " [ Not installed ]"  
    fi 

    if [ "$SADM_PACKTYPE" = "rpm" ] 
        then printf "   - Installing bind-utils"
             if [ "$SADM_OSVERSION" -lt 8 ]
                 then printf "\n   - Running 'yum -y install bind-utils'\n" |tee -a $SLOG
                      yum -y install bind-utils >> $SLOG 2>&1
                 else printf "\n   - Running 'dnf -y install bind-utils'\n" |tee -a $SLOG
                      dnf -y install bind-utils >> $SLOG 2>&1
              fi 
    fi 
    if [ "$SADM_PACKTYPE" = "deb" ] 
        then printf "   - Installing bind9-host"
             apt update >> $SLOG 2>&1
             printf "\n   - Running 'apt -y install bind9-host'"| tee -a $SLOG
             apt -y install bind9-host >>$SLOG 2>&1
    fi 
    
    which host > /dev/null 2>&1
    if [ $? -ne 0 ]
        then echo " " | tee -a $SLOG
             echo "----------" | tee -a $SLOG
             echo "We had problem installing the 'bind-utils' package." | tee -a $SLOG
             echo "Try to manually install 'bind-utils' ('bind9-host' on deb) package." |tee -a $SLOG
             echo "Script aborted, install the package & run this script again." | tee -a $SLOG 
             echo "----------" | tee -a $SLOG
             exit 1
    fi
    return 0
}





# Check if python 3 is installed, if not install it 
#===================================================================================================
check_python3()
{
    install_python3 

    # Check if python3 'pymsql' module is installed 
    printf "   - Check if python3 'pymsql' module is installed ... " | tee -a $SLOG
    python3 -c "import pymysql" > /dev/null 2>&1
    if [ $? -eq 0 ] 
        then echo "[ OK ] " | tee -a $SLOG
             return 0
    fi 

    if [ "$SADM_PACKTYPE" = "rpm" ] 
        then  if [ "$SADM_OSVERSION" -lt 8 ]
                 then printf "\n      - Running 'yum -y install python3-pymysql'\n" |tee -a $SLOG
                      yum -y install python3-pymysql  >> $SLOG 2>&1
                 else printf "\n      - Running 'dnf -y install python3-pymysql'\n" |tee -a $SLOG
                      dnf -y install python3-pymysql >>$SLOG 2>&1
              fi 
    fi 
    
    if [ "$SADM_PACKTYPE" = "deb" ] 
        then apt-get update >> $SLOG 2>&1
             printf "\n      - Running 'apt-get -y install python3-pymysql'"| tee -a $SLOG
             apt-get -y install python3-pymysql>>$SLOG 2>&1
    fi 
    
    # Test if install succeeded
    python3 -c "import pymysql" > /dev/null 2>&1  > /dev/null 2>&1
    if [ $? -ne 0 ]
       then echo " " | tee -a $SLOG
            echo "----------" | tee -a $SLOG
            echo "We have problem installing python module 'pymysql'." | tee -a $SLOG
            echo "Please install pymysql package (pip3 install pymysql)" | tee -a $SLOG
            echo "Then run this script again." | tee -a $SLOG 
            echo "----------" | tee -a $SLOG
            exit 1
       else echo " [ OK ] " | tee -a $SLOG
    fi
    return 0                                                            # Return No Error to Caller
}




# Make sure we have no problem with SELinux
#===================================================================================================
check_selinux()
{

    printf "\nChecking SELinux status ...\n" | tee -a $SLOG

    selinuxenabled
    if [ $? -eq 0 ] 
        then printf "   - SELinux is currently enabled.\n"
        else printf "   - SELinux is currently disabled.\n"
             return 0 
    fi 

    sestat=$(getenforce)
    printf "   - Current SELinux status is ${sestat}.\n"
    
    if [ "$sestat" == "Enforcing" ]
       then while : 
                do
                ans=""
                printf "   - SElinux need to be disable during installation.\n"
                printf "   - Do you wish to disable SElinux [T]emporarily or [P]ermanently [T/P] ? "
                read ans
                ans=$(echo "$ans" | tr '[:lower:]' '[:upper:]')
                if [ "$ans" == "T" ]
                    then setenforce 0
                         printf "   - SELinux is now disable temporarily.\n"
                         break
                    else if [ "$ans" == "P" ]
                            then sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
                                 setenforce 0
                                 printf "   - SELinux is now disable.\n"
                             break
                         fi 
                fi 
                done
    fi 
    
}





# Make sure hostname is in /etc/hosts
#===================================================================================================
check_hostname()
{
    # Get current IP Address of Server
    S_IPADDR=$(ip a s | grep global | head -1 | awk '{ print $2 }' |awk -F/ '{ print $1 }')
    S_DOMAIN=$(domainname -d)

    printf "Making sure '$SADM_HOSTNAME.$S_DOMAIN' is defined in /etc/hosts ... " | tee -a $SLOG

    # Insert Server into /etc/hosts (If not already there)
    grep -Ei "^$S_IPADDR " /etc/hosts | grep -q $SADM_HOSTNAME
    if [ $? -ne 0 ] 
        then if [ ! -f /etc/hosts.org ] ; then cp /etc/hosts /etc/hosts.org ; fi
             echo "$S_IPADDR     $SADM_HOSTNAME.$S_DOMAIN     $SADM_HOSTNAME" >> /etc/hosts
    fi

    echo "[ OK ] " | tee -a $SLOG
}




# Gather System Information needed for this script
#===================================================================================================
get_sysinfo()
{
    # Get O/S Name (REDHAT,UBUNTU,CENTOS,...) and O/S Major Number
    OS_FILE="/etc/os-release"
    SADM_OSNAME=$(awk -F= '/^ID=/ {print $2}' $OS_FILE |tr -d '"' |tr '[:lower:]' '[:upper:]')         
    if [ "$SADM_OSNAME" = "REDHATENTERPRISESERVER" ] ; then SADM_OSNAME="REDHAT"   ;fi
    if [ "$SADM_OSNAME" = "REDHATENTERPRISEAS" ]     ; then SADM_OSNAME="REDHAT"   ;fi
    if [ "$SADM_OSNAME" = "REDHATENTERPRISE" ]       ; then SADM_OSNAME="REDHAT"   ;fi
    if [ "$SADM_OSNAME" = "RHEL" ]                   ; then SADM_OSNAME="REDHAT"   ;fi
    if [ "$SADM_OSNAME" = "CENTOSSTREAM" ]           ; then SADM_OSNAME="CENTOS"   ;fi
    if [ "$SADM_OSNAME" = "ROCKYLINUX" ]             ; then SADM_OSNAME="ROCKY"    ;fi
    if [ "$SADM_OSNAME" = "ALMALINUX" ]              ; then SADM_OSNAME="ALMA"     ;fi
    if [ -f /usr/bin/raspi-config ]                  ; then SADM_OSNAME="RASPBIAN" ;fi
    if [ "$SADM_OSNAME" != "REDHAT" ] && [ "$SADM_OSNAME" != "CENTOS" ] && [ "$SADM_OSNAME" != "FEDORA" ] &&
       [ "$SADM_OSNAME" != "UBUNTU" ] && [ "$SADM_OSNAME" != "DEBIAN" ] && [ "$SADM_OSNAME" != "RASPBIAN" ] &&
       [ "$SADM_OSNAME" != "ALMA"   ] && [ "$SADM_OSNAME" != "ROCKY"  ] && [ "$SADM_OSNAME" != "MINT" ]
       then printf "This distribution of Linux ($SADM_OSNAME) is currently not supported.\n"
            exit 1
    fi

    # Get O/S Full Version Number
    if [ -f /etc/os-release ] 
        then SADM_OSFULLVER=$(awk -F= '/^VERSION_ID=/ {print $2}' /etc/os-release |tr -d '"')
        else printf "File /etc/os-release doesn't exist, couldn't get O/S version\n"
             SADM_OSFULLVER="00.00"
    fi 
    
    # Get O/S Major version number
    SADM_OSVERSION=$(echo $SADM_OSFULLVER | awk -F. '{ print $1 }'| tr -d ' ')
    echo "Your System is running $SADM_OSNAME Version $SADM_OSVERSION ..." >> $SLOG
    
    # Get O/S Type (LINUX,AIX,DARWIN,SUNOS)
    SADM_OSTYPE=$(uname -s | tr '[:lower:]' '[:upper:]')                # OS(AIX/LINUX/DARWIN/SUNOS)

    # Determine Package format in use on this system (rpm,deb,aix,dmg)
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




# Script Start HERE
#===================================================================================================

    if [ $(id -u) -ne 0 ]                                               # If Cur. user is not root 
        then echo "Script can only be run by the 'root' user." 
             echo "Process aborted"                                     # Abort advise message
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

    # Get  OS Name, Version, package type
    get_sysinfo                                                         # Get OS Name,Version,...
    
    echo " " > $SLOG                                                    # Init the Log File
    echo "SADMIN Pre-installation verification v${SADM_VER} - $SADM_OSTYPE $SADM_OSNAME v$SADM_OSVERSION" | tee -a $SLOG
    echo "$(date) - Log file is located in ${SLOGDIR}." | tee -a $SLOG 
    echo "---------------------------------------------------------------------------"| tee -a $SLOG


    # Add EPEL for these distribution
    if [ "$SADM_OSNAME" = "REDHAT" ] || [ "$SADM_OSNAME" = "CENTOS" ] ||  
       [ "$SADM_OSNAME" = "ROCKY" ]  || [ "$SADM_OSNAME" = "ALMA" ] 
        then add_epel_repo                                               
    fi 
    
    check_python3                                                       # Check Python3 sadmin req.
    check_hostname                                                      # Current host in /etc/hosts
    check_host_command                                                  # Check 'host' cmd installed

    # If SELinux present and activated, make it temporarily permissive until next reboot
    if [ "$SADM_PACKTYPE" = "rpm" ] ; then check_selinux ; fi

    # Proceed with Main Setup Script
    printf "\nAll basic requirements were met with success ..." 
    printf "\nWe will now proceed with main setup program ($SCRIPT)" 
    printf "\n---------------------------------------------------------------------------\n\n\n"
    $SCRIPT 
