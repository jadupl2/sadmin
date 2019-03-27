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
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
#--------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x
 



#===================================================================================================
#               Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # Test if 'SADMIN' environment variable is defined
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    # Test if 'SADMIN' Shell Library is readable 
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.3'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="Y"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="N"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="N"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#
#---------------------------------------------------------------------------------------------------
#
    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But they can be overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                  # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#
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



# ==================================================================================================
#                               Disable SADM Service
# ==================================================================================================
service_disable()
{
    sadm_writelog "--- Disabling Service $1 ..."                        # Advise User
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then sadm_writelog "systemctl disable ${1}.service"             # write cmd to log
             systemctl disable "${1}.service" | tee -a $SADM_LOG 2>&1   # use systemctl to disable
             sadm_writelog "Remove Service file $SADM_SRV_OFILE" 
             rm -f $SADM_SRV_OFILE >> $SADM_LOG 2>&1
             systemctl list-unit-files | grep $1 >> $SADM_LOG 2>&1      # Display Service Status
        else sadm_writelog "chkconfig $1 off"                           # write cmd to log
             chkconfig $1 off    >> $SADM_LOG 2>&1                      # disable service
             sadm_writelog "Remove Service file $SADM_INI_OFILE" 
             rm -f $SADM_INI_OFILE >> $SADM_LOG 2>&1
    fi
    sadm_writelog ""                                                    # Blank LIne
}



# ==================================================================================================
#                               Enable Linux Service
# ==================================================================================================
service_enable()
{
    sadm_writelog "--- Enabling service '$1' ..."                       # Action to log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then sadm_writelog "cp $SADM_SRV_IFILE $SADM_SRV_OFILE"         # write cmd to log
             cp $SADM_SRV_IFILE $SADM_SRV_OFILE >> $SADM_LOG 2>&1       # Put in Place Service file
             sadm_writelog "systemctl enable ${1}.service"              # write cmd to log
             systemctl enable "${1}.service" | tee -a $SADM_LOG 2>&1    # use systemctl
        else sadm_writelog "cp $SADM_INI_IFILE $SADM_INI_OFILE"         # write cmd to log
             cp $SADM_INI_IFILE $SADM_INI_OFILE >> $SADM_LOG 2>&1       # Put in Place Service file
             chmod 755 $SADM_INI_OFILE >> $SADM_LOG 2>&1                # Make service script exec.
             chown root:root $SADM_INI_OFILE >> $SADM_LOG 2>&1          # Make service owned by root
             sadm_writelog "chkconfig $1 on"                            # write cmd to log
             chkconfig $1 on    >> $SADM_LOG 2>&1                       # enable service
    fi
    sadm_writelog ""                                                    # Blank LIne
}



# ==================================================================================================
#                               Status of Linux Service
# ==================================================================================================
service_status()
{
    sadm_writelog "--- Status of service '$1' ..."                      # write action to log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then sadm_writelog "systemctl status ${1}.service"              # write cmd to log
             systemctl status ${1}.service | tee -a $SADM_LOG 2>&1      # use systemctl
             systemctl list-unit-files | grep $1 >> $SADM_LOG 2>&1      # Display Service Status
        else sadm_writelog "service $1 status"                          # write cmd to log
             service $1 status | tee -a $SADM_LOG 2>&1                  # Show service status
    fi
}


# ==================================================================================================
#                               Stop SADM Service
# ==================================================================================================
service_stop()
{
    sadm_writelog "--- Stopping service '$1' ..."                       # write action to log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then sadm_writelog "systemctl stop ${1}.service"                # write cmd to log
             systemctl stop "${1}.service" | tee -a $SADM_LOG 2>&1      # use systemctl
        else sadm_writelog "service $1 stop"                            # write cmd to log
             service $1 stop >> $SADM_LOG 2>&1                          # stop the service
    fi
}


# ==================================================================================================
#                               Start SADM Service
# ==================================================================================================
service_start()
{
    sadm_writelog "--- Start service '$1' ..."                          # write action to log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then sadm_writelog "systemctl start ${1}.service"               # write cmd to log
             systemctl start "${1}.service" | tee -a $SADM_LOG 2>&1     # use systemctl
        else sadm_writelog "service $1 start"                           # write cmd to log
             service $1 stop >> $SADM_LOG 2>&1                          # stop the service
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

    # Optional Command line switches    
    P_DISABLE="OFF" ; P_ENABLE="OFF"                                    # Set Switch Default Value
    while getopts "devsh " opt ; do                                     # Loop to process Switch
        case $opt in
            d) P_DISABLE="ON"                                           # Disable SADM Service 
               service_stop    sadmin                                   # Stop sadmin Service
               service_disable sadmin                                   # Enable sadmin Service
               #service_status  sadmin                                   # Status of sadmin Service
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;                                                      
            e) P_ENABLE="ON"                                            # Enable SADM Service 
               service_enable sadmin                                    # Enable sadmin Service
               service_stop   sadmin                                    # Stop sadmin Service
               service_start  sadmin                                    # Start sadmin Service
               service_status sadmin                                    # Status of sadmin Service
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;                                                      
            s) service_status sadmin                                    # Status of sadmin Service
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;                                                      
            h) show_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;
            v) show_version                                             # Display Script Version
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done  

    if [ "$P_DISABLE" = "OFF" ] && [ "$P_ENABLE" = "OFF" ]              # Set Switch Default Value
       then show_usage
            sadm_stop 0                                                 # Close the shop
            exit 0                                                      # Back to shell 
    fi 

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
