#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.sh
#   Date        :   YYYY/MM/DD
#   Requires    :   sh and SADMIN Shell Library
#   Description :
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use 
#                   a 100 characters per line. Comments in script always begin at column 73. You 
#                   will have a better experience, if you set screen width to have at least 100 Chr.
# 
# --------------------------------------------------------------------------------------------------
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
# Version Change Log 
#
# 2017_07_07    V1.0 Initial Version
# 2018_02_08    v1.1 Fix compatibility problem with 'dash' shell (Debian, Ubuntu, Raspbian)
# 2018_05_14    v1.2 Check if root is running script before calling sadm tool library
# 2018_05_14    v1.3 Add SADM_USE_RCH Variable to use or not the [R]eturn [C]ode [H]istory file
# 2018_05_15    v1.4 Add SADM_LOG_FOOTER & SADM_LOG_HEADER var. to create or not log header/footer
# 2018_05_19    v1.5 Make SADMIN Setup a Function, Minor fix and performance issue.
#               v1.5a Remove SADM_HOSTNAME DEFINITION from script (Done in sadmlib)
# 2018_05_26    v1.6 Added SADM_EXIT_CODE for User to use
# 2018_05_27    v1.7 Replace setup_sadmin Function by putting code at the beginning of source.
# 2018_06_03    v1.8 Small Ameliorations and corrections
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
    export SADM_VER='1.8'                               # Current Script Version
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




#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose




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
#
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with error
    fi
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # Command Line Switch Options- 
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
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}" ; fi
    
    main_process                                                        # Main Process
    # OR                                                                # Use line below or above
    #process_servers                                                    # Process All Active Servers
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

    sadm_stop $SADM_EXIT_CODE                                           # Close SADM Tool & Upd RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    