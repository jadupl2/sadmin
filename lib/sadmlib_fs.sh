#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# Shellscript:	sadmlib_fs.sh - Contains SADM FileSystem Related functions
# Version    :	2.0
# Author     :	jacques duplessis (sadmlinux@gmail.com)
# Date       :	2016-06-01
# Requires   :	bash shell - lvm installed
# Category   :	filesystem tools
# SCCS-Id.   :	@(#) sadmlib_fs.sh 1.5 June 2016
#---------------------------------------------------------------------------------------------------
# Description
#   Library of functions to deal with various LVM commands
#
#---------------------------------------------------------------------------------------------------
#   2.0      Revisited to work with SADM environment - Jan 2017 - Jacques Duplessis
#   2.1      Added support for XFS Filesystem
# 2018_05_18 v2.2 Adapted to be used by Auto Filesystem Increase
# 2018_06_12 v2.3 Fix Problem with get_mntdata was not returning good lvsize (xfs only)
# 2018_09_20 v2.4 Fix problem with filesystem commands options
# 2019_02_25 Improvement: v2.5 SADMIN Filesystem Library - Major code revamp and bug fixes.
#===================================================================================================
# 
#
#---------------------------------------------------------------------------------------------------
#set -x





# Global Variables Logical Volume Information 
#---------------------------------------------------------------------------------------------------
FSTAB=/etc/fstab                            ; export FSTAB              # Filesystem Table file
WFSTAB=$SADM_TMP_DIR/fstab.wrk              ; export WFSTAB             # Filesystem Table Work file
VGLIST="$SADM_TMP_DIR/vglist.$$"            ; export VGLIST             # Contain list of VG on system
rm -f $VGLIST >/dev/null 2>&1                                           # Make sure file doesn't exist
VGDIR="/etc/lvm/backup"                     ; export VGDIR              # List if VG 
declare -a mount_array                                                  # Declare mount & unmount array 
MAXLEN_LV=30                                ; export MAXLEN_LV          # Max Char for LV Name
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
#
LVNAME=""			                        ; export LVNAME             # Logical Volume Name
LVSIZE=""                                   ; export LVSIZE             # Logical Volume Size
VGNAME=""                                   ; export VGNAME             # Volume Group Name
VGFREE=""                                   ; export VGFREE             # VG Free Space in MB
LVTYPE=""                                   ; export LVTYPE             # Logical vol.type ext3 swap
LVMOUNT=""                                  ; export LVMOUNT            # Logical vol. mount point
LVOWNER=""                                  ; export LVOWNER            # Mount point owner
LVGROUP=""                                  ; export LVGROUP            # Mount point group
LVPROT=""                                   ; export LVPROT             # Mount point protection
#
LVREMOVE=""                                 ; export LVREMOVE           # lvremove Path


# --------------------------------------------------------------------------------------------------
# FUNCTION SETUP LVM ENVIRONMENT VARIABLES  
# WILL USE THESE ENVIRONMENT VARIABLE TO TEST IF COMMAND ARE AVAILABLE OR NOT.
# --------------------------------------------------------------------------------------------------
setlvm_path() {
    which mkfs.ext3 >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then MKFS_EXT3=`which mkfs.ext3`      ; else MKFS_EXT3=""  ;fi
    export MKFS_EXT3

    which fsck.ext3 >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then FSCK_EXT3=`which fsck.ext3`      ; else FSCK_EXT3=""  ;fi
    export FSCK_EXT3

    which mkfs.ext4 >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then MKFS_EXT4=`which mkfs.ext4`      ; else MKFS_EXT4=""  ;fi
    export MKFS_EXT4

    which fsck.ext4 >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then FSCK_EXT4=`which fsck.ext4`      ; else FSCK_EXT4=""  ;fi
    export FSCK_EXT4

    which mkfs.xfs >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then MKFS_XFS=`which mkfs.xfs`        ; else MKFS_XFS=""  ;fi
    export MKFS_XFS

    which lvcreate >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then LVCREATE=`which lvcreate`        ; else LVCREATE=""  ;fi
    export LVCREATE

    which lvs >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then LVS=`which lvs`                  ; else LVS=""       ;fi
    export LVS

    which lvextend >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then LVEXTEND=`which lvextend`        ; else LVEXTEND=""  ;fi
    export LVEXTEND

    which lvremove >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then LVREMOVE=`which lvremove`        ; else LVREMOVE=""  ;fi
    export LVREMOVE

    which lvscan >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then LVSCAN=`which lvscan`            ; else LVSCAN=""  ;fi
    export LVSCAN

    which vgs >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then VGS=`which vgs`                  ; else VGS=""  ;fi
    export VGS

    which vgdisplay >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then VGDISPLAY=`which vgdisplay`      ; else VGDISPLAY=""  ;fi
    export VGDISPLAY

    which resize2fs >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then RESIZE2FS=`which resize2fs`      ; else RESIZE2FS=""  ;fi
    export RESIZE2FS

    which xfs_growfs >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then XFS_GROWFS=`which xfs_growfs`    ; else XFS_GROWFS=""  ;fi
    export XFS_GROWFS

    which xfs_repair >/dev/null 2>&1 
    if [ $? -eq 0 ] ; then XFS_REPAIR=`which xfs_repair`    ; else XFS_REPAIR=""  ;fi
    export XFS_REPAIR

    if [ "$DEBUG_LEVEL" -gt 0 ]
       then sadm_writelog " " ; sadm_writelog " " 
            sadm_writelog "Important Commands Path or Not Found"
            sadm_writelog "MKFS_EXT3        = $MKFS_EXT3"
            sadm_writelog "MKFS_EXT4        = $MKFS_EXT4"
            sadm_writelog "FSCK_EXT3        = $FSCK_EXT3"
            sadm_writelog "FSCK_EXT4        = $FSCK_EXT4"
            sadm_writelog "LVCREATE         = $LVCREATE"
            sadm_writelog "LVS              = $LVS"
            sadm_writelog "LVEXTEND         = $LVEXTEND"
            sadm_writelog "LVSCAN           = $LVSCAN"
            sadm_writelog "RESIZE2FS        = $RESIZE2FS"
            sadm_writelog "XFS_GROWFS       = $XFS_GROWFS"
            sadm_writelog "XFS_REPAIR       = $XFS_REPAIR"
            sadm_writelog "VGDISPLAY        = $VGDISPLAY"
            sadm_writelog "VGS              = $VGS"
            sadm_writelog " " ; sadm_writelog " " 
    fi
}


#===================================================================================================
# Function that create a file containing a list of volume group(s) on the system
#===================================================================================================
create_vglist()
{
    $VGS --noheadings --separator , |awk -F, '{ print $1 }'|tr -d ' '} >$VGLIST
}


#---------------------------------------------------------------------------------------------------
# Function that verify if a volume group exist on the system
#---------------------------------------------------------------------------------------------------
vgexist()
{
   vg2check=$1 
   create_vglist
   grep -i $vg2check $VGLIST > /dev/null 2>&1
   vgrc=$? 
   return $vgrc
}


#---------------------------------------------------------------------------------------------------
# Function that verify if a logical volume exist on the system
#---------------------------------------------------------------------------------------------------
lvexist()
{
   lv2check=$1
   if [ "$LVS" != "" ] 
        then $LVS --noheadings | awk '{ print $1 }' | grep "^$lv2check$"  >/dev/null
             lvrc=$?   
        else grep -E "^\/dev" $FSTAB|awk '{ print $1 }'|awk -F/ '{ print $NF }'|grep "^${lv2check}$" >/dev/null
             lvrc=$?
   fi 
   return $lvrc
}


# -------------------------------------------------------------------------------------
# Fnction to get the volume group information
# -------------------------------------------------------------------------------------
getvg_info()
{
    WVGNAME=$1
    vgexist $WVGNAME
    VGEXIST=$?
    if [ $VGEXIST -eq 0 ]
        then VGSOPT="--noheadings --separator , --units m "
             VGSIZE=`$VGS $VGSOPT $WVGNAME |awk -F, '{ print $6 }'|tr -d 'G' |awk -F\. '{ print $1 }'`
             VGFREE=`$VGS $VGSOPT $WVGNAME |awk -F, '{ print $7 }'|tr -d 'G' |awk -F\. '{ print $1 }'`
        else VGSIZE=0 ; VGFREE=0; 
             sadm_writelog "VG ${WVGNAME} doesn't exist - process aborted"
    fi
    return
}


#---------------------------------------------------------------------------------------------------
# Check if mount point received exist in /etc/fstab 
#---------------------------------------------------------------------------------------------------
mntexist()
{
   mnt2check=$1
   grep "^/dev/" $FSTAB |awk '{ printf "%s \n", $2 }' |egrep "^${mnt2check} |^${mnt2check}	">/dev/null
   mntrc=$?
   return $mntrc
}



#---------------------------------------------------------------------------------------------------
#  This function based on MountPoint set Global Variable (VGNAME, LVNAME, ...) 
#---------------------------------------------------------------------------------------------------
get_mntdata()
{
   
   # CHECK IF MOUNT POINT EXIST IN /ETC/FSTAB, IF NOT RETURN TO CALLER WITH ERROR
   # ---------------------------------------------------------------------------
   mnt2get=$1
   grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' |egrep "^${mnt2get} |^${mnt2get}	" >/dev/null
   mntget_rc=$?
   if [ $mntget_rc -ne 0 ] ; then return $mntget_rc ; fi
   
   
   # Save mount point
   LVMOUNT=$mnt2get
   
   # Extract /etc/fstab line that contain the mount point
   LVLINE=`grep "^/dev/" $FSTAB | egrep "${mnt2get} |${mnt2get}	"`
   
   # Determine if /dev/mapper/vgname-lvname or /dev/vgname/lvname is used for FS
   DEVTYPE=`echo $LVLINE | awk -F/ '{ print $3 }'  | tr -d " "`
   
   if [ "$DEVTYPE" = "mapper" ] 
        then LVNAME=`echo $LVLINE | awk -F/ '{ print $4 }'  | tr -d " " | awk -F- '{ print $2 }'`
             VGNAME=`echo $LVLINE | awk -F/ '{ print $4 }'  | tr -d " " | awk -F- '{ print $1 }'`
        else LVNAME=`echo $LVLINE | awk -F/ '{ print $4 }'  | tr -d " "`
             VGNAME=`echo $LVLINE | awk -F/ '{ print $3 }'`
    fi
   LVTYPE=`echo $LVLINE | awk     '{ print $3 }' | tr [A-Z] [a-z]`

   LVLINE=`$LVSCAN 2>/dev/null | grep "'/dev/${VGNAME}/${LVNAME}'"`
   LVWS1=$( echo $LVLINE  | awk -F'[' '{ print $2 }' )
   LVWS2=$( echo $LVWS1   | awk -F']' '{ print $1 }' )
   LVFLT=$( echo $LVWS2   | awk '{ print $1 }' | tr -d '<' )
   LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )
   if [ "$LVUNIT" = "GB" ] || [ "$LVUNIT" = "GiB" ]
      then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc |awk -F'.' '{ print $1 }'`
           LVSIZE=$LVINT
      else LVINT=$( echo $LVFLT | awk -F'.' '{ print $1 }' )
           LVSIZE=$LVINT
   fi
           
   LVOWNER=`ls -ld $LVMOUNT | awk '{ printf "%s", $3 }'`
   LVGROUP=`ls -ld $LVMOUNT | awk '{ printf "%s", $4 }'`

   LVLS=`ls -ld $LVMOUNT`
   user_bit=0 ; group_bit=0 ; other_bit=0 ; stick_bit=0
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,2,1) }'`   = "r" ] ; then user_bit=`expr $user_bit + 4`   ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,3,1) }'`   = "w" ] ; then user_bit=`expr $user_bit + 2`   ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`   = "x" ] ; then user_bit=`expr $user_bit + 1`   ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`   = "s" ] ; then user_bit=`expr $user_bit + 1`   ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`   = "s" ] ; then stick_bit=`expr $stick_bit + 4` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,5,1) }'`   = "r" ] ; then group_bit=`expr $group_bit + 4` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,6,1) }'`   = "w" ] ; then group_bit=`expr $group_bit + 2` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`   = "x" ] ; then group_bit=`expr $group_bit + 1` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`   = "s" ] ; then group_bit=`expr $group_bit + 1` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`   = "s" ] ; then stick_bit=`expr $stick_bit + 2` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,8,1) }'`   = "r" ] ; then other_bit=`expr $other_bit + 4` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,9,1) }'`   = "w" ] ; then other_bit=`expr $other_bit + 2` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'`  = "x" ] ; then other_bit=`expr $other_bit + 1` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'`  = "t" ] ; then other_bit=`expr $other_bit + 1` ; fi
   if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'`  = "t" ] ; then stick_bit=`expr $stick_bit + 1` ; fi
   LVPROT="${stick_bit}${user_bit}${group_bit}${other_bit}"

}



#---------------------------------------------------------------------------------------------------
# Function validate if MetaData Collected is ok to create the filesystem 
#---------------------------------------------------------------------------------------------------
metadata_creation_valid()
{

    # Volume Group must exist
   if ! vgexist $VGNAME
      then sadm_writelog "Filesystem Creation - Volume Group $VGNAME does not exist"
           return 1
   fi

    # Logical Volume name must not exist
   if lvexist $LVNAME
      then sadm_writelog "The LV name ${LVNAME} already exist"
           return 1
   fi 

    # Logical Volume Name Length is zero 
   if [ ${#LVNAME} -eq 0 ] 
      then sadm_writelog "No Valid LV name is specify"
           return 1
   fi

    # Refuse First Character Blank for Logical Volume name 
   if [ ${LVNAME:0:1} = " " ] 
      then sadm_writelog "First charecter of the Logical Volume name must not be blank"
           return 1
   fi

    # Logical Volume size must be at least 32 Mb
   if [ ${LVSIZE} -lt 32 ] 
      then sadm_writelog "Filesystem size must greater then 32 MB"
           return 1
   fi

    # Logical Volume type must be ext3 ext4 or xfs 
   if [ $LVTYPE != "ext3" ] && [ $LVTYPE != "ext4" ] && [ $LVTYPE != "xfs" ] 
      then sadm_writelog "Filesystem type must be ext3, ext4 or xfs - Not $LVTYPE"
           return 1
   fi

    # Validate Mount Point
   if mntexist $LVMOUNT
      then sadm_writelog "Mount Point $LVMOUNT already exist"
           return 1
   fi

   return 0
}



#---------------------------------------------------------------------------------------------------
# This function Check if mount point is valid
# Check if first character is a slash
#---------------------------------------------------------------------------------------------------
mntvalid()
{
   mnt2valid=$1 
   mnt2validrc=0
   wchar=${mnt2valid:0:1}
   if [ "$wchar" != "/" ] ; then mnt2validrc=1 ; fi 
   return ${mnt2validrc}
}



#---------------------------------------------------------------------------------------------------
# Expand Filesystem Function
#---------------------------------------------------------------------------------------------------
extend_fs()
{
    sadm_writelog "Filesystem before increase"
    echo "${bold}${yellow}Filesystem before increase${reset}"
    df -h ${LVMOUNT} | tee -a $SADM_LOG 2>&1 
    echo " "

    sadm_writelog "$LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME"
    printf "$LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME "
    $LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME >> $SADM_LOG 2>&1       # Extend the logical volume
    if [ $? -ne 0 ] 
        then sadm_writelog "Error on lvextend /dev/$VGNAME/$LVNAME"
             sadm_print_status "ERROR" "Error on lvextend /dev/$VGNAME/$LVNAME"
             return 1
        else sadm_print_status "OK" ""
    fi 

    if [ "$LVTYPE" = "ext3" ] || [ "$LVTYPE" = "ext4" ]                 # Ext3,Ext4 Resize Filesystem 
        then sadm_writelog "$RESIZE2FS     /dev/$VGNAME/$LVNAME" 
             printf "$RESIZE2FS /dev/$VGNAME/$LVNAME " 
             $RESIZE2FS  /dev/$VGNAME/$LVNAME >> $SADM_LOG 2>&1
             if [ $? -ne 0 ] 
                then sadm_writelog "Error on resize2fs /dev/$VGNAME/$LVNAME"
                     sadm_print_status "ERROR" "Error on resize2fs /dev/$VGNAME/$LVNAME"
                     return 1
                else sadm_print_status "OK" ""
            fi 
    fi

    if [ "$LVTYPE" = "xfs" ]                                            # XFS Resize Filesystem 
        then sadm_writelog "$XFS_GROWFS ${LVMOUNT}" 
             printf "$XFS_GROWFS ${LVMOUNT} " 
             $XFS_GROWFS ${LVMOUNT} >> $SADM_LOG 2>&1
             if [ $? -ne 0 ] 
                then sadm_writelog "Error with $XFS_GROWFS ${LVMOUNT}"
                     sadm_print_status "ERROR" "Error with $XFS_GROWFS ${LVMOUNT}"
                     return 1
                else sadm_print_status "OK" ""
            fi              
    fi

    echo " "
    sadm_writelog "Filesystem after increase"
    echo "${bold}${yellow}Filesystem after increase${reset}"
    df -h ${LVMOUNT} | tee -a $SADM_LOG 2>&1 
    return 0
 
}



#---------------------------------------------------------------------------------------------------
# Delete Filesystem Function
#---------------------------------------------------------------------------------------------------
remove_fs()
{

    # Make sure to unmount filesystem
    mount | grep "${LVMOUNT} "  > /dev/null 
    if [ $? -eq 0 ] 
       then sadm_writelog "Unmounting ${LVMOUNT} "
            printf "Unmounting ${LVMOUNT} "
            umount ${LVMOUNT} >> $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
                then sadm_writelog "Error unmounting ${LVMOUNT}"
                     sadm_print_status "ERROR" "Can't unmount ${LVMOUNT}\n"
                     return 1
                else sadm_print_status "OK" ""
            fi 
     fi
   
    # Remove the logical Volume
    sadm_writelog "$LVREMOVE -f /dev/${VGNAME}/${LVNAME} "              # Write command to Log
    printf "$LVREMOVE -f /dev/${VGNAME}/${LVNAME} "                     # Inform user what we do
    $LVREMOVE -f /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1             # Try to remove Logical Vol.
    if [ $? -ne 0 ]                                                     # If Error while removing lv
        then sadm_writelog "Error removing /dev/${VGNAME}/${LVNAME} logical volume"
             sadm_print_status "ERROR" "Can't remove the logical volume ${LVMOUNT}"
             mount ${LVMOUNT}                                           # Remount Filesystem
             return 1                                                   # Return Error to caller
        else sadm_print_status "OK" ""                                # Action succeeded
    fi 

    # Create a TMP Work file from fstab without the lv to remove
    sadm_writelog "Removing \" $LVMOUNT \" from $FSTAB "                # Write action to log
    printf "Removing \"$LVMOUNT \" from $FSTAB "                        # Advise user what we do
    grep -vi " ${LVMOUNT} " $FSTAB > $WFSTAB                            # New FSTAB work without LV
    if [ $? -ne 0 ]                                                     # Error Creating FSTAB Work
        then sadm_writelog "Error removing $LVMOUNT from $FSTAB"         # Unbale to create work file
             sadm_print_status "ERROR" "Can't create new fstab temp file ($WFSTAB)."
             mount ${LVMOUNT}                                           # Remount Filesystem
             return 1                                                   # Return Error to caller
        else sadm_print_status "OK" ""                                  # Action succeeded
    fi 

    # Erase actual fstab with the new fstab (the tmp file)
    sadm_writelog "Copying $WFSTAB to $FSTAB"                           # Write action to log
    printf "Copying new fstab file in place ($WFSTAB to $FSTAB) "       # Advise user what we do
    cp $WFSTAB $FSTAB                                                   # Install new fstab 
    if [ $? -ne 0 ]                                                     # Error Creating FSTAB Work
        then sadm_writelog "Error copying $WFSTAB to $FSTAB"             # Unable to create work file
             sadm_print_status "ERROR" "Error copying $WFSTAB to $FSTAB - Check /etc/fstab"
             return 1                                                   # Return Error to caller
        else sadm_print_status "OK" ""                                # Action succeeded
    fi 

    # Make sure /etc/fstab have the right owner and permission
    sadm_writelog "Make sure $FSTAB is own by root user/group and permission are at 644" 
    printf "Make sure $FSTAB is own by root user/group and permission are at 644 "
    chmod 644 $FSTAB && chown root.root $FSTAB                          # Change Owner & Permission
    if [ $? -ne 0 ]                                                     # Error Creating FSTAB Work
        then sadm_writelog "Error change owner/group or permission on $FSTAB"  
             sadm_print_status "ERROR" "Error change owner/group or permission on $FSTAB"
             return 1                                                   # Return Error to caller
        else sadm_print_status "OK" ""                                # Action succeeded
    fi 

}



#---------------------------------------------------------------------------------------------------
# Filesysten Check Function
#---------------------------------------------------------------------------------------------------
filesystem_fsck()
{
    # Filesystem got to be unmounted first
    mount | grep "${LVMOUNT} "  > /dev/null 
    if [ $? -eq 0 ] 
       then sadm_writelog "Unmounting ${LVMOUNT} "
            printf "Unmounting ${LVMOUNT} "
            umount ${LVMOUNT}  >> $SADM_LOG 2>&1
            if [ $? -ne 0 ]
                then sadm_writelog "Error unmounting ${LVMOUNT}"
                     sadm_print_status "ERROR" "Can't unmount ${LVMOUNT}"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
            fi
    fi

    
    # Run filesystem check on filesystem
    if [ "$LVTYPE" = "ext3" ]
       then sadm_writelog "$FSCK_EXT3 -fy /dev/$VGNAME/$LVNAME"
            printf "$FSCK_EXT3 -fy /dev/$VGNAME/$LVNAME "
            $FSCK_EXT3 -fy /dev/$VGNAME/$LVNAME >> $SADM_LOG 2>&1
            RC=$?
            if [ "$RC" -ne 0 ]
               then sadm_writelog "Error $RC on fsck /dev/$VGNAME/$LVNAME"
                    sadm_print_status "ERROR" "Error no.${RC} returned by $FSCK_EXT3"  
                    return 1
               else sadm_print_status "OK" ""                           # Action succeeded
            fi
    fi
    if [ "$LVTYPE" = "ext4" ]
       then sadm_writelog "$FSCK_EXT4 -fy /dev/$VGNAME/$LVNAME"
            printf "$FSCK_EXT4 -fy /dev/$VGNAME/$LVNAME "
            $FSCK_EXT4 -fy /dev/$VGNAME/$LVNAME >> $SADM_LOG 2>&1
            RC=$?
            if [ "$RC" -ne 0 ]
               then sadm_writelog "Error on fsck /dev/$VGNAME/$LVNAME"
                    sadm_print_status "ERROR" "Error no.${RC} returned by $FSCK_EXT4"  
                    return 1
               else sadm_print_status "OK" ""                           # Action succeeded
            fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then sadm_writelog "Running : ${XFS_REPAIR} -n /dev/${VGNAME}/${LVNAME}"
             printf "${XFS_REPAIR} -n /dev/${VGNAME}/${LVNAME} "
             ${XFS_REPAIR} -n /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then sadm_writelog "Error $RC returned by ${XFS_REPAIR}"
                     sadm_print_status "ERROR" "Error no.${RC} returned by $XFS_REPAIR"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
             fi
    fi
       

    # Remount unmounted filesystem
    sadm_writelog "Mounting ${LVMOUNT} "
    printf "Mounting ${LVMOUNT} "
    mount ${LVMOUNT}
    if [ $? -ne 0 ]
        then sadm_writelog "Error Mounting ${LVMOUNT}"
             sadm_print_status "ERROR" "Error no.${RC} remounting ${LVMOUNT}"  
             return 1
        else sadm_print_status "OK" ""                                  # Action succeeded
    fi

     return 0  
}



#---------------------------------------------------------------------------------------------------
# Create filesystem function
#---------------------------------------------------------------------------------------------------
create_fs()
{

    if [ "$DEBUG_LEVEL" -gt 0 ] 
       then sadm_writelog "\n-----------------------------"
            sadm_writelog "LINE        = $LVLINE" 
            sadm_writelog "LVNAME      = $LVNAME"
            sadm_writelog "OLD_LVNAME  = $OLD_LVNAME"
            sadm_writelog "VGNAME      = $VGNAME" 
            sadm_writelog "OLD_VGNAME  = $OLD_VGNAME" 
            sadm_writelog "LVSIZE      = $LVSIZE MB" 
            sadm_writelog "LVTYPE      = $LVTYPE" 
            sadm_writelog "LVMOUNT     = $LVMOUNT"
            sadm_writelog "OLDLVMOUNT  = $OLD_LVMOUNT"
            sadm_writelog "LVTYPE      = $LVTYPE"
            sadm_writelog "LVOWNER     = $LVOWNER"
            sadm_writelog "LVGROUP     = $LVGROUP"
            sadm_writelog "LVPROT      = $LVPROT"
            sadm_writelog "\n-----------------------------"
    fi
    
    # If logical volume name is greater than MAXLEN_LV char - then remove char overflow 
    if [ ${#LVNAME} -gt ${MAXLEN_LV} ] 
       then sadm_writelog "The Logical volume name ${LVNAME} is too long (max ${MAXLEN_LV})."
            echo "The Logical volume name ${LVNAME} is too long (max ${MAXLEN_LV})."
            LVNAME=`echo "${LVNAME}" | cut -c1-${MAXLEN_LV}`
            sadm_writelog "It has been changed to ${LVNAME}"
            echo "It has been changed to ${LVNAME}"
    fi 

    # Check if logical volume name already exist - chop it and 2 numbers at the end
    grep -E "^\/dev" $FSTAB | awk '{ print $1 }' | awk -F/ '{ print $4 }'| grep $LVNAME >/dev/null 
    RC=$?
    if [ $RC -eq 0 ]
       then echo "The LV name ${LVNAME} already exist"
            sadm_writelog "The LV name ${LVNAME} already exist"
            NUMBER=100
            while [ $NUMBER -gt 99 ]  
                  do 
                  NUMBER=$RANDOM 
                  done
            WLVNAME=`echo "${LVNAME}" | cut -c1-12`
            LVNAME=`echo "${WLVNAME}${NUMBER}"`
            sadm_writelog "It has been changed with random number ${NUMBER} to ${LVNAME}"
            echo "It has been changed with random number ${NUMBER} to ${LVNAME}"
     fi 
    
    # Check if mount point is already in /etc/fstab
    grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' | grep "^${LVMOUNT} ">/dev/null
    RC=$?
    if [ $RC -eq 0 ]
       then sadm_writelog "The mount point $LVMOUNT already exist in $FSTAB"
            sadm_print_status "ERROR" "Mount point $LVMOUNT already exist in $FSTAB"  
            return 1
    fi 


    # CREATE LOGICAL VOLUME
    sadm_writelog "Running : ${LVCREATE} -y -L${LVSIZE}M -n ${LVNAME} ${VGNAME}"
    printf "${LVCREATE} -y -L${LVSIZE}M -n ${LVNAME} ${VGNAME} "
    ${LVCREATE} -y -L${LVSIZE}M -n ${LVNAME} ${VGNAME} >> $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_writelog "Error (${RC}) returned by lvcreate command."
             sadm_print_status "ERROR" "Error (${RC}) returned by lvcreate command."  
             return 1
        else sadm_print_status "OK" ""                                  # Action succeeded
    fi


    # CREATE FILESYSTEM ON LOGICAL VOLUME
    if [ "$LVTYPE" = "ext3" ]
        then sadm_writelog "Running : ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME}"
             printf "${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} "
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then sadm_writelog "Error $RC with ${MKFS_EXT3}"
                     sadm_print_status "ERROR" "Error (${RC}) returned by ${MKFS_EXT3}"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
             fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_writelog "Running : ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME}"
             printf "${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME} "
             ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then sadm_writelog "Error $RC with ${MKFS_EXT4}"
                     sadm_print_status "ERROR" "Error (${RC}) returned by ${MKFS_EXT4}"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
             fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then sadm_writelog "Running : ${MKFS_XFS} -f /dev/${VGNAME}/${LVNAME}"
             printf "${MKFS_XFS} -f /dev/${VGNAME}/${LVNAME} "
             ${MKFS_XFS} -f /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then sadm_writelog "Error $RC with ${MKFS_XFS}"
                     sadm_print_status "ERROR" "Error (${RC}) returned by ${MKFS_XFS}"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
             fi
    fi

    # RUN FILESYSTEM CHECK ON THE NEWLY FILESYSTEM
    if [ "$LVTYPE" = "ext3" ]
        then sadm_writelog "Running : ${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME}"
             printf "${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME} "
             ${FSCK_EXT3} -fy /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then sadm_writelog "Error $RC with ${FSCK_EXT3}"
                     sadm_print_status "ERROR" "Error No.${RC} with ${FSCK_EXT3}"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
             fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_writelog "Running : ${FSCK_EXT4} -f /dev/${VGNAME}/${LVNAME}"
             printf "${FSCK_EXT4} -f /dev/${VGNAME}/${LVNAME} "
             ${FSCK_EXT4} -fy /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then sadm_writelog "Error $RC with ${FSCK_EXT4}"
                     sadm_print_status "ERROR" "Error No.${RC} with ${FSCK_EXT4}"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
             fi
    fi
    if [ "$LVTYPE" = "xfs" ]
        then sadm_writelog "Running : ${XFS_REPAIR} -n /dev/${VGNAME}/${LVNAME}"
             printf "${XFS_REPAIR} -n /dev/${VGNAME}/${LVNAME} "
             ${XFS_REPAIR} -n /dev/${VGNAME}/${LVNAME} >> $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then sadm_writelog "Error $RC with ${XFS_REPAIR}"
                     sadm_print_status "ERROR" "Error No.${RC} with ${XFS_REPAIR}"  
                     return 1
                else sadm_print_status "OK" ""                          # Action succeeded
             fi
    fi
       
    # MAKE DIRECTORY MOUNT POINT
    sadm_writelog "Running : mkdir -p ${LVMOUNT}"
    printf "mkdir -p ${LVMOUNT} "
    mkdir -p ${LVMOUNT} >> $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_writelog "Error $RC with ${LVMOUNT}"
             sadm_print_status "ERROR" "Error No.${RC} with ${LVMOUNT}"  
             return 1
        else sadm_print_status "OK" ""                                  # Action succeeded
    fi

    # ADD MOUNT POINT TO /ETC/FSTAB
    sadm_writelog "Running : Adding mount point in $FSTAB"
    printf "Adding mount point to $FSTAB\n"
    if [ "$LVTYPE" = "ext3" ]
       then if [ "$(sadm_get_osmajorversion)" -lt 6 ]
               then echo "/dev/${VGNAME}/${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'>>$FSTAB
                    echo "/dev/${VGNAME}/${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'
               else echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'>>$FSTAB
                    echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'
            fi
    fi
    if [ "$LVTYPE" = "ext4" ]
       then echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext4 defaults 1 2"}'>>$FSTAB
            echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext4 defaults 1 2"}'
    fi
    if [ "$LVTYPE" = "xfs" ]
       then echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"xfs  defaults 1 2"}'>>$FSTAB
            echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"xfs  defaults 1 2"}'
    fi
    sadm_writelog "Running : Sort /etc/fstab so that all mounts points are in the right order"
    printf "Sort /etc/fstab so that all mounts points are in the right order "
    awk '! /^#/ && !/^$/ { printf "%03d %s\n", length($2), $0 }' $FSTAB |sort > $WFSTAB
    awk '{ printf "%-30s %-30s %s %s %-3s %-3s\n",$2,$3,$4,$5,$6,$7}' $WFSTAB > $FSTAB 
    sadm_print_status "OK" ""                                           # Action succeeded

    # Make sure /etc/fstab have the right owner and permission
    sadm_writelog "Make sure $FSTAB is own by root user/group and permission are at 644" 
    printf "Make sure $FSTAB is own by root user/group and permission are at 644 "
    chmod 644 $FSTAB && chown root.root $FSTAB                          # Change Owner & Permission
    if [ $? -ne 0 ]                                                     # Error Creating FSTAB Work
        then sadm_writelog "Error change owner/group or permission on $FSTAB"  
             printf "${red} [ERROR]${reset} Error change owner/group or permission on $FSTAB\n"
             sadm_print_status "ERROR" "Error change owner/group or permission on $FSTAB"  
             return 1                                                   # Return Error to caller
        else sadm_print_status "OK" ""                                # Action succeeded
    fi 
    
    # MOUNT NEW FILESYSTEM
    sadm_writelog "Running : mount ${LVMOUNT}"
    printf "mount ${LVMOUNT} "
    mount ${LVMOUNT} >> $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_writelog "Error $RC with mounting ${LVMOUNT}"
             sadm_print_status "ERROR" "Error No.${RC} with mounting ${LVMOUNT}"  
             return 1
        else sadm_print_status "OK" ""                                  # Action succeeded
    fi
    
    # CHANGE OWNER OF FILESYSTEM
    sadm_writelog "Running : chown${LVOWNER}:${LVGROUP} ${LVMOUNT}"
    printf "chown ${LVOWNER}:${LVGROUP} ${LVMOUNT} "
    chown ${LVOWNER}:${LVGROUP} ${LVMOUNT} >> $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_writelog "Error $RC with chown"
             sadm_print_status "ERROR" "Error No.${RC} with chown on ${LVMOUNT}"  
             return 1
        else sadm_print_status "OK" ""                                  # Action succeeded
    fi
    
    # CHANGE PROTECTION OF FILESYSTEM
    sadm_writelog "Running : chmod ${LVPROT} ${LVMOUNT}"
    printf "chmod ${LVPROT} ${LVMOUNT} "
    chmod ${LVPROT} ${LVMOUNT} >> $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_writelog "Error $RC with chmod"
             sadm_print_status "ERROR" "Error No.${RC} with chmod on ${LVMOUNT}"  
             return 1
        else sadm_print_status "OK" ""                                  # Action succeeded
    fi

    return 0
}



#---------------------------------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------------------------------
setlvm_path
create_vglist
