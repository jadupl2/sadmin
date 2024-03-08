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
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
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
# 2023_03_07 backup: v2.31 Major update, backup directory restructure & show backup size in log.
# 2023_03_10 backup: v2.32 Include a list of the 10 biggest files included in the ReaR backup file.
# 2023_03_11 backup: v2.33 New '.lst' file is generated, containing 1st & 2nd level dir. in backup.
# 2023_05_25 backup: v2.34 ReaR USB bootable image is now produce at every execution.
# 2024_01_18 backup: v2.35 Minor improvements & update sadmin section to v1.56.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x



# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='2.35'                                     # Script version number
export SADM_PDESC="Produce a ReaR bootable iso and a restorable backup on a NFS server"
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=400                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------







#===================================================================================================
# Scripts Variables
#===================================================================================================
export NFS_MOUNT="/mnt/rear_$$"                                         # Temp. NFS Backup MountPoint
export REAR_DATE=$(date "+%C%y_%m_%d")                                  # Date Format 2024_05_27
export REAR_CFGFILE="/etc/rear/site.conf"                               # ReaR Site Config file
export REAR_TMP="${SADMIN}/tmp/rear_site.tmp$$"                         # New ReaR site.conf tmp file
#export REAR_DIR="${NFS_MOUNT}/${SADM_HOSTNAME}/${REAR_DATE}"           # Rear Host Backup Dir.
export REAR_DIR="${NFS_MOUNT}/${SADM_HOSTNAME}"                         # Rear Host Backup Dir.
export REAR_NAME="${REAR_DIR}/rear_${SADM_HOSTNAME}"                    # ISO & Backup Prefix Name

# File generated by each backup
export REAR_CUR_ISO="${REAR_NAME}.iso"                                  # CD ISO Boot Image
export REAR_USB_ISO="${REAR_NAME}_usb.iso"                              # USB ISO Boot Image
export REAR_ISO_LOG="${REAR_DIR}/rear-${SADM_HOSTNAME}.log"             # CD ISO creation log
export REAR_CUR_TGZ="${REAR_NAME}.tar.gz"                               # Rear Host Backup File Name
export REAR_CUR_LST="${REAR_CUR_TGZ}.lst"                               # tar -tvzf of ReaR file
export REAR_CUR_LOG="${REAR_NAME}.log"                                  # Rear Host Backup log file
export REAR_README="${REAR_DIR}/README"                                 # Rear Backup README
export REAR_VERSION="${REAR_DIR}/VERSION"                               # Rear Version file




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
# Create the final /etc/rear/site.conf file
# --------------------------------------------------------------------------------------------------
update_url_in_rear_site_conf()
{

    # Ensure that this temporary file doesn't exist,
    if [ -f "$REAR_TMP" ] ; then rm -f $REAR_TMP >/dev/null 2>&1 ; fi
    
    # Loop through /etc/rear/site.conf and update the BACKUP_URL Line.
    while read wline
    do
        echo $wline | grep -i "^BACKUP_URL" >/dev/null 2>&1             # Line begin "BACKUP_URL"
        if [ $? -eq 0 ]                                                 # If BACKUP_URL line
        then sadm_write "Update backup destination in $REAR_CFGFILE with value from sadmin.cfg.\n"
            echo "BACKUP_URL=\"nfs://${SADM_REAR_NFS_SERVER}${SADM_REAR_NFS_MOUNT_POINT}\"" >> $REAR_TMP
            sadm_write "  - BACKUP_URL=\"nfs://${SADM_REAR_NFS_SERVER}${SADM_REAR_NFS_MOUNT_POINT}\"\n"
        else echo "$wline" >> $REAR_TMP                                 # Output normal line in TMP
        fi
    done < $REAR_CFGFILE                                                # Read /etc/rear/site.conf
    
    # Copy New site.conf ($REAR_TMP) to the official one ($REAR_CFGFILE).
    sadm_write "  - Update actual $REAR_CFGFILE "
    cp $REAR_TMP $REAR_CFGFILE                                          # Replace ReaR site.conf
    if [ $? -ne 0 ]
    then sadm_write "[ ERROR ] replacing actual ${REAR_CFGFILE}.\n"
        sadm_write_err "***** Rear Backup Abort *****"
        return 1                                                        # Back to caller with error
    else sadm_write "[ OK ]\n"
    fi
}



# --------------------------------------------------------------------------------------------------
# Process Operating System received in parameter (aix/linux,darwin)
# --------------------------------------------------------------------------------------------------
create_etc_rear_site_conf()
{

# if /etc/rear/site.conf is readable, then return to caller.
    if [ -r "$REAR_CFGFILE" ] 
    then sadm_write_log "The $REAR_CFGFILE exist, no need to create it." 
         return 0 
    else sadm_write_log "The $REAR_CFGFILE isn't present."
         sadm_write_log "Creating a ReaR default site file."
    fi
    
# Start creating the header of ReaR site.conf file into a temp. file for now.
    echo  "# Create a bootable ISO9660 image on disk as rear_${SADM_HOSTNAME}.iso" > $REAR_TMP
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
    echo  "# ONLY_INCLUDE_VG=( 'rootvg'  'vg00' 'vg01' ) " >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# Exclude Volume Group (and filesystem they include)." >> $REAR_TMP
    echo  "# EXCLUDE_VG & EXCLUDE_MOUNTPOINTS get automatically populated. " >> $REAR_TMP
    echo  "# EXCLUDE_VG=( 'datavg' ) " >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# Exclude filesystems by specifying their mountpoints. " >> $REAR_TMP
    echo  "# Added automatically to the $BACKUP_PROG_EXCLUDE array. " >> $REAR_TMP
    echo  "# EXCLUDE_MOUNTPOINTS=( '/data' 'vm' )" >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# BACKUP_PROG_EXCLUDE is an array of strings that get written into a " >> $REAR_TMP
    echo  "# backup-exclude.txt file used in 'tar -X backup-exclude.txt' to get " >> $REAR_TMP
    echo  "# things excluded from the backup. " >> $REAR_TMP
    echo  "# Proper quoting of the BACKUP_PROG_EXCLUDE array members is crucial" >> $REAR_TMP
    echo  "# to avoid bash expansions. Example :" >> $REAR_TMP
    echo  "# BACKUP_PROG_EXCLUDE=( "${BACKUP_PROG_EXCLUDE[@]}" '/tmp/*' '/proc/*' '/sys/*' '/dev/*' )" >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# Exclude components from being backed up,recreation information is active" >> $REAR_TMP
    echo  "# EXCLUDE_BACKUP=()" >> $REAR_TMP
    echo  "" >> $REAR_TMP
    
    echo  "# Exclude components during the backup restore phase." >> $REAR_TMP
    echo  "# Only used to exclude files from the restore. " >> $REAR_TMP
    echo  "# EXCLUDE_RESTORE=()" >> $REAR_TMP
    echo  "" >> $REAR_TMP
    cat $REAR_TMP | tr -d '\r' > $REAR_CFGFILE
}




# --------------------------------------------------------------------------------------------------
# Rear Backup Preparation
#   - Test if rear executable exist, if not return error to caller.
#   - Test existence of ReaR configuration file, if not return error to caller.
#   - Test if local mount point exist, if not create it.
#   - Mount the NFS drive over the local mount point, if don't work return error to caller.
#   - If hostname directory doesn't exist in NFS directory, create it.
#   - Try to write test file to NFS mount point, if don't work return error to caller.
# --------------------------------------------------------------------------------------------------
rear_preparation()
{
    sadm_write_log "-----"
    sadm_write_log "Starting ReaR Preparation"
    sadm_write_log "-----"
    sadm_write_log " "

    # Set the REAR env. variable to 'rear' full path.
    ${SADM_WHICH} rear >/dev/null 2>&1                                  # rear command is found ?
    if [ $? -eq 0 ]                                                     # Yes it is on system
    then export REAR=`${SADM_WHICH} rear`                               # Store Path of command
    else sadm_write_err "[ ERROR ] The 'rear' command is missing, job aborted."
        return 1                                                        # Return Error to Caller
    fi
    
    # Under DEBUG mode run the command 'rear dump' 
    if [ "$SADM_DEBUG" -gt 4 ]
    then sadm_write_log " "
        sadm_write_log "Below is the result of the 'rear dump' command : "
        sadm_write_log " " ; $REAR dump ; sadm_write_log " " ; sadm_write_log " "
    fi 

    # If Rear configuration file '/etc/rear/site.conf' doesn't exist, create a default one.
    if [ ! -r "$REAR_CFGFILE" ] ; then create_etc_rear_site_conf ; fi   # ReaR Site config exist?

    # We also need to update backup destination with the values specified in '$SADMIN/cfg/sadmin.cfg'
    #   - SADM_REAR_NFS_SERVER      = NFS Server hostname where backup is stored
    #   - SADM_REAR_NFS_MOUNT_POINT = NFS Mount point on the nfs server
    update_url_in_rear_site_conf                                        # Go update site.conf file 
    
    # Make sure nfs local mount point exist.
    if [ ! -d ${NFS_MOUNT} ]
    then sadm_write_log " "
        sadm_write_log "Create local mount point directory '${NFS_MOUNT}'."
        mkdir ${NFS_MOUNT} ; chmod 775 ${NFS_MOUNT}
    fi
    
    # Mount the NFS Mount point
    sadm_write_log "Mount NFS share on $SADM_REAR_NFS_SERVER"
    umount ${NFS_MOUNT} > /dev/null 2>&1                                # Make sure it's unmounted.
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
    
# Make sure Directory for the host exist on NFS Server.
    if [ ! -d  "${NFS_MOUNT}/${SADM_HOSTNAME}" ]
    then mkdir ${NFS_MOUNT}/${SADM_HOSTNAME}
        if [ $? -ne 0 ]
        then sadm_write_err "[ ERROR ] Creating directory ${NFS_MOUNT}/${SADM_HOSTNAME}"
            return 1
        fi
    fi
    
# Write test to NFS Mount Point.
    sadm_write "Write test to NFS mount ... "                           # Feed user and log
    TEST_FILE="${NFS_MOUNT}/${SADM_HOSTNAME}/rear_pid_$SADM_TPID.txt"   # Create test file name
    touch ${TEST_FILE} >> $SADM_LOG 2>&1                                # Create empty test file
    if [ $? -ne 0 ]                                                     # If error on chmod command
    then sadm_write_err "[ ERROR ] Can't write test file ${TEST_FILE}."
        return 1                                                    # Back to caller with error
    fi
    sadm_write "[ OK ]\n"                                             # Feed user and log
    rm -f ${TEST_FILE} >> $SADM_LOG 2>&1                                # Delete the test file
    
    sadm_write_log " "
    sadm_write_log "New CD/DVD ISO will be created under the name of ${REAR_CUR_ISO}."
    sadm_write_log "New USB ISO will be created under the name of ${REAR_USB_ISO}."
    sadm_write_log "New Backup will be created under the name of ${REAR_CUR_TGZ}."
    sadm_write_log " "


# Show content of rear directory just before starting the backup.
    sadm_write_log " "
    sadm_write_log "Current content of 'ReaR' backup directory for ${SADM_HOSTNAME} : "
    ls -ltrh ${REAR_DIR} | while read wline ; do sadm_write "${wline}\n"; done


# Move previous backup in one directory (name of dir is YYYY_MM_DD_HH_MM_SS)
    if [ -r "$REAR_CUR_ISO" ]
    then prev_date=`stat --printf='%y\n' $REAR_CUR_ISO |awk '{ print $1 }' |tr '-' '_'`
         prev_time=`stat --printf='%y\n' $REAR_CUR_ISO |awk '{ print $2 }' |awk -F\. '{ print $1 }'| tr ':' '_'`
         prev_dir="${REAR_DIR}/${prev_date}_${prev_time}"
         mkdir -p ${prev_dir}
         sadm_write_log " "
         sadm_write_log "Moving previous backup into $prev_dir"
         mv $REAR_CUR_ISO ${prev_dir}/
         if [ -r "$REAR_USB_ISO" ] ; then mv $REAR_USB_ISO ${prev_dir}/ ; fi
         if [ -r "$REAR_ISO_LOG" ] ; then mv $REAR_ISO_LOG ${prev_dir}/ ; fi
         if [ -r "$REAR_CUR_TGZ" ] ; then mv $REAR_CUR_TGZ ${prev_dir}/ ; fi
         if [ -r "$REAR_CUR_LST" ] ; then mv $REAR_CUR_LST ${prev_dir}/ ; fi
         if [ -r "$REAR_CUR_LOG" ] ; then mv $REAR_CUR_LOG ${prev_dir}/ ; fi
         if [ -r "$REAR_README"  ] ; then mv $REAR_README  ${prev_dir}/ ; fi
         if [ -r "$REAR_VERSION" ] ; then mv $REAR_VERSION ${prev_dir}/ ; fi
    fi 
    
# Show the content og /etc/rear/site.conf before starting the ReaR backup
    sadm_write_log " "
    sadm_write_log "-----"
    sadm_write_log "Current content of 'ReaR' site configuration file ${REAR_CFGFILE} :"
    grep -Ev "^$|^#" $REAR_CFGFILE | while read wline ; do sadm_write_log "${wline}"; done
    sadm_write_log "-----"
    #sadm_write_log " "
    sadm_write_log "[ SUCCESS ] End of 'ReaR' preparation."
    sadm_write_log "-----"
    sadm_write_log " "
    return 0
}





# Make sure we have the correct number of copies
# --------------------------------------------------------------------------------------------------
rear_housekeeping()
{
    FNC_ERROR=0                                                         # Cleanup Error Default 0
    sadm_write_log " "
    sadm_write_log " "
    sadm_write_log "-----"
    sadm_write_log "Perform ReaR housekeeping : "
    sadm_write_log "-----"

# Create USB Bootable image (If isohybrid command is installed)
    if command -v isohybrid > /dev/null
        then if [ -r "$REAR_CUR_ISO" ] 
                then cp ${REAR_CUR_ISO} ${REAR_USB_ISO} 
                     sadm_write_log "Creating USB bootable iso image" 
                     isohybrid ${REAR_USB_ISO} 
                     if [ $? -ne 0 ]
                        then sadm_write_err "[ ERROR ] Running 'isohybrid ${REAR_USB_ISO}'."
                             FNC_ERROR=1
                        else sadm_write_log "[ OK ] USB Boot image created '${REAR_USB_ISO}'."
                     fi
             fi
        else sadm_write_err "[ WARNING ] USB Boot image not created."
             sadm_write_err "The command 'isohybrid' not installed on '${SADM_HOSTNAME}'."
             sadm_write_err " - On debian,ubuntu,Mint use     : 'sudo apt install syslinux-utils'"
             sadm_write_err " - On fedora,rhel,alma,rocky use : 'sudo dnf install syslinux'" 
    fi 


# All generated rear files can be read syncing scripts.0
    sadm_write_log " " 
    if [ -r "$REAR_CUR_ISO" ] ; then chmod -v 664 ${REAR_CUR_ISO} ; fi
    if [ -r "$REAR_USB_ISO" ] ; then chmod -v 664 ${REAR_USB_ISO} ; fi
    if [ -r "$REAR_ISO_LOG" ] ; then chmod -v 664 ${REAR_ISO_LOG} ; fi
    if [ -r "$REAR_CUR_TGZ" ] ; then chmod -v 664 ${REAR_CUR_TGZ} ; fi
    if [ -r "$REAR_CUR_LST" ] ; then chmod -v 664 ${REAR_CUR_LST} ; fi
    if [ -r "$REAR_README" ]  ; then chmod -v 664 ${REAR_README}  ; fi
    if [ -r "$REAR_VERSION" ] ; then chmod -v 664 ${REAR_VERSION} ; fi
    if [ -r "$REAR_CUR_LOG" ] ; then chmod -v 664 ${REAR_CUR_LOG} ; fi

    sadm_write_log " "
    sadm_write_log "Information coming from SADMIN configuration file ${SADM_CFG_FILE} :"
    sadm_write_log " - Always keep last $SADM_REAR_BACKUP_TO_KEEP ReaR backup on '${SADM_REAR_NFS_SERVER}'."
    sadm_write_log " "
    sadm_write_log "List of ReaR backup directory before housekeeping for ${SADM_HOSTNAME}"
    ls -ltrh ${REAR_DIR} | while read wline ; do sadm_write "${wline}\n"; done
    
# Eliminate old backup structure 
    find ${REAR_DIR} -type f -name "rear_${SADM_HOSTNAME}_20*" -exec rm -f {} \;

# Get previous backup directory name and size
    sadm_write_log " "
    ls --color=never -1trdh  ${REAR_DIR}/20* >/dev/null 2>&1            # Check Prv Backup dir exist
    if [ $? -eq 0 ]                                                     # If Prv Backup dir exist
        then prev_backup_dir=$(ls --color=never -1trdh ${REAR_DIR}/20* | tail -1) 
             prev_backup_size=`du -h $prev_backup_dir | awk '{print $1}'`
        else prev_backup_dir=""
             prev_backup_size=0
    fi 
    sadm_write_log "Previous backup size: $prev_backup_size"

# Current backup size 
    ls -l ${REAR_DIR}/rear* >/dev/null 2>&1
    if [ $? -eq 0 ] 
        then cur_backup_size=`du -hac ${REAR_DIR}/rear* | awk '{print $1}' | tail -1`
        else cur_backup_size=0
    fi
    sadm_write_log "Current backup size: $cur_backup_size"

# Total Rear backup directory size
    rear_total_backup_size=`du -ahc ${REAR_DIR} | tail -1 | awk '{ print $1 }' `
    sadm_write_log "$rear_total_backup_size - Total ReaR backup directory size for ${SADM_HOSTNAME}" 

# Calculate number of backup we have for this system
    if [ -r $REAR_CUR_TGZ ]                                             # If current .tar.gz exist
        then nb_backup=1                                                # Then nb backup is 1
        else nb_backup=0                                                # Else nb backup is 0
    fi 
    nb_date_dir=$(find ${REAR_DIR} -type d -name "2*" | wc -l)        # Nb of directories
    nb_backup=$((nb_backup + nb_date_dir))                           # Total nb of ReaR Backup

# Delete backup that are over the number we want to keep.
    nb_dir_to_keep=$((SADM_REAR_BACKUP_TO_KEEP - 1)) 
    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write_log "Number of dir. to keep: $nb_dir_to_keep"
             sadm_write_log "nb_dir_to_keep: $nb_dir_to_keep - nb_date_dir: $nb_date_dir"
    fi 
    if [ $nb_date_dir -gt $nb_dir_to_keep ]
        then nb_to_delete=$((nb_date_dir - nb_dir_to_keep)) 
             sadm_write_log " "
             sadm_write_log "Number of backup directory to delete: $nb_to_delete"
             sadm_write_log "Backup directories that will be removed : "
             /bin/ls -1td ${REAR_DIR}/20* | sort -r | sed 1,${nb_dir_to_keep}d | while read wline ; do sadm_write "${wline}\n"; done
             /bin/ls -1td ${REAR_DIR}/20* | sort -r | sed 1,${nb_dir_to_keep}d | xargs rm -fr >> $SADM_LOG 2>&1
             if [ $? -ne 0 ]
             then sadm_write_err "Problem deleting backup directory [ ERROR ]"
                  FNC_ERROR=1
             else sadm_write_log "Previous backup directory removed [ OK ]"
             fi
        else sadm_write_log " "
             sadm_write_log "No need to remove any directories."
    fi

# List 10 biggest files include in the tgz file
    sadm_write_log " "
    sadm_write_log "Building a list of the 10 biggest files included in the ReaR backup file."
    tar -tzvf $REAR_CUR_TGZ | sort -k3 -rn | nl | head | tee -a  ${SADM_LOG}  
    sadm_write_log " "

# List level 1 and 2 of the directories included in the ReaR tgz file
    sadm_write_log " "
    sadm_write_log "Creating a table of content (-tvzf) of ReaR backup '$REAR_CUR_LST'".
    #tar --exclude '*/*/*/*/*' -tvzf $REAR_CUR_TGZ | grep -Ex '([^/]+/){3}' >$REAR_CUR_LST
    tar -tvzf $REAR_CUR_TGZ >$REAR_CUR_LST
    sadm_write_log " "

# List Backup Directory to user after cleanup
    sadm_write_log " "
    sadm_write_log "List of ReaR backup directory after housekeeping for ${SADM_HOSTNAME}"
    ls -ltrh ${REAR_DIR} | while read wline ; do sadm_write "${wline}\n"; done
    
# Ok Cleanup up is finish - Unmount the NFS
    sadm_write_log " "
    sadm_write_log "Unmounting NFS mount directory ${NFS_MOUNT} ..."
    sadm_write "umount ${NFS_MOUNT} "
    umount ${NFS_MOUNT} >> $SADM_LOG 2>&1
    if [ $? -ne 0 ]
    then sadm_write_err "[ ERROR ] Problem unmounting ${NFS_MOUNT}.\n"
        FNC_ERROR=1
    else rmdir ${NFS_MOUNT} > /dev/null 2>&1
        sadm_write "[ OK ]\n"
    fi
    
# Remove NFS mount point.
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
    sadm_write_log "-----"
    sadm_write_log "[ SUCCESS ] End of 'ReaR' backup housekeeping"
    sadm_write_log "-----"
    return $FNC_ERROR
}





# --------------------------------------------------------------------------------------------------
#                     Create the Rescue ISO and a tar file of the server
# --------------------------------------------------------------------------------------------------
create_backup()
{

# Feed user and log, the what we are about to do.
    sadm_write_log " "
    sadm_write_log "-----"
    sadm_write_log "Creating 'ReaR' backup for system '${SADM_HOSTNAME}' : "
    sadm_write_log "-----"
    sadm_write_log "$REAR mkbackup -v"
    
# Create the Backup TGZ file on the NFS Server
    $REAR mkbackup -v >> $SADM_LOG 2>&1                                 # Produce Rear Backup for DR
    RC=$?                                                               # Save Command return code.
    sadm_write_log "ReaR backup exit code : ${RC}"                      # Show user backup exit code
    if [ $RC -ne 0 ]
    then sadm_write_err "[ ERROR ] See error message in ${SADM_LOG} & ${SADM_ELOG}."
         sadm_write_err "Also look into ReaR log file /var/log/rear/rear-${SADM_HOSTNAME}.log." 
         sadm_write_err "***** Rear Backup completed with Error - Aborting Script *****"
         sadm_write_log "Unmount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT}"
         umount  ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} > /dev/null 2>&1
         return 1                                                        # Back to caller with error
    fi 
    sadm_write_log "More info in the log ${REAR_CUR_LOG}."
    sadm_write_log "[ SUCCESS ] Rear Backup completed."
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
               num=$(echo "$SADM_DEBUG" |grep -E "^\-?[0-9]?\.?[0-9]+$") # Valid if Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nInvalid debug level.\n"                # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug level set to ${SADM_DEBUG}.\n"             # Display Debug Level
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
    #
    rear_preparation                                                    # Mount Point Work ?  ...
    if [ $? -eq 0 ]                                                     # If preparation went OK
    then create_backup                                                  # Do the ReaR ISO and Backup
         SADM_EXIT_CODE=$?                                              # If Error Making Backup
    fi 
    #
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # Everything ok so far
    then rear_housekeeping                                              # Remove old backup & umount
        if [ $? -ne 0 ]                                                 # If Error in housekeeping
        then SADM_EXIT_CODE=1                                           # If Error Exit code = 1
        else SADM_EXIT_CODE=0                                           # No Error Exit code = 0
        fi
    fi
    if [ -f "$REAR_TMP" ] ; then rm -f $REAR_TMP >/dev/null 2>&1 ; fi   # Remove Temp File

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
