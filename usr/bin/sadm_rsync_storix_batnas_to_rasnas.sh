#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   ScriptName: sadm_rsync_storix_batnas_to_rasnas.sh
#   Title:      rsync Storix Backup from DS410 to Raspi Server
#   Date:       28 August 2015
#   Synopsis:   Once a MOnth Make a copy of current Storix Backup on DS410 to Raspi
# --------------------------------------------------------------------------------------------------
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
# 1.6  Change NAS Source and Destination Name 
# 1.7  Change rsync Option (Didn't keep date of source on destination)
# 1.8  June 2017 - Add advice to user when error mounting NFS
# 1.9  2018_09_01 V1.9 Adapt to new feature of Library
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.9'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    export SADM_ALERT_TYPE=3                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================



# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
FROM_SERVER="batnas.maison.ca"               ; export FROM_SERVER    # Source Remote Server
TO_SERVER="rasnas.maison.ca"                 ; export TO_SERVER      # Destination Raspberry Server

FROM_BASE_DIR="/volume1/storix"              ; export FROM_BASE_DIR  # Source Remote Base Dir.
TO_BASE_DIR="/disk02/storix"                 ; export TO_BASE_DIR    # Destination Remote Base Dir.

# Local Mount point for NFS
LOCAL_DIR1="/mnt/storix1"                    ; export LOCAL_DIR1
LOCAL_DIR2="/mnt/storix2"                    ; export LOCAL_DIR2


# --------------------------------------------------------------------------------------------------
#                             M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    # Make sure Local mount point exist
    if [ ! -d ${LOCAL_DIR1} ] ; then mkdir ${LOCAL_DIR1} ; chmod 775 ${LOCAL_DIR1} ; fi
    if [ ! -d ${LOCAL_DIR2} ] ; then mkdir ${LOCAL_DIR2} ; chmod 775 ${LOCAL_DIR2} ; fi
    
    # Mount the FROM NFS Drive (Source)
    sadm_writelog "Mounting the source NFS Drive on $FROM_SERVER"
    sadm_writelog "mount -t nfs ${FROM_SERVER}:${FROM_BASE_DIR} ${LOCAL_DIR1}"
    umount ${LOCAL_DIR1} > /dev/null 2>&1
    mount -t nfs ${FROM_SERVER}:${FROM_BASE_DIR} ${LOCAL_DIR1} >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then RC=1
             sadm_writelog "Mount NFS Failed from $FROM_SERVER Proces Aborted"
             umount ${LOCAL_DIR1} > /dev/null 2>&1
             umount ${LOCAL_DIR2} > /dev/null 2>&1             
             return 1
    fi
    
    # Mount the TO NFS Drive (Destination)
    sadm_writelog "Mounting the destination NFS Drive on $TO_SERVER"
    sadm_writelog "mount -t nfs ${TO_SERVER}:${TO_BASE_DIR} ${LOCAL_DIR2}"
    umount ${LOCAL_DIR2} > /dev/null 2>&1
    mount -t nfs ${TO_SERVER}:${TO_BASE_DIR} ${LOCAL_DIR2} >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then RC=1
             sadm_writelog "Mount NFS Failed from $TO_SERVER Proces Aborted"
             sadm_writelog "Check if NFS is started on $TO_SERVER"
             sadm_writelog "systemctl status nfs-kernel-server"
             umount ${LOCAL_DIR1} > /dev/null 2>&1
             umount ${LOCAL_DIR2} > /dev/null 2>&1             
             return 1
    fi
    
    # Do the Rsync
    sadm_writelog "rsync -vDdLHlr  --delete ${LOCAL_DIR1}/ ${LOCAL_DIR2}/"
    #rsync -vDdLHlr --delete ${LOCAL_DIR1}/ ${LOCAL_DIR2}/ | tee -a $SADM_LOG 2>&1
    rsync -var --delete ${LOCAL_DIR1}/ ${LOCAL_DIR2}/ | tee -a $SADM_LOG 2>&1
    RC=$? 
    if [ $RC -ne 0 ]
       then sadm_writelog "ERROR NUMBER $RC on rsync "
            RC=1
    fi

   sadm_writelog "Unmounting NFS mount directories"
   sadm_writelog "umount ${LOCAL_DIR1}"
   umount ${LOCAL_DIR1} >> $SADM_LOG 2>&1
   sadm_writelog "umount ${LOCAL_DIR2}"   
   umount ${LOCAL_DIR2} >> $SADM_LOG 2>&1
   return $RC                                                            # Return Default return code
}




# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#

    # Create log and update result code file
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    
    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T NEED TO RUN ON THE SADMIN MAIN SERVER, THEN REMOVE
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ] # Only run on SADMIN 
        then sadm_writelog "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T HAVE TO BE RUN BY THE ROOT USER, THEN YOU CAN REMOVE
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
 