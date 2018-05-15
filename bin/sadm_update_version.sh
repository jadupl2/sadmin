#! /bin/bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_update_version.sh
#   Synopsis    :   Release Update Script
#   Version     :   1.0
#   Date        :   24 April 2018
#   Requires    :   sh and SADMIN Library
#   Description :
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
# 2017_04_24 JDuplessis 
#   V1.0 - Initial Version
# 2017_04_25 JDuplessis 
#   V1.3 - First Beta Version
# 2017_05_15 JDuplessis 
#   V1.4 - First Production version
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
SADM_VER='1.4'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_LOG_HEADER="N"                        ; export SADM_LOG_HEADER     # Show/Generate Log Header
SADM_LOG_FOOTER="N"                        ; export SADM_LOG_FOOTER     # Show/Generate Log Footer
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
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
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
EPOCH=`date +%s`                            ; export EPOCH              # Current EPOCH Time
ROLLBACK_DIR="${SADMIN}/pkg/sadm_update"    ; export ROLLBACK_DIR       # Updated File are kept in



#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
#===================================================================================================
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
    echo " "
}


#---------------------------------------------------------------------------------------------------
#  ASK USER THE QUESTION RECEIVED  -  RETURN 0 (FOR NO) OR  1 (FOR YES)
#---------------------------------------------------------------------------------------------------
ask_user()
{
    wmess="$1 [y,n] ? "                                                 # Save MEssage Received 
    wreturn=0                                                           # Function Default Value
    while :
        do
        echo -n "$wmess"                                                   # Write mess rcv + [ Y/N ] ?
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;; 
           n|N ) wreturn=0                                              # No = Return Value of 0
                 break                                                  # Break of the loop
                 ;;
             * ) ;;                                                     # Other stay in the loop
         esac
    done
   return $wreturn                                                      # Return 0=No 1=Yes
}


#===================================================================================================
# RUN O/S COMMAND RECEIVED AS PARAMETER - RETURN 0 IF SUCCEEDED - RETURN 1 IF ERROR ENCOUNTERED
#===================================================================================================
run_oscommand()
{
    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "Invalid number of parameter received by $FUNCNAME function"
             sadm_writelog "Please correct script please, script aborted" # Advise that will abort
             return 1                                                   # Prepare to exit gracefully
        else CMD="$1"                                                   # Save Command to execute
    fi

    if [ $DEBUG_LEVEL -gt 4 ] 
        then sadm_writelog "Command to execute is $CMD"
    fi
    $CMD >>$SADM_LOG 2>&1 
    RC=$?
    if [ $RC -ne 0 ]
        then sadm_writelog "[ ERROR ] ($RC) Running : $CMD"
             return 1
        else sadm_writelog "[ OK ] Command '$CMD' succeeded" 
    fi      
    return 0
}



#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    tput clear                                                          # Clear the screen
    echo -e "SADMIN Updater ($SADM_PN) - Version ${SADM_VER}\n\n"          # Show Script Name & Version

    # Accept tgz FileName of the new version
    cd /                                                                # Be Sure Full Path is enter
    echo -n "Enter location of the new SADMIN tgz file : " 
    read newtgz                                                         # Name of new version tgz
    if  [ ! -r $newtgz ]                                                # If file not readable
        then sadm_writelog "File not found or not readable ($newtgz)"   # Exit - Abort Script
             return 1                                                   # Return Error to caller
    fi  
    tar -tvzf $newtgz > /dev/null 2>&1                                  # Try to read the TGZ file
    if [ $? -ne 0 ]                                                     # If error while reading it
        then sadm_writelog "Error while reading file $newtgz"           # Show Error to user
             return 1                                                   # Return Error to caller
    fi
    ls -l $newtgz >> $SADM_LOG                                          # Save tgz name in log
    
    # Create Temporary Directory in /tmp
    WCUR_DATE=$(date "+%C%y%m%d")                                       # Save Current Date
    WDIR="/tmp/sadmin_${WCUR_DATE}"                                     # Construct Working DirName 
    if [ -d $WDIR ] ; then rm -fr $WDIR > /dev/null 2>&1 ; fi           # If WDIR Exist Remove it
    echo "Creating working directory ${WDIR}" |tee -a $SADM_LOG         # Inform User
    mkdir ${WDIR}                                                       # Create Working Directory

    cd ${WDIR}                                                          # Change to Working Dir.
    echo "Untar $newtgz in ${WDIR}" | tee -a $SADM_LOG                  # Inform user
    tar -xvzf $newtgz >> $SADM_LOG 2>&1                                 # Untar TGZ File

    echo " " 
    echo " " 
    echo "Your Current version is : `cat ${SADMIN}/cfg/.version`"
    echo "You will be updated to  : `cat ${WDIR}/cfg/.version`"
    echo " " 
    echo " " 
    echo "Update Procedure" 
    echo " - Scripts or any files you have created will not modified or deleted"
    echo " - SADMIN scripts (sadm*.py, sadm*.sh) :"
    echo "     - If you haven't change them, they will be updated, if needed."
    echo "     - If you have change them, you will be asked what to do for each of them." 
    echo " - Only files in ${SADMIN} will be changed", not elsewhere.
    echo " - Before proceeding, you should have a backup of SADMIN (${SADMIN})"
    echo " " 
    ask_user "Proceed with the update"                                  # Proceed with update ?
    if [ $? -eq 0 ] ; then return 1 ; fi                                # No, Then Return to caller
    
    # Read the New Version md5sum file line by line
    while read -u3 wline
        do
        #echo "wline = $wline"
        newsum=` echo $wline | awk '{ print $1 }'`                      # New Rel. md5sum of File
        sumfile=`echo $wline | awk '{ print $2 }'`                      # New Rel. FileName 
        cursum=`md5sum ${SADMIN}/$sumfile | awk '{ print $1 }'`         # Create md5sum of Cur. File
        prevsum=`grep '$sumfile'  ${SADMIN}/cfg/.versum`                # Get md5sum of Prev. Rel.

        # If current md5sum is the same in the new version (do nothing)
        if [ "$cursum" == "$newsum" ] ; then continue ; fi              # If New & Cur md5 are equal

        echo -e "\n--------------- "
        echo "File : $sumfile"
        echo "md5sum - Org: $prevsum - Cur.: $cursum - New: $newsum"

        # If user didn't change file since Previous Release 
        if [ "$prevsum" == "$cursum" ] 
            then echo "User didn't change $sumfile since previous release and we have an update - Updating"
                 echo "cp $WDIR/$sumfile ${SADMIN}/$sumfile"
                 continue
        fi 

        # User Made changes to file so ask him if he want to update it or not

        if [ "$prevsum" != "$cursum" ] 
           then echo -e "\n----------" 
                echo "Change were made by you to $sumfile since previous release"
                echo " - [S]kip the update of this file"
                echo " - [U]pdate file"
                echo "    - Current file will be copied to ${ROLLBACK_DIR} before updating it."
                echo "      in case you want to rollback"
                echo -n "Do you want to [S]kip or [U]pdate this file [S/U] ? "
                read choice
                if [ "$choice" == 'S' ] || [ "$choice" == 's' ] ;then continue ;fi # skip update
                echo "Copying $sumfile to ${ROLLBACK_DIR}"              # Inform User
                echo "cp ${SADMIN}/$sumfile ${ROLLBACK_DIR}"            # Copy file to Rollback Dir.
                echo "cp ${WDIR}/$sumfile ${SADMIN}/$sumfile"           # Update Cur. file with New
        fi
        done 3< ${WDIR}/cfg/.versum
    
# /wsadmin/repo/sadmin_0.86_20180422.tgz

}




#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9]) ---------------------------------
    while getopts "hd:" opt ; do                                        # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) help_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell
               ;;
           \?) sadm_writelog "Invalid option: -$OPTARG"                 # Invalid Option Message
               help_usage                                               # Display Help Usage
               sadm_stop 1                                              # Close the shop
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ]                                           # If Debug is Activated
        then sadm_writelog "Debug activated, Level ${DEBUG_LEVEL}"      # Display Debug Level
    fi

    main_process                                                        # Upd./psadmin with latest
    SADM_EXIT_CODE=$?                                                   # Save Return code Errors
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
