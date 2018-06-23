#! /bin/bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_updater.sh
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
# 2018_06_20    V1.6 Fix and Improvement after testing on Raspbian
# 2018_06_20    V1.7 Check if new version of this script before update, if so update it & restart it
# 2018_06_20    V1.8 Add Command line Switch (-u) To do a Batch Update (No Question)
# 2018_06_21    V1.9 Added Debug Information - Fix Minor bug
# 2018_06_21    V2.0 Fix and Minor Minor bug - Re-tested on Raspbian
# 2018_06_21    V2.1 Minor Fix and Improvements 
# 2018_06_22    V2.2 New File were not copied and Rollback Dir. was not populated in some conditions
# 2018_06_23    V2.4 Lot of adjustements,enhancements and change name to sadm_updater.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -xs



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
    export SADM_VER='2.4'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="Y"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="N"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="N"                          # Show/Generate Footer in script log (.log)
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
export ROLLBACK_DIR="${SADMIN}/pkg/sadm_update/`date +%Y_%m_%d`"        # Updated File are kept Dir.
DASHES=`printf %80s |tr " " "="`            ; export DASHES             # 80 equals sign line
SAVEARG=""                                  ; export SAVEARG            # CmdLine ARG In Case restart

# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-a          (Automatic Update - No prompt)"
    printf "\n\t-f [file]   (New version tgz file name)"
    printf "\n\t-d          (Debug Level [0-9])"
    printf "\n\t-h          (Display this help message)"
    printf "\n\t-v          (Show Script Version Info)"
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
# Check if this script have been updated in new version, put in ${SADMIN}/bin & restart it
#===================================================================================================
check_if_new_version()
{
    oldmd5=`md5sum ${SADMIN}/bin/${SADM_PN} | awk '{ print $1 }'`
    newmd5=`md5sum ${WDIR}/bin/${SADM_PN}   | awk '{ print $1 }'`
    if [ "$oldmd5" != "$newmd5" ]
        then sadm_writelog " "
             sadm_writelog "There is a new version of this script ..."
             sadm_writelog "We will install the new version and restart this script"
             sadm_writelog "Copying ${WDIR}/bin/${SADM_PN} to ${SADMIN}/bin/${SADM_PN}"
             cp ${WDIR}/bin/${SADM_PN} ${SADMIN}/bin/${SADM_PN}
             sadm_writelog " "
             sadm_writelog "New version is now in place"
             sadm_writelog " "
             sadm_writelog "Please wait while the script is restarting ..." 
             sadm_stop 0                                                # Close Log & Remove PID
             exec ${SADMIN}/bin/${SADM_PN} $SAVEARG                     # Restart the Script
    fi
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
        then sadm_writelog "[ ERROR ] $RC Running : $CMD"
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
    sadm_writelog "SADMIN Updater - $SADM_PN - Version ${SADM_VER}"     # Show Script Name & Version

    # Create Rollback directory
    sadm_writelog " " 
    if [ ! -d "$ROLLBACK_DIR" ] ; then mkdir $ROLLBACK_DIR ; fi         # Where updated file reside
    sadm_writelog "Rollback Directory is $ROLLBACK_DIR"
    sadm_writelog " " 

    # Accept tgz FileName from keyboard or use filename given on cmdline (-f option)
    cd /                                                                # Be Sure Full Path is enter
    if [ "$UPDATE_FILE" != "" ]                                         # filename given on cmdline
        then newtgz="$UPDATE_FILE"                                      # Use filename given
        else echo -n "Enter location of the new SADMIN version tgz file : " 
             read newtgz                                                # Name of new version tgz
             if  [ ! -r $newtgz ]                                       # If file not readable
                then sadm_writelog "File not found or not readable $newtgz"  # Exit - Abort Script
                     return 1                                           # Return Error to caller
             fi 
    fi 

    # Try to read the new software version tgz file
    tar -tvzf $newtgz > /dev/null 2>&1                                  # Try to read the TGZ file
    if [ $? -ne 0 ]                                                     # If error while reading it
        then sadm_writelog "Error while reading file $newtgz"           # Show Error to user
             return 1                                                   # Return Error to caller
    fi
  
    # List file in tgz file
    echo -e "\n\n-----\nList of files in new software version tgz file\n-----" >>$SADM_LOG
    ls -l $newtgz >> $SADM_LOG                                          # Save tgz name in log
    
    # Create Temporary Directory in /tmp
    WCUR_DATE=$(date "+%C%y%m%d")                                       # Save Current Date
    WDIR="/tmp/sadmin_${WCUR_DATE}"                                     # Construct Working DirName 
    if [ -d $WDIR ] ; then rm -fr $WDIR > /dev/null 2>&1 ; fi           # If WDIR Exist Remove it
    sadm_writelog "Creating working directory ${WDIR}"                  # Inform User
    mkdir ${WDIR}                                                       # Create Working Directory

    cd ${WDIR}                                                          # Change to Working Dir.
    sadm_writelog "Change directory to ${WDIR}"                                  # Inform User
    #
    echo "Untar $newtgz into ${WDIR}" | tee -a $SADM_LOG                # Inform user
    tar -xvzf $newtgz >> $SADM_LOG 2>&1                                 # Untar TGZ File

    # Check if new version of this script, if so copy it to $SADMIN/bin and restart this script
    check_if_new_version                                                # new version of this script
    
    sadm_writelog " " 
    sadm_writelog "Your Current version is : `cat ${SADMIN}/cfg/.version`"
    sadm_writelog "You will be updated to  : `cat ${WDIR}/cfg/.version`"
    sadm_writelog " " 
    sadm_writelog "Update Information" 
    sadm_writelog " - Anything under ${SADMIN}/usr, ${SADMIN}/sys will not be touch."
    sadm_writelog " - Your configuration files in ${SADMIN}/cfg will not be modify."
    sadm_writelog " - Scripts or files you have created won't be modified or deleted."
    sadm_writelog " - For SADMIN scripts (sadm*.py, sadm*.sh, sadm*.php, ...) :"
    sadm_writelog "     - If you haven't change them, they may be updated, if needed."
    sadm_writelog "     - If you have change them, you will be asked what to do for each of them." 
    sadm_writelog " - Only files in ${SADMIN} will be changed, not elsewhere."
    sadm_writelog " - Before proceeding, you should have a backup of ${SADMIN}"
    sadm_writelog " " 
    if [ "$AUTO_UPDATE" == "OFF" ] 
        then ask_user "Proceed with the update"                         # Proceed with update ?
             if [ $? -eq 0 ] ; then sadm_stop 0 ; exit 0 ; fi           # If don't want to proceed    
    fi

    # Read the New Version md5sum file line by line
    while read -u3 wline
        do
        #echo "wline = $wline"
        newsum=` echo $wline | awk '{ print $1 }'`                      # New Rel. md5sum of File
        sumfile=`echo $wline | awk '{ print $2 }'`                      # New Rel. FileName 

        # Skip New version file (Will be copied at the end of this function
        if [ "$sumfile" = "./cfg/.versum" ] || [ "$sumfile" = "./cfg/.version" ]
            then continue
        fi

        # System Startup and Shutdown script are never update once installed - So skip them here.
        if [ "$sumfile" = "./sys/sadm_startup.sh" ] || [ "$sumfile" = "./sys/sadm_shutdown.sh" ]
            then continue
        fi

        # Calculate MD5SUM Checksum of current version of the file
        if [ ! -e ${SADMIN}/$sumfile ]                                  # If Original file not exist
            then cursum=""                                              # No MD5 Sum 
            else cursum=`md5sum ${SADMIN}/$sumfile |awk '{ print $1 }'` # Create md5sum of Cur. File
        fi
        
        # Get MD5SUM of Previous Update
        prevsum=`grep "$sumfile"  ${SADMIN}/cfg/.versum |awk '{ print $1 }'` # md5sum of Prev. Rel.

        # If current md5sum is the same in the new version (do nothing file hasn't changed)
        if [ "$cursum" == "$newsum" ] ; then continue ; fi              # If New & Cur md5 are equal
        
        sadm_writelog " "                                               # White Line
        sadm_writelog "$DASHES"                                         # 80 Dash line
        
        # Under Debug Mode Show MD5SUM used for Updating each file
        if [ $DEBUG_LEVEL -gt 0 ] 
            then sadm_writelog "File changed..........: .$sumfile."
                 sadm_writelog "md5sum - Last version.: .$prevsum."
                 sadm_writelog "       - Current......: .$cursum."
                 sadm_writelog "       - New version..: .$newsum."
                 sadm_writelog " " 
        fi

        # File didn't changed since last update
        if [ "$prevsum" == "$cursum" ] 
            then if [ "$prevsum" == "" ] && [ "$cursum" == "" ] 
                    then sadm_writelog "Copying New Script $sumfile ..."
                         newdir=`dirname $sumfile`
                         if [ ! -d "$newdir" ] ; then mkdir -p $newdir > /dev/null 2>&1 ; fi
                    else if [ -e "${SADMIN}/$sumfile" ] 
                            then sadm_writelog "Saving ${SADMIN}/$sumfile to Rollback Directory."
                                 cp ${SADMIN}/$sumfile ${ROLLBACK_DIR}  # Copy file to Rollback Dir.
                         fi
                         sadm_writelog "Updating file $sumfile"
                 fi 
                 sadm_writelog "cp $WDIR/$sumfile ${SADMIN}/$sumfile"
                 cp $WDIR/$sumfile ${SADMIN}/$sumfile 
                 if [ $? -ne 0 ] ; then sadm_writelog "Error copying $sumfile ..." ; fi
                 continue
        fi 

        # User Made changes to file so ask him if he want to update it or skip this update
        if [ "$prevsum" != "$cursum" ] 
           then sadm_writelog " "
                sadm_writelog "File : \"$sumfile\""
                sadm_writelog "One of these conditions happened since last update of this file."
                sadm_writelog "   1) Change were made to the file."
                sadm_writelog "   2) You didn't update the file at the last update."
                sadm_writelog "   3) The file was deleted from the system."
                sadm_writelog "   4) This is a new file (or have moved in dir. structure)."
                sadm_writelog ""
                sadm_writelog "   Current file will be copied to RollBack Directory before updating it."
                sadm_writelog ""
                if [ "$AUTO_UPDATE" == 'OFF' ] 
                    then while :
                            do
                            echo -n "Do you want to [S]kip or [U]pdate this file [U] ? "
                            read choice                                 # Read User answer
                            if [ ${#choice} -lt 1 ] ;then choice="U" ;fi # [ENTER] = Default Update 
                            case "$choice" in                           # Test Answer
                                S|s )   break                           # Skip update for this file
                                        ;; 
                                U|u )   break                           # Ok with the Update
                                        ;;
                                * )     ;;                              # Wrong Choice Ask again
                            esac
                            done                
                            if [ "$choice" == 'S' ] || [ "$choice" == 's' ] ;then continue ;fi
                    else choice="u"                                     # Batch mode = Update
                fi
                sadm_writelog " "                                       # Blank Line
                if [ -e "${SADMIN}/$sumfile" ]                          # If current file exist
                    then sadm_writelog "Save current version ${SADMIN}/$sumfile to the Rollback Directory."
                         cp ${SADMIN}/$sumfile ${ROLLBACK_DIR}          # Copy file to Rollback Dir.
                fi
                #
                sadm_writelog "Update file to new version"
                newdir=`dirname ${SADMIN}/$sumfile`
                if [ ! -d "$newdir" ] ; then mkdir -p $newdir > /dev/null 2>&1 ; fi
                sadm_writelog "cp ${WDIR}/$sumfile ${SADMIN}/$sumfile" 
                cp ${WDIR}/$sumfile ${SADMIN}/$sumfile                  # Update Cur. file with New
                if [ $? -ne 0 ] ; then sadm_writelog "Error copying $sumfile ..." ; fi
        fi
        done 3< ${WDIR}/cfg/.versum                              # Ex :/opt/sadmin_0.86_20180422.tgz

        # 
        # Ok Update the MD5 Data for this new version on the server
        sadm_writelog " " 
        sadm_writelog "--------------- "
        sadm_writelog "Updating MD5 Version files" 
        cp ./cfg/.versum  ${SADMIN}/cfg/.versum
        cp ./cfg/.version ${SADMIN}/cfg/.version
        #
        # Remove Working Directory
        cd /
        rm -fr ${WDIR} > /dev/null
        #
        # End of Update
        sadm_writelog " " 
        sadm_writelog "--------------- "
        sadm_writelog "`date`"
        sadm_writelog "Update completed !"
        sadm_writelog " " 
        
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
    SAVEARG="$*"                                                        # Save All CmdLine Arg
    printf "SAVEARG = $SAVEARG"
    AUTO_UPDATE="OFF"                                                   # Interactive Mode Default
    UPDATE_FILE=""                                                      # Name of TGZ version file
    while getopts "hvad:f:" opt ; do                                    # Loop to process Switch
        case $opt in
            d)  DEBUG_LEVEL=$OPTARG                                     # Get Debug Level Specified
                ;;                                                      # No stop after each page
            f)  UPDATE_FILE=$OPTARG                                     # Save New Ver. tgz FileName
                if [ ! -e "$UPDATE_FILE" ]                              # If tgz file not exist
                    then printf "\nFile $UPDATE_FILE doesn't exist"     # Advise User missing file
                         printf "Update cancelled"                      # Advise exiting script
                         exit 1                                         # Backup to O/S with Error
                fi
                ;;                                                      # No stop after each page
            a)  AUTO_UPDATE="ON"                                        # No Question asked - Update
                ;;
            h)  show_usage                                              # Show Help Usage
                exit 0                                                  # Back to shell
                ;;
            v)  show_version                                            # Show Script Version Info
                exit 0                                                  # Back to shell
                ;;
           \?)  printf "\nInvalid option: -$OPTARG"                     # Invalid Option Message
                show_usage                                              # Display Help Usage
                exit 1                                                  # Exit with Error
                ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}" ; fi
    
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close SADM Tool & Upd RCH
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    