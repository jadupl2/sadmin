#! /usr/bin/env bash
#===================================================================================================
# Title      :  sadm_ui.sh Systam ADMinistration Tool User Interface Main Menu
# Version    :  1.5
# Author     :  Jacques Duplessis
# Date       :  2016-06-06
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam_ui.sh 1.6 6-Jun-2016
#
#===================================================================================================
#
# Description
#   This is the SADM Main Program
#       - Display Menu and Load function script
#       - It load in memory all functions used by sadm.
#
#===================================================================================================
#
# History    :
#   1.0      Initial Version - May 2016 - Jacques Duplessis
#   1.5      Adapted to work with XFS Filesystem
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
#   1.0      Initial Version - May 2016 - Jacques Duplessis
#   1.5      Adapted to work with XFS Filesystem
#   2.0      Major rewrite
# 2017_09_01 V2.1 For Now Remove RPM Option from main Menu (May put it back later)
# 2017_09_27 V2.1a Don't send email when script terminate with error
# 2017_10_07 V2.2 Correct typo error and correct problem when creating filesystem (when changing type)
# 2018_01_03 V2.3 Correct Main Menu Display Problem 
# 2018_05_14 V2.4 Fix Problem with echo command on MacOS
# 2018_05_14 V2.5 Add SADM_USE_RCH Variable to use or not a RCH FIle (Set to 'N' for this Script)
# 2018_09_20 v2.6 Update code to align with latest Library
# 2019_02_25 Change: v2.7 Nicer color presentation and code cleanup.
# 2019_11_11 Change: v2.8 Add RPM Tools option in menu.
# 2019_11_21 Change: v2.10 Minor correction to RPM Tools Menu
# 2019_11_22 Change: v2.11 Restrict RPM & DEV Menu when available only.
#=================================================================================================== 
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
    export SADM_VER='02.11'                             # Current Script Version
    export SADM_LOG_TYPE="L"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="Y"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="N"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="N"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
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
#
[ -f ${SADMIN}/lib/sadmlib_screen.sh ]  && . ${SADMIN}/lib/sadmlib_screen.sh  # Load SADM Screen Lib




#===================================================================================================
# Script Variables 
#===================================================================================================
#
export WDATA=""                                                         # Contain user data input




#===================================================================================================
#            M A I N      S E C T I O N   -   P R O G R A M   S T A R T    H E R E 
#===================================================================================================
#
    # Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then echo "Script can only be run by the 'root' user"           # Advise User Message
             echo "Process aborted"                                     # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    stty_orig=`stty -g`                                                 # Save stty setting    
    #stty erase "^H"                                                    # Make sure backspace work
    CURDIR=`pwd` ; export CURDIR                                        # Save Current Directory
    
    
    # Display Menu and Process request
    while :
        do
        sadm_display_heading "SADMIN Main Menu" "$SADM_VER"
        menu_array=("Filesystem Tools......" "RPM Packages Tools...." "DEB Packages Tools....")
        sadm_display_menu "${menu_array[@]}"                            # Display menu Array
        CHOICE=$?
        case $CHOICE in
            1)  . $SADM_BIN_DIR/sadm_ui_fsmenu.sh
                ;;
            2)  if [ $(sadm_get_packagetype) = "rpm" ] 
                   then . $SADM_BIN_DIR/sadm_ui_rpm.sh
                   else sadm_mess "Accessible only on system using Red Hat Package Manager ('.rpm')."
                fi 
                ;;
            3)  if [ $(sadm_get_packagetype) = "deb" ] 
                   then . $SADM_BIN_DIR/sadm_ui_deb.sh
                   else sadm_mess "Accessible only on system using Debian packages ('.deb')."
                fi 
                ;;
            99) stty $stty_orig
                cd $CURDIR
                SADM_EXIT_CODE=0
                break
                ;;
            *)  # OPTION INVALIDE #
                sadm_mess "Invalid option - $CHOICE"
                ;;
        esac
        done

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
