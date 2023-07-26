#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_service.sh
#   Version  :  1.6
#   Date     :  7 June 2017
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
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2019_03_27 Fix: v2.3 Making sure InitV sadmin service script is executable.
# 2019_03_28 Fix: v2.4 Was not executing shutdown script under RHEL/CentOS 4,5
# 2019_03_29 cmdline v2.5 Major Revamp - Re-Tested - SysV and SystemD
# 2019_03_30 cmdline v2.6 Added message when enabling/disabling sadmin service.
# 2019_04_07 cmdline v2.7 Use color variables from SADMIN Library.
# 2019_12_27 cmdline v2.8 Was exiting with error when using options '-h' or '-v'.
# 2020_09_10 cmdline v2.9 Minor code improvement.
# 2021_05_23 cmdline v2.10 Change switch from -d (disable) to -u (unset) and -s(status) to -l (List)
# 2021_06_13 cmdline v2.11 When using an invalid command line option, PID file wasn't removed.
# 2023_03_31 cmdline v2.12 Fix problem that could prevent SADMIN startup/shutdown script to executed
#@2023_07_26 cmdline v2.13 Correct typo that correct problem declaring cmdline option.
#--------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x
 


# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.54
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]     # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.13'                                      # Script version number
export SADM_PDESC="Script to enable or disable execution of SADMIN startup/shutdown script."
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
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
# ---------------------------------------------------------------------------------------





# --------------------------------------------------------------------------------------------------
# Global Environment Variables 
# --------------------------------------------------------------------------------------------------
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
    printf "\n\t-s   (Set/Enable SADM Service)"
    printf "\n\t-u   (Unset/Disable SADM Service)"
    printf "\n\t-l   (List/Display Status of SADM Service)"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
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
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If you want this script to be run only by root user, uncomment the lines below.
    if [ $(id -u) -ne 0 ]                                               # If Cur. user is not root
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_writelog "Try 'sudo ${0##*/}'."                       # Suggest using sudo
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
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

    # For Systemd - Check existence of service file in $SADMIN/sys directory
    if [ $SYSTEMD -eq 1 ] && [ ! "${SADM_SRV_IFILE}" ]                  # Using systemd not Sysinit
       then sadm_writelog "File $SADM_SRV_IFILE is missing"             # Inform user
            sadm_writelog "Cannot enable/disable SADM service"          # Abort Msg
            sadm_stop 1                                                 # Close and Trim Log
            exit 1                                                      # Exit To O/S
    fi

    # For SysV Init - Check existence of service file in $SADMIN/sys directory
    if [ $SYSTEMD -eq 0 ] && [ ! "${SADM_INI_IFILE}" ]                  # Using Sysinit
       then sadm_writelog "File $SADM_INI_IFILE is missing"             # Inform user
            sadm_writelog "Cannot enable/disable SADM service"          # Abort Msg
            sadm_stop 1                                                 # Close and Trim Log
            exit 1                                                      # Exit To O/S
    fi

    # Optional Command line switches    
    P_DISABLE="OFF" ; P_ENABLE="OFF" ; P_STATUS="OFF"                   # Set Switch Default Value
    while getopts "dsuvlh" opt ; do                                    # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       sadm_stop 0                                      # Close the shop
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;           
            u) P_DISABLE="ON"                                           # Disable SADM Service 
               service_stop    sadmin                                   # Stop sadmin Service
               service_disable sadmin                                   # Enable sadmin Service
               printf "\nConsequence of disabling SADMIN service :"
               printf "\n${SADMIN}/sys/sadm_startup.sh, will not be executed at system startup."
               printf "\n${SADMIN}/sys/sadm_shutdown.sh will not be executed on system shutdown.\n\n"
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;                                                      
            s) P_ENABLE="ON"                                            # Enable SADM Service 
               service_enable sadmin                                    # Enable sadmin Service
               service_stop   sadmin                                    # Stop sadmin Service
               service_start  sadmin                                    # Start sadmin Service
               service_status sadmin                                    # Status of sadmin Service
               printf "\nConsequence of enabling SADMIN service :"
               printf "\n${SADMIN}/sys/sadm_startup.sh, will be executed at system startup."
               printf "\n${SADMIN}/sys/sadm_shutdown.sh will be executed on system shutdown."
               printf "\nWe encourage you to customize these two scripts to your need.\n\n"
               ;;                                                      
            l) P_STATUS="ON"                                            # Status Option Selected
               service_status sadmin                                    # Status of sadmin Service
               ;;                                        h) show_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close and Trim Log
               exit 0                                                   # Exit To O/S
               ;;
            v) sadm_show_version                                        # Display Script Version
               sadm_stop 0                                              # Close and Trim Log
               exit 0                                                   # Exit To O/S
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               sadm_stop 1                                              # Close the shop
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done  

    # If no Action to perform
    if [ "$P_DISABLE" = "OFF" ] && [ "$P_ENABLE" = "OFF" ] && [ "$P_STATUS" = "OFF" ] 
       then show_usage
    fi 

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
