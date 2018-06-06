#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_osupdate_server.sh
#   Synopsis :  Apply O/S update to all active or selected selected servers
#   Version  :  1.0
#   Date     :  9 March 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_osupdate_server.sh 1.0 2015/03/10
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
#   2016_11_11  v2.6 Insert Logic to Pass a param. (Y/N) to sadm_osupdate_client.sh to Reboot or not
#                    server after successfull update. Reboot is specified in Database (Web Interface)
#                    on a server by server basis.
#   2016_11_15  v2.7 Log will now be cumulative (Not clear every time the script in run)
#   2017_02_03  v2.8 Database Columns were changed
#   2017_03_15  v2.9 Add Logic for command line switch [-s servername] to update only one server
#                    Command line swtich [-h]  for help also added
#   2017_03_17  v3.0 Not a cumulative log anymore
#   2017_04_05  v3.1 Allow program to run more than once at same time, to allow simultanious Update
#                    Put Back cumulative Log, so don't miss anything, when multiple update running
#   2017_12_10  v3.2 Adapt program to use MySQL instead of PostGres 
#   2017_12_12  V3.3 Correct Problem connecting to Database
#   2018_02_08  V3.4 Fix Compatibility problem with 'sadh' shell (If statement)
#   2018_06_05  v3.5 Add Switch -v to view version, change help message, adapt to new Libr.
#
# --------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x




#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "${SADMIN}" ]                               # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory.." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi
    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='3.5'                               # Current Script Version
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
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
ERROR_COUNT=0                               ; export ERROR_COUNT        # Nb. of update failed
WARNING_COUNT=0                             ; export WARNING_COUNT      # Nb. of warning failed
STAR_LINE=`printf %80s |tr " " "*"`         ; export STAR_LINE          # 80 equals sign line
ONE_SERVER=""                               ; export ONE_SERVER         # Name If One server to Upd.

# Script That is run on every client to update the Operating System
USCRIPT="${SADM_BIN_DIR}/sadm_osupdate_client.sh" ; export USCRIPT      # Script to execute on nodes


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
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
#               Update Last O/S Update Date and Result in Server Table in sadm Database
# --------------------------------------------------------------------------------------------------
update_server_db()
{
    WSERVER=$1                                                          # Save Server name Recv.
    WSTATUS=$2                                                          # Save Server Update Status
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
    sadm_writelog "PROCESS LINUX SERVERS"
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_update_auto, "
    SQL2="srv_update_reboot, srv_sporadic, srv_active from server "
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
            fqdn_server=`echo ${server_name}.${server_domain}`          # Create FQN Server Name
            sadm_writelog " "
            sadm_writelog "${STAR_LINE}"
            info_line="Processing ($xcount) ${server_name}.${server_domain} - "
            info_line="${info_line}os:${server_os}"
            sadm_writelog "$info_line"
            
            # Ping Server to check if it is network reachable --------------------------------------
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


            # If Server is network reachable, but the O/S Update field is OFF in DB Skip Update
            if [ "$server_update_auto" = "0" ] && [ "$ONE_SERVER" = "" ] 
                then sadm_writelog "*** O/S UPDATE IS OFF FOR THIS SERVER"
                     sadm_writelog "*** NO O/S UPDATE WILL BE PERFORM - CONTINUE WITH NEXT SERVER"
                     if [ "$SADM_MAIL_TYPE" = "3" ]
                         then wsubject="SADM: WARNING O/S Update - Server $server_name (O/S Update OFF)" 
                              echo "Server O/S Update is OFF"  | mail -s "$wsubject" $SADM_MAIL_ADDR
                     fi
                else WREBOOT=" N"                                       # Default is no reboot
                     if [ "$server_update_reboot" = "1" ]            # If Requested in Database
                        then WREBOOT="Y"                                # Set Reboot flag to ON
                     fi                                                 # This reboot after Update
                     sadm_writelog "Starting $USCRIPT on ${server_name}.${server_domain}"
                     sadm_writelog "$SADM_SSH_CMD ${server_name}.${server_domain} $USCRIPT $WREBOOT"
                     $SADM_SSH_CMD ${server_name}.${server_domain} $USCRIPT $WREBOOT
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
    sadm_writelog " "
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

    ONE_SERVER=""                                                       # Set Switch Default Value
    while getopts "hvd:s:" opt ; do                                     # Loop to process Switch
        case $opt in
            s) ONE_SERVER="$OPTARG"                                     # Display Only Server Name
               ;;
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page               
            v) show_version                                             # Show Script Version Info
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

    sadm_start                                                          # Start Using SADM Tools
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init

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
