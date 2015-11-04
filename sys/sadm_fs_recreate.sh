#! /bin/bash
##########################################################################
# Shellscript:	drcreatefs.sh - Recreate filesystem in case of Disaster
# Version    :	1.2
# Author     :	jacques duplessis (jack.duplessis@standardlife.ca)
# Date       :	2005-10-21
# Requires   :	bash shell - lvm installed
# Category   :	disaster tools
# SCCS-Id.   :	@(#) drcreatefs.sh 1.2 05.20.09
##########################################################################
# Description
#
# Note
#    o this script recreate the filesystem of the system with the right
#      size and protection exactly like we have at the office.
#    o run this script and specify the filesystem vg you want to recreate
#    o This script read it input from the file $SYSADM/drsavevg.dat
#
##########################################################################
#set -x
PN=${0##*/}			; export PN         # Program name
VER='1.2'                       ; export VER        # program version

# Global Variables
# -------------------------------------------------------------------------------------
SYSADM=/sysadmin/sam            ; export SYSADM     # where reside pgm & data
WFILE=/tmp/drcreatefs.$$        ; export WFILE      # temporary work file
DRFILE=$SYSADM/drsavevg.dat     ; export DRFILE     # Output file of program
WTMP=/tmp/drcreatefs_tmp.$$     ; export WTMP       # temporary work file
#DEBUG=true                      ; export DEBUG      # When true more verbose

# Global Variables Logical Volume Information 
# -------------------------------------------------------------------------------------
LVNAME=""			; export LVNAME     # Logical Volume Name
LVSIZE=""                       ; export LVSIZE     # Logical Volume Size
VGNAME=""                       ; export VGNAME     # Volume Group Name
LVTYPE=""                       ; export LVTYPE     # Logical volume type ext3 swap
LVMOUNT=""                      ; export LVMOUNT    # Logical Volume mount point
LVOWNER=""                      ; export LVOWNER    # Logical Vol Mount point owner
LVGROUP=""                      ; export LVGROUP    # Logical Vol Mount point group
LVPROT=""                       ; export LVPROT     # Logical Vol Mount point protection
STDERR=/tmp/stderr.$$		; export STDERR     # Output of Standard Error
STDOUT=/tmp/stdout.$$           ; export STDOUT     # Output of Standard Output
BATCH_MODE=false                ; export BATCH_MODE # true if run in batch mode 
LOGFILE=$SYSADM/drcreate.log    ; export LOGFILE    # Program execution log
FSTAB=/etc/fstab                ; export FSTAB      # Filesystem Table Name


# Determine if we are using lvm1 or lvm2
# -------------------------------------------------------------------------------------
LVMVER=1                       ; export LVMVER  # Assume lvm1 by default
rpm -q lvm2 > /dev/null 2>&1                    # Is lvm2 installed ?
RC=$?                                           # RC = 0 = yes lvm2
if [ $RC -eq 0 ] ; then LVMVER=2 ; fi           # lvm2 install set lvm2 on


# Setup Path for programs depending of LVM Version
# -------------------------------------------------------------------------------------
if [ $LVMVER -eq 2 ]
   then LVCREATE=`which lvcreate`   	; export LVCREATE
   else LVCREATE="/sbin/lvcreate"		; export LVCREATE
fi
TUNE2FS="/sbin/tune2fs"				    ; export TUNE2FS
MKFS_EXT3="/sbin/mkfs.ext3"			    ; export MKFS.EXT3
FSCK_EXT3="/sbin/fsck.ext3"	        	; export FSCK.EXT3
MKFS_EXT4="/sbin/mkfs.ext4"			    ; export MKFS.EXT4
FSCK_EXT4="/sbin/fsck.ext4"	        	; export FSCK.EXT4
MKDIR="/bin/mkdir"	                	; export MKDIR
MOUNT="/bin/mount"	                	; export MOUNT
CHMOD="/bin/chmod"	                	; export CHMOD
CHOWN="/bin/chown"	                	; export CHOWN


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
rm -f $WFILE  >/dev/null 2>&1
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
# Create filesystem function
# -------------------------------------------------------------------------------------
create_fs()
{
    write_log "\n-----------------------------\n"
    
    # If logical volume name is greater than 15 char - then make it 14
    # ---------------------------------------------------------------------------------
    if [ ${#LVNAME} -gt 14 ] 
       then write_log "The Logical volume name ${LVNAME} (${#LVNAME} char) is too long"
            LVNAME=`echo "${LVNAME}" | cut -c1-14`
            write_log "It has been changed to ${LVNAME}"
    fi 


    # Check if logical volume name already exist - chop it and 2 numbers at the end
    # ---------------------------------------------------------------------------------
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
    # ---------------------------------------------------------------------------------
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

    if [ "$LVTYPE" = "ext3" ]
        then write_log "Running : ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT3} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             RC=$?
             if [ "$RC" -ne 0 ] ; then report_error "Error $RC with mkfs.ext3\n `cat $STDERR`" ; return 1 ;  fi
    fi 
    if [ "$LVTYPE" = "ext4" ]
        then write_log "Running : ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME}"
             ${MKFS_EXT4} -b4096 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             RC=$?
             if [ "$RC" -ne 0 ] ; then report_error "Error $RC with mkfs.ext4\n `cat $STDERR`" ; return 1 ;  fi
    fi 

    if [ "$LVTYPE" = "ext3" ]
        then write_log "Running : ${FSCK_EXT3} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT3} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             RC=$?
             if [ "$RC" -ne 0 ] ; then report_error "Error $RC with fsck.ext3\n `cat $STDERR`" ; return 1 ;  fi
    fi
    if [ "$LVTYPE" = "ext4" ]
        then write_log "Running : ${FSCK_EXT4} -f /dev/${VGNAME}/${LVNAME}"
             ${FSCK_EXT4} -fy /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
             RC=$?
             if [ "$RC" -ne 0 ] ; then report_error "Error $RC with fsck.ext4\n `cat $STDERR`" ; return 1 ;  fi
    fi

    write_log "Running : ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME}"
    ${TUNE2FS} -c 0 -i 0 /dev/${VGNAME}/${LVNAME} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with tune2fs\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : ${MKDIR} -p ${LVMOUNT}"
    ${MKDIR} -p ${LVMOUNT} 1> $STDOUT 2> $STDERR
    RC=$?
    if [ "$RC" -ne 0 ] ; then report_error "Error $RC with mkdir\n `cat $STDERR`" ; return 1 ;  fi

    write_log "Running : Adding mount point in /etc/fstab"
    echo "/dev/${VGNAME}/${LVNAME} ${LVMOUNT}" | awk '{ printf "%-30s %-30s %s\n",$1,$2,"ext3 defaults 1 2"}'>>/etc/fstab
    
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
   awk -F: '{ print $1 }' $DRFILE | sort | uniq > $WTMP
   echo "Theses are the volume group that should exist on this system"
   cat $WTMP
   echo -e "\nEnter the volume group that you want to recreate the filesystems : \c" 
   read VG
   grep -i $VG $WTMP > /dev/null
   if [ $? -eq 0 ] ; then break ; fi
   echo -e "\n\aVolume Group $VG is invalid - Press [RETURN] to choose another" 
   read dummy
   done


# Accept final confirmation 
while : 
   do 
   echo -e "Want to proceed with the creation of all filesystems on $VG [Y/N] ? \c" 
   read answer
   if [ "$answer" = "Y" ] || [ "$answer" = "y" ] 
      then answer="Y" ; break
      else echo "Please re-run the script" ; exit 1
   fi
   done


# Process all logical volume detected
#grep -i "$VG" $DRFILE | while read LVLINE
for LVLINE in $( grep -i $VG $DRFILE )

    do
    LVNAME=$( echo $LVLINE | awk -F: '{ print $3 }' )
    VGNAME=$( echo $LVLINE | awk -F: '{ print $1 }' )
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
    if [ $DEBUG ] 
       then echo -e "\nLINE     = $LVLINE" 
            echo "LVNAME   = $LVNAME"
            echo "VGNAME   = $VGNAME" 
            echo "LVSIZE   = $LVSIZE MB" 
            echo "LVTYPE   = $LVTYPE" 
            echo "LVMOUNT  = $LVMOUNT"
            echo "LVTYPE   = $LVTYPE"
            echo "LVOWNER  = $LVOWNER"
            echo "LVGROUP  = $LVGROUP"
            echo "LVPROT   = $LVPROT"
    fi
    create_fs 
    RC=$? 
    if [ $RC -eq 0 ] ; then write_log "Filesystem $LVMOUNT created successfully" ; fi
    if [ $RC -ne 0 ] ; then write_log "Filesystem $LVMOUNT ended with errors - Please verify"  ; fi

    done


# End of program.
echo -e "Program $PN - Version $VER - Ended `date`"
