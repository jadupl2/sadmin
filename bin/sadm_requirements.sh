#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_requirements.sh
#   Date        :   2019/03/17
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Check if all SADMIN Tools requirement are met (-i install missing package)
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <sadmlinux@gmail.com>.
#   Developer Web Site : https://sadmin.ca
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
# Version Change Log 
#
# 2019_03_17 install v1.0 Initial Version.
# 2019_03_20 install v1.1 Verify if SADMIN requirement are met and -i to install missing requirement.
# 2019_03_29 install v1.2 Add 'chkconfig' command requirement if running system using SYSV Init.
# 2019_04_07 install v1.3 Use color variables from SADMIN Library.
# 2019_05_16 install v1.4 Don't generate the RCH file & allow running multiple instance of script.
# 2019_10_30 install v1.5 Remove 'facter' requirement.
# 2019_12_02 install v1.6 Fix Mac OS crash.
# 2020_04_01 install v1.7 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2020_04_29 install v1.8 Remove arp-scan from the SADMIN server requirement list.
# 2020_11_20 install v1.9 Added package 'wkhtmltopdf' installation to server requirement.
# 2021_04_02 install v1.10 Fix crash when trying to install missing package.
# 2022_04_10 install v1.11 Depreciated `lsb_release` for AlmaLinux 9, RHEL 9, Rocky 9 CentOS 9.
# 2022_05_10 install v1.12 Using now 'mutt' instead of 'mail'.
# 2022_07_19 install v1.13 Update of the list of commands and package require by SADMIN.
# 2023_04_27 install v1.14 Add 'base64' command to requirement list.
# 2023_12_21 install v1.15 Revision of the list of the packages require.
#@2024_04_21 install v1.16 Replace 'sadm_write' by 'sadm_write_log' and 'sadm_write_err'.
#@2025_02_22 install v1.17 Replace 'command_available()' by the one in library 'sadm_get_command_path()'.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # INTERCEPT LE ^C
#set -x
     





# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.17'                                     # Your Current Script Version
export SADM_PDESC="Check if all SADMIN Tools requirement are present (-i install missing packages)."
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------





#===================================================================================================
# Scripts Variables 
#===================================================================================================
SPATH=""                                    ; export SPATH              # Work Path of Command 
INSTREQ=0                                   ; export INSTREQ            # 0=DryRun 1=Install Missing
CHK_SERVER="N"                              ; export CHK_SERVER         # Check Server Req. if "Y"
OSRELEASE="/etc/os-release"                 ; export OSRELEASE

package_type="$(sadm_get_packagetype)"      ; export package_type       # System Pack Type (rpm,deb)
#
command -v systemctl > /dev/null 2>&1                                   # Using sysinit or systemd ?
if [ $? -eq 0 ] ; then SYSTEMD=1 ; else SYSTEMD=0 ; fi                  # Set SYSTEMD Accordingly
export SYSTEMD                                                          # Export Result        
#


# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-i   (Install missing package)"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\t-s   (Check SADMIN server requirement)"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
# THIS FUNCTION IS USED TO INSTALL A MISSING PACKAGE THAT IS REQUIRED BY SADMIN TOOLS
#                       THE PACKAGE TO INSTALL IS RECEIVED AS A PARAMETER
# --------------------------------------------------------------------------------------------------
install_package()
{
    # Check if we received at least a parameter
    if [ $# -ne 2 ]                                                      # Should have rcv 2 Param
        then sadm_write_log "Nb. Parameter received by $FUNCNAME function is incorrect."
             sadm_write_log "Please correct your script - Script Aborted.\n" # Advise User to Correct
             sadm_stop 1                                                 # Prepare exit gracefully
             exit 1                                                      # Terminate the script
    fi
    PACKAGE_RPM=$1                                                       # RedHat/CentOS/Fedora Pkg
    PACKAGE_DEB=$2                                                       # Ubuntu/Debian/Raspian Deb

    case "$package_type"  in
        "rpm" ) sadm_write_log "----------"
                if [ "$(sadm_get_osname)" = "FEDORA" ] 
                   then sadm_write_log "Running \"dnf -y install ${PACKAGE_RPM}\"" # Install Command
                        dnf -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List Available update
                        rc=$?                                            # Save Exit Code
                        sadm_write_log "Return Code after in installation of ${PACKAGE_RPM} is ${rc}."
                   else lmess="Starting installation of ${PACKAGE_RPM} under $(sadm_get_osname)"
                        lmess="${lmess} v$(sadm_get_osmajorversion)"
                        sadm_write_log "${lmess}"
                        case "$(sadm_get_osmajorversion)" in
                            [567])  sadm_write_log "Running 'yum -y install ${PACKAGE_RPM}'" 
                                    yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  
                                    rc=$?                                            
                                    sadm_write_log "Return Code after in installation of ${PACKAGE_RPM} is ${rc}."
                                    ;;
                            [89])   sadm_write_log "Running 'dnf -y install ${PACKAGE_RPM}'" 
                                    yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List update
                                    rc=$?                                            # Save ExitCode
                                    sadm_write_log "Return Code after in installation of ${PACKAGE_RPM} is ${rc}."
                                    ;;
                            *)      lmess="The version $(sadm_get_osmajorversion) of"
                                    lmess="${lmess} $(sadm_get_osname) isn't supported at the moment"
                                    sadm_write_log "${lmess}."
                                    rc=1 
                                    ;;
                        esac
                fi
                sadm_write_log "----------"
                ;;

        "deb" ) sadm_write_log "----------"
                sadm_write_log "Running \"apt update\""                 # Msg Get package list
                apt update > /dev/null 2>&1                             # Get Package List From Repo
                rc=$?                                                   # Save Exit Code
                if [ "$rc" -ne 0 ]
                    then sadm_write_err "We had problem running the \"apt update\" command."
                         sadm_write_err "We had a return code ${rc}."
                    else sadm_write_log "Return Code after apt-get update is ${rc}." 
                         sadm_write_log "Installing the Package ${PACKAGE_DEB} now."
                         sadm_write_log "apt -y install ${PACKAGE_DEB}"
                         apt -y install ${PACKAGE_DEB} >>$SADM_LOG 2>&1
                         rc=$?                                          # Save Exit Code
                         sadm_write_log "Return Code after installation of ${PACKAGE_DEB} is $rc"
                fi
                sadm_write_log "----------"
                ;;
    esac

    sadm_write_log " "
    return $rc                                                          # 0=Installed 1=Error
}


#===================================================================================================
#  Install EPEL 7 Repository for Redhat / CentOS / Rocky / Alma Linux / 
#===================================================================================================
add_epel_7_repo()
{
    RC=0                                                                # Default Return Code

    yum repolist | grep -qi "^epel "                                    # Is epel is already install
    if [ $RC -ne 0 ]
        then sadm_write_log "Adding CentOS/Redhat V7 EPEL repository ..." 
             EPEL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
             sadm_write_log "yum install -y $EPEL"
             yum install -y $EPEL >>$SLOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_write_err "[ ERROR ] Adding EPEL 7 repository."
                      RC=1
             fi
    fi

    if [ "$SADM_OSNAME" = "CENTOS" ] 
        then sadm_write_log "Installing epel-next-release CentOS/Redhat v${SADM_OS_VERSION} ..." 
             sadm_write_log "dnf -y install epel-next-release ..."
             dnf -y install epel-next-release >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] Adding epel-next-release v${SADM_OS_VERSION} repo."
                     RC=1
                else sadm_write_log "[ OK ]"
             fi
    fi 

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then rhel1="--enable rhel-*-optional-rpms "
             rhel2="--enable rhel-*-extras-rpms "
             rhel3="--enable rhel-ha-for-rhel-*-server-rpms "
             sadm_write_log "On Red Hat Enable Extra repositories ..."
             sadm_write_log "subscription-manager repos "$rhel1" "$rhel2" "$rhel3""
             subscription-manager repos "$rhel1" "$rhel2" "$rhel3" 
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] Couldn't enable Red Hat extra repositories."
                     RC=1
                else sadm_write_log "[ OK ]"
             fi 
    fi

    #sadm_write_log "Disabling EPEL Repository (yum-config-manager --disable epel) "
    #sadm_write_log "yum-config-manager --disable epel" 
    #yum-config-manager --disable >> $SADM_LOG 2>&1
    #if [ $? -ne 0 ]
    #   then sadm_write_err "Couldn't disable EPEL for version $SADM_OS_VERSION" 
    #        RC=1
    #   else sadm_write_log "[ OK ]"
    #fi 

    return $RC
}


#===================================================================================================
# Add EPEL Repository on Redhat / CentOS 8 (but do not enable it)
#===================================================================================================
add_epel_8_repo()
{
    RC=0                                                                # Default Return Code
    if [ "$SADM_OSNAME" != "REDHAT" ] 
        then dnf repolist | grep -qi "^powertools "                     # Is powertools installed ?
             if [ $RC -ne 0 ]
                then sadm_write_log "dnf config-manager --set-enabled powertools ..." 
                     dnf config-manager --set-enabled powertools  >>$SADM_LOG 2>&1 
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Couldn't enable 'powertools' repository."
                             RC=1
                        else sadm_write_log " [ OK ]"
                     fi 
             fi

             dnf repolist | grep -qi "^epel "                                    # Is epel is already install
             if [ $RC -ne 0 ]
                then sadm_write_log "Installing epel-release on $SADM_OS_NAME v${SADM_OS_VERSION} ..."
                     sadm_write_log "dnf -y install epel-release ..."
                     dnf -y install epel-release >>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Adding epel-release v${SADM_OS_VERSION} repository."
                             RC=1
                        else sadm_write_log " [ OK ]"
                     fi
             fi
    fi 

    if [ "$SADM_OSNAME" = "CENTOS" ] 
        then dnf repolist | grep -qi "^epel-next "                      # Is epel-next installed ?
             if [ $RC -ne 0 ]
                then sadm_write_log "Installing epel-next-release CentOS/Redhat v${SADM_OS_VERSION} ..." 
                     sadm_write_log "dnf -y install epel-next-release ..."
                     dnf -y install epel-next-release >>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Adding epel-next-release v${SADM_OS_VERSION} repo."
                             RC=1
                        else sadm_write_log "[ OK ]"
                     fi
             fi
    fi 

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then dnf repolist | grep -qi "^epel "                                    # Is epel is already install
             if [ $RC -ne 0 ]
                then sadm_write_log "Installing epel-release on $SADM_OS_NAME v${SADM_OS_VERSION} ..."
                     sadm_write_log "dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
                     dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Adding epel-release v${SADM_OS_VERSION} repository."
                             RC=1
                        else sadm_write_log " [ OK ]"
                     fi
             fi

             dnf repolist | grep -qi "^codeready-builder"
             if [ $RC -ne 0 ]
                then sadm_write_log "On Red Hat Enable 'codeready-builder' EPEL repository ..."
                     sadm_write_log "subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms"
                     subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms >>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository."
                             RC=1
                        else sadm_write_log "[ OK ]"
                     fi 
             fi
    fi 

    #sadm_write_log "Disabling EPEL Repository (yum-config-manager --disable epel) " 
    #dnf config-manager --disable epel >/dev/null 2>&1
    #if [ $? -ne 0 ]
    #   then sadm_write_err "Couldn't disable EPEL for version $SADM_OS_VERSION"
    #        RC=1
    #   else sadm_write_log "[ OK ]"
    #fi 
    return $RC
}



#===================================================================================================
# Add EPEL Repository on Redhat / CentOS 9 (but do not enable it)
#===================================================================================================
add_epel_9_repo()
{
    RC=0                                                                # Default Return Code

    dnf repolist | grep -qi "^crb "                                     # Is crb is already install
    if [ $RC -ne 0 ]
        then sadm_write_log "dnf config-manager --set-enabled crb ..." 
             dnf config-manager --set-enabled crb  >>$SADM_LOG 2>&1 
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] Couldn't enable 'crb' repository."
                     RC=1
                else sadm_write_log " [ OK ]"
             fi 
    fi 

    dnf repolist | grep -qi "^epel "                                    # Is epel is already install
    if [ $RC -ne 0 ]
        then sadm_write_log "Installing epel-release on $SADM_OS_NAME v${SADM_OS_VERSION} ..."
             sadm_write_log "dnf -y install epel-release ..."
             dnf -y install epel-release >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] Adding epel-release v${SADM_OS_VERSION} repository."
                     RC=1
                else sadm_write_log " [ OK ]"
             fi
    fi 

    if [ "$SADM_OSNAME" = "CENTOS" ] 
        then sadm_write_log "Installing epel-next-release CentOS/Redhat v${SADM_OS_VERSION} ..." 
             sadm_write_log "dnf -y install epel-next-release ..."
             dnf -y install epel-next-release >>$SADM_LOG 2>&1
             if [ $? -ne 0 ]
                then sadm_write_err "[ ERROR ] Adding epel-next-release v${SADM_OS_VERSION} repo."
                     RC=1
                else sadm_write_log "[ OK ]"
             fi
    fi 

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then dnf repolist | grep -qi "^epel "                                    # Is epel is already install
             if [ $RC -ne 0 ]
                then sadm_write_log "Installing epel-release on $SADM_OS_NAME v${SADM_OS_VERSION} ..."
                     sadm_write_log "dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm"
                     dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm>>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Adding epel-release v${SADM_OS_VERSION} repository."
                             RC=1
                        else sadm_write_log " [ OK ]"
                     fi
             fi

             dnf repolist | grep -qi "^codeready-builder"
             if [ $RC -ne 0 ]
                then sadm_write_log "On Red Hat Enable 'codeready-builder' EPEL repository ..."
                     sadm_write_log "subscription-manager repos --enable codeready-builder-beta-for-rhel-9-$(arch)-rpms"
                     subscription-manager repos --enable codeready-builder-beta-for-rhel-9-$(arch)-rpms >>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository."
                             RC=1
                        else sadm_write_log "[ OK ]"
                     fi 
             fi
    fi  

    #sadm_write_log "Disabling EPEL Repository (yum-config-manager --disable epel) " 
    #dnf config-manager --disable epel >/dev/null 2>&1
    #if [ $? -ne 0 ]
    #   then sadm_write_err "Couldn't disable EPEL for version $SADM_OS_VERSION"
    #        RC=1
    #   else sadm_write_log "[ OK ]"
    #fi 

    return $RC
}


#===================================================================================================
#  Install EPEL Repository for Redhat / CentOS / Rocky / Alma Linux / 
#===================================================================================================
add_epel_repo()
{
    case $SADM_OS_VERSION in
        7)  add_epel_7_repo 
            RC=$?
            ;;
        8)  add_epel_8_repo 
            RC=$?
            ;;
        9)  add_epel_9_repo 
            RC=$?
            ;;
        *)  sadm_write_err "Ver. $SADM_OS_VERSION of $SADM_OS_NAME don't have EPEL repository."
            RC=1
            ;;
    esac

    if [ $RC -ne 0 ]
       then sadm_write_err "[ ERROR ] Adding EPEL for $SADM_OS_NAME v${SADM_OS_VERSION} repo." 
            return 1
       else sadm_write_log "[ OK ] EPEL for $SADM_OS_NAME v${SADM_OS_VERSION} repo added with success." 
    fi
    return 0 
}




# --------------------------------------------------------------------------------------------------
# THIS FUNCTION VERIFY IF THE PACKAGE NAMES RECEIVED IN PARAMETER IS AVAILABLE ON THE SYSTEM
# 1st PARAMETER is the RPM PACKAGE NAME AND THE SECOND IS THE DEB NAME
# IF THE COMMAND EXIST, RETURN 0  -  IF IT DOESN'T EXIST RETURN 1
# --------------------------------------------------------------------------------------------------
package_available() {
    RPM_PACK=$1                                                         # RPM Package Name
    DEB_PACK=$2                                                         # Deb Package Name

    case "$package_type"  in
        "rpm" )     printf "%-56s" "Checking availability of rpm package $RPM_PACK" 
                    rpm -q $RPM_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "${BOLD}${MAGENTA}[Warning]${NORMAL} package missing" 
                    if [ $INSTREQ -eq 1 ] 
                        then install_package "$RPM_PACK" "$DEB_PACK" 
                        else return 1
                    fi
                    #
                    printf "%-56s" "Check if install of $RPM_PACK was successful" 
                    rpm -q $RPM_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "${BOLD}${MAGENTA}[Warning]${NORMAL} package could not be installed." 
                    return 1 
                    ;;

        "deb" )     printf "%-56s" "Checking availability of deb package $DEB_PACK" 
                    dpkg -l $DEB_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "${BOLD}${MAGENTA}[Warning]${NORMAL} package missing" 
                    if [ $INSTREQ -eq 1 ] 
                        then install_package "$RPM_PACK" "$DEB_PACK" 
                        else return 1
                    fi
                    #
                    printf "%-56s" "Check if install of $DEB_PACK was successful" 
                    dpkg -l $DEB_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "${BOLD}${MAGENTA}[Warning]${NORMAL} package could not be installed." 
                    return 1 
                    ;;
        *)          printf "Package type $package+type is not supported yet" 
                    ;;
    esac
    return 0
}



# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIREMENTS ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
check_sadmin_requirements() {
    sadm_write_log "${YELLOW}${BOLD}SADMIN client requirements${NORMAL}"
    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] ||
       [ "$(sadm_get_osname)" = "ROCKY" ]  || [ "$(sadm_get_osname)" = "ALMA" ]
       then if [ $INSTREQ -eq 1 ] 
                then add_epel_repo
                else sadm_write_log "I would install EPEL repositories, if not already installed."
             fi 
    fi 
    
    # The 'which' command is needed to determine presence of command - Return Error if not found
    if [ "$SADM_WHICH" == "" ]
       then sadm_write_err "[ ERROR ] The command 'which' couldn't be found"
            sadm_write_err "          This program is often used by the SADMIN tools"
            sadm_write_err "          Please install it and re-run this script"
            sadm_write_err "          *** Script Aborted"
            return 1                                                   # Return Error to Caller
    fi

    # Get Command path for Linux O/S ---------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # Under Linux O/S
       then 
            sadm_get_command_path "dmidecode"   ; SADM_DMIDECODE=$SPATH     # Save Command Path Returned
            if [ "$SADM_DMIDECODE" = "" ] && [ "$INSTREQ" -eq 1 ]       # Cmd not found & Inst Req.
                then install_package "dmidecode" "dmidecode"            # Install Package (rpm,deb)
                     sadm_get_command_path "dmidecode" ; SADM_DMIDECODE=$SPATH   
            fi

            sadm_get_command_path "nmon"        ; SADM_NMON=$SPATH          # Save Command Path Returned
            if [ "$SADM_NMON" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "--enablerepo=epel nmon" "nmon"    # Install Package (rpm,deb)
                     sadm_get_command_path "nmon" ; SADM_NMON=$SPATH        # Recheck Should be install
            fi

            sadm_get_command_path "ethtool"     ; SADM_ETHTOOL=$SPATH       # Save Command Path Returned
            if [ "$SADM_ETHTOOL" = "" ] && [ "$INSTREQ" -eq 1 ]         # Cmd not found & Inst Req. 
                then install_package "ethtool" "ethtool"                # Install Package (rpm,deb)
                     sadm_get_command_path "ethtool" ; SADM_ETHTOOL=$SPATH  # Recheck Should be install
            fi

            if [ $SYSTEMD -ne 1 ]                                       # Using Sysinit
                then sadm_get_command_path "chkconfig" ; SADM_CHKCONFIG=$SPATH # Save Cmd Path Returned
                     if [ "$SADM_CHKCONFIG" = "" ] && [ "$INSTREQ" -eq 1 ] # Not found = Inst Req. 
                        then install_package "chkconfig" "chkconfig"       # Install Pack (rpm,deb)
                             sadm_get_command_path "chkconfig" ; SADM_CHKCONFIG=$SPATH  # Recheck 
                     fi
            fi

            sadm_get_command_path "sudo"     ; SADM_SUDO=$SPATH             # Save Command Path Returned
            if [ "$SADM_SUDO" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "sudo" "sudo"                      # Install Package (rpm,deb)
                     sadm_get_command_path "sudo"     ; SADM_SUDO=$SPATH    # Recheck Should be install
            fi

            sadm_get_command_path "lshw"     ; SADM_LSHW=$SPATH             # Save Command Path Returned
            if [ "$SADM_LSHW" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "lshw" "lshw"                      # Install Package (rpm,deb)
                     sadm_get_command_path "lshw"     ; SADM_LSHW=$SPATH    # Recheck Should be install
            fi

            sadm_get_command_path "base64"     ; SADM_BASE64=$SPATH         # Save Command Path Returned
            if [ "$SADM_BASE64" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "coreutils" "coreutils"            # Install Package (rpm,deb)
                     sadm_get_command_path "base64"   ; SADM_LSHW=$SPATH    # Recheck Should be install
            fi

            sadm_get_command_path "ifconfig"     ; SADM_IFCONFIG=$SPATH     # Save Command Path Returned
            if [ "$SADM_IFCONFIG" = "" ] && [ "$INSTREQ" -eq 1 ]        # Cmd not found & Inst Req.
                then install_package "net-tools" "net-tools"            # Install Package (rpm,deb)
                     sadm_get_command_path "ifconfig" ;SADM_IFCONFIG=$SPATH # Recheck Should be install
            fi

            sadm_get_command_path "sar"     ; SADM_SAR=$SPATH               # Save Command Path Returned
            if [ "$SADM_SAR" = "" ] && [ "$INSTREQ" -eq 1 ]             # Cmd not found & Inst Req.
                then install_package "sysstat" "sysstat"                # Install Package (rpm,deb)
                     sadm_get_command_path "sar"  ; SADM_SAR=$SPATH         # Recheck Should be install
            fi

            sadm_get_command_path "parted"      ; SADM_PARTED=$SPATH        # Save Command Path Returned
            if [ "$SADM_PARTED" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "parted" "parted"                  # Install Package (rpm,deb)
                     sadm_get_command_path "parted" ; SADM_PARTED=$SPATH    # Recheck Should be install
            fi

            sadm_get_command_path "mutt"        ; SADM_MUTT=$SPATH          # Save Command Path Returned
            if [ "$SADM_MUTT" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "parted" "parted"                  # Install Package (rpm,deb)
                     sadm_get_command_path "mutt"  ; SADM_MUTT=$SPATH       # Recheck Should be install
            fi

            sadm_get_command_path "gawk"        ; SADM_GAWK=$SPATH          # Save Command Path Returned
            if [ "$SADM_GAWK" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "gawk" "gawk"                      # Install Package (rpm,deb)
                     sadm_get_command_path "gawk"  ; SADM_GAWK=$SPATH       # Recheck Should be install
            fi

            sadm_get_command_path "curl"        ; SADM_CURL=$SPATH          # Save Command Path Returned
            if [ "$SADM_CURL" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "curl" "curl"                      # Install Package (rpm,deb)
                     sadm_get_command_path "curl"  ; SADM_CURL=$SPATH       # Recheck Should be install
            fi

            sadm_get_command_path "lscpu"       ; SADM_LSCPU=$SPATH         # Save Command Path Returned
            if [ "$SADM_LSCPU" = "" ] && [ "$INSTREQ" -eq 1 ]           # Cmd not found & Inst Req.
                then install_package "util-linux" "util-linux"          # Install Package (rpm,deb)
                     sadm_get_command_path "lscpu" ; SADM_LSCPU=$SPATH      # Recheck Should be install
            fi
            
            sadm_get_command_path "fdisk"       ; SADM_FDISK=$SPATH         # Save Command Path Returned
            if [ "$SADM_FDISK" = "" ] && [ "$INSTREQ" -eq 1 ]           # Cmd not found & Inst Req.
                then install_package "util-linux" "util-linux"          # Install Package (rpm,deb)
                     sadm_get_command_path "fdisk"  ; SADM_FDISK=$SPATH     # Recheck Should be install
            fi

            if [ "$(sadm_get_osname)" != "RASPBIAN" ]
                then sadm_get_command_path "rear"         ; SADM_REAR=$SPATH        # Save Command Path Returned
                     if [ "$SADM_REAR" = "" ] && [ "$INSTREQ" -eq 1 ]           # Cmd not found & Inst Req.
                         then install_package "rear" "rear"
                              sadm_get_command_path "rear"   ; SADM_SYSLINUX=$SPATH # Recheck Should be install
                     fi    
            fi 

            if [ "$(sadm_get_osname)" != "RASPBIAN" ]
                then sadm_get_command_path "syslinux"         ; SADM_SYSLINUX=$SPATH        
                     if [ "$SADM_RSYNC" = "" ] && [ "$INSTREQ" -eq 1 ]                  
                        then install_package "syslinux" "syslinux"
                             sadm_get_command_path "syslinux"   ; SADM_SYSLINUX=$SPATH      
                     fi    
            fi 

            # Check if Package is installed, if option (-i) is set then install it.
            package_available "perl-libwww-perl" "libwww-perl"          #  Check if Perl Package Inst
            package_available "sysstat" "sysstat"                      
    fi


    # Get Command path for All supported O/S -------------------------------------------------------
    sadm_get_command_path "perl"        ; SADM_PERL=$SPATH                  # Save Command Path Returned
    if [ "$SADM_PERL" = "" ] && [ "$INSTREQ" -eq 1 ]                    # Cmd not found & Inst Req.
        then install_package "perl" "perl-base"                         # Install Package (rpm,deb)
             sadm_get_command_path "perl"  ; SADM_PERL=$SPATH               # Recheck Should be install
    fi    
    
    sadm_get_command_path "ssh"         ; SADM_SSH=$SPATH                   # Save Command Path Returned
    if [ "$SADM_SSH" = "" ] && [ "$INSTREQ" -eq 1 ]                     # Cmd not found & Inst Req.
        then install_package "openssh-clients" "openssh-client"         # Install Package (rpm,deb)
             sadm_get_command_path "ssh"         ; SADM_SSH=$SPATH          # Recheck Should be install
    fi    

    sadm_get_command_path "rsync"         ; SADM_RSYNC=$SPATH               # Save Command Path Returned
    if [ "$SADM_RSYNC" = "" ] && [ "$INSTREQ" -eq 1 ]                   # Cmd not found & Inst Req.
        then install_package "rsync" "rsync"
             sadm_get_command_path "rsync"         ; SADM_RSYNC=$SPATH      # Recheck Should be install
    fi    
    sadm_get_command_path "genisoimage"   ; SADM_GENISOIMAGE=$SPATH         # Save Command Path Returned
    if [ "$SADM_GENISOIMAGE" = "" ] && [ "$INSTREQ" -eq 1 ]              # Cmd not found & Inst Req.
        then install_package "genisoimage" "genisoimage"
             sadm_get_command_path "genisoimage" ; SADM_GENISOIMAGE=$SPATH  # Recheck Should be install
    fi    

    sadm_get_command_path "hwinfo"         ; SADM_HWINFO=$SPATH             # Save Command Path Returned
    if [ "$SADM_HWINFO" = "" ] && [ "$INSTREQ" -eq 1 ]                  # Cmd not found & Inst Req.
        then install_package "hwinfo" "hwinfo"
             sadm_get_command_path "hwinfo"   ; SADM_SYSLINUX=$SPATH        # Recheck Should be install
    fi    

    sadm_get_command_path "bc"          ; SADM_BC=$SADM_BC                  # Save Command Path Returned
    if [ "$SADM_BC" = "" ] && [ "$INSTREQ" -eq 1 ]                      # Cmd not found & Inst Req.
        then install_package "bc" "bc"                                  # Install Package (rpm,deb)
             sadm_get_command_path "bc"          ; SADM_BC=$SADM_BC         # Recheck Should be install
    fi    

    sadm_get_command_path "inxi"          ; SADM_INXI=$SADM_INXI            # Save Command Path Returned
    if [ "$SADM_INXI" = "" ] && [ "$INSTREQ" -eq 1 ]                    # Cmd not found & Inst Req.
        then install_package "inxi" "inxi"                              # Install Package (rpm,deb)
             sadm_get_command_path "inxi" ; SADM_INXI=$SADM_INXI            # Recheck Should be install
    fi    

    sadm_get_command_path "python3"  ; SADM_PYTHON3=$SPATH                  # Save Command Path Returned
    if [ "$SADM_PYTHON3" = "" ] && [ "$INSTREQ" -eq 1 ]                 # Cmd not found & Inst Req.
        then install_package "--enablerepo=epel python34 python34-setuptools python34-pip" "python3" 
             sadm_get_command_path "python3"  ; SADM_PYTHON3=$SPATH         # Recheck Should be install
    fi    


    # If on the SADMIN Server mysql MUST be present - Check Availibility of the mysql command.
    if [ "$SADM_ON_SADMIN_SERVER" = "Y" ] || [ "$CHK_SERVER" = "Y" ] # Check Server Req.
        then sadm_write_log " "
             sadm_write_log "${YELLOW}${BOLD}SADMIN server requirements.${NORMAL}"
             sadm_get_command_path "mysql" ; SADM_MYSQL=$SPATH              # Get mysql cmd path  
             if [ "$SADM_MYSQL" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "mariadb-server " "mariadb-server mariadb-client"  
                     sadm_get_command_path "mysql" ; SADM_MYSQL=$SPATH      # Recheck Should be install 
             fi    
             sadm_get_command_path "rrdtool" ; SADM_RRDTOOL=$SPATH          # Get  cmd path  
             if [ "$SADM_RRDTOOL" = "" ] && [ "$INSTREQ" -eq 1 ]        # Cmd not found & Inst Req.
                then install_package "rrdtool" "rrdtool"                # Install package
                     sadm_get_command_path "rrdtool" ; SADM_RRDTOOL=$SPATH  # Recheck Should be install
             fi        
             sadm_get_command_path "fping" ; SADM_FPING=$SPATH              # Get  cmd path  
             if [ "$SADM_FPING" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "--enablerepo=epel fping" "fping monitoring-plugins-standard" 
                     sadm_get_command_path "fping" ; SADM_FPING=$SPATH      # Recheck Should be install
             fi    
             sadm_get_command_path "pip3" ; SADM_PIP3=$SPATH                # Get cmd path  
             if [ "$SADM_PIP3" = "" ] && [ "$INSTREQ" -eq 1 ]           # Cmd not found & Inst Req.
                then install_package "python3-pip" "python3-pip"        # Install package
                     if [ $? -ne 0 ]                                    # Normal Install not working
                        then install_package "--enablerepo=epel python34-pip" "python3-pip" 
                     fi 
                     sadm_get_command_path "pip3" ; SADM_PIP3=$SPATH        # Recheck Should be install
             fi    
             sadm_get_command_path "php" ; SADM_PHP=$SPATH                  # Get  cmd path  
             if [ "$SADM_PHP" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then rpmpkg="php php-common php-cli php-mysqlnd php-mbstring"
                     debpkg="php php-mysql php-common php-cli"
                     install_package  "$rpmpkg" "$debpkg"
                     sadm_get_command_path "php" ; SADM_PHP=$SPATH          # Recheck Should be install
             fi    
             if [ "$(sadm_get_packagetype)" = "rpm" ]                   # Check HTTPD RPM
                then sadm_get_command_path "httpd" ; SADM_HTTPD=$SPATH      # Get  cmd path  
                     if [ "$SADM_HTTPD" = "" ] && [ "$INSTREQ" -eq 1 ]  # Cmd not found & Inst Req.
                        then install_package "httpd httpd-tools" " "    # Install package
                             sadm_get_command_path "httpd" ; SADM_HTTPD=$SPATH  # Recheck Should be inst
                     fi  
             fi
             if [ "$(sadm_get_packagetype)" = "deb" ]                   # Check HTTPD RPM
                then sadm_get_command_path "apache2" ; SADM_APACHE2=$SPATH  # Get  cmd path  
                     if [ "$SADM_APACHE2" = "" ] && [ "$INSTREQ" -eq 1 ] # Cmd not found & Inst Req.
                        then install_package " " "apache2 apache2-utils libapache2-mod-php" 
                             sadm_get_command_path "apache2" ; SADM_APACHE2=$SPATH 
                     fi  
             fi    
    fi
    return 0
}





# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "hivsd:" opt ; do                                      # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}."               # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            i) INSTREQ=1                                                # Install Requirement ON
               ;;                                                       # No stop after each page
            s) CHK_SERVER="Y"                                           # Check Server Requirement
               ;;                                                       # No stop after each page
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}




# Script Start HERE
# --------------------------------------------------------------------------------------------------
    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    check_sadmin_requirements                                           # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
