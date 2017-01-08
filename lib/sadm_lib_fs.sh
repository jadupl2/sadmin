#!/bin/bash
#---------------------------------------------------------------------------------------------------
# Shellscript:	sadm_lib_fs.sh - Contains SADM FileSystem Related functions
# Version    :	2.0
# Author     :	jacques duplessis (duplessis.jacques@gmail.com)
# Date       :	2016-06-01
# Requires   :	bash shell - lvm installed
# Category   :	filesystem tools
# SCCS-Id.   :	@(#) sadm_lib_fs.sh 1.5 June 2016
#---------------------------------------------------------------------------------------------------
# Description
#   Library of functions to deal with various LVM commands
#
#---------------------------------------------------------------------------------------------------
#   2.0      Revisited to work with SADM environment - Jan 2017 - Jacques Duplessis
#===================================================================================================
# 
#
#---------------------------------------------------------------------------------------------------
#set -x





# Global Variables Logical Volume Information 
#---------------------------------------------------------------------------------------------------
FSTAB=/etc/fstab                            ; export FSTAB              # Filesystem Table file
WFSTAB=$SADM_TMP_DIR/fstab.wrk              ; export WFSTAB             # Filesystem Table Work file
BATCH_MODE=0                                ; export BATCH_MODE         # 0=Not in Batch 1=Batch Mode
LVNAME=""			                        ; export LVNAME             # Logical Volume Name
LVSIZE=""                                   ; export LVSIZE             # Logical Volume Size
VGNAME=""                                   ; export VGNAME             # Volume Group Name
VGFREE=""                                   ; export VGFREE             # VG Free Space in MB
LVTYPE=""                                   ; export LVTYPE             # Logical vol.type ext3 swap
LVMOUNT=""                                  ; export LVMOUNT            # Logical vol. mount point
LVOWNER=""                                  ; export LVOWNER            # Mount point owner
LVGROUP=""                                  ; export LVGROUP            # Mount point group
LVPROT=""                                   ; export LVPROT             # Mount point protection
TUNE2FS=`which tune2fs`	                    ; export TUNE2FS            # Tune2fs Command Path
MKFS_EXT3=`which mkfs.ext3`		            ; export MKFS_EXT3          # ext3 mkfs command path
FSCK_EXT3=`which fsck.ext3`		            ; export FSCK_EXT3          # ext3 fsck command path 
MKFS_EXT4=`which mkfs.ext4`		            ; export MKFS_EXT4          # ext3 mkfs command path
FSCK_EXT4=`which fsck.ext4`		            ; export FSCK_EXT4          # ext3 fsck command path 
MKDIR=`which mkdir`	       		            ; export MKDIR              # mkdir command path
MOUNT=`which mount`	        	            ; export MOUNT              # mount command path
CHMOD=`which chmod`	        	            ; export CHMOD              # chmod command path
CHOWN=`which chown`	        	            ; export CHOWN              # chown command path
LVCREATE=`which lvcreate` 			        ; export LVCREATE           # lvcreate path
LVEXTEND=`which lvextend`                   ; export LVEXTEND           # lvextend path
LVSCAN=`which lvscan`                       ; export LVSCAN             # lvscan
#EXT2ONLINE=`which ext2online`              ; export EXT2ONLINE         # ext2online path
RESIZE2FS=`which resize2fs`                 ; export RESIZE2FS          # resize2fs path
MAXLEN_LV=14                                ; export MAXLEN_LV          # Max Char for LV Name
VGLIST="$SADM_TMP_DIR/vglist.$$"            ; export VGLIST             # Contain list of VG on system
rm -f $VGLIST >/dev/null 2>&1                                           # Make sure file doesn't exist
VGDIR="/etc/lvm/backup"                     ; export VGDIR              # List if VG 
declare -a mount_array                                                  # Declare mount & unmount array 




#---------------------------------------------------------------------------------------------------
# This function create a file that contains a list of volume group on the system
#---------------------------------------------------------------------------------------------------
create_vglist()
{
   ls -1 $VGDIR | sort >  $VGLIST
}



#---------------------------------------------------------------------------------------------------
# This function verify if a volume group exist on the system
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
# This function verify if a logical volume exist on the system
#---------------------------------------------------------------------------------------------------
lvexist()
{
   lv2check=$1
   #mess  "Checking Existance of $lv2check logical Volume" 
   grep -E "^\/dev" $FSTAB|awk '{ print $1 }'|awk -F/ '{ print $NF }'|grep "^${lv2check}$" >/dev/null
   lvrc=$?
   #mess "Return code is $lvrc "
   return $lvrc
}


#---------------------------------------------------------------------------------------------------
# This function get the volume group information
#---------------------------------------------------------------------------------------------------
getvg_info()
{
   vgsize=`vgdisplay $VGNAME 2>/dev/null | grep -i free | awk '{ print $7 }'`
   vgunit=`vgdisplay $VGNAME 2>/dev/null | grep -i free | awk '{ print $8 }'`
   if [ $vgunit = "GB" ] || [ $vgunit = "GiB" ]
      then vgint=`echo "$vgsize * 1024" | /usr/bin/bc  | awk -F'.' '{ print $1 }'`
      else vgint=$( echo $vgsize | awk -F'.' '{ print $1 }' )
    fi
    VGFREE=$vgint

}


#---------------------------------------------------------------------------------------------------
# This function Check if mount point is already in /etc/fstab
#---------------------------------------------------------------------------------------------------
mntexist()
{
   mnt2check=$1
   grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' | egrep "^${mnt2check} |^${mnt2check}	">/dev/null
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

   if [ $LVMVER -eq 2 ]
      then LVLINE=`$LVSCAN 2>/dev/null | grep "'/dev/${VGNAME}/${LVNAME}'"`
           LVWS1=$( echo $LVLINE  | awk -F'[' '{ print $2 }' )
           LVWS2=$( echo $LVWS1   | awk -F']' '{ print $1 }' )
           LVFLT=$( echo $LVWS2   | awk '{ print $1 }' )
           LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )
           if [ "$LVUNIT" = "GB" ] || [ "$LVUNIT" = "GiB" ]
              then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc |awk -F'.' '{ print $1 }'`
                   LVSIZE=$LVINT
              else LVINT=$( echo $LVFLT | awk -F'.' '{ print $1 }' )
                   LVSIZE=$LVINT
           fi
      else LVLINE=`$LVSCAN 2>/dev/null | grep "/dev/${VGNAME}/${LVNAME}\""`
           LVWS1=$( echo $LVLINE | awk -F'[' '{ print $2 }' )
           LVWS2=$( echo $LVWS1  | awk -F']' '{ print $1 }' )
           LVFLT=$( echo $LVWS2 | awk '{ print $1 }' )
           LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )
           if [ "$LVUNIT" = "GB" ]
              then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc |awk -F'.' '{ print $1 }'`
                   LVSIZE=$LVINT
              else LVINT=$( echo $LVFLT | awk -F'.' '{ print $1 }' )
                   LVSIZE=$LVFLT
           fi
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
# This function validate if data is ok to create the filesystem 
#---------------------------------------------------------------------------------------------------
data_creation_valid()
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

# Logical Volume Name must be specified
   if [ ${#LVNAME} -eq 0 ] 
      then sadm_writelog "No Valid LV name is specify"
           return 1
   fi

# Logical Volume name 
   if [ ${LVNAME:0:1} = " " ] 
      then sadm_writelog "First charecter of the Logical Volume name must not be blank"
           return 1
   fi

# Logical Volume size must be at least 32 Mb
   if [ ${LVSIZE} -lt 32 ] 
      then sadm_writelog "Filesystem size must greater then 32 MB"
           return 1
   fi

# Logical Volume type must be Ext3 Xjfs Jfs or Reiserfs
   if [ $LVTYPE != "ext3" ] && [ $LVTYPE != "ext4" ] 
      then sadm_writelog "Filesystem type must be ext3 or ext4 - Not $LVTYPE"
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
   if [ $wchar != "/" ] ; then mnt2validrc=1 ; fi 
   return ${mnt2validrc}
}




#---------------------------------------------------------------------------------------------------
# Function called when an error occured when trying to create a filesystem
#---------------------------------------------------------------------------------------------------
report_error()
{
     WMESS=$1
     WDATE=$(date "+%C%y.%m.%d %H:%M:%S")

    # Write the error in the log file
     echo -e "$WDATE - $WMESS" >> $SADM_LOG

    # If in interactive mode - Advise user before proceeding
     if [ $BATCH_MODE -eq 0 ]
        then echo -e "$WMESS"
             echo -e "\a\aPress [ENTER] to continue - CTRL-C to Abort\c"
             read dummy 
     fi
}



#---------------------------------------------------------------------------------------------------
# Sort /etc/fstab so that all mounts points are in order.
#---------------------------------------------------------------------------------------------------
fix_fstab()
{
   awk '! /^#/ && !/^$/ { printf "%03d %s\n", length($2), $0 }' $FSTAB |sort > $WFSTAB
   awk '{ printf "%-30s %-30s %s %s %-3s %-3s\n",$2,$3,$4,$5,$6,$7}' $WFSTAB > $FSTAB 
   $CHMOD 644 $FSTAB
   $CHOWN root.root $FSTAB
}





#---------------------------------------------------------------------------------------------------
# Umount Filesystems (if any) that need to be unmounted to increase desired filesystem
#---------------------------------------------------------------------------------------------------
prereq_unmount()
{

# Initializing the mount array to make sure it is empty
   mount_array=( ) 

# Default value returned to caller
   prereq_return_flag=0

# Count number of time mount point is used in /etc/fstab
   NBMOUNT=`awk '{ print $2 }' $FSTAB | grep "${LVMOUNT}/" | wc -l`

# If no more than once - No need to umount other filesystems
   if [ "$NBMOUNT" -lt 2 ] 
      then sadm_writelog "No unmount are pre-requisite to this task." 
           return 0
   fi

# Subtract one from number of mount (remove the one specified by user)
   #let "NBMOUNT-=1"
   sadm_writelog "I Will need to umount $NBMOUNT filesystem(s) before increasing $LVMOUNT" 


# Process all filesystems that need to be unmounted before the task
   windex=0
   for wmount in `awk '{ print $2 }' $FSTAB | grep "${LVMOUNT}/"`
       do

# For every filesystem that used the mount point and length is greater than original
       if [ ${#wmount} -gt ${#LVMOUNT} ]
          then mount | grep "$wmount" > /dev/null 2>&1
               if [ $? -eq 0 ]
                  then mount_array[$windex]=${wmount}
                       sadm_writelog "unmount ${mount_array[$windex]}"
                       umount ${mount_array[$windex]} >/dev/null 2>&1
                       if [ $? -ne 0 ]
                          then sadm_writelog "Executing lsof command and searching for ${mount_array[$windex]}"
                               lsof   | grep -v grep | grep -i ${mount_array[$windex]} | tee -a $SADM_LOG
                               sadm_writelog "Executing ps -ef and search for ${mount_array[$windex]}"
                               ps -ef | grep -v grep | grep -i ${mount_array[$windex]} | tee -a $SADM_LOG
                               report_error "Could not unmount ${mount_array[$windex]}"
                               prereq_return_flag=1                               
                               break
                       fi
                       let "windex+=1"
               fi
       fi
   done

# If one umount failed prerq_return_flag=1 else equal 0.
   return $prereq_return_flag
}




#---------------------------------------------------------------------------------------------------
# Umount FS (if any) that need to be unmounted to increase desired filesystem
#---------------------------------------------------------------------------------------------------
remount_prereq_unmount()
{
    windex=0
    while [ $windex -lt ${#mount_array[@]} ]
          do
          sadm_writelog "Mounting ${mount_array[$windex]}"
          mount ${mount_array[$windex]} >/dev/null 2>&1
          let "windex+=1"
          done
}





#---------------------------------------------------------------------------------------------------
#               Function called to Expand a filesystem
#---------------------------------------------------------------------------------------------------
extend_fs()
{

# Check to see if any filesystem must be unmounted first
# ------------------------------------------------------------------------------
    if [ $LVMVER -eq 1 ]
       then sadm_writelog "Checking if any other unmount need to be done"
            prereq_unmount
            if [ $? -ne 0 ]
               then remount_prereq_unmount
                    return 1
            fi
    fi


# In LVM version 1 - Filesystem got to be unmounted first
# ------------------------------------------------------------------------------
  if [ $LVMVER -eq 1 ]
     then sadm_writelog "Unmounting ${LVMOUNT} "
          umount ${LVMOUNT}  > $SADM_LOG 2>&1
          if [ $? -ne 0 ] 
             then report_error "Error unmounting ${LVMOUNT}"
                  remount_prereq_unmount
             return 1
          fi
  fi 


# Extend the logical volume
# ------------------------------------------------------------------------------
  sadm_writelog "$LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME"
  $LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
  ERRCODE="$?"
  if [ "$ERRCODE" -ne 0 ] 
     then report_error "Error on lvextend /dev/$VGNAME/$LVNAME"
          remount_prereq_unmount
          return 1
  fi 


# In LVM Version 1 - Do a fsck on unmounted filesystem
# ------------------------------------------------------------------------------
  if [ $LVMVER -eq 1 ]
     then sadm_writelog "$FSCK_EXT3    -fy  /dev/$VGNAME/$LVNAME" 
          $FSCK_EXT3 -fy /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
          if [ $? -ne 0 ] 
             then report_error "Error on fsck /dev/$VGNAME/$LVNAME"
                  remount_prereq_unmount
                  return 1
          fi
  fi 

 
# Resize Filesystem 
# ------------------------------------------------------------------------------
  if [ $LVMVER -eq 1 ]
     then sadm_writelog "$RESIZE2FS        /dev/$VGNAME/$LVNAME"
          $RESIZE2FS /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
          if [ $? -ne 0 ] 
             then report_error "Error on resize /dev/$VGNAME/$LVNAME"
                  remount_prereq_unmount
                  return 1
          fi 
     else if [ "$(sadm_get_osmajorversion)" -ge 5 ] 
	         then sadm_writelog "$RESIZE2FS     /dev/$VGNAME/$LVNAME" 
                  $RESIZE2FS  /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
				  EN=$?
	         else sadm_writelog "$EXT2ONLINE    /dev/$VGNAME/$LVNAME" 
                  $EXT2ONLINE /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
				  EN=$?
	      fi
          if [ $EN -ne 0 ] 
             then if [ "$(sadm_get_osmajorversion)" -ge 5 ] 
                     then report_error "Error on ext2online /dev/$VGNAME/$LVNAME"
                     else report_error "Error on resize2fs /dev/$VGNAME/$LVNAME" 
                  fi 
                  return 1
          fi 
   fi 

# In LVM Version 1 - Do a fsck on unmounted filesystem
# ------------------------------------------------------------------------------
  if [ $LVMVER -eq 1 ]
     then sadm_writelog "$FSCK_EXT3    -fy  /dev/$VGNAME/$LVNAME" 
          $FSCK_EXT3 -fy /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
          if [ $? -ne 0 ] 
             then report_error "Error on fsck /dev/$VGNAME/$LVNAME"
                  remount_prereq_unmount
                  return 1
          fi
  fi 


# In LVM Version 1 - Remount unmounted filesystem
# ------------------------------------------------------------------------------
  if [ $LVMVER -eq 1 ]
     then sadm_writelog "Mounting ${LVMOUNT} "
          mount ${LVMOUNT} 
          if [ $? -ne 0 ] 
             then report_error "Error Mounting ${LVMOUNT}"
                  remount_prereq_unmount
                  return 1
          fi
  fi 


# If any unmount had to be done prior to increase, remount then now
# ------------------------------------------------------------------------------
  if [ $LVMVER -eq 1 ]
     then remount_prereq_unmount
  fi

}






#---------------------------------------------------------------------------------------------------
# Function called to write code to be run at the end to ; 
#    o delete entries in /etc/fstab
#    o Remove the old logical volume 
#    o Remove mount point
#---------------------------------------------------------------------------------------------------
remove_fs()
{

# Check to see if any sub filesystem must be unmounted first
# ------------------------------------------------------------------------------
sadm_writelog "Checking if any other unmount need to be done"
    prereq_unmount
    if [ $? -ne 0 ]
        then remount_prereq_unmount
             return 1
    fi

# Check filesystem is mounted - if it is umount it 
# ------------------------------------------------------------------------------
    mount | grep "${LVMOUNT} "  > /dev/null 
    if [ $? -eq 0 ] 
       then sadm_writelog "Unmounting ${LVMOUNT} "
            umount ${LVMOUNT} > $SADM_LOG 2>&1
            if [ $? -ne 0 ] 
               then report_error "Error unmounting ${LVMOUNT}"
                    return 1
            fi 
     fi

   
# Remove the logical Volume
# ------------------------------------------------------------------------------
     sadm_writelog "lvremove -f /dev/${VGNAME}/${LVNAME} "
     lvremove -f /dev/${VGNAME}/${LVNAME} > $SADM_LOG 2>&1 
     if [ $? -ne 0 ] 
        then report_error "Error removing /dev/${VGNAME}/${LVNAME} logical volume"
             mount ${LVMOUNT} 
             return 1
     fi 

# Remove entry in /etc/fstab
# ------------------------------------------------------------------------------
     sadm_writelog "Removing \" $LVMOUNT \" from $FSTAB "
#     grep "^/dev/" $FSTAB | grep -vi "${LVMOUNT} " > $WFSTAB
     grep -vi " ${LVMOUNT} " $FSTAB > $WFSTAB
     if [ $? -eq 1 ] 
        then report_error "Error removing $LVMOUNT from $FSTAB"
             return 1
     fi 
     cp $WFSTAB $FSTAB      
     $CHMOD 644 $FSTAB       
     $CHOWN root.root $FSTAB 

# If any unmount had to be done prior to removing the filesystem, remount then now
# ------------------------------------------------------------------------------
  remount_prereq_unmount
}





#---------------------------------------------------------------------------------------------------
#                   Filesysten Check Function
#---------------------------------------------------------------------------------------------------
filesystem_fsck()
{

# Check to see if any filesystem must be unmounted first
# ------------------------------------------------------------------------------
    sadm_writelog "Checking if any other unmount need to be done"
    prereq_unmount
    if [ $? -ne 0 ]
        then remount_prereq_unmount
             return 1
    fi

    
# Filesystem got to be unmounted first
# ------------------------------------------------------------------------------
    mount | grep "${LVMOUNT} "  > /dev/null 
    if [ $? -eq 0 ] 
       then sadm_writelog "Unmounting ${LVMOUNT} "
            umount ${LVMOUNT}  > $SADM_LOG 2>&1
            if [ $? -ne 0 ]
               then report_error "Error unmounting ${LVMOUNT}"
                    remount_prereq_unmount
                    return 1
            fi
    fi

    
# Run filesystem check on filesystem
# ------------------------------------------------------------------------------
    if [ "$LVTYPE" = "ext3" ]
       then sadm_writelog "$FSCK_EXT3 -fy /dev/$VGNAME/$LVNAME"
            $FSCK_EXT3 -fy /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
            if [ $? -ne 0 ]
               then report_error "Error on fsck /dev/$VGNAME/$LVNAME"
            fi
    fi
    if [ "$LVTYPE" = "ext4" ]
       then sadm_writelog "$FSCK_EXT4 -fy /dev/$VGNAME/$LVNAME"
            $FSCK_EXT4 -fy /dev/$VGNAME/$LVNAME > $SADM_LOG 2>&1
            if [ $? -ne 0 ]
               then report_error "Error on fsck /dev/$VGNAME/$LVNAME"
            fi
    fi


# Remount unmounted filesystem
# ------------------------------------------------------------------------------
    sadm_writelog "Mounting ${LVMOUNT} "
    mount ${LVMOUNT}
    if [ $? -ne 0 ]
       then report_error "Error Mounting ${LVMOUNT}"
            remount_prereq_unmount
            return 1
    fi


# If any unmount had to be done prior to increase, remount then now
# ------------------------------------------------------------------------------
     remount_prereq_unmount
     return 0  
}





#---------------------------------------------------------------------------------------------------
#                   Create filesystem function
#---------------------------------------------------------------------------------------------------
create_fs()
{

    if [ $DEBUG ] 
       then sadm_writelog "\n-----------------------------"
            echo "LINE        = $LVLINE" 
            echo "LVNAME      = $LVNAME"
            echo "OLD_LVNAME  = $OLD_LVNAME"
            echo "VGNAME      = $VGNAME" 
            echo "OLD_VGNAME  = $OLD_VGNAME" 
            echo "LVSIZE      = $LVSIZE MB" 
            echo "LVTYPE      = $LVTYPE" 
            echo "LVMOUNT     = $LVMOUNT"
            echo "OLDLVMOUNT  = $OLD_LVMOUNT"
            echo "LVTYPE      = $LVTYPE"
            echo "LVOWNER     = $LVOWNER"
            echo "LVGROUP     = $LVGROUP"
            echo "LVPROT      = $LVPROT"
    fi
    sadm_writelog "\n-----------------------------"
    
# If logical volume name is greater than MAXLEN_LV char - then remove char overflow 
# ------------------------------------------------------------------------------
    if [ ${#LVNAME} -gt ${MAXLEN_LV} ] 
       then sadm_writelog "The Logical volume name ${LVNAME} ${#LVNAME} char is too long"
            LVNAME=`echo "${LVNAME}" | cut -c1-${MAXLEN_LV}`
            sadm_writelog "It has been changed to ${LVNAME}"
    fi 


# Check if logical volume name already exist - chop it and 2 numbers at the end
# ------------------------------------------------------------------------------
    grep -E "^\/dev" $FSTAB | awk '{ print $1 }' | awk -F/ '{ print $4 }'| grep $LVNAME >/dev/null 
    RC=$?
    if [ $RC -eq 0 ]
       then sadm_writelog "The LV name ${LVNAME} already exist"
            NUMBER=100
            while [ $NUMBER -gt 99 ]  
                  do 
                  NUMBER=$RANDOM 
                  done
            WLVNAME=`echo "${LVNAME}" | cut -c1-12`
            LVNAME=`echo "${WLVNAME}${NUMBER}"`
            sadm_writelog "It has been changed with random number ${NUMBER} to ${LVNAME}"
     fi 
    

# Check if mount point is already in /etc/fstab
# ------------------------------------------------------------------------------
    grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' | grep "^${LVMOUNT} ">/dev/null
    RC=$?
    if [ $RC -eq 0 ]
       then report_error "The mount point $LVMOUNT already exist in $FSTAB"
            return 1
    fi 


# CREATE LOGICAL VOLUME
# ------------------------------------------------------------------------------
    sadm_writelog "Running : ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME}"
    ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME} > $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then report_error "Error $RC with lvcreate\n"
             return 1
    fi


# CREATE FILESYSTEM ON LOGICAL VOLUME
# ------------------------------------------------------------------------------
    if [ "$LVTYPE" = "ext3" ]
        then sadm_writelog "Running : ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} > $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then report_error "Error $RC with mkfs.ext3"
                     return 1
             fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_writelog "Running : ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME} > $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then report_error "Error $RC with mkfs.ext4"
                     return 1
             fi
    fi


# RUN FILESYSTEM CHECK ON THE NEWLY FILESYSTEM
# ------------------------------------------------------------------------------
    if [ "$LVTYPE" = "ext3" ]
        then sadm_writelog "Running : ${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT3} -fy /dev/${VGNAME}/${LVNAME} > $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then report_error "Error $RC with fsck.ext3"
                     return 1
             fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then sadm_writelog "Running : ${FSCK_EXT4} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT4} -fy /dev/${VGNAME}/${LVNAME} > $SADM_LOG 2>&1
             RC=$?
             if [ "$RC" -ne 0 ]
                then report_error "Error $RC with fsck.ext4"
                     return 1
             fi
    fi
    
    
# RUN TUNEFS to PREVENT FSCK UPON REBOOT
# ------------------------------------------------------------------------------
    sadm_writelog "Running : ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME}"
    ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME} > $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then report_error "Error $RC with tune2fs"
             return 1
    fi


# MAKE DIRECTORY MOUNT POINT
# ------------------------------------------------------------------------------
    sadm_writelog "Running : ${MKDIR} -p ${LVMOUNT}"
    ${MKDIR} -p ${LVMOUNT} > $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then report_error "Error $RC with mkdir"
             return 1
    fi


# ADD MOUNT POINT TO /ETC/FSTAB
# ------------------------------------------------------------------------------
    sadm_writelog "Running : Adding mount point in $FSTAB"
    if [ "$LVTYPE" = "ext3" ]
       then if [ "$(sadm_get_osmajorversion)" -lt 6 ]
               then echo "/dev/${VGNAME}/${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'>>$FSTAB
               else echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'>>$FSTAB
            fi
    fi
    if [ "$LVTYPE" = "ext4" ]
       then echo "/dev/mapper/${VGNAME}-${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext4 defaults 1 2"}'>>$FSTAB
    fi
    sadm_writelog "Running : Sort /etc/fstab so that all mounts points are in the right order"
    fix_fstab


# MOUNT NEW FILESYSTEM
# ------------------------------------------------------------------------------
    sadm_writelog "Running : ${MOUNT} ${LVMOUNT}"
    ${MOUNT} ${LVMOUNT} > $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then report_error "Error $RC with mount"
             return 1
    fi

    
# CHANGE OWNER OF FILESYSTEM
# ------------------------------------------------------------------------------
    sadm_writelog "Running : ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT}"
    ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT} > $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then report_error "Error $RC with chown"
             return 1
    fi
    

# CHANGE PROTECTION OF FILESYSTEM
# ------------------------------------------------------------------------------
    sadm_writelog "Running : ${CHMOD} ${LVPROT} ${LVMOUNT}"
    ${CHMOD} ${LVPROT} ${LVMOUNT} > $SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then report_error "Error $RC with chmod"
             return 1
    fi
    return 0
}

#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
create_vglist
