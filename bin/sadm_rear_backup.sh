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
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
# 2016_12_14 v1.7 Add Check to see if Rear Configuration file isnt't present, abort Job (Exit 1)
# 2017_03_09 v1.8 Move test if rear is installed first, if not abort process up front.
#                 Error Message more verbose and More Customization
# 2017_04_20 v2.0 Return Code returned by Rear handle correctly, Script Messages more informative
# 2017_06_06 v2.1 NFS Server Name, Mount Point and Nb of copy to keep are taken from sadmin.cfg
# 2018_09_14 v2.2 ExitCode was reporting error on some occasion, even when backup was ok.
#@2018_09_19 v2.3 Include Usage of Alert Group 
#@2018_11_02_v2.4 Produce new log every time
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x




#===================================================================================================
#               Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # Test if 'SADMIN' environment variable is defined
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    # Test if 'SADMIN' Shell Library is readable 
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.4'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code
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




#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
NFS_MOUNT="/mnt/nfs1"                       ; export NFS_MOUNT          # Local NFS Mount Point 
REAR_CFGFILE="/etc/rear/site.conf"          ; export REAR_CFGFILE       # ReaR Configuration file



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

# --------------------------------------------------------------------------------------------------
# Update 'BACKUP_URL' line in /etc/rear/site.conf file, to have same NFS Server and MOunt Point 
# found in $SADMIN/cfg/sadmin.cfg file.
#       $SADM_REAR_NFS_SERVER               # ReaR NFS Server where backup will be stored
#       $SADM_REAR_NFS_MOUNT_POINT          # ReaR Mount Point exported on the NFS Server
# --------------------------------------------------------------------------------------------------
update_site_conf()
{
    sadm_writelog "Updating 'BACKUP_URL' line in ReaR Site file ($REAR_CFGFILE) ..."
    grep -v 'BACKUP_URL' $REAR_CFGFILE > $SADM_TMP_FILE2
    newline="BACKUP_URL=\"nfs://${SADM_REAR_NFS_SERVER}/${SADM_REAR_NFS_MOUNT_POINT}/\"" 
    echo $newline >>$SADM_TMP_FILE2
    cp $SADM_TMP_FILE2 $REAR_CFGFILE
    chmod 644 $REAR_CFGFILE
    chown root:root $REAR_CFGFILE
}





    
# --------------------------------------------------------------------------------------------------
#                     Create the Rescue ISO and a tar file of the server
# --------------------------------------------------------------------------------------------------
create_backup()
{
    # Create the bootable ISO on the NFS Server
    sadm_writelog " "
    sadm_writelog "$SADM_TEN_DASH"; 
    sadm_writelog "***** CREATING THE 'ReaR' BOOTABLE ISO *****"
    sadm_writelog " "
    sadm_writelog "$REAR mkrescue -v "       
    $REAR mkrescue -v | tee -a $SADM_LOG                                 # Produce Bootable ISO
    if [ $? -ne 0 ]
        then sadm_writelog "***** ISO creation completed with error - Aborting Script *****"
             return 1 
        else sadm_writelog "***** ISO created with Success *****"
    fi
    
    # Create the Backup TGZ file on the NFS Server
    sadm_writelog "" 
    sadm_writelog "$SADM_TEN_DASH"; 
    sadm_writelog "***** CREATING THE 'ReaR' BACKUP *****"
    sadm_writelog " "
    sadm_writelog "$REAR mkbackup -v "       
    $REAR mkbackup -v | tee -a $SADM_LOG                                  # Produce Backup for DR
    if [ $? -ne 0 ]
        then sadm_writelog "***** Rear Backup completed with Error - Aborting Script *****"
             return 1 
        else sadm_writelog "***** Rear Backup completed with Success *****"
    fi
    
    return 0                                                            # Return Default return code
}



# --------------------------------------------------------------------------------------------------
# Mount the NFS Drive, check (change)) permission and make sure we have the correct number of copies
# --------------------------------------------------------------------------------------------------
rear_housekeeping()
{
    FNC_ERROR=0                                                       # Cleanup Error Default 0
    sadm_writelog "***** Perform ReaR Housekeeping *****"

    update_site_conf                                                  # Chck Backup URL in site.conf 

    # Make sure Local mount point exist
    if [ ! -d ${NFS_MOUNT} ] ; then mkdir ${NFS_MOUNT} ; chmod 775 ${NFS_MOUNT} ; fi

    # Mount the NFS Mount point 
    sadm_writelog "Mounting the NFS Drive on $SADM_REAR_NFS_SERVER"
    umount ${NFS_MOUNT} > /dev/null 2>&1
    sadm_writelog "mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${NFS_MOUNT}"
    mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${NFS_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]
        then RC=1
             sadm_writelog "Mount of $SADM_REAR_NFS_MOUNT_POINT on NFS server $SADM_REAR_NFS_SERVER Failed"
             sadm_writelog "Proces Aborted"
             umount ${NFS_MOUNT} > /dev/null 2>&1
             return 1
    fi
    sadm_writelog "NFS mount succeeded ..."
    df -h | grep ${NFS_MOUNT} | tee -a $SADM_LOG 2>&1

    
    # Make sure the Directory of the host exist on NFS Server and have proper permission
    if [ ! -d  "${NFS_MOUNT}/${SADM_HOSTNAME}" ]
        then mkdir ${NFS_MOUNT}/${SADM_HOSTNAME}
             if [ $? -ne 0 ] 
                then sadm_writelog "Error can't create directory ${NFS_MOUNT}/${SADM_HOSTNAME}" 
                     return 1 
             fi
    fi
    sadm_writelog "chmod 775 ${NFS_MOUNT}/${SADM_HOSTNAME}"
    chmod 775 ${NFS_MOUNT}/${SADM_HOSTNAME} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] 
       then sadm_writelog "Error can't chmod directory ${NFS_MOUNT}/${SADM_HOSTNAME}" 
            return 1 
    fi
    
    # Create Environnement Variable of all files we are about to deal with below
    REAR_DIR="${NFS_MOUNT}/${SADM_HOSTNAME}"                            # Rear Host Backup Dir.
    REAR_NAME="${REAR_DIR}/rear_${SADM_HOSTNAME}"                       # ISO & Backup Prefix Name
    REAR_ISO="${REAR_NAME}.iso"                                         # Rear Host ISO File Name
    PREV_ISO="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").iso"          # Rear Backup ISO 
    REAR_BAC="${REAR_NAME}.tar.gz"                                      # Rear Host Backup File Name
    PREV_BAC="${REAR_NAME}_$(date "+%C%y.%m.%d_%H:%M:%S").tar.gz"       # Rear Previous Backup File  

    # Make a copy of actual ISO before creating a new one   
    if [ -r "$REAR_ISO" ]
        then sadm_writelog " "
             sadm_writelog "Rename actual ISO before creating a new one"
             sadm_writelog "mv $REAR_ISO $PREV_ISO"
             mv $REAR_ISO $PREV_ISO >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error trying to move $REAR_ISO to $PREV_ISO"
                 else sadm_writelog "The ISO rename was done successfully"
             fi
    fi
    
    # Make a copy of actual Backup file before creating a new one   
    if [ -r "$REAR_BAC" ]
        then sadm_writelog "Rename actual Backup file before creating a new one"
             sadm_writelog "mv $REAR_BAC $PREV_BAC"
             mv $REAR_BAC $PREV_BAC >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_writelog "Error trying to move $REAR_BAC to $PREV_BAC"
                 else sadm_writelog "The rename of the backup file was done successfully"
             fi
    fi
                    
    sadm_writelog " "
    sadm_writelog "You choose to keep $SADM_REAR_BACKUP_TO_KEEP backup files on the NFS server"
    sadm_writelog "Here is a list of ReaR backup and ISO on NFS Server for ${SADM_HOSTNAME}"
    #sadm_writelog "ls -1t ${REAR_NAME}*.iso | sort -r"
    ls -1t ${REAR_NAME}*.iso | sort -r | tee -a $SADM_LOG
    ls -1t ${REAR_NAME}*.gz  | sort -r | tee -a $SADM_LOG

    COUNT_GZ=` ls -1t  ${REAR_NAME}*.gz  |sort -r |sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | wc -l`  # Nb of GZ  to Del.
    if [ "$COUNT_GZ" -ne 0 ]
        then sadm_writelog " "
             sadm_writelog "Number of backup file(s) to delete is $COUNT_GZ"
             sadm_writelog "List of backup file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | tee -a $SADM_LOG
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] ;then sadm_writelog "Problem deleting backup file(s)" ;FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ;then sadm_writelog "Backup was deleted with success" ;fi
        else RC=0
             sadm_writelog " "
             sadm_writelog "We don't need to delete any backup file"
    fi
        
    COUNT_ISO=`ls -1t  ${REAR_NAME}*.iso |sort -r |sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | wc -l`  # Nb of ISO  to Del.
    if [ "$COUNT_ISO" -ne 0 ]
        then sadm_writelog " "
             sadm_writelog "Number of ISO file(s) to delete is $COUNT_ISO"
             sadm_writelog "List of ISO file(s) that will be Deleted :"
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | tee -a $SADM_LOG
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] ; then sadm_writelog "Problem deleting ISO file(s)"; FNC_ERROR=1; fi
             if [ $RC -eq 0 ] ; then sadm_writelog "ISO file(s) deleted with success" ; fi
        else RC=0
             sadm_writelog " "
             sadm_writelog "We don't need to delete any ISO file"
    fi
        
    # Make sure Host Directory permission and files below are ok
    sadm_writelog " "
    sadm_writelog "Make sure backup are readable."
    sadm_writelog "chmod 664 ${REAR_NAME}*"
    chmod 664 ${REAR_NAME}* >> /dev/null 2>&1
        
    # Ok Cleanup up is finish - Unmount the NFS
    sadm_writelog "Unmounting NFS mount directories"
    sadm_writelog "umount ${NFS_MOUNT}"
    umount ${NFS_MOUNT} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] ; then sadm_writelog "Error returned on previous command" ; FNC_ERROR=1; fi

    sadm_writelog " "
    sadm_writelog "***** ReaR Backup Housekeeping is terminated *****"
    sadm_writelog " "
    return $FNC_ERROR
}




# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------
#                                    Script Start HERE
# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------

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
    
    # Remove default crontab job - So we can decide otherwise when we run rear from this script
    if [ -r /etc/cron.d/rear ] ; then rm -f /etc/cron.d/rear >/dev/null 2>&1; fi

    rear_housekeeping                                                   # Set Perm. & rm old version
    if [ $? -eq 0 ]                                                     # If went OK do Clean up
        then create_backup                                              # Set Perm. & rm old version
             if [ $? -ne 0 ]                                            # If Error Making Backup
                then SADM_EXIT_CODE=1                                   # If Error Exit code = 1
                else SADM_EXIT_CODE=0                                   # No Error Exit code = 0
             fi             
        else SADM_EXIT_CODE=1                                           # Error encounter exitcode=1
    fi
 
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
