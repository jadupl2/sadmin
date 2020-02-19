#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_rear_backup.sh
#   Synopsis :  Produce a ReaR bootable iso and a restorable backup on an NFS server
#   Version  :  1.6
#   Date     :  14 December 2016
#   Requires :  sh
#
#   The Values for the NFS server, NFS mount point and number of backup to keep are taken from
#   SADMIN configuration file ($SADMIN/cfg/sadmin.cfg ). 
#   You need to change them to reflect your environment.
#
#       $SADM_REAR_NFS_SERVER               # ReaR NFS Server where backup will be stored
#       $SADM_REAR_NFS_MOUNT_POINT          # ReaR Mount Point exported on the NFS Server
#       $SADM_REAR_BACKUP_TO_KEEP           # ReaR Backup, Number of copies to keep
#
#   Every time this script is run the line below is updated in /etc/rear/site.conf to reflect 
#   the value taken from $SADMIN/cfg/sadmin.cfg
#   
#       BACKUP_URL="nfs://${SADM_REAR_NFS_SERVER}/${SADM_REAR_NFS_MOUNT_POINT}/"
#
#   The ReaR crontab file is remove, every time you run this script.
#   This is to decide when we run rear from this script.
#   If you don't want to remove it, put this line in comment at the end of this script.
#       if [ -r /etc/cron.d/rear ] ; then rm -f /etc/cron.d/rear >/dev/null 2>&1; fi
#
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
# --------------------------------------------------------------------------------------------------
# Change Log
#
# 2016_12_14 v1.7 Add Check to see if Rear Configuration file isn't present, abort Job (Exit 1)
# 2017_03_09 v1.8 Move test if rear is installed first, if not abort process up front.
#                 Error Message more verbose and More Customization
# 2017_04_20 v2.0 Return Code returned by Rear handle correctly, Script Messages more informative
# 2017_06_06 v2.1 NFS Server Name, Mount Point and Nb of copy to keep are taken from sadmin.cfg
# 2018_09_14 v2.2 ExitCode was reporting error on some occasion, even when backup was ok.
# 2018_09_19 v2.3 Include Usage of Alert Group 
# 2018_11_02_v2.4 Produce new log every time
# 2019_08_19 Update: v2.5 Updated to align with new SADMIN definition section.
# 2019_08_29 Fix: v2.6 Code restructure and was not reporting error properly.
# 2019_08_30 Fix: v2.7 Fix renaming backup problem at the end of the backup.
# 2019_09_01 Update: v2.8 Remove separate creation of ISO (Already part of backup)
# 2019_09_02 Update: v2.9 Change syntax of error messages.
# 2019_09_14 Update: v2.10 Backup list before housekeeping was not showing.
# 2019_09_18 Update: v2.11 Show Backup size in human redeable form.
#@2020_01_08 Update: v2.12 Minor logging changes.
#@2020_02_18 Update: v2.13 Correct typo error introduce in v2.12
#
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x




#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # Is 'SADMIN' environment variable defined ?. If not try to use /etc/environment SADMIN value.
    if [ -z $SADMIN ] || [ "$SADMIN" = "" ]                             # If SADMIN EnvVar not right
        then missetc="Missing /etc/environment file, create it and add 'SADMIN=/InstallDir' line." 
             if [ ! -e /etc/environment ] ; then printf "${missetc}\n" ; exit 1 ; fi
             missenv="Please set 'SADMIN' environment variable to the install directory."
             grep "^SADMIN" /etc/environment >/dev/null 2>&1            # SADMIN line in /etc/env.? 
             if [ $? -eq 0 ]                                            # Yes use SADMIN definition
                 then export SADMIN=`grep "^SADMIN" /etc/environment | awk -F\= '{ print $2 }'` 
                      misstmp="Temporarily setting 'SADMIN' environment variable to '${SADMIN}'."
                      missvar="Add 'SADMIN=${SADMIN}' in /etc/environment to suppress this message."
                      if [ ! -e /bin/launchctl ] ; then printf "${missvar}" ; fi 
                      printf "\n${missenv}\n${misstmp}\n\n"
                 else missvar="Add 'SADMIN=/InstallDir' in /etc/environment to remove this message."
                      printf "\n${missenv}\n$missvar\n"                 # Recommendation to user    
                      exit 1                                            # Back to shell with Error
             fi
    fi 
        
    # Check if the SADMIN Shell Library is accessible, if not advise user and exit with error.
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                            # Shell Library not readable
        then missenv="Please set 'SADMIN' environment variable to the install directory."
             printf "${missenv}\nSADMIN library ($SADMIN/lib/sadmlib_std.sh) can't be located\n"     
             exit 1                                                     # Exit to Shell with Error
    fi

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='2.13'                              # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Ok now, load Standard Shell Library
    export SADM_OS_NAME=$(sadm_get_osname)              # Uppercase, REDHAT,CENTOS,UBUNTU,AIX,DEBIAN
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    export SADM_ALERT_TYPE=3                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=60                          # When script end Trim rch file to 60 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================



#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
REAR_CFGFILE="/etc/rear/site.conf"          ; export REAR_CFGFILE       # ReaR Site Config file
#
export NFS_MOUNT="/mnt/rear_$$"                                         # NFS Could be more than one
export REAR_DIR="${NFS_MOUNT}/${SADM_HOSTNAME}"                         # Rear Host Backup Dir.
export REAR_NAME="${REAR_DIR}/rear_${SADM_HOSTNAME}"                    # ISO & Backup Prefix Name
export REAR_CUR_ISO="${REAR_NAME}.iso"                                  # Rear Host ISO File Name
export REAR_NEW_ISO="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").iso"   # Rear Backup ISO 
export REAR_CUR_BAC="${REAR_NAME}.tar.gz"                               # Rear Host Backup File Name
export REAR_NEW_BAC="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").tar.gz" # Rear Previous Backup File  
#



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





# --------------------------------------------------------------------------------------------------
# Rear Backup preparation 
# Make sure mount point exist, do a mount test and make sure backup directory exist
# --------------------------------------------------------------------------------------------------
rear_preparation()
{
    sadm_writelog "$SADM_FIFTY_DASH"                                    # Write 50 dashes line
    sadm_writelog "Perform ReaR preparation."                           # Feed User and Log
    sadm_writelog " "                                                   # Write white line

    # Make sure Local mount point exist.
    if [ ! -d ${NFS_MOUNT} ] ; then mkdir ${NFS_MOUNT} ; chmod 775 ${NFS_MOUNT} ; fi

    # Mount the NFS Mount point 
    sadm_writelog "Testing mount operation of the NFS Drive on $SADM_REAR_NFS_SERVER system."
    umount ${NFS_MOUNT} > /dev/null 2>&1                                # Make sure not already mount
    sadm_writelog "mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${NFS_MOUNT}"
    mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${NFS_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]
        then RC=1
             sadm_writelog "[ ERROR ] NFS Mount on system $SADM_REAR_NFS_SERVER failed."
             sadm_writelog "Process Aborted"
             umount ${NFS_MOUNT} > /dev/null 2>&1
             return 1
    fi
    sadm_writelog "NFS mount succeeded ..."
    df -h | grep ${NFS_MOUNT} | while read wline ; do sadm_writelog "$wline"; done

    
    # Make sure the Directory of the host exist on NFS Server and have proper permission
    if [ ! -d  "${NFS_MOUNT}/${SADM_HOSTNAME}" ]
        then mkdir ${NFS_MOUNT}/${SADM_HOSTNAME}
             if [ $? -ne 0 ] 
                then sadm_writelog "[ ERROR ] Creating directory ${NFS_MOUNT}/${SADM_HOSTNAME}" 
                     return 1 
             fi
    fi
    
    # sadm_writelog "chmod 775 ${NFS_MOUNT}/${SADM_HOSTNAME}"             # Feed user and log.
    chmod 775 ${NFS_MOUNT}/${SADM_HOSTNAME} >> $SADM_LOG 2>&1           # Make sure Dir. is writable
    if [ $? -ne 0 ]                                                     # If error on chmod command
       then sadm_writelog "[ ERROR ] Can't chmod directory ${NFS_MOUNT}/${SADM_HOSTNAME}" 
            return 1 
    fi
    
    sadm_writelog "Trying to write to NFS mount ..."                    # Feed user and log
    TEST_FILE="${NFS_MOUNT}/${SADM_HOSTNAME}/rear_pid_$SADM_TPID.txt"   # Create test file name
    touch ${TEST_FILE} >> $SADM_LOG 2>&1                                # Create empty test file
    if [ $? -ne 0 ]                                                     # If error on chmod command
       then sadm_writelog "[ ERROR ] Can't write test file ${TEST_FILE}."        
            return 1                                                    # Back to caller with error
    fi
    sadm_writelog "Wrote to NFS mount with no problem."                 # Feed user and log
    rm -f ${TEST_FILE} >> $SADM_LOG 2>&1                                # Delete the test file

    #sadm_writelog " "
    sadm_writelog "ReaR preparation done with success."
    sadm_writelog " "
    return 0
}




# --------------------------------------------------------------------------------------------------
# Mount the NFS Drive, check (change)) permission and make sure we have the correct number of copies
# --------------------------------------------------------------------------------------------------
rear_housekeeping()
{
    FNC_ERROR=0                                                       # Cleanup Error Default 0
    sadm_writelog "$SADM_FIFTY_DASH"                                    # Write 50 dashes line
    sadm_writelog "Perform ReaR housekeeping."
    
    # Rename the Newly created ISO 
    # Example: From 'rear_yoda.iso' to 'rear_yoda_2019.08.29_05:00:12.iso')
    if [ -r "$REAR_CUR_ISO" ]
        then sadm_writelog " "
             sadm_writelog "Rename new ISO ..." 
             sadm_writelog "mv $REAR_CUR_ISO $REAR_NEW_ISO"
             mv $REAR_CUR_ISO $REAR_NEW_ISO >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error trying to move $REAR_CUR_ISO to $REAR_NEW_ISO"
                      sadm_writelog "***** Rear Backup Abort *****"
                      return 1                                          # Back to caller with error
                 else sadm_writelog "The ISO rename was done successfully"
             fi
    fi
    
    # Rename the newly created ReaR backup.
    # Example: From 'rear_yoda.tar.gz' to 'rear_yoda_2019.08.29_05:00:12.tar.gz'
    if [ -r "$REAR_CUR_BAC" ]
        then sadm_writelog " "
             sadm_writelog "Rename new backup ..."
             sadm_writelog "mv ${REAR_CUR_BAC} ${REAR_NEW_BAC}"
             mv ${REAR_CUR_BAC} ${REAR_NEW_BAC} >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error trying to move ${REAR_CUR_BAC} to ${REAR_NEW_BAC}"
                      sadm_writelog "***** Rear Backup Abort *****"
                      return 1                                          # Back to caller with error
                 else sadm_writelog "The rename of the backup file was done successfully"
             fi
    fi
                    
    sadm_writelog " "
    sadm_writelog "You have chosen to keep $SADM_REAR_BACKUP_TO_KEEP backup files on the NFS server."
    sadm_writelog " "
    sadm_writelog "List of ReaR backup and ISO actually on NFS Server for ${SADM_HOSTNAME}"
    ls -ltrh ${REAR_NAME}* | while read wline ; do sadm_writelog "$wline"; done

    # Delete backup that are over the number we want to keep.
    COUNT_GZ=`ls -1t ${REAR_NAME}*.gz |sort -r |sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | wc -l` 
    if [ "$COUNT_GZ" -ne 0 ]
        then sadm_writelog " "
             sadm_writelog "Number of backup file(s) to delete is $COUNT_GZ"
             sadm_writelog "Backup file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | while read wline ; do sadm_writelog "$wline"; done
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] ;then sadm_writelog "Problem deleting backup file(s)" ;FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ;then sadm_writelog "Backup was deleted with success" ;fi
        else RC=0
             sadm_writelog " "
             sadm_writelog "We don't need to delete any backup file."
    fi
        
    # Delete the ISO that are over the number we want to keep.
    COUNT_ISO=`ls -1t  ${REAR_NAME}*.iso |sort -r |sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | wc -l`  
    if [ "$COUNT_ISO" -ne 0 ]
        then sadm_writelog " "
             sadm_writelog "Number of ISO file(s) to delete is $COUNT_ISO"
             sadm_writelog "Backup ISO file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | while read wline ; do sadm_writelog "$wline"; done
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] ; then sadm_writelog "Problem deleting ISO file(s)"; FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ; then sadm_writelog "ISO file(s) deleted with success" ; fi
        else RC=0
             sadm_writelog "We don't need to delete any backup ISO file."
    fi
        
    # Make sure Host Directory permission and files below are ok
    sadm_writelog " "
    sadm_writelog "Make sure backup are readable."
    sadm_writelog "chmod 644 ${REAR_NAME}*"
    chmod 644 ${REAR_NAME}* >> /dev/null 2>&1
        
    # List Backup Directory to user after cleanup
    sadm_writelog " "
    sadm_writelog "Content of ${SADM_HOSTNAME} ReaR backup directory after housekeeping."
    ls -ltrh ${REAR_NAME}* | while read wline ; do sadm_writelog "$wline"; done


    # Ok Cleanup up is finish - Unmount the NFS
    sadm_writelog " "
    sadm_writelog "Unmounting NFS mount directories"
    sadm_writelog "umount ${NFS_MOUNT}"
    umount ${NFS_MOUNT} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_writelog "Error returned on previous command" ; FNC_ERROR=1; fi

    # Remove NFS mount point.
    # It is different every time you run the script (more than one backup can run simultaneously)
    if [ -d "${NFS_MOUNT}" ] ; then rm -f ${NFS_MOUNT} >/dev/null 2>&1 ; fi

    sadm_writelog " "
    sadm_writelog "ReaR Backup Housekeeping done with success."
    sadm_writelog " "
    return $FNC_ERROR
}




    
# --------------------------------------------------------------------------------------------------
#                     Create the Rescue ISO and a tar file of the server
# --------------------------------------------------------------------------------------------------
create_backup()
{
    # Feed user and log, the what we are about to do.
    sadm_writelog "$SADM_FIFTY_DASH"                                    # Write 50 dashes line
    sadm_writelog "Creating the 'ReaR' backup." 
    sadm_writelog " "                                                   # Write white line
    sadm_writelog "$REAR mkbackup -v "       

    # Create the Backup TGZ file on the NFS Server
    $REAR mkbackup -v >> $SADM_LOG 2>&1                                 # Produce Rear Backup for DR
    RC=$?                                                               # Save Command return code.
    sadm_writelog "ReaR backup exit code : ${RC}."                      # Show user backup exit code 
    sadm_writelog " "
    if [ $RC -ne 0 ]
        then sadm_writelog "See the error message in ${SADM_LOG}." 
             sadm_writelog "***** Rear Backup completed with Error - Aborting Script *****"
             sadm_writelog " "
             sadm_writelog "$SADM_FIFTY_DASH"                           # Write 50 dashes line
             return 1                                                   # Back to caller with error
        else sadm_writelog "***** Rear Backup completed with Success *****"
             sadm_writelog " "
             sadm_writelog " "
             sadm_writelog "$SADM_FIFTY_DASH"                           # Write 50 dashes line
             sadm_writelog "List of Rear backup on NFS server."
             #ls -ltr ${REAR_DIR}/*.gz | nl | while read wline ; do sadm_writelog "$wline"; done
             ls -ltr ${REAR_NAME}* | while read wline ; do sadm_writelog "$wline"; done
             sadm_writelog " "
    fi
    
    return 0                                                            # Return Default return code
}




# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------
#                                    Script Start HERE
# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------

    # Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "You need to be root to perform this script." # Advise User Message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

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
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi
 
    # Check if REAR is not installed - Abort Process 
    if ${SADM_WHICH} rear >/dev/null 2>&1                               # command is found ?
        then REAR=`${SADM_WHICH} rear`                                  # Store Path of command
        else sadm_writelog "The command 'rear' is missing, Job Aborted" # Advise User Aborting
             sadm_stop 1                                                # Upd. RCH File & Trim Log 
             exit 1                                                     # Exit With Global Err (0/1)
    fi

    # If Rear configuration is not there - Abort Process
    if [ ! -r "$REAR_CFGFILE" ]                                         # ReaR Site config exist?
        then sadm_writelog "The $REAR_CFGFILE isn't present"            # Warn User - Missing file
             sadm_writelog "The backup will not run - Job Aborted"      # Warn User - No Backup
             sadm_stop 1                                                # Upd. RCH File & Trim Log 
             exit 1                                                     # Exit With Global Err (0/1)
    fi

    # Make sure ReaR NFS mount point exist and actually mount, create server dir. on NFS server.
    rear_preparation                                                    # Mount Point Work ?  ...

    # If Rear preparation worked OK, perform the ReaR Backup.
    if [ $? -eq 0 ]                                                     # If preparation went OK 
        then create_backup                                              # Do the ReaR ISO and Backup
             if [ $? -ne 0 ]                                            # If Error Making Backup
                then SADM_EXIT_CODE=1                                   # If Error Exit code = 1
                else SADM_EXIT_CODE=0                                   # No Error Exit code = 0
             fi             
        else SADM_EXIT_CODE=1                                           # When Error, make RC to 1
    fi

    # If Backup is OK, perform housekeeping (Del. backup according to backup policies & umount NFS)
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # Everything ok so far
        then rear_housekeeping                                          # Remove old backup & umount
             if [ $? -ne 0 ]                                            # If Error in housekeeping
                then SADM_EXIT_CODE=1                                   # If Error Exit code = 1
                else SADM_EXIT_CODE=0                                   # No Error Exit code = 0
             fi  
    fi 

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
