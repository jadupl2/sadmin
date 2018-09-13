#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :  Jacques Duplessis
#   Title       :  sadm_server_sunrise.sh
#   Synopsis    :  Daily early morning script, that retrieve data from servers & Update/Backup DB & NetInfo
#   Description :  Run Once Daily early around 5-6 am, it run multiple scripts before you start 
#                  your working day.
#                       Run Multiple Scripts :
#                           1)  housekeeping_server
#                           2)  daily_data_collection
#                           3)  database_update
#                           4)  nmon_rrd_update
#                           5)  subnet_lookup
#                           6)  backupdb
#   Version     :  1.6
#   Date        :  11 December 2016
#   Requires    :  sh & sadmlib.sh 
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
# Change Log
#
# 2016_12_12    v1.6 Cosmetics and Refresh changes 
# 2016_12_14    v1.7 Added execution of MySQL Database Python Update
# 2018_01_25    v1.8 Added update of Performance RRD based on nmon content of each server
#                    Change name from sadm_sod_server.sh to sadm_server_start_of_day.sh
# 2018_02_04    v1.9 Add Mysql Backup
#                    Change name from sadm_server_start_of_day.sh to sadm_server_sunrise.sh
# 2018_02_11    v1.10 Change message when succeeded to run script
# 2018_06_06    v2.0 Restructure Code, Added Comments & Change for New SADMIN Libr.
# 2018_06_09    v2.1 Change all the scripts name executed by this script (Prefix sadm_server)
# 2018_06_11    v2.2 Backtrack change v2.1
# 2018_06_19    v2.3 Change Backup DB Command line (Default compress)
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='2.3'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_ALERT_TYPE=1                           ; export SADM_ALERT_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose




# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
    printf "\n\n" 
}


#===================================================================================================
# Main Process (Used to run script on current server)
#===================================================================================================
main_process()
{
    sadm_writelog "Starting Main Process ... "                          # Inform User Starting Main
    
    # Once a day - Delete old rch and log files & chown+chmod on SADMIN Server
    SCMD="${SADM_BIN_DIR}/sadm_server_housekeeping.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] Encounter in $SCMD"                 # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "[SUCCESS] Running $SCMD"                    # Advise user it's OK
    fi

    # Collect from all servers Hardware info, Perf. Stat, ((nmon and sar)
    SCMD="${SADM_BIN_DIR}/sadm_daily_farm_fetch.sh "
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] Encounter in $SCMD"                 # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "[SUCCESS] Running $SCMD"                    # Advise user it's OK
    fi

    # Daily DataBase Update with the Data Collected
    SCMD="${SADM_BIN_DIR}/sadm_database_update.py"                      # Update DB from sysinfo.txt
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] Encounter in $SCMD"                 # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "[SUCCESS] Running $SCMD"                    # Advise user it's OK
    fi

    # With all the nmon collect from the server farm update respective host rrd performace database
    SCMD="${SADM_BIN_DIR}/sadm_nmon_rrd_update.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] Encounter in $SCMD"                 # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "[SUCCESS] Running $SCMD"                    # Advise user it's OK
    fi

    # Scan the Subnet Selected - Inventory IP Address Avail.
    SCMD="${SADM_BIN_DIR}/sadm_subnet_lookup.py"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] Encounter in $SCMD"                 # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "[SUCCESS] Running $SCMD"                    # Advise user it's OK
    fi

    # Once a day we Backup the MySQL Database
    SCMD="${SADM_BIN_DIR}/sadm_backupdb.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] Encounter in $SCMD"                 # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "[SUCCESS] Running $SCMD"                    # Advise user it's OK
    fi
    
    return $SADM_EXIT_CODE                                              # Return No Error to Caller
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$DEBUG_LEVEL" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi

# Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

# If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

# If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Del PID
             exit 1                                                     # Exit To O/S with error
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

# SADMIN CLosing procedure - Close/Trim log and rch file, Remove PID File, Send email if requested
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
