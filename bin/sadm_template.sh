#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author        : Your Name 
#   Script Name   : XXXXXXXX.sh
#   Creation Date : 2026/MM/DD
#   Requires      : sh and SADMIN Shell Library
#   Description   : Template for starting a new shell script
#
# Note : All scripts (Shell,Python,Perl,php), configuration files and screen output are formatted to 
#        have and use a 100 characters per line. Comments in all scripts always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#   The SADMIN tools are free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
#
# ---CHANGE LOG---
# GRP are :
#   - "Web"     Web Interface modification      - "install"  Install,Uninstall & Update changes.
#   - "cmdline" Command line tools changes.     - "template" Library,Templates,Libr demo.
#   - "mon"     System Monitor related.         - "backup"   Backup related modification or fixes.
#   - "config"  Config files modification.      - "server"   Server related modification or fixes.
#   - "client"  Client related modifications.   - "osupdate" O/S Update modification or fixes.
#
# YYYY-MM-DD GRP      vX.XX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
# 2026_01_02 template v0.1  Initial development version.
#
#---------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     




# --------------------------  S A D M I N   C O D E    S E C T I O N  ------------------------------
# v1.56 - Setup for Global variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.

# Make sure environment variable 'SADMIN' is defined.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\nSet 'SADMIN' environment variable to the install directory." 
        printf "\nAdd a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 ; fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\nSADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 ; fi 

# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='4.4'                                      # Script version number
export SADM_PDESC="SADMIN template shell script"           # Script Optional Desc.(Not use if empty)
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_QUIET="N"                                      # N=Show Err.Msg Y=ReturnErrorCode No Msg
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoLogHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeLogFooter N=NoLogFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") # WorkFile, remove by sadm_stop()
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") # WorkFile, remove by sadm_stop()
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") # WorkFile, remove by sadm_stop()

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VARIABLES DEFINE BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).export SADM_WARNING_GRP="default"
#export SADM_ALERT_GROUP="default"                          # Error Group Define in alert_group.cfg
#export SADM_WARNING_GROUP="default"                        # Warning alert Group (alert_group.cfg)   
#export SADM_INFO_GROUP="default"                           # Info alert Group (in alert_group.cfg)
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=400                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------





#===================================================================================================
# Script global variables definitions
#===================================================================================================






# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" "$(basename "$0")" "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n   ${BOLD}${YELLOW}[-X]${NORMAL}\t\t\tRemove the PID file & run script"
    printf "\n\n" 
}





#===================================================================================================
# Main Processing Function
#===================================================================================================
main_process()
{

    # If script is run from command line, ask user if want to continue (To avoid causing damage).
    # $SHLVL variable indicate the level of shell nesting (1 or 2 = Run from Command line)
    #if (( SHLVL < 3 ))                                                  
    #    then sadm_write_log "${SADM_PN} ${SADM_VER} ${SADM_PDESC} ($SHLVL)"
    #         sadm_ask "Continue"                                        # Continue (y/n) ? 
    #         if [ $? -eq 0 ] ; then sadm_stop 0 ; exit 0 ; fi           # 0 = Don't want to continue
    #    else sadm_write_log "Script executed by another script" 
    #fi
    

    sadm_write_log "Starting Main Process ..."                          # Starting processing Mess.

    # PROCESSING CAN BE PUT HERE
    # If Error occurred, set SADM_EXIT_CODE to 1 before returning to caller, else return 0 (default)
    # ........


    #sadm_sleep 6 2                                                     # Sleep 6Sec, 2sec increment
    return "$SADM_EXIT_CODE"                                            # Return ErrorCode to Caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# -d[0-9] Set Debug Level  
# -h) Show Help Usage, 
# -v) Show Script Version,  
# -X) Delete the script PID file before running the script.
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hvX" opt ; do                                      # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=$(echo "$SADM_DEBUG" |grep -E "^\-?[0-9]?\.?[0-9]+$") # Valid if Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nInvalid debug level.\n"                # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
            X) /usr/bin/rm -f "${SADMIN}/tmp/${SADM_INST}.pid" >/dev/null 2>&1
               printf "\n${BOLD}${BLINK}${YELLOW}The PID File ("${SADMIN}/tmp/${SADM_INST}.pid") is now removed.${NORMAL}\n" 
               ;;
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



#===================================================================================================
# Main Code Start Here
#===================================================================================================
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Won't come back if error
    main_process                                                        # Your PGM Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
