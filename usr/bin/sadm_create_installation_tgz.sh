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
# Change Log
# 2018_06_03    v1.1 Add usr Directories
# 2018_06_19    v1.2 Remove sadmin directory from tar file, will use sadmin installation script
# 2018_07_20    v1.3 Bug fix - Remove files.tar.gz from the file files.tar.gz
# 
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
    export SADM_VER='1.3'                               # Current Script Version
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
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose







# --------------------------------------------------------------------------------------------------
#                      S c r i p t    M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    SRC="/sadmin" 
    DEST="/install/files/sadmin"

    # Make sure Destination directory exist
    #sadm_writelog "Make sure principal directories exist in $DEST"
    #mkdir -p $DST           > /dev/null 2>&1
    #mkdir -p $DST/bin       > /dev/null 2>&1
    #mkdir -p $DST/cfg       > /dev/null 2>&1
    #mkdir -p $DST/lib       > /dev/null 2>&1
    #mkdir -p $DST/doc       > /dev/null 2>&1
    #mkdir -p $DST/pkg       > /dev/null 2>&1
    #mkdir -p $DST/sys       > /dev/null 2>&1
    #mkdir -p $DST/log       > /dev/null 2>&1
    #mkdir -p $DST/tmp       > /dev/null 2>&1
    #mkdir -p $DST/usr/bin   > /dev/null 2>&1
    #mkdir -p $DST/usr/lib   > /dev/null 2>&1
    #mkdir -p $DST/usr/doc   > /dev/null 2>&1
    #mkdir -p $DST/dat/mon   > /dev/null 2>&1

    # Syncing Content of master sadmin with installation directories
    #sadm_writelog "Sync between $SRC and $DEST in progress"
    #rsync -var --delete $SRC/bin/       $DEST/bin/      >/dev/null 2>&1
    #rsync -var --delete $SRC/cfg/       $DEST/cfg/      >/dev/null 2>&1
    #rsync -var --delete $SRC/lib/       $DEST/lib/      >/dev/null 2>&1
    #rsync -var --delete $SRC/doc/       $DEST/doc/      >/dev/null 2>&1
    #rsync -var --delete $SRC/pkg/       $DEST/pkg/      >/dev/null 2>&1
    #rsync -var --delete $SRC/sys/       $DEST/sys/      >/dev/null 2>&1
    #rsync -var --delete $SRC/usr/bin/   $DEST/usr/bin/  >/dev/null 2>&1
    #rsync -var --delete $SRC/usr/lib/   $DEST/usr/lib/  >/dev/null 2>&1
    #rsync -var --delete $SRC/usr/doc/   $DEST/usr/doc/  >/dev/null 2>&1
    #rsync -var --delete $SRC/usr/mon/   $DEST/usr/mon/  >/dev/null 2>&1

    # Remove Server files
    #rm -f $DEST/cfg/.pgpass > /dev/null 


    TAR_SRC="/install/files"
    TAR_NAME="files.tar.gz"
    TAR_FILE="/install/$TAR_NAME"

    # Creating tar file
    cd $TAR_SRC
    sadm_writelog "Now in `pwd` and creating install file $TAR_FILE"
    tar --exclude="files.tar.gz" -cvzf $TAR_FILE . > /dev/null 2>&1
    sadm_writelog "mv $TAR_FILE $TAR_SRC"
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
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
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
