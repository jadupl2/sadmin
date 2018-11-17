#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_support_request.sh
#   Synopsis    :   Run this script to create a log file used to submit problem.
#   Version     :   1.0
#   Date        :   30 March 2018 
#   Requires    :   sh 
#   Description :   Collect logs, and files modified during installation for debugging.
#                   If problem detectied during installation, run this script an send the
#                   resulting log (setup_result.log) to support at support@sadmin.ca
#
#   This code was originally written by Jacques Duplessis <duplessis.jacques@gmail.com>,
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_03_30 v1.0 Initial Version
# 2018_04_04 V1.1 Bug Fixes
# 2018_04_27 V1.2 Change Default Shell to Bash for running this script
# 2018_08_10 v1.3 Remove O/S Version Restriction and added /etc/environment printing.
#@2018_11_16 v1.4 Restructure for performance and flexibility.
#
# --------------------------------------------------------------------------------------------------
trap 'echo "Process Aborted ..." ; exit 1' 2                            # INTERCEPT The Control-C
#set -x


#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    if [ -z "$SADMIN" ]                                 # Test If SADMIN Environment Var. is present
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN Shell Library not readable ?
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # You can use variable below BUT DON'T CHANGE THEM - They are used by SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name with Domain Name

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.4'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#---------------------------------------------------------------------------------------------------
# Value for these variables are taken from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# But they can be overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                  # AlertGroup Used for Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # At end of script Trim log to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
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
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose


#===================================================================================================
#                              Print File received as parameter
#===================================================================================================
print_file()
{
    wfile=$1                                                            # Save FileName to Print
    echo " " >> $SADM_LOG                                               # Insert Blank Line in Log
    
    if [ -r $wfile ]                                                    # If File is Readable
       then echo "Adding $wfile to support request log ..."
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            echo "Content of $wfile"    >> $SADM_LOG
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            cat $wfile                  >> $SADM_LOG
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
            return 0                                                    # Return No Error to Caller
       else echo " "                    >> $SADM_LOG                    # Insert Blank Line
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            echo "File Not Found : $wfile" >> $SADM_LOG
            echo "$SADM_FIFTY_DASH"     >> $SADM_LOG
            echo " "                    >> $SADM_LOG                    # Insert Blank Line
    fi
    return 1
}

#===================================================================================================
#                                       Main Process 
#===================================================================================================
main_process()
{
    print_file "/etc/environment" 
    print_file "/etc/profile.d/sadmin.sh" 
    print_file "$SADM_CFG_FILE"
    print_file "/etc/sudoers.d/033_sadmin-nopasswd"
    print_file "/etc/cron.d/sadm_server"
    print_file "/etc/cron.d/sadm_client"
    print_file "/etc/cron.d/sadm_osupdate"
    print_file "/etc/selinux/config"
    print_file "/etc/hosts"
    print_file "/etc/httpd/conf.d/sadmin.conf"
    print_file "$SADM_SETUP_DIR/log/sadm_setup.log"
    return 0
}

#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
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

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

    # SADMIN Closing procedure - Close/Trim log and rch file, Remove PID File, Remove TMP files ...
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID

    # Compress File
    BACDIR=`pwd`
    cd $SADM_LOG_DIR
    if [ $DEBUG_LEVEL -gt 0 ] 
        then echo "tar -cvzf ${SADM_TMP_DIR}/${SADM_INST}.tgz ${SADM_LOG}"
    fi
    tar -cvzf ${SADM_TMP_DIR}/${SADM_INST}.tgz ${SADM_LOG} 2>1 >/dev/null
    echo "Please attach this file in the support email request : ${SADM_TMP_DIR}/${SADM_INST}.tgz"
    echo " "                                                            # Insert Blank Line
    cd $BACDIR

    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    