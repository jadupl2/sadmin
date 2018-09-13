#! /usr/bin/env sh
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   backup_sdcard.sh
#   Date        :   2018_07_16
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Backup Image of Raspberry Pi SD Card to a NFS Server
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use 
#                   a 100 characters per line. Comments in script always begin at column 73. You 
#                   will have a better experience, if you set screen width to have at least 100 Char
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
#
# 2018_07_16    V1.0 Initial Version
#@2018_07_28    v1.1 Now take same NFS Destination and Parameters as the Rear Backup
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x
     


#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.1'                               # Current Script Version
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
    export SADM_ALERT_TYPE=3                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                       ; export DEBUG_LEVEL                # 0=NoDebug Higher=+Verbose
HOSTNAME=`hostname -s`              ; export HOSTNAME                   # Current Host name
TOTAL_ERROR=0                       ; export TOTAL_ERROR                # Total Backup Error
CUR_DAY_NUM=`date +"%u"`            ; export CUR_DAY_NUM                # Current Day in Week 1=Mon
CUR_DATE_NUM=`date +"%d"`           ; export CUR_DATE_NUM               # Current Date Nb. in Month
CUR_MTH_NUM=`date +"%m"`            ; export CUR_MTH_NUM                # Current Month Number 
CUR_DATE=`date "+%C%y_%m_%d"`       ; export CUR_DATE                   # Date Format 2018_05_27 
LOCAL_MOUNT="/mnt/backup"           ; export LOCAL_MOUNT                # Local NFS Mount Point 
BACKUP_DIR="${LOCAL_MOUNT}/sdcards" ; export BACKUP_DIR                 # Where Backup Will Reside


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




# ==================================================================================================
#                Mount the NFS Directory where all the backup files will be stored
# ==================================================================================================
mount_nfs()
{
    # Make sur the Local Mount Point Exist ---------------------------------------------------------
    if [ ! -d ${LOCAL_MOUNT} ]                                          # Mount Point doesn't exist
        then mkdir ${LOCAL_MOUNT}                                       # Create if not exist
             sadm_writelog "Create local mount point $LOCAL_MOUNT"      # Advise user we create Dir.
             chmod 775 ${LOCAL_MOUNT}                                   # Change Protection
    fi
    
    # Mount the NFS Drive - Where the TGZ File will reside -----------------------------------------
    sadm_writelog "Mounting NFS Drive on $SADM_REAR_NFS_SERVER"       # Show NFS Server Name
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted
    sadm_writelog "mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${LOCAL_MOUNT}" 
    mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "[ERROR] Mount NFS Failed - Proces Aborted"  # Error - Advise User
             return 1                                                   # End Function with error
        else sadm_writelog "[SUCCESS] NFS Mount Succeeded"              # NFS Mount Succeeded Msg
    fi

    return 0 
}


# ==================================================================================================
#                                Unmount NFS Backup Directory
# ==================================================================================================
umount_nfs()
{
    sadm_writelog " "                                                   # Blank Line
    sadm_writelog "Unmounting NFS mount directory $LOCAL_MOUNT"         # Advise user we umount
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "[ERROR] Umounting NFS Dir. $LOCAL_MOUNT"    # Error - Advise User
             return 1                                                   # End Function with error
    fi
    return 0
}



# --------------------------------------------------------------------------------------------------
#               Keep only the number of backup copies specied in $SADM_DAILY_BACKUP_TO_KEEP
# --------------------------------------------------------------------------------------------------
clean_backup_dir()
{
    TOTAL_ERROR=0                                                       # Reset Total of error 
    sadm_writelog " "                                                   # Blank Line in Log
    sadm_writelog "${SADM_TEN_DASH}"                                    # Line of 10 Equal Char.
    sadm_writelog "Applying chosen policy to ${BACKUP_DIR} directory"   # Msg to user
    CUR_PWD=`pwd`                                                       # Save Current Working Dir.

    # Enter Server Backup Directory
    # May need to delete some backup if more than $SADM_REAR_BACKUP_TO_KEEP copies
    cd ${BACKUP_DIR}                                                    # Change Dir. To Backup Dir.

    # List Current backup days we have and Count Nb. how many we need to delete
    sadm_writelog "List of image(s) currently on disk:"
    ls -1 ${HOSTNAME}* |sort -r |while read ln ;do sadm_writelog "$ln" ;done
    backup_count=`ls -1 ${HOSTNAME}* |sort -r |wc -l`                   # Calc. Nb. Days of backup
    day2del=$(($backup_count-$SADM_REAR_BACKUP_TO_KEEP))                # Calc. Nb. Days to remove
    sadm_writelog "Keep last $SADM_REAR_BACKUP_TO_KEEP SD Card images." # Show How many to keep
    sadm_writelog "We now have $backup_count copies."                   # Show Nb. image on disk

    # If current number of backup days on disk is greater than nb. of backup to keep, then cleanup.
    if [ "$backup_count" -gt "$SADM_REAR_BACKUP_TO_KEEP" ] 
        then sadm_writelog "So we need to delete $day2del image(s)." 
             ls -1 ${HOSTNAME}* |sort -r |tail -$day2del > $SADM_TMP_FILE3
             #cat $SADM_TMP_FILE3 |while read ln ;do sadm_writelog "Deleting $ln" ;rm -fr ${ln}* ;done
             cat $SADM_TMP_FILE3 |while read ln ;do sadm_writelog "Deleting $ln" ;done
             sadm_writelog " "
             sadm_writelog "List of image(s) currently on disk:"
             ls -1 ${HOSTNAME}* |sort -r |while read ln ;do sadm_writelog "$ln" ;done
        else sadm_writelog "No clean up needed"
    fi 
    
    cd $CUR_PWD                                                         # Restore Previous Cur Dir.
    return 0                                                            # Return to caller
}


#===================================================================================================
# Script Main Processing Function
#===================================================================================================
main_process()
{
    sadm_writelog "Starting Main Process ... "                          # Inform User Starting Main
    mount_nfs                                                           # Mount NFS Drive
    
    mkdir -p $BACKUP_DIR >/dev/null 2>&1                                # Make Sure Dest. Dir Exist
    TIME_STAMP=`date "+%C%y_%m_%d"`                                     # Current Date 
    BACK_FILE="${BACKUP_DIR}/${HOSTNAME}_${TIME_STAMP}.img.gz"          # Final gz Image file name
    sadm_writelog " "                                                   # Space Line
    sadm_writelog "dd bs=4M if=/dev/mmcblk0 | gzip > $BACK_FILE"        # Show Using Command
    dd bs=4M if=/dev/mmcblk0 | gzip > $BACK_FILE                        # Execute DD Command
    RC=$?                                                               # Save Error Code
    if [ $RC -ne 0 ]                                                    # If Error while Backup
        then MESS="[ERROR] ${RC} while creating $BACK_FILE"             # Advise Backup Error
        else MESS="[SUCCESS] Creating Backup $BACK_FILE"                # Advise Backup Success
    fi
    sadm_writelog "$MESS"                                               # Advise User - Log Info
    # To restore, pipe the output of gunzip to dd:
    # gunzip --stdout raspbian.img.gz | sudo dd bs=4M of=/dev/sdb

    clean_backup_dir                                                    # Keep nb of images choosen
    umount_nfs                                                          # Unmount NFS Drive
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
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

# Your Main process procedure
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

# SADMIN CLosing procedure - Close/Trim log and rch file, Remove PID File, Send email if requested
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    