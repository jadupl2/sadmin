#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_shutdown.sh
#   Date:       25 October 2015
#   Synopsis:   This script is run when the sadmin.service is shutdown when server goes down.
#               Called by /etc/systemd/system/sadmin.service (systemd) or /etc/init.d/sadmin (SysV)
# --------------------------------------------------------------------------------------------------
# Version 2.2 - Log Enhancement
# Version 2.3 - Restructure to use the SADM Library and Send email on execution.
# Version 2.4 - Add sleep of 5 sec. at the end, to allow completion of sending email before shutdown
# Version 2.5 - Added code to run shutdown command based on Hostname
# 2017_08_05    V2.6 Send email only on Execution Error
# 2018_01_31    V2.7 Added execution of /etc/profile.d/sadmin.sh to have SADMIN Env. Var. Defined
# 2018_09_19    V2.8 Added Alert Group Utilisation
# 2018_10_18    v2.9 Remove execution of /etc/profile.d/sadmin.sh (Don't need anymore)
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x 


#===================================================================================================
#               Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # Test if 'SADMIN' environment variable is defined
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    # Test if 'SADMIN' Shell Library is readable 
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.9'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="Y"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#
#---------------------------------------------------------------------------------------------------
#
    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But they can be overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                  # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#
#===================================================================================================



# --------------------------------------------------------------------------------------------------
#                                   This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose




# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    sadm_writelog "*** Running SADM System Shutdown Script on $(sadm_get_fqdn)  ***"
    sadm_writelog " "


    # Special Operation for some particular System
    sadm_writelog " "
    sadm_writelog "Shutdown procedure for $SADM_HOSTNAME"
    case "$SADM_HOSTNAME" in
        "myhost" )      sadm_writelog "Stop MyApp Web Server ..."
                        /myapp/bin/stop_httpd.sh >> $SADM_LOG 2>&1
                        ;;
                *)      sadm_writelog "  No particular procedure needed for $SADM_HOSTNAME"
                        ;;
    esac

    sadm_writelog " "
    return 0                                                            # Return Default return code
}



# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
