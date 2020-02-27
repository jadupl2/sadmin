#! /usr/bin/env bash
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
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# 2016_12_12 v1.6 Cosmetics and Refresh changes 
# 2016_12_14 v1.7 Added execution of MySQL Database Python Update
# 2018_01_25 v1.8 Added update of Performance RRD based on nmon content of each server
#                 Change name from sadm_sod_server.sh to sadm_server_start_of_day.sh
# 2018_02_04 v1.9 Add Mysql Backup
#                    Change name from sadm_server_start_of_day.sh to sadm_server_sunrise.sh
# 2018_02_11 v1.10 Change message when succeeded to run script
# 2018_06_06 v2.0 Restructure Code, Added Comments & Change for New SADMIN Libr.
# 2018_06_09 v2.1 Change all the scripts name executed by this script (Prefix sadm_server)
# 2018_06_11 v2.2 Backtrack change v2.1
# 2018_06_19 v2.3 Change Backup DB Command line (Default compress)
# 2018_09_14 v2.4 Was reporting Error, even when all scripts ran ok.
# 2019_05_01 Update: v2.5 Log name now showed to help user diagnostic problem when an error occurs.
# 2019_05_23 Update: v2.6 Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
#@2020_02_23 Update: v2.7 Produce an alert only if one of the executed scripts isn't executable.
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
    export SADM_VER='2.7'                               # Current Script Version
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
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                   # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------




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



#===================================================================================================
#                  Run the script received as parameter (Return 0=Success 1= Error)
#===================================================================================================
exec_script()
{
    RC=0                                                                # Set Error Flag at OFF
    SCRIPT="$*"                                                         # Name of Script to execute
    SCMD="${SADM_BIN_DIR}/${SCRIPT}"                                    # Script full path name
    FLOG=`echo $SCRIPT | awk -F\. '{print $1}'`                         # Log name without extension
    SLOG="${SADM_LOG_DIR}/${SADM_HOSTNAME}_${FLOG}.log"                 # Log Name full path
    if [ ! -x $SCMD ]                                                   # Script not executable
        then sadm_writelog "[ ERROR ] Script $SCMD not executable or doesn't exist."
             RC=1                                                       # Raise Error Flag 
        else sadm_writelog "Running $SCMD ..."                          # Show Running Script Name
             $SCMD >/dev/null 2>&1                                      # Run the Script
             if [ $? -ne 0 ]                                            # If Error was encounter
                then sadm_writelog "[ WARNING ] Encounter while running $SCRIPT"   
                     sadm_writelog "For detail consult the log ($SLOG)" # Log for more detail
                else sadm_writelog "[ SUCCESS ] Running $SCMD"          # Advise user it's OK
             fi
    fi    
    return $RC
}




#===================================================================================================
# Main Process (Used to run script on current server)
#===================================================================================================
main_process()
{
    ERROR_COUNT=0                                                       # Clear Error Counter

    # Once a day - Delete old rch and log files & chown+chmod on SADMIN Server
    exec_script "sadm_server_housekeeping.sh"                           # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count
    
    # Collect from all servers Hardware info, Perf. Stat, ((nmon and sar)
    exec_script "sadm_daily_farm_fetch.sh"                              # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Daily DataBase Update with the Data Collected
    exec_script "sadm_database_update.py"                               # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # With all the nmon collect from the server farm update respective host rrd performace database
    exec_script "sadm_nmon_rrd_update.sh"                               # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Scan the Subnet Selected - Inventory IP Address Avail.
    exec_script "sadm_subnet_lookup.py"                                 # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Once a day we Backup the MySQL Database
    exec_script "sadm_backupdb.sh"                                      # Name of Script to execute
    if [ $? -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi         # On Error Incr. Err. Count

    # Set SADM_EXIT_CODE according to Error Counter (Return 1 or 0)
    if [ "$ERROR_COUNT" -gt 0 ]                                         # If some error occured
        then SADM_EXIT_CODE=1                                           # Error Set exit code to 1
        else SADM_EXIT_CODE=0                                           # Succes Set exit code to 0
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
            d) SADM_DEBUG=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $SADM_DEBUG -gt 0 ] ; then printf "\nDebug activated, Level ${SADM_DEBUG}\n" ; fi

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
    
