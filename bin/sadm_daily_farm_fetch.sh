#! /usr/bin/env bash
####################################################################################################
# Title      :  sadm_daily_farm_fetch.sh
# Description:  Collect Hardware/Software/Performance Info Data from all actives servers
# Version    :  1.8
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) sadm_daily_farm_fetch.sh 1.4 21-04/2010
####################################################################################################
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
# CHANGE LOG
#
# 2015_10_10    v1.9 Restructure and redesign for modularity
# 2017_12_17    v2.0 Restructure for combining Aix and Linux
# 2017_12_23    v2.1 Modifications for using MySQL and logic Enhancements
# 2018_01_08    v2.2 Update SADM Library insertion section & Minor correction
# 2018_02_02    v2.3 Added Operation Separator in log 
# 2018_02_08    v2.4 Fix compatibility problem with 'dash' shell
# 2018_02_11    v2.5 Rsync locally for SADMN Server
# 2018_05_01    v2.6 Don't return an error if no active server are found & remove unnecessary message
# 2018_06_03    v2.7 Minor Corrections & Adapt to New SADM Shell Library.
# 2018_06_09    v2.8 Change Script Name & Add Help and Version Function & Change Startup Order
# 2018_06_11    v2.9 Change name for sadm_daily_farm_fetch.sh
# 2018_06_30    v3.0 Now get /etc/environment from client to know where SADMIN is install for rsync
# 2018_07_16    v3.1 Remove verbose when doing rsync
# 2018_08_24    v3.2 If couldn't get /etc/environment from client, change Email format.
# 2018_09_16    v3.3 Added Default Alert Group
# 2019_02_27 Change: v3.4 Change error message when ping to system don't work
# 2019_05_07 Update: v3.5 Add 'W 5' ping option, should produce less false alert
# 2020_02_25 Update: v3.6 Fix intermittent problem getting SADMIN value from /etc/environment.
# 2020_03_21 Update: v3.7 Show Error Total only at the end of each system processed.
# 2020_04_05 Update: v3.8 Replace function sadm_writelog() with NL incl. by sadm_write() No NL Incl.
# 2020_04_21 Update: v3.9 Minor Error Message Alignment,
# 2020_04_24 Update: v4.0 Show rsync status & solve problem if duplicate entry in /etc/environment.
# 2020_05_06 Update: v4.1 Modification to log structure
# 2020_05_23 Update: v4.2 No longer report an error, if a system is rebooting because of O/S update.
# 2020_10_29 Fix: v4.3 If comma was used in server description, it cause delimiter problem.
# 2020_11_05 Update: v4.4 Change msg written to log & no alert while o/s update is running.
# 2020_12_12 Update: v4.5 Add and use SADM_PID_TIMEOUT and SADM_LOCK_TIMEOUT Variables.
# 2021_02_13 Minor: v4.5 Change for log appearance.
#@2021_06_03 Update: v4.6 Update SADMIN section and minor code update
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.50
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
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
export SADM_VER='4.6'                                      # Script Version
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





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
HW_DIR="$SADM_DAT_DIR/hw"	                     ; export HW_DIR        # Hardware Data collected
ERROR_COUNT=0                                    ; export ERROR_COUNT   # Global Error Counter
TOTAL_AIX=0                                      ; export TOTAL_AIX     # Nb Error in Aix Function
TOTAL_LINUX=0                                    ; export TOTAL_LINUX   # Nb Error in Linux Function
SADM_STAR=`printf %80s |tr " " "*"`              ; export SADM_STAR     # 80 * line
DEBUG_LEVEL=0                                    ; export DEBUG_LEVEL   # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Show Script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}





# --------------------------------------------------------------------------------------------------
#                                   Process All Actives Servers 
# --------------------------------------------------------------------------------------------------
process_servers()
{
    sadm_write "${BOLD}Processing All Actives Server(s)${NORMAL}\n"

    # BUILD THE SELECT STATEMENT FOR ACTIVE SERVER & OUTPUT RESULT IN CSV FORMAT TO $SADM_TMP_FILE1
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active"
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName

    # RUN THE SELECT STATEMENT
    CMDLINE1="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "        # MySQL & Use Read Only User  
    if [ $DEBUG_LEVEL -gt 5 ]                                           # If Debug Level > 5 
        then sadm_write "$CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' |tr '/\t/' '/,/'\n"
    fi
    $CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1

    # IF FILE WAS NOT CREATED OR HAS A ZERO LENGTH THEN NO ACTIVES SERVERS WERE FOUND
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_write "${BOLD}No Active Server were found.${NORMAL}\n" 
             return 0 
    fi 

    # PROCESS EACH SYSTEM PRESENT IN THE FILE CREATED BY THE SELECT STATEMENT
    xcount=0; ERROR_COUNT=0;                                            # Reset Server/Error Counter
    while read wline                                                    # Then Read Line by Line
        do
        xcount=`expr $xcount + 1`                                       # Server Counter
        server_name=`    echo $wline|awk -F\; '{ print $1 }'`           # Extract Server Name
        server_os=`      echo $wline|awk -F\; '{ print $2 }'`           # Extract O/S (linux/aix)
        server_domain=`  echo $wline|awk -F\; '{ print $3 }'`           # Extract Domain of Server
        server_monitor=` echo $wline|awk -F\; '{ print $4 }'`           # Monitor  t=True f=False
        server_sporadic=`echo $wline|awk -F\; '{ print $5 }'`           # Sporadic t=True f=False
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQN Server Name
        sadm_write "\n"
        sadm_write "${BOLD}Processing ($xcount) ${fqdn_server}${NORMAL}\n" # Show Cur.Syst.
        
        # IF SERVER NAME CAN'T BE RESOLVED - SIGNAL ERROR TO USER AND CONTINUE WITH NEXT SYSTEM.
        if ! host $fqdn_server >/dev/null 2>&1
            then SMSG="${SADM_ERROR} Can't process '$fqdn_server', hostname can't be resolved."
                 sadm_write "${SMSG}\n"                                 # Advise user
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 sadm_write "Error Count is now at $ERROR_COUNT \n"
                 continue                                               # Continue with next Server
        fi

        # Lock File is created when the remote O/S update start (or for Maintenance Period).
        # Prevent to return an error if not able to ssh to server (May be rebooting after update)
        # Lock file will be deleted when the file creation date is older than $SADM_LOCK_TIMEOUT.
        LOCK_FILE="${SADM_TMP_DIR}/${server_name}.lock"                 # Prevent Monitor lock file
        if [ -f "$LOCK_FILE" ]                                          # If O/S Update running 
           then FEPOCH=`stat -c %Y $LOCK_FILE`                          # Get File Modif. Epoch Time
                CEPOCH=$(sadm_get_epoch_time)                           # Get Current Epoch Time
                FAGE=`expr $CEPOCH - $FEPOCH`                           # Nb. Sec. OSUpdate running
                SEC_LEFT=`expr $SADM_LOCK_TIMEOUT - $FAGE`              # Sec left before delete lck
                if [ $FAGE -gt $SADM_LOCK_TIMEOUT ]                     # Running more than 90Min ?
                   then msg="${BOLD}Server is lock for more than $SADM_LOCK_TIMEOUT seconds.${NORMAL}"
                        sadm_writelog "${msg}"
                        msg="${BOLD}Will now start to monitor this system as usual.${NORMAL}"
                        sadm_writelog "${msg}"
                        rm -f LOCK_FILE > /dev/null 2>&1                # Remove O/S Upd Flag File
                   else msg="${SADM_WARNING} '$fqdn_server' server is lock."
                        sadm_writelog "${msg}"
                        msg1="Normal monitoring will resume in ${SEC_LEFT} seconds, "
                        msg2="time allowed to keep a server lock is ${SADM_LOCK_TIMEOUT} sec."
                        sadm_writelog "${msg1}${msg2}"
                        continue                                        # Continue with Nxt Server
                fi 
        fi 

        # TEST SSH TO SERVER (IF NOT ON SADMIN SERVER)
        if [ "${server_name}" != "$SADM_HOSTNAME" ]                     # If not on SADMIN Server 
            then $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1       # Try SSH to Server for date
                 RC=$?                                                  # Save Error Number
            else RC=0                                                   # RC=0 no SSH on SADMIN Srv
        fi 

        if [ $RC -ne 0 ]                                                # If SSH didn't worked
           then if [ "$server_sporadic" = "1" ]                # If Error on Sporadic Host
                   then sadm_write "${SADM_WARNING}  Can't SSH to ${fqdn_server} (Sporadic System).\n"
                     continue
                fi 
                if [ "$server_monitor" = "0" ]                 # If Error & Monitor is OFF
                   then sadm_write "${SADM_WARNING} Can't SSH to ${fqdn_server} (Monitoring is OFF).\n"
                        continue
                fi 
                if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_write "Return Code is $RC \n" ;fi 
                sadm_write "$SADM_ERROR Can't SSH to ${fqdn_server} - Unable to process system.\n"
                ERROR_COUNT=$(($ERROR_COUNT+1))
                sadm_write "Error Count is now at $ERROR_COUNT \n"
                continue
        fi                                                              # OK SSH Worked the 1st time

        # MAKING SURE THE $SADMIN/DAT/$SERVER_NAME EXIST ON LOCAL SADMIN SERVER
        if [ ! -d "${SADM_WWW_DAT_DIR}/${server_name}" ]
            then sadm_writelog "Creating ${SADM_WWW_DAT_DIR}/${server_name} directory"
                 mkdir -p "${SADM_WWW_DAT_DIR}/${server_name}"
                 chmod 2775 "${SADM_WWW_DAT_DIR}/${server_name}"
        fi

        # Get the remote /etc/environment file to determine where SADMIN is install on remote
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}"
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then scp -P${SADM_SSH_PORT} ${server_name}:/etc/environment ${WDIR} >/dev/null 2>&1  
            else cp /etc/environment ${WDIR} >/dev/null 2>&1  
        fi
        if [ $? -eq 0 ]                                                 # If file was transferred
            then RDIR=`grep "SADMIN=" $WDIR/environment |sed 's/export //g' |awk -F= '{print $2}'|tail -1`
                 if [ "$RDIR" != "" ]                                   # No Remote Dir. Set
                    then sadm_writelog "SADMIN installed in ${RDIR} on ${server_name}."
                    else sadm_writelog "$SADM_WARNING Couldn't get /etc/environment."
                         if [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
                            then sadm_writelog "${server_name} is a sporadic system."
                            else ERROR_COUNT=$(($ERROR_COUNT+1))       # Add 1 to Error Count
                                 sadm_writelog "Error Count is now at $ERROR_COUNT"
                         fi
                         sadm_writelog "Continuing with next system."   # Advise we are skipping srv
                         continue                                       # Go process next system
                 fi 
            else sadm_writelog "$SADM_ERROR Couldn't get /etc/environment on ${server_name}."
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Add 1 to Error Count
                 sadm_writelog "Error Count is now at $ERROR_COUNT "
                 sadm_writelog "Continuing with next system."           # Advise we are skipping srv
                 continue                                               # Go process next system
        fi
    


        # DR (Disaster Recovery) Information Files
        # Transfer $SADMIN/dat/dr (Disaster Recovery) from Remote to $SADMIN/www/dat/$server/dr Dir.
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/dr"                    # Local Receiving Dir.
        #sadm_write "Make sure local directory $WDIR exist.\n"
        if [ ! -d "${WDIR}" ]
            then sadm_write "  - Creating ${WDIR} directory.\n"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
        fi
        REMDIR="${RDIR}/dat/dr" 
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then rcmd="rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else rcmd="rsync -ar --delete  ${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
            then sadm_writelog "$SADM_ERROR ($RC) ${rcmd}"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 sadm_writelog "Error Count is now at $ERROR_COUNT"
            else sadm_writelog "${SADM_OK} ${rcmd}"
        fi
 

        # NMON FILES
        # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server_name/nmon  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/nmon"                     # Local Receiving Dir.
        #sadm_write "Make sure local directory $WDIR exist.\n"
        if [ ! -d "${WDIR}" ]
            then sadm_write "  - Creating ${WDIR} directory.\n"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
        fi
        REMDIR="${RDIR}/dat/nmon" 
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then rcmd="rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else rcmd="rsync -ar --delete ${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
            then sadm_writelog "$SADM_ERROR ($RC) ${rcmd}"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
            else sadm_writelog "${SADM_OK} ${rcmd}" 
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count is now at $ERROR_COUNT" ;fi

        done < $SADM_TMP_FILE1

    sadm_write "\n${SADM_TEN_DASH}\nFINAL number of Error(s) detected is $ERROR_COUNT \n"
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



# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ; fi                    # Exit if Problem 

    # If you want this script to be run only by root user, uncomment the lines below.
    if [ $(id -u) -ne 0 ]                                               # If Cur. user is not root
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_writelog "Try 'sudo ${0##*/}'."                       # Suggest using sudo
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # If you want this script to be run only on the SADMIN server, uncomment the lines below.
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_write "Script can only be run on (${SADM_SERVER}), process aborted.\n"
             sadm_write "Process aborted\n"                             # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    process_servers                                                     # Collect Files from Servers
    SADM_EXIT_CODE=$?                                                   # Return Code = Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    