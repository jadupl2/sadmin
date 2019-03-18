#! /usr/bin/env sh
#---------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.sh
#   Date        :   YYYY/MM/DD
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Check if all SADMIN Tools requirement are met.
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <jacques.duplessis@sadmin.ca>.
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
#@2019_03_17 New: v1.0 Initial Version.
#
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
    export SADM_VER='1.1'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

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
INSTALL_MODE=0                              ; export INSTALL_MODE       # Install Mode default OFF
SADM_OSVERSION=""                           ; export SADM_OSVERSION     # O/S System Major Version#
SADM_OSVERSION=`lsb_release -sr |awk -F. '{ print $1 }'| tr -d ' '`     # Use lsb_release 2 Get Ver

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
    printf "\n\n" 
}
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
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
        then sadm_writelog "Nb. Parameter received by $FUNCNAME function is incorrect"
             sadm_writelog "Please correct your script - Script Aborted" # Advise User to Correct
             sadm_stop 1                                                 # Prepare exit gracefully
             exit 1                                                      # Terminate the script
    fi
    PACKAGE_RPM=$1                                                       # RedHat/CentOS/Fedora Pkg
    PACKAGE_DEB=$2                                                       # Ubuntu/Debian/Raspian Deb

    # Add EPEL Repository on RedHat, CentOS 
    if [ "$(sadm_get_osname)" == "REDHAT" ] || [ "$(sadm_get_osname)" == "CENTOS" ]
        then add_epel_repo
    fi 

    case "$(sadm_get_osname)"  in
        "REDHAT"|"CENTOS"|"FEDORA" )
                lmess="Starting installation of ${PACKAGE_RPM} under $(sadm_get_osname)"
                lmess="${lmess} Version $(sadm_get_osmajorversion)"
                sadm_writelog "$lmess"
                case "$(sadm_get_osmajorversion)" in
                    [34])   sadm_writelog "Running \"up2date --nox -i ${PACKAGE_RPM}\""
                            up2date --nox -i ${PACKAGE_RPM} >>$SADM_LOG 2>&1
                            rc=$?
                            sadm_writelog "Return Code after installing ${PACKAGE_RPM} is $rc"
                            break
                            ;;
                    [567])  sadm_writelog "Running \"yum -y install ${PACKAGE_RPM}\"" # Install Command
                            yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List Available update
                            rc=$?                                            # Save Exit Code
                            sadm_writelog "Return Code after in installation of ${PACKAGE_RPM} is $rc"
                            break
                            ;;
                    *)      lmess="The version $(sadm_get_osmajorversion) of"
                            lmess="${lmess} $(sadm_get_osname) isn't supported at the moment"
                            sadm_writelog "$lmess"
                            rc=1                                             # Save Exit Code
                            break
                            ;;
                esac
                break
                ;;
        "UBUNTU"|"DEBIAN"|"RASPBIAN"|"LINUXMINT" )
                sadm_writelog "Resynchronize package index files from their sources via Internet"
                sadm_writelog "Running \"apt-get update\""                 # Msg Get package list
                apt-get update > /dev/null 2>&1                            # Get Package List From Repo
                rc=$?                                                      # Save Exit Code
                if [ "$rc" -ne 0 ]
                    then sadm_writelog "We had problem running the \"apt-get update\" command"
                         sadm_writelog "We had a return code $rc"
                    else sadm_writelog "Return Code after apt-get update is $rc"  # Show  Return Code
                         sadm_writelog "Installing the Package ${PACKAGE_DEB} now"
                         sadm_writelog "apt-get -y install ${PACKAGE_DEB}"
                         apt-get -y install ${PACKAGE_DEB}
                         rc=$?                                              # Save Exit Code
                         sadm_writelog "Return Code after installation of ${PACKAGE_DEB} is $rc"
                fi
                break
                ;;
    esac

    sadm_writelog " "
    return $rc                                                          # 0=Installed 1=Error
}


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


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SYSTEM
# IF THE COMMAND EXIST, RETURN 0  -  IF IT DOESN'T EXIST RETURN 1
# --------------------------------------------------------------------------------------------------
command_available() {
    CMD=$1                                                              # Save Parameter received
    printf "Checking availability of command $CMD ... "
    if ${SADM_WHICH} ${CMD} >/dev/null 2>&1                             # Locate command found ?
        then SPATH=`${SADM_WHICH} ${CMD}`                               # Save Path of command
             echo "$SPATH [OK]"                                         # Show Path to user and OK
             return 0                                                   # Return 0 if cmd found
        else SPATH=""                                                   # PATH empty when Not Avail.
             echo "Command missing [Warning]"                           # Show user Warning
    fi
    return 1
}


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
check_sadmin_requirements() {
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_writelog "sadm_check_requirement" ; fi


    # The 'which' command is needed to determine presence of command - Return Error if not found
    if which which >/dev/null 2>&1                                      # Try the command which
        then SADM_WHICH=`which which`  ; export SADM_WHICH              # Save Path of Which Command
        else sadm_writelog "[ERROR] The command 'which' couldn't be found"
             sadm_writelog "        This program is often used by the SADMIN tools"
             sadm_writelog "        Please install it and re-run this script"
             sadm_writelog "        *** Script Aborted"
             return 1                                                   # Return Error to Caller
    fi

    # Special consideration for nmon on Aix 5.x & 6.x (After that it is included as part of O/S ----
    if [ "$(sadm_get_ostype)" = "AIX" ]                                 # Under Aix O/S
       then SADM_NMON=$(command_available "nmon")                   # Get nmon cmd path   
            if [ "$SADM_NMON" = "" ]                                    # If Command not found
               then NMON_WDIR="${SADM_PKG_DIR}/nmon/aix/"               # Where Aix nmon exec are
                    NMON_EXE="nmon_aix$(sadm_get_osmajorversion)$(sadm_get_osminorversion)"
                    NMON_USE="${NMON_WDIR}${NMON_EXE}"                  # Use exec. of your version
                    if [ ! -x "$NMON_USE" ]                             # nmon exist and executable
                        then sadm_writelog "'nmon' for AIX $(sadm_get_osversion) isn't available"
                             sadm_writelog "The nmon executable we need is $NMON_USE"
                        else sadm_writelog "ln -s ${NMON_USE} /usr/bin/nmon"
                             ln -s ${NMON_USE} /usr/bin/nmon            # Link nmon avail to user
                             if [ $? -eq 0 ] ; then SADM_NMON="/usr/bin/nmon" ; fi # Set SADM_NMON
                    fi
            fi
    fi

    # Get Command path for Linux O/S ---------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # Under Linux O/S
       then 
            command_available "lsb_release" ; SADM_LSB_RELEASE=$SPATH   # Save Command Path Returned
            if [ "$SADM_LSB_RELEASE" = "" ]                             # If Command not found
                then install_package "redhat-lsb-core" "lsb-release"    # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_LSB_RELEASE=$(check_availability "lsb_release") ;fi
            fi

            command_available "dmidecode"   ; SADM_DMIDECODE=$SPATH     # Save Command Path Returned
            if [ "$SADM_DMIDECODE" = "" ]                               # If Command not found
                then install_package "dmidecode" "dmidecode"            # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_DMIDECODE=$(check_availability "dmidecode") ;fi
            fi

            command_available "nmon"        ; SADM_NMON=$SPATH          # Save Command Path Returned
            if [ "$SADM_NMON" = "" ]                                    # If Command not found
                then install_package "nmon" "nmon"                      # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_NMON=$(check_availability "nmon") ;fi
            fi

            command_available "ethtool"     ; SADM_ETHTOOL=$SPATH       # Save Command Path Returned
            if [ "$SADM_NMON" = "" ]                                    # If Command not found
                then install_package "ethtool" "ethtool"                # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_NMON=$(check_availability "ethtool") ;fi
            fi

            command_available "sudo"     ; SADM_SUDO=$SPATH             # Save Command Path Returned
            if [ "$SADM_SUDO" = "" ]                                    # If Command not found
                then install_package "sudo" "sudo"                      # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_SUDO=$(check_availability "sudo") ;fi
            fi

            command_available "lshw"     ; SADM_LSHW=$SPATH             # Save Command Path Returned
            if [ "$SADM_LSHW" = "" ]                                    # If Command not found
                then install_package "lshw" "lshw"                      # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_LSHW=$(check_availability "lshw") ;fi
            fi

            command_available "ifconfig"     ; SADM_IFCONFIG=$SPATH     # Save Command Path Returned
            if [ "$SADM_IFCONFIG" = "" ]                                # If Command not found
                then install_package "net-tools" "net-tools"            # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_IFCONFIG=$(check_availability "ifconfig") ;fi
            fi

            command_available "iostat"     ; SADM_IOSTAT=$SPATH         # Save Command Path Returned
            if [ "$SADM_IOSTAT" = "" ]                                  # If Command not found
                then install_package "sysstat" "sysstat"                # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_IOSTAT=$(check_availability "iostat") ;fi
            fi

            command_available "parted"      ; SADM_PARTED=$SPATH        # Save Command Path Returned
            if [ "$SADM_PARTED" = "" ]                                  # If Command not found
                then install_package "parted" "parted"                  # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_PARTED=$(check_availability "parted") ;fi
            fi

            command_available "mutt"        ; SADM_MUTT=$SPATH          # Save Command Path Returned
            if [ "$SADM_MUTT" = "" ]                                    # If Command not found
                then install_package "parted" "parted"                  # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_MUTT=$(check_availability "mutt") ;fi
            fi

            command_available "gawk"        ; SADM_GAWK=$SPATH          # Save Command Path Returned
            if [ "$SADM_GAWK" = "" ]                                    # If Command not found
                then install_package "gawk" "gawk"                      # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_GAWK=$(check_availability "gawk") ;fi
            fi

            command_available "curl"        ; SADM_CURL=$SPATH          # Save Command Path Returned
            if [ "$SADM_CURL" = "" ]                                    # If Command not found
                then install_package "curl" "curl"                      # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_CURL=$(check_availability "curl") ;fi
            fi

            command_available "lscpu"       ; SADM_LSCPU=$SPATH         # Save Command Path Returned
            if [ "$SADM_LSCPU" = "" ]                                   # If Command not found
                then install_package "util-linux" "util-linux"          # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_CURL=$(check_availability "lscpu") ;fi
            fi
            
            command_available "fdisk"       ; SADM_FDISK=$SPATH         # Save Command Path Returned
            if [ "$SADM_FDISK" = "" ]                                   # If Command not found
                then install_package "util-linux" "util-linux"          # Install Package (rpm,deb)
                     if [ $? -eq 0 ] ; then SADM_FDISK=$(check_availability "curl") ;fi
            fi
    fi


    # Get Command path for All supported O/S -------------------------------------------------------
    command_available "perl"        ; SADM_PERL=$SPATH                  # Save Command Path Returned
    if [ "$SADM_PERL" = "" ]                                            # If Command not found
        then install_package "perl" "perl-base"                         # Install Package (rpm,deb)
             if [ $? -eq 0 ] ; then SADM_PERL=$(check_availability "perl") ;fi
    fi    
    
    command_available "ssh"         ; SADM_SSH=$SPATH                   # Save Command Path Returned
    if [ "$SADM_SSH" = "" ]                                             # If Command not found
        then install_package "openssh-clients" "openssh-client"         # Install Package (rpm,deb)
             if [ $? -eq 0 ] ; then SADM_SSH=$(check_availability "ssh") ;fi
    fi    

    command_available "mail"        ; SADM_MAIL=$SPATH                  # Save Command Path Returned
    if [ "$SADM_MAIL" = "" ]                                            # If Command not found
        then install_package "mailx" "mailutils"                        # Install Package (rpm,deb)
             if [ $? -eq 0 ] ; then SADM_MAIL=$(check_availability "mail") ;fi
    fi    

    command_available "bc"          ; SADM_BC=$SADM_BC                  # Save Command Path Returned
    if [ "$SADM_BC" = "" ]                                              # If Command not found
        then install_package "bc" "bc"                                  # Install Package (rpm,deb)
             if [ $? -eq 0 ] ; then SADM_BC=$(check_availability "bc") ;fi
    fi    

    command_available "facter"      ; SADM_FACTER=$SPATH                # Save Command Path Returned
    if [ "$SADM_FACTER" = "" ]                                          # If Command not found
        then install_package "facter" "facter"                          # Install Package (rpm,deb)
             if [ $? -eq 0 ] ; then SADM_FACTER=$(check_availability "facter") ;fi
    fi    

    # If on the SADMIN Server mysql MUST be present - Check Availibility of the mysql command.
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]                          # Only Check on SADMIN Srv
        then command_available "mysql" ; SADM_MYSQL=$SPATH              # Get mysql cmd path  
             if [ "$SADM_MYSQL" = "" ]                                  # If Command not found
                then install_package "mariadb-server " "mariadb-server mariadb-client"  
                     if [ $? -eq 0 ] ; then SADM_MYSQL=$(check_availability "mysql") ;fi
             fi    
             command_available "rrdtool" ; SADM_RRDTOOL=$SPATH          # Get  cmd path  
             if [ "$SADM_RRDTOOL" = "" ]                                # If Command not found
                then install_package "rrdtool" "rrdtool"                # Install package
                     if [ $? -eq 0 ] ; then SADM_RRDTOOL=$(check_availability "rrdtool") ;fi
             fi        
             command_available "fping" ; SADM_FPING=$SPATH              # Get  cmd path  
             if [ "$SADM_FPING" = "" ]                                  # If Command not found
                then install_package "fping" "fping monitoring-plugins-standard" # Install package
                     if [ $? -eq 0 ] ; then SADM_FPING=$(check_availability "fping") ;fi
             fi    
             command_available "arp-scan" ; SADM_ARPSCAN=$SPATH         # Get  cmd path  
             if [ "$SADM_ARPSCAN" = "" ]                                # If Command not found
                then install_package "arp-scan" "arp-scan"              # Install package
                     if [ $? -eq 0 ] ; then SADM_ARPSCAN=$(check_availability "arp-scan") ;fi
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


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,
# (-d0-9] Set Debug Level, (-i) install missing package
    while getopts "hvid:" opt ; do                                      # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$DEBUG_LEVEL" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            i) INSTALL_MODE=1                                           # Install Mode default ON
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi

    # Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

# Your Main process procedure
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 

# SADMIN Closing procedure - Close/Trim log and rch file, Remove PID File, Remove TMP files ...
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    