#! /usr/bin/env bash
####################################################################################################
# Title      :  sadm_daily_farm_fetch.sh
# Description:  Get Hardware/Software/Performance Info Data from all actives servers
# Version    :  1.8
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) sadm_daily_farm_fetch.sh 1.4 21-04/2010
####################################################################################################
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
#
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ "$SADMIN" = "" ]                             # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             printf "\nAdd this line to /etc/environment file; 'export SADMIN=/InstallDir'" 
             exit 1
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='4.1'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library
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



# --------------------------------------------------------------------------------------------------
#                                   Process All Actives Servers 
# --------------------------------------------------------------------------------------------------
process_servers()
{
    sadm_write "Processing All Actives Server(s)\n"

    # Select Active Server From Database & output result in CSV Format to $SADM_TMP_FILE1 work file
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active"
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    CMDLINE1="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL & Use Read Only User  
    #CMDLINE2="-h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' |tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ]                                           # If Debug Level > 5 
        then sadm_write "$CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' |tr '/\t/' '/,/'\n"
    fi
    $CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    # If File was not created or has a zero lenght then No Actives Servers were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_write "No Active Server were found.\n" 
             return 0 
    fi 

    xcount=0; ERROR_COUNT=0;                                            # Reset Server/Error Counter
    while read wline                                                    # Then Read Line by Line
        do
        xcount=`expr $xcount + 1`                                       # Server Counter
        server_name=`    echo $wline|awk -F, '{ print $1 }'`            # Extract Server Name
        server_os=`      echo $wline|awk -F, '{ print $2 }'`            # Extract O/S (linux/aix)
        server_domain=`  echo $wline|awk -F, '{ print $3 }'`            # Extract Domain of Server
        server_monitor=` echo $wline|awk -F, '{ print $4 }'`            # Monitor  t=True f=False
        server_sporadic=`echo $wline|awk -F, '{ print $5 }'`            # Sporadic t=True f=False
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQN Server Name
        #
        sadm_write "\n"
        #sadm_write "${SADM_TEN_DASH}\n"
        sadm_write "Processing ($xcount) $fqdn_server \n"               # Show Cur. System 
        
        if [ $DEBUG_LEVEL -gt 0 ]                                       # If Debug Activated
            then if [ "$server_monitor" = "1" ]                         # Monitor Flag is at True
                    then sadm_write "Monitoring is ON for $fqdn_server \n"
                    else sadm_write "Monitoring is OFF for $fqdn_server \n"
                 fi
                 if [ "$server_sporadic" = "1" ]                        # Sporadic Flag is at True
                    then sadm_write "Sporadic system is ON for $fqdn_server \n"
                    else sadm_write "Sporadic system is OFF for $fqdn_server \n"
                 fi
        fi

        # If Server Name can't be resolved - Signal Error to user and continue with next system.
        if ! host  $fqdn_server >/dev/null 2>&1
            then SMSG="[ ERROR ] Can't process '$fqdn_server', hostname can't be resolved"
                 sadm_write "${SMSG}\n"                                 # Advise user
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 sadm_write "Error Count is now at $ERROR_COUNT \n"
                 continue                                               # Continue with next Server
        fi

        # Try a Ping to the Server
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_write "ping -c 2 $fqdn_server \n" ; fi 
        ping -c 2 -W 5 $fqdn_server >/dev/null 2>/dev/null
        RC=$?
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_write "Return Code is $RC \n" ;fi 

        # If ping failed and it's a Sporadic Server, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
            then sadm_write "$SADM_WARNING Can't Ping the sporadic system $fqdn_server\n"
                 sadm_write "            Continuing with next system.\n"
                 continue                                               # Go process next system
        fi

        if [ $RC -ne 0 ]
            then sadm_write "$SADM_ERROR Ping to server failed - Unable to process system.\n"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 sadm_write "Error Count is now at $ERROR_COUNT \n"
                 continue
        fi


        # CREATE LOCAL RECEIVING DIR
        # Making sure the $SADMIN/dat/$server_name exist on Local SADMIN server
        #-------------------------------------------------------------------------------------------
        #sadm_write "Make sure local directory ${SADM_WWW_DAT_DIR}/${server_name} exist\n"
        if [ ! -d "${SADM_WWW_DAT_DIR}/${server_name}" ]
            then sadm_write "Creating ${SADM_WWW_DAT_DIR}/${server_name} directory\n"
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
                    then sadm_write "SADMIN installed in ${RDIR} on ${server_name}.\n"
                    else sadm_write "$SADM_WARNING Couldn't get /etc/environment.\n"
                         if [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
                            then sadm_write "${server_name} is a sporadic system.\n"
                            else ERROR_COUNT=$(($ERROR_COUNT+1))       # Add 1 to Error Count
                                 sadm_write "Error Count is now at $ERROR_COUNT \n"
                         fi
                         sadm_write "Continuing with next system.\n"    # Advise we are skipping srv
                         continue                                       # Go process next system
                 fi 
            else sadm_write "$SADM_ERROR Couldn't get /etc/environment on ${server_name}.\n"
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Add 1 to Error Count
                 sadm_write "Error Count is now at $ERROR_COUNT \n"
                 sadm_write "Continuing with next system.\n"            # Advise we are skipping srv
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
            then sadm_write "rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else sadm_write "rsync -ar --delete  ${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
            then sadm_write "$SADM_ERROR ($RC)\n"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 sadm_write "Error Count is now at $ERROR_COUNT \n"
            else sadm_write "${SADM_OK}\n" 
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
            then sadm_write "rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else sadm_write "rsync -ar --delete ${REMDIR}/ $WDIR/ "
                 rsync -ar --delete ${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
            then sadm_write "$SADM_ERROR ($RC)\n"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
            else sadm_write "${SADM_OK}\n" 
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_write "Error Count is now at $ERROR_COUNT \n" ;fi

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

    # If current user is not 'root', exit to O/S with error code 1 
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # If we are not on the SADMIN Server, exit to O/S with error code 1 
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_write "Script can run only on SADMIN server (${SADM_SERVER}).\n"
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Del PID
             exit 1                                                     # Exit To O/S with error
    fi

    # Get Statistics and Configuration files from AIX, Mac and Linux Servers
    process_servers                                                     # Collect Files from Servers
    SADM_EXIT_CODE=$?                                                   # Return Code = Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    