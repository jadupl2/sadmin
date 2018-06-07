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
# 2017_04_24    V1.0 Initial Version
# 2017_04_25    V1.3 First Beta Version
# 2017_05_15    V1.4 First Production version
# 2018_06_06    V1.5 Restructure Code and Adapt to new library
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
    export SADM_VER='1.5'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================






#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
EPOCH=`date +%s`                            ; export EPOCH              # Current EPOCH Time
ROLLBACK_DIR="${SADMIN}/pkg/sadm_update"    ; export ROLLBACK_DIR       # Updated File are kept in


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
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # Command Line Switch Options- 
    # (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
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
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}" ; fi
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close SADM Tool & Upd RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    