#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author        : Jacques Duplessis
#   Script Name   : sysmon_script_test.sh
#   Creation Date : 2026/05/08
#   Requires      : sh and SADMIN Shell Library
#   Description   : Script called from SADMIN monitor 'sadm_sysmon.pl' for testing purpose
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
# Add trap to catch ^C and stop script gracefully.
trap 'sadm_stop 1; exit 1' 2                                        
#set -x
     



# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup Global Variables and load the SADMIN standard library $SADMIN/lib/sadmlib_std.sh.
#       - To use SADMIN scripting tools, this section MUST be present near the top of your code.    


# Make sure environment variable 'SADMIN' is defined.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\nSet 'SADMIN' environment variable to the install directory." 
        printf "\nAdd a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 
fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\nSADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 
fi 


# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.0'                                      # Script version number
export SADM_PDESC="Script called from SADMIN monitor 'sadm_sysmon.pl' for testing purpose"   
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_QUIET="N"                                      # N=Show Err.Msg Y=ReturnErrorCode No Msg
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="Y"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoLogHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeLogFooter N=NoLogFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_TMP_FILE1=$(mktemp -q "$SADMIN/tmp/${SADM_INST}1_XXX") # WorkFile, remove by sadm_stop()
export SADM_TMP_FILE2=$(mktemp -q "$SADMIN/tmp/${SADM_INST}2_XXX") # WorkFile, remove by sadm_stop()
export SADM_TMP_FILE3=$(mktemp -q "$SADMIN/tmp/${SADM_INST}3_XXX") # WorkFile, remove by sadm_stop()

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



# Main Code Start Here
#===================================================================================================
    sadm_start                                                          # Won't come back if error
    sadm_write_log " "
    SADM_EXIT_CODE=0                                                    # 0= Success Exit code
    #SADM_EXIT_CODE=1                                                    # 1= Error Exit Code
    sadm_write_log "SADM_EXIT_CODE = $SADM_EXIT_CODE"                   # Debug Log
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
