#! /usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_osupdate_farm.sh
#   Synopsis :  Apply O/S update to all active or selected selected servers
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
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x





#===================================================================================================
#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================

    # Make sure the 'SADMIN' environment variable defined and pointing to the install directory.
    if [ -z $SADMIN ] || [ "$SADMIN" = "" ]
        then # Check if the file /etc/environment exist, if not exit.
             missetc="Missing /etc/environment file, create it and add 'SADMIN=/InstallDir' line." 
             if [ ! -e /etc/environment ] ; then printf "${missetc}\n" ; exit 1 ; fi
             # Check if can use SADMIN definition line in /etc/environment to continue
             missenv="Please set 'SADMIN' environment variable to the install directory."
             grep "SADMIN" /etc/environment >/dev/null 2>&1             # SADMIN line in /etc/env.? 
             if [ $? -eq 0 ]                                             # Yes use SADMIN definition
                 then export SADMIN=`grep "SADMIN" /etc/environment | awk -F\= '{ print $2 }'` 
                      misstmp="Temporarily setting 'SADMIN' environment variable to '${SADMIN}'."
                      missvar="Add 'SADMIN=${SADMIN}' in /etc/environment to suppress this message."
                      if [ ! -e /bin/launchctl ] ; then printf "${missvar}" ; fi 
                      printf "\n${missenv}\n${misstmp}\n\n"
                 else missvar="Add 'SADMIN=/InstallDir' in /etc/environment to remove this message."
                      printf "\n${missenv}\n$missvar\n"                  # Advise user what to do   
                      exit 1                                             # Back to shell with Error
             fi
    fi 
        
    # Check if SADMIN environment variable is properly defined, check if can locate Shell Library.
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                            # Shell Library not readable
        then missenv="Please set 'SADMIN' environment variable to the install directory."
             printf "${missenv}\nSADMIN library ($SADMIN/lib/sadmlib_std.sh) can't be located\n"     
             exit 1                                                     # Exit to Shell with Error
    fi

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library.)
    export SADM_VER='3.16'                              # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="Y"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Ok now, load Standard Shell Library
    export SADM_OS_NAME=$(sadm_get_osname)              # Uppercase, REDHAT,CENTOS,UBUNTU,AIX,DEBIAN
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are taken from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=60                          # When script end Trim rch file to 60 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================
#===================================================================================================





# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
ERROR_COUNT=0                               ; export ERROR_COUNT        # Nb. of update failed
WARNING_COUNT=0                             ; export WARNING_COUNT      # Nb. of warning failed
STAR_LINE=`printf %80s |tr " " "*"`         ; export STAR_LINE          # 80 equals sign line
ONE_SERVER=""                               ; export ONE_SERVER         # Name If One server to Upd.


# Script That is run on every client to update the Operating System
USCRIPT="sadm_osupdate.sh"                  ; export USCRIPT            # Script to execute on nodes



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-s   [ServerName]"
    printf "\n\t-v   (Show Script Version Info)"
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
    if [ "$WSTATUS" = "F" ]
        then sadm_write "Set O/S update status to 'Failed' in Database "   # Advise user of result
        else sadm_write "Set O/S update status to 'Success' in Database "  # Advise user of result
    fi
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
        then sadm_write "${SADM_ERROR} Updating $WSERVER in Database\n" # Inform user of Error 
             RCU=1                                                      # Set Error Code
        else sadm_write "${SADM_OK}\n"                                  # Inform User of success
             RCU=0                                                      # Set Error Code = Success 
    fi
    return $RCU
}





# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_servers()
{
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_update_auto, "
    SQL2="srv_update_reboot, srv_sporadic, srv_active, srv_sadmin_dir from server "
    SQL3="where srv_ostype = 'linux' and srv_active = True "            # Got to Be a Linux & Active
    if [ "$ONE_SERVER" != "" ]                                          # Update for 1 Server Only
        then SQL4="and srv_name = '$ONE_SERVER' ;"                      # Select only 1 server
        else SQL4="order by srv_name; "                                 # Sort by server name
    fi
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"                                  # Build Final SQL Statement 
    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL'"        # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
   
    # LOOP THROUGH ACTIVE SERVERS FILE LIST
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
            do
            xcount=`expr $xcount + 1`
            server_name=`               echo $wline|awk -F\; '{ print $1 }'`
            server_os=`                 echo $wline|awk -F\; '{ print $2 }'`
            server_domain=`             echo $wline|awk -F\; '{ print $3 }'`
            server_update_auto=`        echo $wline|awk -F\; '{ print $4 }'`
            server_update_reboot=`      echo $wline|awk -F\; '{ print $5 }'`
            server_sporadic=`           echo $wline|awk -F\; '{ print $6 }'`
            server_sadmin_dir=`         echo $wline|awk -F\; '{ print $8 }'`
            fqdn_server=`echo ${server_name}.${server_domain}`          # Create FQN Server Name
            sadm_write "\n"
            sadm_write "${STAR_LINE}\n"
            info_line="Processing ($xcount) ${server_name}.${server_domain} - "
            info_line="${info_line}os:${server_os}"
            sadm_write "${info_line}\n"
            
            # TRY TO PING SERVER TO VERIFY IF IT'S REACHABLE ---------------------------------------
            sadm_write "Ping host $fqdn_server "
            ping -c2 $fqdn_server >> /dev/null 2>&1
            if [ $? -ne 0 ]
                then    sadm_write "${SADM_ERROR} Trying to ping $fqdn_server \n"
                        if [ "$server_sporadic" = "1" ]
                            then    sadm_write "${SADM_WARNING} Sporadic system now offline.\n"
                                    sadm_write "Will continue with next server.\n"
                                    WARNING_COUNT=$(($WARNING_COUNT+1))
                            else    sadm_write "${SADM_ERROR} Update of $fqdn_server Aborted\n"
                                    ERROR_COUNT=$(($ERROR_COUNT+1))
                        fi
                        if [ "$ERROR_COUNT" != "0" ] || [ "$WARNING_COUNT" != "0" ] 
                            then sadm_write "Error at ${ERROR_COUNT}, Warning at ${WARNING_COUNT}\n"
                        fi
                        continue
                else
                        sadm_write "${SADM_OK}\n"
            fi


            # IF SERVER IS NETWORK REACHABLE, BUT THE O/S UPDATE FIELD IS OFF IN DB SKIP UPDATE
            if [ "$server_update_auto" = "0" ] && [ "$ONE_SERVER" = "" ] 
                then sadm_write "*** O/S UPDATE IS OFF FOR THIS SERVER\n"
                     sadm_write "*** NO O/S UPDATE WILL BE PERFORM - CONTINUE WITH NEXT SERVER\n"
                     if [ "$SADM_ALERT_TYPE" = "3" ]
                         then wsubject="SADM: WARNING O/S Update - Server $server_name (O/S Update OFF)" 
                              echo "Server O/S Update is OFF"  | mail -s "$wsubject" $SADM_MAIL_ADDR
                     fi
                else WREBOOT=""                                         # Def. No Cli Opt for reboot
                     if [ "$server_update_reboot" = "1" ]               # If Requested in Database
                        then WREBOOT="-r"                               # Add -r option to reboot  
                     fi                                                 # This reboot after Update
                     #sadm_write "Starting $USCRIPT on ${server_name}.${server_domain}\n"
                     if [ "${server_name}.${server_domain}" != "$SADM_SERVER" ]
                        then UPDATE_RUNNING="${SADM_TMP_DIR}/osupdate_running_${server_name}"
                             sadm_write "\nSuspend monitoring while O/S update is running.\n"
                             sadm_write "Create O/S update running indicator file '${UPDATE_RUNNING}' " 
                             echo $(date) > ${UPDATE_RUNNING}           # Create OSUPDATE Flag File
                             if [ $? -eq 0 ]                            # If Touch went OK
                                then sadm_write "${SADM_OK}\n"          # Show [ OK ] and NewLine
                                else sadm_write "${SADM_ERROR}\n"       # Show [ ERROR ] and NewLine
                             fi
                             sadm_write "\nStarting the O/S update on '${server_name}'.\n"
                             sadm_write "$SADM_SSH_CMD $fqdn_server '${server_sadmin_dir}/bin/$USCRIPT ${WREBOOT}'\n\n"
                             $SADM_SSH_CMD $fqdn_server ${server_sadmin_dir}/bin/$USCRIPT $WREBOOT
                        else sadm_write "Starting execution of ${server_sadmin_dir}/bin/$USCRIPT \n"
                             ${server_sadmin_dir}/bin/$USCRIPT 
                     fi                             
                     if [ $? -ne 0 ]
                        then sadm_write "Error starting $USCRIPT on ${server_name}.${server_domain}\n"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                             update_server_db "${server_name}" "F"  
                        else sadm_write "Script was submitted with success.\n"
                             update_server_db "${server_name}" "S"  
                     fi
            fi
            if [ "$ERROR_COUNT" -ne 0 ] || [ "$WARNING_COUNT" -ne 0 ] 
                then sadm_write "Total Error is $ERROR_COUNT and Warning at ${WARNING_COUNT}\n"
            fi 
            sadm_write "\n"
            done < $SADM_TMP_FILE1
    fi
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
    ONE_SERVER=""                                                       # Set Switch Default Value
    while getopts "d:hvs:" opt ; do                                     # Loop to process Switch
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
            s) ONE_SERVER="$OPTARG"                                     # Display Only Server Name
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

    process_servers                                                     # Go Update Servers
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
