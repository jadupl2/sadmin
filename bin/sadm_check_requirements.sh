#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   sadm_check_requirements.sh
#   Date        :   2019//03/17
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
#   Developer Web Site : http://www.sadmin.ca
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
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# Version Change Log 
#
# 2019_03_17 New: v1.0 Initial Version.
# 2019_03_20 New: v1.1 Verify if SADMIN requirement are met and -i to install missing requirement.
# 2019_03_29 Update: v1.2 Add 'chkconfig' command requirement if running system using SYSV Init.
# 2019_04_07 Update: v1.3 Use color variables from SADMIN Library.
# 2019_05_16 Update: v1.4 Don't generate the RCH file & allow running multiple instance of script.
# 2019_10_30 Update: v1.5 Remove 'facter' requirement.
#@2019_12_02 Fix: v1.6 Fix Mac OS crash.
#@2020_04_01 Update: v1.7 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
#@2020_04_29 Update: v1.8 Remove arp-scan from the SADMIN server requirement list.
#@2020_11_20 Update: v1.9 Added package 'wkhtmltopdf' installation to server requirement.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # INTERCEPTE LE ^C
#set -x
     


#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    if [ -z "$SADMIN" ]                                 # Test If SADMIN Environment Var. is present
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN Shell Library not readable ?
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # You can use variable below BUT DON'T CHANGE THEM - They are used by SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name with Domain Name

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.9'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#---------------------------------------------------------------------------------------------------
# Value for these variables are taken from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# But they can be overridden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                  # AlertGroup Used for Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # At end of script Trim log to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
SPATH=""                                    ; export SPATH              # Full Path of Command 
INSTREQ=0                                   ; export INSTREQ            # Install Mode default OFF
CHK_SERVER="N"                              ; export CHK_SERVER         # Check Server Req. if "Y"

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
        then sadm_write "Nb. Parameter received by $FUNCNAME function is incorrect.\n"
             sadm_write "Please correct your script - Script Aborted.\n" # Advise User to Correct
             sadm_stop 1                                                 # Prepare exit gracefully
             exit 1                                                      # Terminate the script
    fi
    PACKAGE_RPM=$1                                                       # RedHat/CentOS/Fedora Pkg
    PACKAGE_DEB=$2                                                       # Ubuntu/Debian/Raspian Deb

    case "$package_type"  in
        "rpm" ) if [ "$(sadm_get_osname)" = "FEDORA" ] 
                   then sadm_write "Running \"dnf -y install ${PACKAGE_RPM}\"\n" # Install Command
                        dnf -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List Available update
                        rc=$?                                            # Save Exit Code
                        sadm_write "Return Code after in installation of ${PACKAGE_RPM} is ${rc}.\n"
                   else lmess="Starting installation of ${PACKAGE_RPM} under $(sadm_get_osname)"
                        lmess="${lmess} Version $(sadm_get_osmajorversion)"
                        sadm_write "${lmess}\n"
                        case "$(sadm_get_osmajorversion)" in
                            [567])  sadm_write "Running \"yum -y install ${PACKAGE_RPM}\"\n" # Install Command
                                    yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List Available update
                                    rc=$?                                            # Save Exit Code
                                    sadm_write "Return Code after in installation of ${PACKAGE_RPM} is ${rc}.\n"
                                    ;;
                            [89])   sadm_write "Running \"dnf -y install ${PACKAGE_RPM}\"\n" 
                                    yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List update
                                    rc=$?                                            # Save ExitCode
                                    if [ $rc -ne 0 ] && [ "$PACKAGE_RPM" = "wkhtmltopdf" ]
                                       then sadm_write "Running \"dnf -y install $SADMIN/pkg/wkhtmltopdf/*centos8*\"\n" 
                                            dnf -y install $SADMIN/pkg/wkhtmltopdf/*centos8* >> $SADM_LOG 2>&1
                                            rc=$?
                                    fi 
                                    sadm_write "Return Code after in installation of ${PACKAGE_RPM} is ${rc}.\n"
                                    ;;
                            *)      lmess="The version $(sadm_get_osmajorversion) of"
                                    lmess="${lmess} $(sadm_get_osname) isn't supported at the moment"
                                    sadm_write "${lmess}.\n"
                                    rc=1                                             # Save Exit Code
                                    ;;
                        esac
                fi
                ;;
        "deb" )
                sadm_write "Synchronize package index files.\n"
                sadm_write "Running \"apt-get update\"\n"               # Msg Get package list
                apt-get update > /dev/null 2>&1                         # Get Package List From Repo
                rc=$?                                                   # Save Exit Code
                if [ "$rc" -ne 0 ]
                    then sadm_write "We had problem running the \"apt-get update\" command.\n"
                         sadm_write "We had a return code ${rc}.\n"
                    else sadm_write "Return Code after apt-get update is ${rc}.\n" 
                         sadm_write "Installing the Package ${PACKAGE_DEB} now.\n"
                         sadm_write "apt-get -y install ${PACKAGE_DEB}.\n"
                         apt-get -y install ${PACKAGE_DEB} >>$SADM_LOG 2>&1
                         rc=$?                                          # Save Exit Code
                         sadm_write "Return Code after installation of ${PACKAGE_DEB} is $rc \n"
                fi
                break
                ;;
    esac

    sadm_write "\n"
    return $rc                                                          # 0=Installed 1=Error
}


#===================================================================================================
#  Install EPEL Repository for Redhat / CentOS
#===================================================================================================
add_epel_repo()
{
    SADM_OSVERSION=`lsb_release -sr |awk -F. '{ print $1 }'| tr -d ' '` ; export SADM_OSVERSION 
    
    # Add EPEL Repository on Redhat / CentOS 6 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 6 ] 
        then yum -C repolist | grep "^epel " >/dev/null 2>&1
             if [ $? -ne 0 ] 
                then echo "Adding CentOS/Redhat V6 EPEL repository (Disabled by default) ..." 
                     epel="https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm"
                     yum install -y $epel >/dev/null 2>&1
                     if [ $? -ne 0 ]
                        then echo "${YELLOW}Couldn't add EPEL repos for version ${SADM_OSVERSION}${NORMAL}" 
                             return 1
                    fi 
                    echo "${YELLOW}Disabling EPEL Repository, will activate it only when needed"
                    yum-config-manager --disable epel >/dev/null 2>&1
                    if [ $? -ne 0 ]
                        then echo "${YELLOW}Couldn't disable EPEL for version ${SADM_OSVERSION}${NORMAL}"
                             return 1
                    fi 
                    return 0
             fi
    fi

    # Add EPEL Repository on Redhat / CentOS 7 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 7 ] 
        then yum -C repolist | grep "^epel" >/dev/null 2>&1
             if [ $? -ne 0 ]     
                then echo "Adding CentOS/Redhat V7 EPEL repository (Disabled by default) ..." 
                     epel="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
                     yum install -y $epel >/dev/null 2>&1
                     if [ $? -ne 0 ]
                        then echo "${YELLOW}Couldn't add EPEL repository for version ${SADM_OSVERSION}${NORMAL}" 
                             return 1
                     fi 
                     echo "Disabling EPEL Repository, will activate it only when needed" 
                     yum-config-manager --disable epel >/dev/null 2>&1
                     if [ $? -ne 0 ]
                        then echo "${YELLOW}Couldn't disable EPEL for version ${SADM_OSVERSION}${NORMAL}" 
                             return 1
                     fi 
                     return 0
             fi
    fi

    # Add EPEL Repository on Redhat / CentOS 8 (but do not enable it)
    if [ "$SADM_OSVERSION" -eq 8 ] 
        then yum -C repolist | grep "^epel" >/dev/null 2>&1
             if [ $? -ne 0 ]     
                then echo "Adding CentOS/Redhat V8 EPEL repository (Disabled by default) ..." 
                     epel="https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
                     yum install -y $epel 
                     if [ $? -ne 0 ]
                        then echo "${YELLOW}Couldn't add EPEL repository for version ${SADM_OSVERSION}${NORMAL}" 
                             return 1
                     fi 
                     #
                     rpm -qi dnf-utils >/dev/null 2>&1                          # Is dns-utils installed
                     if [ $? -ne 0 ] 
                        then echo "Installing dnf-utils" 
                             dnf install -y dnf-utils >/dev/null 2>&1
                     fi
                     #
                     echo "Disabling EPEL Repository, will activate it only when needed" 
                     dnf config-manager --set-disabled epel >/dev/null 2>&1
                     if [ $? -ne 0 ]
                        then echo "${YELLOW}Couldn't disable EPEL for version ${SADM_OSVERSION}${NORMAL}"
                             return 1
                     fi 
             fi
    fi
    return 0 
}


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SYSTEM
# IF THE COMMAND EXIST, RETURN 0  -  IF IT DOESN'T EXIST RETURN 1
# --------------------------------------------------------------------------------------------------
command_available() {
    CMD=$1                                                              # Save Parameter received
    printf "Checking availability of command $CMD ... "
    if ${SADM_WHICH} ${CMD} >/dev/null 2>&1                             # Locate command found ?
        then SPATH=`${SADM_WHICH} ${CMD}`                               # Save Path of command
             echo "$SPATH ${GREEN}[OK]${NORMAL}"                        # Show Path to user and OK
             return 0                                                   # Return 0 if cmd found
        else SPATH=""                                                   # PATH empty when Not Avail.
             echo "Missing ${BOLD}${MAGENTA}[Warning]${NORMAL}"         # Show user Warning
    fi
    return 1
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
        "rpm" )     printf "Checking availability of rpm package $RPM_PACK ... " 
                    rpm -q $RPM_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "Package missing ${BOLD}${MAGENTA}[Warning]${NORMAL}" 
                    install_package "$RPM_PACK" "$DEB_PACK" 
                    #
                    printf "Check if install of $RPM_PACK was successful ... " 
                    rpm -q $RPM_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "Package missing ${BOLD}${MAGENTA}[Warning]${NORMAL}" 
                    return 1 
                    ;;

        "deb" )     printf "Checking availability of deb package $DEB_PACK ... " 
                    dpkg -s $DEB_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "Package missing ${BOLD}${MAGENTA}[Warning]${NORMAL}" 
                    install_package "$RPM_PACK" "$DEB_PACK" 
                    #
                    printf "Check if install of $DEB_PACK was successful ... " 
                    dpkg -s $DEB_PACK >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then echo "${GREEN}[OK]${NORMAL}" ; return 0 ; fi
                    echo "Package missing ${BOLD}${MAGENTA}[Warning]${NORMAL}" 
                    return 1 
                    ;;
        *)          printf "Package type $package+type is not supported yet" 
                    ;;
    esac
    return 0
}


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
check_sadmin_requirements() {
    sadm_write "${WHITE}${BOLD}SADMIN client requirements${NORMAL}\n"

    # The 'which' command is needed to determine presence of command - Return Error if not found
    if which which >/dev/null 2>&1                                      # Try the command which
        then SADM_WHICH=`which which`  ; export SADM_WHICH              # Save Path of Which Command
        else sadm_write "[ERROR] The command 'which' couldn't be found.\n"
             sadm_write "        This program is often used by the SADMIN tools.\n"
             sadm_write "        Please install it and re-run this script.\n"
             sadm_write "        *** Script Aborted.\n"
             return 1                                                   # Return Error to Caller
    fi

    # Special consideration for nmon on Aix 5.x & 6.x (After that it is included as part of O/S ----
    if [ "$(sadm_get_ostype)" = "AIX" ]                                 # Under Aix O/S
       then command_available "nmon"                                    # Get nmon cmd path   
            SADM_NMON="$SPATH"                                          # Save Path Returned
            if [ "$SADM_NMON" = "" ]                                    # If Command not found
               then NMON_WDIR="${SADM_PKG_DIR}/nmon/aix/"               # Where Aix nmon exec are
                    NMON_EXE="nmon_aix$(sadm_get_osmajorversion)$(sadm_get_osminorversion)"
                    NMON_USE="${NMON_WDIR}${NMON_EXE}"                  # Use exec. of your version
                    if [ ! -x "$NMON_USE" ]                             # nmon exist and executable
                        then sadm_write "'nmon' for AIX $(sadm_get_osversion) isn't available.\n"
                             sadm_write "The nmon executable we need is ${NMON_USE}.\n"
                        else sadm_write "ln -s ${NMON_USE} /usr/bin/nmon\n"
                             ln -s ${NMON_USE} /usr/bin/nmon            # Link nmon avail to user
                             if [ $? -eq 0 ] ; then SADM_NMON="/usr/bin/nmon" ; fi # Set SADM_NMON
                    fi
            fi
    fi

    # Get Command path for Linux O/S ---------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # Under Linux O/S
       then 
            command_available "lsb_release" ; SADM_LSB_RELEASE=$SPATH   # Save Command Path Returned
            if [ "$SADM_LSB_RELEASE" = "" ] && [ "$INSTREQ" -eq 1 ]     # Cmd not found & Inst Req.
                then install_package "redhat-lsb-core" "lsb-release"    # Install Package (rpm,deb)
                     command_available "lsb_release" ; SADM_LSB_RELEASE=$SPATH   
            fi

            command_available "dmidecode"   ; SADM_DMIDECODE=$SPATH     # Save Command Path Returned
            if [ "$SADM_DMIDECODE" = "" ] && [ "$INSTREQ" -eq 1 ]       # Cmd not found & Inst Req.
                then install_package "dmidecode" "dmidecode"            # Install Package (rpm,deb)
                     command_available "dmidecode" ; SADM_DMIDECODE=$SPATH   
            fi

            command_available "nmon"        ; SADM_NMON=$SPATH          # Save Command Path Returned
            if [ "$SADM_NMON" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "--enablerepo=epel nmon" "nmon"    # Install Package (rpm,deb)
                     command_available "nmon" ; SADM_NMON=$SPATH        # Recheck Should be install
            fi

            command_available "ethtool"     ; SADM_ETHTOOL=$SPATH       # Save Command Path Returned
            if [ "$SADM_NMON" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req. 
                then install_package "ethtool" "ethtool"                # Install Package (rpm,deb)
                     command_available "ethtool" ; SADM_ETHTOOL=$SPATH  # Recheck Should be install
            fi

            if [ $SYSTEMD -ne 1 ]                                       # Using Sysinit
                then command_available "chkconfig" ; SADM_CHKCONFIG=$SPATH # Save Cmd Path Returned
                     if [ "$SADM_CHKCONFIG" = "" ] && [ "$INSTREQ" -eq 1 ] # Not found = Inst Req. 
                        then install_package "chkconfig" "chkconfig"       # Install Pack (rpm,deb)
                             command_available "chkconfig" ; SADM_CHKCONFIG=$SPATH  # Recheck 
                     fi
            fi

            command_available "sudo"     ; SADM_SUDO=$SPATH             # Save Command Path Returned
            if [ "$SADM_SUDO" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "sudo" "sudo"                      # Install Package (rpm,deb)
                     command_available "sudo"     ; SADM_SUDO=$SPATH    # Recheck Should be install
            fi

            command_available "lshw"     ; SADM_LSHW=$SPATH             # Save Command Path Returned
            if [ "$SADM_LSHW" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "lshw" "lshw"                      # Install Package (rpm,deb)
                     command_available "lshw"     ; SADM_LSHW=$SPATH    # Recheck Should be install
            fi

            command_available "ifconfig"     ; SADM_IFCONFIG=$SPATH     # Save Command Path Returned
            if [ "$SADM_IFCONFIG" = "" ] && [ "$INSTREQ" -eq 1 ]        # Cmd not found & Inst Req.
                then install_package "net-tools" "net-tools"            # Install Package (rpm,deb)
                     command_available "ifconfig" ;SADM_IFCONFIG=$SPATH # Recheck Should be install
            fi

            command_available "iostat"     ; SADM_IOSTAT=$SPATH         # Save Command Path Returned
            if [ "$SADM_IOSTAT" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "sysstat" "sysstat"                # Install Package (rpm,deb)
                     command_available "iostat"  ; SADM_IOSTAT=$SPATH   # Recheck Should be install
            fi

            command_available "parted"      ; SADM_PARTED=$SPATH        # Save Command Path Returned
            if [ "$SADM_PARTED" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "parted" "parted"                  # Install Package (rpm,deb)
                     command_available "parted" ; SADM_PARTED=$SPATH    # Recheck Should be install
            fi

            command_available "mutt"        ; SADM_MUTT=$SPATH          # Save Command Path Returned
            if [ "$SADM_MUTT" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "parted" "parted"                  # Install Package (rpm,deb)
                     command_available "mutt"  ; SADM_MUTT=$SPATH       # Recheck Should be install
            fi

            command_available "gawk"        ; SADM_GAWK=$SPATH          # Save Command Path Returned
            if [ "$SADM_GAWK" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "gawk" "gawk"                      # Install Package (rpm,deb)
                     command_available "gawk"  ; SADM_GAWK=$SPATH       # Recheck Should be install
            fi

            command_available "curl"        ; SADM_CURL=$SPATH          # Save Command Path Returned
            if [ "$SADM_CURL" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then install_package "curl" "curl"                      # Install Package (rpm,deb)
                     command_available "curl"  ; SADM_CURL=$SPATH       # Recheck Should be install
            fi

            command_available "lscpu"       ; SADM_LSCPU=$SPATH         # Save Command Path Returned
            if [ "$SADM_LSCPU" = "" ] && [ "$INSTREQ" -eq 1 ]           # Cmd not found & Inst Req.
                then install_package "util-linux" "util-linux"          # Install Package (rpm,deb)
                     command_available "lscpu" ; SADM_LSCPU=$SPATH      # Recheck Should be install
            fi
            
            command_available "fdisk"       ; SADM_FDISK=$SPATH         # Save Command Path Returned
            if [ "$SADM_FDISK" = "" ] && [ "$INSTREQ" -eq 1 ]           # Cmd not found & Inst Req.
                then install_package "util-linux" "util-linux"          # Install Package (rpm,deb)
                     command_available "fdisk"  ; SADM_FDISK=$SPATH     # Recheck Should be install
            fi

            # Check if Package is installed, if option (-i) is set then install it.
            package_available "perl-libwww-perl" "libwww-perl"         #  Check if Perl Package Inst
    fi


    # Get Command path for All supported O/S -------------------------------------------------------
    command_available "perl"        ; SADM_PERL=$SPATH                  # Save Command Path Returned
    if [ "$SADM_PERL" = "" ] && [ "$INSTREQ" -eq 1 ]                    # Cmd not found & Inst Req.
        then install_package "perl" "perl-base"                         # Install Package (rpm,deb)
             command_available "perl"  ; SADM_PERL=$SPATH               # Recheck Should be install
    fi    
    
    command_available "ssh"         ; SADM_SSH=$SPATH                   # Save Command Path Returned
    if [ "$SADM_SSH" = "" ] && [ "$INSTREQ" -eq 1 ]                     # Cmd not found & Inst Req.
        then install_package "openssh-clients" "openssh-client"         # Install Package (rpm,deb)
             command_available "ssh"         ; SADM_SSH=$SPATH          # Recheck Should be install
    fi    

    command_available "mail"        ; SADM_MAIL=$SPATH                  # Save Command Path Returned
    if [ "$SADM_MAIL" = "" ] && [ "$INSTREQ" -eq 1 ]                    # Cmd not found & Inst Req.
        then install_package "mailx" "mailutils"                        # Install Package (rpm,deb)
             command_available "mail"        ; SADM_MAIL=$SPATH         # Recheck Should be install
    fi    

    command_available "bc"          ; SADM_BC=$SADM_BC                  # Save Command Path Returned
    if [ "$SADM_BC" = "" ] && [ "$INSTREQ" -eq 1 ]                      # Cmd not found & Inst Req.
        then install_package "bc" "bc"                                  # Install Package (rpm,deb)
             command_available "bc"          ; SADM_BC=$SADM_BC         # Recheck Should be install
    fi    

    command_available "python3"  ; SADM_PYTHON3=$SPATH                  # Save Command Path Returned
    if [ "$SADM_PYTHON3" = "" ] && [ "$INSTREQ" -eq 1 ]                 # Cmd not found & Inst Req.
        then install_package "--enablerepo=epel python34 python34-setuptools python34-pip" "python3" 
             command_available "python3"  ; SADM_PYTHON3=$SPATH         # Recheck Should be install
    fi    

    # If on the SADMIN Server mysql MUST be present - Check Availibility of the mysql command.
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ] || [ "$CHK_SERVER" = "Y" ] # Check Server Req.
        then sadm_write "\n${WHITE}${BOLD}SADMIN server requirements.${NORMAL}\n"
             command_available "mysql" ; SADM_MYSQL=$SPATH              # Get mysql cmd path  
             if [ "$SADM_MYSQL" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "mariadb-server " "mariadb-server mariadb-client"  
                     command_available "mysql" ; SADM_MYSQL=$SPATH      # Recheck Should be install 
             fi    
             command_available "rrdtool" ; SADM_RRDTOOL=$SPATH          # Get  cmd path  
             if [ "$SADM_RRDTOOL" = "" ] && [ "$INSTREQ" -eq 1 ]        # Cmd not found & Inst Req.
                then install_package "rrdtool" "rrdtool"                # Install package
                     command_available "rrdtool" ; SADM_RRDTOOL=$SPATH  # Recheck Should be install
             fi        
             command_available "fping" ; SADM_FPING=$SPATH              # Get  cmd path  
             if [ "$SADM_FPING" = "" ] && [ "$INSTREQ" -eq 1 ]          # Cmd not found & Inst Req.
                then install_package "--enablerepo=epel fping" "fping monitoring-plugins-standard" 
                     command_available "fping" ; SADM_FPING=$SPATH      # Recheck Should be install
             fi    
             #command_available "arp-scan" ; SADM_ARPSCAN=$SPATH        # Get  cmd path  
             #if [ "$SADM_ARPSCAN" = "" ] && [ "$INSTREQ" -eq 1 ]       # Cmd not found & Inst Req.
             #   then install_package "--enablerepo=epel arp-scan" "arp-scan" # Install package
             #        command_available "arp-scan" ; SADM_ARPSCAN=$SPATH # Recheck Should be install
             #fi    
             command_available "pip3" ; SADM_PIP3=$SPATH                # Get cmd path  
             if [ "$SADM_PIP3" = "" ] && [ "$INSTREQ" -eq 1 ]           # Cmd not found & Inst Req.
                then install_package "python3-pip" "python3-pip"        # Install package
                     if [ $? -ne 0 ]                                    # Normal Install not working
                        then install_package "--enablerepo=epel python34-pip" "python3-pip" 
                     fi 
                     command_available "pip3" ; SADM_PIP3=$SPATH        # Recheck Should be install
             fi    
             command_available "wkhtmltopdf" ; SADM_WKHTMLTOPDF=$SPATH  # Get cmd path  
             if [ "$SADM_WKHTMLTOPDF" = "" ] && [ "$INSTREQ" -eq 1 ]    # Cmd not found & Inst Req.
                then install_package "wkhtmltopdf" "wkhtmltopdf"        # Install package (rpm,deb)
                     if [ $? -ne 0 ] 
                        then install_package "--enablerepo=epel wkhtmltopdf" "wkhtmltopdf"
                     fi 
                     command_available "wkhtmltopdf" ; SADM_WKHTMLTOPDF=$SPATH # Recheck if install
             fi    
             command_available "php" ; SADM_PHP=$SPATH                  # Get  cmd path  
             if [ "$SADM_PHP" = "" ] && [ "$INSTREQ" -eq 1 ]            # Cmd not found & Inst Req.
                then rpmpkg="php php-common php-cli php-mysqlnd php-mbstring"
                     debpkg="php php-mysql php-common php-cli"
                     install_package  "$rpmpkg" "$debpkg"
                     command_available "php" ; SADM_PHP=$SPATH          # Recheck Should be install
             fi    
             if [ "$(sadm_get_packagetype)" = "rpm" ]                   # Check HTTPD RPM
                then command_available "httpd" ; SADM_HTTPD=$SPATH      # Get  cmd path  
                     if [ "$SADM_HTTPD" = "" ] && [ "$INSTREQ" -eq 1 ]  # Cmd not found & Inst Req.
                        then install_package "httpd httpd-tools" " "    # Install package
                             command_available "httpd" ; SADM_HTTPD=$SPATH  # Recheck Should be inst
                     fi  
             fi
             if [ "$(sadm_get_packagetype)" = "deb" ]                   # Check HTTPD RPM
                then command_available "apache2" ; SADM_APACHE2=$SPATH  # Get  cmd path  
                     if [ "$SADM_APACHE2" = "" ] && [ "$INSTREQ" -eq 1 ] # Cmd not found & Inst Req.
                        then install_package " " "apache2 apache2-utils libapache2-mod-php" 
                             command_available "apache2" ; SADM_APACHE2=$SPATH 
                     fi  
             fi    
    fi
    return 0
}



#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    check_sadmin_requirements
    SADM_EXIT_CODE=$?

    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}


# --------------------------------------------------------------------------------------------------
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
               if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ]
                   then add_epel_repo
               fi 
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


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
