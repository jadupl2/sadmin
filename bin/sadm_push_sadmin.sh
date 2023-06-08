#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_push_sadmin.sh
#   Synopsis :  Copy the SADMIN master version to all actives clients (No overwrite of config files). 
#   Version  :  1.0
#   Date     :  6 September 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_rsync_sadmin.sh 1.0 2015.09.06
# --------------------------------------------------------------------------------------------------
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
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
#
# Change Log
# 2017_02_04  V1.8 Don't rsync /sadmin/cfg entirely just template.smon file for now    
# 2017_06_03  V1.9 Added the /sadmin/sys to rsync processing
# 2017_09_23  V2.0 Rewritten for performance/flexibility and command line Switch for debug
# 2017_12_30  V2.1 Change name of sysmon.std to template.smon (System Monitor Template)
# 2018_01_20  V2.2 Minor Adjustments
# 2018_02_10  V2.3 Change SQL Statement to remove SADMIN server from rsync process
# 2018_05_31  V2.4 Added ".backup_list.txt" & ".backup_exclude.txt" to rsync list 
# 2018_06_04  V2.5 Change $SADMIN/jac/bin to $SADM_UBIN_DIR 
# 2018_07_15  V2.6 Use Client Install Directory Location from Database instead of assuming /sadmin.
# 2018_07_19  V2.7 Now include Sysmon Template, nmon & service restart (srestart,sh) script
# 2018_07_21  V2.8 Added swatch_nmon.sh 
# 2018_09_03  V2.9 Added .mailgroup.cfg, .slackgroup.cfg and .slackchannel.cfg to rsync process. 
# 2018_09_15  V2.10 Added Alert History files to sync process
# 2018_12_30  v2.11 Added sys/.sadm_startup.sh sys/.sadm_shutdown.sh to rsync process.
# 2019_08_23 Update: v2.12 Added copy of Rear Basic exclude file cfg/.rear_exclude.txt.
# 2019_08_24 Fix: v2.13 Under certain condition not all servers were process (SSH in a loop problem)
# 2020_01_19 Update: v2.14 Add Option -u to sync the $SADMIN/usr/bin of SADMIN server to all clients.
# 2020_01_20 Update: v2.15 Add Option -s to sync the $SADMIN/sys of SADMIN server to all clients.
# 2020_01_26 Update: v2.16 Add Option -c [hostname]  to sync of SADMIN server version to one client.
# 2020_03_04 Update: v2.17 Script was rename from sadm_rsync_sadmin.sh to sadm_push_sadmin.sh
# 2020_04_23 Update: v2.18 Replace sadm_writelog by sadm_write & enhance log output.
# 2020_05_23 Update: v2.19 Changing the way sadm_show_version uniformity , option '-c' changed to '-n'
# 2020_12_12 Update: v2.28 Add pushing of alert_group.cfg alert_slack.cfg to client
# 2021_04_24 Fix: v2.29 Correct typo in error message.
# 2021_05_22 server v2.30 Remove sync depreciated $SADMIN/usr/mon/swatch_nmon* script and files.
# 2021_10_20 server v2.31 Remove sync depreciated slac_channel.cfg file
# 2021_11_07 nolog  v2.32 Don't try to push files (and give error) if the client system is lock. 
# 2022_04_04 server v2.33 Minor code improvement.
# 2022_05_24 server v2.34 Update to check if the SADMIN client is lock prior to push.
# 2022_07_09 server v2.35 Now pushing email user password file ($SADMIN/cfg/.gmpw).
# 2022_08_17 server v2.36 Updated with new SADMIN section v1.52
# 2022_09_20 server v2.37 SSH to client is now using the port defined in each system.
#@2023_04_10 server v2.38 Don't push gmail text password file ($SADMIN/cfg/.gmpw) to client.
#@2023_04_12 server v2.39 Add '-c' option to push 'sadmin.client.cfg' to 'sadmin.cfg' to all clients.
#@2023_04_17 server v2.40 Push encrypted email password file ($SADMIN/cfg/.gmpw64) to all clients.
#@2023_04_29 server v2.41 Increase speed of files copy from clients to SADMIN server.
# 2023_05_26 server v2.42 If /etc/environment is not present on client, proceed with the next system.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.55
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]              # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]     # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.42'                                     # Script Version
export SADM_PDESC="Copy SADMIN version to all actives clients, without overwriting config files)."
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# ---------------------------------------------------------------------------------------






# --------------------------------------------------------------------------------------------------
# Script Environment variables
# --------------------------------------------------------------------------------------------------
export SYNC_USR="N"                                                     # -u Don't sync usr/bin
export SYNC_SYS="N"                                                     # -s Don't sync sys Dir
export SYNC_CLIENT=""                                                   # -n SADMIN client to sync
export SYNC_CFG=""                                                      # -c sadmin_client.cfg sync
export ERROR_COUNT=0                                                    # Script Error Count
export WARNING_COUNT=0                                                  # Script Warning count
export SADM_TEN_DASH=`printf %10s |tr " " "-"`                          # 10 dashes line



# --------------------------------------------------------------------------------------------------
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage : [-d 0-9] [-n hostname] [-u] [-v] [-s] [-h] "
    printf "\n\t-c   (scp \$SADMIN/cfg/sadmin_client.cfg to \$SADMIN/cfg/sadmin.cfg on all clients)" 
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\t-u   (Also sync \$SADMIN/usr/bin to all active clients)" 
    printf "\n\t-n   (Push SADMIN version only to system specified)" 
    printf "\n\t-s   (Also sync \$SADMIN/sys to all active clients)" 
    printf "\n\n" 
}





# --------------------------------------------------------------------------------------------------
#                      Process servers O/S selected by parameter received (aix/linux)
# --------------------------------------------------------------------------------------------------
process_servers()
{
    WOSTYPE=$1                                                          # Should be aix or linux

# MySQL Select All Actives Servers (Except SADMIN Server) & output result in $SADM_TMP_FILE.
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_sadmin_dir,srv_ssh_port"
    SQL="${SQL} from server"
    if [ "$SYNC_CLIENT" != "" ]
        then SQL="${SQL} where srv_active = True and srv_name = '$SYNC_CLIENT' "
        else SQL="${SQL} where srv_active = True and srv_name <> '$SADM_HOSTNAME' "
    fi 
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    if [ $SADM_DEBUG -gt 5 ] 
       then sadm_write "\n"
            sadm_write "SQL = ${SQL}\n"
    fi
    
# Setup Database Authentication
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/;/'" # Build CmdLine
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line

# Execute SQL to Select Active servers Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ $SADM_DEBUG -gt 5 ] 
        then sadm_write "\n"
             sadm_write "List of actives servers to process.\n" 
             cat $SADM_TMP_FILE1 | while read wline ; do sadm_write "${wline}\n"; done
             sadm_write "\n"
    fi      

    xcount=0; ERROR_COUNT=0;                                            # Reset Server/Error Counter

# If SQL result file has a zero length, return to caller, nothing to process
        if [ ! -s "$SADM_TMP_FILE1" ]                                   # File has a zero length?
        then sadm_write "[ ERROR ] No server to process ...\n"          # Nothing to process
             sadm_write "${SADM_TEN_DASH}\n"                            # Terminate dash line
             return 1                                                   # Return to caller RC=1
    fi

# Process each actives servers
    while read wline                                                    # Then Read Line by Line
        do
        xcount=`expr $xcount + 1`                                       # Server Counter
        server_name=`    echo $wline|awk -F\; '{ print $1 }'`           # Extract Server Name
        server_os=`      echo $wline|awk -F\; '{ print $2 }'`           # Extract O/S (linux/aix)
        server_domain=`  echo $wline|awk -F\; '{ print $3 }'`           # Extract Domain of Server
        server_monitor=` echo $wline|awk -F\; '{ print $4 }'`           # Monitor  t=True f=False
        server_sporadic=`echo $wline|awk -F\; '{ print $5 }'`           # Sporadic t=True f=False
        server_dir=`     echo $wline|awk -F\; '{ print $6 }'`           # Client SADMIN Install Dir.
        server_ssh_port=`echo $wline|awk -F\; '{ print $7 }'`           # Client SSH port to use
        server_fqdn=`echo ${server_name}.${server_domain}`              # Create FQN Server Name
        
        sadm_write "\n"                                                 # Blank Line
        sadm_write "${SADM_TEN_DASH}\n"
        sadm_write "Processing ($xcount) $server_fqdn \n"               # Show ServerName Processing
        
# if can't resolve server name (Get IP of server), signal Error and proceed with next server
        if ! host $server_fqdn >/dev/null 2>&1
           then SMSG="[ ERROR ] Can't process '$server_fqdn', hostname can't be resolved."
                sadm_write "${SMSG}\n"                                  # Advise user
                ERROR_COUNT=$(($ERROR_COUNT+1))                         # Consider Error -Incr Cntr
                sadm_write "Total Error(s) now at ${ERROR_COUNT}\n"     # Show Error count
                continue                                                # skip this server
        fi

# Check if System is Locked.
        sadm_check_system_lock "$server_name"                           # Check lock file status
        if [ $? -ne 0 ] 
            then sadm_writelog "[ WARNING ] System ${server_fqdn} is currently lock."
                 WARNING_COUNT=$(($WARNING_COUNT+1))                    # Increase Warning Counter
                 sadm_writelog "$SADM_WARNING at ${WARNING_COUNT} - [ ERROR ] at ${ERROR_COUNT}"
                 continue                                               # Go process next server
        fi

# If SSH to server failed & it's a sporadic server = warning & next server
        $SADM_SSH -qnp $server_ssh_port $server_fqdn date >/dev/null 2>&1 # SSH to Server for date
        RC=$?                                                           # Save Error Number
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" == "1" ]              # SSH don't work & Sporadic
           then sadm_writelog "[ WARNING ] Can't SSH to sporadic server ${server_fqdn}"
                WARNING_COUNT=$(($WARNING_COUNT+1))                     # Increase Warning Counter
                sadm_writelog "$SADM_WARNING at ${WARNING_COUNT} - [ ERROR ] at ${ERROR_COUNT}"
                continue                                                # Go process next server
        fi

# If first SSH failed, try again 3 times to prevent false Error
        if [ $RC -ne 0 ]   
          then RETRY=0                                                  # Set Retry counter to zero
               while [ $RETRY -lt 3 ]                                   # Retry rsync 3 times
                  do
                  let RETRY=RETRY+1                                     # Incr Retry counter
                  $SADM_SSH -qnp $server_ssh_port $server_fqdn date >/dev/null 2>&1 
                  RC=$?                                                 # Save Error Number
                  if [ $RC -ne 0 ]                                      # If Error doing ssh
                      then if [ $RETRY -lt 3 ]                          # If less than 3 retry
                              then MSG="[ RETRY $RETRY ] $SADM_SSH -qnp $server_ssh_port $server_fqdn date"
                                   sadm_writelog "${MSG}"               # Show Retry Count to User
                              else break                                # Break out after 3 attempts
                           fi
                      else sadm_writelog "[ OK ] $SADM_SSH -qnp $server_ssh_port $server_fqdn date " 
                           break                                        # Break out of loop RC=0
                  fi
                  done
        fi

# IF THE 3 SSH ATTEMPT FAILED, ISSUE ERROR MESSAGE AND CONTINUE WITH NEXT SERVER
        if [ $RC -ne 0 ]   
           then SMSG="[ ERROR ] Can't SSH to server '${server_fqdn}'"  
                sadm_writelog "${SMSG}"                                 # Display Error Msg
                ERROR_COUNT=$(($ERROR_COUNT+1))                         # Consider Error -Incr Cntr
                sadm_writelog "Total Error(s) now at ${ERROR_COUNT}"    # Show Error count
                continue                                                # Continue with next server
        fi
        sadm_writelog "[ OK ] SSH to $server_fqdn"                      # Good SSH Work

# Get the remote /etc/environment file to determine where SADMIN is install on remote system
        WDIR="${SADM_WWW_DAT_DIR}/${server_name}"                       # Local Dir. on SADM Server
        if [ ! -d $WDIR ] ; then mkdir $WDIR ; chmod 775 $WDIR ; fi     # Local Dir. if don't exist 
        if [ "${server_name}" != "$SADM_HOSTNAME" ]
            then scp -CqP ${server_ssh_port} ${server_name}:/etc/environment ${WDIR} >/dev/null 2>&1  
            else cp /etc/environment ${WDIR} >/dev/null 2>&1  
        fi
        if [ $? -eq 0 ]                                                 # If file was transferred
            then server_dir=`grep "SADMIN=" $WDIR/environment |awk -F= '{print $2}'` # Set Remote Dir.
                 if [ "$server_dir" != "" ]                             # No Remote Dir. Set
                    then sadm_writelog "[ OK ] SADMIN is install in ${server_dir}."
                    else sadm_write_err "[ ERROR ] Couldn't get /etc/environment."
                         ERROR_COUNT=$(($ERROR_COUNT+1))
                         sadm_write_err "Continue with next server."
                         continue
                 fi 
            else sadm_write_err "scp -CqP ${server_ssh_port} ${server_name}:/etc/environment ${WDIR}"
                 sadm_write_err "[ ERROR ] - Couldn't get /etc/environment on ${server_name}"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 #server_dir="/opt/sadmin" 
                 sadm_write_err "Continue with next server."
                 continue
        fi


# Rsync Array Of Important Directories To Sadm Client
        rem_std_dir_to_rsync=( bin pkg lib )                            # Directories array to sync
        for WDIR in "${rem_std_dir_to_rsync[@]}"                        # Loop through Array
          do
          if [ $SADM_DEBUG -gt 5 ]                                      # If Debug is Activated
              then sadm_writelog "rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/"
          fi
          rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/
          RC=$? 
          if [ $RC -ne 0 ]
             then if [ $RC -eq 23 ] 
                     then sadm_write_log "[ WARNING ] Error code 23 denotes a partial transfer ..." 
                          WARNING_COUNT=$(($WARNING_COUNT+1))           # Increase Warning Counter
                     else sadm_write_err "[ ERROR ] ($RC) doing rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/"
                          ERROR_COUNT=$(($ERROR_COUNT+1))               # Increase Error Counter
                  fi 
             else sadm_writelog "[ OK ] rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/" 
          fi
          done             


# Copy Site Common configuration files to client
        rem_cfg_files=(alert_group.cfg .gmpw64)
        for WFILE in "${rem_cfg_files[@]}"
          do
          CFG_SRC="${SADM_CFG_DIR}/${WFILE}"
          CFG_DST="${server_fqdn}:${server_dir}/cfg/${WFILE}"
          #CFG_CMD="rsync -a ${CFG_SRC} ${CFG_DST}"
          CFG_CMD="scp -CqP $server_ssh_port ${CFG_SRC} ${CFG_DST}"
          if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "$CFG_CMD" ; fi 
          scp -CqP $server_ssh_port ${CFG_SRC} ${CFG_DST} >> $SADM_LOG 2>&1
          #rsync -a ${CFG_SRC} ${CFG_DST} >> $SADM_LOG 2>&1
          RC=$? 
          if [ $RC -ne 0 ]
             then if [ $RC -eq 23 ] 
                     then sadm_writelog "[ WARNING ] Error code 23 denotes a partial transfer ..." 
                          WARNING_COUNT=$(($WARNING_COUNT+1))           # Increase Warning Counter
                     else sadm_writelog "[ ERROR ] ($RC) doing ${CFG_CMD}"
                          ERROR_COUNT=$(($ERROR_COUNT+1))
                  fi 
             else sadm_writelog "[ OK ] ${CFG_CMD}" 
          fi
          done

# If '-c' was specified on cmdline:
# copy $SADMIN/cfg/sadmin_client.cfg from SADMIN server to $SADMIN/cfg/sadmin.cfg on all clients.
        if [ "$SYNC_CFG" = "Y" ]
            then sadmin_common="${SADM_CFG_DIR}/sadmin_client.cfg"
                 sadmin_destination="${server_fqdn}:${server_dir}/cfg/sadmin.cfg"
                 CMD="scp -CqP $server_ssh_port ${sadmin_common} ${sadmin_destination}"
                 scp -CqP $server_ssh_port ${sadmin_common} ${sadmin_destination} >> $SADM_LOG 2>&1
                 RC=$? 
                 if [ $RC -ne 0 ]
                    then sadm_writelog "[ ERROR ] $CMD"
                         ERROR_COUNT=$(($ERROR_COUNT+1))
                    else sadm_writelog "[ OK ] $CMD" 
                 fi
        fi


# If User Choose To Rsync $Sadmin/Usr/Bin To All Actives Clients, Then Do It Here.
        if [ "$SYNC_USR" = "Y" ] 
            then rem_usr_dir_to_rsync=( usr/bin usr/lib usr/cfg )
                 for WDIR in "${rem_usr_dir_to_rsync[@]}"
                    do
                    if [ $SADM_DEBUG -gt 5 ]                           # If Debug is Activated
                        then sadm_write "rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/\n"
                    fi
                    rsync -ar --delete  ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/
                    RC=$? 
                    if [ $RC -ne 0 ]
                        then if [ $RC -eq 23 ] 
                                then sadm_writelog "[ WARNING ] Error 23 - Partial rsync ..." 
                                     WARNING_COUNT=$(($WARNING_COUNT+1)) # Increase Warning Counter
                                else sadm_writelog "[ ERROR ] ($RC) doing rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/"
                                     ERROR_COUNT=$(($ERROR_COUNT+1))    # Increase Error Counter
                             fi 
                        else sadm_writelog "[ OK ] rsync -ar --delete ${SADM_BASE_DIR}/${WDIR}/ ${server_fqdn}:${server_dir}/${WDIR}/" 
                    fi
                    done             
        fi

# Rsync All Dot Configuration (Templates) Files In $SADMIN/cfg To All Actives Clients
        CFG_EXCL="--exclude .dbpass "
        if [ $SADM_DEBUG -gt 5 ]                                        # If Debug is Activated
            then sadm_write "rsync -ar --delete $CFG_EXCL ${SADM_CFG_DIR}/.??* ${server_fqdn}:${server_dir}/cfg/\n"
        fi
        rsync -ar --delete $CFG_EXCL ${SADM_CFG_DIR}/.??* ${server_fqdn}:${server_dir}/cfg/
        RC=$? 
        if [ $RC -ne 0 ]
            then if [ $RC -eq 23 ] 
                    then sadm_writelog "[ WARNING ] Error 23 - Partial rsync ..." 
                         WARNING_COUNT=$(($WARNING_COUNT+1))            # Increase Warning Counter
                    else sadm_writelog "[ ERROR ] ($RC) doing rsync -ar --delete $CFG_EXCL ${SADM_CFG_DIR}/.??* ${server_fqdn}:${server_dir}/cfg/"
                         ERROR_COUNT=$(($ERROR_COUNT+1))                # Increase Error Counter
                 fi
           else sadm_writelog "[ OK ] rsync -ar --delete ${SADM_CFG_DIR}/.??* ${server_fqdn}:${server_dir}/cfg/" 
        fi

# If User Choose To Rsync $SADMIN/sys To All Actives Clients, Then Do It Here.
        if [ "$SYNC_SYS" = "Y" ] 
            then if [ $SADM_DEBUG -gt 5 ]                               # If Debug is Activated
                    then sadm_write "rsync -ar --delete ${SADM_SYS_DIR}/ ${server_fqdn}:${server_dir}/sys/\n"
                 fi
                 rsync -ar --delete ${SADM_SYS_DIR}/ ${server_fqdn}:${server_dir}/sys/
                 RC=$? 
                 if [ $RC -ne 0 ]
                    then if [ $RC -eq 23 ] 
                            then sadm_writelog "[ WARNING ] Error 23 - Partial rsync ..." 
                                 WARNING_COUNT=$(($WARNING_COUNT+1))    # Increase Warning Counter
                            else sadm_writelog "[ ERROR ] ($RC) doing rsync -ar --delete ${SADM_SYS_DIR}/ ${server_fqdn}:${server_dir}/sys/"
                                 ERROR_COUNT=$(($ERROR_COUNT+1))        # Increase Error Counter
                         fi
                    else sadm_writelog "[ OK ] rsync -ar --delete ${SADM_SYS_DIR}/ ${server_fqdn}:${server_dir}/sys/" 
                 fi

            else # RSYNC STARTUP/SHUTDOWN TEMPLATE SCRIPT FILES IN $SADMIN/SYS TO ALL ACTIVES CLIENTS
                 if [ $SADM_DEBUG -gt 5 ]                               # If Debug is Activated
                    then sadm_write "rsync -ar --delete ${SADM_SYS_DIR}/.??* ${server_fqdn}:${server_dir}/sys/\n"
                 fi
                 rsync -ar --delete ${SADM_SYS_DIR}/.??* ${server_fqdn}:${server_dir}/sys/
                 RC=$? 
                 if [ $RC -ne 0 ]
                    then if [ $RC -eq 23 ] 
                            then sadm_writelog "[ WARNING ] Error 23 - Partial rsync ..." 
                                 WARNING_COUNT=$(($WARNING_COUNT+1))    # Increase Warning Counter
                            else sadm_writelog "[ ERROR ] ($RC) doing rsync -ar --delete ${SADM_SYS_DIR}/.??* ${server_fqdn}:${server_dir}/sys/"
                                 ERROR_COUNT=$(($ERROR_COUNT+1))        # Increase Error Counter
                         fi
                    else sadm_writelog "[ OK ] rsync -ar --delete ${SADM_SYS_DIR}/.??* ${server_fqdn}:${server_dir}/sys/" 
                 fi
        fi

# Rsync Nmon Watcher, Sadmin_Monitor Template Script, Service Restart Script
        rem_files_to_rsync=(usr/mon/stemplate.sh usr/mon/srestart.sh ) 
        for WFILE in "${rem_files_to_rsync[@]}"                         # Loop to sync template file
          do
            CFG_SRC="${SADM_BASE_DIR}/${WFILE}"
            CFG_DST="${server_fqdn}:${server_dir}/${WFILE}"
            CFG_CMD="scp -CqP $server_ssh_port ${CFG_SRC} ${CFG_DST}"
            scp  -CqP $server_ssh_port ${CFG_SRC} ${CFG_DST} >> $SADM_LOG 2>&1
            RC=$?
            if [ $RC -ne 0 ]
                then sadm_writelog "[ ERROR ] ($RC) doing $CFG_CMD"
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "[ OK ] $CFG_CMD"  
            fi
          done             

        # Show Cumulative Warning and Error
        if [ "$ERROR_COUNT" -ne 0 ] || [ "$WARNING_COUNT" -ne 0 ]
           then sadm_writelog "$SADM_WARNING at ${WARNING_COUNT} - [ ERROR ] at ${ERROR_COUNT}"
        fi

        done < $SADM_TMP_FILE1

# Show Total Error Count After Processing Each Server
    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Total Error(s) count   : ${ERROR_COUNT}"
    sadm_writelog "Total Warning(s) count : ${WARNING_COUNT}"
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog " "
    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
#   -u rsync $SADMIN/usr/bin to clients
#   -s rsync $SADMIN/sys to clients
#   -n rsync Clients Hostname Name to update (Comma separated, no space between them: host1,host2)
# --------------------------------------------------------------------------------------------------
function cmd_options()
{

    # Switch for Help Usage (-h), Activate Debug Level (-d[1-9]), -v show version
    # -u rsync $SADMIN/usr/bin to clients, 
    # -s rsync $SADMIN/sys to clients, 
    # -c rsync $SADMIN/cfg/sadmin_client.cfg to $sadmin/cfg/sadmin.cfg 
    # -n rsync Clients Hostname Name to update (Comma separated, no space between them: host1,host2)
    while getopts "hvscun:d:" opt ; do                                  # Loop to process Switch
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
            n) SYNC_CLIENT=$OPTARG                                      # Gather host name to Update
               ;;                                                       # No stop after each page
            u) SYNC_USR="Y"                                             # Sync $SADMIN/usr/bin Dir.
               ;;
            c) SYNC_CFG="Y"                                             # Sync $SADMIN/cfg/sadmin.cfg
               ;;
            s) SYNC_SYS="Y"                                             # Sync $SADMIN/sys Dir.
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
    done                               
    return 
}




# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    process_servers                                                     # Process Active Servers
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
