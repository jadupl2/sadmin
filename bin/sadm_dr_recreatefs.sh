#! /usr/bin/env bash
#===================================================================================================
# Shellscript   :  sadm_dr_fs_recreate.sh - 
# Description   :  On Linux - Recreate all filesystems of the selected volume group
#                  On Aix   - Recreate all Filesystems of the selected volume group
#                  On Linux environnement the VG MUST create before running this script.
#                  On Aix the VG is Create and the filesystem within it are created.
# Version       :  1.5
# Author        :  Jacques Duplessis (jacques.duplessis@sadmin.ca)
# Date          :  2010-10-09
# Requires      :  bash shell or sh under Aix - lvm installed (on Linux)
# Category      :  Disaster recovery tools 
#===================================================================================================
# Description
# -----
# Linux Notes
#    - This script recreate the filesystem of the system with the proper size and protection. 
#    - Run this script and specify the Volume Group you want to recreate the filesystems.
#    - This script read it input from the file "HOSTNAME_fs_save_info.dat". 
#    - The file "HOSTNAME_fs_save_info.prev" contains data from previous day could be used, if you
#      rename it to "HOSTNAME_fs_save_info.dat".
#    - The necessary Volume Group got to created prior to running this script.
#
# At Disaster Recovery Site, You just need to create the volume group, run this script to 
# recreate the empties filesystems as they were at the Office and then restore data to these
# filesystems.
# 
# -----
# Aix Notes
#
#    - This file "$SADMIN_BASE_DIR/dat/dr/HOSTNAME_VGNAME.savevg" is the restore input filename 
#      (savevg backup), that will be produce every night by running the script 
#      "sadm_dr_fs_save_info.sh" (should be in cron) normally located in /sadmin/bin. 
#      File is in backup/restore format.
#            root@aixb50(/sadmin/dat/dr)# file aixb50_datavg.savevg
#                     aixb50_datavg.savevg: backup/restore format file
#  
#    - The restore of the VG will be created on the disks specified in
#      "$SADMIN_BASE_DIR/HOSTNAME_VGNAME_restvg_disks.txt" file. This file contain the disks 
#      that the VG was using last night and was created by the script "sadm_dr_fs_save_info.sh.
#      This file can be modify prior to running this script. 
#      If you want te recreate the VG on different disks then you should modify it.
#
#
#===================================================================================================
#
# 2016_11_02    v2.0 Correct problem in LVM Version detection in Linux(Affect Only RedHat/CentOS V3)
#                   Support for AIX was added 
#                   - Using savevg to save the structure of the VG
#                   - THe Filesystem (and Raw) within VG are recreated automatically,with proper perm
#                   - You need to restore the content of the filesystems from your usual backup.
# 2018_06_04    v2.1 Correction for new Library
#@2018_12_08    v2.2 Fix bug with Debugging Level. 
#@2020_04_06 Update: v2.3 Replace function sadm_writelog() with NL incl. by sadm_write() No NL Incl.
#            
#
#===================================================================================================
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "\n'SADMIN' Environment variable was temporarily set to ${SADMIN}."
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='2.3'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=35                          # When script end Trim rch file to 35 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================








# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
DRFILE=$SADM_DR_DIR/$(sadm_get_hostname)_fs_save_info.dat   ;export DRFILE  # Output file of program
DEBUG_LEVEL=0                                   ; export DEBUG_LEVEL    # DEBUG increase Verbose 
STDERR="${SADM_TMP_DIR}/stderr.$$"              ; export STDERR         # Output of Standard Error
STDOUT="${SADM_TMP_DIR}/stdout.$$"              ; export STDOUT         # Output of Standard Output
FSTAB=/etc/fstab                                ; export FSTAB          # Filesystem Table Name
XFS_ENABLE="N"                                  ; export XFS_ENABLE     # Disable Unless cmd are present

# Global Variables Logical Volume Information
# -------------------------------------------------------------------------------------
LVNAME=""                                       ; export LVNAME         # Logical Volume Name
LVSIZE=""                                       ; export LVSIZE         # Logical Volume Size
VGNAME=""                                       ; export VGNAME         # Volume Group Name
LVTYPE=""                                       ; export LVTYPE         # LV Type ext3 swap xfs
LVMOUNT=""                                      ; export LVMOUNT        # LV Mount point
LVOWNER=""                                      ; export LVOWNER        # LV Mount point owner
LVGROUP=""                                      ; export LVGROUP        # LV Mount point group
LVPROT=""                                       ; export LVPROT         # LV Mount point protection

# Variables Used by Aix
RESTVG="restvg -q -fVGDATAFILE_PLACE_HOLDER"    ; export RESTVG         # Cmnd to restore VG in Aix
VG=""                                           ; export VG             # Name of VG to Restore
DISK_LIST=""                                    ; export DISK_LIST      # Restore Destination disks



# --------------------------------------------------------------------------------------------------
#     - Set command path used in the script (Some path are different on some RHEL Version)
#     - Check if Input exist and is readable
# --------------------------------------------------------------------------------------------------
#
linux_setup()
{
    sadm_write "Validating Program Requirements before proceeding ...\n\n"
    sadm_write " "

    # Check if Input File exist
    if [ ! -r "$DRFILE" ]
        then sadm_write "$SADM_ERROR The input file $DRFILE does not exist !\n"
             sadm_write "Process aborted.\n"
             return 1
    fi

    if which which >/dev/null 2>&1   
       then sadm_write "\n"
       else sadm_write "The command 'which' is not installed - Install it and rerun this script.\n"
            return 1
    fi

    LVCREATE=`which lvcreate >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then LVCREATE=`which lvcreate`
        else sadm_write "$SADM_ERROR The command 'lvcreate' was not found.\n" ; return 1
    fi
    export LVCREATE  
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND LVCREATE  : $LVCREATE \n" ; fi


    TUNE2FS=`which tune2fs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then TUNE2FS=`which tune2fs`
        else sadm_write "$SADM_ERROR The command 'tune2fs' was not found.\n" ; return 1
    fi
    export TUNE2FS   
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND TUNE2FS   : $TUNE2FS \n" ; fi


    MKFS_EXT2=`which mkfs.ext2 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT2=`which mkfs.ext2`
        else sadm_write "$SADM_ERROR The command 'mkfs.ext2' was not found.\n" ; return 1
    fi
    export MKFS_EXT2  
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND MKFS_EXT2 : $MKFS_EXT2 \n" ; fi


    MKFS_EXT3=`which mkfs.ext3 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT3=`which mkfs.ext3`
        else sadm_write "$SADM_ERROR The command 'mkfs.ext3' was not found.\n" ; return 1
    fi
    export MKFS_EXT3  
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND MKFS_EXT3 : $MKFS_EXT3 \n" ; fi


    MKFS_EXT4=`which mkfs.ext4 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT4=`which mkfs.ext4`
        else sadm_write "$SADM_ERROR The command 'mkfs.ext4' was not found.\n" 
             return 1
    fi
    export MKFS_EXT4 
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND MKFS_EXT4 : $MKFS_EXT4 \n" ; fi


    MKFS_XFS=`which mkfs.xfs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_XFS=`which mkfs.xfs`
             XFS_ENABLE="Y"
        else MKFS_XFS=""
             XFS_ENABLE="N"
    fi
    export MKFS_XFS  
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND MKFS_XFS  : $MKFS_XFS \n" ; fi


    FSCK_EXT2=`which fsck.ext2 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT2=`which fsck.ext2`
        else sadm_write "$SADM_ERROR The command 'fsck.ext2' was not found.\n" ; return 1
    fi
    export FSCK_EXT2  
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND FSCK_EXT2 : $FSCK_EXT2 \n" ; fi


    FSCK_EXT3=`which fsck.ext3 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT3=`which fsck.ext3`
        else sadm_write "$SADM_ERROR The command 'fsck.ext3' was not found.\n" ; return 1
    fi
    export FSCK_EXT3  
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND FSCK_EXT3 : $FSCK_EXT3 \n" ; fi


    FSCK_EXT4=`which fsck.ext4 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT4=`which fsck.ext4`
        else sadm_write "$SADM_ERROR The command 'fsck.ext4' was not found.\n" ; return 1
    fi
    export FSCK_EXT4  
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND FSCK_EXT4 : $FSCK_EXT4 \n" ; fi


    FSCK_XFS=`which fsck.xfs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_XFS=`which fsck.xfs`
             XFS_ENABLE="Y"
        else FSCK_XFS=""
             XFS_ENABLE="N"
    fi
    export FSCK_XFS   
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND FSCK_XFS  : $FSCK_XFS\n" ; fi


    MKDIR=`which mkdir >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKDIR=`which mkdir`
        else sadm_write "$SADM_ERROR The command 'mkdir' was not found\n" ; return 1
    fi
    export MKDIR      
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND MKDIR     : $MKDIR \n" ; fi


    MOUNT=`which mount >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MOUNT=`which mount`
        else sadm_write "$SADM_ERROR The command 'mount' was not found\n" ; return 1
    fi
    export MOUNT      
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND MOUNT \n     : $MOUNT" ; fi


    CHMOD=`which chmod >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then CHMOD=`which chmod`
        else sadm_write "$SADM_ERROR The command 'chmod' was not found\n" ; return 1
    fi
    export CHMOD      
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND CHMOD     : $CHMOD \n" ; fi


    CHOWN=`which chown >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then CHOWN=`which chown`
        else sadm_write "$SADM_ERROR The command 'chown' was not found.\n" ; return 1
    fi
    export CHOWN      
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND CHOWN     : $CHOWN \n" ; fi

    
    MKSWAP=`which mkswap >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKSWAP=`which mkswap`
        else sadm_write "$SADM_ERROR The command 'mkswap' was not found.\n" ; return 1
    fi
    export MKSWAP      
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND MKSWAP    : $MKSWAP \n" ; fi
    
    
    SWAPON=`which swapon >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then SWAPON=`which swapon`
        else sadm_write "$SADM_ERROR The command 'swapon' was not found.\n" ; return 1
    fi
    export SWAPON      
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_write "COMMAND SWAPON    : $SWAPON \n" ; fi

    return 0
}




# --------------------------------------------------------------------------------------------------
#          Determine if LVM is installed and what version of lvm is installed (1 or 2)
# --------------------------------------------------------------------------------------------------
#
check_lvm_version()
{
    LVMVER=0                                                            # Assume lvm not install
    sadm_write "Currently verifying the LVM version installed on system.\n"

    # Check if LVM Version 1 is installed
    rpm -qa | grep '^lvm-1' > /dev/null 2>&1                            # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=1 ; fi                                # Found LVM V1

    # Check if LVM Version 2 is installed
    rpm -qa | grep '^lvm2' > /dev/null 2>&1                             # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=2 ; fi                                # Found LVM V2

    # If LVM Not Installed
    if [ $LVMVER -eq 0 ]                                                # lvm wasn't found on server
        then sadm_write "The rpm 'lvm' or 'lvm2' is not installed.\n"   # Advise user no lvm package
             sadm_write "No use in running this script - Script Aborted\n" # No LVM - No Script
    fi
    return $LVMVER                                                      # Return LVM Version
}






# --------------------------------------------------------------------------------------------------
#               Function called when an error occured while creating a filesystem
# --------------------------------------------------------------------------------------------------
report_error()
{
     WMESS=$1
     sadm_write "$WMESS \n"
     sadm_write  "\a\aPress [ENTER] to continue - CTRL-C to Abort\c\n"
     read dummy
}






# -------------------------------------------------------------------------------------
#   Create filesystem Based on content of all LVXXXXX Variables
# -------------------------------------------------------------------------------------
recreate_filesystem()
{

    # CHECK IF THE LV ALREADY EXIST BY RUNNING A LVSCAN COMMAND ------------------------------------
    lvscan |grep "'/dev/${VGNAME}/${LVNAME}'" >/dev/null 2>&1  # Parse LV in lvscan output
    RC=$?                                                      # Save Search result
    if [ $RC -eq 0 ]                                                    # If LV already exist
        then report_error "Logical Volume /dev/${VGNAME}/${LVNAME} already exist, Skipping this one"
             return 1                                                   # Exit function
    fi
    
    # IF MOUNT POINT ALREADY EXIST IN /ETC/FSTAB , THEN REPORT ERROR AND EXIT FUNCTIONS ------------
    grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' | grep "^${LVMOUNT} ">/dev/null 2>&1
    if [ $? -eq 0 ]
       then report_error "The mount point $LVMOUNT already exist in $FSTAB"
            return 1
    fi

    
    # CREATE THE LOGICAL VOLUME - IF ERROR DETECTED THEN REPORT ERROR & EXIT FUNCTION --------------
    sadm_write "Running : ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME}\n"
    ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME} 1> $STDOUT 2> $STDERR
    if [ $? -ne 0 ] ; then report_error "Error with lvcreate\n `cat $STDERR`" ; return 1 ;  fi

    
    # CREATE FILESYSTEM ON THE LOGICAL VOLUME ------------------------------------------------------
    if [ "$LVTYPE" = "ext2" ]
        then sadm_write "Running : ${MKFS_EXT2} -b4096 /dev/${VGNAME}/${LVNAME}\n"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext2 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "ext3" ]
        then sadm_write "Running : ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME}\n"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext3 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_write "Running : ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME}\n"
             ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext4 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then if [ "$XFS_ENABLE" = "Y" ]
                then sadm_write "Running : ${MKFS_XFS} -b size=4k  /dev/${VGNAME}/${LVNAME}\n"
                     ${MKFS_XFS} -b size=4k /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
                     if [ $? -ne 0 ] ; then report_error "mkfs.xfs error \n `cat $STDERR`" ;return 1 ;fi
                else report_error "Can't create XFS Filesystem - Install xfsprogs\n `cat $STDERR`" ;return 1 
             fi 
    fi
    if [ "$LVTYPE" = "swap" ]
        then sadm_write "Running : ${MKSWAP} -c /dev/${VGNAME}/${LVNAME}\n"
             ${MKSWAP} -c /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkswap error \n `cat $STDERR`" ;return 1 ;fi
    fi 
        
        
    # DO A FILESYSTEM CHECK - JUST TO BE SURE FILESYSTEM IS OK TO USE. -----------------------------
    if [ "$LVTYPE" = "ext2" ]
        then sadm_write "Running : ${FSCK_EXT2} -f /dev/${VGNAME}/${LVNAME}\n"
             ${FSCK_EXT2} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext2 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "ext3" ]
        then sadm_write "Running : ${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME}\n"
             ${FSCK_EXT3} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext3 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_write "Running : ${FSCK_EXT4} -f /dev/${VGNAME}/${LVNAME}\n"
             ${FSCK_EXT4} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext4 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then if [ "$XFS_ENABLE" = "Y" ]
                then sadm_write "Running : ${FSCK_XFS} -f /dev/${VGNAME}/${LVNAME}\n"
                     ${FSCK_XFS} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
                     if [ $? -ne 0 ] ; then report_error "fsck.xfs error\n `cat $STDERR`" ; return 1 ;  fi
                else report_error "Can't create XFS Filesystem - Install xfsprogs\n `cat $STDERR`" ;return 1
             fi 
    fi
    
    
    # SET FSCK MAX-COUNT TO 0 & FSCK MAXIMAL TIME BETWEEN FSCK TO 0  ON EXT? FILESYSTEM ------------
    # PREVENT VERY LONG FSCK WHEN PRODUCTION SYSTEM REBOOT AFTER A LONG TIME.
    if [ "$LVTYPE" = "ext2" ] || [ "$LVTYPE" = "ext3" ] || [ "$LVTYPE" = "ext4" ]  
        then sadm_write "Running : ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME}\n"
             ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "tune2fs error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    
    
    # CREATE THE MOUNT POINT DIRECTORY - FOR SWAP SPACE ACTIVATE IT --------------------------------
    if [ "$LVTYPE" != "swap" ]
        then sadm_write "Running : ${MKDIR} -p ${LVMOUNT}\n"
             ${MKDIR} -p ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkdir error\n `cat $STDERR`" ; return 1 ;  fi
        else sadm_write "Running : $SWAPON /dev/${VGNAME}/${LVNAME}\n"
             $SWAPON /dev/${VGNAME}/${LVNAME}
             if [ $? -ne 0 ] ; then report_error "swapon error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    
    # ADD MOUNT POINT IN /ETC/FSTAB ----------------------------------------------------------------
    sadm_write "Running : Adding entry in $FSTAB \n"
    WDEV="/dev/mapper/${VGNAME}-${LVNAME}"
    echo "$WDEV ${LVMOUNT} $LVTYPE" |awk '{ printf "%-30s %-30s %-4s %s\n",$1,$2,$3,"defaults 1 2"}'>>$FSTAB
    
    
    # IF NOT A SWAP FILE TO CREATE - CREATE MOUNT POINT AND ISSUE CHMOD AND CHOWN COMMAND
    if [ "$LVTYPE" != "swap" ]
        then sadm_write "Running : ${MOUNT} ${LVMOUNT}\n"
             ${MOUNT} ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mount error\n `cat $STDERR`" ; return 1 ;  fi
             sadm_write "Running : ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT}\n"
             ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "chown error\n `cat $STDERR`" ; return 1 ;  fi
             sadm_write "Running : ${CHMOD} ${LVPROT} ${LVMOUNT}\n"
             ${CHMOD} ${LVPROT} ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "chmod error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    return 0
}




# --------------------------------------------------------------------------------------------------
#  Ask User what is the volume group he wish to recreate the filesystems
#   Volume group MUST be created first
# --------------------------------------------------------------------------------------------------
#
ask_linux_user_vg()
{
    # Accept the volume group that we need to create the filesystems
    while :
        do
        VGDIR="/etc/lvm/backup" ;  export VGDIR
        ls -1 $VGDIR | sort >  $SADM_TMP_FILE2                          # Create VG Lits on System
        grep -v "^#" $DRFILE | awk -F: '{ print $1 }' | sort | uniq > $SADM_TMP_FILE1  # List VG in Data Input file
        sadm_write "\nList of the volume group that are present in $DRFILE \n"
        sadm_write "${SADM_BOLD}${SADM_GREEN}"
        sort $SADM_TMP_FILE1 | tee $SADM_LOG                            # List VG in Input File
        sadm_write "${SADM_RESET}"
        sadm_write "\nEnter the volume group name that you want to recreate the filesystems : \n"
        read VG                                                         # Accept Volume Group Name
        grep -i $VG $SADM_TMP_FILE1 > /dev/null ; RC1=$?                # VG in input DAta File ?
        grep -i $VG $SADM_TMP_FILE2 > /dev/null ; RC2=$?                # VG Exist on System ?
        RC_ERROR=$(($RC1+$RC2))                                         # Add two search results
        if [ $RC_ERROR -eq 0 ] ; then break ; fi                        # Exist in Both = Perfect
        echo -e "\n\aVolume Group $VG is invalid or not present - Press [RETURN] and choose another"
        read dummy                                                      # Wait till [EMTER] pressed
        done
    export VG

    # Accept final confirmation
    while :
        do
        sadm_write "\nThis is a list of filesystems (and swap) that will created on $VG volume group\n"
        grep "^${VG}:" $DRFILE > $SADM_TMP_FILE3
        awk -F: '{ printf "Type: %-4s  Mount Point: %-30s  LVName: %-20s \n",$4,$2,$3 }' $SADM_TMP_FILE3
        sadm_write "\n"
        echo -e "Do you want to proceed with the creation of all filesystems on $VG [Y/N] ? "
        read answer
        if [ "$answer" = "Y" ] || [ "$answer" = "y" ]
            then answer="Y" ; break
            else echo "Please re-run the script" ; exit 1
        fi
        done
}


# --------------------------------------------------------------------------------------------------
#  Ask User what is the volume group he wish to recreate the filesystems
#  Volume group MUST not exist before starting the restore
# --------------------------------------------------------------------------------------------------
ask_aix_user_vg()
{

    # Accept the volume group that we need to restore
    while :
        do
        tput clear
        RC1=0 ; RC2=0 
        ls -1 ${SADM_DR_DIR}/*.savevg |awk -F_ '{ print $2 }' |awk -F. '{ print $1 }' |sort >$SADM_TMP_FILE1
        sadm_write "AIX RESTORE OF A VOLUME GROUP\n"
        sadm_write "\nA Backup of these VG(s) exist in ${SADM_DR_DIR} :\n"
        sort $SADM_TMP_FILE1 | tee $SADM_LOG                            # List VG that have backup
        sadm_write "\nEnter the volume group name that you want to restore : \n"
        read VG                                                         # Accept Volume Group Name
        grep -i $VG $SADM_TMP_FILE1 >/dev/null 2>&1                     # VG is in the avail.list
        if [ $? -ne 0 ] ; then RC1=1 ; fi                               # Error to 1 ON VG not found
        lsvg | grep -i $VG         > /dev/null 2>&1                     # VG Exist on System ?
        if [ $? -eq 0 ] ; then RC2=1 ; fi                               # Error to 1 ON VG Exit
        RC_ERROR=$(($RC1+$RC2))                                         # Add two search results
        if [ $RC_ERROR -eq 0 ] 
            then DISKFILE=`ls -1 ${SADM_DR_DIR}/$(sadm_get_hostname)_${VG}_restvg_disks.txt`
                 if [ ! -r "$DISKFILE" ] 
                    then sadm_write "The file $DISKFILE is missing\n"
                         sadm_write "This file should contain the destination disk used for the restore\n"
                         sadm_write "Until the file exist and contain the disk name, we cannot proceed\n"
                         sadm_write "Press [ENTER] to continue\n\n" 
                         read dummy
                    else sadm_write "Based on the content of $DISKFILE \n" 
                         sadm_write "Here is the list of the destination disk(s) used for the restore\n" 
                         cat $DISKFILE | while read disk
                            do
                            DISK_LIST="$DISK_LIST $disk"
                            done  
                        sadm_write "$DISK_LIST \n\n"
                        break
                 fi
            else if [ $RC1 -ne 0 ] ; then sadm_write "Invalid VG no Backup for $VG available\n" ;fi
                 if [ $RC2 -ne 0 ] ; then sadm_write "Invalid VG $VG exist on system\n";fi
                 sadm_write "Press [RETURN] and choose another VG\n"
                 read dummy                                              # Wait till [EMTER] pressed
        fi 
        done
    export VG DISK_LIST

    # Accept final confirmation
    while :
        do
        sadm_write "\nWe are now ready to restore the volume group $VG using the following disk(s)\n"
        sadm_write "$DISK_LIST \n\n" 
        echo "Do you want to proceed with the restore [Y/N] ? "
        read answer
        if [ "$answer" = "Y" ] || [ "$answer" = "y" ]
            then answer="Y" ; break
            else sadm_stop 0
                 exit 0
        fi
        done
}



# --------------------------------------------------------------------------------------------------
# Create all Linux filesystems part of the VG the user specified (Parameter Recv is VG name)
# --------------------------------------------------------------------------------------------------
create_linux_filesystem_on_vg()
{
    WVG=$1                                                              # Save VG Received

    # Process all logical volume detected
    for LVLINE in $( grep "^${VG}:" $DRFILE )
        do
        LVNAME=$( echo $LVLINE | awk -F: '{ print $3 }' )
        VGNAME=$( echo $LVLINE | awk -F: '{ print $1 }' )
        LVSIZE=$( echo $LVLINE | awk -F: '{ print $5 }' )
        LVTYPE=$( echo $LVLINE | awk -F: '{ print $4 }' )
        if [ "$LVTYPE" = "swap" ]
            then    LVGROUP="" ; LVOWNER=""
                    LVMOUNT="" ; LVPROT="0000"
            else    LVMOUNT=$(echo $LVLINE | awk -F: '{ print $2 }' )
                    LVTYPE=$( echo $LVLINE | awk -F: '{ print $4 }' )
                    LVOWNER=$(echo $LVLINE | awk -F: '{ print $7 }' )
                    LVGROUP=$(echo $LVLINE | awk -F: '{ print $6 }' )
                    LVPROT=$( echo $LVLINE | awk -F: '{ print $8 }' )
        fi
    #
        if [ $Debug ]
            then    sadm_write "\n\n-----------------------------\n"
                    sadm_write "LINE     = ...$LVLINE...\n"
                    sadm_write "LVNAME   = ...$LVNAME...\n"
                    sadm_write "VGNAME   = ...$VGNAME...\n"
                    sadm_write "LVSIZE   = ...$LVSIZE MB...\n"
                    sadm_write "LVTYPE   = ...$LVTYPE...\n"
                    sadm_write "LVMOUNT  = ...$LVMOUNT...\n"
                    sadm_write "LVOWNER  = ...$LVOWNER...\n"
                    sadm_write "LVGROUP  = ...$LVGROUP...\n"
                    sadm_write "LVPROT   = ...$LVPROT...\n"
        fi

        if [ "$LVTYPE" != "swap" ] && [ "$LVMOUNT" = "" ]
           then report_error "The LVNAME $LVNAME has no mount point - Will bypass this entry"
                continue
        fi
        if [ "$LVTYPE" != "swap" ] && [ "$LVTYPE" = "" ]
           then report_error "The LVNAME $LVNAME has no filesystem type - Will bypass this entry"
                continue
        fi
        recreate_filesystem
        RC=$?

        if [ $RC -eq 0 ] ; then sadm_write "Filesystem $LVMOUNT created successfully\n" ; fi
        if [ $RC -ne 0 ] ; then sadm_write "Filesystem $LVMOUNT ended with errors - Please verify\n"  ; fi
        done
}



# --------------------------------------------------------------------------------------------------
# Create all Aix filesystems part of the VG the user specified (Parameter Recv is VG name)
# --------------------------------------------------------------------------------------------------
#
aix_restore_vg()
{
    #vg=$1                                                               # Save VG Received

    VGBACKUP="$SADM_DR_DIR/$(sadm_get_hostname)_${VG}.savevg"
    VGDISKS="$SADM_DR_DIR/$(sadm_get_hostname)_${VG}_restvg_disks.txt"
    sadm_write "Restoring Volume Group $VG using backup file named :\n" 
    sadm_write "$VGBACKUP \n" 
    sadm_write "\bThe backup will be restore onto these disk(s) :\n"
    sadm_write "$DISK_LIST \n\n"

    restvgcommand=`echo "$RESTVG" | sed -e "s|VGDATAFILE_PLACE_HOLDER|$VGBACKUP|g"`
    restvgcommand=`echo "$restvgcommand" "$DISK_LIST" `
    sadm_write "Command running is \n" 
    sadm_write "$restvgcommand | tee -a ${SADM_LOG}\n\n" 
    $restvgcommand | tee -a ${SADM_LOG}
    RC=$?
    return $RC
}

# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    # If you want this script to be run only by 'root'.
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo %s" "${0##*/}"                          # Suggest using sudo
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S with error
    fi

    sadm_start                                                          # Start Using SADM Tools
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init
    
    if [ $(sadm_get_ostype) = "LINUX" ]                                 # Check LVM Ver under Linux
        then check_lvm_version                                          # Get LVM Version in $LVMVER
             SADM_EXIT_CODE=$?                                          # Save Function Return code
             if [ $SADM_EXIT_CODE -eq 0 ]                               # LVM Not install - Exit
                then sadm_stop $SADM_EXIT_CODE                          # Upd RC & Trim Log & Set RC
                     exit 1
             fi
             if [ $Debug ]                                              # If Debug Activated
                then sadm_write "We are using LVM version $LVMVER \n"   # Show LVM Version
             fi
             linux_setup                                                # Input File & Cmd present ?
             SADM_EXIT_CODE=$?                                          # Save Function Return code
             if [ $SADM_EXIT_CODE -ne 0 ]                               # Cmd|File missing = exit
                then sadm_stop $SADM_EXIT_CODE                          # Upd RC & Trim Log & Set RC
                     exit 1
             fi
    fi
#
    if [ $(sadm_get_ostype) = "LINUX" ]                                 # Linux FS use *.dat file   
        then ask_linux_user_vg                                          # Input VG to recreate FS
             create_linux_filesystem_on_vg $VG                          # Create FS on VG specified
             SADM_EXIT_CODE=$?                                          # Save Status return Code
    fi
    if [ $(sadm_get_ostype) = "AIX" ]                                   # For Aix un testvg Command
        then ask_aix_user_vg 
             aix_restore_vg $VG                                         # Restore VG specified
             SADM_EXIT_CODE=$?                                          # Save Status return Code
    fi
#
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
