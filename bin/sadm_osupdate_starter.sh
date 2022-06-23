#! /usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_osupdate_starter.sh
#   Synopsis :  Run the O/S update to selected remote system
#   Version  :  1.0
#   Date     :  9 March 2015 
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_osupdate_starter.sh 1.0 2015/03/10
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2016_11_11  v2.6 Insert Logic to Pass a param. (Y/N) to sadm_osupdate_client.sh to Reboot or not
#                  server after successfully update. Reboot is specified in Database (Web Interface)
#                  on a server by server basis.
# 2016_11_15  v2.7 Log will now be cumulative (Not clear every time the script in run)
# 2017_02_03  v2.8 Database Columns were changed
# 2017_03_15  v2.9 Add Logic for command line switch [-s servername] to update only one server
#                  Command line switch [-h]  for help also added
# 2017_03_17  v3.0 Not a cumulative log anymore
# 2017_04_05  v3.1 Allow program to run more than once at same time, to allow simultanious Update
#                  Put Back cumulative Log, so don't miss anything, when multiple update running
# 2017_12_10  v3.2 Adapt program to use MySQL instead of PostGres 
# 2017_12_12  V3.3 Correct Problem connecting to Database
# 2018_02_08  V3.4 Fix Compatibility problem with 'dash' shell (If statement)
# 2018_06_05  v3.5 Add Switch -v to view version, change help message, adapt to new Libr.
# 2018_06_09  v3.6 Change the name  of the client o/s update script & Change name of this script
# 2018_06_10  v3.7 Change name to sadm_osupdate_starter.sh - and change client script name
# 2018_07_01  v3.8 Use SADMIN dir. of client from DB & allow running multiple instance at once
# 2018_07_11  v3.9 Solve problem when running update on SADMIN server (Won't start)
# 2018_09_19  v3.10 Include Alert Group
# 2018_10_24  v3.11 Adjustment needed to call sadm_osupdate.sh with or without '-r' (reboot) option.
# 2019_07_14 Update: v3.12 Adjustment for Library Changes.
# 2019_12_22 Fix: v3.13 Fix problem when using debug (-d) option without specifying level of debug.
# 2020_05_23 Update: v3.14 Create 'LOCK_FILE' file before launching O/S update on remote.
# 2020_07_28 Update: v3.15 Move location of o/s update is running indicator file to $SADMIN/tmp.
# 2020_10_29 Fix: v3.16 If comma was used in server description, it cause delimiter problem.
# 2020_11_04 Minor: v3.17 Minor code modification.
# 2020_11_20 Update: v4.0 Restructure & rename from sadm_osupdate_farm to sadm_osupdate_starter.
# 2020_12_02 Update: v4.1 Log is now in appending mode and can grow up to 5000 lines.
# 2020_12_12 Update: v4.2 Use new LOCK_FILE & Add and use SADM_PID_TIMEOUT & SADM_LOCK_TIMEOUT Var.
# 2021_02_13 Minor: v4.2 Change for log appearance.
# 2021_03_05 Update: v4.3 Add a sleep time after update to give system to reboot & become available.
# 2021_05_04 Update: v4.4 Don't sleep after updating a server if a reboot wasn't requested.
# 2021_05_10 nolog: v4.5 Error message change "sadm_osupdate_farm.sh" to "sadm_osupdate_starter"
# 2021_08_17 nolog: v4.6 Change to use the library lock file function. 
#@2022_05_24 nolog: v4.7 Fix problem with lock file detection. 
#@2022_06_21 Update: v4.8 Changes to use new functionalities SADMIN CODE SECTION 1.51
#
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.51
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] # SADMIN defined ? SADMIN Libr. exist   
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi # Last chance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='4.8'                                       # Script version number
export SADM_PDESC="SADMIN template shell script"           # Script Optional Desc.(Not use if empty)
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                               # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use
export SADM_ROOT_ONLY="Y"                                   # Run only by root ? - 1=Yes 0=No
export SADM_SADM_SERVER_ONLY="Y"                            # Run only on SADMIN server?- 1=Yes 0=No

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
export SADM_MAX_LOGLINE=5000                                 # Nb Lines to trim(0=NoTrim)
export SADM_MAX_RCLINE=60                                    # Nb Lines to trim(0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems
# ---------------------------------------------------------------------------------------




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
export ONE_SERVER=""                                                    # Name of server to update
export USCRIPT="sadm_osupdate.sh"                                       # Script to execute on nodes

# Seconds given for system reboot and to start applications.
export REBOOT_TIME=480                                                  



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${BOLD}${SADM_PN} [ -d 0-9 ] [ -h ] [ -v ]   hostname${NORMAL}" 
    printf "\n\t${BOLD}-d${NORMAL}   (Debug Level [0-9])"
    printf "\n\t${BOLD}-h${NORMAL}   (Display this help message)"
    printf "\n\t${BOLD}-v${NORMAL}   (Show Script Version Info)"
    printf "\n\n" 
}




# --------------------------------------------------------------------------------------------------
#  Update the O/S Update date and result status in Server Table in SADMIN Database
# --------------------------------------------------------------------------------------------------
update_server_db()
{
    WSERVER=$1                                                          # Server Name to Update
    WSTATUS=$2                                                          # Status of OS Update (F/S)
    WCURDAT=`date "+%C%y.%m.%d %H:%M:%S"`                               # Get & Format Update Date

    # Construct SQL Update Statement
    #if [ "$WSTATUS" = "F" ]
    #    then sadm_write "Set O/S update status to 'Failed' in Database "   # Advise user of result
    #    else sadm_write "Set O/S update status to 'Success' in Database "  # Advise user of result
    #fi
    SQL1="UPDATE server SET "                                           # SQL Update Statement
    SQL2="srv_date_osupdate = '${WCURDAT}', "                           # Update Date of this Update
    SQL3="srv_update_status = '${WSTATUS}' "                            # [S]uccess [F]ail [R]unning
    SQL4="where srv_name = '${WSERVER}' ;"                              # Server name to update
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"                                  # Create final SQL Statement
    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -e '$SQL'"           # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -e "$SQL" >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]                                                     # If Error while updating
        then sadm_write "${SADM_ERROR} O/S update status changed to 'Failed' in Database. \n"
             RCU=1                                                      # Set Error Code
        else sadm_write "${SADM_OK} O/S update status changed to 'Success' in Database.\n"
             RCU=0                                                      # Set Error Code = Success 
    fi
    return $RCU
}





# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
rcmd_osupdate()
{
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_update_auto, "
    SQL2="srv_update_reboot, srv_sporadic, srv_active, srv_sadmin_dir from server "
    SQL3="where srv_ostype = 'linux' and srv_active = True "            # Got to Be a Linux & Active
    SQL4="and srv_name = '$ONE_SERVER' ;"                               # Select server to update
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"                                  # Build Final SQL Statement 
    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL'"        # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line

    # Execute SQL to Get Server Information
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
   
    # Result file not readable or is empty = Server Name not found in Database
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_writelog "${SADM_ERROR} The system '$ONE_SERVER' was not found is the Database."
             return 1                                                   # Return Error to Caller
    fi 
    
    wline=$(head -1 $SADM_TMP_FILE1)                                    # Read Server Info Line 
    server_name=`               echo $wline|awk -F\; '{ print $1 }'`    # Get Server Name
    server_os=`                 echo $wline|awk -F\; '{ print $2 }'`    # Server O/S
    server_domain=`             echo $wline|awk -F\; '{ print $3 }'`    # Server Domain
    server_update_auto=`        echo $wline|awk -F\; '{ print $4 }'`    # Update Auto 1=Yes 0=No
    server_update_reboot=`      echo $wline|awk -F\; '{ print $5 }'`    # RebootAfter Upd 1=Yes 0=No
    server_sporadic=`           echo $wline|awk -F\; '{ print $6 }'`    # SporadicServer 1=Yes 0=No
    server_sadmin_dir=`         echo $wline|awk -F\; '{ print $8 }'`    # $SADMIN on remote Server
    fqdn_server=`echo ${server_name}.${server_domain}`                  # Create FQN Server Name
        
    # Ping to server 
    ping -c2 $fqdn_server >> /dev/null 2>&1
    if [ $? -ne 0 ]
        then if [ "$server_sporadic" = "1" ]
                 then    sadm_writelog "${SADM_WARNING} Sporadic system now offline."
                         return 0 
                 else    sadm_writelog "${SADM_ERROR} Could not ping ${fqdn_server}."
                         sadm_writelog "Update is not possible, process aborted."
                         return 1 
             fi
        else sadm_writelog "${SADM_OK} Ping host $fqdn_server."
    fi

    # If 'srv_update_auto' = 0 in Database for that server, it means no update allowed for server
    if [ "$server_update_auto" = "0" ]
        then sadm_writelog "${SADM_WARNING} O/S Update for '${fqdn_server}' isn't activated."
             sadm_writelog "No O/S Update will be performed."
             sadm_writelog "Unless you check field 'Activate O/S Update Schedule' in the schedule."
             return 1
    fi 

    # Check existence of script on remote server and that it is executable.
    pgm="${server_sadmin_dir}/bin/$USCRIPT"                         # Path To o/s update script
    response=$($SADM_SSH_CMD $fqdn_server "if [ -x $pgm ] ;then echo 'ok' ;else echo 'error' ;fi")
    if [ "$response" != "ok" ]
        then sadm_writelog "${SADM_ERROR} '$pgm' don't exist or not executable on $fqdn_server."
             sadm_writelog "No O/S Update will be perform."
             return 1
        else sadm_writelog "${SADM_OK} '$pgm' exist & executable on $fqdn_server."
    fi 

    # Activate or not the reboot at the end of the O/S Update.
    WREBOOT=""                                                      # Def. Action = NO reboot
    if [ "$server_update_reboot" = "1" ]                            # If Requested in Database
        then WREBOOT="-r"                                           # Add -r option to reboot  
    fi                                                              # This reboot after Update
    
    # Check if System is Locked.
    sadm_check_lockfile "$server_name"                              # Check lock file status
    if [ $? -ne 0 ]                                                 # If System is lock
       then sadm_write_err "System '${server_name}' is lock, update not possible at this time."
            return 1 
    fi

    # Create lock file while O/S Update is running (this turn off monitoring)
    sadm_create_lockfile "${server_name}"                           # Stop monitoring server
    if [ $? -ne 0 ]                                                 # If Creation went OK
       then sadm_write_err "Update of '${server_name}' cancelled."  # Couldn't create lock file
            return 1 
    fi
    
    # Go and Script the O/S Update on the selected system.
    sadm_writelog " "
    sadm_writelog "Starting the O/S update on '${server_name}'."
    if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If not on SADMIN Server
        then sadm_writelog "$SADM_SSH_CMD $fqdn_server '${server_sadmin_dir}/bin/$USCRIPT ${WREBOOT}'"
             $SADM_SSH_CMD $fqdn_server ${server_sadmin_dir}/bin/$USCRIPT $WREBOOT
             RC=$? 
        else sadm_writelog "Starting execution of ${server_sadmin_dir}/bin/$USCRIPT "
             ${server_sadmin_dir}/bin/$USCRIPT                       # Run Locally when on SADMIN
             RC=$?
    fi      

    # After the O/S update is terminated, a reboot will be done on some occasion.
    # If user requested a reboot after each update, see reboot option when scheduling the O/S Update
    # We need to wait a moment to give the selected system time to reboot and become available again.
    # We will sleep 480 seconds (8 Min.) to give system time to restart and start it's app.
    if [ "$WREBOOT" != "" ]                                         # if Reboot requested
        then sadm_writelog "Sleep $REBOOT_TIME seconds, give time to '${server_name}' to become available."
             # Sleep for $REBOOT_TIME seconds and update progress bar every 30 seconds.
             sadm_sleep $REBOOT_TIME 30 
    fi 


    # Ignore if return an error.
    # Cause if script failed on remote, an alert has been generated for it, 
    # and we want only one alert for a failed update.
    #if [ $RC -ne 0 ]                                                    # Update went Successfully?
    #   then sadm_write "${SADM_ERROR} O/S Update completed with error on '${server_name}'.\n"
    #        update_server_db "${server_name}" "F"                       # Update Status False in DB
    #   else sadm_write "${SADM_OK} O/S Update completed successfully on '${server_name}'.\n"
    #        update_server_db "${server_name}" "S"                       # Update Status Success 
    #fi
    
    sadm_write "O/S Update completed on '${server_name}'.\n"            # Advise User were back .
    return 0
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
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
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
#
    cmd_options "$@"                                                    # Check command-line Options
    if [ $# -ne 1 ]                                                     # MUST be hostname to update
        then printf "\n${SADM_ERROR} Please specify the system name.\n" # Advise user of error
             exit 1                                                     # Exit To O/S
        else ONE_SERVER=$1                                              # Save Server Name to Update
    fi 
    SADM_PDESC="Operating system update of '$ONE_SERVER'"               # Desc of running program
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    rcmd_osupdate                                                       # Go Update Server
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_remove_lockfile "${ONE_SERVER}"                                # Go remove the lock file
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
