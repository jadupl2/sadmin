#! /usr/bin/env bash
#---------------------------------------------------------------------------------------------------
#   Author      :   Your Name 
#   Script Name :   XXXXXXXX.sh
#   Date        :   2021/MM/DD
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Template for starting a new shell script
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <jacques.duplessis@sadmin.ca>.
#   Developer Web Site : https://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# Version Change Log 
#
# 2021_MM_DD New: v1.0 Initial Version

# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 1; exit 1' 2                                            # Intercept ^C
#set -x
     



# ---------------------------------------------------------------------------------------
# SADMIN section - Setup for Global Variables and import SADMIN Python module
# To use SADMIN tools module, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null 
         if [ $? -eq 0 ]                                   # Found SADMIN in /etc/env.
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.0'                                      # Script Version
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy ?
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. LockFile
export SADM_USE_RCH="Y"                                    # Update RCH HistoryFile 
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # LOAD SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Server
# ---------------------------------------------------------------------------------------


  

#===================================================================================================
# Global Scripts Variables 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\n\t${BOLD}${YELLOW}-d${NORMAL} Set Debug (Verbose) Level [0-9]"
    printf "\n\t${BOLD}${YELLOW}-h${NORMAL} Display this help message)"
    printf "\n\t${BOLD}${YELLOW}-v${NORMAL} Show script version info"
    printf "\n\n" 
}




#===================================================================================================
# Process all your active(s) server(s) found in Database (Used if want to process selected servers)
#===================================================================================================
process_servers()
{
    sadm_write "${BOLD}${YELLOW}Processing All Active(s) Server(s) ...${NORMAL}\n"

    # Put Rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir" 
    SQL="${SQL},srv_backup,srv_img_backup "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    
    xcount=0; ERROR_COUNT=0;                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Server Counter
        server_name=$(      echo $wline|awk -F\; '{print $1}')          # Extract Server Name
        server_os=$(        echo $wline|awk -F\; '{print $2}')          # O/S (linux/aix/darwin)
        server_domain=$(    echo $wline|awk -F\; '{print $3}')          # Extract Domain of Server
        server_monitor=$(   echo $wline|awk -F\; '{print $4}')          # Monitor  1=True 0=False
        server_sporadic=$(  echo $wline|awk -F\; '{print $5}')          # Sporadic 1=True 0=False
        server_rootdir=$(   echo $wline|awk -F\; '{print $7}')          # Client SADMIN Root Dir.
        server_backup=$(    echo $wline|awk -F\; '{print $8}')          # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $9}')          # ReaR Sched. 1=True 0=False
        #
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        sadm_write "\n"                                                 # Blank Line
        sadm_write "${SADM_TEN_DASH}\n"                                 # Ten Dashes Line    
        sadm_write "Processing ($xcount) ${fqdn_server}.\n"             # Server Count & FQDN Name 

        # Check if server name can be resolve - If not, we won't be able to SSH to it.
        host  $fqdn_server >/dev/null 2>&1                              # Try to resolve Hostname
        if (( $? ))                                                     # If hostname not resolvable
            then SMSG="$SADM_ERROR Can't process '$fqdn_server', hostname can't be resolved."
                 sadm_writelog "${SMSG}"                                # Advise user & Feed log
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 sadm_write "Total error(s) : ${ERROR_COUNT}\n"         # Show Total Error Count
                 continue                                               # Continue with next Server
        fi

        # Try a SSH to Host Name
        if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "$SADM_SSH_CMD $fqdn_server date\n" ; fi 
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Server
            then $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1       # SSH to Server & Run 'date'
                 RC=$?                                                  # Save Return Code Number
            else RC=0                                                   # No SSH to SADMIN Server
        fi
        if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "Return Code: ${RC}\n" ;fi # Show SSH Status

        # If SSH failed and it's a Sporadic Server, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
            then sadm_writelog "${SADM_WARNING} Can't SSH to sporadic system ${fqdn_server}."
                 sadm_write "Continuing with next system\n"             # Not Error if Sporadic Srv. 
                 continue                                               # Continue with next system
        fi

        # If SSH Failed & Monitoring is Off, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_monitor" = "0" ]                # SSH don't work/Monitor OFF
            then sadm_writelog "$SADM_WARNING Can't SSH to $fqdn_server - Monitoring is OFF"
                 sadm_write "Continuing with next system\n"             # Not Error if don't Monitor
                 continue                                               # Continue with next system
        fi

        # If All SSH test failed, Issue Error Message and continue with next system
        if (( $RC ))                                                    # If SSH to Server Failed
            then SMSG="$SADM_ERROR Can't SSH to '${fqdn_server}'"       # Problem with SSH
                 sadm_writelog "${SMSG}"                                # Show/Log Error Msg
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 continue                                               # Continue with next system
        fi
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If not on SADMIN Server
            then sadm_write "$SADM_OK SSH to ${fqdn_server} work\n"     # Good SSH Work on Client
            else sadm_write "$SADM_OK No SSH using 'root' on the SADMIN Server ($SADM_SERVER)\n"
        fi

        # PROCESSING CAN BE PUT HERE
        # ........
        # ........
        done < $SADM_TMP_FILE1
    return $ERROR_COUNT                                                 # Return Err Count to caller
}



#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    sadm_write "${BOLD}${YELLOW}Starting Main Process ...${NORMAL}\n"   # Starting processing Mess.
    
    # PROCESSING CAN BE PUT HERE
    # If Error occurred, set SADM_EXIT_CODE to 1 before returning to caller, else return 0 (default)
    # ........
    sadm_write "Hello World\n" 
    
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
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
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
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
# MAIN CODE START HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If you want this script to be run only on the SADMIN server, uncomment the lines below.
    #if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
    #    then sadm_write "Script can only be run on (${SADM_SERVER}), process aborted.\n"
    #         sadm_stop 1                                                # Close and Trim Log
    #         exit 1                                                     # Exit To O/S
    #fi

    # Use 'main_process' for code without interaction with SADMIN Database.
    main_process                                                        # Main Process
    
    # Or use 'process_server' for code dealing with server in SADMIN Database.
    #process_servers                                                    # Process All Active Servers
    
    SADM_EXIT_CODE=$?                                                   # Save Process Return Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
