    #! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_fs_incr.sh [filesystem-to-increase]
#   Synopsis    :   Script designed to be called by SADM SYStem MONitor (sadm_sysmon.pl) to 
#                   automatically increase filesystem.
#                   When filesystem usage reach a level that is greater than the warning threshold 
#                   defined in SysMon configuration file (`hostname`.smon) a filesystem increase
#                   is trigger. 
#                   The filesystem increase, will occurs only if these conditions are met :
#                       1)  The name of this script 'sadm_fs_incr' must appears at the end of the 
#                           line of the chosen filesystem in `hostname`.smon file.
#                       2)  Filesystem will be increase by 10% each time they are increase.
#                       3)  No more than 2 filesystems increase will occurs in 24hours.
#                       4)  The script 'sadm_fs_incr.sh' must be present and executable in 
#                           directory "$SADMIN/bin".
#   Version     :   1.0
#   Date        :   15 May 2018
#   Requires    :   sh, lvm package and SADMIN Filesystem Library
#   This code was originally written by Jacques Duplessis,
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_05_15 JDuplessis
#   V1.0 - Initial Version
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x

#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.0'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_LOG_HEADER="Y"                        ; export SADM_LOG_HEADER     # Show/Generate Log Header
SADM_LOG_FOOTER="Y"                        ; export SADM_LOG_FOOTER     # Show/Generate Log Footer
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_USE_RCH="Y"                           ; export SADM_USE_RCH        # Update Return Code History
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#

# Load Filesystem Tool SADM Library
[ -f ${SADMIN}/lib/sadmlib_fs.sh ]  && . ${SADMIN}/lib/sadmlib_fs.sh    # Load FS SADMIN Library


#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
PN=${0##*/}                                     ; export PN                     # Script name
VER='1.8'                                       ; export VER                    # Version No.
MYHOST=`hostname -s`                            ; export MYHOST                 # Host name
OSNAME=`uname -s | tr '[A-Z]' '[a-z]'`          ; export OSNAME                 # OS Name AIX/Linux)
INST=`echo "$PN" | awk -F\. '{ print $1 }'`     ; export INST                   # script name
SLAM_DIR="/scom"                                ; export BASE_DIR               # Base Directories
SLAM_LOGDIR="${SLAM_DIR}/log"                   ; export SLAM_LOGDIR            # SLAM LOG Dir
SLAM_BINDIR="${SLAM_DIR}/bin"                   ; export SLAM_BINDIR            # SLAM Bin Dir
SLAM_SCRDIR="${SLAM_DIR}/scripts"               ; export SLAM_SCRDIR            # SLAM Script Dir
SLAM_CFGDIR="${SLAM_DIR}/cfg"                   ; export SLAM_CFGDIR            # SLAM Cfg Dir
SLAM_TMPDIR="${SLAM_DIR}/tmp"                   ; export SLAM_TMPDIR            # SLAM TMP Dir.
SLAM_CTR="${SLAM_SCR}/.fs_count"                ; export SLAM_CTR               # SLAM Counter File
WDATE=`date "+%C%y.%m.%d;%H:%M:%S"`             ; export WDATE                  # Today Date and Time
SYSADMIN="duplessis.jacques@gmail.com"              ; export SYSADMIN               # sysadmin email
SLAM_TMP_FILE1="${SLAM_TMP}/${INST}.$$"         ; export SLAM_TMP_FILE1         # Script Work file
SLAM_LOG="${SLAM_LOGDIR}/${INST}.log"           ; export SLAM_LOG               # Script log file
SLAM_MAIL="${SLAM_LOGDIR}/${INST}.txt"          ; export SLAM_MAIL              # Email data file
DASH="===================="                     ; export DASH                   # 20 dashes
DASH="${DASH}${DASH}${DASH}${DASH}\n"                                           # 80 dashes
MAX_RUN=2                                       ; export MAX_RUN                # Max increase per day
LVNAME=""			                            ; export LVNAME                 # Logical Volume Name
LVSIZE=""                                       ; export LVSIZE                 # Logical Volume Size
SIZE2ADD=""                                     ; export SIZE2ADD               # MB 2 add to Filesystem
VGNAME=""                                       ; export VGNAME                 # Volume Group Name
VGSIZE=""                                       ; export VGSIZE                 # Volume Group Size in GB
VGFREE=""                                       ; export VGFREE                 # Volume Group Free Space in GB
LVTYPE=""                                       ; export LVTYPE                 # Logical volume type ext3 swap
LVMOUNT=""                                      ; export LVMOUNT                # Logical Volume mount point
LVOWNER=""                                      ; export LVOWNER                # Logical Vol Mount point owner
LVGROUP=""                                      ; export LVGROUP                # Logical Vol Mount point group
LVPROT=""                                       ; export LVPROT                 # Logical Vol Mount point protection
STDERR=/$SLAM_TMPDIR/stderr.$$	                ; export STDERR                 # Output of Standard Error
STDOUT=/$SLAM_TMPDIR/stdout.$$                  ; export STDOUT                 # Output of Standard Output
BATCH_MODE=0                                    ; export BATCH_MODE             # 0=Not in Batch 1=Batch MOde
FSTAB=/etc/fstab                                ; export FSTAB                  # Filesystem Table file
TUNE2FS="/sbin/tune2fs"	                        ; export TUNE2FS                # Tune2fs Command Path
MKFS_EXT3="/sbin/mkfs.ext3"		                ; export MKFS_EXT3              # ext3 mkfs command path
FSCK_EXT3="/sbin/fsck.ext3"		                ; export FSCK_EXT3              # ext3 fsck command path
MKDIR="/bin/mkdir"	       		                ; export MKDIR                  # mkdir command path
MOUNT="/bin/mount"	        	                ; export MOUNT                  # mount command path
CHMOD="/bin/chmod"	        	                ; export CHMOD                  # chmod command path
CHOWN="/bin/chown"	        	                ; export CHOWN                  # chown command path
VGS="/usr/sbin/vgs"                             ; export VGS                    # VGS Command Path
VGLIST="$SLAM_TMPDIR/vglist.$$"                 ; export VGLIST                 # Contain list of VG on system
declare -a mount_array                                                          # Declare mount & unmount array
INCR_PCT=1.10                                   ; export INCR_PCT               # Percentage Filesystem Increase
VGMIN_PCT=10                                    ; export VGMIN_PCT              # Must have PCT free in VG to Incr
VGMIN_MB=10240                                  ; export VGMIN_MB               # Min Free Space needed in VG to incr filesystem



# Filesystem name need to be passed to this script.
# If no parameter is received, then log is updated and process aborted
#####################################################################################################
if [ $# -ne 1 ]
        then echo "$PN must receive one parameters." >>$SLAM_LOG 2>&1
             echo "The filesystem name to increase"  >>$SLAM_LOG 2>&1
             echo "Could not process the request"    >>$SLAM_LOG 2>&1
             exit 1
        else FSNAME=$1
fi


# -------------------------------------------------------------------------------------
# Convert String Received to Lowercase
# -------------------------------------------------------------------------------------
tolower() {
    echo $1 | tr "[:upper:]" "[:lower:]"
}


# -------------------------------------------------------------------------------------
# Convert String Received to Uppercase
# -------------------------------------------------------------------------------------
toupper() {
    echo $1 | tr  "[:lower:]" "[:upper:]"
}



# -------------------------------------------------------------------------------------
# This function get the volume group information
# -------------------------------------------------------------------------------------
getvg_info()
{
    WVGNAME=$1
    vgexist $WVGNAME
    VGEXIST=$?
    if [ $VGEXIST -eq 0 ]
        then if [ "$OSNAME" = "linux" ]
                then VGSOPT="--noheadings --separator , --units m "
                     VGSIZE=`$VGS $VGSOPT $WVGNAME |awk -F, '{ print $6 }'|tr -d 'G' |awk -F\. '{ print $1 }'`
                     VGFREE=`$VGS $VGSOPT $WVGNAME |awk -F, '{ print $7 }'|tr -d 'G' |awk -F\. '{ print $1 }'`
             fi
    fi
    return
}



# -------------------------------------------------------------------------------------
# This function based on MountPoint set Global Variable (VGNAME, LVNAME, ...)
# -------------------------------------------------------------------------------------
get_mntdata()
{
   mnt2get=$1
   grep "^/dev/" $FSTAB | awk '{ printf "%s \n", $2 }' |grep "^${mnt2get} " >/dev/null
   mntget_rc=$?
   if [ $mntget_rc -ne 0 ] ; then return $mntget_rc ; fi

   LVMOUNT=$mnt2get
   LVLINE=`grep "^/dev/" $FSTAB | tr -s '\t' ' ' | grep "${mnt2get} "`
   LVNAME=`echo $LVLINE | awk -F/ '{ print $4 }'  | tr -d " "`
   VGNAME=`echo $LVLINE | awk -F/ '{ print $3 }'`
   LVTYPE=`echo $LVLINE | awk     '{ print $3 }'`
   LVTYPE=`tolower $LVTYPE`

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

}


# -------------------------------------------------------------------------------------
# Function called to Expand a filesystem
# -------------------------------------------------------------------------------------
extend_fs()
{

# Extend the logical volume
    write_log "$LVEXTEND -L+${SIZE2ADD} /dev/$VGNAME/$LVNAME"
    $LVEXTEND -L+${SIZE2ADD} /dev/$VGNAME/$LVNAME 1> $STDOUT 2> $STDERR
    ERRCODE="$?"
    if [ "$ERRCODE" -ne 0 ]
        then cat $STDOUT $STDERR >> $SLAM_LOG
             write_log "Error on lvextend /dev/$VGNAME/$LVNAME"
             return 1
        else write_log "OK"
    fi


    if [ "$OSVERSION" -ge 5 ]
         then write_log "$RESIZE2FS     /dev/$VGNAME/$LVNAME"
              $RESIZE2FS  /dev/$VGNAME/$LVNAME 1> $STDOUT 2> $STDERR
  		      EN=$?
	     else write_log "$EXT2ONLINE    /dev/$VGNAME/$LVNAME"
              $EXT2ONLINE /dev/$VGNAME/$LVNAME 1> $STDOUT 2> $STDERR
			  EN=$?
	fi

    if [ $EN -ne 0 ]
        then cat $STDOUT $STDERR >> $SLAM_LOG
             if [ "$OSVERSION" -ge 5 ]
                then write_log "Error on ext2online /dev/$VGNAME/$LVNAME"
                else write_log "Error on resize2fs /dev/$VGNAME/$LVNAME"
             fi
             return 1
        else write_log "OK"
    fi

}



# -------------------------------------------------------------------------------------
# This function is called at the beginning of the script
# -------------------------------------------------------------------------------------
initialize_process()
{
    # OSVERSION Indicate the RedHat (CentOS) Version 3,4,5 based on kernel version
    OSVERSION=6                                         # Default Value
    kver=`uname -r | awk -F"." '{ print $1 $2 $3 }' | awk -F"-" '{ print $1 }'`
    if [ $kver -eq 3100 ] ; then OSVERSION=7 ; fi
    if [ $kver -eq 2632 ] ; then OSVERSION=6 ; fi
    if [ $kver -eq 2618 ] ; then OSVERSION=5 ; fi
    if [ $kver -eq 269  ] ; then OSVERSION=4 ; fi
    if [ $kver -eq 2421 ] ; then OSVERSION=3 ; fi
    if [ $kver -eq 249  ] ; then OSVERSION=2 ; fi
    export OSVERSION

    # Check for supported version
    if [ "$OSVERSION" -lt 4 ]
        then echo "Red Hat version $OSVERSION is not supported"  >>$SLAM_LOG 2>&1
             exit 1
    fi

    # Determine if we are using lvm1 or lvm2
    LVMVER=1                        ; export LVMVER     # Assume lvm1 by default
    rpm -q lvm2 > /dev/null 2>&1                        # Is lvm2 installed ?
    RC=$?                                               # RC = 0 = yes lvm2
    if [ $RC -eq 0 ] ; then LVMVER=2 ; fi               # lvm2 install set lvm2 on


    # Setup Path for programs depending of LVM Version
    LVCREATE=`which lvcreate`   	                ; export LVCREATE
    LVEXTEND=`which lvextend`                       ; export LVEXTEND
    LVSCAN=`which lvscan`                          ; export LVSCAN
    RESIZE2FS=`which resize2fs`                     ; export RESIZE2FS
    EXT2ONLINE="/usr/sbin/ext2online"               ; export EXT2ONLINE # RHEL4 Only
    if [ $OSVERSION -gt 3 ]
       then VGDIR="/etc/lvm/backup"                 ; export VGDIR # RHEL4 and Above
       else VGDIR="/etc/lvmtab.d"                   ; export VGDIR # RHEL3 Only
    fi
}



# -------------------------------------------------------------------------------------
# This function is called just before exiting the script
# -------------------------------------------------------------------------------------
end_process()
{
    # Maintain log file at a reasonnable size (2000 Records)
    touch $SLAM_LOG
    tail -2000 $SLAM_LOG > $SLAM_LOG.$$
    rm -f $SLAM_LOG > /dev/null 2>&1
    mv $SLAM_LOG.$$ $SLAM_LOG
    chmod 666 $SLAM_LOG

    # Remove Work Files
    rm -f $SLAM_TMP_FILE1 > /dev/null 2>&1
    rm -f $VGLIST > /dev/null 2>&1
    rm -f $SLAM_MAIL > /dev/null 2>&1
}



# -------------------------------------------------------------------------------------
# This function is called to send an email to the sysadmin
# -------------------------------------------------------------------------------------
send_email()
{
    WSUBJECT=$1

	# Current Directory Size and Usage
	echo -e "\n${DASH}Current ${FSNAME} Filesystem size and usage \n${DASH}" >> $SLAM_MAIL
	df -hP ${FSNAME} >> $SLAM_MAIL

    # Print 20 biggest directory of filesystem
    echo -e "\n${DASH}Biggest directories of ${FSNAME} - Can we do some cleanup ? \n${DASH}" >> $SLAM_MAIL
    du -kx $FSNAME | sort -rn | head -20 | nl >> $SLAM_MAIL

    # Print 20 biggest file
    echo -e "\n${DASH}Biggest files of ${FSNAME} - Can we delete some files ? \n${DASH}" >> $SLAM_MAIL
    find $FSNAME -type f -printf '%s %p\n'|sort -nr|head -20 | nl >> $SLAM_MAIL

    # Check Filesystem name for Oracle/DB2 keyword
    echo ${FSNAME} | grep -iE "ora|dbf|exp|dmp|arc|db2" > /dev/null 2>&1
    dba_related=$?

    # Send Email to sysadmin and DBA if DBA related
    if [ "$dba_related" -eq 0 ]
        then cat $SLAM_MAIL | mail -s "$WSUBJECT" "${SYSADMIN}"
        else cat $SLAM_MAIL | mail -s "$WSUBJECT" "${SYSADMIN}"
    fi
    rm -f $SLAM_MAIL > /dev/null 2>&1

}



#####################################################################################################
#                               Main Process Start Here
#####################################################################################################
    echo -e "\n${DASH}Starting the script $PN on - ${MYHOST} - ${WDATE}"
    initialize_process

# Only Run on Linux
    if [ "$OSNAME" = "aix" ]
       then write_log "AIX filesystem auto increase is not implemented ... "
            exit 1
    fi


# Check if mount point exist
    if ! mntexist $FSNAME
        then write_log "Filesystem $FSNAME does not exist"
             exit 1
    fi

# Get filesystem metadata
    get_mntdata $FSNAME

# Display useful date for debugging
    write_log "Logical Volume Name ..........: $LVNAME"
    write_log "Volume Group .................: $VGNAME"
    write_log "Filesystem Type ..............: $LVTYPE"
    write_log "Filesystem Size in MB ........: $LVSIZE"
    write_log "Filesystem Owner .............: $LVOWNER"
    write_log "Filesystem Group .............: $LVGROUP"
    write_log "Filesystem Protection ........: $LVPROT"
    write_log "Filesystem Increase Pct.......: $INCR_PCT"

# No Email or message when GFS filesystem need increase for the moment
    if [ "$LVTYPE" == "GFS" ]
       then WMESS="This type of filesystem (${LVTYPE}) is not supported - ..."
            write_log "$WMESS"
            write_log "Exit scom-fs-inc.sh - exit 1"
            exit 1
    fi

# Only Linux EXT3 filesystem are supported
    if [ "$LVTYPE" != "ext3" ] && [ "$LVTYPE" != "ext4" ]
       then WMESS="This type of filesystem $LVTYPE is not yet supported ..."
            write_log "$WMESS"
            write_log "Sending Email and exit - $WMESS"
            send_email "$WMESS"
            exit 1
    fi

# Calculate new Filesystem Size
    OLDSIZE=$LVSIZE
    NEW_LVSIZE=`echo "$LVSIZE * $INCR_PCT" | bc | awk -F \. ' {print $1 }'`
    write_log "New Filesystem Size in MB ....: $NEW_LVSIZE"

# Calculate number of MB that will be added
    SIZE2ADD=`echo "$NEW_LVSIZE - $OLDSIZE" | bc `
    write_log "FS will be increase by (MB)...: $SIZE2ADD"

# Get VG Information
    getvg_info $VGNAME
    write_log "VG size in MB ................: $VGSIZE"
    write_log "VG MB free space before incr..: $VGFREE"
    VGUSED=`echo "$VGSIZE - $VGFREE" | bc `
    write_log "VG MB used ...................: $VGUSED"

# If MB needed to increase is greater/equal MB free in VG - Refuse increase
    if [ $SIZE2ADD -ge $VGFREE ]
       then WMESS="Increase Refused - Need ${SIZE2ADD}MB only ${VGFREE}MB left in $VGNAME on $MYHOST"
            write_log "$WMESS"
            echo "$WMESS" >> $SLAM_MAIL
            send_email "Filesystem $FSNAME was rejected"
            exit 1
    fi

    MBLEFT=`echo "$VGFREE - $SIZE2ADD" | bc `
    write_log "VG MB free space after incr...: $MBLEFT"
    write_log "Min. free MB in VG after incr.: $VGMIN_MB"


# Calculate the % Left in the VG
    VGPCT_LEFT=`echo "(($VGFREE/$VGSIZE)*100)" | bc -l | xargs printf "%2.0f"`
    write_log "Percent free space left in VG.: $VGPCT_LEFT %"
    write_log "Minimum percent needed in VG..: $VGMIN_PCT %"

# If MB Free in VG after filesystem increase is less than 10240MB then refuse filesystem increase
    if [ $MBLEFT -le $VGMIN_MB ]
       then WMESS="$FSNAME increase refused only ${MBLEFT}MB free in VG $VGNAME on $MYHOST"
            write_log "$WMESS"
            echo "$WMESS" >> $SLAM_MAIL
            send_email "Filesystem $FSNAME was rejected"
            exit 1
       else write_log "Filesystem $FSNAME will be increase by $SIZE2ADD MB"
    fi


# If % Free in VG is less than the minimun - Refuse filesystem increase
#    if [ $VGPCT_LEFT -le $VGMIN_PCT ]
#       then WMESS="$FSNAME increase refused only ${VGPCT_LEFT}% free in VG $VGNAME on $MYHOST"
#            write_log "$WMESS"
#            echo "$WMESS" >> $SLAM_MAIL
#            send_email "Filesystem $FSNAME was rejected"
#            exit 1
#       else write_log "Filesystem $FSNAME will be increase by $SIZE2ADD MB"
#    fi


# Increase filesystem
    write_log "$FSNAME filesystem increase is starting"
    write_log "df -hP $FSNAME - Before increase"
    echo -e "`date` - Filesystem $FSNAME before increase : \n `df -hP $FSNAME` \n" >> $SLAM_MAIL
    df -hP $FSNAME >> $SLAM_LOG 2>&1
    extend_fs
    RC=$?
    if [ "$RC" -ne 0 ]
        then WMESS="Error ($RC) occured while increasing the filesystemn"
             write_log "$WMESS"
             echo -e "$WMESS \n" >> $SLAM_MAIL
        else WMESS="Filesystem increased with success !"
             write_log "$WMESS"
             echo -e "$WMESS \n" >> $SLAM_MAIL
    fi
    write_log "df -hP $FSNAME - After increase"
    df -hP $FSNAME >> $SLAM_LOG 2>&1
    echo -e "`date` - Filesystem $FSNAME after increase : \n `df -hP $FSNAME` \n" >> $SLAM_MAIL

# End of script
    send_email "Filesystem $FSNAME on $MYHOST was increase"
    write_log "The script $PN Ver $VER on - ${MYHOST} - Ended \n${DASH}"
	rm -f $STD_OUT $STD_ERR
    end_process
