#! /bin/sh
#===================================================================================================
# Shellscript   :  sadm_fs_recreate.sh - 
# Description   :  On Linux - Recreate all filesystems of the selected volume group
#                  On Aix   - Recreate all Filesystems of the selected volume group
#                  On Linux environnement the VG MUST create before running this script.
#                  On Aix the VG is Create and the filesystem within it are created.
# Version       :  1.5
# Author        :  Jacques Duplessis (duplessis.jacques@gmail.com)
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
#      "sadm_fs_save_info.sh" (should be in cron) normally located in /sadmin/bin. 
#      File is in backup/restore format.
#            root@aixb50(/sadmin/dat/dr)# file aixb50_datavg.savevg
#                     aixb50_datavg.savevg: backup/restore format file
#  
#    - The restore of the VG will be created on the disks specified in
#      "$SADMIN_BASE_DIR/HOSTNAME_VGNAME_restvg_disks.txt" file. This file contain the disks 
#      that the VG was using last night and was created by the script "sadm_fs_save_info.sh.
#      This file can be modify prior to running this script. 
#      If you want te recreate the VG on different disks then you should modify it.
#
#
#===================================================================================================
#
# 2.0   Nov 2016 - Jacques Duplessis
#       Correct problem in LVM Version detection in Linux (Affect Only RedHat/CentOS V3)
#       Support for AIX was added 
#           - Using savevg to save the structure of the VG
#           - THe Filsystem (and Raw) within VG are recreated automatically, with proper perm.
#           - You need to restore the content of the filesystems from your usual backup.
#            
#
#===================================================================================================
#
#set -x


#
#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
#===================================================================================================

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='2.0'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh    
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh 

# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export ADM_MAIL_ADDR        # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                          ; export SADM_MAIL_TYPE       # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME        # Company Name
#SADM_USER="sadmin"                        ; export SADM_USER            # sadmin user account
#SADM_GROUP="sadmin"                       ; export SADM_GROUP           # sadmin group account
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE     # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE      # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=40                      ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#===================================================================================================
#







# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
DRFILE=$SADM_DR_DIR/$(sadm_get_hostname)_fs_save_info.dat   ;export DRFILE  # Output file of program
Debug=true                                      ; export Debug          # Debug increase Verbose
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
    sadm_writelog "Validate Program Requirements before proceeding ..."
    sadm_writelog " "

    # Check if Input File exist
    if [ ! -r "$DRFILE" ]
        then sadm_writelog "The input file $DRFILE does not exist !"
             sadm_writelog "Process aborted"
             return 1
    fi

    rpm -q which > /dev/null 2>&1
    if [ $? -eq 1 ]
        then sadm_writelog "The command 'which' is not installed - Install it and rerun this script"
             return 1
    fi

    LVCREATE=`which lvcreate >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then LVCREATE=`which lvcreate`
        else sadm_writelog "Error : The command 'lvcreate' was not found" ; return 1
    fi
    export LVCREATE   ; if [ $Debug ] ; then sadm_writelog "COMMAND LVCREATE  : $LVCREATE" ; fi


    TUNE2FS=`which tune2fs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then TUNE2FS=`which tune2fs`
        else sadm_writelog "Error : The command 'tune2fs' was not found" ; return 1
    fi
    export TUNE2FS    ; if [ $Debug ] ; then sadm_writelog "COMMAND TUNE2FS   : $TUNE2FS" ; fi


    MKFS_EXT2=`which mkfs.ext2 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT2=`which mkfs.ext2`
        else sadm_writelog "Error : The command 'mkfs.ext2' was not found" ; return 1
    fi
    export MKFS_EXT2  ; if [ $Debug ] ; then sadm_writelog "COMMAND MKFS_EXT2 : $MKFS_EXT2" ; fi


    MKFS_EXT3=`which mkfs.ext3 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT3=`which mkfs.ext3`
        else sadm_writelog "Error : The command 'mkfs.ext3' was not found" ; return 1
    fi
    export MKFS_EXT3  ; if [ $Debug ] ; then sadm_writelog "COMMAND MKFS_EXT3 : $MKFS_EXT3" ; fi


    MKFS_EXT4=`which mkfs.ext4 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT4=`which mkfs.ext4`
        else sadm_writelog "Error : The command 'mkfs.ext4' was not found" ; return 1
    fi
    export MKFS_EXT4  ; if [ $Debug ] ; then sadm_writelog "COMMAND MKFS_EXT4 : $MKFS_EXT4" ; fi


    MKFS_XFS=`which mkfs.xfs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_XFS=`which mkfs.xfs`
             XFS_ENABLE="Y"
        else MKFS_XFS=""
             XFS_ENABLE="N"
    fi
    export MKFS_XFS   ; if [ $Debug ] ; then sadm_writelog "COMMAND MKFS_XFS  : $MKFS_XFS" ; fi


    FSCK_EXT2=`which fsck.ext2 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT2=`which fsck.ext2`
        else sadm_writelog "Error : The command 'fsck.ext2' was not found" ; return 1
    fi
    export FSCK_EXT2  ; if [ $Debug ] ; then sadm_writelog "COMMAND FSCK_EXT2 : $FSCK_EXT2" ; fi


    FSCK_EXT3=`which fsck.ext3 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT3=`which fsck.ext3`
        else sadm_writelog "Error : The command 'fsck.ext3' was not found" ; return 1
    fi
    export FSCK_EXT3  ; if [ $Debug ] ; then sadm_writelog "COMMAND FSCK_EXT3 : $FSCK_EXT3" ; fi


    FSCK_EXT4=`which fsck.ext4 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT4=`which fsck.ext4`
        else sadm_writelog "Error : The command 'fsck.ext4' was not found" ; return 1
    fi
    export FSCK_EXT4  ; if [ $Debug ] ; then sadm_writelog "COMMAND FSCK_EXT4 : $FSCK_EXT4" ; fi


    FSCK_XFS=`which fsck.xfs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_XFS=`which fsck.xfs`
             XFS_ENABLE="Y"
        else FSCK_XFS=""
             XFS_ENABLE="N"
    fi
    export FSCK_XFS   ; if [ $Debug ] ; then sadm_writelog "COMMAND FSCK_XFS  : $FSCK_XFS" ; fi


    MKDIR=`which mkdir >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKDIR=`which mkdir`
        else sadm_writelog "Error : The command 'mkdir' was not found" ; return 1
    fi
    export MKDIR      ; if [ $Debug ] ; then sadm_writelog "COMMAND MKDIR     : $MKDIR" ; fi


    MOUNT=`which mount >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MOUNT=`which mount`
        else sadm_writelog "Error : The command 'mount' was not found" ; return 1
    fi
    export MOUNT      ; if [ $Debug ] ; then sadm_writelog "COMMAND MOUNT     : $MOUNT" ; fi


    CHMOD=`which chmod >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then CHMOD=`which chmod`
        else sadm_writelog "Error : The command 'chmod' was not found" ; return 1
    fi
    export CHMOD      ; if [ $Debug ] ; then sadm_writelog "COMMAND CHMOD     : $CHMOD" ; fi


    CHOWN=`which chown >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then CHOWN=`which chown`
        else sadm_writelog "Error : The command 'chown' was not found" ; return 1
    fi
    export CHOWN      ; if [ $Debug ] ; then sadm_writelog "COMMAND CHOWN     : $CHOWN" ; fi

    
    MKSWAP=`which mkswap >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKSWAP=`which mkswap`
        else sadm_writelog "Error : The command 'mkswap' was not found" ; return 1
    fi
    export MKSWAP      ; if [ $Debug ] ; then sadm_writelog "COMMAND MKSWAP    : $MKSWAP" ; fi
    
    
    SWAPON=`which swapon >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then SWAPON=`which swapon`
        else sadm_writelog "Error : The command 'swapon' was not found" ; return 1
    fi
    export SWAPON      ; if [ $Debug ] ; then sadm_writelog "COMMAND SWAPON    : $SWAPON" ; fi

    return 0
}




# --------------------------------------------------------------------------------------------------
#          Determine if LVM is installed and what version of lvm is installed (1 or 2)
# --------------------------------------------------------------------------------------------------
#
check_lvm_version()
{
    LVMVER=0                                                            # Assume lvm not install
    sadm_writelog "Currently verifying the LVM version installed on system"

    # Check if LVM Version 1 is installed
    rpm -qa | grep '^lvm-1' > /dev/null 2>&1                            # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=1 ; fi                                # Found LVM V1

    # Check if LVM Version 2 is installed
    rpm -qa | grep '^lvm2' > /dev/null 2>&1                             # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=2 ; fi                                # Found LVM V2

    # If LVM Not Installed
    if [ $LVMVER -eq 0 ]                                                # lvm wasn't found on server
        then sadm_writelog "The rpm 'lvm' or 'lvm2' is not installed"       # Advise user no lvm package
             sadm_writelog "No use in running this script - Script Aborted" # No LVM - No Script
    fi
    return $LVMVER                                                      # Return LVM Version
}






# --------------------------------------------------------------------------------------------------
#               Function called when an error occured while creating a filesystem
# --------------------------------------------------------------------------------------------------
report_error()
{
     WMESS=$1
     sadm_writelog "$WMESS"
     sadm_writelog  "\a\aPress [ENTER] to continue - CTRL-C to Abort\c"
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
    sadm_writelog "Running : ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME}"
    ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME} 1> $STDOUT 2> $STDERR
    if [ $? -ne 0 ] ; then report_error "Error with lvcreate\n `cat $STDERR`" ; return 1 ;  fi

    
    # CREATE FILESYSTEM ON THE LOGICAL VOLUME ------------------------------------------------------
    if [ "$LVTYPE" = "ext2" ]
        then sadm_writelog "Running : ${MKFS_EXT2} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext2 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "ext3" ]
        then sadm_writelog "Running : ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext3 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_writelog "Running : ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext4 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then if [ "$XFS_ENABLE" = "Y" ]
                then sadm_writelog "Running : ${MKFS_XFS} -b size=4k  /dev/${VGNAME}/${LVNAME}"
                     ${MKFS_XFS} -b size=4k /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
                     if [ $? -ne 0 ] ; then report_error "mkfs.xfs error \n `cat $STDERR`" ;return 1 ;fi
                else report_error "Can't create XFS Filesystem - Install xfsprogs\n `cat $STDERR`" ;return 1 
             fi 
    fi
    if [ "$LVTYPE" = "swap" ]
        then sadm_writelog "Running : ${MKSWAP} -c /dev/${VGNAME}/${LVNAME}"
             ${MKSWAP} -c /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkswap error \n `cat $STDERR`" ;return 1 ;fi
    fi 
        
        
    # DO A FILESYSTEM CHECK - JUST TO BE SURE FILESYSTEM IS OK TO USE. -----------------------------
    if [ "$LVTYPE" = "ext2" ]
        then sadm_writelog "Running : ${FSCK_EXT2} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT2} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext2 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "ext3" ]
        then sadm_writelog "Running : ${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT3} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext3 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_writelog "Running : ${FSCK_EXT4} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT4} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext4 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then if [ "$XFS_ENABLE" = "Y" ]
                then sadm_writelog "Running : ${FSCK_XFS} -f /dev/${VGNAME}/${LVNAME}"
                     ${FSCK_XFS} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
                     if [ $? -ne 0 ] ; then report_error "fsck.xfs error\n `cat $STDERR`" ; return 1 ;  fi
                else report_error "Can't create XFS Filesystem - Install xfsprogs\n `cat $STDERR`" ;return 1
             fi 
    fi
    
    
    # SET FSCK MAX-COUNT TO 0 & FSCK MAXIMAL TIME BETWEEN FSCK TO 0  ON EXT? FILESYSTEM ------------
    # PREVENT VERY LONG FSCK WHEN PRODUCTION SYSTEM REBOOT AFTER A LONG TIME.
    if [ "$LVTYPE" = "ext2" ] || [ "$LVTYPE" = "ext3" ] || [ "$LVTYPE" = "ext4" ]  
        then sadm_writelog "Running : ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME}"
             ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "tune2fs error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    
    
    # CREATE THE MOUNT POINT DIRECTORY - FOR SWAP SPACE ACTIVATE IT --------------------------------
    if [ "$LVTYPE" != "swap" ]
        then sadm_writelog "Running : ${MKDIR} -p ${LVMOUNT}"
             ${MKDIR} -p ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkdir error\n `cat $STDERR`" ; return 1 ;  fi
        else sadm_writelog "Running : $SWAPON /dev/${VGNAME}/${LVNAME}"
             $SWAPON /dev/${VGNAME}/${LVNAME}
             if [ $? -ne 0 ] ; then report_error "swapon error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    
    # ADD MOUNT POINT IN /ETC/FSTAB ----------------------------------------------------------------
    sadm_writelog "Running : Adding entry in $FSTAB"
    WDEV="/dev/mapper/${VGNAME}-${LVNAME}"
    echo "$WDEV ${LVMOUNT} $LVTYPE" |awk '{ printf "%-30s %-30s %-4s %s\n",$1,$2,$3,"defaults 1 2"}'>>$FSTAB
    
    
    # IF NOT A SWAP FILE TO CREATE - CREATE MOUNT POINT AND ISSUE CHMOD AND CHOWN COMMAND
    if [ "$LVTYPE" != "swap" ]
        then sadm_writelog "Running : ${MOUNT} ${LVMOUNT}"
             ${MOUNT} ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mount error\n `cat $STDERR`" ; return 1 ;  fi
             sadm_writelog "Running : ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT}"
             ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "chown error\n `cat $STDERR`" ; return 1 ;  fi
             sadm_writelog "Running : ${CHMOD} ${LVPROT} ${LVMOUNT}"
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
        sadm_writelog " "
        sadm_writelog "This is a list of the volume group that are present in $DRFILE"
        sort $SADM_TMP_FILE1 | tee $SADM_LOG                            # List VG in Input File
        sadm_writelog "Enter the volume group that you want to recreate the filesystems : \c"
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
        sadm_writelog " "
        sadm_writelog "This is a list of filesystems (and swap) that will created on $VG volume group"
        grep "^${VG}:" $DRFILE > $SADM_TMP_FILE3
        awk -F: '{ printf "Type: %-4s  Mount Point: %-30s  LVName: %-20s \n",$4,$2,$3 }' $SADM_TMP_FILE3
        sadm_writelog " "
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
        sadm_writelog "AIX RESTORE OF A VOLUME GROUP"
        sadm_writelog " "
        sadm_writelog "A Backup of these VG(s) exist in ${SADM_DR_DIR} :"
        sort $SADM_TMP_FILE1 | tee $SADM_LOG                            # List VG that have backup
        sadm_writelog " "
        sadm_writelog "Enter the volume group name that you want to restore : "
        read VG                                                         # Accept Volume Group Name
        grep -i $VG $SADM_TMP_FILE1 >/dev/null 2>&1                     # VG is in the avail.list
        if [ $? -ne 0 ] ; then RC1=1 ; fi                               # Error to 1 ON VG not found
        lsvg | grep -i $VG         > /dev/null 2>&1                     # VG Exist on System ?
        if [ $? -eq 0 ] ; then RC2=1 ; fi                               # Error to 1 ON VG Exit
        RC_ERROR=$(($RC1+$RC2))                                         # Add two search results
        if [ $RC_ERROR -eq 0 ] 
            then DISKFILE=`ls -1 ${SADM_DR_DIR}/$(sadm_get_hostname)_${VG}_restvg_disks.txt`
                 if [ ! -r "$DISKFILE" ] 
                    then sadm_writelog "The file $DISKFILE is missing"
                         sadm_writelog "This file should contain the destination disk used for the restore"
                         sadm_writelog "Until the file exist and contain the disk name, we cannot proceed"
                         sadm_writelog "Press [ENTER] to continue" 
                         sadm_writelog " "
                         read dummy
                    else sadm_writelog "Based on the content of $DISKFILE" 
                         sadm_writelog "Here is the list of the destination disk(s) used for the restore" 
                         cat $DISKFILE | while read disk
                            do
                            DISK_LIST="$DISK_LIST $disk"
                            done  
                        sadm_writelog "$DISK_LIST"
                        sadm_writelog " "
                        break
                 fi
            else if [ $RC1 -ne 0 ] ; then sadm_writelog "Invalid VG no Backup for $VG available" ;fi
                 if [ $RC2 -ne 0 ] ; then sadm_writelog "Invalid VG $VG exist on system";fi
                 sadm_writelog "Press [RETURN] and choose another VG"
                 read dummy                                              # Wait till [EMTER] pressed
        fi 
        done
    export VG DISK_LIST

    # Accept final confirmation
    while :
        do
        sadm_writelog " "
        sadm_writelog "We are now ready to restore the volume group $VG using the following disk(s)"
        sadm_writelog "$DISK_LIST" 
        sadm_writelog " "
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
            then    sadm_writelog " "
                    sadm_writelog "\n-----------------------------\n"
                    sadm_writelog "LINE     = ...$LVLINE..."
                    sadm_writelog "LVNAME   = ...$LVNAME..."
                    sadm_writelog "VGNAME   = ...$VGNAME..."
                    sadm_writelog "LVSIZE   = ...$LVSIZE MB..."
                    sadm_writelog "LVTYPE   = ...$LVTYPE..."
                    sadm_writelog "LVMOUNT  = ...$LVMOUNT..."
                    sadm_writelog "LVOWNER  = ...$LVOWNER..."
                    sadm_writelog "LVGROUP  = ...$LVGROUP..."
                    sadm_writelog "LVPROT   = ...$LVPROT..."
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

        if [ $RC -eq 0 ] ; then sadm_writelog "Filesystem $LVMOUNT created successfully" ; fi
        if [ $RC -ne 0 ] ; then sadm_writelog "Filesystem $LVMOUNT ended with errors - Please verify"  ; fi
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
    sadm_writelog "Restoring Volume Group $VG using backup file named :" 
    sadm_writelog "$VGBACKUP" 
    sadm_writelog " " 
    sadm_writelog "The backup will be restore onto these disk(s) :"
    sadm_writelog "$DISK_LIST"
    sadm_writelog " " 

    restvgcommand=`echo "$RESTVG" | sed -e "s|VGDATAFILE_PLACE_HOLDER|$VGBACKUP|g"`
    restvgcommand=`echo "$restvgcommand" "$DISK_LIST" `
    sadm_writelog "Command running is " 
    sadm_writelog "$restvgcommand | tee -a ${SADM_LOG}" 
    sadm_writelog " " 
    $restvgcommand | tee -a ${SADM_LOG}
    RC=$?
    return $RC
}

# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    if [ $(sadm_get_ostype) = "LINUX" ]                                 # Check LVM Ver under Linux
        then check_lvm_version                                          # Get LVM Version in $LVMVER
             SADM_EXIT_CODE=$?                                          # Save Function Return code
             if [ $SADM_EXIT_CODE -eq 0 ]                               # LVM Not install - Exit
                then sadm_stop $SADM_EXIT_CODE                          # Upd RC & Trim Log & Set RC
                     exit 1
             fi
             if [ $Debug ]                                              # If Debug Activated
                then sadm_writelog "We are using LVM version $LVMVER"   # Show LVM Version
             fi
             linux_setup                                                # Input File & Cmd present ?
             SADM_EXIT_CODE=$?                                          # Save Function Return code
             if [ $SADM_EXIT_CODE -ne 0 ]                               # Cmd|File missing = exit
                then sadm_stop $SADM_EXIT_CODE                          # Upd RC & Trim Log & Set RC
                     exit 1
             fi
    fi
#
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
