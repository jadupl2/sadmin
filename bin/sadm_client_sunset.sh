#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_client_sunset.sh
#   Synopsis :  This script must be run once a day at the end of the day.
#               It run multiple script that collect information's about server.
#   Version  :  1.0
#   Date     :  3 December 2016
#   Requires :  sh
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2017_12_28    v1.2 Adapted to MacOS to show Message non availability of nmon on OSX. 
# 2018_01_05    v1.3 Add MySQL Database Backup in execution sequence
# 2018_01_06    v1.4 Create Function fork the multiple script run by this one
# 2018_01_10    v1.5 Database Backup - Compress Backup now
# 2018_01_10    v1.6 Database Backup was not taken when compress (-c) was used.
# 2018_01_23    v1.7 Added the script to read all nmon files and create/update the proper RRD.
# 2018_01_24    v1.8 Pgm Restructure and add check to run rrd_update only on sadm server.
# 2018_01_25    v1.9 Remove rrd_update and move it to sadm_sod_server.sh (start of day script)
# 2018_02_04    v2.0 Remove MySql Backup & Change Script name from sadm_eod_client.sh to sadm_client_sunset.sh
# 2018_04_05    v2.1 Remove execution of sadm_create_sar_perfdata.sh not needed anymore
# 2018_06_03    v2.2 Adapt to new version of Shell Library and small ameliorations
# 2018_06_09    v2.3 Change & Standardize scripts name called by this script & Change Startup Order
# 2018_09_16    v2.4 Added Default Alert Group
# 2018_11_13    v2.5 Adapted for MacOS (Don't run Aix/Linux scripts)
# 2020_02_23 Update: v2.6 Produce an alert only if one of the executed scripts isn't executable.
# 2020_04_01 Update: v2.7 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2020_04_05 Update: v2.8 Remove one call to sadm_start (Was there twice)
# 2020_05_08 Update: v2.9 Minor Comment changes.
# 2020_11_24 Update: v2.10 Minor log adjustment.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "\n'SADMIN' Environment variable was temporarily set to ${SADMIN}."
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='2.10'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=35                          # When script end Trim rch file to 35 Lines
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



#===================================================================================================
#                  Run the script received as parameter (Return 0=Success 1= Error)
#===================================================================================================
run_command()
{
    SCRIPT=$1                                                           # Shell Script Name to Run
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${CMDLINE}"                                   # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                               # If SCript do not exist
        then sadm_write "[ ERROR ] Script $SCMD not executable or doesn't exist.\n"
             return 1                                                   # Return Error to Caller
    fi 

    $SCMD  >>$SADM_LOG 2>&1                                             # Run the Script
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_write "${SADM_ERROR} Encounter while running ${SCRIPT}.\n"   
             sadm_write "Check the log file : ${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log\n"  
        else sadm_write "${SADM_OK} $SCMD \n"                               # Advise user it's OK
    fi

    # Return code different than zero would give an Error/Alert for this script and the 
    # called script. 
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
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}."               # Display Debug Level
               ;;                                                       
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
    return 
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
