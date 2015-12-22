#! /bin/sh
#===================================================================================================
# Shellscript   :  sadm_fs_recreate.sh - 
# Description   :  Recreate all filesystems of the selected volume group
# Version       :  1.5
# Author        :  Jacques Duplessis (duplessis.jacques@gmail.com)
# Date          :  2010-10-09
# Requires      :  bash shell - lvm installed
# Category      :  disaster recovery tools 
#===================================================================================================
# Description
#
# Note
#    - This script recreate the filesystem of the system with the right
#      size and protection exactly like we have at the office, based on the input file content.
#    - Run this script and specify the Volume Group you want to recreate the filesystems.
#    - This script read it input from the file "sadm_fs_save_info.dat". 
#    - The file "sadm_fs_save_info.prev" contains data from previous day could be used 
#       If rename to "sadm_fs_save_info.dat".
#    - The necessary Volume Group got to created prior to running this script.
#
# At Disaster Recovery Site, You just need to create the volume group, run this script to 
# recreate the empties filesystems as they were at the Office and then restore data to these
# filesystems.

#===================================================================================================
#set -x

#set -x
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH VARIABLES AND
#   FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
SADM_EXIT_CODE=0                               ; export SADM_EXIT_CODE  # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#
#





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
DRFILE=$DR_DIR/`hostname`_fs_save_info.dat      ; export DRFILE         # Input file of program
Debug=true                                      ; export Debug          # Debug increase Verbose
STDERR="${TMP_DIR}/stderr.$$"                   ; export STDERR         # Output of Standard Error
STDOUT="${TMP_DIR}/stdout.$$"                   ; export STDOUT         # Output of Standard Output
FSTAB=/etc/fstab                                ; export FSTAB          # Filesystem Table Name
XFS_ENABLE="N"                                  ; export XFS_ENABLE     # Disable Unless cmd are present

# Global Variables Logical Volume Information
# -------------------------------------------------------------------------------------
LVNAME=""                                       ; export LVNAME         # Logical Volume Name
LVSIZE=""                                       ; export LVSIZE         # Logical Volume Size
VGNAME=""                                       ; export VGNAME         # Volume Group Name
LVTYPE=""                                       ; export LVTYPE         # Logical volume type ext3 swap
LVMOUNT=""                                      ; export LVMOUNT        # Logical Volume mount point
LVOWNER=""                                      ; export LVOWNER        # Logical Vol Mount point owner
LVGROUP=""                                      ; export LVGROUP        # Logical Vol Mount point group
LVPROT=""                                       ; export LVPROT         # Logical Vol Mount point protection


# --------------------------------------------------------------------------------------------------
#     - Set command path used in the script (Some path are different on some RHEL Version)
#     - Check if Input exist and is readable
# --------------------------------------------------------------------------------------------------
#
pre_validation()
{
    sadm_logger "Validate Program Requirements before proceeding ..."
    sadm_logger " "

    # Check if Input File exist
    if [ ! -r "$DRFILE" ]
        then sadm_logger "The input file $DRFILE does not exist !"
             sadm_logger "Process aborted"
             return 1
    fi

    rpm -q which > /dev/null 2>&1
    if [ $? -eq 1 ]
        then sadm_logger "The command 'which' is not installed - Install it and rerun this script"
             return 1
    fi

    LVCREATE=`which lvcreate >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then LVCREATE=`which lvcreate`
        else sadm_logger "Error : The command 'lvcreate' was not found" ; return 1
    fi
    export LVCREATE   ; if [ $Debug ] ; then sadm_logger "COMMAND LVCREATE  : $LVCREATE" ; fi


    TUNE2FS=`which tune2fs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then TUNE2FS=`which tune2fs`
        else sadm_logger "Error : The command 'tune2fs' was not found" ; return 1
    fi
    export TUNE2FS    ; if [ $Debug ] ; then sadm_logger "COMMAND TUNE2FS   : $TUNE2FS" ; fi


    MKFS_EXT2=`which mkfs.ext2 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT2=`which mkfs.ext2`
        else sadm_logger "Error : The command 'mkfs.ext2' was not found" ; return 1
    fi
    export MKFS_EXT2  ; if [ $Debug ] ; then sadm_logger "COMMAND MKFS_EXT2 : $MKFS_EXT2" ; fi


    MKFS_EXT3=`which mkfs.ext3 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT3=`which mkfs.ext3`
        else sadm_logger "Error : The command 'mkfs.ext3' was not found" ; return 1
    fi
    export MKFS_EXT3  ; if [ $Debug ] ; then sadm_logger "COMMAND MKFS_EXT3 : $MKFS_EXT3" ; fi


    MKFS_EXT4=`which mkfs.ext4 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_EXT4=`which mkfs.ext4`
        else sadm_logger "Error : The command 'mkfs.ext4' was not found" ; return 1
    fi
    export MKFS_EXT4  ; if [ $Debug ] ; then sadm_logger "COMMAND MKFS_EXT4 : $MKFS_EXT4" ; fi


    MKFS_XFS=`which mkfs.xfs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKFS_XFS=`which mkfs.xfs`
             XFS_ENABLE="Y"
        else MKFS_XFS=""
             XFS_ENABLE="N"
    fi
    export MKFS_XFS   ; if [ $Debug ] ; then sadm_logger "COMMAND MKFS_XFS  : $MKFS_XFS" ; fi


    FSCK_EXT2=`which fsck.ext2 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT2=`which fsck.ext2`
        else sadm_logger "Error : The command 'fsck.ext2' was not found" ; return 1
    fi
    export FSCK_EXT2  ; if [ $Debug ] ; then sadm_logger "COMMAND FSCK_EXT2 : $FSCK_EXT2" ; fi


    FSCK_EXT3=`which fsck.ext3 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT3=`which fsck.ext3`
        else sadm_logger "Error : The command 'fsck.ext3' was not found" ; return 1
    fi
    export FSCK_EXT3  ; if [ $Debug ] ; then sadm_logger "COMMAND FSCK_EXT3 : $FSCK_EXT3" ; fi


    FSCK_EXT4=`which fsck.ext4 >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_EXT4=`which fsck.ext4`
        else sadm_logger "Error : The command 'fsck.ext4' was not found" ; return 1
    fi
    export FSCK_EXT4  ; if [ $Debug ] ; then sadm_logger "COMMAND FSCK_EXT4 : $FSCK_EXT4" ; fi


    FSCK_XFS=`which fsck.xfs >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then FSCK_XFS=`which fsck.xfs`
             XFS_ENABLE="Y"
        else FSCK_XFS=""
             XFS_ENABLE="N"
    fi
    export FSCK_XFS   ; if [ $Debug ] ; then sadm_logger "COMMAND FSCK_XFS  : $FSCK_XFS" ; fi


    MKDIR=`which mkdir >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKDIR=`which mkdir`
        else sadm_logger "Error : The command 'mkdir' was not found" ; return 1
    fi
    export MKDIR      ; if [ $Debug ] ; then sadm_logger "COMMAND MKDIR     : $MKDIR" ; fi


    MOUNT=`which mount >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MOUNT=`which mount`
        else sadm_logger "Error : The command 'mount' was not found" ; return 1
    fi
    export MOUNT      ; if [ $Debug ] ; then sadm_logger "COMMAND MOUNT     : $MOUNT" ; fi


    CHMOD=`which chmod >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then CHMOD=`which chmod`
        else sadm_logger "Error : The command 'chmod' was not found" ; return 1
    fi
    export CHMOD      ; if [ $Debug ] ; then sadm_logger "COMMAND CHMOD     : $CHMOD" ; fi


    CHOWN=`which chown >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then CHOWN=`which chown`
        else sadm_logger "Error : The command 'chown' was not found" ; return 1
    fi
    export CHOWN      ; if [ $Debug ] ; then sadm_logger "COMMAND CHOWN     : $CHOWN" ; fi

    
    MKSWAP=`which mkswap >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then MKSWAP=`which mkswap`
        else sadm_logger "Error : The command 'mkswap' was not found" ; return 1
    fi
    export MKSWAP      ; if [ $Debug ] ; then sadm_logger "COMMAND MKSWAP    : $MKSWAP" ; fi
    
    
    SWAPON=`which swapon >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then SWAPON=`which swapon`
        else sadm_logger "Error : The command 'swapon' was not found" ; return 1
    fi
    export SWAPON      ; if [ $Debug ] ; then sadm_logger "COMMAND SWAPON    : $SWAPON" ; fi

    return 0
}




# --------------------------------------------------------------------------------------------------
#          Determine if LVM is installed and what version of lvm is installed (1 or 2)
# --------------------------------------------------------------------------------------------------
#
check_lvm_version()
{
    LVMVER=0                                                            # Assume lvm not install
    sadm_logger "Currently verifying the LVM version installed on system"

    # Check if LVM Version 2 is installed
    rpm -qa '^lvm-2' > /dev/null 2>&1                                   # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=2 ; fi                                # Found LVM V2

    # If LVM Not Installed
    if [ $LVMVER -eq 0 ]                                                # lvm wasn't found on server
        then sadm_logger "The rpm 'lvm' or 'lvm2' is not installed"       # Advise user no lvm package
             sadm_logger "No use in running this script - Script Aborted" # No LVM - No Script
    fi
    return $LVMVER                                                      # Return LVM Version
}






# --------------------------------------------------------------------------------------------------
#               Function called when an error occured while creating a filesystem
# --------------------------------------------------------------------------------------------------
report_error()
{
     WMESS=$1
     sadm_logger "$WMESS"
     sadm_logger  "\a\aPress [ENTER] to continue - CTRL-C to Abort\c"
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
    sadm_logger "Running : ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME}"
    ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME} 1> $STDOUT 2> $STDERR
    if [ $? -ne 0 ] ; then report_error "Error with lvcreate\n `cat $STDERR`" ; return 1 ;  fi

    
    # CREATE FILESYSTEM ON THE LOGICAL VOLUME ------------------------------------------------------
    if [ "$LVTYPE" = "ext2" ]
        then sadm_logger "Running : ${MKFS_EXT2} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext2 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "ext3" ]
        then sadm_logger "Running : ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext3 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_logger "Running : ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkfs.ext4 error \n `cat $STDERR`" ;return 1 ;fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then if [ "$XFS_ENABLE" = "Y" ]
                then sadm_logger "Running : ${MKFS_XFS} -b size=4k  /dev/${VGNAME}/${LVNAME}"
                     ${MKFS_XFS} -b size=4k /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
                     if [ $? -ne 0 ] ; then report_error "mkfs.xfs error \n `cat $STDERR`" ;return 1 ;fi
                else report_error "Can't create XFS Filesystem - Install xfsprogs\n `cat $STDERR`" ;return 1 
             fi 
    fi
    if [ "$LVTYPE" = "swap" ]
        then sadm_logger "Running : ${MKSWAP} -c /dev/${VGNAME}/${LVNAME}"
             ${MKSWAP} -c /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkswap error \n `cat $STDERR`" ;return 1 ;fi
    fi 
        
        
    # DO A FILESYSTEM CHECK - JUST TO BE SURE FILESYSTEM IS OK TO USE. -----------------------------
    if [ "$LVTYPE" = "ext2" ]
        then sadm_logger "Running : ${FSCK_EXT2} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT2} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext2 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "ext3" ]
        then sadm_logger "Running : ${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT3} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext3 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_logger "Running : ${FSCK_EXT4} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT4} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "fsck.ext4 error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then if [ "$XFS_ENABLE" = "Y" ]
                then sadm_logger "Running : ${FSCK_XFS} -f /dev/${VGNAME}/${LVNAME}"
                     ${FSCK_XFS} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
                     if [ $? -ne 0 ] ; then report_error "fsck.xfs error\n `cat $STDERR`" ; return 1 ;  fi
                else report_error "Can't create XFS Filesystem - Install xfsprogs\n `cat $STDERR`" ;return 1
             fi 
    fi
    
    
    # SET FSCK MAX-COUNT TO 0 & FSCK MAXIMAL TIME BETWEEN FSCK TO 0  ON EXT? FILESYSTEM ------------
    # PREVENT VERY LONG FSCK WHEN PRODUCTION SYSTEM REBOOT AFTER A LONG TIME.
    if [ "$LVTYPE" = "ext2" ] || [ "$LVTYPE" = "ext3" ] || [ "$LVTYPE" = "ext4" ]  
        then sadm_logger "Running : ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME}"
             ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "tune2fs error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    
    
    # CREATE THE MOUNT POINT DIRECTORY - FOR SWAP SPACE ACTIVATE IT --------------------------------
    if [ "$LVTYPE" != "swap" ]
        then sadm_logger "Running : ${MKDIR} -p ${LVMOUNT}"
             ${MKDIR} -p ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mkdir error\n `cat $STDERR`" ; return 1 ;  fi
        else sadm_logger "Running : $SWAPON /dev/${VGNAME}/${LVNAME}"
             $SWAPON /dev/${VGNAME}/${LVNAME}
             if [ $? -ne 0 ] ; then report_error "swapon error\n `cat $STDERR`" ; return 1 ;  fi
    fi
    
    # ADD MOUNT POINT IN /ETC/FSTAB ----------------------------------------------------------------
    sadm_logger "Running : Adding entry in $FSTAB"
    WDEV="/dev/mapper/${VGNAME}-${LVNAME}"
    echo "$WDEV ${LVMOUNT} $LVTYPE" |awk '{ printf "%-30s %-30s %-4s %s\n",$1,$2,$3,"defaults 1 2"}'>>$FSTAB
    
    
    # IF NOT A SWAP FILE TO CREATE - CREATE MOUNT POINT AND ISSUE CHMOD AND CHOWN COMMAND
    if [ "$LVTYPE" != "swap" ]
        then sadm_logger "Running : ${MOUNT} ${LVMOUNT}"
             ${MOUNT} ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "mount error\n `cat $STDERR`" ; return 1 ;  fi
             sadm_logger "Running : ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT}"
             ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT} 1> $STDOUT 2> $STDERR
             if [ $? -ne 0 ] ; then report_error "chown error\n `cat $STDERR`" ; return 1 ;  fi
             sadm_logger "Running : ${CHMOD} ${LVPROT} ${LVMOUNT}"
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
ask_user_vg()
{
    # Accept the volume group that we need to create the filesystems
    while :
        do
        if [ $LVMVER -eq 1 ] ; then VGDIR="/etc/lvmtab.d" ; else VGDIR="/etc/lvm/backup" ; fi
        export VGDIR
        ls -1 $VGDIR | sort >  $TMP_FILE2                               # Create VG Lits on System
        awk -F: '{ print $1 }' $DRFILE | sort | uniq > $TMP_FILE1       # List VG in Data Input file
        sadm_logger " "
        sadm_logger "This is a list of the volume group that are present in $DRFILE"
        sort $TMP_FILE1 | tee $LOG                                      # List VG in Input File
        sadm_logger "\nEnter the volume group that you want to recreate the filesystems : \c"
        read VG                                                         # Accept Volume Group Name
        grep -i $VG $TMP_FILE1 > /dev/null ; RC1=$?                     # VG in input DAta File ?
        grep -i $VG $TMP_FILE2 > /dev/null ; RC2=$?                     # VG Exist on System ?
        RC_ERROR=$(($RC1+$RC2))                                         # Add two search results
        if [ $RC_ERROR -eq 0 ] ; then break ; fi                        # Exist in Both = Perfect
        echo -e "\n\aVolume Group $VG is invalid or not present - Press [RETURN] and choose another"
        read dummy                                                      # Wait till [EMTER] pressed
        done
    export VG

    # Accept final confirmation
    while :
        do
        sadm_logger " "
        sadm_logger "This is a list of filesystems (and swap) that will created on $VG volume group"
        grep "^${VG}:" $DRFILE > $TMP_FILE3
        awk -F: '{ printf "Type: %-4s  Mount Point: %-30s  LVName: %-20s \n",$4,$2,$3 }' $TMP_FILE3
        sadm_logger " "
        echo -e "Do you want to proceed with the creation of all filesystems on $VG [Y/N] ? \c"
        read answer
        if [ "$answer" = "Y" ] || [ "$answer" = "y" ]
            then answer="Y" ; break
            else echo "Please re-run the script" ; exit 1
        fi
        done
}



# --------------------------------------------------------------------------------------------------
# Create all filesystems part of the VG the user specified
# --------------------------------------------------------------------------------------------------
#
create_filesystem_on_vg()
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
            then    sadm_logger " "
                    sadm_logger "\n-----------------------------\n"
                    sadm_logger "LINE     = ...$LVLINE..."
                    sadm_logger "LVNAME   = ...$LVNAME..."
                    sadm_logger "VGNAME   = ...$VGNAME..."
                    sadm_logger "LVSIZE   = ...$LVSIZE MB..."
                    sadm_logger "LVTYPE   = ...$LVTYPE..."
                    sadm_logger "LVMOUNT  = ...$LVMOUNT..."
                    sadm_logger "LVOWNER  = ...$LVOWNER..."
                    sadm_logger "LVGROUP  = ...$LVGROUP..."
                    sadm_logger "LVPROT   = ...$LVPROT..."
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

        if [ $RC -eq 0 ] ; then sadm_logger "Filesystem $LVMOUNT created successfully" ; fi
        if [ $RC -ne 0 ] ; then sadm_logger "Filesystem $LVMOUNT ended with errors - Please verify"  ; fi
        done
}


# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
#
    check_lvm_version                                                   # Get LVM Version in $LVMVER
    SADM_EXIT_CODE=$?                                                     # Save Function Return code
    if [ $SADM_EXIT_CODE -eq 0 ]                                          # LVM Not install - Exit
        then sadm_stop $SADM_EXIT_CODE                                    # Upd. RC & Trim Log & Set RC
             exit 1
    fi
    if [ $Debug ]                                                       # If Debug Activated
        then sadm_logger "We are using LVM version $LVMVER"               # Show LVM Version
    fi
#
    pre_validation                                                      # Input File > Cmd present ?
    SADM_EXIT_CODE=$?                                                     # Save Function Return code
    if [ $SADM_EXIT_CODE -ne 0 ]                                          # Cmd|File missing = exit
        then sadm_stop $SADM_EXIT_CODE                                    # Upd. RC & Trim Log & Set RC
             exit 1
    fi
#
    ask_user_vg                                                         # Input VG to recreate FS
    create_filesystem_on_vg $VG                                         # Create All FS on VG specified
#
    sadm_stop $SADM_EXIT_CODE                                             # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                  # Exit Glob. Err.Code (0/1)
