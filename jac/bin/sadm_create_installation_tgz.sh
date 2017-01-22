#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_installation_tgz.sh
#   Synopsis :  Update /install/files/sadmin with current content of /sadmin on this server
#               Create /install/file.tar.gz of files under /install/files
#               This tar.gz file will be untar the postinstall.sh script during O/S installation 
#   Version  :  1.0
#   Date     :  22 January 2017
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
# 1.1   
# 
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
SADM_VER='1.0'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  

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







# --------------------------------------------------------------------------------------------------
#                      S c r i p t    M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    SRC="/sadmin" 
    DEST="/install/files/sadmin"

    # Make sure Destination directory exist
    sadm_writelog "Make sure principal directories exist in $DEST"
    mkdir -p $DST           > /dev/null 2>&1
    mkdir -p $DST/bin       > /dev/null 2>&1
    mkdir -p $DST/cfg       > /dev/null 2>&1
    mkdir -p $DST/lib       > /dev/null 2>&1
    mkdir -p $DST/pkg       > /dev/null 2>&1
    mkdir -p $DST/sys       > /dev/null 2>&1
    mkdir -p $DST/log       > /dev/null 2>&1
    mkdir -p $DST/tmp       > /dev/null 2>&1
    mkdir -p $DST/jac/bin   > /dev/null 2>&1
    mkdir -p $DST/dat/rch   > /dev/null 2>&1

    # Syncing Content of master sadmin with installation directories
    sadm_writelog "Sync between $SRC and $DEST in progress"
    rsync -var --delete $SRC/bin/       $DEST/bin/      >/dev/null 2>&1
    rsync -var --delete $SRC/cfg/       $DEST/cfg/      >/dev/null 2>&1
    rsync -var --delete $SRC/lib/       $DEST/lib/      >/dev/null 2>&1
    rsync -var --delete $SRC/pkg/       $DEST/pkg/      >/dev/null 2>&1
    rsync -var --delete $SRC/sys/       $DEST/sys/      >/dev/null 2>&1
    rsync -var --delete $SRC/jac/bin/   $DEST/jac/bin/  >/dev/null 2>&1


    TAR_SRC="/install/files"
    TAR_NAME="files.tar.gz"
    TAR_FILE="/install/$TAR_NAME"

    # Creating tar file
    cd $TAR_SRC
    sadm_writelog "Now in `pwd` and creating install file $TAR_FILE"
    tar -cvzf $TAR_FILE . > /dev/null 2>&1
    sadm_writelog "mv $TAR_FILE $TAR_SRC"s
    mv $TAR_FILE $TAR_SRC

    sadm_writelog "Final tar file created ..."
    chown sadmin.sadmin $TAR_SRC/$TAR_NAME
    ls -l $TAR_SRC/$TAR_NAME | tee -a $SADM_LOG 
    return 0                                                            # Return Default return code
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
