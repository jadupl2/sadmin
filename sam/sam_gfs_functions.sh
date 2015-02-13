#! /bin/bash
##########################################################################
# Shellscript:	sam_gfs.sh - Contains gfs related functions
# Version    :	1.2
# Author     :	jacques duplessis 
# Date       :	2007-12-20
# Requires   :	bash shell - cluster installed
# Category   :	gfs filesystem tools
# SCCS-Id.   :	@(#) sam_gfs.sh 1.2 07.12.20
##########################################################################
# Description
#
#
##########################################################################
#set -x



# Global Variables Logical Volume Information 
# ------------------------------------------------------------------------------
SAM=/sysadmin/sam               ; export SYSADM     # where reside pgm & data
LVNAME=""			            ; export LVNAME     # Logical Volume Name
LVSIZE=""                       ; export LVSIZE     # Logical Volume Size
VGNAME=""                       ; export VGNAME     # Volume Group Name
VGFREE=""                       ; export VGFREE     # VG Free Space in MB
LVTYPE=""                       ; export LVTYPE     # Lv type ext3 swap
LVMOUNT=""                      ; export LVMOUNT    # LV mount point
LVOWNER=""                      ; export LVOWNER    # LV Mount point owner
LVGROUP=""                      ; export LVGROUP    # LV Mount point group
LVPROT=""                       ; export LVPROT     # LV Mount point protection
LVJNL=""                        ; export LVJNL      # GFS Number of Journal
STDERR=/$SAM/tmp/stderr.$$	    ; export STDERR     # Output of Standard Error
STDOUT=/$SAM/tmp/stdout.$$      ; export STDOUT     # Output of Standard Output
BATCH_MODE=0                    ; export BATCH_MODE # 0=Not in Batch 1=Batch MOde
LOGFILE=$SAM/sam.log            ; export LOGFILE    # Program execution log
FSTAB=/etc/fstab                ; export FSTAB      # Filesystem Table file
WFSTAB=$SAM/tmp/fstab.wrk       ; export WFSTAB     # Filesystem Table Work file
TUNE2FS="/sbin/tune2fs"	        ; export TUNE2FS    # Tune2fs Command Path
MKFS_GFS="/sbin/gfs_mkfs"	    ; export MKFS_GFS   # GFS mkfs command path
MKFS_EXT3="/sbin/mkfs.ext3"	    ; export MKFS_EXT3  # ext3 mkfs command path
FSCK_EXT3="/sbin/fsck.ext3"	    ; export FSCK_EXT3  # ext3 fsck command path 
FSCK_GFS="/sbin/gfs_fsck"	    ; export FSCK_GFS   # GFS fsck command path 
GFS_GROW="/sbin/gfs_grow"	    ; export GFS_GROW   # GFS GROW command path 
GFS_JADD="/sbin/gfs_jadd" 	    ; export GFS_JADD   # GFS Add Journal Command
LVCHANGE="/usr/sbin/lvchange"	; export LVCHANGE   # lvchange command path 
MKDIR="/bin/mkdir"	            ; export MKDIR      # mkdir command path
MOUNT="/bin/mount"	            ; export MOUNT      # mount command path
CHMOD="/bin/chmod"	            ; export CHMOD      # chmod command path
CHOWN="/bin/chown"	            ; export CHOWN      # chown command path
GFSTOOL="/sbin/gfs_tool"        ; export GFSTOOL    # GFS Tool command
CP="/bin/cp"	                ; export CP         # cp command path
MAXLEN_LV=14                    ; export MAXLEN_LV  # Max Char for LV Name
VGLIST="$SAM/tmp/vglist.$$"     ; export VGLIST     # List of VG on system
CLUSTAT="/usr/sbin/clustat"     ; export CLUSTAT

# Declare mount & unmount array - Used in filesystem size increase
declare -a mount_array

#
# Delete old Temporary file in $SAM/tmp directory
find $SAM/tmp -type f -mtime +2 -exec rm {} \; >/dev/null 2>&1

# Determine if we are using lvm1 or lvm2
# ------------------------------------------------------------------------------
LVMVER=1                        ; export LVMVER     # Assume lvm1 by default
rpm -q lvm2 > /dev/null 2>&1                        # Is lvm2 installed ?
RC=$?                                               # RC = 0 = yes lvm2
if [ $RC -eq 0 ] ; then LVMVER=2 ; fi               # lvm2 install set lvm2 on


# Setup Path for programs depending of LVM Version
# ------------------------------------------------------------------------------
if [ $LVMVER -eq 2 ]
   then LVCREATE="/usr/sbin/lvcreate"			; export LVCREATE
        LVEXTEND="/usr/sbin/lvextend"           ; export LVEXTEND
        LVSCAN="/usr/sbin/lvscan"               ; export LVSCAN
        EXT2ONLINE="/usr/sbin/ext2online"       ; export EXT2ONLINE
        RESIZE2FS="/sbin/resize2fs"             ; export RESIZE2FS
        VGDIR="/etc/lvm/backup"                 ; export VGDIR
   else LVCREATE="/sbin/lvcreate"				; export LVCREATE
        LVEXTEND="/sbin/lvextend"               ; export LVEXTEND
        LVSCAN="/sbin/lvscan"                   ; export LVSCAN
        RESIZE2FS="/sbin/resize2fs"             ; export RESIZE2FS
        VGDIR="/etc/lvmtab.d"                   ; export VGDIR
fi





# make sure the output and work file does not exist
# ------------------------------------------------------------------------------
rm -f $VGLIST >/dev/null 2>&1




# ------------------------------------------------------------------------------
# This function create a file that contains a list of volume group on the system
# ------------------------------------------------------------------------------
create_vglist()
{
   ls -1 $VGDIR | sort >  $VGLIST
}



# ------------------------------------------------------------------------------
# This function verify if a volume group exist on the system
# ------------------------------------------------------------------------------
vgexist()
{
   vg2check=$1 
   create_vglist
   grep -i $vg2check $VGLIST > /dev/null 2>&1
   vgrc=$? 
   return $vgrc
}


# ------------------------------------------------------------------------------
# This function verify if a logical volume exist on the system
# ------------------------------------------------------------------------------
lvexist()
{
   lv2check=$1
   grep -E "^\/dev" $FSTAB|awk '{ print $1 }'|awk -F/ '{ print $NF }'|grep "^${lv2check}$" >/dev/null
   lvrc=$?
   #mess "Return code is $lvrc "
   return $lvrc
}


# ------------------------------------------------------------------------------
# This function get the volume group information
# ------------------------------------------------------------------------------
getvg_info()
{
   vgsize=`vgdisplay $VGNAME | grep -i free | awk '{ print $7 }'`
   vgunit=`vgdisplay $VGNAME | grep -i free | awk '{ print $8 }'`
   if [ $vgunit = "GB" ]
      then vgint=`echo "$vgsize * 1024" | /usr/bin/bc  | awk -F'.' '{ print $1 }'`
      else vgint=$( echo $vgsize | awk -F'.' '{ print $1 }' )
    fi
    VGFREE=$vgint

}


# ------------------------------------------------------------------------------
# This function Check if mount point is already in /etc/fstab
# ------------------------------------------------------------------------------
mntexist()
{
   mnt2check=$1
   grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' | grep "^${mnt2check} ">/dev/null
   mntrc=$?
   return $mntrc
}


# -------------------------------------------------------------------------------------
# Umount Filesystems (if any) that need to be unmounted to increase desired filesystem
# -------------------------------------------------------------------------------------
remount_prereq_unmount()
{
    windex=0
    while [ $windex -lt ${#mount_array[@]} ]
          do
          write_log "Mounting ${mount_array[$windex]}"
          mount ${mount_array[$windex]} >/dev/null 2>&1
          let "windex+=1"
          done
}


# -------------------------------------------------------------------------------------
# Umount Filesystems (if any) that need to be unmounted to increase desired filesystem
# -------------------------------------------------------------------------------------
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
      then write_log "No unmount are pre-requisite to this task." 
           return 0
   fi

# Subtract one from number of mount (remove the one specified by user)
   #let "NBMOUNT-=1"
   write_log "I Will need to umount $NBMOUNT filesystem(s) before increasing $LVMOUNT" 


# Process all filesystems that need to be unmounted before the task
   windex=0
   for wmount in `awk '{ print $2 }' $FSTAB | grep "${LVMOUNT}/"`
       do

# For every filesystem that used the mount point and length is greater than original
       if [ ${#wmount} -gt ${#LVMOUNT} ]
          then mount | grep "$wmount" > /dev/null 2>&1
               if [ $? -eq 0 ]
                  then mount_array[$windex]=${wmount}
                       write_log "unmount ${mount_array[$windex]}"
                       umount ${mount_array[$windex]} >/dev/null 2>&1
                       if [ $? -ne 0 ]
                          then write_log "Executing lsof command and searching for ${mount_array[$windex]}"
                               lsof   | grep -v grep | grep -i ${mount_array[$windex]} | tee -a $LOGFILE
                               write_log "Executing ps -ef and search for ${mount_array[$windex]}"
                               ps -ef | grep -v grep | grep -i ${mount_array[$windex]} | tee -a $LOGFILE
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


# ------------------------------------------------------------------------------
# This function based on MountPoint set Global Variable (VGNAME, LVNAME, ...) 
# ------------------------------------------------------------------------------
get_mntdata()
{
   mnt2get=$1
   grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' |grep "^${mnt2get} " >/dev/null
   mntget_rc=$?
   if [ $mntget_rc -ne 0 ] ; then return $mntget_rc ; fi
   
   LVMOUNT=$mnt2get
   LVLINE=`grep "^/dev/" $FSTAB | grep "${mnt2get} "`
   LVNAME=`echo $LVLINE | awk -F/ '{ print $4 }'  | tr -d " "`
   VGNAME=`echo $LVLINE | awk -F/ '{ print $3 }'`
   LVTYPE=`echo $LVLINE | awk     '{ print $3 }' | tr [a-z] {A-Z]`

   if [ $LVMVER -eq 2 ]
      then LVLINE=`$LVSCAN | grep "'/dev/${VGNAME}/${LVNAME}'"`
           LVWS1=$( echo $LVLINE  | awk -F'[' '{ print $2 }' )
           LVWS2=$( echo $LVWS1   | awk -F']' '{ print $1 }' )
           LVFLT=$( echo $LVWS2   | awk '{ print $1 }' )
           LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )
           if [ "$LVUNIT" = "GB" ]
              then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc |awk -F'.' '{ print $1 }'`
                   LVSIZE=$LVINT
              else LVINT=$( echo $LVFLT | awk -F'.' '{ print $1 }' )
                   LVSIZE=$LVINT
           fi
      else LVLINE=`$LVSCAN | grep "/dev/${VGNAME}/${LVNAME}\""`
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

# Get Actual Number of Journal for the GFS
   LVJNL=`$GFSTOOL df $LVMOUNT | grep -i journals | awk '{ print $3 }'` 
}



# ------------------------------------------------------------------------------
# This function validate if data is ok to create the filesystem 
# ------------------------------------------------------------------------------
data_creation_valid()
{

# Volume Group must exist
   if ! vgexist $VGNAME
      then write_log "Filesystem Creation - Volume Group $VGNAME does not exist"
           return 1
   fi

# Logical Volume name must not exist
   if lvexist $LVNAME
      then write_log "The LV name ${LVNAME} already exist"
           return 1
   fi 

# Logical Volume Name must be specified
   if [ ${#LVNAME} -eq 0 ] 
      then write_log "No Valid LV name is specify"
           return 1
   fi

# Logical Volume name 
   if [ ${LVNAME:0:1} = " " ] 
      then write_log "First charecter of the Logical Volume name must not be blank"
           return 1
   fi

# Logical Volume size must be at least 32 Mb
   if [ ${LVSIZE} -lt 32 ] 
      then write_log "Filesystem size must greater then 32 MB"
           return 1
   fi

# Logical Volume type must be Ext3 Xjfs Jfs or Reiserfs
   if [ $LVTYPE != "E" ] && [ $LVTYPE != "X" ] [ $LVTYPE != "J" ] [ $LVTYPE != "R" ]
      then write_log "Filesystem type must be Ext3 Xfs Jfs or Reiserfs - Not $LVTYPE"
           return 1
   fi

# Validate Mount Point
   if mntexist $LVMOUNT
      then write_log "Mount Point $LVMOUNT already exist"
           return 1
   fi

   return 0
}




# ------------------------------------------------------------------------------
# This function Check if mount point is valid
# Check if first character is a slash
# ------------------------------------------------------------------------------
mntvalid()
{
   mnt2valid=$1 
   mnt2validrc=0
   wchar=${mnt2valid:0:1}
   if [ $wchar != "/" ] ; then mnt2validrc=1 ; fi 
   return ${mnt2validrc}
}





# ------------------------------------------------------------------------------
# Function called to display message and write it at the same time in the log
# ------------------------------------------------------------------------------
write_log()
{
     WMESS=$1 
     WDATE=$(date "+%C%y.%m.%d %H:%M:%S")
     echo -e "$WMESS"
     echo -e "$WDATE - $WMESS" >> $LOGFILE
}




# ------------------------------------------------------------------------------
# Function called when an error occured when trying to create a filesystem
# ------------------------------------------------------------------------------
report_error()
{
     WMESS=$1
     WDATE=$(date "+%C%y.%m.%d %H:%M:%S")

# Write the error in the log file
     echo -e "$WDATE - $WMESS" >> $LOGFILE

# If in interactive mode - Advise user before proceeding
     if [ $BATCH_MODE -eq 0 ]
        then echo -e "$WMESS"
             echo -e "\a\aPress [ENTER] to continue - CTRL-C to Abort\c"
             read dummy 
     fi
}



# ------------------------------------------------------------------------------
# Sort /etc/fstab so that all mounts points are in order.
# ------------------------------------------------------------------------------
fix_cluster_fstab()
{


# Make sure we have a backup of /etc/fstab before doing some change
# ------------------------------------------------------------------------------
        rcode=0

# Create a new /etc/wstab sorted based on the lenght of the mount point
#   - First field is lenght of mount point
#   - Second field is the normal line
# ------------------------------------------------------------------------------
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."

        WNOW=`date +%Y_%m_%d_%H_%M_%S`
        cmd="$CP $FSTAB ${FSTAB}.${WNOW}"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error changing mode of fstab on $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
 
        cmd="awk '! /^#/ && !/^\$/ { printf \"%03d %s\n\", length(\$2), \$0 }' $FSTAB |sort > $WFSTAB"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error fixing fstab (1) on node $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   

        
# Recreate the /etc/fstab sorted by mount point length
# ------------------------------------------------------------------------------
        cmd="awk '{ printf \"%-30s %-30s %s %s %-3s %-3s\\n\",\$2,\$3,\$4,\$5,\$6,\$7}' $WFSTAB >$FSTAB"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error fixing fstab (2) on node $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        

# Make sure /etc/fstab is only by modified by root
# ------------------------------------------------------------------------------
        cmd="$CHMOD 644 $FSTAB"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
               report_error "Error changing mode of fstab on $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        
# Make sure /etc/fstab in own by root
# ------------------------------------------------------------------------------
        cmd="$CHOWN root.root $FSTAB"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error changing owner of fstab on $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   

        done
     return $rcode
}




# ------------------------------------------------------------------------------
# Create Mount point on every Nodes in the cluster
# ------------------------------------------------------------------------------
create_mount_point_on_cluster()
{
    rcode=0
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."
        cmd="mkdir -p $LVMOUNT"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error creating mount point $LVMOUNT on $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        done
    return $rcode
}



# ------------------------------------------------------------------------------
# Mount Filesystem on every nodes in the cluster
# ------------------------------------------------------------------------------
mount_gfs_on_cluster()
{
    rcode=0
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."
        cmd="mount $LVMOUNT"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error mounting $LVMOUNT on $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        done
    return $rcode
}






# ------------------------------------------------------------------------------
# Remove Mount point on every Nodes in the cluster
# ------------------------------------------------------------------------------
remove_mount_point_on_cluster()
{
    rcode=0
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."
        cmd="rmdir $LVMOUNT"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error removing mount point $LVMOUNT on $wnode"
                rcode=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        done
    return $rcode
}



# ------------------------------------------------------------------------------
# Unount GFS on every Nodes in the cluster
# ------------------------------------------------------------------------------
umount_filesystem_on_cluster()
{

    rcode=0
    echo "Unmount filesystem on the cluster" 
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."
        cmd="umount $LVMOUNT"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
#        if [ $? -ne 0 ]
#           then if [ $DEBUG ] ; then echo " ERROR" ; fi
#                report_error "Error unmount $LVMOUNT on $wnode"
#                rcode=1
#                break 
#           else if [ $DEBUG ] ; then echo " OK" ; fi
#        fi   
        done
    return $rcode
}




# ------------------------------------------------------------------------------
# Function called to Add GFS Journal
# ------------------------------------------------------------------------------
add_journal()
{

# Extend the logical volume
  let LVSIZE=$NBJNL*256
  write_log "$LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME"
  $LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME 1> $STDOUT 2> $STDERR
  ERRCODE="$?"
  if [ "$ERRCODE" -ne 0 ]
     then cat $STDOUT $STDERR | tee -a $LOGFILE
          report_error "Error on lvextend /dev/$VGNAME/$LVNAME"
          return 1
  fi
 
# GFS Grow the filesystem
  write_log "$GFS_JADD -j $NBJNL $LVMOUNT" 
  $GFS_JADD -j $NBJNL $LVMOUNT 
  EN=$?
  if [ $EN -ne 0 ] 
     then cat $STDOUT $STDERR | tee -a $LOGFILE
          report_error "Error on $GFS_JADD -j $NBJNL $LVMOUNT"
          return 1
  fi 
  return 0
}




# ------------------------------------------------------------------------------
# Function called to Expand a filesystem
# ------------------------------------------------------------------------------
extend_gfs()
{

# Extend the logical volume
  write_log "$LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME"
  $LVEXTEND -L+${LVSIZE} /dev/$VGNAME/$LVNAME 1> $STDOUT 2> $STDERR
  ERRCODE="$?"
  if [ "$ERRCODE" -ne 0 ]
     then cat $STDOUT $STDERR | tee -a $LOGFILE
          report_error "Error on lvextend /dev/$VGNAME/$LVNAME"
          remount_prereq_unmount
          return 1
  fi
 
# GFS Grow the filesystem
  write_log "$GFS_GROW $LVMOUNT" 
  $GFS_GROW $LVMOUNT 
  EN=$?
  if [ $EN -ne 0 ] 
     then cat $STDOUT $STDERR | tee -a $LOGFILE
          report_error "Error on gfs_grow $LVMOUNT"
          return 1
  fi 
  return 0
}






# ------------------------------------------------------------------------------
# Function called to write code to be run at the end to ; 
#    o delete entries in /etc/fstab
#    o Remove the old logical volume 
#    o Remove mount point
# ------------------------------------------------------------------------------
remove_gfs()
{


# Umount GFS filesystem on all nodes
     umount_filesystem_on_cluster
   
# Deactivate GFS First 
     cmd="$LVCHANGE -an /dev/${VGNAME}/${LVNAME} "
     write_log "\nRunning : $cmd"
     if [ $DEBUG ] ; then echo -n "$cmd" ; fi
     $cmd  1>> $STDOUT 2>>$STDERR
     if [ $? -ne 0 ]
        then if [ $DEBUG ] ; then echo " ERROR" ; fi
             cat $STDOUT $STDERR | tee -a $LOGFILE
             report_error "Error deactivating /dev/${VGNAME}/${LVNAME} logical volume"
             mount ${LVMOUNT} 
             return 1
        else if [ $DEBUG ] ; then echo " OK" ; fi
     fi   
        
# Remove the logical Volume
     cmd="lvremove -f /dev/${VGNAME}/${LVNAME}  "
     write_log "Running : $cmd"
     if [ $DEBUG ] ; then echo -n "$cmd" ; fi
     $cmd  1>> $STDOUT 2>>$STDERR
     if [ $? -ne 0 ]
        then if [ $DEBUG ] ; then echo " ERROR" ; fi
             cat $STDOUT $STDERR | tee -a $LOGFILE
             report_error "Error removing /dev/${VGNAME}/${LVNAME} logical volume"
             mount ${LVMOUNT} 
             return 1
        else if [ $DEBUG ] ; then echo " OK" ; fi
     fi   

# Remove mount point in /etc/fstab on all the nodes
    write_log "\nRunning : Removing mount point in $FSTAB on all cluster nodes"
    remove_fstab
    if [ "$?" -ne 0 ] ; then report_error "Error $RC while updating $FSTAB" ; return 1 ;  fi
    
# Remove mount point on all the nodes
    write_log "\nRunning : rmdir ${LVMOUNT} on the cluster nodes"
    remove_mount_point_on_cluster 
    if [ "$?" -ne 0 ] ; then report_error "Error $RC with rmdir\n `cat $STDERR`" ; return 1 ;  fi

}





# ------------------------------------------------------------------------------
# Filesysten Check Function
# ------------------------------------------------------------------------------
gfs_fsck()
{

# Check to see if any filesystem must be unmounted first
    write_log "Checking if any other unmount need to be done"
    prereq_unmount
    if [ $? -ne 0 ]
        then remount_prereq_unmount
             return 1
    fi
                                                                                                                             
# Filesystem got to be unmounted first
    mount | grep "${LVMOUNT} "  > /dev/null 
    if [ $? -eq 0 ] 
       then write_log "Unmounting ${LVMOUNT} "
            umount ${LVMOUNT}  1> $STDOUT 2> $STDERR
            if [ $? -ne 0 ]
               then cat $STDOUT $STDERR | tee -a $LOGFILE
                    report_error "Error unmounting ${LVMOUNT}"
                    remount_prereq_unmount
                    return 1
            fi
    fi
                                                                                                                             
# Run filesystem check on filesystem
    write_log "$FSCK_GFS -y /dev/$VGNAME/$LVNAME"
    $FSCK_GFS -y /dev/$VGNAME/$LVNAME 1> $STDOUT 2> $STDERR
    if [ $? -ne 0 ]
       then cat $STDOUT $STDERR | tee -a $LOGFILE
            report_error "Error on fsck /dev/$VGNAME/$LVNAME"
    fi

# Remount unmounted filesystem
    write_log "Mounting ${LVMOUNT} "
    mount ${LVMOUNT}
    if [ $? -ne 0 ]
       then cat $STDOUT $STDERR | tee -a $LOGFILE
            report_error "Error Mounting ${LVMOUNT}"
            remount_prereq_unmount
            return 1
    fi


# If any unmount had to be done prior to increase, remount then now
     remount_prereq_unmount
     return 0  
}



# ------------------------------------------------------------------------------
# Change Filesystem Owner
# ------------------------------------------------------------------------------
change_owner()
{

# Changing the owner and the group of the mount point
    RC=0
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."
        cmd="${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT}"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error $RC with $cmd on $wnode.\n `cat $STDERR`"
                RC=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        done
    if [ "$RC" -ne 0 ] ; then report_error "Error when $cmd\n `cat $STDERR`" ; return 1 ;  fi
        
# Changing the protection on the mount point on all the nodes.
    write_log "\nRunning : ${CHMOD} ${LVPROT} ${LVMOUNT} on all the nodes"
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."
        cmd="${CHMOD} ${LVPROT} ${LVMOUNT}"
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error $RC with $cmd on $wnode.\n `cat $STDERR`"
                RC=1
                break 
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        done
    if [ "$RC" -ne 0 ] ; then report_error "Error when $cmd\n `cat $STDERR`" ; return 1 ;  fi
    return 0
}


# ------------------------------------------------------------------------------
# Add Entry in /etc/fstab
# ------------------------------------------------------------------------------
update_fstab()
{
    RC=0
    for wnode in `cat $CNODEFILE`
        do 
        echo -n "$wnode.."
        if [ "$CR_CM" = "Y" ] 
           then cmd=`echo "echo \"/dev/${VGNAME}/${LVNAME} ${LVMOUNT} gfs noauto   0 0\">>$FSTAB"`
           else cmd=`echo "echo \"/dev/${VGNAME}/${LVNAME} ${LVMOUNT} gfs defaults 0 0\">>$FSTAB"`
        fi 
        if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
        ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
        if [ $? -ne 0 ]
           then if [ $DEBUG ] ; then echo " ERROR" ; fi
                report_error "Error creating mount point $LVMOUNT on $wnode"
                RC=1
                break
           else if [ $DEBUG ] ; then echo " OK" ; fi
        fi   
        done
    if [ "$RC" -ne 0 ] ; then report_error "Error when adding mount point in ${FSTAB}\n `cat $STDERR`" ; return 1 ;  fi
    return 0

}




# ------------------------------------------------------------------------------
# Remove Entry in /etc/fstab
# ------------------------------------------------------------------------------
remove_fstab()
{
     RC=0
     for wnode in `cat $CNODEFILE`
         do 
         echo -n "$wnode.."
         cmd="grep -vi \"^/dev/${VGNAME}/${LVNAME}\" $FSTAB > $WFSTAB"
         if [ $DEBUG ] ; then echo -n "ssh $wnode $cmd" ; fi
         ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
         if [ $? -ne 0 ]
            then if [ $DEBUG ] ; then echo " ERROR" ; fi
                 report_error "Error removing /dev/${VGNAME}/${LVNAME} in $FSTAB on node $wnode"
                 RC=1
                 break
            else if [ $DEBUG ] ; then echo " OK" ; fi
         fi   
 
         cmd="cp $WFSTAB $FSTAB ; $CHMOD 644 $FSTAB ; $CHOWN root.root $FSTAB"
         ssh $wnode "$cmd"  1>> $STDOUT 2>>$STDERR
         if [ $? -ne 0 ]
            then if [ $DEBUG ] ; then echo " ERROR" ; fi
                 report_error "cp $WFSTAB $FSTAB;$CHMOD 644 $FSTAB;$CHOWN root.root $FSTAB on node $wnode"
                 RC=1
                 break
            else if [ $DEBUG ] ; then echo " OK" ; fi
         fi   
         done

    if [ "$RC" -ne 0 ]
       then report_error "Error when removing mount point in ${FSTAB}\n `cat $STDERR`"
           return 1
    fi
    return 0
}




# ------------------------------------------------------------------------------
# Create filesystem function
# ------------------------------------------------------------------------------
create_gfs()
{

    if [ "$DEBUG" = "5" ] 
       then write_log "\n-----------------------------"
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
            echo "CR_REAL_SIZE= $CR_REAL_SIZE"
            write_log "\n-----------------------------"
    fi
    
# If logical volume name is greater than MAXLEN_LV char - then remove char overflow 
    if [ ${#LVNAME} -gt ${MAXLEN_LV} ] 
       then write_log "The Logical volume name ${LVNAME} ${#LVNAME} char is too long"
            LVNAME=`echo "${LVNAME}" | cut -c1-${MAXLEN_LV}`
            write_log "It has been changed to ${LVNAME}"
    fi 


# Check if logical volume name already exist - chop it and 2 numbers at the end
    grep -E "^\/dev" $FSTAB | awk '{ print $1 }' | awk -F/ '{ print $4 }'| grep $LVNAME >/dev/null 
    RC=$?
    if [ $RC -eq 0 ]
       then write_log "The LV name ${LVNAME} already exist"
            NUMBER=100
            while [ $NUMBER -gt 99 ]  
                  do 
                  NUMBER=$RANDOM 
                  done
            WLVNAME=`echo "${LVNAME}" | cut -c1-12`
            LVNAME=`echo "${WLVNAME}${NUMBER}"`
            write_log "It has been changed with random number ${NUMBER} to ${LVNAME}"
     fi 
    

# Check if mount point is already in /etc/fstab
    grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' | grep "^${LVMOUNT} ">/dev/null
    RC=$?
    if [ $RC -eq 0 ]
       then report_error "The mount point $LVMOUNT already exist in $FSTAB"
            return 1
    fi 


# Creating the Logical Volume
    cmd="${LVCREATE} -L${CR_REAL_SIZE}M -n ${LVNAME} ${VGNAME}"
    write_log "Running : $cmd"
    if [ $DEBUG ] ; then echo -n "$cmd" ; fi
    $cmd 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ]
       then if [ $DEBUG ] ; then echo " ERROR" ; fi
            report_error "Error $RC with ${LVCREATE} \n `cat $STDERR`"
            RC=1
       else if [ $DEBUG ] ; then echo " OK" ; fi
    fi   
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with lvcreate\n `cat $STDERR`" ; return 1 ;  fi


# Creating the GFS on the logical volume    
    cmd="$MKFS_GFS -O -p lock_dlm -t ${CNAME}:${LVNAME} -j $CR_JL /dev/${VGNAME}/${LVNAME}"
#    cmd="$MKFS_GFS -O -p lock_nolock -t ${CNAME}:${LVNAME} -j $CR_JL /dev/${VGNAME}/${LVNAME}"
    write_log "Running : $cmd"
    if [ $DEBUG ] ; then echo "$cmd" ; fi
    $cmd 
    RC=$?
    if [ "$RC" -ne 0 ]
       then if [ $DEBUG ] ; then echo " ERROR" ; fi
            report_error "Error $RC with gfs_mkfs \n `cat $STDERR`"
            RC=1
       else if [ $DEBUG ] ; then echo " OK" ; fi
    fi   
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with gfs_mkfs \n `cat $STDERR`" ; return 1 ;  fi

    
# Create mount point on all the nodes
    write_log "\nRunning : ${MKDIR} -p ${LVMOUNT} on the cluster nodes"
    create_mount_point_on_cluster 
    if [ "$?" -ne 0 ] ; then report_error "Error $RC with mkdir\n `cat $STDERR`" ; return 1 ;  fi


# Add mount point in /etc/fstab on all the nodes
    write_log "\nRunning : Adding mount point in $FSTAB on all cluster nodes"
    update_fstab
    if [ "$?" -ne 0 ] ; then report_error "Error $RC while updating /etc/fstab" ; return 1 ;  fi
     
   
# Make all entries in the /etc/fstab in the right mount point order
    write_log "\nRunning : Sort /etc/fstab so that all mounts points are in the right order"
    fix_cluster_fstab
    if [ "$?" -ne 0 ] ; then report_error "Error while fixing fstab\n `cat $STDERR`" ; return 1 ;  fi

# Changing the owner and the group of the mount point
    write_log "\nRunning : ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT} on all the nodes"
    change_owner
    if [ "$?" -ne 0 ] ; then report_error "Error while change owner on ${LMOUNT}\n `cat $STDERR`" ; return 1 ;  fi


# Mounting the new GFS 
    write_log "\nRunning : mount ${LVMOUNT} on all the nodes"
    mount_gfs_on_cluster
    if [ "$?" -ne 0 ] ; then report_error "Error while change mounting ${LMOUNT}\n `cat $STDERR`" ; return 1 ;  fi

    echo " "
    return 0
}


create_vglist
