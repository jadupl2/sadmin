#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_client_sunset.sh
#   Synopsis :  This script must be run once a day at the end of the day.
#               It run multiple script that collect informations about server.
#   Version  :  1.0
#   Date     :  3 December 2016
#   Requires :  sh
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# 2017_01_02    v1.1 Cosmetic Log Output change
# 2017_12_28    v1.2 Adapted to MacOS to show Message non availibility of nmon on OSX. 
# 2018_01_05    v1.3 Add MySQL Database Backup in execution sequence
# 2018_01_06    v1.4 Create Function fork the multiple script run by this one
# 2018_01_10    v1.5 Database Backup - Compress Backup now
# 2018_01_10    v1.6 Database Backup was not taken when compress (-c) was used.
# 2018_01_23    v1.7 Added the script to read all nmon files and create/update the proper RRD.
# 2018_01_24    v1.8 Pgm Restructure and add check to run rrd_update only on sadm server.
# 2018_01_25    v1.9 Remove rrd_update and move it to sadm_sod_server.sh (start of day script)
# 2018_02_04    v2.0 Remove MySql Backup & Change Script name from sadm_eod_client.sh to sadm_client_sunset.sh
# 2018_04_05    v2.1 Remove execution of sadm_create_sar_perfdata.sh not neede anymmore
# 2018_06_03    v2.2 Adapt to new version of Shell Library and small ameliorations
# 2018_06_09    v2.3 Change & Standardize scripts name called by this script & Change Startup Order
# 2018_09_16    v2.4 Added Default Alert Group
# 2018_11_13    v2.5 Adapted for MacOS (Don't run Aix/Linux scripts)
#@2020_02_23 Update: v2.6  Return error only if one script is not executable or doesn't exist.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
    export SADM_VER='2.6'                               # Current Script Version
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





#===================================================================================================
# Scripts Variables 
#===================================================================================================
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
#                  Run the script received as parameter (Return 0=Success 1= Error)
#===================================================================================================
run_command()
{
    SCRIPT=$1                                                           # Shell Script Name to Run
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${CMDLINE}"                                   # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                               # If SCript do not exist
        then sadm_writelog "[ ERROR ] Script $SCMD not executable or doesn't exist."
             sadm_writelog " " 
             return 1                                                   # Return Error to Caller
    fi 

    sadm_writelog "Running $SCMD ..."                                   # Show Command about to run
    $SCMD >/dev/null 2>&1                                               # Run the Script
    if [ $? -ne 0 ]                                            # If Error was encounter
        then sadm_writelog "[ WARNING ] Encounter while running $SCRIPT"   
             sadm_writelog "${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log" # Show Log Name    
        else sadm_writelog "[ SUCCESS ] Running $SCMD"          # Advise user it's OK
    fi

    sadm_writelog " " 
    return 0                                                            # Return Success to Caller
}


#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    SADM_EXIT_CODE=0                                                    # Reset Error counter

    # On Every Client (including SADMIN Server) we prune some files & check file owner & Permission
    run_command "sadm_client_housekeeping.sh"                           # Client HouseKeeping Script
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi     # Increase Error Counter

    # Save Filesystem Information of current filesystem ($SADMIN/dat/dr/hostname_fs_save_info.dat)
    if [ "$(sadm_get_ostype)" != "DARWIN" ]                             # If Not on MacOS 
        then run_command "sadm_dr_savefs.sh"                            # Client Save LVM FS Info
             if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi  # Incr. Error Counter
    fi

    # Collect System Information and store it in $SADMIN/dat/dr (Used for Disaster Recovery)
    run_command "sadm_create_sysinfo.sh"                                # Create Client Sysinfo file
    if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi     # Increase Error Counter

    # Create HTML file containing System Info.(files,hardware,software) $SADMIN/dat/dr/hostname.html
    if [ "$(sadm_get_ostype)" != "DARWIN" ]                             # If Not on MacOS 
        then run_command "sadm_cfg2html.sh"                             # Produce cfg2html html file
             if [ $? -ne 0 ] ;then SADM_EXIT_CODE=$(($SADM_EXIT_CODE+1)) ;fi  # Incr. Error Counter
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
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
