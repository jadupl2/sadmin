#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_sod_server.sh
#   Synopsis :  Start Of Day script, run daily in the morning, so it is finish when you arrive
#               at work.
#               It run multiple script that rsync stat. and info file from client to this server
#   Version  :  1.6
#   Date     :  11 December 2016
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
# V1.6 Cosmetics and Refresh changes 
# V1.7 Added execution of MySQL Database Python Update
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
SADM_VER='1.7'                             ; export SADM_VER            # Script Version
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





# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
     if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                        # Only run on SADMIN 
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

    # Once a day - Delete old rch and log files & chown+chmod on SADMIN Server
    SCMD="${SADM_BIN_DIR}/sadm_housekeeping_server.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    # Collect from all servers Hardware info, Perf. Stat, ((nmon and sar)
    SCMD="${SADM_BIN_DIR}/sadm_daily_data_collection.sh "
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    # Daily DataBase Update with the Data Collected
    SCMD="${SADM_BIN_DIR}/sadm_database_update.py"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    # Scan the Subnet Selected - Inventory IP Address Avail.
    SCMD="${SADM_BIN_DIR}/sadm_subnet_lookup.py"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    # Send email to SysAdmin Daily Reporting Summary of Script Activity
    #SCMD="${SADM_BIN_DIR}/sadm_rch_scr_summary.sh -m"
    #sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    #$SCMD >/dev/null 2>&1
    #if [ $? -ne 0 ]                                                     # If Error was encounter
    #    then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
    #         SADM_EXIT_CODE=1                                           # Script Global Error to 1
    #    else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    #fi

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
