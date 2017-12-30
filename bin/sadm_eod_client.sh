#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_eod_client.sh
#   Synopsis :  This script must be run once a day at the end of the day.
#               It run multiple script that collect informations about server.
#   Version  :  1.0
#   Date     :  3 December 2016
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
# 1.1 Jan 2017 - Cosmetic Log Output change
# 2017_12_28 - JDuplessis
#   v1.2 Adapted to MacOS to show Message non availibility of nmon on OSX. 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $sadmin/lib/sadmlib_test.sh for viewing functions and informations avail. to you .
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to SADMIN directory" ;exit 1 ;fi
wlib="${SADMIN}/lib/sadmlib_std.sh"                                     # SADMIN Library Location
if [ ! -f $wlib ] ;then echo "SADMIN Library ($wlib) Not Found" ;exit 1 ;fi
#
# These are Global variables used by SADMIN Libraries - Some influence the behavior of some function
# These variables need to be defined prior to loading the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='1.2'                             ; export SADM_VER            # Your Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# Load SADMIN Libraries
[ -f ${SADMIN}/lib/sadmlib_std.sh ]    && . ${SADMIN}/lib/sadmlib_std.sh
# These variables are defined in sadmin.cfg file - You can override them here on a per script basis
# --------------------------------------------------------------------------------------------------
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE  # Max Nb. Lines in LOG file
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE   # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR    # Email Address to send status
#
# An email can be sent at the end of the script depending on the ending status
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE    # 0=No 1=OnErr 2=Success 3=All
#
#===================================================================================================
#

# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------




# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem

    # Script Got to be run by root user
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # At midnight Kill nmon & restart nmon
    if [ "$(sadm_get_ostype)" != "DARWIN" ]                             # No Midnight Restart on OSX
        then SCRIPT="sadm_nmon_midnight_restart"                        # Name of Script to run 
             SCMD="${SADM_BIN_DIR}/${SCRIPT}.sh"                        # Full Path to Script
             sadm_writelog "Running $SCMD ..."                          # Show in Log Pgm. Running
             $SCMD >/dev/null 2>&1                                      # Run the Script
             if [ $? -ne 0 ]                                            # If Error was encounter
                then sadm_writelog "Error encounter in $SCMD"           # Signal Error in Log
                     SADM_EXIT_CODE=1                                   # Script Global Error to 1
                     sadm_writelog "Please check Log for further detail about the error :"
                     sadm_writelog "${SADM_LOG_DIR}/${SCRIPT}.log"
                else sadm_writelog "Script $SCMD terminated with success" # Advise user it's OK
             fi
    fi


    # Once a day just before midnight - Create daily Linux performance data file
    SCRIPT="sadm_create_sar_perfdata"
    SCMD="${SADM_BIN_DIR}/${SCRIPT}.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
             sadm_writelog "Please check Log for further detail about the error :"
             sadm_writelog "${SADM_LOG_DIR}/${SCRIPT}.log"
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi


    # Once a day - Delete old rch and log files & chown+chmod on SADMIN client
    SCRIPT="sadm_housekeeping_client"
    SCMD="${SADM_BIN_DIR}/${SCRIPT}.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
             sadm_writelog "Please check Log for further detail about the error :"
             sadm_writelog "${SADM_LOG_DIR}/${SCRIPT}.log"
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi


    # Save Filesystems Structure for every Volume Group on System
    #  - Used in case of a System Recovery by sadm_fs_recreate.sh script
    SCRIPT="sadm_fs_save_info"
    SCMD="${SADM_BIN_DIR}/${SCRIPT}.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
             sadm_writelog "Please check Log for further detail about the error :"
             sadm_writelog "${SADM_LOG_DIR}/${SCRIPT}.log"
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi


    # Generate System Configuration for this server (Collect by sadmin server)
    SCRIPT="sadm_create_server_info"
    SCMD="${SADM_BIN_DIR}/${SCRIPT}.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
             sadm_writelog "Please check Log for further detail about the error :"
             sadm_writelog "${SADM_LOG_DIR}/${SCRIPT}.log"
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi


    # Produce html page containing configuration (Collect by sadmin server)
    SCRIPT="sadm_create_cfg2html" 
    SCMD="${SADM_BIN_DIR}/${SCRIPT}.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
             sadm_writelog "Please check Log for further detail about the error :"
             sadm_writelog "${SADM_LOG_DIR}/${SCRIPT}.log"
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi


    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
