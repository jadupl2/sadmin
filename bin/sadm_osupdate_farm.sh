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
# 2016_11_11  v2.6 Insert Logic to Pass a param. (Y/N) to sadm_osupdate_client.sh to Reboot or not
#                  server after successfull update. Reboot is specified in Database (Web Interface)
#                  on a server by server basis.
# 2016_11_15  v2.7 Log will now be cumulative (Not clear every time the script in run)
# 2017_02_03  v2.8 Database Columns were changed
# 2017_03_15  v2.9 Add Logic for command line switch [-s servername] to update only one server
#                  Command line swtich [-h]  for help also added
# 2017_03_17  v3.0 Not a cumulative log anymore
# 2017_04_05  v3.1 Allow program to run more than once at same time, to allow simultanious Update
#                  Put Back cumulative Log, so don't miss anything, when multiple update running
# 2017_12_10  v3.2 Adapt program to use MySQL instead of PostGres 
# 2017_12_12  V3.3 Correct Problem connecting to Database
# 2018_02_08  V3.4 Fix Compatibility problem with 'sadh' shell (If statement)
# 2018_06_05  v3.5 Add Switch -v to view version, change help message, adapt to new Libr.
# 2018_06_09  v3.6 Change the name  of the client o/s update script & Change name of this script
# 2018_06_10  v3.7 Change name to sadm_osupdate_farm.sh - and change client script name
# 2018_07_01  v3.8 Use SADMIN dir. of client from DB & allow running multiple instance at once
# 2018_07_11  v3.9 Solve problem when running update on SADMIN server (Won't start)
# 2018_09_19  v3.10 Include Alert Group
# 2018_10_24  v3.11 Adjustment needed to call sadm_osupdate.sh with or without '-r' (reboot) option.
#@2019_07_14 Update: v3.12 Adjustment for Library Changes.
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
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
             grep "^SADMIN" /etc/environment >/dev/null 2>&1             # SADMIN line in /etc/env.? 
             if [ $? -eq 0 ]                                             # Yes use SADMIN definition
                 then export SADMIN=`grep "^SADMIN" /etc/environment | awk -F\= '{ print $2 }'` 
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
    export SADM_VER='3.12'                              # Your Current Script Version
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
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
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
#          Update Last Date of Last O/S Update and Result in Server Table in SADMIN Database
# --------------------------------------------------------------------------------------------------
update_server_db()
{
    WSERVER=$1                                                          # Server Name to Update
    WSTATUS=$2                                                          # Status of OS Update (F/S)
    WCURDAT=`date "+%C%y.%m.%d %H:%M:%S"`                               # Get & Format Update Date

    # Construct SQL Update Statement
    sadm_writelog "Record O/S Update Status & Date for $WSERVER in DataBase" # Advise user
    SQL1="UPDATE server SET "                                           # SQL Update Statement
    SQL2="srv_date_osupdate = '${WCURDAT}', "                           # Update Date of this Update
    SQL3="srv_update_status = '${WSTATUS}' "                            # [S]uccess [F]ail [R]unning
    SQL4="where srv_name = '${WSERVER}' ;"                              # Server name to update
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"                                  # Create final SQL Statement
    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -e '$SQL'"           # Build Full Command Line
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -e "$SQL" >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]                                                     # If Error while updating
        then sadm_writelog "Error updating $WSERVER in Database"        # Inform user of Error 
             RCU=1                                                      # Set Error Code
        else sadm_writelog "Database Update Succeeded"                  # Inform User of success
             RCU=0                                                      # Set Error Code = Success 
    fi
    return $RCU
}





# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_servers()
{
    #sadm_writelog "PROCESS LINUX SERVERS"
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_update_auto, "
    SQL2="srv_update_reboot, srv_sporadic, srv_active, srv_sadmin_dir from server "
    if [ "$ONE_SERVER" != "" ] 
        then SQL3="where srv_ostype = 'linux' and srv_active = True " 
             SQL4="and srv_name = '$ONE_SERVER' ;"
        else SQL3="where srv_ostype = 'linux' and srv_active = True "
             SQL4="order by srv_name; "
    fi
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}"                                  # Build Final SQL Statement 

    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL'"        # Build Full Command Line
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1
   
    # LOOP THROUGH ACTIVE SERVERS FILE LIST
    xcount=0; ERROR_COUNT=0;
    if [ -s "$SADM_TMP_FILE1" ]
       then while read wline
            do
            xcount=`expr $xcount + 1`
            server_name=`               echo $wline|awk -F, '{ print $1 }'`
            server_os=`                 echo $wline|awk -F, '{ print $2 }'`
            server_domain=`             echo $wline|awk -F, '{ print $3 }'`
            server_update_auto=`        echo $wline|awk -F, '{ print $4 }'`
            server_update_reboot=`      echo $wline|awk -F, '{ print $5 }'`
            server_sporadic=`           echo $wline|awk -F, '{ print $6 }'`
            server_sadmin_dir=`         echo $wline|awk -F, '{ print $8 }'`
            fqdn_server=`echo ${server_name}.${server_domain}`          # Create FQN Server Name
            sadm_writelog " "
            sadm_writelog "${STAR_LINE}"
            info_line="Processing ($xcount) ${server_name}.${server_domain} - "
            info_line="${info_line}os:${server_os}"
            sadm_writelog "$info_line"
            
            # TRY TO PING SERVER TO VERIFY IF IT'S REACHABLE ---------------------------------------
            sadm_writelog "Ping host $fqdn_server"
            ping -c2 $fqdn_server >> /dev/null 2>&1
            if [ $? -ne 0 ]
                then    sadm_writelog "Error trying to ping host $fqdn_server"
                        if [ "$server_sporadic" = "1" ]
                            then    sadm_writelog "[WARNING] This host is sporadically online"
                                    sadm_writelog "Will continue with next server"
                                    WARNING_COUNT=$(($WARNING_COUNT+1))
                            else    sadm_writelog "Update of server $fqdn_server Aborted"
                                    ERROR_COUNT=$(($ERROR_COUNT+1))
                        fi
                        if [ "$ERROR_COUNT" != "0" ] || [ "$WARNING_COUNT" != "0" ] 
                            then sadm_writelog "Error at ${ERROR_COUNT}, Warning at $WARNING_COUNT"
                        fi
                        continue
                else
                        sadm_writelog "[OK] Ping worked"
            fi


            # IF SERVER IS NETWORK REACHABLE, BUT THE O/S UPDATE FIELD IS OFF IN DB SKIP UPDATE
            if [ "$server_update_auto" = "0" ] && [ "$ONE_SERVER" = "" ] 
                then sadm_writelog "*** O/S UPDATE IS OFF FOR THIS SERVER"
                     sadm_writelog "*** NO O/S UPDATE WILL BE PERFORM - CONTINUE WITH NEXT SERVER"
                     if [ "$SADM_ALERT_TYPE" = "3" ]
                         then wsubject="SADM: WARNING O/S Update - Server $server_name (O/S Update OFF)" 
                              echo "Server O/S Update is OFF"  | mail -s "$wsubject" $SADM_MAIL_ADDR
                     fi
                else WREBOOT=""                                         # Default is no reboot
                     if [ "$server_update_reboot" = "1" ]               # If Requested in Database
                        then WREBOOT=" -r"                              # Set Reboot flag to ON
                     fi                                                 # This reboot after Update
                     sadm_writelog "Starting $USCRIPT on ${server_name}.${server_domain}"
                     if [ "${server_name}.${server_domain}" != "$SADM_SERVER" ]
                        then sadm_writelog "$SADM_SSH_CMD ${server_name}.${server_domain} ${server_sadmin_dir}/bin/$USCRIPT $WREBOOT"
                             $SADM_SSH_CMD ${server_name}.${server_domain} ${server_sadmin_dir}/bin/$USCRIPT $WREBOOT
                        else sadm_writelog "Starting execution of ${server_sadmin_dir}/bin/$USCRIPT"
                             ${server_sadmin_dir}/bin/$USCRIPT 
                     fi                             
                     if [ $? -ne 0 ]
                        then sadm_writelog "Error starting $USCRIPT on ${server_name}.${server_domain}"
                             ERROR_COUNT=$(($ERROR_COUNT+1))
                             update_server_db "${server_name}" "F"  
                        else sadm_writelog "Script was submitted with no error."
                             update_server_db "${server_name}" "S"  
                     fi
            fi
            sadm_writelog "Total Error is $ERROR_COUNT and Warning at $WARNING_COUNT"
            sadm_writelog " "
            done < $SADM_TMP_FILE1
    fi
    #sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Total Error is $ERROR_COUNT and Warning at $WARNING_COUNT"
    return $ERROR_COUNT
}



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    
    # If you want this script to be run only by 'root'.
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo %s" "${0##*/}"                          # Suggest using sudo
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S with error
    fi

    sadm_start                                                          # Start Using SADM Tools
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init

    ONE_SERVER=""                                                       # Set Switch Default Value
    while getopts "hvd:s:" opt ; do                                     # Loop to process Switch
        case $opt in
            s) ONE_SERVER="$OPTARG"                                     # Display Only Server Name
               ;;
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page 
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
        done             
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}" ; fi


    # RUN ON THE SADMIN MAIN SERVER ONLY
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ] # Only run on SADMIN 
        then sadm_writelog "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    process_servers                                                     # Go Update Servers
    SADM_EXIT_CODE=$?                                                   # Save Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
