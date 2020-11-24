#! /usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_osupdate_starter.sh
#   Synopsis :  Apply O/S update to selected selected servers
#   Version  :  1.0
#   Date     :  9 March 2015 
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_osupdate_farm.sh 1.0 2015/03/10
# --------------------------------------------------------------------------------------------------
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
# 2018_06_10  v3.7 Change name to sadm_osupdate_farm.sh - and change client script name
# 2018_07_01  v3.8 Use SADMIN dir. of client from DB & allow running multiple instance at once
# 2018_07_11  v3.9 Solve problem when running update on SADMIN server (Won't start)
# 2018_09_19  v3.10 Include Alert Group
# 2018_10_24  v3.11 Adjustment needed to call sadm_osupdate.sh with or without '-r' (reboot) option.
# 2019_07_14 Update: v3.12 Adjustment for Library Changes.
# 2019_12_22 Fix: v3.13 Fix problem when using debug (-d) option without specifying level of debug.
#@2020_05_23 Update: v3.14 Create 'osupdate_running' file before launching O/S update on remote.
#@2020_07_28 Update: v3.15 Move location of o/s update is running indicator file to $SADMIN/tmp.
#@2020_10_29 Fix: v3.16 If comma was used in server description, it cause delimiter problem.
#@2020_11_04 Minor: v3.17 Minor code modification.
#@2020_11_20 Update: v4.0 Restructure & rename from sadm_osupdate_farm to sadm_osupdate_starter.
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x




#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================

# MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # If SADMIN EnvVar not right
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null          # SADMIN in /etc/environment
         if [ $? -eq 0 ]                                                # Yes it is 
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' Environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                 # Current Script filename(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`       # Current Script filename(without extension)
export SADM_TPID="$$"                                   # Current Script Process ID.
export SADM_HOSTNAME=`hostname -s`                      # Current Host name without Domain Name
export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Std Libr.).
export SADM_VER='4.0'                                   # Current Script Version
export SADM_EXIT_CODE=0                                 # Current Script Default Exit Return Code
export SADM_LOG_TYPE="B"                                # writelog go to [S]creen [L]ogFile [B]oth
export SADM_LOG_APPEND="N"                              # [Y]=Append Existing Log [N]=Create New One
export SADM_LOG_HEADER="Y"                              # [Y]=Include Log Header  [N]=No log Header
export SADM_LOG_FOOTER="Y"                              # [Y]=Include Log Footer  [N]=No log Footer
export SADM_MULTIPLE_EXEC="N"                           # Allow running multiple copy at same time ?
export SADM_USE_RCH="Y"                                 # Gen. History Entry in ResultCodeHistory 
export SADM_DEBUG=0                                     # Debug Level - 0=NoDebug Higher=+Verbose
export SADM_TMP_FILE1=""                                # Tmp File1 you can use, Libr. will set name
export SADM_TMP_FILE2=""                                # Tmp File2 you can use, Libr. will set name
export SADM_TMP_FILE3=""                                # Tmp File3 you can use, Libr. will set name

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                          # LOAD SADMIN Standard Shell Libr. Functions
export SADM_OS_NAME=$(sadm_get_osname)                  # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
export SADM_OS_VERSION=$(sadm_get_osversion)            # O/S Full Version Number  (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)      # O/S Major Version Number (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/CFG/SADMIN.CFG FILE).
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                               # 0=None 1=AlertOnError 2=AlertOnOK 3=Always
#export SADM_ALERT_GROUP="default"                      # Alert Group to advise (alert_group.cfg)
#export SADM_MAIL_ADDR="your_email@domain.com"          # Email to send log (Override sadmin.cfg)
#export SADM_MAX_LOGLINE=500                            # At the end Trim log to 500 Lines(0=NoTrim)
#export SADM_MAX_RCLINE=35                              # At the end Trim rch to 35 Lines (0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT        # Nb. of update failed
WARNING_COUNT=0                             ; export WARNING_COUNT      # Nb. of warning failed
STAR_LINE=`printf %80s |tr " " "*"`         ; export STAR_LINE          # 80 equals sign line
ONE_SERVER=""                               ; export ONE_SERVER         # Name If One server to Upd.

# Script That is to be run on remote client to update the Operating System
USCRIPT="sadm_osupdate.sh"                  ; export USCRIPT            # Script to execute on nodes




# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${BOLD}${SADM_PN} [-d Level] [-h] [-v] hostname${NORMAL}" 
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
        then sadm_write "${SADM_ERROR} The system '$ONE_SERVER' was not found is the Database.\n"
             return 1                                                   # Return Error to Caller
        else sadm_write "${SADM_OK} Information about '$ONE_SERVER' found in Database.\n"
    fi 
    

    while read wline
        do
        server_name=`               echo $wline|awk -F\; '{ print $1 }'`
        server_os=`                 echo $wline|awk -F\; '{ print $2 }'`
        server_domain=`             echo $wline|awk -F\; '{ print $3 }'`
        server_update_auto=`        echo $wline|awk -F\; '{ print $4 }'`
        server_update_reboot=`      echo $wline|awk -F\; '{ print $5 }'`
        server_sporadic=`           echo $wline|awk -F\; '{ print $6 }'`
        server_sadmin_dir=`         echo $wline|awk -F\; '{ print $8 }'`
        fqdn_server=`echo ${server_name}.${server_domain}`          # Create FQN Server Name
            
        # Ping to server 
        ping -c2 $fqdn_server >> /dev/null 2>&1
        if [ $? -ne 0 ]
            then sadm_write "${SADM_ERROR} Trying to ping $fqdn_server \n"
                 if [ "$server_sporadic" = "1" ]
                     then    sadm_write "${SADM_WARNING} Sporadic system now offline.\n"
                             WARNING_COUNT=$(($WARNING_COUNT+1))
                     else    sadm_write "${SADM_ERROR} Could not ping ${fqdn_server}.\n"
                             sadm_write "Update is not possible, process aborted.\n"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                 fi
                 return $ERROR_COUNT                                    # Return to Caller
            else sadm_write "${SADM_OK} Ping host $fqdn_server \n"
        fi

        # IF SERVER O/S UPDATE FIELD IS OFF IN DATABASE, SKIP UPDATE
        if [ "$server_update_auto" = "0" ]
            then sadm_write "${SADM_WARNING} O/S Update for '${fqdn_server}' isn't activated.\n"
                 sadm_write "No O/S Update will be perform.\n"
                 return 1
        fi 


        # Activate or not the reboot at the end of the O/S Update.
        WREBOOT=""                                                      # Def. Action = NO reboot
        if [ "$server_update_reboot" = "1" ]                            # If Requested in Database
            then WREBOOT="-r"                                           # Add -r option to reboot  
        fi                                                              # This reboot after Update

        # Create a file name $UPDATE_RUNNING while O/S Update is running (this turn off monitoring)
        UPDATE_RUNNING="${SADM_TMP_DIR}/osupdate_running_${server_name}"
        echo $(date) > ${UPDATE_RUNNING}                                # Create OSUPDATE Flag File
        if [ $? -eq 0 ]                                                 # If Touch went OK
           then sadm_write "${SADM_OK} Suspend monitoring while O/S update is running.\n"  
           else sadm_write "${SADM_ERROR} Creating O/S update indicator file '${UPDATE_RUNNING}' \n" 
        fi
        
        
        #sadm_write "Starting $USCRIPT on ${server_name}.${server_domain}\n"
        sadm_write "\nStarting the O/S update on '${server_name}'.\n"
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If not on SADMIN Server
            then sadm_write "$SADM_SSH_CMD $fqdn_server '${server_sadmin_dir}/bin/$USCRIPT ${WREBOOT}'\n\n"
                 $SADM_SSH_CMD $fqdn_server ${server_sadmin_dir}/bin/$USCRIPT $WREBOOT
                 RC=$? 
            else sadm_write "Starting execution of ${server_sadmin_dir}/bin/$USCRIPT \n"
                 ${server_sadmin_dir}/bin/$USCRIPT                       # Run Locally when on SADMIN
                 RC=$?
        fi                             
        if [ $RC -ne 0 ]                                                # Update went Successfully ?
           then sadm_write "${SADM_ERROR} O/S Update completed with error on '${server_name}'.\n"
                ERROR_COUNT=$(($ERROR_COUNT+1))                         # Increment Error Counter
                update_server_db "${server_name}" "F"                   # Update Status False in DB
           else sadm_write "${SADM_OK} O/S Update completed successfully on '${server_name}'.\n"
                update_server_db "${server_name}" "S"                   # Update Status Success in DB
        fi
        done < $SADM_TMP_FILE1

    if [ "$ERROR_COUNT" -ne 0 ] || [ "$WARNING_COUNT" -ne 0 ] 
       then sadm_write "Total Error is $ERROR_COUNT and Warning at ${WARNING_COUNT}\n"
    fi 
    return $ERROR_COUNT
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

    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user, process aborted.\n"
             sadm_write "Try sudo %s" "${0##*/}\n"                      # Suggest using sudo
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_write "Script can only be run on (${SADM_SERVER}), process aborted.\n"
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Get the server Name to Update, Else exit with Error.
    if [ $# -ne 1 ]
        then sadm_write "\n${SADM_ERROR} You need to specify the server name you wish to update.\n"
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
        else ONE_SERVER=$1                                              # Save Server Name to Update
    fi 

    rcmd_osupdate                                                       # Go Update Server
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)