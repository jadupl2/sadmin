#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.sh
#   Date        :   YYYY/MM/DD
#   Requires    :   sh, SADMIN Shell Library and 
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
# 2016_10_01    v1.0 Initial Version
# 2018_06_06    v1.1 Restructure and Add code examples
#@2019_05_22 Updated: v1.2 Comment code for documentation
#@2019_05_23 Updated: v1.3 Correct Typo Error
#@2019_11_18 Updated: v1.4 Put 'root' and SADM_SERVER test in comment.
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
    export SADM_VER='1.4'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="N"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="N"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
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



    # Load SADMIN Screen Shell Library 
    . ${SADMIN}/lib/sadmlib_screen.sh                   # Load SADMIN Screen Standard Library


#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose





# --------------------------------------------------------------------------------------------------
#                      S c r i p t    M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    
    return 0                                                            # Return Default return code
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

#    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
#        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
#             sadm_writelog "Process aborted"                            # Abort advise message
#             sadm_stop 1                                                # Close and Trim Log
#             exit 1                                                     # Exit To O/S with error
#    fi
#    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
#        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
#             sadm_writelog "Process aborted"                            # Abort advise message
#             sadm_stop 1                                                # Close and Trim Log
#             exit 1                                                     # Exit To O/S with Error
#    fi

    # Display Main Menu     
    while :
        do
        sadm_display_heading "Your Menu Heading Here" "$SADM_VER"       # Std SADMIN Menu Heading
        menu_array=("Your Menu Item 1" "Your Menu Item 2" "Your Menu Item 3" "Your Menu Item 4" )             
        sadm_display_menu "${menu_array[@]}"                            # Display menu Array
        sadm_choice=$?                                                  # Choice is returned in $?
        case $sadm_choice   in                                            
            1) sadm_mess "You press choice number $sadm_choice"
               ;;
            2) sadm_mess "You press choice number $sadm_choice"
               ;;
            3) sadm_mess "You press choice number $sadm_choice"
               ;;
            4) sadm_mess "You press choice number $sadm_choice"
               ;;
           99) # Option Quit -                                          # 99 = [Q],[q] was pressed
               break                                                    # Break out of the loop
               ;;
            *) # Invalid Option #                                       # If an invalid key press
               sadm_mess "Invalid option"                               # Message to user
               ;;
        esac
        done

    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Close SADM Tool & Upd RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
