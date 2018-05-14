#! /bin/bash
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
# 2017_09_01 JDuplessis 
#   V2.1  - For Now Remove RPM Option from main Menu (May put it back later)
# 2017_09_27 JDuplessis 
#   V2.1a - Don't send email when script terminate with error
# 2017_10_07 JDuplessis 
#   V2.2  - Correct typo error and correct problem when creating filesystem (when changing type)
# 2018_01_03 JDuplessis 
#   V2.3  - Correct Main Menu Display Problem 
# 2018_05_14 JDuplessis 
#   V2.4  - Fix Problem with echo command on MacOS
# 2018_05_14 JDuplessis 
#   V2.5  - Add SADM_USE_RCH Variable to use or not a RCH FIle (Set to 'N' for this Script)
#=================================================================================================== 
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
SADM_VER='2.5'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="L"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="Y"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="Y"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_USE_RCH="N"                           ; export SADM_USE_RCH        # Upd Record History File
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
[ -f ${SADMIN}/lib/sadmlib_screen.sh ]  && . ${SADMIN}/lib/sadmlib_screen.sh  # Load SADM Screen Lib
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



#===================================================================================================
#            M A I N      S E C T I O N   -   P R O G R A M   S T A R T    H E R E 
#===================================================================================================
#
    # User root you must be 
    if ! [ $(id -u) -eq 0 ]                                             # Only ROOT can run Script
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo \$SADMIN/bin/%s" "$SADM_PN"             # Suggest using 'sudo'
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S
    fi

    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    stty_orig=`stty -g`                                                 # Save stty setting    
    #stty erase "^H"                                                    # Make sure backspace work
    CURDIR=`pwd` ; export CURDIR                                        # Save Current Directory
    
    
    # Display Menu and Process request
    while :
        do
        sadm_display_heading "Main Menu"
        #menu_array="Filesystem_Tools RPM_DataBase_Tools"
        menu_array="Filesystem_Tools "
        sadm_display_menu "$menu_array"
        CHOICE=$?
        case $CHOICE in
            1)  . $SADM_BIN_DIR/sadm_ui_fsmenu.sh
                ;;
            #2)  . $SADM_BIN_DIR/sadm_ui_rpm.sh
            #    ;;
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
