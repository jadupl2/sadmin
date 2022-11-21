#! /usr/bin/env bash
#===================================================================================================
# Title      :  sadm_ui.sh System ADMinistration Tool User Interface Main Menu
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
# 2017_08_08 cmdline v1.0 Initial Version - May 2016 - Jacques Duplessis
# 2017_08_08 cmdline v1.5 Adapted to work with XFS Filesystem
# 2017_08_08 cmdline v2.0 Major rewrite
# 2017_09_01 cmdline V2.1 For Now Remove RPM Option from main Menu (May put it back later)
# 2017_09_27 cmdline V2.1a Don't send email when script terminate with error
# 2017_10_07 cmdline V2.2 Typo error and correct problem when creating filesystem (when changing type)
# 2018_01_03 cmdline V2.3 Correct Main Menu Display Problem 
# 2018_05_14 cmdline V2.4 Fix Problem with echo command on MacOS
# 2018_05_14 cmdline V2.5 Add 'SADM_USE_RCH' var. to use or not RCH File (Set 'N' for this Script)
# 2018_09_20 cmdline v2.6 Update code to align with latest Library
# 2019_02_25 cmdline v2.7 Nicer color presentation and code cleanup.
# 2019_11_11 cmdline v2.8 Add RPM Tools option in menu.
# 2019_11_21 cmdline v2.10 Minor correction to RPM Tools Menu
# 2019_11_22 cmdline v2.11 Restrict RPM & DEV Menu when available only.
#@2022_11_19 cmdline v2.12 Fix problem when dealing with tera bytes in Filesystem increase
#=================================================================================================== 
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x


# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.52
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE ENVIRONMENT VARIABLE 'SADMIN' IS DEFINED.
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
export SADM_VER='2.12'                                     # Script version number
export SADM_PDESC="SADM Tool Main Menu"                    # Script Optional Desc.(Not use if empty)
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]

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
# ---------------------------------------------------------------------------------------
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
    sadm_start                                                          # Won't come back if error
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong 
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
