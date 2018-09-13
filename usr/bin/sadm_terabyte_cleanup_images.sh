#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      This script is run to keep only $NB_COPY of each terabyte server image into
#               $TERABYTE_IMG_DIR
#   Synopsis:   This script is used to delete old terabyte image from the image repository on NAS
#   Date:       September 2015
# --------------------------------------------------------------------------------------------------
#
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
# Enhancements/Corrections Version Log
# 1.6   April 2017 - Add display of the log on the screen  
# 
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.6'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                                  ; export DEBUG_LEVEL     # 0=NoDebug Higher=+Verbose
NB_COPY=3                                      ; export NB_COPY         # Nb. Copy of images to keep
REMOTE_HOST="batnas.maison.ca"                 ; export REMOTE_HOST     # NAS BOX NAME
NFS_REM_MOUNT="/volume1/os_images/terabyte"    ; export NFS_REM_MOUNT   # Remote NFS Mount Point
NFS_LOC_MOUNT="/mnt/tera"                      ; export NFS_LOC_MOUNT   # Local NFS Mount Point

# List of servers that have terabyte images 
TERA_SERVER="watson sherlock surface dm4500"

																				     
# ==================================================================================================
#           Function to only keep $NB_COPY of each windows server image on the server
# ==================================================================================================
clean_terabyte_dir()
{
    SADM_EXIT_CODE=0
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Keep $NB_COPY copies of TeraByte images per host"


    # Check if NFS Local mount point exist - If not create it.
    if [ ! -d ${NFS_LOC_MOUNT} ]
        then mkdir ${NFS_LOC_MOUNT} ; chmod 2775 ${NFS_LOC_MOUNT} ; fi
        
    # Check to make sure it is not already mounted
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
    
    # Mount the NFS drive on the NAS
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Mount the NAS NFS"
    sadm_writelog "mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}"
    mount ${REMOTE_HOST}:${NFS_REM_MOUNT} ${NFS_LOC_MOUNT}
    RC=$?

    # If the mount NFS did not work - Abort Script after advising user (update logs)
    if [ $RC -ne 0 ]
        then sadm_writelog " "
             sadm_writelog "SCRIPT ABORTED - UNABLE TO MOUNT NFS DRIVE ON THE NAS"
             return 1
    fi

    # Change to OS Image Directory
    cd ${NFS_LOC_MOUNT}
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "List of current TeraByte Images in `pwd`"
    ls -lt | nl | tee -a $SADM_LOG
    sadm_writelog " "
        
    for WSERVER in $TERA_SERVER
        do
        sadm_writelog " "
        sadm_writelog "${SADM_TEN_DASH}"
        sadm_writelog "List of Terabyte Images for server ${WSERVER}"
        ls -lt *_${WSERVER}.TBI | tee -a $SADM_LOG
        FILE_COUNT=`ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d | wc -l`
        if [ "$FILE_COUNT" -ne 0 ]
            then    sadm_writelog " "
                    sadm_writelog "Number of TBI file(s) to delete is $FILE_COUNT"
                    sadm_writelog "Terabyte TBI File(s) Deleted :"
                    ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d | tee -a $SADM_LOG
                    ls -t1 *_${WSERVER}.TBI | sort -r | sed 1,${NB_COPY}d | xargs rm -f >> $SADM_LOG 2>&1
                    RC=$?
                    if [ $RC -ne 0 ]
                        then    sadm_writelog "RESULT : Error $RC returned while cleaning up ${WSERVER} TBI files"
                                RC=1
                        else    sadm_writelog "RESULT : Clean up of ${WSERVER} went OK"
                                RC=0
                    fi
            else    RC=0
                    sadm_writelog "RESULT : No file(s) to delete for ${WSERVER} - OK"
        fi 
        SADM_EXIT_CODE=`echo $SADM_EXIT_CODE + $RC | bc `
        sadm_writelog "Total of Error is $SADM_EXIT_CODE"
        done
    
     # Umount THE NFS Mount of the Terabyte Images
    sadm_writelog "${SADM_TEN_DASH}"
    cd $BASE_DIR
    sadm_writelog "Unmount NAS NFS"
    sadm_writelog "umount ${NFS_LOC_MOUNT}"
    umount ${NFS_LOC_MOUNT} > /dev/null 2>&1
    
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Grand Total of Error is $SADM_EXIT_CODE"
    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                          # Initialize the LOG and RC File - Check existence of Dir.
    clean_terabyte_dir                  # Clean up old multiple copies of Storix Images
    rc=$? ; export rc                   # Save Return Code
    sadm_stop $rc                       # Save and trim Logs
    exit $SADM_EXIT_CODE                # Exit with Error code value


