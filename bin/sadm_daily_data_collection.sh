#! /bin/sh
####################################################################################################
# Title      :  sadm_daily_data_collection.sh
# Description:  Get hardware Info & Performance Datafrom all active servers
# Version    :  2.4
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) sys_daily_data_collection.sh 1.4 21-04/2010
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
# 2015 - Restructure and redesign for modularity - Jacques Duplessus
# 2017_12_17 J.Duplessis
#   V2.0    Restructure for combining Aix and Linux
# 2017_12_23 J.Duplessis
#   V2.1    Modifications for using MySQL and logic Enhancements
# 2018_01_08 J.Duplessis
#   V2.2    Update SADM Library insertion section & Minor correction
# 2018_02_02 J.Duplessis
#   V2.3    Added Operation Separator in log 
# 2018_02_08 J.Duplessis
#   V2.4    Fix compatibility problem with 'dash' shell
# 2018_02_11 J.Duplessis
#   V2.5    Rsync locally for SADMN Server
# 2018_05_01 J.Duplessis
#   V2.6    Don't return an error if no active server are found & remove unnecessary message
######################################################################################&&&&&&&#######
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x

#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='2.6'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#


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
        sadm_writelog " " ; 
        #sadm_writelog "---------- Making Sure Client Directory exist on Server"
        sadm_writelog "Make sure local directory ${SADM_WWW_DAT_DIR}/${server_name} Exist"
        if [ ! -d "${SADM_WWW_DAT_DIR}/${server_name}" ]
            then sadm_writelog "  - Creating ${SADM_WWW_DAT_DIR}/${server_name} directory"
                 mkdir -p "${SADM_WWW_DAT_DIR}/${server_name}"
                 chmod 2775 "${SADM_WWW_DAT_DIR}/${server_name}"
            else sadm_writelog "  - [OK] Directory already exist"
        fi

    
        # DR INFO FILES
        # Transfer $SADMIN/dat/dr (Disaster Recovery) from Remote to $SADMIN/www/dat/$server/dr Dir.
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/dr"                    # Local Receiving Dir.
        sadm_writelog " " ; 
        #sadm_writelog "---------- Disaster Recovery Directory"
        sadm_writelog "Make sure local directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_writelog "  - Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_writelog "  - [OK] Directory already exist"
        fi
        sadm_writelog " " ; 
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server_name}:${SADM_DR_DIR}/ $WDIR/"
                 rsync -var --delete -e 'ssh -qp32' ${server_name}:${SADM_DR_DIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${SADM_DR_DIR}/ $WDIR/"
                 rsync -var --delete -e 'ssh -qp32' ${SADM_DR_DIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_writelog "  - [ERROR] $RC for $server_name"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_writelog "  - [SUCCESS] Rsync ${server_name}:${SADM_DR_DIR}/ $WDIR/"
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count at $ERROR_COUNT" ;fi


        # NMON FILES
        # Transfer Remote $SADMIN/dat/nmon files to local $SADMIN/www/dat/$server_name/nmon  Dir
        #-------------------------------------------------------------------------------------------
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}/nmon"                     # Local Receiving Dir.
        sadm_writelog " " ; 
        #sadm_writelog "---------- nmon Data Directory"
        sadm_writelog "Make sure local directory $WDIR Exist"
        if [ ! -d "${WDIR}" ]
            then sadm_writelog "  - Creating ${WDIR} directory"
                 mkdir -p ${WDIR} ; chmod 2775 ${WDIR}
            else sadm_writelog "  - [OK] Directory already exist"
        fi
        sadm_writelog " " ; 
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${server_name}:${SADM_NMON_DIR}/ $WDIR/"
                 rsync -var --delete -e 'ssh -qp32' ${server_name}:${SADM_NMON_DIR}/ $WDIR/ >>$SADM_LOG 2>&1
            else sadm_writelog "rsync -var --delete -e 'ssh -qp32' ${SADM_NMON_DIR}/ $WDIR/"
                 rsync -var --delete -e 'ssh -qp32' ${SADM_NMON_DIR}/ $WDIR/ >>$SADM_LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
           then sadm_writelog "  - [ERROR] $RC for $server_name"
                ERROR_COUNT=$(($ERROR_COUNT+1))
           else sadm_writelog "  - [OK] Rsync Success"
        fi
        if [ "$ERROR_COUNT" -ne 0 ] ;then sadm_writelog "Error Count is now at $ERROR_COUNT" ;fi

        done < $SADM_TMP_FILE1

    sadm_writelog " "
    sadm_writelog "FINAL number of Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    
    # This Script should only be run on the SADMIN Server
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ] # Only run on SADM Server
        then sadm_writelog "Script can be run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # This Script Should only be run by the user 'root'
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # Get Statistics and Configuration files from AIX and Linux Servers
    process_servers                                                     # Collect Files from Servers
    SADM_EXIT_CODE=$?                                                   # Return Code = Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Error code (0/1)
