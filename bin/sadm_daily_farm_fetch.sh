#! /bin/sh
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
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
#@2018_08_24    v3.2 If couldn't get /etc/environment from client, change Email format.
#
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='3.2'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
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
    sadm_writelog "Processing All Actives Server(s)"

    # Select Active Server From Database & output result in CSV Format to $SADM_TMP_FILE1 work file
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active"
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    CMDLINE1="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL & Use Read Only User  
    CMDLINE2="-h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' |tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ]                                           # If Debug Level > 5 
        then sadm_writelog "$CMDLINE1 $CMDLINE2"                        # Debug = Write SQL CMD Line
    fi

    # Execute SQL Query to Create CSV Work File - $SADM_TMP_FILE1
    $CMDLINE1 -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    # If File was not created or has a zero lenght then No Actives Servers were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_writelog "No Active Server were found." 
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
        sadm_writelog " "                                               # Blank Line
        sadm_writelog "${SADM_TEN_DASH}"                                # Ten Dashes Line    
        sadm_writelog "Processing ($xcount) $fqdn_server"               # Show Current System 
        
        if [ $DEBUG_LEVEL -gt 0 ]                                       # If Debug Activated
            then if [ "$server_monitor" = "1" ]                         # Monitor Flag is at True
                    then sadm_writelog "Monitoring is ON for $fqdn_server"
                    else sadm_writelog "Monitoring is OFF for $fqdn_server"
                 fi
                 if [ "$server_sporadic" = "1" ]                        # Sporadic Flag is at True
                    then sadm_writelog "Sporadic system is ON for $fqdn_server"
                    else sadm_writelog "Sporadic system is OFF for $fqdn_server"
                 fi
        fi

        # If Server Name can't be resolved - Signal Error to user and continue with next system.
        if ! host  $fqdn_server >/dev/null 2>&1
            then SMSG="[ ERROR ] Can't process '$fqdn_server', hostname can't be resolved"
                 sadm_writelog "$SMSG"                                  # Advise user
                 echo "$SMSG" >> $SADM_ELOG                             # Log Err. to Email Log
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 if [ $ERROR_COUNT -ne 0 ]                              # If Error count not at zero
                    then sadm_writelog "Total error(s) : $ERROR_COUNT"  # Show Total Error Count
                 fi
                 continue                                               # Continue with next Server
        fi

        # Try a Ping to the Server
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_writelog "ping -c 2 $fqdn_server " ; fi 
        ping -c 2 $fqdn_server >/dev/null 2>/dev/null
        RC=$?
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_writelog "Return Code is $RC" ;fi 

        # If ping failed and it's a Sporadic Server, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
            then sadm_writelog "[ WARNING ] Can't Ping the sporadic system $fqdn_server"
                 sadm_writelog "            Continuing with next system"
                 continue                                               # Go process next system
        fi

        if [ $RC -ne 0 ]
            then sadm_writelog "[ ERROR ] Will not be able to process that server."
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count at $ERROR_COUNT" ;fi
                 continue
        fi


        # CREATE LOCAL RECEIVING DIR
        # Making sure the $SADMIN/dat/$server_name exist on Local SADMIN server
        #-------------------------------------------------------------------------------------------
        sadm_writelog "Make sure local directory ${SADM_WWW_DAT_DIR}/${server_name} exist"
        if [ ! -d "${SADM_WWW_DAT_DIR}/${server_name}" ]
            then sadm_writelog "  - Creating ${SADM_WWW_DAT_DIR}/${server_name} directory"
                 mkdir -p "${SADM_WWW_DAT_DIR}/${server_name}"
                 chmod 2775 "${SADM_WWW_DAT_DIR}/${server_name}"
        fi

        # Get the remote /etc/environment file to determine where SADMIN is install on remote
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}"
        sadm_writelog "Getting /etc/environment from ${server_name}"
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then scp -P${SADM_SSH_PORT} ${server_name}:/etc/environment ${WDIR} >/dev/null 2>&1  
            else cp /etc/environment ${WDIR} >/dev/null 2>&1  
        fi
        if [ $? -eq 0 ]                                                 # If file was transfered
            then RDIR=`grep "^SADMIN=" $WDIR/environment |awk -F= '{print $2}'` # Set Remote Dir.
                 if [ "$RDIR" != "" ]                                   # No Remote Dir. Set
                    then sadm_writelog "SADMIN is install in $RDIR on ${server_name}."
                    else sadm_writelog "  - [ERROR] Couldn't get /etc/environment on ${server_name}"
                         ERROR_COUNT=$(($ERROR_COUNT+1))
                         sadm_writelog "  - Assuming /opt/sadmin" 
                         RDIR="/opt/sadmin" 
                 fi 
            else sadm_writelog "  - [ERROR] Couldn't get /etc/environment on ${server_name}"
                 sadm_writelog "  - Assuming /opt/sadmin" 
                 sadm_writelog "  - Check SSH Connection to ${server_name}" 
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 RDIR="/opt/sadmin" 
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count at $ERROR_COUNT" ;fi
    


        # DR (Disaster Recovery) Information Files
        # Transfer $SADMIN/dat/dr (Disaster Recovery) from Remote to $SADMIN/www/dat/$server/dr Dir.
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/dr"                    # Local Receiving Dir.
        sadm_writelog "Make sure local directory $WDIR exist"
        if [ ! -d "${WDIR}" ]
            then sadm_writelog "  - Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
        fi
        REMDIR="${RDIR}/dat/dr" 
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then sadm_writelog "rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/"
                 rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else sadm_writelog "rsync -ar --delete  ${REMDIR}/ $WDIR/"
                 rsync -ar --delete ${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_writelog "  - [ERROR] $RC for $server_name"
                ERROR_COUNT=$(($ERROR_COUNT+1))
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count at $ERROR_COUNT" ;fi
 

        # NMON FILES
        # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server_name/nmon  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/nmon"                     # Local Receiving Dir.
        sadm_writelog "Make sure local directory $WDIR exist"
        if [ ! -d "${WDIR}" ]
            then sadm_writelog "  - Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
        fi
        REMDIR="${RDIR}/dat/nmon" 
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then sadm_writelog "rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/"
                 rsync -ar --delete ${server_name}:${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else sadm_writelog "rsync -ar --delete ${REMDIR}/ $WDIR/"
                 rsync -ar --delete ${REMDIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_writelog "  - [ERROR] $RC for $server_name"
                ERROR_COUNT=$(($ERROR_COUNT+1))
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count is now at $ERROR_COUNT" ;fi

        done < $SADM_TMP_FILE1

    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"                                # Ten Dashes Line    
    sadm_writelog "FINAL number of Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi

# Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

# If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

# If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Del PID
             exit 1                                                     # Exit To O/S with error
    fi


# Get Statistics and Configuration files from AIX and Linux Servers
    process_servers                                                     # Collect Files from Servers
    SADM_EXIT_CODE=$?                                                   # Return Code = Exit Code

# SADMIN CLosing procedure - Close/Trim log and rch file, Remove PID File, Send email if requested
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    