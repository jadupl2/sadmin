#! /usr/bin/env sh
#---------------------------------------------------------------------------------------------------
# Test Alerting System
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' SIGHUP SIGINT SIGTERM       # if signals - SIGHUP SIGINT SIGTERM received
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
    export SADM_VER='1.1'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file

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
# Test Alert SysAdmin by Email
#===================================================================================================
test_sysadmin_alert()
{
    FIELD_IN_RCH=9
    wsubject="Sysadmin Alert Test"
    wmess="$SADM_PN - `date`\nList of lines without $FIELD_IN_RCH fields.\n"
    FILE3="/tmp/coco.log"
    echo -e "Jacques\nHelene\nline3" > $FILE3 ; chmod 666 $FILE3
    alert_sysadmin 'M' 'E' "$SADM_HOSTNAME" "$wsubject" "$wmess" "$FILE3"   
}


#===================================================================================================
# Test Slack Alert
#===================================================================================================
test_slack_alert()
{


    # ----------------------------------------------------------------------
    # Example of Alert Group File ($SADMIN/cfg/alert_group.cfg) below
    # ----------------------------------------------------------------------
    # Slack Alert Group
    # sinfo,     s, sadm_info
    # sdev,      s, sadm_dev
    # sprod,     s, sadm_prod
    #
    # Email Alert Group
    # sysadmin,  m, batman@batcave.com
    # webteam,   m, batman@batcave.com,robin@batcave.com 
    # prod_team, m, batman@batcave.com,robin@batcave.com,alfred@batcave.com
    # ----------------------------------------------------------------------

    # ----------------------------------------------------------------------
    # Example of Slack WebHook File ($SADMIN/cfg/alert_slack.cfg) below
    # ----------------------------------------------------------------------
    #
    #default,      https://hooks.slack.com/services/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2HK
    #
    #sadm_prod,    https://hooks.slack.com/services/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kFY
    #sadm_info,    https://hooks.slack.com/services/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2HK
    #sadm_dev,     https://hooks.slack.com/services/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uKc
    # ----------------------------------------------------------------------
    #
    export NBMESS=1
    export NBCOUNT=0


    # Send an alert from a script - Slack Message to alert group 'sinfo'
    NBCOUNT=$(($NBCOUNT+1))                                             # Incr. Message counter
    wmess="Test ${NBCOUNT} of ${NBMESS} Slack Alert from script No attachment"
    wsub="SADM SCRIPT: $SADM_PN reported an error on $SADM_HOSTNAME"   
    sadm_send_alert "S" "$SADM_HOSTNAME" "sinfo" "$wsub" "$wmess" ""
    if [ $? -ne 0 ] ; then sadm_writelog "Error Sending Alert" ; else sadm_writelog "Alert sent" ;fi


}


#===================================================================================================
# Test Email Alert
#===================================================================================================
test_email_alert()
{

    # ----------------------------------------------------------------------
    # Example of Alert Group File ($SADMIN/cfg/alert_group.cfg) below
    # ----------------------------------------------------------------------
    # Slack Alert Group
    # sinfo,     s, sadm_info
    # sdev,      s, sadm_dev
    # sprod,     s, sadm_prod
    #
    # Email Alert Group
    # sysadmin,  m, batman@batcave.com
    # webteam,   m, batman@batcave.com,robin@batcave.com 
    # prod_team, m, batman@batcave.com,robin@batcave.com,alfred@batcave.com
    # ----------------------------------------------------------------------

    # ----------------------------------------------------------------------
    # Example of Slack WebHook File ($SADMIN/cfg/alert_slack.cfg) below
    # ----------------------------------------------------------------------
    #
    #default,      https://hooks.slack.com/services/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2HK
    #
    #sadm_prod,    https://hooks.slack.com/services/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kFY
    #sadm_info,    https://hooks.slack.com/services/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2HK
    #sadm_dev,     https://hooks.slack.com/services/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uKc
    # ----------------------------------------------------------------------
    #
    export NBMESS=6
    export NBCOUNT=0


    # Send an alert from a script - Email to alert group 'sysadmin' - No Attachment
    NBCOUNT=$(($NBCOUNT+1))                                  # Incr. Message counter
    alert_type="S"                                           # [S]cript [E]rror [W]arning [I]nfo
    alert_server="$SADM_HOSTNAME"                            # Server where alert Come 
    alert_group="sysadmin"                                   # SADM AlertGroup to Advise
    wmess="Test ${NBCOUNT} of ${NBMESS} - Email Alert from script - No Attachment"
    wsub="SADM SCRIPT: $SADM_PN reported an error on $SADM_HOSTNAME"   
    sadm_send_alert "S" "$SADM_HOSTNAME" "sysadmin"  "$wsub" "$wmess" ""
    if [ $? -ne 0 ] ; then sadm_writelog "Error Sending Alert" ; else sadm_writelog "Alert sent" ;fi


    # Send an alert from a script - Email to alert group 'sysadmin' - With Attachment
    NBCOUNT=$(($NBCOUNT+1))                                             # Incr. Message counter
    wmess="Test ${NBCOUNT} of ${NBMESS} - Email Alert from script - with Attachment"
    wsub="SADM SCRIPT: $SADM_PN reported an error on $SADM_HOSTNAME"   
    sadm_send_alert "S" "$SADM_HOSTNAME" "sysadmin" "$wsub" "$wmess" "$SADM_CFG_FILE"
    if [ $? -ne 0 ] ; then sadm_writelog "Error Sending Alert" ; else sadm_writelog "Alert sent" ;fi


    # Simulate an Email Error Alert that come from System Monitor - With Attachment
    NBCOUNT=$(($NBCOUNT+1))                                             # Incr. Message counter
    wmess="Test ${NBCOUNT} of ${NBMESS} - Error Email Alert from SysMon with Attachment"
    wsub="SADM SCRIPT: $SADM_PN reported an error on $SADM_HOSTNAME"   
    sadm_send_alert "E" "$SADM_HOSTNAME" "sysadmin" "$wsub" "$wmess" "$SADM_CFG_FILE"
    if [ $? -ne 0 ] ; then sadm_writelog "Error Sending Alert" ; else sadm_writelog "Alert sent" ;fi

    # Simulate an Email Error Alert that come from System Monitor - No Attachement
    NBCOUNT=$(($NBCOUNT+1))                                             # Incr. Message counter
    wmess="Test ${NBCOUNT} of ${NBMESS} - Error Email Alert from SysMon No Attachment"
    wsub="SADM SCRIPT: $SADM_PN reported an error on $SADM_HOSTNAME"   
    sadm_send_alert "E" "$SADM_HOSTNAME" "sysadmin" "$wsub" "$wmess" "$SADM_CFG_FILE"
    if [ $? -ne 0 ] ; then sadm_writelog "Error Sending Alert" ; else sadm_writelog "Alert sent" ;fi


    # Simulate an Email Warning Alert that come from System Monitor
    NBCOUNT=$(($NBCOUNT+1))                                             # Incr. Message counter
    wmess="Test ${NBCOUNT} of ${NBMESS} - Warning Email Alert from SysMon - No Attachment"
    wsub="SADM SCRIPT: $SADM_PN reported an error on $SADM_HOSTNAME"   
    sadm_send_alert "W" "$SADM_HOSTNAME" "sysadmin" "$wsub" "$wmess" ""
    if [ $? -ne 0 ] ; then sadm_writelog "Error Sending Alert" ; else sadm_writelog "Alert sent" ;fi


    # Simulate an Email Info Alert that come from System Monitor
    NBCOUNT=$(($NBCOUNT+1))                                             # Incr. Message counter
    wmess="Test ${NBCOUNT} of ${NBMESS} - Info Email Alert from SysMon - With Attachment"
    wsub="SADM SCRIPT: $SADM_PN reported an error on $SADM_HOSTNAME"   
    sadm_send_alert "I" "$SADM_HOSTNAME" "sysadmin" "$wsub" "$wmess" "$SADM_CFG_FILE"
    if [ $? -ne 0 ] ; then sadm_writelog "Error Sending Alert" ; else sadm_writelog "Alert sent" ;fi
 
}



#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    sadm_writelog "Starting Main Process ... "                          # Inform User Starting Main
    #sadm_send_alert "E" "holmes" "sprod" "Filesystem /usr at 85% >= 85%" 
    
    #test_sysadmin_alert
    test_email_alert
    test_slack_alert

    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$DEBUG_LEVEL" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
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

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    