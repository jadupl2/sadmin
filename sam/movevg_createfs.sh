#! /bin/bash
##########################################################################
# Shellscript:	movevg_createfs.sh - Recreate fs  on a VG to another
# Version    :	1.2
# Author     :	jacques duplessis (jack.duplessis@standardlife.ca)
# Date       :	2005-11-15
# Requires   :	bash shell - lvm installed
# Category   :	filesystem tools
# SCCS-Id.   :	@(#) movevg_createfs.sh 1.2 05.11.15
##########################################################################
# Description
#
# Note
#    o this script recreate the filesystem of a VG onto another.
#    o the lvname is change - a x is added in the front on the name
#    o the filesystem name is prefix with a x 
#    o the drsavevg.dat file is used as input for this program
#    o user enter source and destination volume group
#
##########################################################################
#set -x
PN=${0##*/}			; export PN         # Program name
VER='1.8'                       ; export VER        # program version

# Global Variables
# -------------------------------------------------------------------------------------
SYSADM=/sysadmin/sam            ; export SYSADM     # where reside pgm & data
RSYNCFILE=/tmp/rsync.$$         ; export RSYNCFILE  # Script that contain rsync command
REMOVEFILE=/tmp/remove.$$       ; export REMOVEFILE # Script to remove old lv after move
GOLIVE=/tmp/golive.$$           ; export GOLIVE     # Script to go live on new VG
WFILE=/tmp/drcreatefs.$$        ; export WFILE      # temporary work file
DRFILE="$SYSADM/drsavevg.dat"   ; export DRFILE     # Output file of program
WTMP=/tmp/drcreatefs_tmp.$$     ; export WTMP       # temporary work file
DEBUG=true                      ; export DEBUG      # When true more verbose
RLINE=0                         ; export RLINE      # Used as a line counter
WREF=/tmp/moveref.$$            ; export WREF       # Work Reference file

# Global Variables Logical Volume Information 
# -------------------------------------------------------------------------------------
LVNAME=""						; export LVNAME     # Logical Volume Name
LVSIZE=""                       ; export LVSIZE     # Logical Volume Size
VGNAME=""                       ; export VGNAME     # Volume Group Name
LVTYPE=""                       ; export LVTYPE     # Logical volume type ext3 swap
LVMOUNT=""                      ; export LVMOUNT    # Logical Volume mount point
LVOWNER=""                      ; export LVOWNER    # Logical Vol Mount point owner
LVGROUP=""                      ; export LVGROUP    # Logical Vol Mount point group
LVPROT=""                       ; export LVPROT     # Logical Vol Mount point protection
STDERR=/tmp/stderr.$$			; export STDERR     # Output of Standard Error
STDOUT=/tmp/stdout.$$           ; export STDOUT     # Output of Standard Output
BATCH_MODE=false                ; export BATCH_MODE # true if run in batch mode 
LOGFILE=$SYSADM/drcreate.log    ; export LOGFILE    # Program execution log
FSTAB=/etc/fstab                ; export FSTAB      # Filesystem Table file
WFSTAB=/tmp/fstab.wrk           ; export WFSTAB     # Filesystem Table Work file
TUNE2FS="/sbin/tune2fs"	        ; export TUNE2FS    # Tune2fs Command Path
MKFS_EXT3="/sbin/mkfs.ext3"		; export MKFS_EXT3  # ext3 mkfs command path
FSCK_EXT3="/sbin/fsck.ext3"		; export FSCK_EXT3  # ext3 fsck command path 
MKDIR="/bin/mkdir"	        	; export MKDIR      # mkdir command path
MOUNT="/bin/mount"	        	; export MOUNT      # mount command path
CHMOD="/bin/chmod"	        	; export CHMOD      # chmod command path
CHOWN="/bin/chown"	        	; export CHOWN      # chown command path
MAXLEN_LV=14                    ; export MAXLEN_LV  # Max Char for LV Name

# Determine if we are using lvm1 or lvm2
# -------------------------------------------------------------------------------------
LVMVER=1                       ; export LVMVER  # Assume lvm1 by default
rpm -q lvm2 > /dev/null 2>&1                    # Is lvm2 installed ?
RC=$?                                           # RC = 0 = yes lvm2
if [ $RC -eq 0 ] ; then LVMVER=2 ; fi           # lvm2 install set lvm2 on


# Setup Path for programs depending of LVM Version
# -------------------------------------------------------------------------------------
if [ $LVMVER -eq 2 ]
   then LVCREATE="/usr/sbin/lvcreate"		; export LVCREATE
        VGDIR="/etc/lvm/backup"                 ; export VGDIR
   else LVCREATE="/sbin/lvcreate"		; export LVCREATE
        VGDIR="/etc/lvmtab.d"                   ; export VGDIR
fi


# Display Program setting - LVM Version - Batch Mode
# -------------------------------------------------------------------------------------
tput clear
WDATE=$(date "+%C%y.%m.%d %H:%M:%S")
if [ ! $BATCH_MODE ]  
   then echo -e "Program $PN - Version $VER - Starting `date`" 
        echo "Batch mode is OFF" 
        echo -e "We are using LVM version $LVMVER\n"
   else echo -e "\n\n---------------------------------------" >>$LOGFILE
        echo -e "$WDATE - Program $PN - Version $VER - Starting `date`" >> $LOGFILE
        echo "$WDATE - Batch mode is ON"  >>$LOGFILE 
        echo -e "$WDATE - We are using LVM version $LVMVER\n" >> $LOGFILE
        stty erase "^H"
fi
    



# make sure the output and work file does not exist
# -------------------------------------------------------------------------------------
#rm -f $WFILE  >/dev/null 2>&1
rm -f $WTMP   >/dev/null 2>&1


# Verify that data file exist
# -------------------------------------------------------------------------------------
if [ ! -r "$DRFILE" ]
   then echo "The input file $DRFILE does not exist !"
        WDATE=$(date "+%C%y.%m.%d %H:%M:%S")
        echo "$WDATE - The input file $DRFILE does not exist !" >>$LOGFILE
        echo "Process aborted"
        echo "$WDATE - Process aborted" >>$LOGFILE
        exit 1
fi


# -------------------------------------------------------------------------------------
# Function called to display message and write it at the same time in the log
# -------------------------------------------------------------------------------------
write_log()
{
     WMESS=$1 
     WDATE=$(date "+%C%y.%m.%d %H:%M:%S")
     echo -e "$WMESS"
     echo -e "$WDATE - $WMESS" >> $LOGFILE
}




# -------------------------------------------------------------------------------------
# Function called when an error occured when trying to create a filesystem
# -------------------------------------------------------------------------------------
report_error()
{
     WMESS=$1
     WDATE=$(date "+%C%y.%m.%d %H:%M:%S")

# Write the error in the log file
     echo -e "$WDATE - $WMESS" >> $LOGFILE

# If in interactive mode - Advise user before proceeding
     if ( ! $BATCH_MODE )
        then echo -e "$WMESS"
             echo -e "\a\aPress [ENTER] to continue - CTRL-C to Abort\c"
             read dummy 
     fi
}



# -------------------------------------------------------------------------------------
# Function called to write code to be run at the end to ; 
#    o delete all entriues that are in comment in /etc/fstab
#    o Remove the old logical volume 
# -------------------------------------------------------------------------------------
update_cleanup()
{
     echo -e "\n# Remove the logical volume /dev/${OLD_VGNAME}/${OLD_LVNAME}" >> $REMOVEFILE
     #echo "echo \"Unmount ${OLD_LVMOUNT} \"">>$REMOVEFILE
     #echo -e "umount ${OLD_LVMOUNT}" >> $REMOVEFILE
     #echo -e "if [ \$? -ne 0 ] ; then echo \"Error umounting ${OLD_LVMOUNT} - [ENTER] Continue\" ; read dummy ; fi" >> $REMOVEFILE
     #echo -e "#"               >> $REMOVEFILE
     echo "echo \"lvremove -f /dev/${OLD_VGNAME}/${OLD_LVNAME} \"">>$REMOVEFILE
     echo -e "lvremove -f /dev/${OLD_VGNAME}/${OLD_LVNAME}" >> $REMOVEFILE
     echo -e "if [ \$? -ne 0 ] ; then echo \"Error on lvremove\" ; read dummy ; fi" >> $REMOVEFILE
     echo -e "#"               >> $REMOVEFILE
#     echo -e "# Removing /dev/${OLD_VGNAME}/${OLD_LVNAME} from $FSTAB " >> $REMOVEFILE
#     echo -e "grep -vi \"/dev/${OLD_VGNAME}/${OLD_LVNAME} \" $FSTAB > $WFSTAB" >> $REMOVEFILE
#     echo -e "cp $WFSTAB $FSTAB "               >> $REMOVEFILE
#     echo -e "$CHMOD 644 $FSTAB"                         >> $REMOVEFILE
#     echo -e "$CHOWN root.root $FSTAB"                   >> $REMOVEFILE
#     echo -e " "               >> $REMOVEFILE
}




# -------------------------------------------------------------------------------------
# Function called to write code to be run after rsync ; 
#     o Umount OLd and New FIlesystem
#     o Put in comment the original filesystem in /etc/fstab
#     o Remove the new filesystem line in /etc/fstab 
#     o Add a new line that used the new LV with the old munt point
# -------------------------------------------------------------------------------------
update_golive()
{
    echo -e "\n\n# ----- Stop using /dev/${OLD_VGNAME}/${OLD_LVNAME} and use /dev/${VGNAME}/${LVNAME}" >> $GOLIVE
    echo "echo \"------------ \"">>$GOLIVE
    echo "echo \"Unmount ${OLD_LVMOUNT} \"">>$GOLIVE
    echo -e "umount ${OLD_LVMOUNT}"           >> $GOLIVE
    echo -e "if [ \$? -ne 0 ] ; then echo \"Error umounting ${OLD_LVMOUNT} - [ENTER] Continue\" ; read dummy ; fi" >> $GOLIVE

    echo "echo \"Unmount ${LVMOUNT} \"">>$GOLIVE
    echo -e "umount ${LVMOUNT}"               >> $GOLIVE
    echo -e "if [ \$? -ne 0 ] ; then echo \"Error umounting ${LVMOUNT} - [ENTER] Continue\" ; read dummy ; fi" >> $GOLIVE

    echo -e "#"               >> $GOLIVE
    echo "echo \"Put in comment /dev/${OLD_VGNAME}/${OLD_LVNAME} on ${OLD_LVMOUNT} in $FSTAB \"">>$GOLIVE
    echo -e "grep -vi \"^/dev/${OLD_VGNAME}/${OLD_LVNAME} \" $FSTAB > $WFSTAB "  >> $GOLIVE
    echo -e "echo \"#/dev/${OLD_VGNAME}/${OLD_LVNAME} ${OLD_LVMOUNT} \" | awk '{ printf \"%-30s %-30s %s\\\n\",\$1,\$2,\"ext3 defaults 1 2\" }' >> $WFSTAB" >> $GOLIVE
    echo -e "cp $WFSTAB $FSTAB " >> $GOLIVE

    echo -e "#"               >> $GOLIVE
    echo "echo \"Adding ${OLD_LVMOUNT} on /dev/${VGNAME}/${LVNAME} in $FSTAB \"">>$GOLIVE
    echo -e "grep -vi \"^/dev/${VGNAME}/${LVNAME} \" $FSTAB > $WFSTAB"          >> $GOLIVE
    echo -e "echo \"/dev/${VGNAME}/${LVNAME} ${OLD_LVMOUNT} \" | awk '{ printf \"%-30s %-30s %s\\\n\",\$1,\$2,\"ext3 defaults 1 2\" }'>>$WFSTAB" >> $GOLIVE
    echo -e "cp $WFSTAB $FSTAB "  >> $GOLIVE
    echo -e "# "               >> $GOLIVE

#    echo "echo \"mount ${OLD_LVMOUNT} on /dev/${VGNAME}/${LVNAME} \"">>$GOLIVE
#    echo -e "mount ${OLD_LVMOUNT}"           >> $GOLIVE
#    echo -e "if [ \$? -ne 0 ] ; then echo \"Error mounting ${OLD_LVMOUNT} - [ENTER] Continue\" ; read dummy ; fi" >> $GOLIVE
}





# -------------------------------------------------------------------------------------
# Re-arrange /etc/fstab so that all mounts points are in order.
# -------------------------------------------------------------------------------------
fix_fstab()
{
awk '! /^#/ && !/^$/ { printf "%03d %s\n", length($2), $0 }' $FSTAB |sort > $WFSTAB
awk '{ printf "%-30s %-30s %s %s %-3s %-3s\n",$2,$3,$4,$5,$6,$7}' $WFSTAB>$FSTAB 
$CHMOD 644 $FSTAB
$CHOWN root.root $FSTAB
}






# -------------------------------------------------------------------------------------
# Create filesystem function
# -------------------------------------------------------------------------------------
create_fs()
{
    write_log "\n-----------------------------\n"
    
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


    write_log "\nRunning : ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME}"
    ${LVCREATE} -L${LVSIZE}M -n ${LVNAME} ${VGNAME} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with lvcreate\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME}"
    ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with mkfs.ext3\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : ${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME}"
    ${FSCK_EXT3} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with fsck.ext3\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME}"
    ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with tune2fs\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : ${MKDIR} -p ${LVMOUNT}"
    ${MKDIR} -p ${LVMOUNT} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with mkdir\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : Adding mount point in $FSTAB"
    echo "/dev/${VGNAME}/${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'>>$FSTAB
   
    write_log "Running : Fix /etc/fstab so that all mounts points are in correct order"
    fix_fstab

    write_log "Running : ${MOUNT} ${LVMOUNT}"
    ${MOUNT} ${LVMOUNT} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with mount\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT}"
    ${CHOWN} ${LVOWNER}:${LVGROUP} ${LVMOUNT} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with chown\n `cat $STDERR`" ; return 1 ;  fi
    
    write_log "Running : ${CHMOD} ${LVPROT} ${LVMOUNT}"
    ${CHMOD} ${LVPROT} ${LVMOUNT} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with chmod\n `cat $STDERR`" ; return 1 ;  fi
}













# -------------------------------------------------------------------------------------
#  M A I N    P R O G R A M    S T A R T    H E R E  
# -------------------------------------------------------------------------------------


# Accept the volume group that we need to create the filesystems
while : 
   do 
   echo -e "Program $PN - Version $VER - Starting `date`"
   echo -e "We are using LVM version $LVMVER\n"
   ls -1 $VGDIR | sort >  $WTMP
   echo -e "\n\nTheses are the volume group that exist on this system"
   cat $WTMP
   echo -e "\nSpecify volume group that you want to REPLICATE the filesystems : \c" 
   read VG
   grep -i $VG $WTMP > /dev/null
   if [ $? -eq 0 ] ; then break ; fi
   echo -e "\n\aVolume Group $VG is invalid - Press [RETURN] to choose another" 
   read dummy
   done




# Accept the destination volume group
while : 
   do 
   ls -1 $VGDIR | grep -v $VG | sort >  $WTMP
   echo -e "\n\nTheses are the volume group acceptable for the destination VG" 
   cat $WTMP
   echo -e "\nSpecify destination volume group where new filesystems will be created : \c" 
   read VGDEST
   grep -i $VGDEST $WTMP > /dev/null
   if [ $? -eq 0 ] ; then break ; fi
   echo -e "\n\aVolume Group $VGDEST is invalid - Press [RETURN] to choose another" 
   read dummy
   done




# Accept final confirmation 
while : 
   do 
   echo -e "Want to proceed to create all filesystems of $VG onto $VGDEST [Y/N] ? \c" 
   read answer
   if [ "$answer" = "Y" ] || [ "$answer" = "y" ] 
      then answer="Y" ; break
      else echo "Please re-run the script" ; exit 1
   fi
   done




#
# Initialize rsync script file 
echo "#! /bin/bash"                           > $RSYNCFILE
echo "# Creation Date - `date`"              >> $RSYNCFILE
echo -e "echo \"Starting rsync \`date\`\""   >> $RSYNCFILE

#
echo "#! /bin/bash"                           > $GOLIVE
echo "# Creation Date - `date`"              >> $GOLIVE
echo "#                       "              >> $GOLIVE
echo -e " " >> $GOLIVE
echo -e "tput clear" >> $GOLIVE
echo -e "echo -e \"This process umount filesystem and update the $FSTAB file\"" >> $GOLIVE
echo -e "echo -e \"I will make a backup of $FSTAB to /etc/fstab.$$\"" >> $GOLIVE
echo -e "echo -e \"   - If an error is encountered, the process stop and wait for a response\"" >> $GOLIVE
echo -e "echo -e \"   - If you need to go back just copy this file back\""  >> $GOLIVE
echo -e " " >> $GOLIVE
echo -e "echo -e \"Press [ENTER} to start process or CTRL-C to abort\"" >> $GOLIVE
echo -e "read dummy" >> $GOLIVE

#
echo "#! /bin/bash"                           > $REMOVEFILE
echo "# Creation Date - `date`"              >> $REMOVEFILE
echo "#                       "              >> $REMOVEFILE
echo -e " " >> $REMOVEFILE
echo -e "tput clear" >> $REMOVEFILE
echo -e "echo -e \"This process remove the logical volumes on the old vg ${OLD_VGNAME} one by one\"" >> $REMOVEFILE
echo -e "echo -e \"   - If an error is encountered, the process stop and wait for a response\"" >> $REMOVEFILE
echo -e " " >> $REMOVEFILE
echo -e "echo -e \"Press [ENTER} to start process or CTRL-C to abort\"" >> $REMOVEFILE
echo -e "read dummy" >> $REMOVEFILE


# Process all logical volume detected
for LVLINE in $( grep -i "^$VG:" $DRFILE )

    do
    OLD_LVNAME=$( echo $LVLINE | awk -F: '{ print $3 }' )
    LVNAME="x${OLD_LVNAME}"
    OLD_VGNAME=$( echo $LVLINE | awk -F: '{ print $1 }' )
    VGNAME=$VGDEST 
    LVSIZE=$( echo $LVLINE | awk -F: '{ print $5 }' )
    LVTYPE=$( echo $LVLINE | awk -F: '{ print $4 }' )
    if [ "$LVTYPE" = "swap" ]
       then LVGROUP="" ; LVOWNER=""
            LVMOUNT="" ; LVPROT="0000"
       else LVMOUNT=$(echo $LVLINE | awk -F: '{ print $2 }' )
            LVTYPE=$( echo $LVLINE | awk -F: '{ print $4 }' )
            LVOWNER=$(echo $LVLINE | awk -F: '{ print $7 }' )
            LVGROUP=$(echo $LVLINE | awk -F: '{ print $6 }' )
            LVPROT=$( echo $LVLINE | awk -F: '{ print $8 }' )
    fi
    OLD_LVMOUNT=$LVMOUNT
    LVMOUNT=`echo "$LVMOUNT" |  sed 's/\//\/x/'`
    if [ $DEBUG ] 
       then write_log "\n-----------------------------\n"
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
    

    # Ask if user want to do this filesystem
    while :
          do
          echo -e "Want to proceed to create $LVMOUNT filesystem onto $VGDEST [Y/N] ? \c"
          read answer
          if [ "$answer" = "Y" ] || [ "$answer" = "y" ]
             then answer="Y"
                  create_fs
                  RC=$?
                  if [ $RC -eq 0 ] ; then write_log "Filesystem $LVMOUNT created successfully" ; fi
                  if [ $RC -ne 0 ] ; then write_log "Filesystem $LVMOUNT ended with errors - Please verify";fi

                  # The others scripts MUST process mount point in reverse order (Length of mount point)
                  # Need to umount /coco/coco1 before /coco
                  RLINE=`expr $RLINE + 1`
                  echo "${RLINE}:${OLD_LVMOUNT}:${OLD_LVNAME}:${OLD_VGNAME}:${LVMOUNT}:${LVNAME}:${VGNAME}" >> $WFILE
                  break
             else break
          fi
          done
    done



# Update RSYNC Script
for LVLINE in $( sort -rn $WFILE )
    do 
    OLD_LVMOUNT=$(echo $LVLINE | awk -F: '{ print $2 }' )
    OLD_LVNAME=$( echo $LVLINE | awk -F: '{ print $3 }' )
    OLD_VGNAME=$( echo $LVLINE | awk -F: '{ print $4 }' )
    LVMOUNT=$(echo $LVLINE | awk -F: '{ print $5 }' )
    LVNAME=$( echo $LVLINE | awk -F: '{ print $6 }' )
    VGNAME=$( echo $LVLINE | awk -F: '{ print $7 }' )

    # Update Rsync Script
    echo "#" >> $RSYNCFILE
    echo -e "echo -e \"\\\n--------------------------\""   >> $RSYNCFILE
    echo "echo -e \"rsync -axv --delete ${OLD_LVMOUNT}/ ${LVMOUNT}/\"" >> $RSYNCFILE
    echo "time /usr/bin/rsync -axv --delete ${OLD_LVMOUNT}/ ${LVMOUNT}/" >> $RSYNCFILE
    echo "RC=\$?" >> $RSYNCFILE
    echo "if [ \"\$RC\" -ne 0 ] ; then echo \"ERROR \$RC on rsync\" ;  fi" >> $RSYNCFILE
    echo "echo \"Counting number of file in $OLD_LVMOUNT and $LVMOUNT - Please wait ...\"" >>$RSYNCFILE
    echo "OLD_COUNT=\`/usr/bin/find $OLD_LVMOUNT  2>&1 | wc | awk '{ print \$1 }'\`" >>$RSYNCFILE
    echo "NEW_COUNT=\`/usr/bin/find $LVMOUNT      2>&1 | wc | awk '{ print \$1 }'\`" >>$RSYNCFILE
    echo "echo \"Number of files in $OLD_LVMOUNT is \$OLD_COUNT and in $LVMOUNT it's \$NEW_COUNT\"" >>$RSYNCFILE
    echo "if [ \$OLD_COUNT -ne \$NEW_COUNT ] ; then echo \"Number of file in $OLD_LVMOUNT and $LVMOUNT are not equal\"; echo ERROR ;fi">>$RSYNCFILE

    # Update Go Live script
    update_golive

    # Update Clean up Script
    update_cleanup

    done

    echo -e "echo \"End of rsync \`date\`\""   >> $RSYNCFILE

# Clean up FSTAB 
    echo -e "# Re-order mount point in $FSTAB"      >> $GOLIVE
    echo -e "grep -Ev \"^#|^$\" $FSTAB | awk '{ printf \"%03d %s\\\n\", length(\$2), \$0 }' |sort >$WFSTAB" >> $GOLIVE
    echo -e "awk '{ printf \"%-30s %-30s %s %s %-3s %-3s\\\n\",\$2,\$3,\$4,\$5,\$6,\$7}' $WFSTAB > $FSTAB" >> $GOLIVE
    echo -e "$CHMOD 644 $FSTAB"                     >> $GOLIVE
    echo -e "$CHOWN root.root $FSTAB"               >> $GOLIVE
    echo "echo \"Mounting all filesystems \""       >> $GOLIVE
    echo -e "mount -a "                             >> $GOLIVE
    echo -e "mount -a "                             >> $GOLIVE


# End of program.
write_log "\n-----------------------------\n"
write_log "The script for synchronizing the filesystem is : $RSYNCFILE"
write_log "The script for going live on new datavg is     : $GOLIVE"
write_log "The script for removing old LV at the end is   : $REMOVEFILE"
write_log "Program $PN - Version $VER - Ended `date`"
