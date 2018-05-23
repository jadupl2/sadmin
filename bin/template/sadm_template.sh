#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Title       :   XXXXXXXX.sh
#   Version     :   1.0
#   Date        :   DD/MM/YYYY
#   Requires    :   sh and SADMIN Library
#   Description :
# 
#   This code was originally written by Jacques Duplessis <jacques.duplessis@sadmin.ca>.
#   Developer Web Site : http://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
#
# 2017_07_07 JDuplessis V1.0 - Initial Version
# 2018_02_08 JDuplessis
#   v1.1   Fix compatibility problem with 'dash' shell (Debian, Ubuntu, Raspbian)
# 2018_05_14 JDuplessis
#   v1.2 Check if root is running script before calling sadm tool library
# 2018_05_14 JDuplessis
#   v1.3 Add SADM_USE_RCH Variable to use or not the [R]eturn [C]ode [H]istory file
# 2018_05_15 JDuplessis
#   v1.4 Add SADM_LOG_FOOTER and SADM_LOG_HEADER global variable to produce or not log header/footer
# 2018_05_19 JDuplessis
#   v1.5 Make SADMIN Setup a Function, Minor fix and performance issue.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose




#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
setup_sadmin()
{
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
    export SADM_VER='1.4'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name (without domain name)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    # An email can be sent at the end of the script depending on the ending status 
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
}



#===================================================================================================
# Display help usage of this script
#===================================================================================================
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
    echo " "
}



#===================================================================================================
# Process all your active(s) server(s) in the Database (Used if want to process selected servers)
#===================================================================================================
process_servers()
{
    sadm_writelog "Processing All Active(s) Server(s)"                  # Enter Servers Processing

    # Put Rows you want in the select 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    
    # Build SQL to select active server(s) from Database & output result in CSV Format to work file.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1
    # If File was not created or has a zero lenght then No Actives Servers were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_writelog "No Active Server were found."               # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    
    xcount=0; ERROR_COUNT=0;                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Server Counter
        server_name=`    echo $wline|awk -F, '{ print $1 }'`            # Extract Server Name
        server_os=`      echo $wline|awk -F, '{ print $2 }'`            # O/S (linux/aix/darwin)
        server_domain=`  echo $wline|awk -F, '{ print $3 }'`            # Extract Domain of Server
        server_monitor=` echo $wline|awk -F, '{ print $4 }'`            # Monitor  1=True 0=False
        server_sporadic=`echo $wline|awk -F, '{ print $5 }'`            # Sporadic 1=True 0=False
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        sadm_writelog " "                                               # Blank Line
        sadm_writelog "`printf %10s |tr " " "-"`"                       # Ten Dashes Line    
        sadm_writelog "Processing ($xcount) $fqdn_server"               # Server Count & FQDN Name 
        if [ $DEBUG_LEVEL -gt 5 ]                                       # If Debug Activated
            then if [ "$server_monitor" = "1" ]                         # Monitor Flag is at True
                    then sadm_writelog "$fqdn_server Monitoring ON"     # Show Monitor Status ON
                    else sadm_writelog "$fqdn_server Monitoring OFF"    # Show Monitor Status OFF
                 fi
                 if [ "$server_sporadic" = "1" ]                        # Sporadic Flag is at True
                    then sadm_writelog "$fqdn_server Sporadic ON"       # Show Server is Sporadic
                    else sadm_writelog "$fqdn_server Sporadic OFF"      # Show Non Sporadic Server
                 fi
        fi

        # Check if server name can be resolve - If not, we won't be able to SSH to it.
        if ! host  $fqdn_server >/dev/null 2>&1                         # If hostname not resolvable
            then SMSG="[ ERROR ] Can't process '$fqdn_server', hostname can't be resolved"
                 sadm_writelog "$SMSG"                                  # Advise user & Feed log
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 if [ $ERROR_COUNT -ne 0 ]                              # If Error count not at zero
                    then sadm_writelog "Total error(s) : $ERROR_COUNT"  # Show Total Error Count
                 fi
                 continue                                               # Continue with next Server
        fi

        # Try a SSH to the Server
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_writelog "$SADM_SSH_CMD $fqdn_server date" ; fi 
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Server
            then $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1       # SSH to Server & Run 'date'
                 RC=$?                                                  # Save Return Code Number
            else RC=0                                                   # No SSH to SADMIN Server
        fi
        if [ $DEBUG_LEVEL -gt 0 ] ;then sadm_writelog "Return Code: $RC" ;fi # Show SSH Status

        # If SSH failed and it's a Sporadic Server, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
            then sadm_writelog "[ WARNING ] Can't SSH to sporadic system $fqdn_server"
                 sadm_writelog "Continuing with next system"            # Not Error if Sporadic Srv. 
                 continue                                               # Continue with next system
        fi

        # If SSH Failed & Monitoring is Off, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_monitor" = "0" ]                # SSH don't work/Monitor OFF
            then sadm_writelog "[ WARNING ] Can't SSH to $fqdn_server - Monitoring is OFF"
                 sadm_writelog "Continuing with next system"            # Not Error if don't Monitor
                 continue                                               # Continue with next system
        fi

        # If All SSH test failed, Issue Error Message and continue with next system
        if [ $RC -ne 0 ]                                                # If SSH to Server Failed
            then SMSG="[ ERROR ] Can't SSH to system '${fqdn_server}'"  # Problem with SSH
                 sadm_writelog "$SMSG"                                  # Show/Log Error Msg
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 continue                                               # Continue with next system
        fi
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If not on SADMIN Server
            then sadm_writelog "[ OK ] SSH to $fqdn_server work"        # Good SSH Work on Client
            else sadm_writelog "[ OK ] No SSH using 'root' on the SADMIN Server ($SADM_SERVER)"
        fi

        # PROCESSING CAN BE PUT HERE
        # ........
        # ........
        done < $SADM_TMP_FILE1
    return $ERROR_COUNT                                                 # Return Err Count to caller
}



#===================================================================================================
# Main Process (Used to run script on current server)
#===================================================================================================
main_process()
{
    sadm_writelog "Starting Main Process ... "                          # Inform User Starting Main
    
    # PROCESSING CAN BE PUT HERE
    # ........
    # ........
    
    return $SADM_EXIT_CODE                                              # Return No Error to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    # If you want this script to be run only by 'root'.
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo %s" "${0##*/}"                          # Suggest using sudo
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S with error
    fi
    setup_sadmin                                                        # Setup Var. & Load SADM Lib
    sadm_start                                                          # Init Env. Dir. & RCH/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init

    # Include this 'if' when you want this script to only be run on the SADMIN server.
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # If not on SADMIN Server
        then sadm_writelog "Script only run on SADMIN system (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort, Advise User message
             sadm_stop 1                                                # Close SADM and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Inspect Command Line Argument (Help Usage (-h) or Activate Debug Level (-d[1-9]) -------------------------------
    while getopts "hd:" opt ; do                                        # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # 
            h) help_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close SADM Tool
               exit 0                                                   # Back to shell
               ;;                                                       #
           \?) sadm_writelog "Invalid option: -$OPTARG"                 # Invalid Option Message
               help_usage                                               # Display Help Usage
               sadm_stop 1                                              # Close SADM Tool
               exit 1                                                   # Exit Script with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ]                                           # If Debug is Activated
        then sadm_writelog "Debug activated, Level ${DEBUG_LEVEL}"      # Display Debug Level
    fi

    # MAIN SCRIPT PROCESS HERE ---------------------------------------------------------------------
    main_process                                                        # Main Process
    # OR                                                                # Use line below or above
    #process_servers                                                    # Process All Active Servers

    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close SADM Tool & Upd RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    