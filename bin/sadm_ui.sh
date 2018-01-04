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
#=================================================================================================== 
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $sadmin/lib/sadmlib_test.sh for viewing functions and informations avail. to you .
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to SADMIN directory" ;exit 1 ;fi
wlib="${SADMIN}/lib/sadmlib_std.sh"                                     # SADMIN Library Location
if [ ! -f $wlib ] ;then echo "SADMIN Library ($wlib) Not Found" ;exit 1 ;fi
#
# These are Global variables used by SADMIN Libraries - Some influence the behavior of some function
# These variables need to be defined prior to loading the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='2.3'                             ; export SADM_VER            # Your Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# Load SADMIN Libraries
[ -f ${SADMIN}/lib/sadmlib_std.sh ]    && . ${SADMIN}/lib/sadmlib_std.sh
#
# These variables are defined in sadmin.cfg file - You can override them here on a per script basis
# --------------------------------------------------------------------------------------------------
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE  # Max Nb. Lines in LOG file
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE   # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR    # Email Address to send status
#
# An email can be sent at the end of the script depending on the ending status
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE    # 0=No 1=OnErr 2=Success 3=All
#
#===================================================================================================
#



#===================================================================================================
#            M A I N      S E C T I O N   -   P R O G R A M   S T A R T    H E R E 
#===================================================================================================
#
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
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
