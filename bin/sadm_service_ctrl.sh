#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_service.sh
#   Version  :  1.6
#   Date     :  7 Juin 2017
#   Requires :  sh
#   Synopsis :  Script to enable/disable/status SADM Service
#               If SADM Service is enable, at system startup/shutdown above scripts are executed
#                   - At System startup  : $SADMIN/sys/sadm_startup.sh
#                   - At System shutdown : $SADMIN/sys/sadm_shutdown.sh 
#               When disable these scripts are not executed.
#               You can get the status of SADMIN service
# 
#               sadm_service.sh usage :"
#                   -e   (Enable SADM Service)
#                   -d   (Disable SADM Service)
#                   -s   (Display Status of SADM Service)
#                   -h   (Display this help message)
#                   -v   (Show Script and Library Version)
#
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# --------------------------------------------------------------------------------------------------
# Change Log
#
# 2017_06_06    v1.6 Initial Version
# 2017_07_07    v1.7 Corrections for System V service
# 2017_07_08    v1.8 Add '-s' switch to display sadmin service status
# 2017_07_09    v1.9 Modify Help Message
# 2017_08_03    v1.10 Added a Stop Service beore the start (eliminate problem)
# 2018_01_12    v1.11 Add Synopsis - Update SADM Tools section
# 2018_02_08    v1.12 Correct compatibility problem with 'dash' shell (Debian, Ubuntu, Raspbian)
# 2018_06_06    v2.0 Restructure Code & Adapt to new SADMIN Shell Libr.
# 2018_06_23    v2.1 Change Location of default file for Systemd and InitV SADMIN service to cfg
# 2018_10_18    v2.2 Prevent Error Message don't display status after disabling the service
#@2019_03_27 Fix: v2.3 Making sure InitV sadmin service script is executable.
#@2019_03_28 Fix: v2.4 Was not executing shutdown script under RHEL/CentOS 4,5
#@2019_03_29 Update: v2.5 Major Revamp - Re-Tested - SysV and SystemD
#@2019_03_30 Update: v2.6 Added message when enabling/disabling sadmin service.
#@2019_04_07 Update: v2.7 Use color variables from SADMIN Library.
#@2019_12_27 Update: v2.8 Was exiting with error when using options '-h' or '-v'.
#@2020_09_10 Update: v2.9 Minor code improvement.
#--------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x
 



#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "\n'SADMIN' Environment variable was temporarily set to ${SADMIN}.\n"
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='2.9'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writ#set -x
    export SADM_LOG_APPEND="Y"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="N"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="N"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # At the end Trim log to 500 Lines(0=NoTrim)
    #export SADM_MAX_RCLINE=35                          # At the end Trim rch to 35 Lines (0=NoTrim)
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
#
command -v systemctl > /dev/null 2>&1                                   # Using sysinit or systemd ?
if [ $? -eq 0 ] ; then SYSTEMD=1 ; else SYSTEMD=0 ; fi                  # Set SYSTEMD Accordingly
export SYSTEMD                                                          # Export Result        
#
# Systemd Ini File
SADM_SRV_IFILE="${SADM_CFG_DIR}/.sadmin.service"    ; export SADM_SRV_IFILE  # Input Srv File
SADM_SRV_OFILE="/etc/systemd/system/sadmin.service" ; export SADM_SRV_OFILE  # Output Dest. Srv File
#
# SysV Init File
SADM_INI_IFILE="${SADM_CFG_DIR}/.sadmin.rc"         ; export SADM_INI_IFILE  # Input Srv File
SADM_INI_OFILE="/etc/init.d/sadmin"                 ; export SADM_INI_OFILE  # Output Dest. Srv File






# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-e   (Enable SADM Service)"
    printf "\n\t-d   (Disable SADM Service)"
    printf "\n\t-s   (Display Status of SADM Service)"
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
# THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SYSTEM
# IF THE COMMAND EXIST, RETURN 0  -  IF IT DOESN'T EXIST RETURN 1
# --------------------------------------------------------------------------------------------------
command_available() {
    CMD=$1                                                              # Save Parameter received
    printf "Checking availability of command $CMD ... "
    if which ${CMD} >/dev/null 2>&1                                     # Locate command found ?
        then SPATH=`which ${CMD}`                                       # Save Path of command
             echo "$SPATH ${SADM_OK}"                                   # Show Path to user and OK
             return 0                                                   # Return 0 if cmd found
        else SPATH=""                                                   # PATH empty when Not Avail.
             echo "Command missing ${SADM_WARNING}" 
    fi
    return 1
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

    case "$package_type"  in
        "rpm" )
                lmess="Starting installation of ${PACKAGE_RPM} under $(sadm_get_osname)"
                lmess="${lmess} Version $(sadm_get_osmajorversion)"
                sadm_writelog "$lmess"
                case "$(sadm_get_osmajorversion)" in
                    [567])  sadm_writelog "Running \"yum -y install ${PACKAGE_RPM}\"" # Install Command
                            yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List Available update
                            rc=$?                                            # Save Exit Code
                            sadm_writelog "Return Code after in installation of ${PACKAGE_RPM} is $rc"
                            break
                            ;;
                    [8])    sadm_writelog "Running \"yum -y install ${PACKAGE_RPM}\"" # Install Command
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
        "deb" )
                sadm_writelog "Synchronize package index files"
                sadm_writelog "Running \"apt-get update\""                 # Msg Get package list
                apt-get update > /dev/null 2>&1                            # Get Package List From Repo
                rc=$?                                                      # Save Exit Code
                if [ "$rc" -ne 0 ]
                    then sadm_writelog "We had problem running the \"apt-get update\" command"
                         sadm_writelog "We had a return code $rc"
                    else sadm_writelog "Return Code after apt-get update is $rc"  # Show  Return Code
                         sadm_writelog "Installing the Package ${PACKAGE_DEB} now"
                         sadm_writelog "apt-get -y install ${PACKAGE_DEB}"
                         apt-get -y install ${PACKAGE_DEB} >>$SADM_LOG 2>&1
                         rc=$?                                              # Save Exit Code
                         sadm_writelog "Return Code after installation of ${PACKAGE_DEB} is $rc"
                fi
                break
                ;;
    esac

    sadm_writelog " "
    return $rc                                                          # 0=Installed 1=Error
}

# ==================================================================================================
#                               Disable SADM Service
# ==================================================================================================
service_disable()
{
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then printf "systemctl disable ${1}.service..."                 # Show User cmd executed
             systemctl disable "${1}.service" >>$SADM_LOG 2>&1          # use systemctl to disable
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
             
             printf "rm -f $SADM_SRV_OFILE ..."                         # Show user cmd executed
             rm -f $SADM_SRV_OFILE >> $SADM_LOG 2>&1         # rm /etc/systemd/system/sadmin.service
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

             systemctl list-unit-files | grep $1 >> $SADM_LOG 2>&1      # Display Service Status
             return
    fi

    if [ $SYSTEMD -ne 1 ]                                               # Using Sysinit
        then printf "chkconfig $1 off ... "
             chkconfig $1 off    >> $SADM_LOG 2>&1                      # disable service
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
             
             printf "chkconfig --del $1 ... "
             chkconfig --del $1     >> $SADM_LOG 2>&1                   # disable service
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
             
             printf "Remove service file $SADM_INI_OFILE ... " 
             rm -f $SADM_INI_OFILE >> $SADM_LOG 2>&1
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
    fi
    return 0
}



# ==================================================================================================
#                               Enable Linux Service
# ==================================================================================================
service_enable()
{
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd 
        then printf "cp $SADM_SRV_IFILE $SADM_SRV_OFILE ... "           # write cmd to execute
             cp $SADM_SRV_IFILE $SADM_SRV_OFILE >> $SADM_LOG 2>&1       # Put in Place Service file
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

             printf "systemctl enable ${1}.service ... "                # write cmd to execute
             systemctl enable "${1}.service" >> $SADM_LOG 2>&1          # use systemctl
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
    fi

    if [ $SYSTEMD -ne 1 ]                                               # Using Sysinit
        then printf "cp $SADM_INI_IFILE $SADM_INI_OFILE ... "           # write cmd to log
             cp $SADM_INI_IFILE $SADM_INI_OFILE >> $SADM_LOG 2>&1       # Put in Place Service file
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

             printf "chmod 755 $SADM_INI_OFILE ... "                    # Make service script exec.
             chmod 755 $SADM_INI_OFILE >> $SADM_LOG 2>&1                # Make service script exec.
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

             printf "chown root:root $SADM_INI_OFILE ..."
             chown root:root $SADM_INI_OFILE >> $SADM_LOG 2>&1          # Make service owned by root
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

             printf "chkconfig -add ${1} ..."                           # write cmd to log
             chkconfig --add ${1}  >> $SADM_LOG 2>&1                    # enable service
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

             printf "chkconfig $1 on ..."                               # write cmd to log
             chkconfig $1 on    >> $SADM_LOG 2>&1                       # enable service
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
    fi
    return
}



# ==================================================================================================
#                               Status of Linux Service
# ==================================================================================================
service_status()
{
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then sadm_write "systemctl status ${1}.service ... "            # write cmd to log
             systemctl status ${1}.service >> $SADM_LOG 2>&1            # use systemctl
             if [ $? -eq 0 ] 
                then sadm_write "${SADM_OK}\n" 
                else sadm_write "${SADM_ERROR} Service '$1' may not be enable\n" 
             fi
             systemctl list-unit-files | grep $1                        # Display Service Status
        else service $1 status                                          # Show service status
             if [ $? -eq 0 ] 
                then sadm_write "Service '$1' status ... ${SADM_OK}\n" 
                else sadm_write "Service '$1' status ... ${SADM_ERROR} Service '$1' not enable\n" 
             fi
    fi
}


# ==================================================================================================
#                               Stop SADM Service
# ==================================================================================================
service_stop()
{
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then printf "systemctl stop ${1}.service ... "                  # write cmd to log
             systemctl stop "${1}.service" | tee -a $SADM_LOG 2>&1      # use systemctl
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

        else printf "service $1 stop ..."                               # write cmd to log
             service $1 stop >> $SADM_LOG 2>&1                          # stop the service
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
    fi
}


# ==================================================================================================
#                               Start SADM Service
# ==================================================================================================
service_start()
{
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then printf "systemctl start ${1}.service ... "                 # write cmd to log
             systemctl start "${1}.service" | tee -a $SADM_LOG 2>&1     # use systemctl
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi

        else printf "service $1 start ... "                             # write cmd to log
             service $1 stop >> $SADM_LOG 2>&1                          # stop the service
             if [ $? -eq 0 ] ; then printf "[OK]\n" ; else printf "[ERROR]\n" ; fi
    fi
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Script can only run under Linux
    if [ "$(sadm_get_ostype)" != "LINUX" ]                              # if not Under Linux O/S
        then sadm_writelog "This script can only run under Linux O/S"   # Advise user
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # If Running under a SysV Init System (Not systemd) this script need 'chkconfig' command
    if [ $SYSTEMD -ne 1 ]                                               # Using Sysinit
        then command_available "chkconfig" ; CHKCONFIG=$SPATH           # Save Cmd Path Returned
             if [ "$CHKCONFIG" = "" ]                                   # Not found = Inst Req. 
                then install_package "chkconfig" "chkconfig"            # Install Pack (rpm,deb)
                     command_available "chkconfig"                      # Recheck 
             fi
             if [ "$CHKCONFIG" = "" ]                                   # Not found = Inst Req. 
                then sadm_writelog "Command chkconfig not found"
                     sadm_writelog "Process aborted"                    # Abort advise message
                     sadm_stop 1                                        # Close and Trim Log
                     exit 1                                             # Exit To O/S
             fi
    fi 

    # For Systemd - Check existance of service file in $SADMIN/sys directory
    if [ $SYSTEMD -eq 1 ] && [ ! "${SADM_SRV_IFILE}" ]                  # Using systemd not Sysinit
       then sadm_writelog "File $SADM_SRV_IFILE is missing"             # Inform user
            sadm_writelog "Cannot enable/disable SADM service"          # Abort Msg
            sadm_stop 1                                                 # Close and Trim Log
            exit 1                                                      # Exit To O/S
    fi

    # For SysV Init - Check existance of service file in $SADMIN/sys directory
    if [ $SYSTEMD -eq 0 ] && [ ! "${SADM_INI_IFILE}" ]                  # Using Sysinit
       then sadm_writelog "File $SADM_INI_IFILE is missing"             # Inform user
            sadm_writelog "Cannot enable/disable SADM service"          # Abort Msg
            sadm_stop 1                                                 # Close and Trim Log
            exit 1                                                      # Exit To O/S
    fi

#
#    echo "Avant"
#    sadm_write "Ca write"
#    sadm_write "Ca writelog"
#    echo "Apres"
#    sadm_stop 0 
#    exit 0
#
    # Optional Command line switches    
    P_DISABLE="OFF" ; P_ENABLE="OFF" ; P_STATUS="OFF"                   # Set Switch Default Value
    while getopts "devsh " opt ; do                                     # Loop to process Switch
        case $opt in
            d) P_DISABLE="ON"                                           # Disable SADM Service 
               service_stop    sadmin                                   # Stop sadmin Service
               service_disable sadmin                                   # Enable sadmin Service
               printf "\nConsequence of disabling SADMIN service :"
               printf "\n${SADMIN}/sys/sadm_startup.sh, will not be executed at system startup."
               printf "\n${SADMIN}/sys/sadm_shutdown.sh will not be executed on system shutdown.\n\n"
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;                                                      
            e) P_ENABLE="ON"                                            # Enable SADM Service 
               service_enable sadmin                                    # Enable sadmin Service
               service_stop   sadmin                                    # Stop sadmin Service
               service_start  sadmin                                    # Start sadmin Service
               service_status sadmin                                    # Status of sadmin Service
               printf "\nConsequence of enabling SADMIN service :"
               printf "\n${SADMIN}/sys/sadm_startup.sh, will be executed at system startup."
               printf "\n${SADMIN}/sys/sadm_shutdown.sh will be executed on system shutdown."
               printf "\nWe encourage you to customize these two scripts to your need.\n\n"
               ;;                                                      
            s) P_STATUS="ON"                                            # Status Option Selected
               service_status sadmin                                    # Status of sadmin Service
               ;;                                                      
            h) show_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close and Trim Log
               exit 0                                                   # Exit To O/S
               ;;
            v) show_version                                             # Display Script Version
               sadm_stop 0                                              # Close and Trim Log
               exit 0                                                   # Exit To O/S
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done  

    if [ "$P_DISABLE" = "OFF" ] && [ "$P_ENABLE" = "OFF" ] && [ "$P_STATUS" = "OFF" ] 
       then show_usage
    fi 

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
