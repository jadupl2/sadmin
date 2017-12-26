#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_service.sh
#   Synopsis : .
#   Version  :  1.6
#   Date     :  7 Juin 2017
#   Requires :  sh
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
# --------------------------------------------------------------------------------------------------
# Enhancements/Corrections Version Log
# V1.6 June 2017 - Initial Version
# V1.7 June 2017 - Corrections for System V service
# V1.8 July 2017 - Add '-s' switch to display sadmin service status
# V1.9 July 2017 - Modify Help Message
# 2017_08_03 JDuplessis - v1.10 Added a Stop Service beore the start (eliminate problem)
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x
 

#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='1.10'                            ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadmlib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadmlib_server.sh  

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis 
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
#===================================================================================================
#



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
SADM_SRV_IFILE="${SADM_SYS_DIR}/sadmin.service"     ; export SADM_SRV_IFILE  # Input Srv File
SADM_SRV_OFILE="/etc/systemd/system/sadmin.service" ; export SADM_SRV_OFILE  # Output Dest. Srv File
#
# SysV Init File
SADM_INI_IFILE="${SADM_SYS_DIR}/sadmin.rc"          ; export SADM_INI_IFILE  # Input Srv File
SADM_INI_OFILE="/etc/init.d/sadmin"                 ; export SADM_INI_OFILE  # Output Dest. Srv File


#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N 
#===================================================================================================
help()
{
    echo " "
    echo "sadm_service.sh usage :"
    echo "             -e   (Enable SADM Service)"
    echo "             -d   (Disable SADM Service)"
    echo "             -s   (Display Status of SADM Service)"
    echo "             -h   (Display this help message)"
    echo " "
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
    if ! $(sadm_is_root)                                                # Is it root running script?
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
    while getopts "desh " opt ; do                                      # Loop to process Switch
        case $opt in
            d) P_DISABLE="ON"                                           # Disable SADM Service 
               service_stop    sadmin                                   # Stop sadmin Service
               service_disable sadmin                                   # Enable sadmin Service
               service_status  sadmin                                   # Status of sadmin Service
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
            h) help                                                     # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               help                                                     # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done  

    if [ "$P_DISABLE" == "OFF" ] && [ "$P_ENABLE" == "OFF" ]             # Set Switch Default Value
       then help
            sadm_stop 0                                                 # Close the shop
            exit 0                                                      # Back to shell 
    fi 

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
  
