#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script rsync all the content of Storix local ISO directory onto the NAS BOX.
#               This script is run daily after the image backup are done 
#   Date:       September 2015
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
SADM_VER='1.6'                             ; export SADM_VER            # Script Version
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
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
LOCAL_ISO_DIR="/backups/iso"                  ; export LOCAL_ISO_DIR    # Storix ISO Directory
REMOTE_HOST="batnas.maison.ca"                ; export REMOTE_HOST      # NAS BOX NAME
REMOTE_ISO_DIR="/volume1/storix/iso"          ; export REMOTE_ISO_DIR   # ISO Dir. on NAS Box

	     
# ==================================================================================================
#           Rsync the Storix ISO Directory of local server to the NAS BOX
# ==================================================================================================
rsync_storix_iso()
{
    sadm_writelog "${SADM_TEN_DASH}"  
    sadm_writelog "Rsync the local directory $LOCAL_ISO_DIR with ${REMOTE_HOST}:${REMOTE_ISO_DIR}" 
    sadm_writelog "rsync -e 'ssh -p 22' -vrOltD --delete ${LOCAL_ISO_DIR}/ ${REMOTE_HOST}:${REMOTE_ISO_DIR}/"
    sadm_writelog " "
    rsync -e 'ssh -p 22' -vrOltD --delete ${LOCAL_ISO_DIR}/ ${REMOTE_HOST}:${REMOTE_ISO_DIR}/ >>$SADM_LOG 2>&1
    rc=$? ; export rc                                                    # Save Return Code
 
    # If error was reported  
    if [ "$rc" -ne 0 ]
        then sadm_writelog "Rsync ISO - Error $rc returned"
             rc=1
        else sadm_writelog "SUCCESS - No error reported by synchronization of iso files"
    fi
    return $rc
}

# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                          # Initialize the LOG and RC File - Check existence of Dir.

    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    rsync_storix_iso                                                    # Rsync Storix ISO with  NAS
    rc=$? ; export rc                                                   # Save Return Code
    sadm_stop $rc                                                       # Saveand trim Logs
    exit $rc                                                            # Exit with Error code value


