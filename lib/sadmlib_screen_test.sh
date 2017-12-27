#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadmlib_screen_test,sh
#   Synopsis : .
#   Version  :  1.0 
#   Date     :  14 August 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadmlib_screen_test.sh 1.0 2015/08/14
# --------------------------------------------------------------------------------------------------
# 2.2 Correction in end_process function (April 2014)
# 2.3 Cosmetic changes - Jan 2017
# 2.4 Allow to run multiple instance of the script - SADM_MULTIPLE_EXEC="Y"
# 2.5 Minor Change to adapt to new Library
# 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
SADM_VER='2.5'                             ; export SADM_VER            # Your Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="L"                          ; export SADM_LOG_TYPE       # Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# Load SADMIN Libraries
[ -f ${SADMIN}/lib/sadmlib_std.sh ]    && . ${SADMIN}/lib/sadmlib_std.sh
[ -f ${SADMIN}/lib/sadmlib_server.sh ] && . ${SADMIN}/lib/sadmlib_server.sh
[ -f ${SADMIN}/lib/sadmlib_screen.sh ] && . ${SADMIN}/lib/sadmlib_screen.sh
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



# --------------------------------------------------------------------------------------------------
#                                           Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log 
   
    # Example of a menu with less than 8 Items
    sadm_display_heading "Small Menu (7 Items or less)"
    menu_array=("Menu Item 1" "Menu Item 2" "Menu Item 3" "Menu Item 4" "Menu Item 5" \
                "Menu Item 6" "Menu Item 7" )
    sadm_display_menu "${menu_array[@]}"
    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy

    # Example with 1 to 15 Items on the menu
    sadm_display_heading "Medium Menu (Up to 15 Items)"
    menu_array=("Menu Item 1"  "Menu Item 2"  "Menu Item 3"  "Menu Item 4"  "Menu Item 5"   \
                "Menu Item 6"  "Menu Item 7"  "Menu Item 8"  "Menu Item 9"  "Menu Item 10"  \
                "Menu Item 11" "Menu Item 12" "Menu Item 13" "Menu Item 14" "Menu Item 15"  )
    sadm_display_menu "${menu_array[@]}"
    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy

    # Example With more than 15 Items (But Less than the maximum (30))
    sadm_display_heading "Large Menu (Up to 30 Items)"
    menu_array=("Menu Item 1"  "Menu Item 2"  "Menu Item 3"  "Menu Item 4"  "Menu Item 5"   \
                "Menu Item 6"  "Menu Item 7"  "Menu Item 8"  "Menu Item 9"  "Menu Item 10"  \
                "Menu Item 11" "Menu Item 12" "Menu Item 13" "Menu Item 14" "Menu Item 15"  \
                "Menu Item 16" "Menu Item 17" "Menu Item 18" "Menu Item 19" "Menu Item 20"  \
                "Menu Item 21" "Menu Item 22" "Menu Item 23" "Menu Item 24" "Menu Item 25"  \
                "Menu Item 26" "Menu Item 27" "Menu Item 28" "Menu Item 29" "Menu Item 30"  )
    sadm_display_menu "${menu_array[@]}"
    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy
 
    #tput clear
    e_header    "e_eheader"
    e_arrow     "e_arrow"
    e_success   "e_success"
    e_error     "e_error"
    e_warning   "e_warning"
    e_underline "e_underline"
    e_bold      "e_bold"
    e_note      "e_note"

    SDAM_EXIT_CODE=0                                                    # For Test purpose
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
