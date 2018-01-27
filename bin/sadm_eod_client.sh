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
# 2018_01_05 - JDuplessis
#   v1.3 Add MySQL Database Backup in execution sequence
# 2018_01_06 - JDuplessis
#   v1.4 Create Function fork the multiple script run by this one
# 2018_01_10 - JDuplessis
#   v1.5 Database Backup - Compress Backup now
# 2018_01_10 - JDuplessis
#   v1.6 Database Backup was not taken when compress (-c) was used.
# 2018_01_23 - JDuplessis
#   v1.7 Added the script to read all nmon files and create/update the proper RRD.
# 2018_01_24 - JDuplessis
#   v1.8 Pgm Restructure and add check to run rrd_update only on sadm server.
# 2018_01_25 - JDuplessis
#   v1.9 Remove rrd_update and move it to sadm_sod_server.sh (start of day script)
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# These Global variables are used by SADMIN Libraries - They influence behavior of some functions
# These variables need to be defined prior to loading the SADMIN function Libraries
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='1.9a'                            ; export SADM_VER            # Your Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But you can override them here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE    # Max Nb. Lines in LOG file
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE     # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send status
#===================================================================================================

# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------



#===================================================================================================
#                  Run the script received if parameter (Return 0=Success 1= Error)
#===================================================================================================
run_command()
{
    SCRIPT=$1                                                           # Shell Script Name to Run
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${CMDLINE}"                                   # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                               # If SCript do not exist
        then sadm_writelog "[ERROR] ${SADM_BIN_DIR}/${SCRIPT} Don't exist or can't execute" 
             sadm_writelog " " 
             return 1                                                   # Return Error to Callerr
    fi 

    sadm_writelog "Running $SCMD ..."                                   # Show Command about to run
    $SCMD >/dev/null 2>&1                                               # Run the Script
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] $SCRIPT Terminate with Error"       # Signal Error in Log
             sadm_writelog "Check Log for further detail about Error"   # Show user where to look
             sadm_writelog "${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log" # Show Log Name    
             sadm_writelog " " 
             return 1                                                   # Return Error to Callerr
        else sadm_writelog "[SUCCESS] Script $SCRIPT terminated"        # Advise user it's OK
             sadm_writelog " " 
    fi
    return 0                                                            # Return Success to Caller
}


#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    sadm_writelog "Main Process as started ..."
    SADM_EXIT_CODE=0                                                    # Reset Error counter

    # Once a day we Backup the MySQL Database - Run only on the SADMIN Server
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]                          # Only run on SADMIN Server
        then run_command "sadm_backupdb.sh" " -c "                      # Create MySQL DB Backup
             if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi # Increase Error Cntr 
    fi
    
    # On Every Client (including SADMIN Server) we prune some files & check file owner & Permission
    run_command "sadm_housekeeping_client.sh"                           # Client HouseKeeping Script
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi     # Increase Error Counter

    # Save Filesystem Information of current filesystem ($SADMIN/dat/dr/hostname_fs_save_info.dat)
    run_command "sadm_fs_save_info.sh"                                  # Client Save LVM FS Info
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi     # Increase Error Counter

    # Collect System Activity report and store it in $SADMIN/dat/sar 
    run_command "sadm_create_sar_perfdata.sh"                           # Create Perf. File from SAR
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi     # Increase Error Counter

    # Collect System Information and store it in $SADMIN/dat/dr (Used for Disaster Recovery)
    run_command "sadm_create_server_info.sh"                            # Create Client Sysinfo file
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi     # Increase Error Counter

    # Create HTML file containing System Info.(files,hardware,software) $SADMIN/dat/dr/hostname.html
    run_command "sadm_create_cfg2html.sh"                               # Produce cfg2html html file
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi     # Increase Error Counter

    return $SADM_EXIT_CODE                                              # Return No Error to Caller
}



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

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)  