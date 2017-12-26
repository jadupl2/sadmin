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
SADM_VER='1.8'                             ; export SADM_VER            # Script Version
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
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
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
 