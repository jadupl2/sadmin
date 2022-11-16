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
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
# 2019_09_18 Update: v2.11 Show Backup size in human readable form.
# 2020_01_08 Update: v2.12 Minor logging changes.
# 2020_02_18 Update: v2.13 Correct typo error introduce in v2.12
# 2020_03_04 Fix: v2.14 always leave latest ReaR Backup to default name to ease the restore.
# 2020_03_05 Fix: v2.15 Was not removing NFS mount point in /mnt after the backup.
# 2020_04_11 Fix: v2.16 site.conf, "BACKUP_URL" line is align with sadmin.cfg before each backup.
# 2020_04_12 Update: v2.17 If ReaR site.conf doesn't exist, create it, bug fix and enhancements.
# 2020_04_13 Update: v2.18 Lot of little adjustments.
# 2020_04_14 Update: v2.19 Some more logging adjustments.
# 2020_04_16 Update: v2.20 Minor adjustments
# 2020_05_13 Update: v2.21 Remove mount directory before exiting script.
# 2020_05_18 Fix: v2.22 Fix /etc/rear/site.conf auto update problem, prior to starting backup.
# 2020_06_30 Fix: v2.23 Fix chmod 664 for files in server backup directory
# 2020_09_05 Fix: v2.24 Minor Changes.
# 2021_01_11 Fix: v2.25 NFS drive was not unmounted when the backup failed.
# 2021_05_11 backup: v2.26 Fix 'rear' command missing false error message 
# 2021_05_12 backup: v2.27 Write more information about ReaR sadmin.cfg in the log.
# 2021_06_02 backup: v2.28 Added more information in the script log.
# 2022_05_11 backup: v2.29 Minor change to log output.
# 2022_08_17 backup: v2.30 Update new SADMIN section v1.52 and code revision.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.52
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] # SADMIN defined ? SADMIN Libr. exist   
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi # Last chance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                    # No SADMIN Env. Var. Exit
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
export SADM_VER='2.30'                                     # Script version number
export SADM_PDESC="Produce a ReaR bootable iso and a restorable backup on an NFS server"
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
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




#===================================================================================================
# Scripts Variables 
#===================================================================================================
export NFS_MOUNT="/mnt/rear_$$"                                         # Temp. NFS Backup MountPoint
export REAR_DIR="${NFS_MOUNT}/${SADM_HOSTNAME}"                         # Rear Host Backup Dir.
export REAR_NAME="${REAR_DIR}/rear_${SADM_HOSTNAME}"                    # ISO & Backup Prefix Name
export REAR_CUR_ISO="${REAR_NAME}.iso"                                  # Rear Host ISO File Name
export REAR_CUR_BAC="${REAR_NAME}.tar.gz"                               # Rear Host Backup File Name
export REAR_CFGFILE="/etc/rear/site.conf"                               # ReaR Site Config file
export REAR_TMP="${SADMIN}/tmp/rear_site.tmp$$"                         # New ReaR site.conf tmp file




# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
# Process Operating System received in parameter (aix/linux,darwin)
# --------------------------------------------------------------------------------------------------
update_url_in_rear_site_conf()
{
    # if ReaR Temp. File exist delete it, we will use it below.
    if [ -f "$REAR_TMP" ] ; then rm -f $REAR_TMP >/dev/null 2>&1 ; fi

    # Loop through /etc/rear/site.conf and update the BACKUP_URL Line.
    while read wline
	    do
        echo $wline | grep -i "^BACKUP_URL" >/dev/null 2>&1             # Line begin "BACKUP_URL"
        if [ $? -eq 0 ]                                                   # If BACKUP_URL line
            then sadm_write "Update backup destination in $REAR_CFGFILE with value from sadmin.cfg.\n" 
                 echo "BACKUP_URL=\"nfs://${SADM_REAR_NFS_SERVER}${SADM_REAR_NFS_MOUNT_POINT}\"" >> $REAR_TMP
                 sadm_write "  - BACKUP_URL=\"nfs://${SADM_REAR_NFS_SERVER}${SADM_REAR_NFS_MOUNT_POINT}\"\n"
            else echo "$wline" >> $REAR_TMP                             # Output normal line in TMP
        fi
        done < $REAR_CFGFILE                                            # Read /etc/rear/site.conf

    # Copy New site.conf ($REAR_TMP) to the official one ($REAR_CFGFILE).
    sadm_write "  - Update actual $REAR_CFGFILE "
    cp $REAR_TMP $REAR_CFGFILE                                              # Replace ReaR site.conf
    if [ $? -ne 0 ]
       then sadm_write_err "[ ERROR ] replacing actual ${REAR_CFGFILE}."
            sadm_write_err "***** Rear Backup Abort *****"
            return 1                                                    # Back to caller with error
       else sadm_writelog "[ OK ]"
    fi
}



# --------------------------------------------------------------------------------------------------
# Process Operating System received in parameter (aix/linux,darwin)
# --------------------------------------------------------------------------------------------------
create_etc_rear_site_conf()
{
    # if /etc/rear/site.conf is readable, then return to caller.
    if [ -r "$REAR_CFGFILE" ] ; then return 0 ; fi

    sadm_write "The $REAR_CFGFILE isn't present.\n"                     # Warn User - Missing file
    sadm_write "A Default ReaR site file have been created.\n"          # Warn User - new site.conf 

    # Start creating the header of ReaR site.conf file into a temp. file for now.
    echo  "# Create a bootable ISO9660 image on disk as rear-${SADM_HOSTNAME}.iso" > $REAR_TMP
    echo  "OUTPUT=ISO" >> $REAR_TMP
    echo  " " >> $REAR_TMP

    echo  "# Internal backup method (NFS) used to create a simple backup (tar archive)." >>$REAR_TMP
    echo  "BACKUP=NETFS" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    
    echo  "# Directory within mount point where iso and tgz will be stored" >> $REAR_TMP
    echo  "NETFS_PREFIX=\"\$HOSTNAME\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    
    echo  "# To backup to NFS disk, use BACKUP_URL=nfs://nfs-server-name/share/path"  >> $REAR_TMP
    echo  "BACKUP_URL=\"nfs://${SADM_REAR_NFS_SERVER}${SADM_REAR_NFS_MOUNT_POINT}\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    
    echo  "# Disable SELinux while the backup is running." >> $REAR_TMP
    echo  "BACKUP_SELINUX_DISABLE=1" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    
    echo  "# Prefix name for ISO images without the .iso suffix (rear_HOSTNAME.iso)" >> $REAR_TMP
    echo  "ISO_PREFIX=\"rear_\$HOSTNAME\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    
    echo  "# Name of Backup (tar.gz) File" >> $REAR_TMP
    echo  "BACKUP_PROG_ARCHIVE=\"rear_\$HOSTNAME\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    
    echo  "# Only include volume groups (opposite of EXCLUDE_VG)." >> $REAR_TMP
    echo  "# ONLY_INCLUDE_VG=( "rootvg"  "vg00" "vg01" ) " >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# Exclude Volume Group (and filesystem they include)." >> $REAR_TMP
    echo  "# EXCLUDE_VG & EXCLUDE_MOUNTPOINTS get automatically populated. " >> $REAR_TMP
    echo  "# EXCLUDE_VG=( datavg ) " >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# Exclude filesystems by specifying their mountpoints. " >> $REAR_TMP
    echo  "# Added automatically to the $BACKUP_PROG_EXCLUDE array. " >> $REAR_TMP
    echo  "# EXCLUDE_MOUNTPOINTS=( /data )" >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# BACKUP_PROG_EXCLUDE is an array of strings that get written into a " >> $REAR_TMP
    echo  "# backup-exclude.txt file used in 'tar -X backup-exclude.txt' to get " >> $REAR_TMP
    echo  "# things excluded from the backup. " >> $REAR_TMP
    echo  "# Proper quoting of the BACKUP_PROG_EXCLUDE array members is crucial" >> $REAR_TMP
    echo  "# to avoid bash expansions. Example :" >> $REAR_TMP
    echo  "# BACKUP_PROG_EXCLUDE=( "${BACKUP_PROG_EXCLUDE[@]}" '/d1/*' '/d2/*' ) " >> $REAR_TMP
    echo  "# BACKUP_PROG_EXCLUDE=( ${BACKUP_PROG_EXCLUDE[@]} '/tmp/*' "$HOME/.cache" )" >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# Exclude components from being backed up,recreation information is active" >> $REAR_TMP
    echo  "# EXCLUDE_BACKUP=()" >> $REAR_TMP
    echo  "" >> $REAR_TMP

    echo  "# Exclude components during the backup restore phase." >> $REAR_TMP
    echo  "# Only used to exclude files from the restore. " >> $REAR_TMP
    echo  "# EXCLUDE_RESTORE=()" >> $REAR_TMP
    echo  "" >> $REAR_TMP
    cat $REAR_TMP | tr -d '\r' > $REAR_CFGFILE                              # Remove CR in file
}




# --------------------------------------------------------------------------------------------------
# Rear Backup preparation 
#   - Test if rear executable exist, if not return error to caller.
#   - Test existence of ReaR configuration file, if not return error to caller.
#   - Test if local mount point exist, if not create it.
#   - Mount the NFS drive over the local mount point, if don't work return error to caller.
#   - If hostname directory doesn't exist in NFS directory, create it.
#   - Try to write test file to NFS mount point, if don't work return error to caller.
# --------------------------------------------------------------------------------------------------
rear_preparation()
{
    sadm_write_log "-----"                                              # Separator Line
    sadm_write_log "STARTING ReaR PREPARATION"                          # Feed User and Log

    # Check if REAR is not installed - Abort Process 
    ${SADM_WHICH} rear >/dev/null 2>&1                                  # rear command is found ?
    if [ $? -eq 0 ]                                                     # Yes it is on system                 
        then export REAR=`${SADM_WHICH} rear`                           # Store Path of command
        else sadm_write_err "[ ERROR ] The 'rear' command is missing, Job Aborted.\n" 
             return 1                                                   # Return Error to Caller 
    fi

    if [ ! -r "$REAR_CFGFILE" ]                                         # ReaR Site config exist?
        then create_etc_rear_site_conf                                  # Create /etc/rear/site.conf
    fi

    # If Rear configuration is not there - Create a default one 
    # We also need to update Backup Destination with the Value in sadmin.cfg 
    #   - SADM_REAR_NFS_SERVER      = NFS Server Host Name where Backup is stored
    #   - SADM_REAR_NFS_MOUNT_POINT = NFS mount point on the NFS Server
    update_url_in_rear_site_conf                                        # Update BACKUP_URL Line

    # Make sure Local mount point exist.
    if [ ! -d ${NFS_MOUNT} ] 
        then sadm_write_log " "
             sadm_write_log "Create local temporary mount point directory (${NFS_MOUNT})." 
             mkdir ${NFS_MOUNT} ; chmod 775 ${NFS_MOUNT} 
     fi

    # Mount the NFS Mount point 
    sadm_write "Mount the NFS share on $SADM_REAR_NFS_SERVER system.\n"
    umount ${NFS_MOUNT} > /dev/null 2>&1                                # Make sure not already mount
    sadm_write "mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${NFS_MOUNT} "
    mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${NFS_MOUNT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]
        then RC=1
             sadm_write_err "[ ERROR ] NFS Mount failed - Process Aborted."
             umount ${NFS_MOUNT} > /dev/null 2>&1
             rmdir  ${NFS_MOUNT} > /dev/null 2>&1
             return 1
    fi
    sadm_write "$SADM_OK \n"
    df -h | grep ${NFS_MOUNT} | sed 's/%//g' | while read wline ; do sadm_write "${wline}\n"; done

    # Make sure the Directory of the host exist on NFS Server and have proper permission
    if [ ! -d  "${NFS_MOUNT}/${SADM_HOSTNAME}" ]
        then mkdir ${NFS_MOUNT}/${SADM_HOSTNAME}
             if [ $? -ne 0 ] 
                then sadm_write_err "[ ERROR ] Creating directory ${NFS_MOUNT}/${SADM_HOSTNAME}" 
                     return 1 
             fi
    fi
    #chmod 775 ${NFS_MOUNT}/${SADM_HOSTNAME} >> $SADM_LOG 2>&1           # Make sure Dir. is writable
    #if [ $? -ne 0 ]                                                     # If error on chmod command
    #   then sadm_write "$SADM_ERROR Can't chmod directory ${NFS_MOUNT}/${SADM_HOSTNAME}\n" 
    #        return 1 
    #fi
    
    # Write test to NFS Mount Point.
    sadm_write "Write test to NFS mount ... "                           # Feed user and log
    TEST_FILE="${NFS_MOUNT}/${SADM_HOSTNAME}/rear_pid_$SADM_TPID.txt"   # Create test file name
    touch ${TEST_FILE} >> $SADM_LOG 2>&1                                # Create empty test file
    if [ $? -ne 0 ]                                                     # If error on chmod command
       then sadm_write_err "[ ERROR ] Can't write test file ${TEST_FILE}."        
            return 1                                                    # Back to caller with error
    fi
    sadm_write_log "[ OK ]"                                             # Feed user and log
    rm -f ${TEST_FILE} >> $SADM_LOG 2>&1                                # Delete the test file

    # If Last Backup ISO Exist, rename it to 'read_hostname_last modification date_time'.iso 
    # Example: From 'rear_yoda.iso' to 'rear_yoda_2019-08-29_05:00:12.iso')
    if [ -r "$REAR_CUR_ISO" ]
        then sadm_write "\n"
             FDATE=`stat --printf='%y\n' $REAR_CUR_ISO |awk '{ print $1 }'`
             FTIME=`stat --printf='%y\n' $REAR_CUR_ISO |awk '{ print $2 }' |awk -F\. '{ print $1 }'`
             REAR_NEW_ISO="${REAR_NAME}_${FDATE}_${FTIME}.iso"
             #sadm_write "Rename previous ISO `basename $REAR_CUR_ISO` to `basename $REAR_NEW_ISO` " 
             mv $REAR_CUR_ISO $REAR_NEW_ISO >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_write_err "[ ERROR ] trying to move $REAR_CUR_ISO to $REAR_NEW_ISO "
                      sadm_write_err "***** Rear Backup Abort *****"
                      return 1                                          # Back to caller with error
                 else sadm_write_log "Rename previous ISO `basename $REAR_CUR_ISO` to `basename $REAR_NEW_ISO` [ OK ]" 
             fi
        else sadm_write_log "New ISO will be created under the name of ${REAR_CUR_ISO}."
    fi
    
    # If Last Backup tar.gz Exist, rename it to 'read_hostname_last modification date_time'.tar.gz
    # Example: From 'rear_yoda.tar.gz' to 'rear_yoda_2019-08-29_05:00:12.tar.gz'
    if [ -r "$REAR_CUR_BAC" ]
        then FDATE=`stat --printf='%y\n' $REAR_CUR_BAC |awk '{ print $1 }'`
             FTIME=`stat --printf='%y\n' $REAR_CUR_BAC |awk '{ print $2 }' |awk -F\. '{ print $1 }'`
             REAR_NEW_BAC="${REAR_NAME}_${FDATE}_${FTIME}.tar.gz"
             mv ${REAR_CUR_BAC} ${REAR_NEW_BAC} >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
                 then sadm_write_err "Tried to move ${REAR_CUR_BAC} to ${REAR_NEW_BAC} [ ERROR ]"
                      sadm_write_err "***** Rear Backup Abort *****"
                      return 1                                          # Back to caller with error
                 else sadm_write_log "Rename previous backup `basename ${REAR_CUR_BAC}` to `basename ${REAR_NEW_BAC}` [ OK ]"
             fi
        else sadm_write_log "New Backup will be created under the name of ${REAR_CUR_BAC}."
    fi

    sadm_write_log "END OF ReaR PREPARATION ${SADM_SUCCESS}"
    sadm_write_log "-----" 
    sadm_write_log " " 
    return 0
}




# --------------------------------------------------------------------------------------------------
# Mount the NFS Drive, check (change)) permission and make sure we have the correct number of copies
# --------------------------------------------------------------------------------------------------
rear_housekeeping()
{
    FNC_ERROR=0                                                         # Cleanup Error Default 0
    sadm_write "${SADM_FIFTY_DASH}\n"
    sadm_write "${BOLD}Perform ReaR housekeeping.${NORMAL}\n"
                    
    sadm_writelog " "
    sadm_writelog "Information coming from ${SADM_CFG_FILE}:"
    sadm_writelog " - Always keep last $SADM_REAR_BACKUP_TO_KEEP backup on '${SADM_REAR_NFS_SERVER}'"  
    sadm_writelog " "
    sadm_writelog "List of ReaR backup and ISO actually on NFS Server for ${SADM_HOSTNAME}"
    ls -ltrh ${REAR_NAME}* | while read wline ; do sadm_write "${wline}\n"; done

    # Delete backup that are over the number we want to keep.
    COUNT_GZ=`ls -1t ${REAR_NAME}*.gz |sort -r |sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | wc -l` 
    if [ "$COUNT_GZ" -ne 0 ]
        then sadm_write "\n"
             sadm_write "Number of backup file(s) to delete is $COUNT_GZ \n"
             sadm_write "Backup file(s) that will be Deleted :\n"
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | while read wline ; do sadm_write "${wline}\n"; done
             ls -1t ${REAR_NAME}*.gz | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] 
                then sadm_write_err "Problem deleting backup file(s) [ ERROR ]" 
                     FNC_ERROR=1
                else sadm_write_log "Backup deleted [ OK ]" 
             fi
        else RC=0
             sadm_write "Don't need to delete any old backup file(s) ${SADM_OK}\n"
    fi
        
    # Delete the ISO that are over the number we want to keep.
    COUNT_ISO=`ls -1t  ${REAR_NAME}*.iso |sort -r |sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | wc -l`  
    if [ "$COUNT_ISO" -ne 0 ]
        then sadm_write "\n"
             sadm_write "Number of ISO file(s) to delete is $COUNT_ISO \n"
             sadm_write "Backup ISO file(s) that will be Deleted :\n"
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | while read wline ; do sadm_write "${wline}\n"; done
             ls -1t ${REAR_NAME}*.iso | sort -r| sed 1,${SADM_REAR_BACKUP_TO_KEEP}d | xargs rm -f >> $SADM_LOG 2>&1
             RC=$?
             if [ $RC -ne 0 ] 
                 then sadm_write_err "Problem deleting ISO file(s) [ ERROR ]"
                      FNC_ERROR=1
                 else sadm_write_log "ISO deleted [ OK ]" 
             fi
        else RC=0
             sadm_write_log "Don't need to delete any old ISO file(s) [ OK ]"
    fi
        
    # List Backup Directory to user after cleanup
    sadm_write_log " "
    sadm_write_log "Content of ${SADM_HOSTNAME} ReaR backup directory after housekeeping."
    ls -ltrh ${REAR_NAME}* | while read wline ; do sadm_write "${wline}\n"; done

     #TOTALK=$(du -k ${REAR_NAME}.* | awk '{sum+=$1} END{print sum}')
    #TOTALG=$(echo "$TOTALK /1024/1024" | $SADM_BC -l) 
    #TOTAL

    # Ok Cleanup up is finish - Unmount the NFS
    sadm_write_log " "
    sadm_write_log "Unmounting NFS mount directory ${NFS_MOUNT} ..."
    sadm_write_log "umount ${NFS_MOUNT} "
    umount ${NFS_MOUNT} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ] 
       then sadm_write_err "[ ERROR ] Problem unmounting ${NFS_MOUNT}.\n"
            FNC_ERROR=1
       else rmdir ${NFS_MOUNT} > /dev/null 2>&1
            sadm_write_log "[ OK ]" 
    fi  

    # Remove NFS mount point.
    # It is different every time you run the script (more than one backup can run simultaneously)
    if [ -d "${NFS_MOUNT}" ] 
        then sadm_write "\n" 
             sadm_write "Removing NFS mount directory ${NFS_MOUNT} ...\n"
             sadm_write "rm -fr ${NFS_MOUNT} "
             rm -fr ${NFS_MOUNT} >/dev/null 2>&1 
             if [ $? -ne 0 ] 
                then sadm_write_err "[ ERROR ] Problem removing mount point unmounting ${NFS_MOUNT}.\n"
                     FNC_ERROR=1
                else sadm_write_log "[ OK ] " 
             fi
    fi  

    # Delete TMP work file before retuning to caller 
    if [ ! -f "$REAR_TMP" ] ; then rm -f $REAR_TMP >/dev/null 2>&1 ; fi
    
    sadm_write_log " "
    sadm_write_log "ReaR Backup Housekeeping ${SADM_SUCCESS}"
    return $FNC_ERROR
}




    
# --------------------------------------------------------------------------------------------------
#                     Create the Rescue ISO and a tar file of the server
# --------------------------------------------------------------------------------------------------
create_backup()
{
    # Feed user and log, the what we are about to do.
    sadm_write_log " "                                                     # Write white line
    sadm_write_log "-----"
    sadm_write_log "CREATING THE 'ReaR' BACKUP" 
    sadm_write_log " "                                                     # Write white line
    sadm_write_log "$REAR mkbackup -v"       

    # Create the Backup TGZ file on the NFS Server
    $REAR mkbackup -v >> $SADM_LOG 2>&1                                 # Produce Rear Backup for DR
    RC=$?                                                               # Save Command return code.
    sadm_write "ReaR backup exit code : ${RC}\n"                        # Show user backup exit code 
    if [ $RC -ne 0 ]
        then sadm_write_err "See the error message in ${SADM_LOG} ${SADM_ERROR}." 
             sadm_write_err "***** Rear Backup completed with Error - Aborting Script *****"
             sadm_write_err "Unmount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT}" 
             umount  ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} > /dev/null 2>&1
             return 1                                                   # Back to caller with error
        else sadm_write_log " "
             sadm_write_log "More info in the log ${SADM_LOG}."
             sadm_write_log "Rear Backup completed ${SADM_SUCCESS}"
             sadm_write_log " "
    fi
    #chmod 664 ${REAR_DIR}/*                                             # Give access for Maint.
    return 0                                                            # Return Default return code
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    rear_preparation                                                    # Mount Point Work ?  ...
    if [ $? -eq 0 ]                                                     # If preparation went OK 
        then create_backup                                              # Do the ReaR ISO and Backup
             if [ $? -ne 0 ]                                            # If Error Making Backup
                then SADM_EXIT_CODE=1                                   # If Error Exit code = 1
                else SADM_EXIT_CODE=0                                   # No Error Exit code = 0
             fi             
        else SADM_EXIT_CODE=1                                           # When Error, make RC to 1
    fi
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # Everything ok so far
        then rear_housekeeping                                          # Remove old backup & umount
             if [ $? -ne 0 ]                                            # If Error in housekeeping
                then SADM_EXIT_CODE=1                                   # If Error Exit code = 1
                else SADM_EXIT_CODE=0                                   # No Error Exit code = 0
             fi  
    fi 
    if [ -f "$REAR_TMP" ] ; then rm -f $REAR_TMP >/dev/null 2>&1 ; fi   # Remove Temp File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
